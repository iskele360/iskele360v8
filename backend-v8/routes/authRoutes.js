const express = require('express');
const authController = require('../controllers/authController');

const router = express.Router();

// Kayıt ve giriş rotaları
router.post('/signup', authController.signup);
router.post('/login', authController.login);

module.exports = router; 