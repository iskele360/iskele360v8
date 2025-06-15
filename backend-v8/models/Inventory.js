const mongoose = require('mongoose');

const inventorySchema = new mongoose.Schema({
  malzemeci: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  isci: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  malzeme: {
    type: String,
    required: true
  },
  miktar: {
    type: Number,
    required: true,
    min: 1
  },
  birim: {
    type: String,
    required: true,
    enum: ['adet', 'metre', 'kg', 'litre']
  },
  zimmetTarihi: {
    type: Date,
    default: Date.now
  },
  teslimTarihi: {
    type: Date
  },
  durum: {
    type: String,
    enum: ['zimmetli', 'teslim_edildi'],
    default: 'zimmetli'
  },
  aciklama: String
}, {
  timestamps: true
});

const Inventory = mongoose.model('Inventory', inventorySchema);

module.exports = Inventory; 