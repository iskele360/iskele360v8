import express from 'express';
import multer from 'multer';
import {
  register,
  login,
  logout,
  updatePassword,
  forgotPassword,
  resetPassword,
  getMe,
  updateMe
} from '../controllers/auth.controller.js';
import { protect, logAuthAttempt } from '../middleware/auth.middleware.js';
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
}).single('avatar');

// Public routes
router.post('/register', upload, handleMulterError, register);
router.post('/login', logAuthAttempt, login);
router.post('/forgot-password', forgotPassword);
router.patch('/reset-password/:token', resetPassword);

// Protected routes
router.use(protect); // All routes after this middleware require authentication

router.get('/me', getMe);
router.patch('/update-me', upload, handleMulterError, updateMe);
router.patch('/update-password', updatePassword);
router.post('/logout', logout);

export default router;
