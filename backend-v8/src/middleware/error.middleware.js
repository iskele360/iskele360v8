// Custom Error Class
class AppError extends Error {
  constructor(message, statusCode) {
    super(message);
    this.statusCode = statusCode;
    this.status = `${statusCode}`.startsWith('4') ? 'fail' : 'error';
    this.isOperational = true;

    Error.captureStackTrace(this, this.constructor);
  }
}

// Async Handler Wrapper
const catchAsync = fn => {
  return (req, res, next) => {
    Promise.resolve(fn(req, res, next)).catch(next);
  };
};

// Error Handler Middleware
const errorHandler = (err, req, res, next) => {
  err.statusCode = err.statusCode || 500;
  err.status = err.status || 'error';

  // Development Error Response
  if (process.env.NODE_ENV === 'development') {
    res.status(err.statusCode).json({
      status: err.status,
      error: err,
      message: err.message,
      stack: err.stack
    });
  } 
  // Production Error Response
  else {
    // Operational, trusted error: send message to client
    if (err.isOperational) {
      res.status(err.statusCode).json({
        status: err.status,
        message: err.message
      });
    }
    // Programming or other unknown error: don't leak error details
    else {
      // Log error
      console.error('❌ ERROR:', err);

      // Send generic message
      res.status(500).json({
        status: 'error',
        message: 'Bir şeyler yanlış gitti'
      });
    }
  }
};

// Not Found Handler
const notFound = (req, res, next) => {
  const err = new AppError(`${req.originalUrl} yolu bulunamadı`, 404);
  next(err);
};

// Validation Error Handler
const handleValidationError = (err) => {
  const errors = Object.values(err.errors).map(el => el.message);
  const message = `Geçersiz girdi: ${errors.join('. ')}`;
  return new AppError(message, 400);
};

// Cast Error Handler (for MongoDB)
const handleCastError = (err) => {
  const message = `Geçersiz ${err.path}: ${err.value}`;
  return new AppError(message, 400);
};

// Duplicate Field Error Handler
const handleDuplicateFieldsError = (err) => {
  const value = err.errmsg.match(/(["'])(\\?.)*?\1/)[0];
  const message = `Yinelenen alan değeri: ${value}. Lütfen başka bir değer kullanın.`;
  return new AppError(message, 400);
};

// JWT Error Handlers
const handleJWTError = () => 
  new AppError('Geçersiz token. Lütfen tekrar giriş yapın.', 401);

const handleJWTExpiredError = () => 
  new AppError('Token süresi doldu. Lütfen tekrar giriş yapın.', 401);

// Global Error Middleware
const globalErrorHandler = (err, req, res, next) => {
  let error = { ...err };
  error.message = err.message;

  // Mongoose Validation Error
  if (err.name === 'ValidationError') error = handleValidationError(err);
  
  // Mongoose CastError (Invalid ID)
  if (err.name === 'CastError') error = handleCastError(err);
  
  // Mongoose Duplicate Key Error
  if (err.code === 11000) error = handleDuplicateFieldsError(err);
  
  // JWT Invalid Token Error
  if (err.name === 'JsonWebTokenError') error = handleJWTError();
  
  // JWT Token Expired Error
  if (err.name === 'TokenExpiredError') error = handleJWTExpiredError();

  errorHandler(error, req, res, next);
};

// Rate Limit Error Handler
const handleRateLimitError = (req, res) => {
  res.status(429).json({
    status: 'error',
    message: 'Çok fazla istek yapıldı. Lütfen daha sonra tekrar deneyin.'
  });
};

// Multer Error Handler
const handleMulterError = (err, req, res, next) => {
  if (err.code === 'LIMIT_FILE_SIZE') {
    return next(new AppError('Dosya boyutu çok büyük. Maksimum boyut: 10MB', 400));
  }
  if (err.code === 'LIMIT_FILE_COUNT') {
    return next(new AppError('Çok fazla dosya. Maksimum dosya sayısı: 5', 400));
  }
  if (err.code === 'LIMIT_UNEXPECTED_FILE') {
    return next(new AppError('Beklenmeyen dosya tipi', 400));
  }
  next(err);
};

export {
  AppError,
  catchAsync,
  errorHandler,
  notFound,
  globalErrorHandler,
  handleRateLimitError,
  handleMulterError
};
