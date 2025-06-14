const mongoose = require('mongoose');

const puantajSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  date: {
    type: Date,
    required: true
  },
  startTime: {
    type: String,
    required: true
  },
  endTime: {
    type: String,
    required: true
  },
  breakTime: {
    type: Number,
    default: 60 // Minutes
  },
  overtime: {
    type: Number,
    default: 0 // Minutes
  },
  location: {
    type: String,
    required: true
  },
  notes: {
    type: String
  },
  status: {
    type: String,
    enum: ['pending', 'approved', 'rejected'],
    default: 'pending'
  },
  approvedBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User'
  },
  approvedAt: {
    type: Date
  }
}, {
  timestamps: true
});

// Bileşik indeks oluşturma
puantajSchema.index({ userId: 1, date: 1 }, { unique: true });
puantajSchema.index({ date: 1 });
puantajSchema.index({ status: 1 });

// Toplam çalışma saatini hesaplama metodu
puantajSchema.methods.calculateTotalHours = function() {
  const start = new Date(`2000-01-01T${this.startTime}`);
  const end = new Date(`2000-01-01T${this.endTime}`);
  const totalMinutes = (end - start) / 1000 / 60 - this.breakTime + this.overtime;
  return Math.round(totalMinutes / 60 * 100) / 100; // 2 ondalık basamağa yuvarlama
};

const Puantaj = mongoose.model('Puantaj', puantajSchema);

module.exports = Puantaj; 