const express = require('express');
const mongoose = require('mongoose');
const dotenv = require('dotenv');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const http = require('http');
const socketService = require('./services/socketService');

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

// MongoDB bağlantısı
mongoose.connect(process.env.MONGO_URI)
  .then(() => {
    console.log('MongoDB bağlantısı başarılı');
  })
  .catch((err) => {
    console.error('MongoDB bağlantı hatası:', err.message);
    process.exit(1);
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
}); 