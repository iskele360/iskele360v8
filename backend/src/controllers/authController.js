const jwt = require('jsonwebtoken');
const User = require('../models/User');
const config = require('../../config');
const validator = require('validator');
const redis = require('../services/redisService');
require('dotenv').config();

// JWT token oluşturma
const signToken = (id) => {
  return jwt.sign({ id }, config.JWT_SECRET, {
    expiresIn: config.JWT_EXPIRES_IN,
  });
};

// Token oluştur ve gönder
const createSendToken = (user, statusCode, res) => {
  const token = signToken(user._id);

  // Şifreyi yanıtta gösterme
  user.password = undefined;

  res.status(statusCode).json({
    status: 'success',
    token,
    data: {
      user,
    },
  });
};

// JWT Token oluşturma fonksiyonu
const generateToken = (user) => {
  return jwt.sign(
    { id: user.id, email: user.email, role: user.role },
    process.env.JWT_SECRET,
    { expiresIn: process.env.JWT_EXPIRES_IN }
  );
};

// Kullanıcı kaydı
const register = async (req, res) => {
  try {
    const { email, password, firstName, lastName } = req.body;

    // Check if user already exists
    const existingUser = await User.findOne({ where: { email } });
    if (existingUser) {
      return res.status(400).json({
        success: false,
        message: 'User already exists'
      });
    }

    // Create new user
    const user = await User.create({
      email,
      password,
      firstName,
      lastName,
      role: 'user'
    });

    // Generate token
    const token = generateToken(user);

    res.status(201).json({
      success: true,
      data: {
        user: user.toPublicJSON(),
        token
      }
    });
  } catch (error) {
    console.error('Registration error:', error);
    res.status(500).json({
      success: false,
      message: 'Error during registration'
    });
  }
};

// Kullanıcı girişi
const login = async (req, res) => {
  try {
    const { email, password } = req.body;

    // Find user
    const user = await User.findOne({ where: { email } });
    if (!user) {
      return res.status(401).json({
        success: false,
        message: 'Invalid credentials'
      });
    }

    // Check password
    const isMatch = await user.comparePassword(password);
    if (!isMatch) {
      return res.status(401).json({
        success: false,
        message: 'Invalid credentials'
      });
    }

    // Check if user is active
    if (!user.isActive) {
      return res.status(401).json({
        success: false,
        message: 'Account is disabled'
      });
    }

    // Generate token
    const token = generateToken(user);

    // Update last login
    user.lastLogin = new Date();
    await user.save();

    // Cache user data in Redis
    await redis.set(`user:${user.id}`, JSON.stringify(user.toPublicJSON()), 'EX', 3600); // 1 hour

    res.json({
      success: true,
      data: {
        user: user.toPublicJSON(),
        token
      }
    });
  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({
      success: false,
      message: 'Error during login'
    });
  }
};

const logout = async (req, res) => {
  try {
    // Remove user data from Redis
    await redis.del(`user:${req.user.id}`);

    res.json({
      success: true,
      message: 'Logged out successfully'
    });
  } catch (error) {
    console.error('Logout error:', error);
    res.status(500).json({
      success: false,
      message: 'Error during logout'
    });
  }
};

const me = async (req, res) => {
  try {
    // Try to get user from Redis first
    const cachedUser = await redis.get(`user:${req.user.id}`);
    if (cachedUser) {
      return res.json({
        success: true,
        data: JSON.parse(cachedUser)
      });
    }

    // If not in Redis, get from DB
    const user = await User.findByPk(req.user.id);
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    // Cache user data
    await redis.set(`user:${user.id}`, JSON.stringify(user.toPublicJSON()), 'EX', 3600);

    res.json({
      success: true,
      data: user.toPublicJSON()
    });
  } catch (error) {
    console.error('Get user error:', error);
    res.status(500).json({
      success: false,
      message: 'Error getting user data'
    });
  }
};

// Kullanıcı profili
const getProfile = async (req, res) => {
  try {
    const user = await User.findById(req.user._id);

    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'Kullanıcı bulunamadı'
      });
    }

    res.status(200).json({
      success: true,
      data: user
    });
  } catch (error) {
    console.error('Profil getirme hatası:', error);
    res.status(500).json({
      success: false,
      message: 'Sunucu hatası, lütfen daha sonra tekrar deneyin'
    });
  }
};

// Oturum doğrulama middleware
const protect = async (req, res, next) => {
  try {
    // 1) Token var mı kontrol et
    let token;
    if (
      req.headers.authorization &&
      req.headers.authorization.startsWith('Bearer')
    ) {
      token = req.headers.authorization.split(' ')[1];
    }

    if (!token) {
      return res.status(401).json({
        status: 'fail',
        message: 'Giriş yapmadınız. Lütfen giriş yapın.',
      });
    }

    // 2) Token doğrulama
    const decoded = jwt.verify(token, config.JWT_SECRET);

    // 3) Kullanıcı hala var mı kontrol et
    const currentUser = await User.findById(decoded.id);
    if (!currentUser) {
      return res.status(401).json({
        status: 'fail',
        message: 'Bu token\'a ait kullanıcı artık mevcut değil.',
      });
    }

    // Kullanıcıyı request'e ekle
    req.user = currentUser;
    next();
  } catch (err) {
    res.status(401).json({
      status: 'fail',
      message: 'Yetkilendirme hatası: ' + err.message,
    });
  }
};

// Rol bazlı yetkilendirme
const restrictTo = (...roles) => {
  return (req, res, next) => {
    if (!roles.includes(req.user.role)) {
      return res.status(403).json({
        status: 'fail',
        message: 'Bu işlemi yapmaya yetkiniz yok',
      });
    }
    next();
  };
};

module.exports = {
  register,
  login,
  logout,
  me,
  getProfile,
  protect,
  restrictTo
}; 