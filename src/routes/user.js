const express = require('express');
const router = express.Router();
const { verifyToken, checkRole } = require('../middlewares/auth.middleware');
const { User, Worker, Company } = require('../models');
const logger = require('../utils/logger');
const memoryService = require('../services/memory.service');

// Get user profile
router.get('/profile', verifyToken, async (req, res, next) => {
  try {
    // Check cache first
    const cachedUser = await memoryService.getCachedUserData(req.user.id);
    if (cachedUser) {
      return res.json(cachedUser);
    }

    const user = await User.findByPk(req.user.id, {
      attributes: { exclude: ['password'] },
      include: [
        {
          model: Worker,
          include: [Company]
        }
      ]
    });

    // Cache user data
    await memoryService.cacheUserData(req.user.id, user);

    res.json(user);
  } catch (error) {
    next(error);
  }
});

// Delete own account
router.delete('/delete', verifyToken, async (req, res, next) => {
  try {
    await User.destroy({ where: { id: req.user.id } });
    
    // Clear user cache
    await memoryService.deleteCachedUserData(req.user.id);
    
    res.json({ message: 'Hesabınız başarıyla silindi' });
  } catch (error) {
    next(error);
  }
});

// Delete user by ID (only for puantajci)
router.delete('/delete/:userId', [
  verifyToken,
  checkRole(['puantajci'])
], async (req, res, next) => {
  try {
    const { userId } = req.params;

    // Check if user exists
    const user = await User.findByPk(userId);
    if (!user) {
      return res.status(404).json({ message: 'Kullanıcı bulunamadı' });
    }

    // Delete user and related data
    await User.destroy({ where: { id: userId } });

    // Clear user cache
    await memoryService.deleteCachedUserData(userId);

    res.json({ message: 'Kullanıcı başarıyla silindi' });
  } catch (error) {
    next(error);
  }
});

module.exports = router; 