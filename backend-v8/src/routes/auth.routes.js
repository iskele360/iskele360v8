const express = require('express');
const authController = require('../controllers/auth.controller');
const authMiddleware = require('../middleware/auth.middleware');
const { catchAsync } = require('../middleware/error.middleware');

const router = express.Router();

// Public routes
router.post('/register', 
  authMiddleware.rateLimiter,
  catchAsync(authController.register)
);

router.post('/login',
  authMiddleware.rateLimiter,
  catchAsync(authController.login)
);

router.post('/forgot-password',
  authMiddleware.rateLimiter,
  catchAsync(authController.forgotPassword)
);

router.patch('/reset-password/:token',
  authMiddleware.rateLimiter,
  catchAsync(authController.resetPassword)
);

// Protected routes
router.use(authMiddleware.protect);
router.use(authMiddleware.isActive);

router.post('/logout',
  catchAsync(authController.logout)
);

router.patch('/update-password',
  catchAsync(authController.updatePassword)
);

router.post('/validate-token',
  catchAsync(authController.validateToken)
);

// Admin only routes
router.use(authMiddleware.restrictTo('admin'));

router.post('/create-supervisor',
  catchAsync(async (req, res) => {
    req.body.role = 'puantajci';
    await authController.register(req, res);
  })
);

router.post('/create-worker',
  catchAsync(async (req, res) => {
    req.body.role = 'isci';
    await authController.register(req, res);
  })
);

router.post('/create-supplier',
  catchAsync(async (req, res) => {
    req.body.role = 'tedarikci';
    await authController.register(req, res);
  })
);

// Supervisor only routes
router.use(authMiddleware.restrictTo('admin', 'puantajci'));

router.post('/create-worker-by-supervisor',
  catchAsync(async (req, res) => {
    req.body.role = 'isci';
    await authController.register(req, res);
  })
);

// Device token management
router.post('/device-token',
  authMiddleware.requireDeviceToken,
  catchAsync(async (req, res) => {
    res.status(200).json({
      status: 'success',
      message: 'Device token başarıyla kaydedildi'
    });
  })
);

router.delete('/device-token/:token',
  catchAsync(async (req, res) => {
    await req.user.removeDeviceToken(req.params.token);
    res.status(200).json({
      status: 'success',
      message: 'Device token başarıyla silindi'
    });
  })
);

// Health check
router.get('/healthcheck',
  catchAsync(async (req, res) => {
    res.status(200).json({
      status: 'success',
      message: 'Auth servisi çalışıyor',
      timestamp: new Date().toISOString()
    });
  })
);

module.exports = router;
