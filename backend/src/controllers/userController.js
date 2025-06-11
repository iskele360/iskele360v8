const User = require('../models/User');

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

// Puantajcının başka bir kullanıcıyı silmesi
exports.deleteUser = async (req, res) => {
  try {
    // Silinecek kullanıcı ID'si
    const { userId } = req.params;

    // Kullanıcıyı bul
    const userToDelete = await User.findById(userId);

    if (!userToDelete) {
      return res.status(404).json({
        success: false,
        message: 'Kullanıcı bulunamadı'
      });
    }

    // Yalnızca puantajcı rolündeki kullanıcılar başkasını silebilir
    if (req.user.role !== 'puantajcı' && req.user.role !== 'admin') {
      return res.status(403).json({
        success: false,
        message: 'Bu işlem için yetkiniz bulunmamaktadır'
      });
    }

    // Puantajcı yalnızca kendi oluşturduğu kullanıcıları silebilir
    if (req.user.role === 'puantajcı' && 
        userToDelete.createdBy && 
        userToDelete.createdBy.toString() !== req.user._id.toString()) {
      return res.status(403).json({
        success: false,
        message: 'Yalnızca kendi oluşturduğunuz kullanıcıları silebilirsiniz'
      });
    }

    // Kullanıcıyı sil
    await User.findByIdAndDelete(userId);

    // İlişkili diğer verileri de silmek için gerekli işlemler burada yapılabilir
    // Örneğin: puantaj kayıtları, zimmet kayıtları, vb.
    
    // TODO: Puantaj ve zimmet silme işlemleri eklenecek

    res.status(200).json({
      success: true,
      message: 'Kullanıcı başarıyla silindi'
    });
  } catch (error) {
    console.error('Kullanıcı silme hatası:', error);
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
    let query = {};
    
    // Puantajcı yalnızca kendi oluşturduğu kullanıcıları görebilir
    if (req.user.role === 'puantajcı') {
      query.createdBy = req.user._id;
    }
    
    // Admin tüm kullanıcıları görebilir
    
    const users = await User.find(query);
    
    res.status(200).json({
      success: true,
      count: users.length,
      data: users
    });
  } catch (error) {
    console.error('Kullanıcı listeleme hatası:', error);
    res.status(500).json({
      success: false,
      message: 'Sunucu hatası, lütfen daha sonra tekrar deneyin'
    });
  }
}; 