const User = require('../models/User');
const cloudinary = require('../services/cloudinaryService');
const redis = require('../services/redisService');

// Kullanıcı profili
exports.getMe = async (req, res) => {
  try {
    const user = await User.findById(req.user.id);
    
    res.status(200).json({
      status: 'success',
      data: {
        user
      }
    });
  } catch (err) {
    res.status(400).json({
      status: 'fail',
      message: err.message
    });
  }
};

// Puantajcı tarafından işçi oluşturma
exports.createWorker = async (req, res) => {
  try {
    // İşçi için rastgele şifre oluştur (sadece örnektir, gerçek uygulamada farklı yaklaşımlar kullanılabilir)
    const defaultPassword = Math.random().toString(36).slice(-8);
    
    const newWorker = await User.create({
      name: req.body.name,
      surname: req.body.surname,
      email: req.body.email,
      password: defaultPassword,
      role: 'isci',
      createdBy: req.user._id
    });
    
    // Şifreyi yanıta dahil et (sadece oluşturma sırasında)
    const workerWithPassword = newWorker.toObject();
    workerWithPassword.password = defaultPassword;
    
    res.status(201).json({
      status: 'success',
      data: {
        worker: workerWithPassword
      }
    });
  } catch (err) {
    res.status(400).json({
      status: 'fail',
      message: err.message
    });
  }
};

// Puantajcı tarafından malzemeci oluşturma
exports.createMaterialManager = async (req, res) => {
  try {
    // Malzemeci için rastgele şifre oluştur
    const defaultPassword = Math.random().toString(36).slice(-8);
    
    const newManager = await User.create({
      name: req.body.name,
      surname: req.body.surname,
      email: req.body.email,
      password: defaultPassword,
      role: 'malzemeci',
      createdBy: req.user._id
    });
    
    // Şifreyi yanıta dahil et (sadece oluşturma sırasında)
    const managerWithPassword = newManager.toObject();
    managerWithPassword.password = defaultPassword;
    
    res.status(201).json({
      status: 'success',
      data: {
        materialManager: managerWithPassword
      }
    });
  } catch (err) {
    res.status(400).json({
      status: 'fail',
      message: err.message
    });
  }
};

// Puantajcının işçilerini getir
exports.getMyWorkers = async (req, res) => {
  try {
    const workers = await User.find({ 
      createdBy: req.user._id,
      role: 'isci'
    });
    
    res.status(200).json({
      status: 'success',
      results: workers.length,
      data: {
        workers
      }
    });
  } catch (err) {
    res.status(400).json({
      status: 'fail',
      message: err.message
    });
  }
};

// Puantajcının malzemecilerini getir
exports.getMyMaterialManagers = async (req, res) => {
  try {
    const managers = await User.find({ 
      createdBy: req.user._id,
      role: 'malzemeci'
    });
    
    res.status(200).json({
      status: 'success',
      results: managers.length,
      data: {
        materialManagers: managers
      }
    });
  } catch (err) {
    res.status(400).json({
      status: 'fail',
      message: err.message
    });
  }
};

// Kullanıcının kendi hesabını silmesi
exports.deleteSelf = async (req, res) => {
  try {
    // Kullanıcı ID'si
    const userId = req.user._id;

    // Kullanıcıyı bul ve sil
    const user = await User.findByIdAndDelete(userId);

    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'Kullanıcı bulunamadı'
      });
    }

    // İlişkili diğer verileri de silmek için gerekli işlemler burada yapılabilir
    // Örneğin: puantaj kayıtları, zimmet kayıtları, vb.
    
    // TODO: Puantaj ve zimmet silme işlemleri eklenecek

    res.status(200).json({
      success: true,
      message: 'Hesabınız başarıyla silindi'
    });
  } catch (error) {
    console.error('Hesap silme hatası:', error);
    res.status(500).json({
      success: false,
      message: 'Sunucu hatası, lütfen daha sonra tekrar deneyin'
    });
  }
};

// Kullanıcı profili güncelleme
exports.updateProfile = async (req, res) => {
  try {
    const { name, surname, email } = req.body;
    
    // Güvenli güncelleme için sadece belirli alanları al
    const updates = {};
    if (name) updates.name = name;
    if (surname) updates.surname = surname;
    if (email) updates.email = email;
    
    // Şifre güncellemesi burada yapılmıyor, ayrı bir endpoint'te olmalı
    
    const user = await User.findByIdAndUpdate(
      req.user._id,
      updates,
      { new: true, runValidators: true }
    );
    
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'Kullanıcı bulunamadı'
      });
    }
    
    res.status(200).json({
      success: true,
      data: user
    });
  } catch (error) {
    console.error('Profil güncelleme hatası:', error);
    res.status(500).json({
      success: false,
      message: 'Sunucu hatası, lütfen daha sonra tekrar deneyin'
    });
  }
};

