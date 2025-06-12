const mongoose = require('mongoose');

const puantajSchema = new mongoose.Schema({
  isciId: {
    type: mongoose.Schema.ObjectId,
    ref: 'User',
    required: [true, 'İşçi ID alanı zorunludur']
  },
  puantajciId: {
    type: mongoose.Schema.ObjectId,
    ref: 'User',
    required: [true, 'Puantajcı ID alanı zorunludur']
  },
  baslangicSaati: {
    type: Date,
    required: [true, 'Başlangıç saati zorunludur']
  },
  bitisSaati: {
    type: Date,
    required: [true, 'Bitiş saati zorunludur']
  },
  calismaSuresi: {
    type: Number,
    required: [true, 'Çalışma süresi zorunludur'],
    min: [0, 'Çalışma süresi 0\'dan küçük olamaz'],
    max: [24, 'Çalışma süresi 24 saatten fazla olamaz']
  },
  projeId: {
    type: String,
    required: [true, 'Proje ID alanı zorunludur']
  },
  projeBilgisi: {
    type: String,
    required: [true, 'Proje bilgisi zorunludur'],
    trim: true,
    maxlength: [500, 'Proje bilgisi en fazla 500 karakter olabilir']
  },
  aciklama: {
    type: String,
    trim: true,
    maxlength: [1000, 'Açıklama en fazla 1000 karakter olabilir']
  },
  durum: {
    type: String,
    enum: {
      values: ['beklemede', 'onaylandi', 'reddedildi'],
      message: 'Geçersiz durum'
    },
    default: 'beklemede'
  },
  tarih: {
    type: Date,
    required: [true, 'Tarih alanı zorunludur']
  },
  lokasyon: {
    type: {
      type: String,
      enum: ['Point'],
      default: 'Point'
    },
    coordinates: {
      type: [Number],
      required: true
    },
    adres: String
  },
  fotograf: [{
    url: String,
    publicId: String,
    yuklemeTarihi: {
      type: Date,
      default: Date.now
    }
  }],
  imza: {
    isci: {
      url: String,
      tarih: Date
    },
    puantajci: {
      url: String,
      tarih: Date
    }
  },
  meta: {
    deviceInfo: {
      platform: String,
      version: String,
      model: String
    },
    ipAddress: String,
    userAgent: String
  },
  degisiklikGecmisi: [{
    alan: String,
    eskiDeger: mongoose.Schema.Types.Mixed,
    yeniDeger: mongoose.Schema.Types.Mixed,
    degistirenId: {
      type: mongoose.Schema.ObjectId,
      ref: 'User'
    },
    degisiklikTarihi: {
      type: Date,
      default: Date.now
    },
    aciklama: String
  }]
}, {
  timestamps: true,
  toJSON: { virtuals: true },
  toObject: { virtuals: true }
});

// Indexes
puantajSchema.index({ isciId: 1, tarih: -1 });
puantajSchema.index({ puantajciId: 1, tarih: -1 });
puantajSchema.index({ projeId: 1, tarih: -1 });
puantajSchema.index({ durum: 1, tarih: -1 });
puantajSchema.index({ lokasyon: '2dsphere' });

// Virtual Fields
puantajSchema.virtual('worker', {
  ref: 'User',
  localField: 'isciId',
  foreignField: '_id',
  justOne: true
});

puantajSchema.virtual('supervisor', {
  ref: 'User',
  localField: 'puantajciId',
  foreignField: '_id',
  justOne: true
});

// Methods
puantajSchema.methods.hesaplaCalismaSuresi = function() {
  const baslangic = new Date(this.baslangicSaati);
  const bitis = new Date(this.bitisSaati);
  const fark = (bitis - baslangic) / (1000 * 60 * 60); // Saat cinsinden
  return Math.round(fark * 10) / 10; // 1 ondalık basamak
};

puantajSchema.methods.durumGuncelle = async function(yeniDurum, degistirenId, aciklama) {
  const eskiDurum = this.durum;
  this.durum = yeniDurum;
  
  this.degisiklikGecmisi.push({
    alan: 'durum',
    eskiDeger: eskiDurum,
    yeniDeger: yeniDurum,
    degistirenId,
    aciklama
  });
  
  await this.save();
};

puantajSchema.methods.fotografEkle = async function(fotografBilgisi) {
  this.fotograf.push({
    url: fotografBilgisi.url,
    publicId: fotografBilgisi.publicId,
    yuklemeTarihi: new Date()
  });
  
  await this.save();
};

puantajSchema.methods.imzaEkle = async function(tip, imzaBilgisi) {
  if (tip === 'isci') {
    this.imza.isci = {
      url: imzaBilgisi.url,
      tarih: new Date()
    };
  } else if (tip === 'puantajci') {
    this.imza.puantajci = {
      url: imzaBilgisi.url,
      tarih: new Date()
    };
  }
  
  await this.save();
};

// Statics
puantajSchema.statics.getGunlukPuantajlar = function(tarih) {
  const baslangic = new Date(tarih);
  baslangic.setHours(0, 0, 0, 0);
  
  const bitis = new Date(tarih);
  bitis.setHours(23, 59, 59, 999);
  
  return this.find({
    tarih: {
      $gte: baslangic,
      $lte: bitis
    }
  }).populate('worker supervisor');
};

puantajSchema.statics.getIsciPuantajlari = function(isciId, baslangicTarihi, bitisTarihi) {
  return this.find({
    isciId,
    tarih: {
      $gte: baslangicTarihi,
      $lte: bitisTarihi
    }
  }).sort({ tarih: -1 });
};

puantajSchema.statics.getProjePuantajlari = function(projeId, baslangicTarihi, bitisTarihi) {
  return this.find({
    projeId,
    tarih: {
      $gte: baslangicTarihi,
      $lte: bitisTarihi
    }
  }).populate('worker supervisor').sort({ tarih: -1 });
};

// Middleware
puantajSchema.pre('save', function(next) {
  if (this.isModified('baslangicSaati') || this.isModified('bitisSaati')) {
    this.calismaSuresi = this.hesaplaCalismaSuresi();
  }
  next();
});

puantajSchema.pre(/^find/, function(next) {
  this.populate({
    path: 'worker',
    select: 'firstName lastName code'
  }).populate({
    path: 'supervisor',
    select: 'firstName lastName'
  });
  next();
});

const Puantaj = mongoose.model('Puantaj', puantajSchema);

module.exports = Puantaj;
