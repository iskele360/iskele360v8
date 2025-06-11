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

// Puantaj kayıtlarını işçi ve tarih bazında indeksle
puantajSchema.index({ isciId: 1, tarih: -1 });

// Puantaj kayıtlarını puantajcı bazında indeksle
puantajSchema.index({ puantajciId: 1 });

const Puantaj = mongoose.model('Puantaj', puantajSchema);

module.exports = Puantaj; 