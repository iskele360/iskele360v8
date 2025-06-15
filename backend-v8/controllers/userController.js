const User = require('../models/User');
const cloudinary = require('../services/cloudinaryService');
const redis = require('../services/redisService');
const Inventory = require('../models/Inventory');
const catchAsync = require('../utils/catchAsync');
const AppError = require('../utils/appError');

// Kullanıcı profili
const getMe = catchAsync(async (req, res, next) => {
  const user = await User.findById(req.user.id);
  
  res.status(200).json({
    success: true,
    data: user
  });
});

// Puantajcı tarafından işçi oluşturma
const createWorker = catchAsync(async (req, res, next) => {
  const { name } = req.body;
  
  if (!name) {
    return next(new AppError('İsim alanı zorunludur', 400));
  }

  // W- ile başlayan 10 haneli kod oluştur
  const code = 'W-' + Math.random().toString().slice(2, 10);
  
  const worker = await User.create({
    name,
    code,
    role: 'isci',
    createdBy: req.user.id
  });

  res.status(201).json({
    success: true,
    data: worker
  });
});

// Puantajcı tarafından malzemeci oluşturma
const createSupplier = catchAsync(async (req, res, next) => {
  const { name } = req.body;
  
  if (!name) {
    return next(new AppError('İsim alanı zorunludur', 400));
  }

  // S- ile başlayan 10 haneli kod oluştur
  const code = 'S-' + Math.random().toString().slice(2, 10);
  
  const supplier = await User.create({
    name,
    code,
    role: 'malzemeci',
    createdBy: req.user.id
  });

  res.status(201).json({
    success: true,
    data: supplier
  });
});

// Puantajcının işçilerini getir
const getMyWorkers = catchAsync(async (req, res, next) => {
  const workers = await User.find({ 
    createdBy: req.user._id,
    role: 'isci'
  });
  
  res.status(200).json({
    success: true,
    results: workers.length,
    data: {
      workers
    }
  });
});

// Puantajcının malzemecilerini getir
const getMyMaterialManagers = catchAsync(async (req, res, next) => {
  const managers = await User.find({ 
    createdBy: req.user._id,
    role: 'malzemeci'
  });
  
  res.status(200).json({
    success: true,
    results: managers.length,
    data: {
      materialManagers: managers
    }
  });
});

// Kullanıcının kendi hesabını silmesi
const deleteSelf = catchAsync(async (req, res, next) => {
  const userId = req.user._id;

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
});

// Kullanıcı profili güncelleme
const updateMe = catchAsync(async (req, res, next) => {
  const { name, email, password } = req.body;
  
  const updateData = {};
  if (name) updateData.name = name;
  if (email) updateData.email = email;
  if (password) updateData.password = password;

  const user = await User.findByIdAndUpdate(
    req.user.id,
    updateData,
    { new: true, runValidators: true }
  );

  res.status(200).json({
    success: true,
    data: user
  });
});

// Şifre güncelleme
const updatePassword = catchAsync(async (req, res, next) => {
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
});

// Tüm kullanıcıları getir (Yalnızca Admin ve Puantajcı için)
const getAllUsers = catchAsync(async (req, res, next) => {
  const users = await User.findAll({
    attributes: { exclude: ['password'] }
  });

  res.json({
    success: true,
    data: users
  });
});

const getUserById = catchAsync(async (req, res, next) => {
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
});

const updateUser = catchAsync(async (req, res, next) => {
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
});

const deleteUser = catchAsync(async (req, res, next) => {
  const user = await User.findById(req.params.userId);

  if (!user) {
    return next(new AppError('Kullanıcı bulunamadı', 404));
  }

  // Sadece kendi oluşturduğu kullanıcıları silebilir
  if (user.createdBy.toString() !== req.user.id) {
    return next(new AppError('Bu işlem için yetkiniz yok', 403));
  }

  await user.remove();

  res.status(200).json({
    success: true,
    message: 'Kullanıcı başarıyla silindi'
  });
});

const updateProfileImage = catchAsync(async (req, res, next) => {
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
});

// İşçileri getir
const getWorkers = catchAsync(async (req, res, next) => {
  const workers = await User.find({ role: 'isci', createdBy: req.user.id });
  
  res.status(200).json({
    success: true,
    data: workers
  });
});

// Malzemecileri getir
const getSuppliers = catchAsync(async (req, res, next) => {
  const suppliers = await User.find({ role: 'malzemeci', createdBy: req.user.id });
  
  res.status(200).json({
    success: true,
    data: suppliers
  });
});

// İşçi için zimmet listesi
const getWorkerInventory = catchAsync(async (req, res, next) => {
  const inventory = await Inventory.find({ 
    isci: req.user._id,
    durum: 'zimmetli'
  })
  .populate('malzemeci', 'name');

  res.status(200).json({
    success: true,
    data: inventory
  });
});

// Malzemeci için işçi listesi
const getWorkersForSupplier = catchAsync(async (req, res, next) => {
  // Önce malzemeciyi oluşturan puantajcıyı bul
  const malzemeci = await User.findById(req.user._id);
  if (!malzemeci) {
    return res.status(404).json({
      success: false,
      message: 'Malzemeci bulunamadı'
    });
  }

  // Puantajcının oluşturduğu işçileri getir
  const workers = await User.find({ 
    role: 'isci',
    createdBy: malzemeci.createdBy 
  }).select('name code');

  res.status(200).json({
    success: true,
    data: workers
  });
});

// Malzemeci için zimmet oluşturma
const createInventory = catchAsync(async (req, res, next) => {
  const { isciId, malzeme, miktar, birim, aciklama } = req.body;

  // İşçinin varlığını kontrol et
  const isci = await User.findOne({ 
    _id: isciId,
    role: 'isci'
  });

  if (!isci) {
    return res.status(404).json({
      success: false,
      message: 'İşçi bulunamadı'
    });
  }

  // Zimmet oluştur
  const inventory = await Inventory.create({
    malzemeci: req.user._id,
    isci: isciId,
    malzeme,
    miktar,
    birim,
    aciklama
  });

  res.status(201).json({
    success: true,
    data: inventory
  });
});

module.exports = {
  getAllUsers,
  getUserById,
  updateUser,
  deleteUser,
  updateProfileImage,
  getWorkers,
  getSuppliers,
  createWorker,
  createSupplier,
  getMe,
  updateMe
}; 