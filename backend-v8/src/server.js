import express from 'express';
import mongoose from 'mongoose';
import Redis from 'ioredis';
import { v2 as cloudinary } from 'cloudinary';
import cors from 'cors';
import helmet from 'helmet';
import rateLimit from 'express-rate-limit';
import compression from 'compression';
import dotenv from 'dotenv';
import morgan from 'morgan';
import { createServer } from 'http';
import { Server } from 'socket.io';
import { fileURLToPath } from 'url';
import { dirname } from 'path';

// ES Module dirname setup
const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

// Load environment variables
dotenv.config();

// Create Express app
const app = express();
const httpServer = createServer(app);
const io = new Server(httpServer, {
  cors: {
    origin: process.env.CORS_ORIGIN,
    methods: ['GET', 'POST'],
    credentials: true
  }
});

// MongoDB connection with optimized settings
mongoose.connect(process.env.MONGODB_URI, {
  useNewUrlParser: true,
  useUnifiedTopology: true,
  maxPoolSize: parseInt(process.env.DB_MAX_POOL_SIZE),
  minPoolSize: parseInt(process.env.DB_MIN_POOL_SIZE),
  socketTimeoutMS: parseInt(process.env.DB_CONNECTION_TIMEOUT),
  serverSelectionTimeoutMS: parseInt(process.env.DB_CONNECTION_TIMEOUT),
  heartbeatFrequencyMS: 10000,
  retryWrites: true,
  w: 'majority',
  autoIndex: false
})
.then(() => {
  console.log('✅ MongoDB bağlantısı başarılı');
  // Create indexes for better performance
  createIndexes();
})
.catch((err) => {
  console.error('❌ MongoDB bağlantı hatası:', err.message);
  process.exit(1);
});

// Redis client setup
let redis;
try {
  if (process.env.UPSTASH_REDIS_URL) {
    redis = new Redis(process.env.UPSTASH_REDIS_URL);
    redis.on('connect', () => {
      console.log('✅ Redis bağlantısı başarılı');
    });
    redis.on('error', (err) => {
      console.warn('⚠️ Redis bağlantı hatası:', err.message);
      console.log('Redis olmadan devam ediliyor...');
      redis = null;
    });
  } else {
    console.log('⚠️ Redis URL tanımlanmamış, Redis olmadan devam ediliyor...');
  }
} catch (error) {
  console.warn('⚠️ Redis başlatma hatası:', error.message);
  console.log('Redis olmadan devam ediliyor...');
  redis = null;
}

// Cloudinary configuration
cloudinary.config({
  cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
  api_key: process.env.CLOUDINARY_API_KEY,
  api_secret: process.env.CLOUDINARY_API_SECRET
});

// Security Middleware
app.use(helmet()); // Security headers
app.use(cors({
  origin: process.env.CORS_ORIGIN,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH'],
  allowedHeaders: ['Content-Type', 'Authorization'],
  credentials: true
}));

// Performance Middleware
app.use(compression()); // Response compression
app.use(express.json({ limit: process.env.MAX_FILE_SIZE })); // Body parser
app.use(express.urlencoded({ extended: true, limit: process.env.MAX_FILE_SIZE }));
app.use(morgan('combined')); // Request logging

// Rate limiting
const limiter = rateLimit({
  windowMs: parseInt(process.env.RATE_LIMIT_WINDOW_MS),
  max: parseInt(process.env.RATE_LIMIT_MAX_REQUESTS),
  message: {
    status: 'error',
    message: 'Çok fazla istek yapıldı, lütfen daha sonra tekrar deneyin.'
  }
});
app.use('/api', limiter);

// Performance monitoring middleware
app.use((req, res, next) => {
  const start = Date.now();
  res.on('finish', () => {
    const duration = Date.now() - start;
    if (duration > parseInt(process.env.SLOW_QUERY_THRESHOLD_MS)) {
      console.warn(`⚠️ Yavaş sorgu: ${req.method} ${req.originalUrl} - ${duration}ms`);
    }
  });
  next();
});

