require('dotenv').config({ path: __dirname + '/../.env' });
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const rateLimit = require('express-rate-limit');
const path = require('path');
const sequelize = require(path.join(__dirname, 'config', 'database'));
const { Redis } = require('@upstash/redis');
const cloudinary = require('cloudinary').v2;
const authRoutes = require('./routes/auth');

// Initialize Express
const app = express();

// Middleware
app.use(cors({
  origin: process.env.CORS_ORIGIN || '*'
}));
app.use(helmet());
app.use(express.json({ limit: '50mb' }));
app.use(express.urlencoded({ extended: true, limit: '50mb' }));

// Configure Cloudinary
cloudinary.config({
  cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
  api_key: process.env.CLOUDINARY_API_KEY,
  api_secret: process.env.CLOUDINARY_API_SECRET
});

// Configure Redis
const redis = new Redis({
  url: process.env.UPSTASH_REDIS_REST_URL,
  token: process.env.UPSTASH_REDIS_REST_TOKEN
});

// Rate limiting
const limiter = rateLimit({
  windowMs: parseInt(process.env.RATE_LIMIT_WINDOW_MS) || 900000, // 15 minutes
  max: parseInt(process.env.RATE_LIMIT_MAX_REQUESTS) || 100
});
app.use(limiter);

// Logging middleware
if (process.env.NODE_ENV === 'development') {
  app.use(morgan('dev'));
}

// Routes
app.use('/api/auth', authRoutes);
app.use('/api/users', require('./routes/userRoutes'));
app.use('/api/puantaj', require('./routes/puantaj'));

// Health check endpoint
app.get('/health', async (req, res) => {
  try {
    // Test database connection
    await sequelize.authenticate();
    
    // Test Redis connection
    await redis.ping();
    
    res.status(200).json({
      status: 'healthy',
      services: {
        database: 'connected',
        redis: 'connected',
        cloudinary: 'configured'
      },
      environment: process.env.NODE_ENV,
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    res.status(500).json({
      status: 'unhealthy',
      error: error.message,
      timestamp: new Date().toISOString()
    });
  }
});

// Error handling middleware
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({
    success: false,
    message: process.env.NODE_ENV === 'development' ? err.message : 'Internal server error'
  });
});

// Initialize services
const initializeServices = async () => {
  try {
    // Test PostgreSQL connection
    await sequelize.authenticate();
    console.log('✅ PostgreSQL connection successful');
    
    // Test Redis connection
    await redis.ping();
    console.log('✅ Redis connection successful');
    
    console.log('✅ Cloudinary configured');
    
    // Sync database models
    await sequelize.sync();
    console.log('✅ Database sync completed');

    const PORT = process.env.PORT || 3000;
    app.listen(PORT, () => {
      console.log(`🚀 Server is running on port ${PORT}`);
      console.log(`🌍 Environment: ${process.env.NODE_ENV}`);
    });
  } catch (error) {
    console.error('❌ Service initialization error:', error);
    process.exit(1);
  }
};

initializeServices(); 