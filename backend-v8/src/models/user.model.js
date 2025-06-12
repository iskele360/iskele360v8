const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const userSchema = new mongoose.Schema({
  firstName: {
    type: String,
    required: [true, 'Ad alanı zorunludur'],
    trim: true,
    minlength: [2, 'Ad en az 2 karakter olmalıdır'],
    maxlength: [50, 'Ad en fazla 50 karakter olabilir']
  },
  lastName: {
    type: String,
    required: [true, 'Soyad alanı zorunludur'],
    trim: true,
    minlength: [2, 'Soyad en az 2 karakter olmalıdır'],
    maxlength: [50, 'Soyad en fazla 50 karakter olabilir']
  },
  email: {
    type: String,
    unique: true,
    sparse: true,
    trim: true,
    lowercase: true,
    match: [/^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$/, 'Geçerli bir email adresi giriniz']
  },
  password: {
    type: String,
    required: [true, 'Şifre alanı zorunludur'],
    minlength: [6, 'Şifre en az 6 karakter olmalıdır'],
    select: false
  },
  role: {
    type: String,
    enum: {
      values: ['admin', 'puantajci', 'isci', 'tedarikci'],
      message: 'Geçersiz rol'
    },
    required: [true, 'Rol alanı zorunludur']
  },
  code: {
    type: String,
    unique: true,
    sparse: true
  },
  phone: {
    type: String,
    trim: true,
    match: [/^[0-9]{10}$/, 'Geçerli bir telefon numarası giriniz']
  },
  avatar: {
    type: String,
    default: 'default-avatar.png'
  },
  isActive: {
    type: Boolean,
    default: true
  },
  lastLogin: {
    type: Date
  },
  passwordChangedAt: Date,
  passwordResetToken: String,
  passwordResetExpires: Date,
  deviceTokens: [{
    token: String,
    platform: {
      type: String,
      enum: ['ios', 'android']
    },
    lastUsed: Date
  }],
  settings: {
    notifications: {
      push: {
        type: Boolean,
        default: true
      },
      email: {
        type: Boolean,
        default: true
      }
    },
    language: {
      type: String,
      enum: ['tr', 'en'],
      default: 'tr'
    },
    theme: {
      type: String,
      enum: ['light', 'dark', 'system'],
      default: 'system'
    }
  },
  meta: {
    createdBy: {
      type: mongoose.Schema.ObjectId,
      ref: 'User'
    },
    updatedBy: {
      type: mongoose.Schema.ObjectId,
      ref: 'User'
    }
  }
}, {
  timestamps: true,
  toJSON: { virtuals: true },
  toObject: { virtuals: true }
});

// Virtual Fields
userSchema.virtual('fullName').get(function() {
  return `${this.firstName} ${this.lastName}`;
});

// Indexes
userSchema.index({ email: 1 }, { unique: true, sparse: true });
userSchema.index({ code: 1 }, { unique: true, sparse: true });
userSchema.index({ role: 1, isActive: 1 });
userSchema.index({ createdAt: -1 });

// Middleware
userSchema.pre('save', async function(next) {
  if (!this.isModified('password')) return next();
  
  try {
    const salt = await bcrypt.genSalt(parseInt(process.env.BCRYPT_SALT_ROUNDS));
    this.password = await bcrypt.hash(this.password, salt);
    
    if (this.isModified('password') && !this.isNew) {
      this.passwordChangedAt = Date.now() - 1000;
    }
    
    next();
  } catch (error) {
    next(error);
  }
});

// Instance Methods
userSchema.methods.comparePassword = async function(candidatePassword) {
  try {
    return await bcrypt.compare(candidatePassword, this.password);
  } catch (error) {
    throw new Error('Şifre karşılaştırma hatası');
  }
};

userSchema.methods.changedPasswordAfter = function(JWTTimestamp) {
  if (this.passwordChangedAt) {
    const changedTimestamp = parseInt(this.passwordChangedAt.getTime() / 1000, 10);
    return JWTTimestamp < changedTimestamp;
  }
  return false;
};

userSchema.methods.createPasswordResetToken = function() {
  const resetToken = crypto.randomBytes(32).toString('hex');
  
  this.passwordResetToken = crypto
    .createHash('sha256')
    .update(resetToken)
    .digest('hex');
    
  this.passwordResetExpires = Date.now() + 10 * 60 * 1000; // 10 minutes
  
  return resetToken;
};

userSchema.methods.addDeviceToken = async function(token, platform) {
  const existingToken = this.deviceTokens.find(t => t.token === token);
  
  if (existingToken) {
    existingToken.lastUsed = new Date();
  } else {
    this.deviceTokens.push({
      token,
      platform,
      lastUsed: new Date()
    });
  }
  
  await this.save();
};

userSchema.methods.removeDeviceToken = async function(token) {
  this.deviceTokens = this.deviceTokens.filter(t => t.token !== token);
  await this.save();
};

// Static Methods
userSchema.statics.findByEmail = function(email) {
  return this.findOne({ email: email.toLowerCase() });
};

userSchema.statics.findByCode = function(code) {
  return this.findOne({ code });
};

userSchema.statics.findActiveByRole = function(role) {
  return this.find({ role, isActive: true });
};

const User = mongoose.model('User', userSchema);

module.exports = User;
