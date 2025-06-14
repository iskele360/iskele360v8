const rateLimit = require('express-rate-limit');

const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 dakika
  max: 100, // IP başına maksimum istek sayısı
  message: {
    message: 'Çok fazla istek gönderdiniz. Lütfen daha sonra tekrar deneyin.'
  }
});

module.exports = limiter; 