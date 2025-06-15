require('dotenv').config({ path: __dirname + '/../.env' });
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const rateLimit = require('express-rate-limit');
const cloudinary = require('cloudinary').v2;
const connectDB = require('./config/database');
const authRoutes = require('./routes/auth');
const mongoose = require('mongoose');
const cacheManager = require('./utils/cache');
const cluster = require('cluster');
const numCPUs = require('os').cpus().length;
const routes = require('./routes');

if (cluster.isPrimary) {
  console.log(`Ana process ${process.pid} çalışıyor`);

  // Worker'ları başlat
  for (let i = 0; i < numCPUs; i++) {
    cluster.fork();
  }

  cluster.on('exit', (worker, code, signal) => {
    console.log(`Worker ${worker.process.pid} kapandı`);
  });
} else {
  const app = express();
  const port = process.env.PORT || 3000;

  // Configure Cloudinary
  cloudinary.config({
    cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
    api_key: process.env.CLOUDINARY_API_KEY,
    api_secret: process.env.CLOUDINARY_API_SECRET
  });

  // Middleware
  app.use(cors());
  app.use(express.json());
  app.use(morgan('dev'));

  // Rate limiting with memory store
  const limiter = rateLimit({
    windowMs: 15 * 60 * 1000, // 15 minutes
    max: 100, // limit each IP to 100 requests per windowMs
    standardHeaders: true,
    legacyHeaders: false,
  });
  app.use(limiter);

  // Routes
  app.use('/api', routes);

  // MongoDB'ye bağlan
  connectDB().then(() => {
    console.log('✅ MongoDB bağlantısı başarılı');
  }).catch(err => {
    console.error('❌ MongoDB bağlantı hatası:', err);
    process.exit(1);
  });

  // Health check endpoint
  app.get('/health', async (req, res) => {
    try {
      const cacheStatus = await cacheManager.get('health_check');
      if (!cacheStatus) {
        await cacheManager.set('health_check', 'OK', 60);
      }
      
      res.status(200).json({
        status: 'OK',
        database: 'MongoDB',
        cache: cacheManager.isRedisAvailable ? 'Redis' : 'In-Memory',
        environment: process.env.NODE_ENV,
        cacheStatus: cacheStatus ? 'Working' : 'New Entry',
        mongodb: mongoose.connection.readyState === 1 ? 'Connected' : 'Disconnected',
        worker: process.pid
      });
    } catch (error) {
      res.status(500).json({
        status: 'Error',
        error: error.message
      });
    }
  });

  // Sunucuyu başlat
  app.listen(port, () => {
    console.log(`🚀 Worker ${process.pid} başlatıldı: Port ${port}`);
    console.log(`🌍 Ortam: ${process.env.NODE_ENV || 'development'}`);
  });
} 