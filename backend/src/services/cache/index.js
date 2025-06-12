/**
 * Önbellek servis modülü
 * 
 * Bu modül hem in-memory hem de Redis önbellekleme 
 * servislerini dışa aktarır. REDIS_ENABLED çevre 
 * değişkenine göre uygun servisi otomatik olarak seçer.
 */

const inMemoryCache = require('./cacheService');
const redisCache = require('./redisService');

// Redis aktif mi kontrol et
const REDIS_ENABLED = process.env.REDIS_ENABLED === 'true';

// Aktif önbellek servisini seç
const cacheService = async () => {
  if (REDIS_ENABLED && await redisCache.isConnected()) {
    console.log('Önbellek servisi: Redis');
    return redisCache;
  }
  
  console.log('Önbellek servisi: In-Memory');
  return inMemoryCache;
};

/**
 * Önbellekten veri getir
 * @param {string} key - Önbellek anahtarı
 * @returns {Promise<any|null>} - Önbellekteki veri veya null
 */
const get = async (key) => {
  const service = await cacheService();
  
  if (REDIS_ENABLED) {
    return service.get(key);
  }
  
  return service.get(key);
};

/**
 * Önbelleğe veri kaydet
 * @param {string} key - Önbellek anahtarı
 * @param {any} value - Kaydedilecek veri
 * @param {number} ttl - Önbellek süresi
 * @returns {Promise<boolean>} - İşlem başarılı mı
 */
const set = async (key, value, ttl = 300000) => { // 5 dakika varsayılan
  const service = await cacheService();
  
  if (REDIS_ENABLED) {
    return service.set(key, value, ttl / 1000); // Redis: milisaniye -> saniye
  }
  
  return service.set(key, value, ttl);
};

/**
 * Önbellekten veriyi sil
 * @param {string} key - Önbellek anahtarı
 * @returns {Promise<boolean>} - İşlem başarılı mı
 */
const del = async (key) => {
  const service = await cacheService();
  
  if (REDIS_ENABLED) {
    return service.del(key);
  }
  
  service.delete(key); // inMemoryCache için delete
  return true;
};

/**
 * Belirli bir prefix ile başlayan tüm anahtarları sil
 * @param {string} prefix - Silinecek anahtarların prefix'i
 * @returns {Promise<boolean>} - İşlem başarılı mı
 */
const deleteByPrefix = async (prefix) => {
  const service = await cacheService();
  
  if (REDIS_ENABLED) {
    return service.deleteByPrefix(prefix);
  }
  
  service.deleteByPrefix(prefix);
  return true;
};

/**
 * Tüm önbelleği temizle
 * @returns {Promise<boolean>} - İşlem başarılı mı
 */
const clear = async () => {
  const service = await cacheService();
  
  if (REDIS_ENABLED) {
    return service.clear();
  }
  
  service.clear();
  return true;
};

/**
 * Önbellek durumunu kontrol et
 * @returns {Promise<Object>} - Durum bilgisi
 */
const getStats = async () => {
  const service = await cacheService();
  
  if (REDIS_ENABLED) {
    return service.getStats();
  }
  
  return {
    type: 'in-memory',
    ...service.getStats()
  };
};

// Dışa aktar
module.exports = {
  get,
  set,
  del,
  delete: del, // Alternatif isim
  deleteByPrefix,
  clear,
  getStats
}; 