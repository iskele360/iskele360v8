const logger = require('../utils/logger');

const errorHandler = (err, req, res, next) => {
  logger.error(`Error: ${err.message}`);
  logger.error(err.stack);

  if (err.name === 'SequelizeValidationError') {
    return res.status(400).json({
      message: 'Validasyon hatası',
      errors: err.errors.map(e => ({
        field: e.path,
        message: e.message
      }))
    });
  }

  if (err.name === 'SequelizeUniqueConstraintError') {
    return res.status(409).json({
      message: 'Bu kayıt zaten mevcut',
      errors: err.errors.map(e => ({
        field: e.path,
        message: e.message
      }))
    });
  }

  return res.status(500).json({
    message: 'Sunucu hatası'
  });
};

module.exports = errorHandler; 