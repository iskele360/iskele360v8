const mongoose = require('mongoose');

const connectDB = async () => {
  try {
    const conn = await mongoose.connect(process.env.MONGODB_URI, {
      // Deprecated options removed
      autoIndex: true,
      maxPoolSize: 10,
      serverSelectionTimeoutMS: 5000,
      socketTimeoutMS: 45000,
      family: 4
    });

    console.log('MongoDB bağlantısı başarılı');
    
    // İndeksleri oluştur
    console.log('MongoDB indeksleri oluşturuluyor...');
    await Promise.all([
      require('../models/user').createIndexes(),
      require('../models/project').createIndexes(),
      require('../models/notification').createIndexes(),
      require('../models/activity').createIndexes()
    ]);
    console.log('MongoDB indeksleri oluşturuldu');

    return conn;
  } catch (err) {
    console.error('MongoDB bağlantı hatası:', err.message);
    process.exit(1);
  }
};

module.exports = connectDB; 