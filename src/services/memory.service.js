const redis = require('../config/redis');
const logger = require('../utils/logger');

class MemoryService {
  constructor() {
    this.defaultTTL = 3600; // 1 saat
  }

  async get(key) {
    try {
      const value = await redis.get(key);
      return value ? JSON.parse(value) : null;
    } catch (error) {
      logger.error(`Redis get hatası: ${error.message}`);
      return null;
    }
  }

  async set(key, value, ttl = this.defaultTTL) {
    try {
      await redis.set(key, JSON.stringify(value), 'EX', ttl);
      return true;
    } catch (error) {
      logger.error(`Redis set hatası: ${error.message}`);
      return false;
    }
  }

  async delete(key) {
    try {
      await redis.del(key);
      return true;
    } catch (error) {
      logger.error(`Redis delete hatası: ${error.message}`);
      return false;
    }
  }

  async clear() {
    try {
      await redis.flushdb();
      return true;
    } catch (error) {
      logger.error(`Redis clear hatası: ${error.message}`);
      return false;
    }
  }

  // Özel metodlar
  async cacheUserData(userId, data, ttl = this.defaultTTL) {
    return this.set(`user:${userId}`, data, ttl);
  }

  async getCachedUserData(userId) {
    return this.get(`user:${userId}`);
  }

  async deleteCachedUserData(userId) {
    return this.delete(`user:${userId}`);
  }

  async cacheCompanyData(companyId, data, ttl = this.defaultTTL) {
    return this.set(`company:${companyId}`, data, ttl);
  }

  async getCachedCompanyData(companyId) {
    return this.get(`company:${companyId}`);
  }

  async deleteCachedCompanyData(companyId) {
    return this.delete(`company:${companyId}`);
  }
}

module.exports = new MemoryService(); 