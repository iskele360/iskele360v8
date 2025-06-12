import mongoose from 'mongoose';

const puantajSchema = new mongoose.Schema({
  isciId: {
    type: mongoose.Schema.ObjectId,
    ref: 'User',
    required: [true, 'İşçi ID\'si zorunludur']
  },
  puantajciId: {
    type: mongoose.Schema.ObjectId,
    ref: 'User',
    required: [true, 'Puantajcı ID\'si zorunludur']
  },
  projeId: {
    type: mongoose.Schema.ObjectId,
    ref: 'Proje',
    required: [true, 'Proje ID\'si zorunludur']
  },
  tarih: {
    type: Date,
    required: [true, 'Tarih zorunludur'],
    default: Date.now
  },
  giris: {
    saat: {
      type: String,
      required: [true, 'Giriş saati zorunludur'],
      validate: {
        validator: function(v) {
          return /^([01]?[0-9]|2[0-3]):[0-5][0-9]$/.test(v);
        },
        message: 'Geçerli bir saat giriniz (HH:MM)'
      }
    },
    konum: {
      type: {
        type: String,
        enum: ['Point'],
        default: 'Point'
      },
      coordinates: {
        type: [Number],
        required: true
      }
    },
    foto: {
      url: String,
      publicId: String,
      timestamp: Date
    }
  },
  cikis: {
    saat: {
      type: String,
      validate: {
        validator: function(v) {
          return !v || /^([01]?[0-9]|2[0-3]):[0-5][0-9]$/.test(v);
        },
        message: 'Geçerli bir saat giriniz (HH:MM)'
      }
    },
    konum: {
      type: {
        type: String,
        enum: ['Point'],
        default: 'Point'
      },
      coordinates: {
        type: [Number]
      }
    },
    foto: {
      url: String,
      publicId: String,
      timestamp: Date
    }
  },
  calismaSuresi: {
    type: Number, // Dakika cinsinden
    default: 0
  },
  durum: {
    type: String,
    enum: {
      values: ['giris', 'cikis', 'iptal'],
      message: 'Geçersiz durum'
    },
    default: 'giris'
  },
  notlar: {
    type: String,
    trim: true,
    maxLength: [500, 'Not 500 karakterden uzun olamaz']
  },
  meta: {
    iptalNedeni: {
      type: String,
      trim: true
    },
    iptalEden: {
      type: mongoose.Schema.ObjectId,
      ref: 'User'
    },
    iptalTarihi: Date,
    guncelleyen: {
      type: mongoose.Schema.ObjectId,
      ref: 'User'
    },
    guncellenmeTarihi: Date,
    olusturan: {
      type: mongoose.Schema.ObjectId,
      ref: 'User'
    }
  }
}, {
  timestamps: true,
  toJSON: { virtuals: true },
  toObject: { virtuals: true }
});

// Indexes for better query performance
puantajSchema.index({ isciId: 1, tarih: -1 });
puantajSchema.index({ puantajciId: 1, tarih: -1 });
puantajSchema.index({ projeId: 1, tarih: -1 });
puantajSchema.index({ durum: 1, tarih: -1 });
puantajSchema.index({ 'giris.konum': '2dsphere' });
puantajSchema.index({ 'cikis.konum': '2dsphere' });

// Virtual field for formatted date
puantajSchema.virtual('tarihFormatted').get(function() {
  return this.tarih.toLocaleDateString('tr-TR', {
    weekday: 'long',
    year: 'numeric',
    month: 'long',
    day: 'numeric'
  });
});

// Middleware to calculate working hours before save
puantajSchema.pre('save', function(next) {
  if (this.giris.saat && this.cikis.saat) {
    const giris = this.giris.saat.split(':');
    const cikis = this.cikis.saat.split(':');
    
    const girisDate = new Date(this.tarih);
    girisDate.setHours(parseInt(giris[0]), parseInt(giris[1]));
    
    const cikisDate = new Date(this.tarih);
    cikisDate.setHours(parseInt(cikis[0]), parseInt(cikis[1]));
    
    // If checkout time is before check-in time, assume it's next day
    if (cikisDate < girisDate) {
      cikisDate.setDate(cikisDate.getDate() + 1);
    }
    
    this.calismaSuresi = Math.round((cikisDate - girisDate) / 1000 / 60);
  }
  next();
});

// Middleware to update meta fields
puantajSchema.pre('save', function(next) {
  if (this.isModified() && !this.isNew) {
    this.meta.guncellenmeTarihi = new Date();
  }
  next();
});

// Static method to get daily stats
puantajSchema.statics.getDailyStats = async function(date) {
  const startOfDay = new Date(date);
  startOfDay.setHours(0, 0, 0, 0);
  
  const endOfDay = new Date(date);
  endOfDay.setHours(23, 59, 59, 999);
  
  return this.aggregate([
    {
      $match: {
        tarih: {
          $gte: startOfDay,
          $lte: endOfDay
        }
      }
    },
    {
      $group: {
        _id: '$projeId',
        toplamIsci: { $addToSet: '$isciId' },
        toplamSure: { $sum: '$calismaSuresi' },
        girisSayisi: { $sum: 1 }
      }
    }
  ]);
};

// Static method to get worker's monthly stats
puantajSchema.statics.getWorkerMonthlyStats = async function(isciId, year, month) {
  const startOfMonth = new Date(year, month - 1, 1);
  const endOfMonth = new Date(year, month, 0, 23, 59, 59, 999);
  
  return this.aggregate([
    {
      $match: {
        isciId: mongoose.Types.ObjectId(isciId),
        tarih: {
          $gte: startOfMonth,
          $lte: endOfMonth
        },
        durum: { $ne: 'iptal' }
      }
    },
    {
      $group: {
        _id: { $dayOfMonth: '$tarih' },
        calismaSuresi: { $sum: '$calismaSuresi' },
        projeId: { $first: '$projeId' }
      }
    },
    {
      $sort: { '_id': 1 }
    }
  ]);
};

const Puantaj = mongoose.model('Puantaj', puantajSchema);

export default Puantaj;
