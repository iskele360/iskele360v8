import mongoose from 'mongoose';
import bcrypt from 'bcryptjs';
import crypto from 'crypto';
import validator from 'validator';

const userSchema = new mongoose.Schema({
  firstName: {
    type: String,
    required: [true, 'İsim zorunludur'],
    trim: true,
    maxLength: [50, 'İsim 50 karakterden uzun olamaz']
  },
  lastName: {
    type: String,
    required: [true, 'Soyisim zorunludur'],
    trim: true,
    maxLength: [50, 'Soyisim 50 karakterden uzun olamaz']
  },
  email: {
    type: String,
    required: [true, 'Email zorunludur'],
    unique: true,
    lowercase: true,
    validate: [validator.isEmail, 'Geçerli bir email adresi giriniz']
  },
  phone: {
    type: String,
    trim: true,
    validate: {
      validator: function(v) {
        return /^\+?[1-9]\d{1,14}$/.test(v);
      },
      message: 'Geçerli bir telefon numarası giriniz'
    }
  },
  password: {
    type: String,
    required: [true, 'Şifre zorunludur'],
    minlength: [8, 'Şifre en az 8 karakter olmalıdır'],
    select: false
  },
  role: {
    type: String,
    enum: {
      values: ['admin', 'supervisor', 'puantajci', 'isci'],
      message: 'Geçersiz rol'
    },
    default: 'isci'
  },
  isActive: {
    type: Boolean,
    default: true,
    select: false
  },
  avatar: {
    url: String,
    publicId: String
  },
  meta: {
    lastLogin: Date,
    passwordChangedAt: Date,
    passwordResetToken: String,
    passwordResetExpires: Date,
    createdBy: {
      type: mongoose.Schema.ObjectId,
      ref: 'User'
    },
    updatedBy: {
      type: mongoose.Schema.ObjectId,
      ref: 'User'
    }
  },
  permissions: {
    type: [String],
    select: false
  }
}, {
  timestamps: true,
  toJSON: { virtuals: true },
  toObject: { virtuals: true }
});

// Virtual field for full name
userSchema.virtual('fullName').get(function() {
  return `${this.firstName} ${this.lastName}`;
});

// Index for better query performance
userSchema.index({ email: 1 }, { unique: true });
userSchema.index({ role: 1, isActive: 1 });
userSchema.index({ 'meta.createdBy': 1 });

// Middleware to hash password before save
userSchema.pre('save', async function(next) {
  // Only hash the password if it has been modified
  if (!this.isModified('password')) return next();
  
  try {
    // Hash password with cost of 12
    this.password = await bcrypt.hash(this.password, 12);
    
    // Update passwordChangedAt if password is changed
    if (!this.isNew) {
      this.meta.passwordChangedAt = Date.now() - 1000;
    }
    
    next();
  } catch (error) {
    next(error);
  }
});

// Middleware to update updatedBy field
userSchema.pre('save', function(next) {
  if (this.updatedBy) {
    this.meta.updatedBy = this.updatedBy;
  }
  next();
});

// Method to check if password is correct
userSchema.methods.comparePassword = async function(candidatePassword) {
  try {
    return await bcrypt.compare(candidatePassword, this.password);
  } catch (error) {
    throw new Error('Şifre karşılaştırma hatası');
  }
};

// Method to check if password was changed after token was issued
userSchema.methods.changedPasswordAfter = function(JWTTimestamp) {
  if (this.meta.passwordChangedAt) {
    const changedTimestamp = parseInt(
      this.meta.passwordChangedAt.getTime() / 1000,
      10
    );
    return JWTTimestamp < changedTimestamp;
  }
  return false;
};

// Method to create password reset token
userSchema.methods.createPasswordResetToken = function() {
  const resetToken = crypto.randomBytes(32).toString('hex');

  this.meta.passwordResetToken = crypto
    .createHash('sha256')
    .update(resetToken)
    .digest('hex');

  this.meta.passwordResetExpires = Date.now() + 10 * 60 * 1000; // 10 minutes

  return resetToken;
};

// Method to check if user has permission
userSchema.methods.hasPermission = function(permission) {
  return this.permissions?.includes(permission);
};

// Static method to get user by email
userSchema.statics.findByEmail = function(email) {
  return this.findOne({ email: email.toLowerCase() });
};

// Static method to get active users by role
userSchema.statics.findActiveByRole = function(role) {
  return this.find({ role, isActive: true });
};

// Static method to get user stats
userSchema.statics.getUserStats = async function() {
  return this.aggregate([
    {
      $group: {
        _id: '$role',
        count: { $sum: 1 },
        activeCount: {
          $sum: { $cond: ['$isActive', 1, 0] }
        }
      }
    }
  ]);
};

const User = mongoose.model('User', userSchema);

export default User;
