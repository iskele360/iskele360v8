const express = require('express');
const router = express.Router();
const {
  registerPuantajci,
  registerWorkerOrSupplier,
  loginPuantajci,
  loginWorkerOrSupplier,
  protect
} = require('../controllers/authController');
const User = require('../models/User');

// Puantajcı routes
router.post('/puantajci/register', registerPuantajci);
router.post('/puantajci/login', loginPuantajci);

// İşçi ve malzemeci routes
router.post('/worker/register', registerWorkerOrSupplier);
router.post('/supplier/register', registerWorkerOrSupplier);
router.post('/code/login', loginWorkerOrSupplier);

// Protected routes
router.use(protect);

// Debug endpoint - Sadece geliştirme aşamasında kullanın
router.get('/debug/:email', async (req, res) => {
  try {
    const user = await User.findOne({ email: req.params.email }).select('+password');
    if (!user) {
      return res.status(404).json({ message: 'Kullanıcı bulunamadı' });
    }
    res.json({ user });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

module.exports = router; 