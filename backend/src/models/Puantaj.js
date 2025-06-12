const mongoose = require('mongoose');

const puantajSchema = new mongoose.Schema({
  tarih: {
    type: Date,
    required: true,
    default: Date.now
  },
  isciId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  puantajciId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  baslangicSaati: {
    type: String,
    required: true
  },
  bitisSaati: {
    type: String,
    required: true
  },
  calismaSuresi: {
    type: Number, // Saat cinsinden
    required: true
  },
  projeId: {
    type: String,
    required: true
  },
  projeBilgisi: {
    type: String,
    required: true
  },
  aciklama: {
    type: String,
    default: ''
  },
  durum: {
    type: String,
    enum: ['tamamlandi', 'devam_ediyor', 'iptal_edildi'],
    default: 'tamamlandi'
  }
}, {
  timestamps: true
});

// Ana sorgu indeksleri
// 1. Puantaj kayıtlarını işçi ve tarih bazında indeksle (işçilere ait kayıtları sorgularken hızlı erişim için)
puantajSchema.index({ isciId: 1, tarih: -1 });

// 2. Puantaj kayıtlarını puantajcı ve tarih bazında indeksle (ana dashboard sorgusu için optimize)
puantajSchema.index({ puantajciId: 1, tarih: -1 });

// 3. Compound indeks: Puantajcı + İşçi + Tarih (filtreleme yaparken hızlı erişim için)
puantajSchema.index({ puantajciId: 1, isciId: 1, tarih: -1 });

// 4. Proje bazlı sorgular için indeks
puantajSchema.index({ puantajciId: 1, projeId: 1, tarih: -1 });

// 5. Durum bazlı sorgular için indeks
puantajSchema.index({ puantajciId: 1, durum: 1, tarih: -1 });

// 6. Aggregation sorgularını hızlandıracak indeks (istatistikler için)
puantajSchema.index({ puantajciId: 1, tarih: 1, calismaSuresi: 1 });

// 7. Arama işlemleri için text indeksi
puantajSchema.index(
  { projeBilgisi: 'text', aciklama: 'text' },
  { 
    weights: { 
      projeBilgisi: 10, 
      aciklama: 5 
    },
    name: 'text_index' 
  }
);

/**
 * Puantaj kaydı oluşturulmadan önce çalışan middleware
 * tarih alanını normalize eder
 */
puantajSchema.pre('save', function(next) {
  // Tarih değeri varsa, saat kısmını sıfırla (günlük bazda gruplamak için)
  if (this.tarih) {
    const tarih = new Date(this.tarih);
    tarih.setHours(0, 0, 0, 0);
    this.tarih = tarih;
  }
  next();
});

const Puantaj = mongoose.model('Puantaj', puantajSchema);

module.exports = Puantaj; 