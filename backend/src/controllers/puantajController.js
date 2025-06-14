const { Op } = require('sequelize');
const Puantaj = require('../models/Puantaj');
const User = require('../models/User');
const redis = require('../services/redisService');
const sequelize = require('sequelize');

const getAllPuantaj = async (req, res) => {
  try {
    const { startDate, endDate, status, location } = req.query;
    const where = {};

    // Date range filter
    if (startDate || endDate) {
      where.date = {};
      if (startDate) where.date[Op.gte] = startDate;
      if (endDate) where.date[Op.lte] = endDate;
    }

    // Status filter
    if (status) where.status = status;

    // Location filter
    if (location) where.location = location;

    // Role-based filtering
    if (req.user.role === 'user') {
      where.userId = req.user.id;
    } else if (req.user.role === 'manager') {
      // Managers can see their team's records
      const teamMembers = await User.findAll({
        where: { supervisorId: req.user.id },
        attributes: ['id']
      });
      where.userId = {
        [Op.in]: teamMembers.map(member => member.id)
      };
    }
    // Admins can see all records

    const puantajRecords = await Puantaj.findAll({
      where,
      include: [{
        model: User,
        as: 'user',
        attributes: ['id', 'firstName', 'lastName', 'email']
      }],
      order: [['date', 'DESC']]
    });

    res.json({
      success: true,
      data: puantajRecords
    });
  } catch (error) {
    console.error('Get all puantaj error:', error);
    res.status(500).json({
      success: false,
      message: 'Error getting puantaj records'
    });
  }
};

const getPuantajById = async (req, res) => {
  try {
    const puantaj = await Puantaj.findByPk(req.params.id, {
      include: [{
        model: User,
        as: 'user',
        attributes: ['id', 'firstName', 'lastName', 'email']
      }]
    });

    if (!puantaj) {
      return res.status(404).json({
        success: false,
        message: 'Puantaj record not found'
      });
    }

    // Check permissions
    if (req.user.role === 'user' && puantaj.userId !== req.user.id) {
      return res.status(403).json({
        success: false,
        message: 'Not authorized'
      });
    }

    res.json({
      success: true,
      data: puantaj
    });
  } catch (error) {
    console.error('Get puantaj error:', error);
    res.status(500).json({
      success: false,
      message: 'Error getting puantaj record'
    });
  }
};

const createPuantaj = async (req, res) => {
  try {
    const { date, startTime, endTime, location, notes } = req.body;

    // Check if puantaj already exists for this date
    const existingPuantaj = await Puantaj.findOne({
      where: {
        userId: req.user.id,
        date
      }
    });

    if (existingPuantaj) {
      return res.status(400).json({
        success: false,
        message: 'Puantaj record already exists for this date'
      });
    }

    const puantaj = await Puantaj.create({
      userId: req.user.id,
      date,
      startTime,
      endTime,
      location,
      notes
    });

    // Clear cache
    await redis.del(`puantaj:user:${req.user.id}`);

    res.status(201).json({
      success: true,
      data: puantaj
    });
  } catch (error) {
    console.error('Create puantaj error:', error);
    res.status(500).json({
      success: false,
      message: 'Error creating puantaj record'
    });
  }
};

const updatePuantaj = async (req, res) => {
  try {
    const puantaj = await Puantaj.findByPk(req.params.id);
    if (!puantaj) {
      return res.status(404).json({
        success: false,
        message: 'Puantaj record not found'
      });
    }

    // Check permissions
    if (req.user.role === 'user' && puantaj.userId !== req.user.id) {
      return res.status(403).json({
        success: false,
        message: 'Not authorized'
      });
    }

    // Only allow updates if status is pending
    if (puantaj.status !== 'pending') {
      return res.status(400).json({
        success: false,
        message: 'Cannot update approved or rejected puantaj'
      });
    }

    const { startTime, endTime, location, notes } = req.body;

    await puantaj.update({
      startTime: startTime || puantaj.startTime,
      endTime: endTime || puantaj.endTime,
      location: location || puantaj.location,
      notes: notes || puantaj.notes
    });

    // Clear cache
    await redis.del(`puantaj:user:${puantaj.userId}`);

    res.json({
      success: true,
      data: puantaj
    });
  } catch (error) {
    console.error('Update puantaj error:', error);
    res.status(500).json({
      success: false,
      message: 'Error updating puantaj record'
    });
  }
};

const deletePuantaj = async (req, res) => {
  try {
    const puantaj = await Puantaj.findByPk(req.params.id);
    if (!puantaj) {
      return res.status(404).json({
        success: false,
        message: 'Puantaj record not found'
      });
    }

    // Check permissions
    if (req.user.role === 'user' && puantaj.userId !== req.user.id) {
      return res.status(403).json({
        success: false,
        message: 'Not authorized'
      });
    }

    // Only allow deletion if status is pending
    if (puantaj.status !== 'pending') {
      return res.status(400).json({
        success: false,
        message: 'Cannot delete approved or rejected puantaj'
      });
    }

    await puantaj.destroy();

    // Clear cache
    await redis.del(`puantaj:user:${puantaj.userId}`);

    res.json({
      success: true,
      message: 'Puantaj record deleted successfully'
    });
  } catch (error) {
    console.error('Delete puantaj error:', error);
    res.status(500).json({
      success: false,
      message: 'Error deleting puantaj record'
    });
  }
};

