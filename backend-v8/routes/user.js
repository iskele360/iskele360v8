const express = require('express');
const userController = require('../controllers/userController');
const { verifyToken, isPuantajci, isAdmin } = require('../middleware/verifyToken');
const authController = require('../controllers/authController');

const router = express.Router();

// Middleware'ler
const { protect, restrictTo } = authController;

// Tüm rotalar için token doğrulama gerekli
router.use(verifyToken);

// Kullanıcı silme işlemleri
router.delete('/delete', userController.deleteSelf);
router.delete('/delete/:userId', isPuantajci, userController.deleteUser);

// Kullanıcı profil güncelleme
router.put('/update', userController.updateProfile);
router.put('/update-password', userController.updatePassword);

// Kullanıcı listeleme (sadece puantajcı ve admin)
router.get('/', userController.getAllUsers);

// Protect all routes after this middleware
router.use(protect);

// Puantajcı rotaları
router.get('/workers', restrictTo('puantajci'), userController.getWorkers);
router.get('/suppliers', restrictTo('puantajci'), userController.getSuppliers);

// İşçi ve malzemeci yönetimi
router.post('/worker', restrictTo('puantajci'), userController.createWorker);
router.post('/supplier', restrictTo('puantajci'), userController.createSupplier);
router.delete('/:userId', restrictTo('puantajci'), userController.deleteUser);

// Profil yönetimi
router.get('/me', userController.getMe);
router.patch('/me', userController.updateMe);

module.exports = router; 