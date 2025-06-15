const jwt = require('jsonwebtoken');
const User = require('../models/User');
const config = require('../../config');
const validator = require('validator');
const redis = require('../services/redisService');
const bcrypt = require('bcryptjs');
require('dotenv').config();

// JWT token oluşturma
const signToken = (id) => {
  return jwt.sign({ id }, process.env.JWT_SECRET, {
    expiresIn: process.env.JWT_EXPIRES_IN,
  });
};

// Token oluştur ve gönder
const createSendToken = (user, statusCode, res) => {
  const token = signToken(user._id);

  // Şifreyi yanıtta gösterme
  user.password = undefined;

  res.status(statusCode).json({
    success: true,
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

// Puantajcı kaydı
const registerPuantajci = async (req, res) => {
  try {
    const { name, email, password } = req.body;

    // Validation
    if (!email || !password || !name) {
      return res.status(400).json({
        success: false,
        message: 'Lütfen tüm alanları doldurun'
      });
    }

    // Email format kontrolü
    if (!email.includes('@')) {
      return res.status(400).json({
        success: false,
        message: 'Geçerli bir email adresi girin'
      });
    }

    // Email kullanımda mı kontrolü
    const existingUser = await User.findOne({ email });
    if (existingUser) {
      return res.status(400).json({
        success: false,
        message: 'Bu email adresi zaten kullanımda'
      });
    }

    // Yeni puantajcı oluştur
    const user = await User.create({
      name,
      email,
      password,
      role: 'puantajci'
    });

    // Token oluştur ve gönder
    createSendToken(user, 201, res);
  } catch (error) {
    console.error('Kayıt hatası:', error);
    res.status(500).json({
      success: false,
      message: 'Kayıt sırasında bir hata oluştu'
    });
  }
};

// İşçi veya malzemeci kaydı
const registerWorkerOrSupplier = async (req, res) => {
  try {
    const { name, role } = req.body;

    if (!name || !['isci', 'malzemeci'].includes(role)) {
      return res.status(400).json({
        success: false,
        message: 'Geçersiz bilgiler'
      });
    }

    // Benzersiz kod oluştur
    const code = await User.generateUniqueCode(role);

    // Yeni kullanıcı oluştur
    const user = await User.create({
      name,
      role,
      code,
      createdBy: req.user._id // Oluşturan puantajcının ID'si
    });

    res.status(201).json({
      success: true,
      data: {
        user: user.toPublicJSON(),
        code // Kodu sadece kayıt sırasında göster
      },
      message: `${role === 'isci' ? 'İşçi' : 'Malzemeci'} başarıyla kaydedildi. Kod: ${code}`
    });
  } catch (error) {
    console.error('Kayıt hatası:', error);
    res.status(500).json({
      success: false,
      message: 'Kayıt sırasında bir hata oluştu'
    });
  }
};

// Puantajcı girişi
const loginPuantajci = async (req, res) => {
  try {
    const { email, password } = req.body;

    // Email ve şifre var mı kontrol et
    if (!email || !password) {
      return res.status(400).json({
        success: false,
        message: 'Lütfen email ve şifre girin'
      });
    }

    // Kullanıcıyı bul ve şifreyi kontrol et
    const user = await User.findOne({ email, role: 'puantajci' }).select('+password');
    if (!user || !(await user.comparePassword(password))) {
      return res.status(401).json({
        success: false,
        message: 'Email veya şifre hatalı'
      });
    }

    // Token oluştur ve gönder
    createSendToken(user, 200, res);
  } catch (error) {
    console.error('Giriş hatası:', error);
    res.status(500).json({
      success: false,
      message: 'Giriş sırasında bir hata oluştu'
    });
  }
};

// İşçi veya malzemeci girişi
const loginWorkerOrSupplier = async (req, res) => {
  try {
    const { code } = req.body;

    if (!code) {
      return res.status(400).json({
        success: false,
        message: 'Lütfen kod girin'
      });
    }

    // Kullanıcıyı bul ve kodu kontrol et
    const user = await User.findOne({ 
      code,
      role: code.startsWith('W') ? 'isci' : 'malzemeci'
    });

    if (!user || !user.compareCode(code)) {
      return res.status(401).json({
        success: false,
        message: 'Geçersiz kod'
      });
    }

    // Token oluştur ve gönder
    createSendToken(user, 200, res);
  } catch (error) {
    console.error('Giriş hatası:', error);
    res.status(500).json({
      success: false,
      message: 'Giriş sırasında bir hata oluştu'
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
  registerPuantajci,
  registerWorkerOrSupplier,
  loginPuantajci,
  loginWorkerOrSupplier,
  logout,
  me,
  getProfile,
  protect,
  restrictTo
}; 