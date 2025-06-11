// Firebase ve Express modüllerini yükle
const functions = require('firebase-functions');
const admin = require('firebase-admin');
const express = require('express');
const cors = require('cors');

// Firebase admin başlat
admin.initializeApp();
const db = admin.firestore();

// Express app oluştur
const app = express();

// CORS ayarlarını genişlet
app.use(cors({
  origin: '*',
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'Accept', 'Origin', 'X-Requested-With'],
  credentials: true,
  preflightContinue: false,
  optionsSuccessStatus: 204
}));
app.use(express.json());


// Basit test endpointi - API canlı kontrolü için
app.get('/ping', (req, res) => {
  res.status(200).json({ 
    status: 'success', 
    message: 'Iskele360 API çalışıyor',
    timestamp: new Date().toISOString()
  });
});


// Kullanıcı kayıt endpoint'i
app.post('/auth/register', async (req, res) => {
  try {
    const { name, surname, email, password, role } = req.body;

    if (!name || !surname || !email || !password || !role) {
      return res.status(400).json({
        success: false,
        message: 'Tüm alanlar zorunludur'
      });
    }

    const usersRef = db.collection('users');
    const emailCheck = await usersRef.where('email', '==', email).get();

    if (!emailCheck.empty) {
      return res.status(400).json({
        success: false,
        message: 'Bu e-posta zaten kayıtlı'
      });
    }

    const newUser = {
      name,
      surname,
      email,
      password,
      role,
      createdAt: admin.firestore.FieldValue.serverTimestamp()
    };

    const userRef = await usersRef.add(newUser);

    return res.status(201).json({
      success: true,
      message: 'Kullanıcı eklendi',
      userId: userRef.id
    });

  } catch (error) {
    console.error('Register error:', error);
    return res.status(500).json({
      success: false,
      message: 'Sunucu hatası'
    });
  }
});


// Kullanıcı login endpoint'i
app.post('/auth/login', async (req, res) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({
        success: false,
        message: 'Email ve şifre gereklidir'
      });
    }

    // Test için mock veri
    const token = `token_${Date.now()}`;
    const user = {
      id: '1',
      name: 'Demo',
      surname: 'Puantajcı',
      email: email,
      role: 'supervisor',
      createdAt: new Date()
    };

    return res.status(200).json({
      success: true,
      token,
      data: user
    });
  } catch (error) {
    console.error('Login error:', error);
    return res.status(500).json({
      success: false,
      message: 'Sunucu hatası'
    });
  }
});


// Kod ile giriş endpoint'i
app.post('/auth/login-with-code', async (req, res) => {
  try {
    const { code, password } = req.body;
    
    if (!code || !password) {
      return res.status(400).json({
        success: false,
        message: 'Kod ve şifre gereklidir'
      });
    }
    
    // Test için mock veri
    const token = `token_${Date.now()}`;
    const isWorker = code.startsWith('1');
    
    const user = {
      id: '2',
      name: 'Demo',
      surname: isWorker ? 'İşçi' : 'Malzemeci',
      code: code,
      role: isWorker ? 'isci' : 'supplier',
      createdAt: new Date()
    };
    
    return res.status(200).json({
      success: true,
      token,
      data: user
    });
  } catch (error) {
    console.error('Login with code error:', error);
    return res.status(500).json({
      success: false,
      message: 'Sunucu hatası'
    });
  }
});


// Kullanıcı profili endpoint'i
app.get('/users/profile', async (req, res) => {
  try {
    const authHeader = req.headers.authorization;
    
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({
        success: false,
        message: 'Yetkilendirme başarısız'
      });
    }
    
    const token = authHeader.split('Bearer ')[1];
    
    // NOT: Gerçek uygulamada token doğrulaması yapılır ve kullanıcı bilgileri veritabanından alınır
    // Bu örnek için basitçe statik bir kullanıcı dönüyoruz
    return res.status(200).json({
      success: true,
      data: {
        id: 'sample_id',
        name: 'Demo',
        surname: 'Kullanıcı',
        email: 'demo@example.com',
        role: 'supervisor',
        createdAt: new Date()
      }
    });
  } catch (error) {
    console.error('Profile error:', error);
    return res.status(500).json({
      success: false,
      message: 'Sunucu hatası'
    });
  }
});


// İşçi oluşturma endpoint'i
app.post('/users/create-worker', async (req, res) => {
  try {
    const { firstName, lastName } = req.body;

    if (!firstName || !lastName) {
      return res.status(400).json({
        success: false,
        message: 'Ad ve soyad gereklidir'
      });
    }

    const code = Math.floor(1000000000 + Math.random() * 9000000000).toString();

    const newWorker = {
      name: firstName,
      surname: lastName,
      code,
      password: '123456',
      role: 'isci',
      createdAt: admin.firestore.FieldValue.serverTimestamp()
    };

    const usersRef = db.collection('users');
    const workerRef = await usersRef.add(newWorker);

    return res.status(201).json({
      success: true,
      message: 'İşçi başarıyla oluşturuldu',
      workerId: workerRef.id,
      code
    });

  } catch (error) {
    console.error('Create worker error:', error);
    return res.status(500).json({
      success: false,
      message: 'Sunucu hatası'
    });
  }
});


// Malzemeci oluşturma endpoint'i
app.post('/users/create-supplier', async (req, res) => {
  try {
    const { firstName, lastName } = req.body;

    if (!firstName || !lastName) {
      return res.status(400).json({
        success: false,
        message: 'Ad ve soyad gereklidir'
      });
    }

    const code = Math.floor(2000000000 + Math.random() * 7999999999).toString();

    const newSupplier = {
      name: firstName,
      surname: lastName,
      code,
      password: '123456',
      role: 'supplier',
      createdAt: admin.firestore.FieldValue.serverTimestamp()
    };

    const usersRef = db.collection('users');
    const supplierRef = await usersRef.add(newSupplier);

    return res.status(201).json({
      success: true,
      message: 'Malzemeci başarıyla oluşturuldu',
      supplierId: supplierRef.id,
      code
    });

  } catch (error) {
    console.error('Create supplier error:', error);
    return res.status(500).json({
      success: false,
      message: 'Sunucu hatası'
    });
  }
});


// Express'i Firebase Functions'a export et
exports.api = functions.https.onRequest(app);