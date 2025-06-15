const { Redis } = require('@upstash/redis');
require('dotenv').config();

module.exports = new Redis({
  url: process.env.UPSTASH_REDIS_REST_URL,
  token: process.env.UPSTASH_REDIS_REST_TOKEN
}); 