import Redis from 'ioredis';
import dotenv from 'dotenv';

dotenv.config();

class RedisService {
  constructor() {
    this.client = null;
    this.isConnected = false;
    this.init();
  }

  init() {
    try {
      if (process.env.UPSTASH_REDIS_URL) {
        this.client = new Redis(process.env.UPSTASH_REDIS_URL);
        
        this.client.on('connect', () => {
          console.log('✅ Redis service bağlantısı başarılı');
          this.isConnected = true;
        });

        this.client.on('error', (err) => {
          console.warn('⚠️ Redis service hatası:', err.message);
          this.isConnected = false;
        });

        this.client.on('end', () => {
          console.log('⚠️ Redis service bağlantısı kesildi');
          this.isConnected = false;
        });
      }
    } catch (error) {
      console.error('❌ Redis service başlatma hatası:', error.message);
      this.isConnected = false;
    }
  }

  // Token Management
  async setToken(userId, token, expiresIn) {
    if (!this.isConnected) return;
    try {
      await this.client.set(`token:${userId}`, token, 'EX', expiresIn);
    } catch (error) {
      console.error('❌ Redis token kaydetme hatası:', error.message);
    }
  }

  async getToken(userId) {
    if (!this.isConnected) return null;
    try {
      return await this.client.get(`token:${userId}`);
    } catch (error) {
      console.error('❌ Redis token getirme hatası:', error.message);
      return null;
    }
  }

  async invalidateToken(userId) {
    if (!this.isConnected) return;
    try {
      await this.client.del(`token:${userId}`);
    } catch (error) {
      console.error('❌ Redis token silme hatası:', error.message);
    }
  }

  // Cache Management
  async setCache(key, value, expiresIn = 3600) {
    if (!this.isConnected) return;
    try {
      const serializedValue = JSON.stringify(value);
      await this.client.set(key, serializedValue, 'EX', expiresIn);
    } catch (error) {
      console.error('❌ Redis cache kaydetme hatası:', error.message);
    }
  }

  async getCache(key) {
    if (!this.isConnected) return null;
    try {
      const value = await this.client.get(key);
      return value ? JSON.parse(value) : null;
    } catch (error) {
      console.error('❌ Redis cache getirme hatası:', error.message);
      return null;
    }
  }

  async invalidateCache(key) {
    if (!this.isConnected) return;
    try {
      await this.client.del(key);
    } catch (error) {
      console.error('❌ Redis cache silme hatası:', error.message);
    }
  }

  async invalidatePattern(pattern) {
    if (!this.isConnected) return;
    try {
      const keys = await this.client.keys(pattern);
      if (keys.length > 0) {
        await this.client.del(...keys);
      }
    } catch (error) {
      console.error('❌ Redis pattern silme hatası:', error.message);
    }
  }

  // Rate Limiting
  async incrementRateLimit(key, expiresIn = 60) {
    if (!this.isConnected) return 1;
    try {
      const count = await this.client.incr(key);
      if (count === 1) {
        await this.client.expire(key, expiresIn);
      }
      return count;
    } catch (error) {
      console.error('❌ Redis rate limit hatası:', error.message);
      return 1;
    }
  }

  // Session Management
  async setSession(sessionId, data, expiresIn = 86400) {
    if (!this.isConnected) return;
    try {
      const serializedData = JSON.stringify(data);
      await this.client.set(`session:${sessionId}`, serializedData, 'EX', expiresIn);
    } catch (error) {
      console.error('❌ Redis session kaydetme hatası:', error.message);
    }
  }

  async getSession(sessionId) {
    if (!this.isConnected) return null;
    try {
      const data = await this.client.get(`session:${sessionId}`);
      return data ? JSON.parse(data) : null;
    } catch (error) {
      console.error('❌ Redis session getirme hatası:', error.message);
      return null;
    }
  }

  async invalidateSession(sessionId) {
    if (!this.isConnected) return;
    try {
      await this.client.del(`session:${sessionId}`);
    } catch (error) {
      console.error('❌ Redis session silme hatası:', error.message);
    }
  }

  // Utility Methods
  async ping() {
    if (!this.isConnected) return false;
    try {
      const result = await this.client.ping();
      return result === 'PONG';
    } catch (error) {
      console.error('❌ Redis ping hatası:', error.message);
      return false;
    }
  }

  async clearAll() {
    if (!this.isConnected) return;
    try {
      await this.client.flushall();
    } catch (error) {
      console.error('❌ Redis clearAll hatası:', error.message);
    }
  }

  async quit() {
    if (this.client) {
      try {
        await this.client.quit();
        this.isConnected = false;
        console.log('✅ Redis service bağlantısı kapatıldı');
      } catch (error) {
        console.error('❌ Redis service kapatma hatası:', error.message);
      }
    }
  }
}

// Create and export a singleton instance
const redisService = new RedisService();
export default redisService;
