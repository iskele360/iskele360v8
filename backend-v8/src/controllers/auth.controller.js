import jwt from 'jsonwebtoken';
import { AppError, catchAsync } from '../middleware/error.middleware.js';
import redisService from '../services/redis.service.js';
import cloudinaryService from '../services/cloudinary.service.js';
import User from '../models/user.model.js';

// Generate JWT token
const generateToken = (id) => {
  return jwt.sign({ id }, process.env.JWT_SECRET, {
    expiresIn: process.env.JWT_EXPIRES_IN
  });
};

// Send response with token
const createSendToken = async (user, statusCode, res) => {
  const token = generateToken(user._id);

  // Store token in Redis
  await redisService.setToken(
    user._id.toString(),
    token,
    parseInt(process.env.JWT_EXPIRES_IN) * 24 * 60 * 60
  );

  // Update last login
  user.meta.lastLogin = new Date();
  await user.save({ validateBeforeSave: false });

  // Remove password from output
  user.password = undefined;

  res.status(statusCode).json({
    status: 'success',
    token,
    data: { user }
  });
};

// Register new user
export const register = catchAsync(async (req, res, next) => {
  const { firstName, lastName, email, password, role, phone } = req.body;

  // Check if email exists
  const existingUser = await User.findOne({ email: email?.toLowerCase() });
  if (existingUser) {
    return next(new AppError('Bu email adresi zaten kullanımda', 400));
  }

  // Create user
  const newUser = await User.create({
    firstName,
    lastName,
    email: email?.toLowerCase(),
    password,
    role: role || 'isci',
    phone,
    meta: {
      createdBy: req.user ? req.user._id : undefined
    }
  });

  // Upload avatar if provided
  if (req.file) {
    try {
      const result = await cloudinaryService.uploadProfileImage(req.file, newUser._id);
      newUser.avatar = {
        url: result.url,
        publicId: result.publicId
      };
      await newUser.save({ validateBeforeSave: false });
    } catch (error) {
      console.error('❌ Avatar yükleme hatası:', error);
    }
  }

  createSendToken(newUser, 201, res);
});

// Login user
export const login = catchAsync(async (req, res, next) => {
  const { email, password } = req.body;

  // Check if email and password exist
  if (!email || !password) {
    return next(new AppError('Lütfen email ve şifre girin', 400));
  }

  // Check if user exists && password is correct
  const user = await User.findOne({ email: email.toLowerCase() }).select('+password +isActive');

  if (!user || !(await user.comparePassword(password))) {
    return next(new AppError('Hatalı email veya şifre', 401));
  }

  // Check if user is active
  if (!user.isActive) {
    return next(new AppError('Bu hesap devre dışı bırakılmış', 401));
  }

  // Send token
  createSendToken(user, 200, res);
});

// Logout user
export const logout = catchAsync(async (req, res) => {
  // Invalidate token in Redis
  await redisService.invalidateToken(req.user._id.toString());

  res.status(200).json({
    status: 'success',
    message: 'Başarıyla çıkış yapıldı'
  });
});

// Update password
export const updatePassword = catchAsync(async (req, res, next) => {
  const { currentPassword, newPassword } = req.body;

  // Get user from collection
  const user = await User.findById(req.user._id).select('+password');

  // Check current password
  if (!(await user.comparePassword(currentPassword))) {
    return next(new AppError('Mevcut şifreniz yanlış', 401));
  }

  // Update password
  user.password = newPassword;
  await user.save();

  // Log in user with new password
  createSendToken(user, 200, res);
});

// Forgot password
export const forgotPassword = catchAsync(async (req, res, next) => {
  // Get user based on POSTed email
  const user = await User.findOne({ email: req.body.email.toLowerCase() });
  if (!user) {
    return next(new AppError('Bu email adresine sahip kullanıcı bulunamadı', 404));
  }

  // Generate random reset token
  const resetToken = user.createPasswordResetToken();
  await user.save({ validateBeforeSave: false });

  try {
    // TODO: Send email with reset token
    // For now, just send the token in response
    res.status(200).json({
      status: 'success',
      message: 'Şifre sıfırlama token\'ı email adresinize gönderildi',
      resetToken // Remove in production
    });
  } catch (err) {
    user.meta.passwordResetToken = undefined;
    user.meta.passwordResetExpires = undefined;
    await user.save({ validateBeforeSave: false });

    return next(new AppError('Email gönderilirken bir hata oluştu', 500));
  }
});

// Reset password
export const resetPassword = catchAsync(async (req, res, next) => {
  // Get user based on the token
  const hashedToken = crypto
    .createHash('sha256')
    .update(req.params.token)
    .digest('hex');

  const user = await User.findOne({
    'meta.passwordResetToken': hashedToken,
    'meta.passwordResetExpires': { $gt: Date.now() }
  });

  // If token has not expired, and there is user, set the new password
  if (!user) {
    return next(new AppError('Token geçersiz veya süresi dolmuş', 400));
  }

  user.password = req.body.password;
  user.meta.passwordResetToken = undefined;
  user.meta.passwordResetExpires = undefined;
  await user.save();

  // Log in user
  createSendToken(user, 200, res);
});

// Get current user
export const getMe = catchAsync(async (req, res, next) => {
  const user = await User.findById(req.user._id);
  
  res.status(200).json({
    status: 'success',
    data: { user }
  });
});

// Update current user
export const updateMe = catchAsync(async (req, res, next) => {
  // Create error if user POSTs password data
  if (req.body.password) {
    return next(new AppError('Bu route şifre güncellemek için değil. Lütfen /updatePassword kullanın.', 400));
  }

  // Filter unwanted fields
  const filteredBody = filterObj(req.body, 'firstName', 'lastName', 'email', 'phone');
  
  // Update user document
  const updatedUser = await User.findByIdAndUpdate(req.user._id, filteredBody, {
    new: true,
    runValidators: true
  });

  // Upload new avatar if provided
  if (req.file) {
    try {
      // Delete old avatar if exists
      if (updatedUser.avatar?.publicId) {
        await cloudinaryService.deleteFile(updatedUser.avatar.publicId);
      }

      const result = await cloudinaryService.uploadProfileImage(req.file, updatedUser._id);
      updatedUser.avatar = {
        url: result.url,
        publicId: result.publicId
      };
      await updatedUser.save({ validateBeforeSave: false });
    } catch (error) {
      console.error('❌ Avatar güncelleme hatası:', error);
    }
  }

  res.status(200).json({
    status: 'success',
    data: { user: updatedUser }
  });
});

// Helper function to filter object
const filterObj = (obj, ...allowedFields) => {
  const newObj = {};
  Object.keys(obj).forEach(el => {
    if (allowedFields.includes(el)) newObj[el] = obj[el];
  });
  return newObj;
};
