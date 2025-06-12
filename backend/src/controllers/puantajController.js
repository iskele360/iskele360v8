const Puantaj = require('../models/Puantaj');
const User = require('../models/User');
const socketService = require('../services/socketService');
const cacheService = require('../services/cache');
const parallelQueryService = require('../services/parallelQueryService');
const mongoose = require('mongoose');

/**
 * Dashboard verilerini getir
 * Tüm gerekli verileri parallel olarak ve önbellekli şekilde sorgular
 */
exports.getDashboardData = async (req, res) => {
  try {
    const userId = req.user._id;

    // Sayfalama ve filtreleme seçenekleri
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 20;
    const todayOnly = req.query.todayOnly === 'true';
    const useCache = req.query.noCache !== 'true';

    // Tüm verileri parallel olarak getir
    const dashboardData = await parallelQueryService.fetchDashboardData(userId, {
      workerLimit: limit,
      puantajLimit: limit,
      todayOnly,
      useCache
    });

    // Verileri gönder
    res.status(200).json({
      success: true,
      ...dashboardData,
      pagination: {
        page,
        limit,
        totalWorkers: dashboardData.workers.length,
        totalSuppliers: dashboardData.suppliers.length,
        totalPuantaj: dashboardData.puantaj.totalCount,
        hasMoreWorkers: dashboardData.workers.length === limit,
        hasMorePuantaj: dashboardData.puantaj.puantajList.length < dashboardData.puantaj.totalCount
      }
    });
  } catch (error) {
    console.error('Dashboard data error:', error);
    res.status(500).json({
      success: false,
      message: 'Sunucu hatası, lütfen daha sonra tekrar deneyin'
    });
  }
};

/**
 * Yeni puantaj kaydı oluştur
 */
exports.createPuantaj = async (req, res) => {
  try {
    const {
      isciId, 
      baslangicSaati, 
      bitisSaati, 
      calismaSuresi, 
      projeId, 
      projeBilgisi,
      aciklama,
      tarih
    } = req.body;

    // Kullanıcı ID'yi MongoDB ObjectId'ye çevir
    const isciObjectId = mongoose.Types.ObjectId.isValid(isciId) 
      ? new mongoose.Types.ObjectId(isciId) 
      : null;
    
    if (!isciObjectId) {
      return res.status(400).json({
        success: false,
        message: 'Geçersiz işçi ID'
      });
    }

    // İşçinin varlığını kontrol et
    const isci = await User.findById(isciObjectId);
    
    if (!isci) {
      return res.status(404).json({
        success: false,
        message: 'İşçi bulunamadı'
      });
    }
    
    // İşçinin puantajcıya ait olup olmadığını kontrol et
    if (isci.createdBy && isci.createdBy.toString() !== req.user._id.toString()) {
      return res.status(403).json({
        success: false,
        message: 'Sadece kendi oluşturduğunuz işçiler için puantaj kaydı oluşturabilirsiniz'
      });
    }

    // Tarih değerini işle
    const puantajTarihi = tarih ? new Date(tarih) : new Date();

    // Geçerli bir tarih değeri olduğundan emin ol
    if (isNaN(puantajTarihi.getTime())) {
      return res.status(400).json({
        success: false,
        message: 'Geçersiz tarih formatı'
      });
    }

    // Puantaj kaydı oluştur
    const puantaj = await Puantaj.create({
      isciId: isciObjectId,
      puantajciId: req.user._id,
      baslangicSaati,
      bitisSaati,
      calismaSuresi,
      projeId,
      projeBilgisi,
      aciklama: aciklama || '',
      tarih: puantajTarihi
    });

    // Önbelleği temizle
    await cacheService.deleteByPrefix(`user_${req.user._id}_dashboard`);

    // Socket.IO ile işçiye bildirim gönder
    socketService.emitToUser(isciId, 'puantaj_created', {
      puantaj,
      message: 'Yeni puantaj kaydı oluşturuldu'
    });

    // Başarılı yanıt
    res.status(201).json({
      success: true,
      data: puantaj
    });
  } catch (error) {
    console.error('Puantaj oluşturma hatası:', error);
    res.status(500).json({
      success: false,
      message: 'Sunucu hatası, lütfen daha sonra tekrar deneyin'
    });
  }
};

/**
 * Puantaj kaydını güncelle
 */
