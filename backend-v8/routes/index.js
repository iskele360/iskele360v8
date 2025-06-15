const express = require('express');
const router = express.Router();
const authRoutes = require('./auth');
const userRoutes = require('./user');
const inventoryRoutes = require('./inventory');

// Auth routes
router.use('/auth', authRoutes);

// User routes (protected)
router.use('/users', userRoutes);

// Inventory routes (protected)
router.use('/inventory', inventoryRoutes);

module.exports = router; 