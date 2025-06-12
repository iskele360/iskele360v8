const Redis = require('ioredis');
const dotenv = require('dotenv');

dotenv.config();

class RedisService {
  constructor() {
    this.inMemoryStore = new Map();
    this.ttl = parseInt(process.env.CACHE_TTL) || 3600; // Default 1 hour
    
    try {
      if (process.env.UPSTASH_REDIS_URL) {
        this.redis = new Redis(process.env.UPSTASH_REDIS_URL);
        this._setupListeners();
      } else {
        console.log('Redis URL tanımlanmamış, in-memory cache kullanılıyor...');
        this.redis = null;
      }
    } catch (error) {
      console.warn('Redis başlatma hatası:', error.message);
      console.log('In-memory cache kullanılıyor...');
      this.redis = null;
    }
  }

  _setupListeners() {
    this.redis.on('connect', () => {
      console.log('Redis service bağlantısı başarılı');
    });

    this.redis.on('error', (error) => {
      console.warn('Redis service hatası:', error);
      console.log('In-memory cache kullanılıyor...');
      this.redis = null;
    });
  }

  async get(key) {
    try {
      if (this.redis) {
        const value = await this.redis.get(key);
        return value ? JSON.parse(value) : null;
      } else {
        const item = this.inMemoryStore.get(key);
        if (!item) return null;
        if (item.expiry && item.expiry < Date.now()) {
          this.inMemoryStore.delete(key);
          return null;
        }
        return item.value;
      }
    } catch (error) {
      console.warn('Cache get hatası:', error);
      return null;
    }
  }

  async set(key, value, expireSeconds = null) {
    try {
      if (this.redis) {
        const stringValue = JSON.stringify(value);
        if (expireSeconds) {
          await this.redis.setex(key, expireSeconds, stringValue);
        } else {
          await this.redis.setex(key, this.ttl, stringValue);
        }
      } else {
        const expiry = expireSeconds 
          ? Date.now() + (expireSeconds * 1000)
          : Date.now() + (this.ttl * 1000);
        this.inMemoryStore.set(key, { value, expiry });
      }
      return true;
    } catch (error) {
      console.warn('Cache set hatası:', error);
      return false;
    }
  }

  async delete(key) {
    try {
      if (this.redis) {
        await this.redis.del(key);
      } else {
        this.inMemoryStore.delete(key);
      }
      return true;
    } catch (error) {
      console.warn('Cache delete hatası:', error);
      return false;
    }
  }

  async exists(key) {
    try {
      if (this.redis) {
        return await this.redis.exists(key);
      } else {
        return this.inMemoryStore.has(key);
      }
    } catch (error) {
      console.warn('Cache exists hatası:', error);
      return false;
    }
  }

  async clear() {
    try {
      if (this.redis) {
        await this.redis.flushall();
      } else {
        this.inMemoryStore.clear();
      }
      return true;
    } catch (error) {
      console.warn('Cache clear hatası:', error);
      return false;
    }
  }

  // Puantaj cache methods
  async getPuantajList(userId) {
    return this.get(`puantaj:list:${userId}`);
  }

  async setPuantajList(userId, puantajList) {
    return this.set(`puantaj:list:${userId}`, puantajList);
  }

  async invalidatePuantajCache(userId) {
    return this.delete(`puantaj:list:${userId}`);
  }

  // User cache methods
  async getUser(userId) {
    return this.get(`user:${userId}`);
  }

  async setUser(userId, userData) {
    return this.set(`user:${userId}`, userData);
  }

  async invalidateUserCache(userId) {
    return this.delete(`user:${userId}`);
  }

  // Auth token methods
  async setToken(userId, token, expireSeconds) {
    return this.set(`token:${userId}`, token, expireSeconds);
  }

  async getToken(userId) {
    return this.get(`token:${userId}`);
  }

  async invalidateToken(userId) {
    return this.delete(`token:${userId}`);
  }

  // Rate limiting methods
  async incrementRequestCount(ip) {
    const key = `ratelimit:${ip}`;
    try {
      if (this.redis) {
        const count = await this.redis.incr(key);
        if (count === 1) {
          await this.redis.expire(key, process.env.RATE_LIMIT_WINDOW_MS / 1000);
        }
        return count;
      } else {
        const item = this.inMemoryStore.get(key) || { count: 0, expiry: Date.now() + parseInt(process.env.RATE_LIMIT_WINDOW_MS) };
        item.count++;
        this.inMemoryStore.set(key, item);
        return item.count;
      }
    } catch (error) {
      console.warn('Rate limit increment hatası:', error);
      return 1;
    }
  }

  async getRequestCount(ip) {
    try {
      if (this.redis) {
        const count = await this.redis.get(`ratelimit:${ip}`);
        return parseInt(count) || 0;
      } else {
        const item = this.inMemoryStore.get(`ratelimit:${ip}`);
        if (!item || item.expiry < Date.now()) return 0;
        return item.count;
      }
    } catch (error) {
      console.warn('Rate limit get hatası:', error);
      return 0;
    }
  }

  // Socket.IO room management
  async addToRoom(roomId, userId) {
    const key = `room:${roomId}`;
    try {
      if (this.redis) {
        return this.redis.sadd(key, userId);
      } else {
        const members = this.inMemoryStore.get(key) || new Set();
        members.add(userId);
        this.inMemoryStore.set(key, members);
        return true;
      }
    } catch (error) {
      console.warn('Room add hatası:', error);
      return false;
    }
  }

  async removeFromRoom(roomId, userId) {
    const key = `room:${roomId}`;
    try {
      if (this.redis) {
        return this.redis.srem(key, userId);
      } else {
        const members = this.inMemoryStore.get(key);
        if (members) {
          members.delete(userId);
          return true;
        }
        return false;
      }
    } catch (error) {
      console.warn('Room remove hatası:', error);
      return false;
    }
  }

  async getRoomMembers(roomId) {
    const key = `room:${roomId}`;
    try {
      if (this.redis) {
        return this.redis.smembers(key);
      } else {
        const members = this.inMemoryStore.get(key);
        return members ? Array.from(members) : [];
      }
    } catch (error) {
      console.warn('Room members get hatası:', error);
      return [];
    }
  }

  // Health check
  async ping() {
    try {
      if (this.redis) {
        const result = await this.redis.ping();
        return result === 'PONG';
      }
      return true; // In-memory store is always available
    } catch (error) {
      console.warn('Health check hatası:', error);
      return false;
    }
  }

  // Cleanup methods
  async cleanup() {
    try {
      if (this.redis) {
        // Redis cleanup
        const tokenKeys = await this.redis.keys('token:*');
        for (const key of tokenKeys) {
          const ttl = await this.redis.ttl(key);
          if (ttl <= 0) await this.redis.del(key);
        }

        const rateLimitKeys = await this.redis.keys('ratelimit:*');
        for (const key of rateLimitKeys) {
          const ttl = await this.redis.ttl(key);
          if (ttl <= 0) await this.redis.del(key);
        }
      } else {
        // In-memory cleanup
        const now = Date.now();
        for (const [key, value] of this.inMemoryStore.entries()) {
          if (value.expiry && value.expiry < now) {
            this.inMemoryStore.delete(key);
          }
        }
      }
      return true;
    } catch (error) {
      console.warn('Cleanup hatası:', error);
      return false;
    }
  }
}

// Singleton instance
const redisService = new RedisService();

module.exports = redisService;