const approvePuantaj = async (req, res) => {
  try {
    // Only managers can approve
    if (req.user.role !== 'manager' && req.user.role !== 'admin') {
      return res.status(403).json({
        success: false,
        message: 'Not authorized'
      });
    }

    const puantaj = await Puantaj.findByPk(req.params.id);
    if (!puantaj) {
      return res.status(404).json({
        success: false,
        message: 'Puantaj record not found'
      });
    }

    // Check if the user is under this manager
    if (req.user.role === 'manager') {
      const user = await User.findByPk(puantaj.userId);
      if (user.supervisorId !== req.user.id) {
        return res.status(403).json({
          success: false,
          message: 'Not authorized'
        });
      }
    }

    await puantaj.update({
      status: 'approved',
      approvedBy: req.user.id,
      approvedAt: new Date()
    });

    // Clear cache
    await redis.del(`puantaj:user:${puantaj.userId}`);

    res.json({
      success: true,
      data: puantaj
    });
  } catch (error) {
    console.error('Approve puantaj error:', error);
    res.status(500).json({
      success: false,
      message: 'Error approving puantaj record'
    });
  }
};

const rejectPuantaj = async (req, res) => {
  try {
    // Only managers can reject
    if (req.user.role !== 'manager' && req.user.role !== 'admin') {
      return res.status(403).json({
        success: false,
        message: 'Not authorized'
      });
    }

    const puantaj = await Puantaj.findByPk(req.params.id);
    if (!puantaj) {
      return res.status(404).json({
        success: false,
        message: 'Puantaj record not found'
      });
    }

    // Check if the user is under this manager
    if (req.user.role === 'manager') {
      const user = await User.findByPk(puantaj.userId);
      if (user.supervisorId !== req.user.id) {
        return res.status(403).json({
          success: false,
          message: 'Not authorized'
        });
      }
    }

    await puantaj.update({
      status: 'rejected',
      approvedBy: req.user.id,
      approvedAt: new Date()
    });

    // Clear cache
    await redis.del(`puantaj:user:${puantaj.userId}`);

    res.json({
      success: true,
      data: puantaj
    });
  } catch (error) {
    console.error('Reject puantaj error:', error);
    res.status(500).json({
      success: false,
      message: 'Error rejecting puantaj record'
    });
  }
};

const getUserPuantaj = async (req, res) => {
  try {
    const { startDate, endDate, status } = req.query;
    const userId = req.params.userId;

    // Check permissions
    if (req.user.role === 'user' && userId !== req.user.id) {
      return res.status(403).json({
        success: false,
        message: 'Not authorized'
      });
    }

    // Try to get from cache first
    const cacheKey = `puantaj:user:${userId}`;
    const cachedData = await redis.get(cacheKey);
    if (cachedData && !startDate && !endDate && !status) {
      return res.json({
        success: true,
        data: JSON.parse(cachedData)
      });
    }

    const where = { userId };

    // Date range filter
    if (startDate || endDate) {
      where.date = {};
      if (startDate) where.date[Op.gte] = startDate;
      if (endDate) where.date[Op.lte] = endDate;
    }

    // Status filter
    if (status) where.status = status;

    const puantajRecords = await Puantaj.findAll({
      where,
      order: [['date', 'DESC']]
    });

    // Cache the results
    if (!startDate && !endDate && !status) {
      await redis.set(cacheKey, JSON.stringify(puantajRecords), 'EX', 3600); // 1 hour
    }

    res.json({
      success: true,
      data: puantajRecords
    });
  } catch (error) {
    console.error('Get user puantaj error:', error);
    res.status(500).json({
      success: false,
      message: 'Error getting user puantaj records'
    });
  }
};

const getPuantajStats = async (req, res) => {
  try {
    const { startDate, endDate } = req.query;
    const where = {};

    // Date range filter
    if (startDate || endDate) {
      where.date = {};
      if (startDate) where.date[Op.gte] = startDate;
      if (endDate) where.date[Op.lte] = endDate;
    }

    // Role-based filtering
    if (req.user.role === 'user') {
      where.userId = req.user.id;
    } else if (req.user.role === 'manager') {
      const teamMembers = await User.findAll({
        where: { supervisorId: req.user.id },
        attributes: ['id']
      });
      where.userId = {
        [Op.in]: teamMembers.map(member => member.id)
      };
    }

    const stats = await Puantaj.findAll({
      where,
      attributes: [
        [sequelize.fn('COUNT', sequelize.col('id')), 'totalRecords'],
        [sequelize.fn('SUM', sequelize.col('overtime')), 'totalOvertime'],
        [sequelize.fn('AVG', 
          sequelize.fn('TIMESTAMPDIFF', 
            sequelize.literal('MINUTE'), 
            sequelize.col('startTime'), 
            sequelize.col('endTime')
          )
        ), 'avgWorkingMinutes'],
        [sequelize.fn('COUNT', 
          sequelize.literal('CASE WHEN status = "approved" THEN 1 END')
        ), 'approvedCount'],
        [sequelize.fn('COUNT', 
          sequelize.literal('CASE WHEN status = "rejected" THEN 1 END')
        ), 'rejectedCount'],
        [sequelize.fn('COUNT', 
          sequelize.literal('CASE WHEN status = "pending" THEN 1 END')
        ), 'pendingCount']
      ],
      group: [sequelize.fn('DATE_FORMAT', sequelize.col('date'), '%Y-%m')]
    });

    res.json({
      success: true,
      data: stats
    });
  } catch (error) {
    console.error('Get puantaj stats error:', error);
    res.status(500).json({
      success: false,
      message: 'Error getting puantaj statistics'
    });
  }
};

module.exports = {
  getAllPuantaj,
  getPuantajById,
  createPuantaj,
  updatePuantaj,
  deletePuantaj,
  approvePuantaj,
  rejectPuantaj,
  getUserPuantaj,
  getPuantajStats
}; 