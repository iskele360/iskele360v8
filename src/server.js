require('dotenv').config();
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const sequelize = require('./config/database');
const { Redis } = require('@upstash/redis');
const cloudinary = require('cloudinary').v2;

// Initialize Express
const app = express();

// Middleware
app.use(cors({
  origin: process.env.CORS_ORIGIN || '*'
}));
app.use(helmet());
app.use(express.json());

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