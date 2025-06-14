const Redis = require('ioredis');
const logger = require('../utils/logger');

const redisConfig = {
  host: process.env.REDIS_HOST || 'red-cjvvvvvvvvvvvvvvvvvvvvvvvv.redis.render.com',
  port: process.env.REDIS_PORT || 6379,
  username: process.env.REDIS_USERNAME || 'red-cjvvvvvvvvvvvvvvvvvvvvvvvv',
  password: process.env.REDIS_PASSWORD,
  tls: process.env.NODE_ENV === 'production' ? {} : undefined
};

const redis = new Redis(redisConfig);

redis.on('connect', () => {
  logger.info('Redis bağlantısı başarılı');
});

redis.on('error', (error) => {
  logger.error('Redis bağlantı hatası:', error);
});

module.exports = redis; 