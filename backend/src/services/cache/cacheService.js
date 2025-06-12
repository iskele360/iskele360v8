/**
 * In-memory cache servisi
 * Veritabanı sorgularını önbelleğe alarak performansı artırır
 */

class CacheService {
  constructor() {
    this.cache = new Map();
    this.ttl = new Map(); // Time to live
    this.defaultTTL = 5 * 60 * 1000; // 5 dakika (milisaniye)
  }

  /**
   * Önbellekte veri sorgulama
   * @param {string} key - Önbellek anahtarı
   * @returns {any|null} - Önbellekteki veri veya null
   */
  get(key) {
    // TTL kontrolü yap
    const expiry = this.ttl.get(key);
    if (expiry && expiry < Date.now()) {
      // Süre dolmuş, önbellekten temizle
      this.delete(key);
      return null;
    }
    
    // Önbellekteki veriyi döndür (yoksa null)
    return this.cache.has(key) ? this.cache.get(key) : null;
  }

  /**
   * Önbelleğe veri kaydetme
   * @param {string} key - Önbellek anahtarı
   * @param {any} value - Kaydedilecek veri
   * @param {number} ttl - Önbellek süresi (milisaniye)
   */
  set(key, value, ttl = this.defaultTTL) {
    this.cache.set(key, value);
    this.ttl.set(key, Date.now() + ttl);
  }

  /**
   * Önbellekten veriyi silme
   * @param {string} key - Önbellek anahtarı
   */
  delete(key) {
    this.cache.delete(key);
    this.ttl.delete(key);
  }

  /**
   * Belirli bir prefix ile başlayan tüm anahtarları silme
   * @param {string} prefix - Silinecek anahtarların prefix'i
   */
  deleteByPrefix(prefix) {
    for (const key of this.cache.keys()) {
      if (key.startsWith(prefix)) {
        this.delete(key);
      }
    }
  }

  /**
   * Tüm önbelleği temizleme
   */
  clear() {
    this.cache.clear();
    this.ttl.clear();
  }

  /**
   * Önbellek istatistiklerini alma
   * @returns {Object} - Önbellek istatistikleri
   */
  getStats() {
    const now = Date.now();
    let activeItems = 0;
    let expiredItems = 0;

    for (const [key, expiry] of this.ttl.entries()) {
      if (expiry > now) {
        activeItems++;
      } else {
        expiredItems++;
        // Temizleme
        this.delete(key);
      }
    }

    return {
      totalItems: this.cache.size,
      activeItems,
      expiredItems,
      memoryUsage: process.memoryUsage().heapUsed / 1024 / 1024
    };
  }
}

// Singleton örneği oluştur
const cacheService = new CacheService();

module.exports = cacheService; 