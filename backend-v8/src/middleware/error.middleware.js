const mongoose = require('mongoose');

class AppError extends Error {
  constructor(message, statusCode) {
    super(message);
    this.statusCode = statusCode;
    this.status = `${statusCode}`.startsWith('4') ? 'fail' : 'error';
    this.isOperational = true;

    Error.captureStackTrace(this, this.constructor);
  }
}

const handleCastErrorDB = err => {
  const message = `Geçersiz ${err.path}: ${err.value}`;
  return new AppError(message, 400);
};

const handleDuplicateFieldsDB = err => {
  const value = err.errmsg.match(/(["'])(\\?.)*?\1/)[0];
  const message = `${value} değeri zaten kullanımda. Lütfen başka bir değer girin.`;
  return new AppError(message, 400);
};

const handleValidationErrorDB = err => {
  const errors = Object.values(err.errors).map(el => el.message);
  const message = `Geçersiz veri girişi. ${errors.join('. ')}`;
  return new AppError(message, 400);
};

const handleJWTError = () =>
  new AppError('Geçersiz token. Lütfen tekrar giriş yapın.', 401);

const handleJWTExpiredError = () =>
  new AppError('Token süresi doldu. Lütfen tekrar giriş yapın.', 401);

const handleMulterError = err => {
  if (err.code === 'LIMIT_FILE_SIZE') {
    return new AppError('Dosya boyutu çok büyük. Maksimum boyut: 5MB', 400);
  }
  if (err.code === 'LIMIT_FILE_COUNT') {
    return new AppError('Çok fazla dosya. Maksimum dosya sayısı: 5', 400);
  }
  if (err.code === 'LIMIT_UNEXPECTED_FILE') {
    return new AppError('Beklenmeyen dosya tipi', 400);
  }
  return new AppError('Dosya yükleme hatası', 400);
};

const sendErrorDev = (err, req, res) => {
  return res.status(err.statusCode).json({
    status: err.status,
    error: err,
    message: err.message,
    stack: err.stack
  });
};

const sendErrorProd = (err, req, res) => {
  // Operational, trusted error: send message to client
  if (err.isOperational) {
    return res.status(err.statusCode).json({
      status: err.status,
      message: err.message
    });
  }
  
  // Programming or other unknown error: don't leak error details
  console.error('ERROR 💥', err);
  return res.status(500).json({
    status: 'error',
    message: 'Bir şeyler yanlış gitti!'
  });
};

const errorHandler = (err, req, res, next) => {
  err.statusCode = err.statusCode || 500;
  err.status = err.status || 'error';

  if (process.env.NODE_ENV === 'development') {
    sendErrorDev(err, req, res);
  } else {
    let error = { ...err };
    error.message = err.message;

    if (error instanceof mongoose.Error.CastError) error = handleCastErrorDB(error);
    if (error.code === 11000) error = handleDuplicateFieldsDB(error);
    if (error instanceof mongoose.Error.ValidationError) error = handleValidationErrorDB(error);
    if (error.name === 'JsonWebTokenError') error = handleJWTError();
    if (error.name === 'TokenExpiredError') error = handleJWTExpiredError();
    if (error.name === 'MulterError') error = handleMulterError(error);

    sendErrorProd(error, req, res);
  }
};

// Async error wrapper
const catchAsync = fn => {
  return (req, res, next) => {
    fn(req, res, next).catch(next);
  };
};

// Not Found handler
const notFound = (req, res, next) => {
  const error = new AppError(`${req.originalUrl} yolu bulunamadı`, 404);
  next(error);
};

// Unhandled route handler
const unhandledRoute = (req, res) => {
  res.status(404).json({
    status: 'error',
    message: `${req.originalUrl} yolu bulunamadı`
  });
};

// Validation error handler
const validationError = (err, req, res, next) => {
  if (err.name === 'ValidationError') {
    return res.status(400).json({
      status: 'error',
      message: err.message
    });
  }
  next(err);
};

module.exports = {
  AppError,
  errorHandler,
  catchAsync,
  notFound,
  unhandledRoute,
  validationError
};
