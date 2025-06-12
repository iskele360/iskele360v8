import express from 'express';
import multer from 'multer';
import {
  createPuantaj,
  recordExit,
  cancelPuantaj,
  getWorkerDailyRecords,
  getWorkerMonthlyStats,
  getDailyProjectStats,
  getRecordsByLocation
} from '../controllers/puantaj.controller.js';
import { protect, restrictTo } from '../middleware/auth.middleware.js';
import { handleMulterError } from '../middleware/error.middleware.js';

const router = express.Router();

// Multer configuration for file uploads
const upload = multer({
  storage: multer.diskStorage({}),
  limits: {
    fileSize: 5 * 1024 * 1024 // 5MB limit
  },
  fileFilter: (req, file, cb) => {
    if (!file.mimetype.startsWith('image/')) {
      return cb(new Error('Sadece resim dosyaları yüklenebilir'), false);
    }
    cb(null, true);
  }
}).single('foto');

// Protect all routes
router.use(protect);

// Routes accessible by puantajci and admin
router.use(restrictTo('puantajci', 'admin', 'supervisor'));

// Create and manage puantaj records
router.post('/', upload, handleMulterError, createPuantaj);
router.patch('/:id/cikis', upload, handleMulterError, recordExit);
router.patch('/:id/iptal', cancelPuantaj);

// Get worker records
router.get('/isci/:isciId/gun/:date', getWorkerDailyRecords);
router.get('/isci/:isciId/ay/:year/:month', getWorkerMonthlyStats);

// Get project stats
router.get('/proje/gun/:date', getDailyProjectStats);

// Location based queries
router.get('/konum', getRecordsByLocation);

export default router;
