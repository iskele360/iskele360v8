const jwt = require('jsonwebtoken');
const User = require('../models/user.model');
const redisService = require('../services/redis.service');

exports.protect = async (req, res, next) => {
  try {
    // 1) Token'ı al
    let token;
    if (req.headers.authorization && req.headers.authorization.startsWith('Bearer')) {
      token = req.headers.authorization.split(' ')[1];
    }

    if (!token) {
      return res.status(401).json({
        status: 'error',
        message: 'Lütfen giriş yapın'
      });
    }

    // 2) Token'ı doğrula
    const decoded = jwt.verify(token, process.env.JWT_SECRET);

    // 3) Redis'ten token'ı kontrol et
    const cachedToken = await redisService.getToken(decoded.id);
    if (!cachedToken || cachedToken !== token) {
      return res.status(401).json({
        status: 'error',
        message: 'Token geçersiz veya süresi dolmuş'
      });
    }

    // 4) Kullanıcı hala var mı kontrol et
    const user = await User.findById(decoded.id);
    if (!user) {
      return res.status(401).json({
        status: 'error',
        message: 'Bu token\'a ait kullanıcı artık mevcut değil'
      });
    }

    // 5) Kullanıcı şifresini değiştirmiş mi kontrol et
    if (user.changedPasswordAfter(decoded.iat)) {
      return res.status(401).json({
        status: 'error',
        message: 'Kullanıcı yakın zamanda şifresini değiştirdi, lütfen tekrar giriş yapın'
      });
    }

    // 6) Kullanıcı aktif mi kontrol et
    if (!user.isActive) {
      return res.status(401).json({
        status: 'error',
        message: 'Bu hesap devre dışı bırakılmış'
      });
    }

    // Request'e kullanıcı bilgisini ekle
    req.user = user;
    next();
  } catch (error) {
    return res.status(401).json({
      status: 'error',
      message: 'Yetkilendirme hatası: ' + error.message
    });
  }
};

exports.restrictTo = (...roles) => {
  return (req, res, next) => {
    if (!roles.includes(req.user.role)) {
      return res.status(403).json({
        status: 'error',
        message: 'Bu işlem için yetkiniz yok'
      });
    }
    next();
  };
};

exports.isActive = (req, res, next) => {
  if (!req.user.isActive) {
    return res.status(403).json({
      status: 'error',
      message: 'Bu hesap devre dışı bırakılmış'
    });
  }
  next();
};

exports.checkOwnership = (paramIdField) => {
  return (req, res, next) => {
    const resourceId = req.params[paramIdField];
    if (req.user.role === 'admin') return next();
    
    if (resourceId !== req.user.id) {
      return res.status(403).json({
        status: 'error',
        message: 'Bu kaynağı görüntüleme/düzenleme yetkiniz yok'
      });
    }
    next();
  };
};

exports.rateLimiter = async (req, res, next) => {
  try {
    const ip = req.ip;
    const count = await redisService.incrementRequestCount(ip);
    
    if (count > parseInt(process.env.RATE_LIMIT_MAX_REQUESTS)) {
      return res.status(429).json({
        status: 'error',
        message: 'Çok fazla istek yapıldı, lütfen daha sonra tekrar deneyin'
      });
    }
    
    next();
  } catch (error) {
    next(error);
  }
};

exports.validateToken = async (req, res, next) => {
  try {
    const { token } = req.body;
    
    if (!token) {
      return res.status(400).json({
        status: 'error',
        message: 'Token gerekli'
      });
    }

    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    const user = await User.findById(decoded.id);

    if (!user) {
      return res.status(401).json({
        status: 'error',
        message: 'Geçersiz token'
      });
    }

    req.user = user;
    next();
  } catch (error) {
    return res.status(401).json({
      status: 'error',
      message: 'Token doğrulama hatası: ' + error.message
    });
  }
};

exports.requireDeviceToken = async (req, res, next) => {
  try {
    const { deviceToken, platform } = req.body;

    if (!deviceToken || !platform) {
      return res.status(400).json({
        status: 'error',
        message: 'Device token ve platform bilgisi gerekli'
      });
    }

    if (!['ios', 'android'].includes(platform)) {
      return res.status(400).json({
        status: 'error',
        message: 'Geçersiz platform'
      });
    }

    await req.user.addDeviceToken(deviceToken, platform);
    next();
  } catch (error) {
    next(error);
  }
};

exports.checkMaintenanceMode = (req, res, next) => {
  if (process.env.MAINTENANCE_MODE === 'true') {
    return res.status(503).json({
      status: 'error',
      message: process.env.MAINTENANCE_MESSAGE || 'Sistem bakımda'
    });
  }
  next();
};

exports.logRequest = (req, res, next) => {
  const start = Date.now();
  
  res.on('finish', () => {
    const duration = Date.now() - start;
    console.log(`${req.method} ${req.originalUrl} - ${res.statusCode} - ${duration}ms`);
    
    if (duration > parseInt(process.env.SLOW_QUERY_THRESHOLD_MS)) {
      console.warn(`Yavaş istek tespit edildi: ${req.method} ${req.originalUrl} - ${duration}ms`);
    }
  });
  
  next();
};
