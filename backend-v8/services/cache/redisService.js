/**
 * Redis önbellek servisi
 * Upstash Redis kullanımı
 */

const { Redis } = require('@upstash/redis');
const cacheService = require('./cacheService');

// Redis istemci yapılandırması
const REDIS_URL = process.env.REDIS_URL || '';
const REDIS_ENABLED = process.env.REDIS_ENABLED === 'true';

// Debug için environment variables
console.log('Environment Variables:', {
  REDIS_URL_EXISTS: !!process.env.REDIS_URL,
  REDIS_URL_VALUE: process.env.REDIS_URL ? process.env.REDIS_URL.replace(/\/\/.*@/, '//***@') : 'not set',
  REDIS_ENABLED_RAW: process.env.REDIS_ENABLED,
  REDIS_ENABLED_PARSED: REDIS_ENABLED,
  NODE_ENV: process.env.NODE_ENV
});

// Redis istemcisi
let redisClient = null;

// Bağlantı durumu
let redisConnected = false;

/**
 * Redis URL'ini parse et ve gerekli bilgileri çıkar
 * @param {string} url 
 * @returns {{endpoint: string, token: string}}
 */
const parseRedisUrl = (url) => {
  // URL'i parse et
  const parsedUrl = new URL(url);
  
  // Token ve endpoint bilgilerini çıkar
  const token = parsedUrl.password;
  let endpoint = '';
  
  // Eğer URL rediss:// ile başlıyorsa, https:// ile değiştir
  if (parsedUrl.protocol === 'rediss:') {
    endpoint = `https://${parsedUrl.host}`;
  } else {
    endpoint = `${parsedUrl.protocol}//${parsedUrl.host}`;
  }
  
  return { endpoint, token };
};

/**
 * Redis bağlantısını başlat
 * @returns {Promise<void>}
 */
const initRedis = async () => {
  console.log('Redis yapılandırması kontrol ediliyor...');
  console.log('REDIS_ENABLED:', REDIS_ENABLED);
  console.log('REDIS_URL mevcut:', !!REDIS_URL);
  
  if (!REDIS_ENABLED || !REDIS_URL) {
    console.log('Redis devre dışı veya URL tanımlanmamış, in-memory cache kullanılıyor');
    return;
  }

  try {
    console.log('Redis bağlantısı başlatılıyor...');
    console.log('Redis URL:', REDIS_URL);
    
    // URL'i parse et
    const { endpoint, token } = parseRedisUrl(REDIS_URL);
    
    console.log('Redis endpoint:', endpoint);
    console.log('Token uzunluğu:', token?.length || 0);
    
    // Upstash Redis client oluştur
    redisClient = new Redis({
      url: endpoint,
      token: token
    });

    // Bağlantıyı test et
    console.log('Redis ping testi yapılıyor...');
    const pingResult = await redisClient.ping();
    console.log('Redis ping başarılı:', pingResult);
    redisConnected = true;
    console.log('Redis bağlantısı hazır');
    
  } catch (err) {
    console.error('Redis bağlantısı kurulamadı:', {
      name: err.name,
      message: err.message,
      code: err.code,
      stack: err.stack
    });
    console.log('In-memory cache fallback kullanılıyor');
    redisConnected = false;
  }
};

/**
 * Redis'ten veri getir
 * @param {string} key - Önbellek anahtarı
 * @returns {Promise<any|null>} - Önbellekteki veri veya null
 */
const get = async (key) => {
  if (!redisConnected || !redisClient) {
    return cacheService.get(key);
  }

  try {
    const data = await redisClient.get(key);
    return data || null;
  } catch (err) {
    console.error('Redis get hatası:', err.message);
    return cacheService.get(key);
  }
};

/**
 * Redis'e veri kaydet
 * @param {string} key - Önbellek anahtarı
 * @param {any} value - Kaydedilecek veri
 * @param {number} ttl - Önbellek süresi (saniye)
 * @returns {Promise<boolean>} - İşlem başarılı mı
 */
const set = async (key, value, ttl = 300) => {
  if (!redisConnected || !redisClient) {
    cacheService.set(key, value, ttl * 1000);
    return true;
  }

  try {
    await redisClient.set(key, value, { ex: ttl });
    return true;
  } catch (err) {
    console.error('Redis set hatası:', err.message);
    cacheService.set(key, value, ttl * 1000);
    return false;
  }
};

/**
 * Redis'ten veriyi sil
 * @param {string} key - Önbellek anahtarı
 * @returns {Promise<boolean>} - İşlem başarılı mı
 */
const del = async (key) => {
  if (!redisConnected || !redisClient) {
    cacheService.delete(key);
    return true;
  }

  try {
    await redisClient.del(key);
    return true;
  } catch (err) {
    console.error('Redis delete hatası:', err.message);
    cacheService.delete(key);
    return false;
  }
};

/**
 * Belirli bir prefix ile başlayan tüm anahtarları sil
 * @param {string} prefix - Silinecek anahtarların prefix'i
 * @returns {Promise<boolean>} - İşlem başarılı mı
 */
const deleteByPrefix = async (prefix) => {
  if (!redisConnected || !redisClient) {
    cacheService.deleteByPrefix(prefix);
    return true;
  }

  try {
    const keys = await redisClient.keys(`${prefix}*`);
    if (keys.length > 0) {
      await redisClient.del(keys);
    }
    return true;
  } catch (err) {
    console.error('Redis deleteByPrefix hatası:', err.message);
    cacheService.deleteByPrefix(prefix);
    return false;
  }
};

/**
 * Tüm önbelleği temizle
 * @returns {Promise<boolean>} - İşlem başarılı mı
 */
const clear = async () => {
  if (!redisConnected || !redisClient) {
    cacheService.clear();
    return true;
  }

  try {
    await redisClient.flushall();
    return true;
  } catch (err) {
    console.error('Redis clear hatası:', err.message);
    cacheService.clear();
    return false;
  }
};

/**
 * Önbellek durumunu kontrol et
 * @returns {Promise<Object>} - Durum bilgisi
 */
const getStats = async () => {
  // Redis bağlı değilse in-memory cache'e yönlendir
  if (!redisConnected || !redisClient) {
    return {
      type: 'in-memory',
      ...cacheService.getStats()
    };
  }

  try {
    const info = await redisClient.info();
    const dbSize = await redisClient.dbSize();

    return {
      type: 'redis',
      connected: redisConnected,
      keys: dbSize,
      info: info
    };
  } catch (err) {
    console.error('Redis stats hatası:', err.message);
    // Hata durumunda in-memory cache'e fallback yap
    return {
      type: 'in-memory',
      ...cacheService.getStats()
    };
  }
};

// Redis başlatma işlemi
initRedis().catch(err => {
  console.error('Redis başlatma hatası:', err.message);
});

module.exports = {
  initRedis,
  get,
  set,
  del,
  deleteByPrefix,
  clear,
  getStats,
  isConnected: () => redisConnected
}; 