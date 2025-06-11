const jwt = require('jsonwebtoken');
const User = require('../models/User');
const config = require('../../config');

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

// Kayıt olma
exports.signup = async (req, res) => {
  try {
    // Sadece puantajcı rolünde kayıt olabilir, diğer roller puantajcı tarafından oluşturulur
    const newUser = await User.create({
      name: req.body.name,
      surname: req.body.surname,
      email: req.body.email,
      password: req.body.password,
      role: 'puantajci', // Doğrudan kayıt olanlar sadece puantajcı olabilir
    });

    createSendToken(newUser, 201, res);
  } catch (err) {
    res.status(400).json({
      status: 'fail',
      message: err.message,
    });
  }
};

// Giriş yapma
exports.login = async (req, res) => {
  try {
    const { email, password, code } = req.body;

    // 1) Email/kod ve şifre var mı kontrol et
    if ((!email && !code) || !password) {
      return res.status(400).json({
        status: 'fail',
        message: 'Lütfen email/kod ve şifre girin',
      });
    }

    // 2) Kullanıcı var mı ve şifre doğru mu kontrol et
    const query = code ? { code } : { email };
    const user = await User.findOne(query).select('+password');

    if (!user || !(await user.correctPassword(password, user.password))) {
      return res.status(401).json({
        status: 'fail',
        message: 'Email/kod veya şifre hatalı',
      });
    }

    // 3) Her şey yolundaysa token gönder
    createSendToken(user, 200, res);
  } catch (err) {
    res.status(400).json({
      status: 'fail',
      message: err.message,
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