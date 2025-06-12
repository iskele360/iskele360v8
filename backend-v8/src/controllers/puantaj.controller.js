const Puantaj = require('../models/puantaj.model');
const User = require('../models/user.model');
const { AppError, catchAsync } = require('../middleware/error.middleware');
const redisService = require('../services/redis.service');
const cloudinaryService = require('../services/cloudinary.service');

exports.createPuantaj = catchAsync(async (req, res, next) => {
  // 1) İşçi kontrolü
  const isci = await User.findById(req.body.isciId);
  if (!isci || isci.role !== 'isci') {
    return next(new AppError('Geçersiz işçi ID', 400));
  }

  // 2) Puantaj oluştur
  const puantaj = await Puantaj.create({
    ...req.body,
    puantajciId: req.user._id,
    meta: {
      deviceInfo: req.body.deviceInfo,
      ipAddress: req.ip,
      userAgent: req.headers['user-agent']
    }
  });

  // 3) Cache'i temizle
  await redisService.invalidatePuantajCache(req.body.isciId);
  await redisService.invalidatePuantajCache(req.user._id);

  res.status(201).json({
    status: 'success',
    data: {
      puantaj
    }
  });
});

exports.getPuantajList = catchAsync(async (req, res, next) => {
  const page = parseInt(req.query.page) || 1;
  const limit = parseInt(req.query.limit) || 10;
  const skip = (page - 1) * limit;

  // 1) Cache kontrolü
  const cacheKey = `puantaj:list:${req.user._id}:${page}:${limit}`;
  const cachedData = await redisService.get(cacheKey);

  if (cachedData) {
    return res.status(200).json({
      status: 'success',
      data: cachedData
    });
  }

  // 2) Filtreleme
  const filter = {};
  
  if (req.user.role === 'isci') {
    filter.isciId = req.user._id;
  } else if (req.user.role === 'puantajci') {
    filter.puantajciId = req.user._id;
  }

  if (req.query.baslangicTarihi && req.query.bitisTarihi) {
    filter.tarih = {
      $gte: new Date(req.query.baslangicTarihi),
      $lte: new Date(req.query.bitisTarihi)
    };
  }

  if (req.query.durum) {
    filter.durum = req.query.durum;
  }

  // 3) Puantajları getir
  const puantajlar = await Puantaj.find(filter)
    .sort({ tarih: -1, createdAt: -1 })
    .skip(skip)
    .limit(limit)
    .populate('worker', 'firstName lastName code')
    .populate('supervisor', 'firstName lastName');

  const total = await Puantaj.countDocuments(filter);

  // 4) Response'u cache'le
  const response = {
    status: 'success',
    results: puantajlar.length,
    pagination: {
      page,
      limit,
      total,
      pages: Math.ceil(total / limit)
    },
    data: {
      puantajlar
    }
  };

  await redisService.set(cacheKey, response, 300); // 5 dakika cache

  res.status(200).json(response);
});

exports.getPuantaj = catchAsync(async (req, res, next) => {
  const puantaj = await Puantaj.findById(req.params.id)
    .populate('worker', 'firstName lastName code')
    .populate('supervisor', 'firstName lastName');

  if (!puantaj) {
    return next(new AppError('Puantaj bulunamadı', 404));
  }

  // Yetki kontrolü
  if (
    req.user.role !== 'admin' &&
    puantaj.isciId.toString() !== req.user._id.toString() &&
    puantaj.puantajciId.toString() !== req.user._id.toString()
  ) {
    return next(new AppError('Bu puantajı görüntüleme yetkiniz yok', 403));
  }

  res.status(200).json({
    status: 'success',
    data: {
      puantaj
    }
  });
});

