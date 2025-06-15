/**
 * Paralel sorgu servisi
 * Birden fazla MongoDB sorgusunu paralel olarak çalıştırır
 */

const cacheService = require('./cache');

/**
 * Birden fazla sorguyu paralel olarak çalıştırır ve sonuçları döndürür
 * @param {Object[]} queries - Çalıştırılacak sorgular dizisi
 * @param {Function} queries[].query - Sorgu fonksiyonu (Promise döndürmeli)
 * @param {string} queries[].key - Sorgu için önbellek anahtarı (opsiyonel)
 * @param {number} queries[].ttl - Önbellek süresi (milisaniye) (opsiyonel)
 * @param {boolean} useCache - Önbelleği kullan (varsayılan: true)
 * @returns {Promise<Object[]>} - Sorgu sonuçları
 */
const executeParallel = async (queries = [], useCache = true) => {
  const results = await Promise.all(
    queries.map(async ({ query, key, ttl }) => {
      // Önbellek kullanılıyorsa ve anahtar varsa, önbellekten kontrol et
      if (useCache && key) {
        const cachedResult = await cacheService.get(key);
        if (cachedResult !== null) {
          return cachedResult;
        }
      }

      try {
        // Sorguyu çalıştır
        const result = await query();
        
        // Sonucu önbelleğe ekle
        if (useCache && key) {
          await cacheService.set(key, result, ttl);
        }
        
        return result;
      } catch (error) {
        console.error(`Paralel sorgu hatası (${key || 'noKey'}):`, error);
        return null;
      }
    })
  );

  return results;
};

/**
 * Ana ekran için gerekli tüm verileri paralel olarak getirir
 * @param {string} userId - Kullanıcı ID
 * @param {Object} options - Sorgu seçenekleri
 * @param {number} options.workerLimit - İşçi sorgusu için limit
 * @param {number} options.puantajLimit - Puantaj sorgusu için limit
 * @param {boolean} options.todayOnly - Sadece bugünkü puantajları getir
 * @param {boolean} options.useCache - Önbelleği kullan
 * @returns {Promise<Object>} - Tüm veriler
 */
const fetchDashboardData = async (userId, options = {}) => {
  const {
    workerLimit = 20,
    puantajLimit = 20,
    todayOnly = true,
    useCache = true
  } = options;

  // Bugünün başlangıcı (saat 00:00:00)
  const today = new Date();
  today.setHours(0, 0, 0, 0);

  // Tüm sorgular için önbellek anahtarı ön eki
  const cacheKeyPrefix = `user_${userId}_dashboard`;
  
  // Tüm sorguları tanımla
  const queries = [
    {
      key: `${cacheKeyPrefix}_workers`,
      ttl: 5 * 60 * 1000, // 5 dakika
      query: async () => {
        const User = require('../models/User');
        return User.find({ createdBy: userId, role: 'isci' })
          .select('_id name surname code')
          .sort({ createdAt: -1 })
          .limit(workerLimit);
      }
    },
    {
      key: `${cacheKeyPrefix}_suppliers`,
      ttl: 5 * 60 * 1000, // 5 dakika
      query: async () => {
        const User = require('../models/User');
        return User.find({ createdBy: userId, role: 'supplier' })
          .select('_id name surname code')
          .sort({ createdAt: -1 })
          .limit(workerLimit);
      }
    },
    {
      key: `${cacheKeyPrefix}_puantaj_${todayOnly ? 'today' : 'all'}_${Date.now()}`,
      ttl: 2 * 60 * 1000, // 2 dakika (puantaj verileri daha sık değişebilir)
      query: async () => {
        const Puantaj = require('../models/Puantaj');
        
        // Filtreleme kriteri
        const filter = { puantajciId: userId };
        
        // Sadece bugünkü kayıtlar isteniyorsa, tarih filtresi ekle
        if (todayOnly) {
          filter.tarih = { $gte: today };
        }
        
        // Puantaj sayısı için toplam sayıyı getir (optimizasyon için ayrı sorgu)
        const totalCount = await Puantaj.countDocuments(filter);
        
        // Puantaj kayıtlarını getir
        const puantajList = await Puantaj.find(filter)
          .sort({ tarih: -1, createdAt: -1 })
          .limit(puantajLimit)
          .populate('isciId', 'name surname code');
          
        return { totalCount, puantajList };
      }
    },
    {
      key: `${cacheKeyPrefix}_puantaj_stats`,
      ttl: 10 * 60 * 1000, // 10 dakika
      query: async () => {
        const Puantaj = require('../models/Puantaj');
        
        // Bugün ve bu ay için toplam puantaj sayılarını ve çalışma saatlerini hesapla
        const now = new Date();
        const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);
        
        // Aggregation pipeline ile istatistikleri hesapla
        const stats = await Puantaj.aggregate([
          {
            $match: {
              puantajciId: userId,
              tarih: { $gte: startOfMonth }
            }
          },
          {
            $facet: {
              // Bugünkü puantajlar
              todayStats: [
                {
                  $match: {
                    tarih: { $gte: today }
                  }
                },
                {
                  $group: {
                    _id: null,
                    count: { $sum: 1 },
                    totalHours: { $sum: '$calismaSuresi' }
                  }
                }
              ],
              // Bu ayki puantajlar
              monthStats: [
                {
                  $group: {
                    _id: null,
                    count: { $sum: 1 },
                    totalHours: { $sum: '$calismaSuresi' }
                  }
                }
              ],
              // Proje bazlı istatistikler
              projectStats: [
                {
                  $group: {
                    _id: '$projeId',
                    projectName: { $first: '$projeBilgisi' },
                    count: { $sum: 1 },
                    totalHours: { $sum: '$calismaSuresi' }
                  }
                },
                {
                  $sort: { totalHours: -1 }
                },
                {
                  $limit: 5
                }
              ]
            }
          }
        ]);
        
        // Sonuçları formatla
        return {
          today: stats[0].todayStats[0] || { count: 0, totalHours: 0 },
          month: stats[0].monthStats[0] || { count: 0, totalHours: 0 },
          projects: stats[0].projectStats || []
        };
      }
    }
  ];
  
  // Tüm sorguları paralel olarak çalıştır
  const [workers, suppliers, puantajData, puantajStats] = await executeParallel(queries, useCache);
  
  // Sonuçları birleştir
  return {
    workers: workers || [],
    suppliers: suppliers || [],
    puantaj: puantajData || { totalCount: 0, puantajList: [] },
    stats: puantajStats || {
      today: { count: 0, totalHours: 0 },
      month: { count: 0, totalHours: 0 },
      projects: []
    }
  };
};

module.exports = {
  executeParallel,
  fetchDashboardData
}; 