const { Redis } = require('@upstash/redis');
const config = require('./index');

const redis = new Redis({
  url: config.redis.url,
  token: config.redis.token
});

// Test the connection
redis.ping().then(() => {
  console.log('Redis Client Connected');
}).catch((err) => {
  console.error('Redis Client Error:', err);
});

module.exports = redis; 