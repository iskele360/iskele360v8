const express = require('express');
const router = express.Router();
const multer = require('multer');
const { verifyToken, checkRole } = require('../middlewares/auth.middleware');
const { Worker } = require('../models');
const cloudinaryService = require('../services/cloudinary.service');
const logger = require('../utils/logger');

// Multer configuration for handling file uploads
const upload = multer({
  storage: multer.memoryStorage(),
  limits: {
    fileSize: 5 * 1024 * 1024, // 5MB limit
  },
  fileFilter: (req, file, cb) => {
    if (file.mimetype.startsWith('image/')) {
      cb(null, true);
    } else {
      cb(new Error('Sadece resim dosyaları yüklenebilir'));
    }
  }
});

// Upload worker photo
router.post('/:workerId/photo', [
  verifyToken,
  checkRole(['puantajci']),
  upload.single('photo')
], async (req, res, next) => {
  try {
    const { workerId } = req.params;
    const worker = await Worker.findByPk(workerId);

    if (!worker) {
      return res.status(404).json({ message: 'İşçi bulunamadı' });
    }

    if (!req.file) {
      return res.status(400).json({ message: 'Fotoğraf yüklenmedi' });
    }

    // Delete old photo if exists
    if (worker.photoPublicId) {
      await cloudinaryService.deleteImage(worker.photoPublicId);
    }

    // Upload new photo
    const result = await cloudinaryService.uploadImage(
      req.file.buffer.toString('base64'),
      `workers/${workerId}`
    );

    // Update worker record
    await worker.update({
      photoUrl: result.url,
      photoPublicId: result.publicId
    });

    res.json({
      message: 'Fotoğraf başarıyla yüklendi',
      photoUrl: result.url
    });
  } catch (error) {
    logger.error('Photo upload error:', error);
    next(error);
  }
});

// Delete worker photo
router.delete('/:workerId/photo', [
  verifyToken,
  checkRole(['puantajci'])
], async (req, res, next) => {
  try {
    const { workerId } = req.params;
    const worker = await Worker.findByPk(workerId);

    if (!worker) {
      return res.status(404).json({ message: 'İşçi bulunamadı' });
    }

    if (!worker.photoPublicId) {
      return res.status(404).json({ message: 'Fotoğraf bulunamadı' });
    }

    // Delete photo from Cloudinary
    await cloudinaryService.deleteImage(worker.photoPublicId);

    // Update worker record
    await worker.update({
      photoUrl: null,
      photoPublicId: null
    });

    res.json({ message: 'Fotoğraf başarıyla silindi' });
  } catch (error) {
    logger.error('Photo delete error:', error);
    next(error);
  }
});

module.exports = router; 