const express = require('express');
const multer = require('multer');
const puantajController = require('../controllers/puantaj.controller');
const authMiddleware = require('../middleware/auth.middleware');
const { catchAsync } = require('../middleware/error.middleware');

const router = express.Router();

// Multer configuration
const upload = multer({
  storage: multer.diskStorage({}),
  limits: {
    fileSize: parseInt(process.env.MAX_FILE_SIZE),
    files: parseInt(process.env.MAX_FILES_PER_REQUEST)
  },
  fileFilter: (req, file, cb) => {
    if (!file.mimetype.startsWith('image/')) {
      return cb(new Error('Sadece resim dosyaları yüklenebilir'), false);
    }
    cb(null, true);
  }
});

// Protect all routes
router.use(authMiddleware.protect);
router.use(authMiddleware.isActive);

// Public routes (authenticated users)
router.get('/list',
  catchAsync(puantajController.getPuantajList)
);

router.get('/:id',
  catchAsync(puantajController.getPuantaj)
);

// Worker routes
router.use(authMiddleware.restrictTo('isci'));

router.get('/my/list',
  catchAsync(async (req, res, next) => {
    req.query.isciId = req.user._id;
    await puantajController.getPuantajList(req, res, next);
  })
);

// Supervisor routes
router.use(authMiddleware.restrictTo('admin', 'puantajci'));

router.post('/',
  catchAsync(puantajController.createPuantaj)
);

router.patch('/:id',
  catchAsync(puantajController.updatePuantaj)
);

router.delete('/:id',
  catchAsync(puantajController.deletePuantaj)
);

// Photo upload routes
router.post('/:id/fotograf',
  upload.array('photos', parseInt(process.env.MAX_FILES_PER_REQUEST)),
  catchAsync(puantajController.uploadFotograf)
);

router.delete('/:id/fotograf/:fotografId',
  catchAsync(puantajController.deleteFotograf)
);

// Bulk operations (admin only)
router.use(authMiddleware.restrictTo('admin'));

router.post('/bulk/create',
  catchAsync(async (req, res, next) => {
    const puantajlar = await Promise.all(
      req.body.puantajlar.map(async (puantajData) => {
        const puantaj = await Puantaj.create({
          ...puantajData,
          puantajciId: req.user._id
        });
        return puantaj;
      })
    );

    res.status(201).json({
      status: 'success',
      results: puantajlar.length,
      data: {
        puantajlar
      }
    });
  })
);

router.patch('/bulk/update',
  catchAsync(async (req, res, next) => {
    const puantajlar = await Promise.all(
      req.body.puantajlar.map(async ({ id, ...updateData }) => {
        const puantaj = await Puantaj.findByIdAndUpdate(
          id,
          {
            ...updateData,
            $push: {
              degisiklikGecmisi: {
                degistirenId: req.user._id,
                aciklama: 'Toplu güncelleme'
              }
            }
          },
          { new: true }
        );
        return puantaj;
      })
    );

    res.status(200).json({
      status: 'success',
      results: puantajlar.length,
      data: {
        puantajlar
      }
    });
  })
);

router.delete('/bulk/delete',
  catchAsync(async (req, res, next) => {
    const { ids } = req.body;

    await Puantaj.deleteMany({ _id: { $in: ids } });

    res.status(204).json({
      status: 'success',
      data: null
    });
  })
);

// Statistics routes
router.get('/stats/daily',
  catchAsync(async (req, res, next) => {
    const stats = await Puantaj.aggregate([
      {
        $match: {
          tarih: {
            $gte: new Date(new Date().setHours(0, 0, 0, 0)),
            $lte: new Date(new Date().setHours(23, 59, 59, 999))
          }
        }
      },
      {
        $group: {
          _id: null,
          totalPuantaj: { $sum: 1 },
          totalHours: { $sum: '$calismaSuresi' },
          avgHours: { $avg: '$calismaSuresi' }
        }
      }
    ]);

    res.status(200).json({
      status: 'success',
      data: {
        stats: stats[0] || {
          totalPuantaj: 0,
          totalHours: 0,
          avgHours: 0
        }
      }
    });
  })
);

router.get('/stats/monthly',
  catchAsync(async (req, res, next) => {
    const year = parseInt(req.query.year) || new Date().getFullYear();
    const month = parseInt(req.query.month) || new Date().getMonth() + 1;

    const startDate = new Date(year, month - 1, 1);
    const endDate = new Date(year, month, 0);

    const stats = await Puantaj.aggregate([
      {
        $match: {
          tarih: {
            $gte: startDate,
            $lte: endDate
          }
        }
      },
      {
        $group: {
          _id: { $dayOfMonth: '$tarih' },
          totalPuantaj: { $sum: 1 },
          totalHours: { $sum: '$calismaSuresi' }
        }
      },
      {
        $sort: { _id: 1 }
      }
    ]);

    res.status(200).json({
      status: 'success',
      data: {
        year,
        month,
        stats
      }
    });
  })
);

module.exports = router;
