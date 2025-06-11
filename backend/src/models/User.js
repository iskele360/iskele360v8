const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const userSchema = new mongoose.Schema({
  name: {
    type: String,
    required: [true, 'İsim alanı zorunludur'],
    trim: true
  },
  surname: {
    type: String,
    required: [true, 'Soyisim alanı zorunludur'],
    trim: true
  },
  code: {
    type: String,
    unique: true,
    sparse: true
  },
  email: {
    type: String,
    unique: true,
    required: [true, 'Email alanı zorunludur'],
    lowercase: true,
    trim: true
  },
  password: {
    type: String,
    required: [true, 'Şifre alanı zorunludur'],
    minlength: 6,
    select: false
  },
  role: {
    type: String,
    enum: ['puantajci', 'isci', 'malzemeci'],
    default: 'puantajci'
  },
  createdBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    default: null
  },
  createdAt: {
    type: Date,
    default: Date.now
  }
});

// Şifreyi hash'leme
userSchema.pre('save', async function(next) {
  // Şifre değiştirilmemişse hash'leme işlemini atla
  if (!this.isModified('password')) return next();
  
  // Şifreyi hash'le
  this.password = await bcrypt.hash(this.password, 12);
  next();
});

// 10 haneli otomatik kod oluşturma (işçi ve malzemeci için)
userSchema.pre('save', async function(next) {
  // Sadece yeni oluşturulan işçi ve malzemeci için kod oluştur
  if (this.isNew && (this.role === 'isci' || this.role === 'malzemeci')) {
    // 10 haneli rastgele kod oluştur
    let code;
    let codeExists = true;
    
    while (codeExists) {
      code = Math.floor(1000000000 + Math.random() * 9000000000).toString();
      const existingUser = await mongoose.model('User').findOne({ code });
      codeExists = !!existingUser;
    }
    
    this.code = code;
  }
  
  next();
});

// Şifre doğrulama metodu
userSchema.methods.correctPassword = async function(candidatePassword, userPassword) {
  return await bcrypt.compare(candidatePassword, userPassword);
};

const User = mongoose.model('User', userSchema);

module.exports = User; 