// Create MongoDB indexes
async function createIndexes() {
  try {
    const db = mongoose.connection.db;
    
    // User indexes with sparse option
    await db.collection('users').createIndex({ email: 1 }, { unique: true, sparse: true });
    await db.collection('users').createIndex({ username: 1 }, { unique: true, sparse: true });
    await db.collection('users').createIndex({ role: 1, isActive: 1 });
    
    // Puantaj indexes
    await db.collection('puantaj').createIndex({ isciId: 1, tarih: -1 });
    await db.collection('puantaj').createIndex({ puantajciId: 1, tarih: -1 });
    await db.collection('puantaj').createIndex({ puantajciId: 1, isciId: 1, tarih: -1 });
    await db.collection('puantaj').createIndex({ projeId: 1, tarih: -1 });
    await db.collection('puantaj').createIndex({ durum: 1, tarih: -1 });
    
    console.log('✅ MongoDB indeksleri oluşturuldu');
  } catch (error) {
    console.error('❌ Index oluşturma hatası:', error);
  }
}

// Socket.IO connection handling
io.on('connection', (socket) => {
  console.log('🔌 Yeni socket bağlantısı:', socket.id);

  socket.on('join', (room) => {
    socket.join(room);
    console.log(`🔌 Socket ${socket.id} joined room: ${room}`);
  });

  socket.on('leave', (room) => {
    socket.leave(room);
    console.log(`🔌 Socket ${socket.id} left room: ${room}`);
  });

  socket.on('disconnect', () => {
    console.log('🔌 Socket bağlantısı kesildi:', socket.id);
  });
});

// Health check endpoint
app.get('/healthcheck', (req, res) => {
  const mongoStatus = mongoose.connection.readyState === 1;
  const redisStatus = redis ? redis.status === 'ready' : 'disabled';

  res.json({
    status: 'ok',
    version: process.env.API_VERSION,
    timestamp: new Date().toISOString(),
    services: {
      mongodb: mongoStatus ? 'connected' : 'disconnected',
      redis: redisStatus,
      cloudinary: 'connected'
    }
  });
});

// Ana sayfa
app.get('/', (req, res) => {
  res.json({
    name: 'İskele360 v8 API',
    version: process.env.API_VERSION,
    environment: process.env.NODE_ENV
  });
});

// API Routes
const API_PREFIX = process.env.API_PREFIX;

// Import routes dynamically
const routes = [
  { path: '/auth', module: './routes/auth.routes.js' },
  { path: '/puantaj', module: './routes/puantaj.routes.js' }
];

// Register routes
for (const route of routes) {
  const module = await import(route.module);
  app.use(`${API_PREFIX}${route.path}`, module.default);
}

// 404 handler
app.all('*', (req, res) => {
  res.status(404).json({
    status: 'error',
    message: `${req.originalUrl} yolu bulunamadı`
  });
});

// Global error handler
app.use((err, req, res, next) => {
  console.error('❌ Hata:', err);

  res.status(err.status || 500).json({
    status: 'error',
    message: process.env.NODE_ENV === 'development' ? err.message : 'Sunucu hatası'
  });
});

// Start server
const PORT = process.env.PORT || 3000;
httpServer.listen(PORT, () => {
  console.log(`🚀 Sunucu ${PORT} portunda çalışıyor`);
  console.log(`🌍 Ortam: ${process.env.NODE_ENV}`);
  console.log('✨ API hazır');
});

// Graceful shutdown
process.on('SIGTERM', () => {
  console.log('⚡ SIGTERM sinyali alındı. Sunucu kapatılıyor...');
  httpServer.close(() => {
    console.log('✅ Sunucu kapatıldı');
    mongoose.connection.close(false, () => {
      console.log('✅ MongoDB bağlantısı kapatıldı');
      if (redis) {
        redis.quit(() => {
          console.log('✅ Redis bağlantısı kapatıldı');
          process.exit(0);
        });
      } else {
        process.exit(0);
      }
    });
  });
});

// Handle uncaught exceptions
process.on('uncaughtException', (err) => {
  console.error('❌ Yakalanmamış istisna:', err);
  httpServer.close(() => {
    process.exit(1);
  });
});

// Handle unhandled promise rejections
process.on('unhandledRejection', (err) => {
  console.error('❌ İşlenmemiş promise reddi:', err);
  httpServer.close(() => {
    process.exit(1);
  });
});

export { app, httpServer, io, redis };
