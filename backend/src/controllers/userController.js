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