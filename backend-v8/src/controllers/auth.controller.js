const jwt = require('jsonwebtoken');
const User = require('../models/user.model');
const { AppError, catchAsync } = require('../middleware/error.middleware');
const redisService = require('../services/redis.service');

const generateToken = (id) => {
  return jwt.sign({ id }, process.env.JWT_SECRET, {
    expiresIn: process.env.JWT_EXPIRES_IN
  });
};

const createSendToken = async (user, statusCode, res) => {
  const token = generateToken(user._id);

  // Token'ı Redis'e kaydet
  await redisService.setToken(
    user._id.toString(),
    token,
    parseInt(process.env.JWT_EXPIRES_IN) * 24 * 60 * 60
  );

  // Son giriş tarihini güncelle
  user.lastLogin = new Date();
  await user.save({ validateBeforeSave: false });

  // Password'ü response'dan çıkar
  user.password = undefined;

  res.status(statusCode).json({
    status: 'success',
    token,
    data: {
      user
    }
  });
};

exports.register = catchAsync(async (req, res, next) => {
  const { firstName, lastName, email, password, role } = req.body;

  // Email veya kod ile kayıt kontrolü
  if (email) {
    const existingUser = await User.findOne({ email: email.toLowerCase() });
    if (existingUser) {
      return next(new AppError('Bu email adresi zaten kullanımda', 400));
    }
  }

  // Yeni kullanıcı oluştur
  const newUser = await User.create({
    firstName,
    lastName,
    email: email?.toLowerCase(),
    password,
    role: role || 'isci',
    meta: {
      createdBy: req.user ? req.user._id : undefined
    }
  });

  createSendToken(newUser, 201, res);
});

exports.login = catchAsync(async (req, res, next) => {
  const { email, code, password } = req.body;

  // 1) Email/kod ve şifre var mı kontrol et
  if ((!email && !code) || !password) {
    return next(new AppError('Lütfen email/kod ve şifre girin', 400));
  }

  // 2) Kullanıcıyı bul
  let user;
  if (email) {
    user = await User.findOne({ email: email.toLowerCase() }).select('+password');
  } else if (code) {
    user = await User.findOne({ code }).select('+password');
  }

  // 3) Kullanıcı var mı ve şifre doğru mu kontrol et
  if (!user || !(await user.comparePassword(password))) {
    return next(new AppError('Hatalı email/kod veya şifre', 401));
  }

  // 4) Kullanıcı aktif mi kontrol et
  if (!user.isActive) {
    return next(new AppError('Bu hesap devre dışı bırakılmış', 401));
  }

  // 5) Token oluştur ve gönder
  createSendToken(user, 200, res);
});

exports.logout = catchAsync(async (req, res) => {
  // Redis'ten token'ı sil
  await redisService.invalidateToken(req.user._id.toString());

  res.status(200).json({
    status: 'success',
    message: 'Başarıyla çıkış yapıldı'
  });
});

exports.protect = catchAsync(async (req, res, next) => {
  // 1) Token var mı kontrol et
  let token;
  if (req.headers.authorization?.startsWith('Bearer')) {
    token = req.headers.authorization.split(' ')[1];
  }

  if (!token) {
    return next(new AppError('Lütfen giriş yapın', 401));
  }

  // 2) Token'ı doğrula
  const decoded = jwt.verify(token, process.env.JWT_SECRET);

  // 3) Redis'ten token'ı kontrol et
  const cachedToken = await redisService.getToken(decoded.id);
  if (!cachedToken || cachedToken !== token) {
    return next(new AppError('Token geçersiz veya süresi dolmuş', 401));
  }

  // 4) Kullanıcı hala var mı kontrol et
  const user = await User.findById(decoded.id);
  if (!user) {
    return next(new AppError('Bu token\'a ait kullanıcı artık mevcut değil', 401));
  }

  // 5) Şifre değiştirilmiş mi kontrol et
  if (user.changedPasswordAfter(decoded.iat)) {
    return next(new AppError('Kullanıcı yakın zamanda şifresini değiştirdi, lütfen tekrar giriş yapın', 401));
  }

  // 6) Kullanıcıyı request'e ekle
  req.user = user;
  next();
});

exports.updatePassword = catchAsync(async (req, res, next) => {
  const { currentPassword, newPassword } = req.body;

  // 1) Kullanıcıyı bul
  const user = await User.findById(req.user._id).select('+password');

  // 2) Mevcut şifreyi kontrol et
  if (!(await user.comparePassword(currentPassword))) {
    return next(new AppError('Mevcut şifreniz yanlış', 401));
  }

  // 3) Şifreyi güncelle
  user.password = newPassword;
  await user.save();

  // 4) Yeni token oluştur ve gönder
  createSendToken(user, 200, res);
});

exports.forgotPassword = catchAsync(async (req, res, next) => {
  // 1) Email ile kullanıcıyı bul
  const user = await User.findOne({ email: req.body.email.toLowerCase() });
  if (!user) {
    return next(new AppError('Bu email adresine sahip kullanıcı bulunamadı', 404));
  }

  // 2) Reset token oluştur
  const resetToken = user.createPasswordResetToken();
  await user.save({ validateBeforeSave: false });

  // 3) Email gönder
  try {
    // TODO: Email gönderme işlemi implement edilecek
    res.status(200).json({
      status: 'success',
      message: 'Şifre sıfırlama token\'ı email adresinize gönderildi',
      resetToken // Geliştirme aşamasında token'ı response'da gönder
    });
  } catch (err) {
    user.passwordResetToken = undefined;
    user.passwordResetExpires = undefined;
    await user.save({ validateBeforeSave: false });

    return next(new AppError('Email gönderilirken bir hata oluştu', 500));
  }
});

exports.resetPassword = catchAsync(async (req, res, next) => {
  // 1) Token'a göre kullanıcıyı bul
  const hashedToken = crypto
    .createHash('sha256')
    .update(req.params.token)
    .digest('hex');

  const user = await User.findOne({
    passwordResetToken: hashedToken,
    passwordResetExpires: { $gt: Date.now() }
  });

  // 2) Token geçerli ve kullanıcı varsa, şifreyi güncelle
  if (!user) {
    return next(new AppError('Token geçersiz veya süresi dolmuş', 400));
  }

  user.password = req.body.password;
  user.passwordResetToken = undefined;
  user.passwordResetExpires = undefined;
  await user.save();

  // 3) Kullanıcıyı giriş yap
  createSendToken(user, 200, res);
});

exports.validateToken = catchAsync(async (req, res) => {
  res.status(200).json({
    status: 'success',
    message: 'Token geçerli',
    data: {
      user: req.user
    }
  });
});
