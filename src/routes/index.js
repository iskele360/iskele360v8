const express = require('express');
const router = express.Router();
const authRoutes = require('./auth');
const { authenticateToken } = require('../middleware/auth');

// Public routes
router.use('/auth', authRoutes);

// Protected routes
router.use(authenticateToken);

module.exports = router; 