exports.updatePuantaj = async (req, res) => {
  try {
    const { id } = req.params;
    const {
      baslangicSaati, 
      bitisSaati, 
      calismaSuresi, 
      projeId, 
      projeBilgisi,
      aciklama,
      durum
    } = req.body;

    // Puantaj kaydını bul
    const puantaj = await Puantaj.findById(id);

    if (!puantaj) {
      return res.status(404).json({
        success: false,
        message: 'Puantaj kaydı bulunamadı'
      });
    }

    // Sadece puantaj kaydını oluşturan kişi güncelleyebilir
    if (puantaj.puantajciId.toString() !== req.user._id.toString()) {
      return res.status(403).json({
        success: false,
        message: 'Sadece kendi oluşturduğunuz puantaj kayıtlarını güncelleyebilirsiniz'
      });
    }

    // Güncelleme
    const updatedPuantaj = await Puantaj.findByIdAndUpdate(
      id,
      {
        baslangicSaati: baslangicSaati || puantaj.baslangicSaati,
        bitisSaati: bitisSaati || puantaj.bitisSaati,
        calismaSuresi: calismaSuresi || puantaj.calismaSuresi,
        projeId: projeId || puantaj.projeId,
        projeBilgisi: projeBilgisi || puantaj.projeBilgisi,
        aciklama: aciklama !== undefined ? aciklama : puantaj.aciklama,
        durum: durum || puantaj.durum
      },
      { new: true, runValidators: true }
    );

    // Önbelleği temizle
    await cacheService.deleteByPrefix(`user_${req.user._id}_dashboard`);

    // Socket.IO ile işçiye bildirim gönder
    socketService.emitToUser(puantaj.isciId, 'puantaj_updated', {
      puantaj: updatedPuantaj,
      message: 'Puantaj kaydı güncellendi'
    });

    // Başarılı yanıt
    res.status(200).json({
      success: true,
      data: updatedPuantaj
    });
  } catch (error) {
    console.error('Puantaj güncelleme hatası:', error);
    res.status(500).json({
      success: false,
      message: 'Sunucu hatası, lütfen daha sonra tekrar deneyin'
    });
  }
};

/**
 * Puantaj kaydını sil
 */
exports.deletePuantaj = async (req, res) => {
  try {
    const { id } = req.params;

    // Puantaj kaydını bul
    const puantaj = await Puantaj.findById(id);

    if (!puantaj) {
      return res.status(404).json({
        success: false,
        message: 'Puantaj kaydı bulunamadı'
      });
    }

    // Sadece puantaj kaydını oluşturan kişi silebilir
    if (puantaj.puantajciId.toString() !== req.user._id.toString()) {
      return res.status(403).json({
        success: false,
        message: 'Sadece kendi oluşturduğunuz puantaj kayıtlarını silebilirsiniz'
      });
    }

    // Puantaj kaydını sil
    await Puantaj.findByIdAndDelete(id);

    // Önbelleği temizle
    await cacheService.deleteByPrefix(`user_${req.user._id}_dashboard`);

    // Socket.IO ile işçiye bildirim gönder
    socketService.emitToUser(puantaj.isciId, 'puantaj_deleted', {
      puantajId: id,
      message: 'Puantaj kaydı silindi'
    });

    // Başarılı yanıt
    res.status(200).json({
      success: true,
      message: 'Puantaj kaydı başarıyla silindi'
    });
  } catch (error) {
    console.error('Puantaj silme hatası:', error);
    res.status(500).json({
      success: false,
      message: 'Sunucu hatası, lütfen daha sonra tekrar deneyin'
    });
  }
};

/**
 * İşçinin puantaj kayıtlarını getir (sayfalı)
 */
