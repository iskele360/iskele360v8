const express = require('express');
const userController = require('../controllers/userController');
const authController = require('../controllers/authController');

const router = express.Router();

// Tüm rotalar için kimlik doğrulama gerekli
router.use(authController.protect);

// Kullanıcı profili
router.get('/me', userController.getMe);

// Puantajcı tarafından işçi ve malzemeci oluşturma
router.post('/worker', authController.restrictTo('puantajci'), userController.createWorker);
router.post('/material-manager', authController.restrictTo('puantajci'), userController.createMaterialManager);

// Puantajcının kendi işçi ve malzemecilerini getirme
router.get('/workers', authController.restrictTo('puantajci'), userController.getMyWorkers);
router.get('/material-managers', authController.restrictTo('puantajci'), userController.getMyMaterialManagers);

module.exports = router; 