const jwt = require('jsonwebtoken');
const User = require('../models/User');

// Token doğrulama middleware
const verifyToken = async (req, res, next) => {
  try {
    // Header'dan token'ı al
    const authHeader = req.headers.authorization;
    
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({ 
        success: false, 
        message: 'Yetkilendirme tokeni bulunamadı' 
      });
    }
    
    // Bearer kısmını kaldırıp token'ı çıkar
    const token = authHeader.split(' ')[1];
    
    if (!token) {
      return res.status(401).json({ 
        success: false, 
        message: 'Geçersiz token formatı' 
      });
    }
    
    // Token'ı doğrula
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    
    // Kullanıcıyı bul
    const user = await User.findById(decoded.id);
    
    if (!user) {
      return res.status(401).json({ 
        success: false, 
        message: 'Kullanıcı bulunamadı' 
      });
    }
    
    // Kullanıcıyı request'e ekle
    req.user = user;
    next();
  } catch (error) {
    if (error.name === 'JsonWebTokenError') {
      return res.status(401).json({ 
        success: false, 
        message: 'Geçersiz token' 
      });
    }
    
    if (error.name === 'TokenExpiredError') {
      return res.status(401).json({ 
        success: false, 
        message: 'Token süresi doldu' 
      });
    }
    
    console.error('Token doğrulama hatası:', error);
    return res.status(500).json({ 
      success: false, 
      message: 'Sunucu hatası' 
    });
  }
};

// Puantajcı rolünü kontrol eden middleware
const isPuantajci = (req, res, next) => {
  if (req.user && req.user.role === 'puantajcı') {
    return next();
  }
  
  return res.status(403).json({ 
    success: false, 
    message: 'Bu işlem için yetkiniz bulunmamaktadır' 
  });
};

// Malzemeci rolünü kontrol eden middleware
const isMalzemeci = (req, res, next) => {
  if (req.user && req.user.role === 'malzemeci') {
    return next();
  }
  
  return res.status(403).json({ 
    success: false, 
    message: 'Bu işlem için yetkiniz bulunmamaktadır' 
  });
};

// Admin rolünü kontrol eden middleware
const isAdmin = (req, res, next) => {
  if (req.user && req.user.role === 'admin') {
    return next();
  }
  
  return res.status(403).json({ 
    success: false, 
    message: 'Bu işlem için yetkiniz bulunmamaktadır' 
  });
};

module.exports = {
  verifyToken,
  isPuantajci,
  isMalzemeci,
  isAdmin
}; 