// Şifre güncelleme
exports.updatePassword = async (req, res) => {
  try {
    const { currentPassword, newPassword } = req.body;
    
    if (!currentPassword || !newPassword) {
      return res.status(400).json({
        success: false,
        message: 'Mevcut şifre ve yeni şifre gereklidir'
      });
    }
    
    // Şifre uzunluk kontrolü
    if (newPassword.length < 6) {
      return res.status(400).json({
        success: false,
        message: 'Şifre en az 6 karakter olmalıdır'
      });
    }
    
    // Kullanıcıyı bul
    const user = await User.findById(req.user._id);
    
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'Kullanıcı bulunamadı'
      });
    }
    
    // Mevcut şifreyi kontrol et
    const isPasswordCorrect = await user.comparePassword(currentPassword);
    
    if (!isPasswordCorrect) {
      return res.status(401).json({
        success: false,
        message: 'Mevcut şifre yanlış'
      });
    }
    
    // Şifreyi güncelle
    user.password = newPassword;
    await user.save();
    
    res.status(200).json({
      success: true,
      message: 'Şifreniz başarıyla güncellendi'
    });
  } catch (error) {
    console.error('Şifre güncelleme hatası:', error);
    res.status(500).json({
      success: false,
      message: 'Sunucu hatası, lütfen daha sonra tekrar deneyin'
    });
  }
};

// Tüm kullanıcıları getir (Yalnızca Admin ve Puantajcı için)
exports.getAllUsers = async (req, res) => {
  try {
    const users = await User.findAll({
      attributes: { exclude: ['password'] }
    });

    res.json({
      success: true,
      data: users
    });
  } catch (error) {
    console.error('Get all users error:', error);
    res.status(500).json({
      success: false,
      message: 'Error getting users'
    });
  }
};

const getUserById = async (req, res) => {
  try {
    const user = await User.findByPk(req.params.id);
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    res.json({
      success: true,
      data: user.toPublicJSON()
    });
  } catch (error) {
    console.error('Get user error:', error);
    res.status(500).json({
      success: false,
      message: 'Error getting user'
    });
  }
};

const updateUser = async (req, res) => {
  try {
    const user = await User.findByPk(req.params.id);
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    // Check permissions
    if (req.user.role !== 'admin' && req.user.id !== user.id) {
      return res.status(403).json({
        success: false,
        message: 'Not authorized'
      });
    }

    const { firstName, lastName, email, role, isActive } = req.body;

    // Only admin can change role and active status
    if (req.user.role !== 'admin') {
      delete req.body.role;
      delete req.body.isActive;
    }

    await user.update({
      firstName: firstName || user.firstName,
      lastName: lastName || user.lastName,
      email: email || user.email,
      role: role || user.role,
      isActive: isActive !== undefined ? isActive : user.isActive
    });

    // Clear Redis cache
    await redis.del(`user:${user.id}`);

    res.json({
      success: true,
      data: user.toPublicJSON()
    });
  } catch (error) {
    console.error('Update user error:', error);
    res.status(500).json({
      success: false,
      message: 'Error updating user'
    });
  }
};

const deleteUser = async (req, res) => {
  try {
    const user = await User.findByPk(req.params.id);
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    // Only admin can delete users
    if (req.user.role !== 'admin') {
      return res.status(403).json({
        success: false,
        message: 'Not authorized'
      });
    }

    // Delete profile image from Cloudinary if exists
    if (user.profileImage) {
      const publicId = user.profileImage.split('/').pop().split('.')[0];
      await cloudinary.deleteImage(publicId);
    }

    // Delete user
    await user.destroy();

    // Clear Redis cache
    await redis.del(`user:${user.id}`);

    res.json({
      success: true,
      message: 'User deleted successfully'
    });
  } catch (error) {
    console.error('Delete user error:', error);
    res.status(500).json({
      success: false,
      message: 'Error deleting user'
    });
  }
};

const updateProfileImage = async (req, res) => {
  try {
    const user = await User.findByPk(req.user.id);
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    // Delete old profile image if exists
    if (user.profileImage) {
      const publicId = user.profileImage.split('/').pop().split('.')[0];
      await cloudinary.deleteImage(publicId);
    }

    // Upload new image
    const result = await cloudinary.uploadImage(
      req.body.image,
      `iskele360/profile/${user.id}`
    );

    if (!result.success) {
      return res.status(400).json({
        success: false,
        message: 'Error uploading image'
      });
    }

    // Update user profile
    user.profileImage = result.url;
    await user.save();

    // Clear Redis cache
    await redis.del(`user:${user.id}`);

    res.json({
      success: true,
      data: {
        profileImage: result.url
      }
    });
  } catch (error) {
    console.error('Update profile image error:', error);
    res.status(500).json({
      success: false,
      message: 'Error updating profile image'
    });
  }
};

module.exports = {
  getAllUsers,
  getUserById,
  updateUser,
  deleteUser,
  updateProfileImage
}; 