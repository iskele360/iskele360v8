const express = require('express');
const puantajController = require('../controllers/puantajController');
const { verifyToken, isPuantajci } = require('../middleware/verifyToken');

const router = express.Router();

// Tüm rotalar için token doğrulama gerekli
router.use(verifyToken);

// Dashboard verilerini getir (optimize edilmiş, paralel sorgular)
router.get('/dashboard', isPuantajci, puantajController.getDashboardData);

// İstatistik verileri (aggregation pipeline kullanır)
router.get('/stats', isPuantajci, puantajController.getPuantajStats);

// Puantaj kaydı oluşturma (sadece puantajcı)
router.post('/', isPuantajci, puantajController.createPuantaj);

// Puantaj kaydı güncelleme (sadece puantajcı)
router.put('/:id', isPuantajci, puantajController.updatePuantaj);

// Puantaj kaydı silme (sadece puantajcı)
router.delete('/:id', isPuantajci, puantajController.deletePuantaj);

// İşçinin puantaj kayıtlarını getirme (sayfalı)
router.get('/isci/:isciId', puantajController.getIsciPuantajlari);

// Puantajcının tüm puantaj kayıtlarını getirme (sayfalı, filtreli)
router.get('/puantajci', isPuantajci, puantajController.getPuantajciPuantajlari);
router.get('/puantajci/:puantajciId', isPuantajci, puantajController.getPuantajciPuantajlari);

// Get all puantaj records
router.get('/', puantajController.getAllPuantaj);

// Get puantaj by ID
router.get('/:id', puantajController.getPuantajById);

// Approve puantaj (manager only)
router.post('/:id/approve', puantajController.approvePuantaj);

// Reject puantaj (manager only)
router.post('/:id/reject', puantajController.rejectPuantaj);

// Get user's puantaj records
router.get('/user/:userId', puantajController.getUserPuantaj);

// Get puantaj statistics
router.get('/stats/overview', puantajController.getPuantajStats);

module.exports = router; 