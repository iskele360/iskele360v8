const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const userSchema = new mongoose.Schema({
  name: {
    type: String,
    required: true,
    trim: true
  },
  email: {
    type: String,
    trim: true,
    lowercase: true,
    match: [/^\w+([.-]?\w+)*@\w+([.-]?\w+)*(\.\w{2,3})+$/, 'Lütfen geçerli bir email adresi giriniz'],
    // Email sadece puantajcı için zorunlu
    required: function() {
      return this.role === 'puantajci';
    }
  },
  password: {
    type: String,
    // Şifre sadece puantajcı için zorunlu
    required: function() {
      return this.role === 'puantajci';
    },
    select: false
  },
  code: {
    type: String,
    // Kod işçi ve malzemeci için zorunlu
    required: function() {
      return ['isci', 'malzemeci'].includes(this.role);
    },
    unique: true,
    sparse: true
  },
  role: {
    type: String,
    enum: ['puantajci', 'isci', 'malzemeci'],
    required: true
  },
  createdBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: function() {
      return ['isci', 'malzemeci'].includes(this.role);
    }
  },
  isActive: {
    type: Boolean,
    default: true
  },
  lastLogin: {
    type: Date
  },
  profileImage: {
    type: String
  }
}, {
  timestamps: true
});

// Şifre hashleme middleware
userSchema.pre('save', async function(next) {
  if (!this.isModified('password')) return next();
  
  try {
    const salt = await bcrypt.genSalt(10);
    this.password = await bcrypt.hash(this.password, salt);
    next();
  } catch (error) {
    next(error);
  }
});

// Şifre karşılaştırma metodu
userSchema.methods.comparePassword = async function(candidatePassword) {
  return await bcrypt.compare(candidatePassword, this.password);
};

// Kod karşılaştırma metodu
userSchema.methods.compareCode = function(candidateCode) {
  return this.code === candidateCode;
};

// Public profil metodu
userSchema.methods.toPublicJSON = function() {
  const obj = this.toObject();
  delete obj.password;
  delete obj.code;
  return obj;
};

// Kod oluşturma static metodu
userSchema.statics.generateUniqueCode = async function(role) {
  const prefix = role === 'isci' ? 'W' : 'S'; // Worker veya Supplier
  let code;
  let isUnique = false;

  while (!isUnique) {
    // 10 haneli random sayı
    const randomNum = Math.floor(1000000000 + Math.random() * 9000000000);
    code = `${prefix}${randomNum}`;
    
    // Kodun benzersiz olduğunu kontrol et
    const existingUser = await this.findOne({ code });
    if (!existingUser) {
      isUnique = true;
    }
  }

  return code;
};

const User = mongoose.model('User', userSchema);

module.exports = User; 