exports.getIsciPuantajlari = async (req, res) => {
  try {
    const { isciId } = req.params;
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 20;
    const skip = (page - 1) * limit;
    
    // Önbellek anahtarı
    const cacheKey = `isci_${isciId}_puantaj_${page}_${limit}`;
    const cachedData = await cacheService.get(cacheKey);
    
    if (cachedData) {
      return res.status(200).json(cachedData);
    }
    
    // MongoDB ObjectId'ye çevir
    const isciObjectId = mongoose.Types.ObjectId.isValid(isciId) 
      ? new mongoose.Types.ObjectId(isciId) 
      : null;
    
    if (!isciObjectId) {
      return res.status(400).json({
        success: false,
        message: 'Geçersiz işçi ID'
      });
    }
    
    // İşçinin varlığını kontrol et
    const isci = await User.findById(isciObjectId);
    
    if (!isci) {
      return res.status(404).json({
        success: false,
        message: 'İşçi bulunamadı'
      });
    }
    
    // İşçi kendi puantajlarını görebilir veya onu oluşturan puantajcı görebilir
    if (req.user.role === 'isci' && req.user._id.toString() !== isciId) {
      return res.status(403).json({
        success: false,
        message: 'Sadece kendi puantaj kayıtlarınızı görüntüleyebilirsiniz'
      });
    }
    
    if (req.user.role === 'puantajcı' && isci.createdBy && isci.createdBy.toString() !== req.user._id.toString()) {
      return res.status(403).json({
        success: false,
        message: 'Sadece kendi oluşturduğunuz işçilerin puantaj kayıtlarını görüntüleyebilirsiniz'
      });
    }
    
    // Paralel sorguları tanımla
    const queries = [
      {
        query: () => Puantaj.countDocuments({ isciId: isciObjectId })
      },
      {
        query: () => Puantaj.find({ isciId: isciObjectId })
          .sort({ tarih: -1, createdAt: -1 })
          .skip(skip)
          .limit(limit)
      }
    ];
    
    // Paralel sorguları çalıştır
    const [totalCount, puantajlar] = await parallelQueryService.executeParallel(queries, false);
    
    // Yanıt formatla
    const response = {
      success: true,
      count: puantajlar.length,
      total: totalCount,
      pagination: {
        page,
        limit,
        totalPages: Math.ceil(totalCount / limit),
        hasNextPage: skip + puantajlar.length < totalCount,
        hasPrevPage: page > 1
      },
      data: puantajlar
    };
    
    // Önbelleğe kaydet (5 dakika)
    await cacheService.set(cacheKey, response, 5 * 60 * 1000);
    
    // Başarılı yanıt
    res.status(200).json(response);
  } catch (error) {
    console.error('Puantaj listeleme hatası:', error);
    res.status(500).json({
      success: false,
      message: 'Sunucu hatası, lütfen daha sonra tekrar deneyin'
    });
  }
};

/**
 * Puantajcının oluşturduğu tüm puantaj kayıtlarını getir (sayfalı)
 */
exports.getPuantajciPuantajlari = async (req, res) => {
  try {
    // Puantajcı ID'si (varsayılan olarak giriş yapan kullanıcı)
    const puantajciId = req.params.puantajciId || req.user._id;
    
    // Sayfalama parametreleri
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 20;
    const skip = (page - 1) * limit;
    
    // Filtreleme parametreleri
    const tarihBaslangic = req.query.baslangicTarihi ? new Date(req.query.baslangicTarihi) : null;
    const tarihBitis = req.query.bitisTarihi ? new Date(req.query.bitisTarihi) : null;
    const projeId = req.query.projeId || null;
    const isciId = req.query.isciId || null;
    const durum = req.query.durum || null;
    
    // Önbellek anahtarı
    const cacheKey = `puantajci_${puantajciId}_puantaj_${page}_${limit}_${tarihBaslangic}_${tarihBitis}_${projeId}_${isciId}_${durum}`;
    const cachedData = await cacheService.get(cacheKey);
    
    if (cachedData) {
      return res.status(200).json(cachedData);
    }
    
    // MongoDB ObjectId'ye çevir
    const puantajciObjectId = mongoose.Types.ObjectId.isValid(puantajciId) 
      ? new mongoose.Types.ObjectId(puantajciId) 
      : null;
    
    if (!puantajciObjectId) {
      return res.status(400).json({
        success: false,
        message: 'Geçersiz puantajcı ID'
      });
    }
    
    // Farklı bir puantajcının kayıtlarını görüntülemeye çalışırken yetki kontrolü
    if (req.params.puantajciId && req.params.puantajciId !== req.user._id.toString() && req.user.role !== 'admin') {
      return res.status(403).json({
        success: false,
        message: 'Sadece kendi oluşturduğunuz puantaj kayıtlarını görüntüleyebilirsiniz'
      });
    }
    
    // Filtre oluştur
    const filter = { puantajciId: puantajciObjectId };
    
    // Tarih filtresi
    if (tarihBaslangic && tarihBitis) {
      filter.tarih = { $gte: tarihBaslangic, $lte: tarihBitis };
    } else if (tarihBaslangic) {
      filter.tarih = { $gte: tarihBaslangic };
    } else if (tarihBitis) {
      filter.tarih = { $lte: tarihBitis };
    }
    
    // Proje filtresi
    if (projeId) {
      filter.projeId = projeId;
    }
    
    // İşçi filtresi
    if (isciId) {
      filter.isciId = mongoose.Types.ObjectId.isValid(isciId) 
        ? new mongoose.Types.ObjectId(isciId) 
        : isciId;
    }
    
    // Durum filtresi
    if (durum) {
      filter.durum = durum;
    }
    
    // Paralel sorguları tanımla
    const queries = [
      {
        query: () => Puantaj.countDocuments(filter)
      },
      {
        query: () => Puantaj.find(filter)
          .sort({ tarih: -1, createdAt: -1 })
          .skip(skip)
          .limit(limit)
          .populate('isciId', 'name surname code')
      }
    ];
    
    // Paralel sorguları çalıştır
    const [totalCount, puantajlar] = await parallelQueryService.executeParallel(queries, false);
    
    // Yanıt formatla
    const response = {
      success: true,
      count: puantajlar.length,
      total: totalCount,
      pagination: {
        page,
        limit,
        totalPages: Math.ceil(totalCount / limit),
        hasNextPage: skip + puantajlar.length < totalCount,
        hasPrevPage: page > 1
      },
      data: puantajlar
    };
    
    // Önbelleğe kaydet (3 dakika)
    await cacheService.set(cacheKey, response, 3 * 60 * 1000);
    
    // Başarılı yanıt
    res.status(200).json(response);
  } catch (error) {
    console.error('Puantaj listeleme hatası:', error);
    res.status(500).json({
      success: false,
      message: 'Sunucu hatası, lütfen daha sonra tekrar deneyin'
    });
  }
};