exports.updatePuantaj = catchAsync(async (req, res, next) => {
  // 1) Puantajı bul
  const puantaj = await Puantaj.findById(req.params.id);

  if (!puantaj) {
    return next(new AppError('Puantaj bulunamadı', 404));
  }

  // 2) Yetki kontrolü
  if (
    req.user.role !== 'admin' &&
    puantaj.puantajciId.toString() !== req.user._id.toString()
  ) {
    return next(new AppError('Bu puantajı düzenleme yetkiniz yok', 403));
  }

  // 3) Güncelleme
  Object.assign(puantaj, req.body);
  
  // Değişiklik geçmişi ekle
  puantaj.degisiklikGecmisi.push({
    degistirenId: req.user._id,
    aciklama: req.body.degisiklikAciklamasi || 'Puantaj güncellendi'
  });

  await puantaj.save();

  // 4) Cache'i temizle
  await redisService.invalidatePuantajCache(puantaj.isciId);
  await redisService.invalidatePuantajCache(puantaj.puantajciId);

  res.status(200).json({
    status: 'success',
    data: {
      puantaj
    }
  });
});

exports.deletePuantaj = catchAsync(async (req, res, next) => {
  const puantaj = await Puantaj.findById(req.params.id);

  if (!puantaj) {
    return next(new AppError('Puantaj bulunamadı', 404));
  }

  // Yetki kontrolü
  if (
    req.user.role !== 'admin' &&
    puantaj.puantajciId.toString() !== req.user._id.toString()
  ) {
    return next(new AppError('Bu puantajı silme yetkiniz yok', 403));
  }

  // Fotoğrafları Cloudinary'den sil
  if (puantaj.fotograf && puantaj.fotograf.length > 0) {
    const publicIds = puantaj.fotograf.map(f => f.publicId);
    await cloudinaryService.deleteMultipleImages(publicIds);
  }

  await puantaj.remove();

  // Cache'i temizle
  await redisService.invalidatePuantajCache(puantaj.isciId);
  await redisService.invalidatePuantajCache(puantaj.puantajciId);

  res.status(204).json({
    status: 'success',
    data: null
  });
});

exports.uploadFotograf = catchAsync(async (req, res, next) => {
  if (!req.files || !req.files.length) {
    return next(new AppError('Lütfen fotoğraf yükleyin', 400));
  }

  const puantaj = await Puantaj.findById(req.params.id);

  if (!puantaj) {
    return next(new AppError('Puantaj bulunamadı', 404));
  }

  // Yetki kontrolü
  if (
    req.user.role !== 'admin' &&
    puantaj.puantajciId.toString() !== req.user._id.toString()
  ) {
    return next(new AppError('Bu puantaja fotoğraf ekleme yetkiniz yok', 403));
  }

  // Fotoğrafları Cloudinary'e yükle
  const uploadPromises = req.files.map(file =>
    cloudinaryService.uploadImage(file.path, `puantaj/${puantaj._id}`)
  );

  const uploadedImages = await Promise.all(uploadPromises);

  // Puantaja fotoğrafları ekle
  uploadedImages.forEach(img => {
    puantaj.fotograf.push({
      url: img.url,
      publicId: img.publicId
    });
  });

  await puantaj.save();

  res.status(200).json({
    status: 'success',
    data: {
      puantaj
    }
  });
});

exports.deleteFotograf = catchAsync(async (req, res, next) => {
  const { id, fotografId } = req.params;

  const puantaj = await Puantaj.findById(id);

  if (!puantaj) {
    return next(new AppError('Puantaj bulunamadı', 404));
  }

  // Yetki kontrolü
  if (
    req.user.role !== 'admin' &&
    puantaj.puantajciId.toString() !== req.user._id.toString()
  ) {
    return next(new AppError('Bu puantajdan fotoğraf silme yetkiniz yok', 403));
  }

  // Fotoğrafı bul
  const fotograf = puantaj.fotograf.id(fotografId);

  if (!fotograf) {
    return next(new AppError('Fotoğraf bulunamadı', 404));
  }

  // Cloudinary'den sil
  await cloudinaryService.deleteImage(fotograf.publicId);

  // Puantajdan sil
  fotograf.remove();
  await puantaj.save();

  res.status(204).json({
    status: 'success',
    data: null
  });
});
