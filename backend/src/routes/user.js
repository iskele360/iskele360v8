const express = require('express');
const userController = require('../controllers/userController');
const { verifyToken, isPuantajci, isAdmin } = require('../middleware/verifyToken');

const router = express.Router();

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

module.exports = router; 