/**
 * Özet istatistikleri getir
 */
exports.getPuantajStats = async (req, res) => {
  try {
    const userId = req.user._id;
    
    // Önbellek anahtarı
    const cacheKey = `user_${userId}_puantaj_stats`;
    const cachedData = await cacheService.get(cacheKey);
    
    if (cachedData) {
      return res.status(200).json({
        success: true,
        data: cachedData
      });
    }
    
    // Zaman aralıkları
    const now = new Date();
    const today = new Date(now);
    today.setHours(0, 0, 0, 0);
    
    const startOfWeek = new Date(now);
    startOfWeek.setDate(now.getDate() - now.getDay());
    startOfWeek.setHours(0, 0, 0, 0);
    
    const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);
    
    // Aggregation pipeline kullanarak istatistikleri hesapla
    const stats = await Puantaj.aggregate([
      {
        $match: {
          puantajciId: userId
        }
      },
      {
        $facet: {
          totalStats: [
            {
              $group: {
                _id: null,
                count: { $sum: 1 },
                totalHours: { $sum: '$calismaSuresi' }
              }
            }
          ],
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
          weekStats: [
            {
              $match: {
                tarih: { $gte: startOfWeek }
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
          monthStats: [
            {
              $match: {
                tarih: { $gte: startOfMonth }
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
          ],
          workerStats: [
            {
              $group: {
                _id: '$isciId',
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
    
    // İşçi bilgilerini getir
    const workerIds = stats[0].workerStats.map(stat => stat._id);
    const workers = await User.find({ _id: { $in: workerIds } }).select('name surname code');
    
    // İşçi bilgilerini ekle
    const workerStatsWithNames = stats[0].workerStats.map(stat => {
      const worker = workers.find(w => w._id.toString() === stat._id.toString());
      return {
        ...stat,
        name: worker ? `${worker.name} ${worker.surname}` : 'Bilinmeyen İşçi',
        code: worker ? worker.code : ''
      };
    });
    
    // Sonuçları formatla
    const formattedStats = {
      total: stats[0].totalStats[0] || { count: 0, totalHours: 0 },
      today: stats[0].todayStats[0] || { count: 0, totalHours: 0 },
      week: stats[0].weekStats[0] || { count: 0, totalHours: 0 },
      month: stats[0].monthStats[0] || { count: 0, totalHours: 0 },
      projects: stats[0].projectStats || [],
      workers: workerStatsWithNames || []
    };
    
    // Önbelleğe kaydet (10 dakika)
    await cacheService.set(cacheKey, formattedStats, 10 * 60 * 1000);
    
    // Başarılı yanıt
    res.status(200).json({
      success: true,
      data: formattedStats
    });
  } catch (error) {
    console.error('İstatistik hatası:', error);
    res.status(500).json({
      success: false,
      message: 'Sunucu hatası, lütfen daha sonra tekrar deneyin'
    });
  }
}; 