import { AppError, catchAsync } from '../middleware/error.middleware.js';
import cloudinaryService from '../services/cloudinary.service.js';
import redisService from '../services/redis.service.js';
import Puantaj from '../models/puantaj.model.js';

// Create puantaj record
export const createPuantaj = catchAsync(async (req, res, next) => {
  const { isciId, giris } = req.body;

  // Check if worker already has an active entry for today
  const today = new Date();
  today.setHours(0, 0, 0, 0);
  
  const existingEntry = await Puantaj.findOne({
    isciId,
    tarih: {
      $gte: today,
      $lt: new Date(today.getTime() + 24 * 60 * 60 * 1000)
    },
    durum: { $ne: 'iptal' }
  });

  if (existingEntry) {
    return next(new AppError('Bu işçi için bugün zaten bir puantaj kaydı mevcut', 400));
  }

  // Upload entry photo if provided
  let fotoData = {};
  if (req.file) {
    try {
      const result = await cloudinaryService.uploadFile(req.file, 'iskele360/puantaj');
      fotoData = {
        url: result.url,
        publicId: result.publicId,
        timestamp: new Date()
      };
    } catch (error) {
      return next(new AppError('Fotoğraf yükleme başarısız', 500));
    }
  }

  // Create puantaj record
  const puantaj = await Puantaj.create({
    isciId,
    puantajciId: req.user._id,
    projeId: req.body.projeId,
    tarih: new Date(),
    giris: {
      saat: giris.saat,
      konum: {
        type: 'Point',
        coordinates: [
          parseFloat(giris.konum.longitude),
          parseFloat(giris.konum.latitude)
        ]
      },
      foto: fotoData
    },
    durum: 'giris',
    notlar: req.body.notlar,
    meta: {
      olusturan: req.user._id
    }
  });

  // Invalidate cache
  await redisService.invalidatePattern(`puantaj:${isciId}:*`);

  res.status(201).json({
    status: 'success',
    data: { puantaj }
  });
});

// Record exit
export const recordExit = catchAsync(async (req, res, next) => {
  const { id } = req.params;
  const { cikis } = req.body;

  const puantaj = await Puantaj.findOne({
    _id: id,
    durum: 'giris'
  });

  if (!puantaj) {
    return next(new AppError('Aktif puantaj kaydı bulunamadı', 404));
  }

  // Upload exit photo if provided
  let fotoData = {};
  if (req.file) {
    try {
      const result = await cloudinaryService.uploadFile(req.file, 'iskele360/puantaj');
      fotoData = {
        url: result.url,
        publicId: result.publicId,
        timestamp: new Date()
      };
    } catch (error) {
      return next(new AppError('Fotoğraf yükleme başarısız', 500));
    }
  }

  // Update puantaj record
  puantaj.cikis = {
    saat: cikis.saat,
    konum: {
      type: 'Point',
      coordinates: [
        parseFloat(cikis.konum.longitude),
        parseFloat(cikis.konum.latitude)
      ]
    },
    foto: fotoData
  };
  puantaj.durum = 'cikis';
  puantaj.meta.guncelleyen = req.user._id;
  puantaj.meta.guncellenmeTarihi = new Date();

  await puantaj.save();

  // Invalidate cache
  await redisService.invalidatePattern(`puantaj:${puantaj.isciId}:*`);

  res.status(200).json({
    status: 'success',
    data: { puantaj }
  });
});

// Cancel puantaj record
export const cancelPuantaj = catchAsync(async (req, res, next) => {
  const { id } = req.params;
  const { iptalNedeni } = req.body;

  const puantaj = await Puantaj.findById(id);

  if (!puantaj) {
    return next(new AppError('Puantaj kaydı bulunamadı', 404));
  }

  puantaj.durum = 'iptal';
  puantaj.meta.iptalNedeni = iptalNedeni;
  puantaj.meta.iptalEden = req.user._id;
  puantaj.meta.iptalTarihi = new Date();

  await puantaj.save();

  // Invalidate cache
  await redisService.invalidatePattern(`puantaj:${puantaj.isciId}:*`);

  res.status(200).json({
    status: 'success',
    data: { puantaj }
  });
});

// Get worker's daily records
export const getWorkerDailyRecords = catchAsync(async (req, res, next) => {
  const { isciId, date } = req.params;

  // Try to get from cache
  const cacheKey = `puantaj:${isciId}:${date}`;
  const cachedData = await redisService.getCache(cacheKey);

  if (cachedData) {
    return res.status(200).json({
      status: 'success',
      data: cachedData
    });
  }

  const queryDate = new Date(date);
  queryDate.setHours(0, 0, 0, 0);

  const records = await Puantaj.find({
    isciId,
    tarih: {
      $gte: queryDate,
      $lt: new Date(queryDate.getTime() + 24 * 60 * 60 * 1000)
    }
  }).populate('projeId', 'ad');

  // Cache the results
  await redisService.setCache(cacheKey, records, 3600); // Cache for 1 hour

  res.status(200).json({
    status: 'success',
    data: { records }
  });
});

// Get worker's monthly stats
export const getWorkerMonthlyStats = catchAsync(async (req, res, next) => {
  const { isciId, year, month } = req.params;

  // Try to get from cache
  const cacheKey = `puantaj:${isciId}:${year}-${month}:stats`;
  const cachedStats = await redisService.getCache(cacheKey);

  if (cachedStats) {
    return res.status(200).json({
      status: 'success',
      data: cachedStats
    });
  }

  const stats = await Puantaj.getWorkerMonthlyStats(isciId, parseInt(year), parseInt(month));

  // Cache the results
  await redisService.setCache(cacheKey, stats, 3600); // Cache for 1 hour

  res.status(200).json({
    status: 'success',
    data: { stats }
  });
});

// Get daily project stats
export const getDailyProjectStats = catchAsync(async (req, res, next) => {
  const { date } = req.params;

  // Try to get from cache
  const cacheKey = `puantaj:projects:${date}:stats`;
  const cachedStats = await redisService.getCache(cacheKey);

  if (cachedStats) {
    return res.status(200).json({
      status: 'success',
      data: cachedStats
    });
  }

  const stats = await Puantaj.getDailyStats(new Date(date));

  // Cache the results
  await redisService.setCache(cacheKey, stats, 1800); // Cache for 30 minutes

  res.status(200).json({
    status: 'success',
    data: { stats }
  });
});

// Get records by location
export const getRecordsByLocation = catchAsync(async (req, res, next) => {
  const { longitude, latitude, distance = 1000 } = req.query; // distance in meters

  const records = await Puantaj.find({
    $or: [
      {
        'giris.konum': {
          $near: {
            $geometry: {
              type: 'Point',
              coordinates: [parseFloat(longitude), parseFloat(latitude)]
            },
            $maxDistance: distance
          }
        }
      },
      {
        'cikis.konum': {
          $near: {
            $geometry: {
              type: 'Point',
              coordinates: [parseFloat(longitude), parseFloat(latitude)]
            },
            $maxDistance: distance
          }
        }
      }
    ]
  }).populate('isciId', 'firstName lastName');

  res.status(200).json({
    status: 'success',
    results: records.length,
    data: { records }
  });
});
