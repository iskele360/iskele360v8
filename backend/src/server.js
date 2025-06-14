require('dotenv').config({ path: __dirname + '/../.env' });
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const { Redis } = require('@upstash/redis');
const rateLimit = require('express-rate-limit');
const cloudinary = require('cloudinary').v2;
const connectDB = require('./config/database');
const authRoutes = require('./routes/auth');
const mongoose = require('mongoose');

// Initialize Express
const app = express();

// Initialize Redis
const redis = new Redis({
  url: process.env.UPSTASH_REDIS_REST_URL,
  token: process.env.UPSTASH_REDIS_REST_TOKEN,
});

// Configure Cloudinary
cloudinary.config({
  cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
  api_key: process.env.CLOUDINARY_API_KEY,
  api_secret: process.env.CLOUDINARY_API_SECRET
});

// Connect to MongoDB
connectDB().then(() => {
  console.log('✅ MongoDB bağlantısı başarılı');
}).catch(err => {
  console.error('❌ MongoDB bağlantı hatası:', err);
  process.exit(1);
});

// Test Redis connection
redis.ping().then(() => {
  console.log('✅ Redis bağlantısı başarılı');
}).catch(err => {
  console.error('❌ Redis bağlantı hatası:', err);
});

// Middleware
app.use(cors({
  origin: process.env.CORS_ORIGIN || '*'
}));
app.use(helmet());
app.use(express.json({ limit: '50mb' }));
app.use(express.urlencoded({ extended: true, limit: '50mb' }));

// Rate limiting with Redis
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // limit each IP to 100 requests per windowMs
  standardHeaders: true,
  legacyHeaders: false,
});
app.use(limiter);

// Development logging
if (process.env.NODE_ENV === 'development') {
  app.use(morgan('dev'));
}

// Routes
app.use('/api/auth', authRoutes);

// Health check endpoint
app.get('/health', async (req, res) => {
  try {
    const redisStatus = await redis.ping();
    res.status(200).json({
      status: 'OK',
      database: 'MongoDB',
      cache: 'Redis',
      environment: process.env.NODE_ENV,
      redis: redisStatus === 'PONG' ? 'Connected' : 'Error',
      mongodb: mongoose.connection.readyState === 1 ? 'Connected' : 'Disconnected'
    });
  } catch (error) {
    res.status(500).json({
      status: 'Error',
      error: error.message
    });
  }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`🚀 Server başlatıldı: Port ${PORT}`);
  console.log(`🌍 Ortam: ${process.env.NODE_ENV}`);
}); 