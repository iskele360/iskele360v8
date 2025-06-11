const jwt = require('jsonwebtoken');
const User = require('../models/User');
const config = require('../../config');
const validator = require('validator');

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
const generateToken = (id) => {
  return jwt.sign({ id }, process.env.JWT_SECRET, {
    expiresIn: '30d'
  });
};

// Kullanıcı kaydı
exports.register = async (req, res) => {
  try {
    const { name, surname, email, password, role } = req.body;

    // Gerekli alanların kontrolü
    if (!name || !surname || !email || !password) {
      return res.status(400).json({
        success: false,
        message: 'Lütfen tüm zorunlu alanları doldurun'
      });
    }

    // E-posta formatı kontrolü
    if (!validator.isEmail(email)) {
      return res.status(400).json({
        success: false,
        message: 'Geçerli bir e-posta adresi girin'
      });
    }

    // Şifre uzunluk kontrolü
    if (password.length < 6) {
      return res.status(400).json({
        success: false,
        message: 'Şifre en az 6 karakter olmalıdır'
      });
    }

    // E-postanın zaten kayıtlı olup olmadığını kontrol et
    const existingUser = await User.findOne({ email });

    if (existingUser) {
      return res.status(400).json({
        success: false,
        message: 'Bu e-posta adresi zaten kullanılıyor'
      });
    }

    // Puantajcı oluşturan kişinin bilgilerini ekle
    let userData = {
      name,
      surname,
      email,
      password,
      role: role || 'puantajcı' // Varsayılan olarak puantajcı
    };

    // Eğer token ile giriş yapmış bir kullanıcı varsa ve işçi veya malzemeci oluşturuyorsa
    if (req.user && (role === 'isci' || role === 'malzemeci')) {
      userData.createdBy = req.user._id;
      userData.supervisorId = req.user._id;
      
      // İşçi veya malzemeci için benzersiz kod oluştur
      if (role === 'isci') {
        // 6 haneli rastgele kod
        userData.code = Math.floor(100000 + Math.random() * 900000).toString();
      } else if (role === 'malzemeci') {
        // 8 haneli rastgele kod
        userData.code = Math.floor(10000000 + Math.random() * 90000000).toString();
      }
    }

    // Yeni kullanıcı oluştur
    const user = await User.create(userData);

    // Başarılı yanıt
    res.status(201).json({
      success: true,
      token: generateToken(user._id),
      data: user
    });
  } catch (error) {
    console.error('Kayıt hatası:', error);
    res.status(500).json({
      success: false,
      message: 'Sunucu hatası, lütfen daha sonra tekrar deneyin'
    });
  }
};

// Kullanıcı girişi
exports.login = async (req, res) => {
  try {
    const { email, password, code } = req.body;

    // E-posta veya kod ile giriş kontrolü
    if ((!email && !code) || !password) {
      return res.status(400).json({
        success: false,
        message: 'Lütfen giriş bilgilerinizi girin'
      });
    }

    let user;

    // E-posta veya kod ile kullanıcıyı bul
    if (email) {
      user = await User.findOne({ email });
    } else if (code) {
      user = await User.findOne({ code });
    }

    // Kullanıcı bulunamadı
    if (!user) {
      return res.status(401).json({
        success: false,
        message: 'Geçersiz giriş bilgileri'
      });
    }

    // Şifre kontrolü
    const isPasswordCorrect = await user.comparePassword(password);

    if (!isPasswordCorrect) {
      return res.status(401).json({
        success: false,
        message: 'Geçersiz giriş bilgileri'
      });
    }

    // Başarılı yanıt
    res.status(200).json({
      success: true,
      token: generateToken(user._id),
      data: user
    });
  } catch (error) {
    console.error('Giriş hatası:', error);
    res.status(500).json({
      success: false,
      message: 'Sunucu hatası, lütfen daha sonra tekrar deneyin'
    });
  }
};

// Kullanıcı profili
exports.getProfile = async (req, res) => {
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
exports.protect = async (req, res, next) => {
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
exports.restrictTo = (...roles) => {
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