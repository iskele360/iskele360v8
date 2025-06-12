const express = require('express');
const mongoose = require('mongoose');
const dotenv = require('dotenv');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const http = require('http');
const socketService = require('./services/socketService');
const cacheService = require('./services/cache');

// Route dosyaları
const authRoutes = require('./routes/auth');
const userRoutes = require('./routes/user');
const puantajRoutes = require('./routes/puantaj');

// Env değişkenlerini yükle
dotenv.config();

// Express uygulaması oluştur
const app = express();
const server = http.createServer(app);

// Socket.IO başlat
const io = socketService.initSocketIO(server);

// MongoDB bağlantı optimizasyonları
const mongoOptions = {
  useNewUrlParser: true,
  useUnifiedTopology: true,
  maxPoolSize: 50, // Yüksek eşzamanlı istek sayısı için havuz boyutunu artır
  socketTimeoutMS: 30000, // Soket zaman aşımı (30 saniye)
  connectTimeoutMS: 30000, // Bağlantı zaman aşımı (30 saniye)
  serverSelectionTimeoutMS: 30000, // Sunucu seçim zaman aşımı (30 saniye)
  heartbeatFrequencyMS: 10000, // Heartbeat sıklığı (10 saniye)
  retryWrites: true, // Yazma hatalarında yeniden dene
  w: 'majority', // Yazma onayı (çoğunluk)
  minPoolSize: 10 // Minimum havuz boyutu (performans için)
};

// MongoDB bağlantısı
mongoose.connect(process.env.MONGO_URI, mongoOptions)
  .then(() => {
    console.log('MongoDB bağlantısı başarılı');
    
    // İndeksleri oluştur (performans için gerekli)
    console.log('MongoDB indeksleri oluşturuluyor...');
    mongoose.connection.db.collection('puantaj').createIndex({ isciId: 1, tarih: -1 });
    mongoose.connection.db.collection('puantaj').createIndex({ puantajciId: 1, tarih: -1 });
    mongoose.connection.db.collection('puantaj').createIndex({ puantajciId: 1, isciId: 1, tarih: -1 });
    mongoose.connection.db.collection('puantaj').createIndex({ puantajciId: 1, projeId: 1, tarih: -1 });
    mongoose.connection.db.collection('puantaj').createIndex({ puantajciId: 1, durum: 1, tarih: -1 });
    mongoose.connection.db.collection('puantaj').createIndex({ puantajciId: 1, tarih: 1, calismaSuresi: 1 });
    console.log('MongoDB indeksleri oluşturuldu');
  })
  .catch((err) => {
    console.error('MongoDB bağlantı hatası:', err.message);
    process.exit(1);
  });

// Performans optimizasyonu için mongoose buffer komutları
mongoose.set('bufferCommands', true);
mongoose.set('bufferTimeoutMS', 2000);

// MongoDB bağlantısı için olay dinleyicileri
mongoose.connection.on('error', (err) => {
  console.error('MongoDB bağlantı hatası:', err);
});

mongoose.connection.on('disconnected', () => {
  console.warn('MongoDB bağlantısı kesildi, yeniden bağlanmaya çalışılıyor...');
});

mongoose.connection.on('reconnected', () => {
  console.log('MongoDB ile yeniden bağlantı kuruldu');
});

// Güvenlik middleware'leri
app.use(helmet()); // Temel güvenlik başlıkları
app.use(cors({
  origin: '*', // Gerçek projede daha spesifik olmalı
  methods: ['GET', 'POST', 'PUT', 'DELETE'],
  allowedHeaders: ['Content-Type', 'Authorization']
}));

// Rate limiter - DoS koruması
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 dakika
  max: 100, // IP başına 100 istek
  standardHeaders: true,
  legacyHeaders: false,
  message: {
    success: false,
    message: 'Çok fazla istek yapıldı, lütfen daha sonra tekrar deneyin'
  }
});
app.use(limiter);

// Body parser
app.use(express.json({ limit: '10kb' }));
app.use(express.urlencoded({ extended: true, limit: '10kb' }));

// Performans izleme middleware'i
app.use((req, res, next) => {
  // İstek başlangıç zamanını kaydet
  const startTime = Date.now();
  
  // İstek tamamlandığında süreyi ölç
  res.on('finish', () => {
    const duration = Date.now() - startTime;
    // Sadece yavaş sorguları logla (500ms üzeri)
    if (duration > 500) {
      console.warn(`Yavaş sorgu: ${req.method} ${req.originalUrl} - ${duration}ms`);
    }
  });
  
  next();
});

// Rotaları tanımla
app.use('/api/auth', authRoutes);
app.use('/api/users', userRoutes);
app.use('/api/puantaj', puantajRoutes);

// Socket.IO test endpoint'i
app.post('/api/socket-test', (req, res) => {
  const { event, data, userId } = req.body;
  
  if (userId) {
    // Belirli bir kullanıcıya mesaj gönder
    socketService.emitToUser(userId, event || 'message', data || { message: 'Test mesajı' });
  } else {
    // Tüm kullanıcılara mesaj gönder
    socketService.emitToAll(event || 'message', data || { message: 'Test mesajı' });
  }
  
  res.status(200).json({
    success: true,
    message: 'Socket mesajı gönderildi'
  });
});

// Önbellek yönetimi endpoint'i
app.get('/api/cache/stats', async (req, res) => {
  try {
    const stats = await cacheService.getStats();
    res.status(200).json({
      success: true,
      data: stats
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Önbellek durumu alınamadı'
    });
  }
});

app.delete('/api/cache/clear', async (req, res) => {
  try {
    await cacheService.clear();
    res.status(200).json({
      success: true,
      message: 'Önbellek temizlendi'
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Önbellek temizlenemedi'
    });
  }
});

// Sistem durumu endpoint'i
app.get('/api/health', (req, res) => {
  const mongoStatus = mongoose.connection.readyState === 1 ? 'connected' : 'disconnected';
  
  res.status(200).json({
    success: true,
    status: 'up',
    uptime: process.uptime(),
    timestamp: new Date().toISOString(),
    mongo: {
      status: mongoStatus,
      host: mongoose.connection.host,
      name: mongoose.connection.name
    },
    memory: process.memoryUsage()
  });
});

// Ana sayfa
app.get('/', (req, res) => {
  res.status(200).json({
    success: true,
    message: 'İskele360 API çalışıyor',
    version: '1.0.0'
  });
});

// 404 hatası
app.all('*', (req, res) => {
  res.status(404).json({
    success: false,
    message: `${req.originalUrl} yolu bulunamadı`
  });
});

// Global hata yakalayıcı
app.use((err, req, res, next) => {
  console.error('Sunucu hatası:', err);
  
  res.status(err.statusCode || 500).json({
    success: false,
    message: err.message || 'Sunucu hatası'
  });
});

// Sunucuyu başlat
const PORT = process.env.PORT || 3000;
server.listen(PORT, () => {
  console.log(`Sunucu ${PORT} portunda çalışıyor`);
  console.log('WebSocket servisi aktif');
  
  // REDIS_ENABLED çevre değişkenini kontrol et
  const redisEnabled = process.env.REDIS_ENABLED === 'true';
  console.log(`Önbellek modu: ${redisEnabled ? 'Redis' : 'In-Memory'}`);
}); 