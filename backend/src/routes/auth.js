const express = require('express');
const authController = require('../controllers/authController');
const { verifyToken } = require('../middleware/verifyToken');

const router = express.Router();

// Kayıt ve giriş işlemleri
router.post('/register', authController.register);
router.post('/login', authController.login);

// Kullanıcı profili (token gerekli)
router.get('/profile', verifyToken, authController.getProfile);

module.exports = router; 