const { Redis } = require('@upstash/redis');

class CacheManager {
  constructor() {
    this.redis = new Redis({
      url: process.env.UPSTASH_REDIS_REST_URL,
      token: process.env.UPSTASH_REDIS_REST_TOKEN,
    });
    
    this.memoryCache = new Map();
    this.isRedisAvailable = false;
    
    // Redis bağlantısını kontrol et
    this.checkRedisConnection();
  }

  async checkRedisConnection() {
    try {
      await this.redis.ping();
      this.isRedisAvailable = true;
      console.log('✅ Redis bağlantısı başarılı');
    } catch (error) {
      this.isRedisAvailable = false;
      console.log('⚠️ Redis bağlantısı başarısız, in-memory cache kullanılıyor');
    }
  }

  async get(key) {
    try {
      if (this.isRedisAvailable) {
        return await this.redis.get(key);
      }
      return this.memoryCache.get(key);
    } catch (error) {
      return this.memoryCache.get(key);
    }
  }

  async set(key, value, ttl = 3600) {
    try {
      if (this.isRedisAvailable) {
        await this.redis.set(key, value, { ex: ttl });
      }
      this.memoryCache.set(key, value);
      
      // In-memory cache için TTL
      if (ttl) {
        setTimeout(() => {
          this.memoryCache.delete(key);
        }, ttl * 1000);
      }
    } catch (error) {
      this.memoryCache.set(key, value);
    }
  }

  async del(key) {
    try {
      if (this.isRedisAvailable) {
        await this.redis.del(key);
      }
      this.memoryCache.delete(key);
    } catch (error) {
      this.memoryCache.delete(key);
    }
  }

  async clear() {
    try {
      if (this.isRedisAvailable) {
        await this.redis.flushall();
      }
      this.memoryCache.clear();
    } catch (error) {
      this.memoryCache.clear();
    }
  }
}

// Singleton instance
const cacheManager = new CacheManager();
module.exports = cacheManager; 