const rateLimit = require('express-rate-limit');
const config = require('../config');

const limiter = rateLimit({
  windowMs: config.rateLimiter.windowMs,
  max: config.rateLimiter.max,
  message: {
    status: 'error',
    message: 'Too many requests from this IP, please try again later.'
  }
});

module.exports = limiter; 