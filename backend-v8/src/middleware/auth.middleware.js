import jwt from 'jsonwebtoken';
import { AppError, catchAsync } from './error.middleware.js';
import redisService from '../services/redis.service.js';
import User from '../models/user.model.js';

// Protect routes - Authentication check
const protect = catchAsync(async (req, res, next) => {
  // 1) Get token from header
  let token;
  if (req.headers.authorization?.startsWith('Bearer')) {
    token = req.headers.authorization.split(' ')[1];
  }

  if (!token) {
    return next(new AppError('Lütfen giriş yapın', 401));
  }

  try {
    // 2) Verify token
    const decoded = jwt.verify(token, process.env.JWT_SECRET);

    // 3) Check if token is in Redis (valid session)
    const cachedToken = await redisService.getToken(decoded.id);
    if (!cachedToken || cachedToken !== token) {
      return next(new AppError('Oturum geçersiz veya sona erdi', 401));
    }

    // 4) Check if user still exists
    const user = await User.findById(decoded.id).select('+role +isActive');
    if (!user) {
      return next(new AppError('Bu token\'a ait kullanıcı artık mevcut değil', 401));
    }

    // 5) Check if user is active
    if (!user.isActive) {
      return next(new AppError('Bu hesap devre dışı bırakılmış', 401));
    }

    // Grant access to protected route
    req.user = user;
    next();
  } catch (error) {
    if (error.name === 'JsonWebTokenError') {
      return next(new AppError('Geçersiz token', 401));
    }
    if (error.name === 'TokenExpiredError') {
      return next(new AppError('Token süresi doldu', 401));
    }
    next(error);
  }
});

// Restrict to certain roles
const restrictTo = (...roles) => {
  return (req, res, next) => {
    if (!roles.includes(req.user.role)) {
      return next(new AppError('Bu işlem için yetkiniz yok', 403));
    }
    next();
  };
};

// Check ownership
const checkOwnership = (Model, paramField = 'id') => {
  return catchAsync(async (req, res, next) => {
    const doc = await Model.findById(req.params[paramField]);

    if (!doc) {
      return next(new AppError('Kayıt bulunamadı', 404));
    }

    // Allow admins to access any record
    if (req.user.role === 'admin') {
      return next();
    }

    // Check if the user owns the record
    if (doc.userId?.toString() !== req.user._id.toString()) {
      return next(new AppError('Bu kayıt üzerinde işlem yapma yetkiniz yok', 403));
    }

    req.doc = doc;
    next();
  });
};

// Rate limiting per user
const userRateLimit = async (req, userId, limit, windowMs) => {
  const key = `rate_limit:${userId}:${req.originalUrl}`;
  const count = await redisService.incrementRateLimit(key, windowMs / 1000);
  
  if (count > limit) {
    throw new AppError('Çok fazla istek yapıldı. Lütfen daha sonra tekrar deneyin.', 429);
  }
};

// Validate active session
const validateSession = catchAsync(async (req, res, next) => {
  const sessionId = req.headers['x-session-id'];
  
  if (!sessionId) {
    return next(new AppError('Oturum ID\'si bulunamadı', 401));
  }

  const session = await redisService.getSession(sessionId);
  
  if (!session) {
    return next(new AppError('Geçersiz veya süresi dolmuş oturum', 401));
  }

  req.session = session;
  next();
});

// Check if user has required permissions
const hasPermission = (permission) => {
  return catchAsync(async (req, res, next) => {
    const user = await User.findById(req.user._id).select('+permissions');

    if (!user.permissions?.includes(permission)) {
      return next(new AppError(`Bu işlem için '${permission}' yetkisi gerekiyor`, 403));
    }

    next();
  });
};

// Validate API key for external services
const validateApiKey = catchAsync(async (req, res, next) => {
  const apiKey = req.headers['x-api-key'];

  if (!apiKey) {
    return next(new AppError('API anahtarı bulunamadı', 401));
  }

  // Check if API key is valid in Redis
  const isValid = await redisService.getCache(`api_key:${apiKey}`);
  
  if (!isValid) {
    return next(new AppError('Geçersiz API anahtarı', 401));
  }

  next();
});

// Log authentication attempts
const logAuthAttempt = catchAsync(async (req, res, next) => {
  const { email, ip } = req;
  const key = `auth_attempts:${ip}:${email}`;
  const attempts = await redisService.incrementRateLimit(key, 3600); // 1 hour window

  if (attempts > 5) {
    return next(new AppError('Çok fazla başarısız giriş denemesi. Lütfen daha sonra tekrar deneyin.', 429));
  }

  next();
});

export {
  protect,
  restrictTo,
  checkOwnership,
  userRateLimit,
  validateSession,
  hasPermission,
  validateApiKey,
  logAuthAttempt
};
