/**
 * Redis önbellek servisi
 * In-memory cache'e alternatif olarak Redis kullanımı
 * Redis bağlantısı yoksa in-memory cache'e fallback yapar
 */

const redis = require('redis');
const cacheService = require('./cacheService');

// Redis istemci yapılandırması
const REDIS_URL = process.env.REDIS_URL || 'redis://localhost:6379';
const REDIS_ENABLED = process.env.REDIS_ENABLED === 'true';

// Redis istemcisi
let redisClient = null;

// Bağlantı durumu
let redisConnected = false;

/**
 * Redis bağlantısını başlat
 * @returns {Promise<void>}
 */
const initRedis = async () => {
  if (!REDIS_ENABLED || !REDIS_URL) {
    console.log('Redis devre dışı veya URL tanımlanmamış, in-memory cache kullanılıyor');
    return;
  }

  try {
    // URL protokolüne göre TLS ayarı
    const isTLS = REDIS_URL.startsWith('rediss://');
    
    console.log('Redis bağlantı ayarları:', {
      url: REDIS_URL.replace(/\/\/.*@/, '//***@'), // Hassas bilgileri gizle
      enabled: REDIS_ENABLED,
      isTLS: isTLS,
      mode: isTLS ? 'SSL/TLS' : 'Standard'
    });

    // Redis client oluştur
    redisClient = redis.createClient({
      url: REDIS_URL,
      socket: {
        ...(isTLS && {
          tls: true,
          rejectUnauthorized: false,
          servername: new URL(REDIS_URL).hostname
        }),
        connectTimeout: 10000,
        reconnectStrategy: (retries) => {
          const delay = Math.min(retries * 50, 3000);
          console.log(`Redis yeniden bağlanma denemesi ${retries}, ${delay}ms sonra`);
          return delay;
        }
      }
    });

    // Bağlantı olaylarını dinle
    redisClient.on('connect', () => {
      console.log('Redis bağlantısı başlatılıyor...');
    });

    redisClient.on('ready', () => {
      console.log('Redis bağlantısı hazır');
      redisConnected = true;
    });

    redisClient.on('error', (err) => {
      console.error('Redis bağlantı hatası:', {
        message: err.message,
        code: err.code,
        syscall: err.syscall,
        hostname: err.hostname,
        fatal: err.fatal
      });
      redisConnected = false;
    });

    redisClient.on('reconnecting', () => {
      console.log('Redis yeniden bağlanıyor...');
    });

    redisClient.on('end', () => {
      console.log('Redis bağlantısı sonlandı');
      redisConnected = false;
    });

    // Bağlantıyı aç
    console.log('Redis bağlantısı açılıyor...');
    await redisClient.connect();

    // Bağlantıyı test et
    console.log('Redis ping testi yapılıyor...');
    const pingResult = await redisClient.ping();
    console.log('Redis ping sonucu:', pingResult);
    
  } catch (err) {
    console.error('Redis bağlantısı kurulamadı:', {
      message: err.message,
      code: err.code,
      syscall: err.syscall,
      hostname: err.hostname,
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
  // Redis bağlı değilse in-memory cache'e yönlendir
  if (!redisConnected || !redisClient) {
    return cacheService.get(key);
  }

  try {
    const data = await redisClient.get(key);
    return data ? JSON.parse(data) : null;
  } catch (err) {
    console.error('Redis get hatası:', err.message);
    // Hata durumunda in-memory cache'e fallback yap
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
const set = async (key, value, ttl = 300) => { // 5 dakika varsayılan
  // Redis bağlı değilse in-memory cache'e yönlendir
  if (!redisConnected || !redisClient) {
    cacheService.set(key, value, ttl * 1000); // saniye -> milisaniye
    return true;
  }

  try {
    const stringValue = JSON.stringify(value);
    await redisClient.set(key, stringValue);
    await redisClient.expire(key, ttl);
    return true;
  } catch (err) {
    console.error('Redis set hatası:', err.message);
    // Hata durumunda in-memory cache'e fallback yap
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
  // Redis bağlı değilse in-memory cache'e yönlendir
  if (!redisConnected || !redisClient) {
    cacheService.delete(key);
    return true;
  }

  try {
    await redisClient.del(key);
    return true;
  } catch (err) {
    console.error('Redis delete hatası:', err.message);
    // Hata durumunda in-memory cache'e fallback yap
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
  // Redis bağlı değilse in-memory cache'e yönlendir
  if (!redisConnected || !redisClient) {
    cacheService.deleteByPrefix(prefix);
    return true;
  }

  try {
    // SCAN kullanarak prefixle eşleşen anahtarları bul
    let cursor = 0;
    const pattern = `${prefix}*`;
    let keys = [];

    do {
      const scan = await redisClient.scan(cursor, {
        MATCH: pattern,
        COUNT: 100
      });
      
      cursor = scan.cursor;
      keys = [...keys, ...scan.keys];
    } while (cursor !== 0);

    // Bulunan tüm anahtarları sil
    if (keys.length > 0) {
      await redisClient.del(keys);
    }

    return true;
  } catch (err) {
    console.error('Redis deleteByPrefix hatası:', err.message);
    // Hata durumunda in-memory cache'e fallback yap
    cacheService.deleteByPrefix(prefix);
    return false;
  }
};

/**
 * Tüm önbelleği temizle
 * @returns {Promise<boolean>} - İşlem başarılı mı
 */
const clear = async () => {
  // Redis bağlı değilse in-memory cache'e yönlendir
  if (!redisConnected || !redisClient) {
    cacheService.clear();
    return true;
  }

  try {
    await redisClient.flushDb();
    return true;
  } catch (err) {
    console.error('Redis clear hatası:', err.message);
    // Hata durumunda in-memory cache'e fallback yap
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
  get,
  set,
  del,
  deleteByPrefix,
  clear,
  getStats,
  isConnected: () => redisConnected
}; 