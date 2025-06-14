const express = require('express');
const router = express.Router();
const { register, login, me } = require('../controllers/authController');
const verifyToken = require('../middleware/verifyToken');

// Public routes
router.post('/register', register);
router.post('/login', login);

// Protected routes - requires authentication
router.use('/me', verifyToken);  // Apply middleware only to /me route
router.get('/me', me);

module.exports = router; 