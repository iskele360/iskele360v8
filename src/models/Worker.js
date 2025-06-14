const { DataTypes } = require('sequelize');
const { sequelize } = require('../config/database');
const cloudinaryService = require('../services/cloudinary.service');

const Worker = sequelize.define('Worker', {
  id: {
    type: DataTypes.UUID,
    defaultValue: DataTypes.UUIDV4,
    primaryKey: true
  },
  firstName: {
    type: DataTypes.STRING,
    allowNull: false
  },
  lastName: {
    type: DataTypes.STRING,
    allowNull: false
  },
  nationalId: {
    type: DataTypes.STRING,
    unique: true
  },
  phone: {
    type: DataTypes.STRING
  },
  address: {
    type: DataTypes.TEXT
  },
  photoUrl: {
    type: DataTypes.STRING
  },
  isActive: {
    type: DataTypes.BOOLEAN,
    defaultValue: true
  },
  companyId: {
    type: DataTypes.UUID,
    references: {
      model: 'Companies',
      key: 'id'
    }
  },
  userId: {
    type: DataTypes.UUID,
    allowNull: false,
    references: {
      model: 'Users',
      key: 'id'
    }
  },
  tcNo: {
    type: DataTypes.STRING(11),
    allowNull: false,
    unique: true,
    validate: {
      len: [11, 11],
      isNumeric: true
    }
  },
  birthDate: {
    type: DataTypes.DATEONLY,
    allowNull: false
  },
  startDate: {
    type: DataTypes.DATEONLY,
    allowNull: false
  },
  endDate: {
    type: DataTypes.DATEONLY,
    allowNull: true
  },
  position: {
    type: DataTypes.STRING,
    allowNull: false
  },
  salary: {
    type: DataTypes.DECIMAL(10, 2),
    allowNull: false
  },
  salaryType: {
    type: DataTypes.ENUM('daily', 'monthly'),
    defaultValue: 'daily'
  },
  bloodType: {
    type: DataTypes.STRING,
    allowNull: true
  },
  emergencyContact: {
    type: DataTypes.STRING,
    allowNull: true
  },
  emergencyPhone: {
    type: DataTypes.STRING,
    allowNull: true
  },
  notes: {
    type: DataTypes.TEXT,
    allowNull: true
  },
  photoPublicId: {
    type: DataTypes.STRING,
    allowNull: true
  }
}, {
  timestamps: true,
  paranoid: true, // Soft delete
  hooks: {
    beforeDestroy: async (worker) => {
      if (worker.photoPublicId) {
        await cloudinaryService.deleteImage(worker.photoPublicId);
      }
    }
  }
});

// Create indexes
Worker.createIndexes = async () => {
  await Worker.sync();
  await sequelize.query(`
    CREATE INDEX IF NOT EXISTS workers_tc_no_idx ON "Workers" ("tcNo");
    CREATE INDEX IF NOT EXISTS workers_company_id_idx ON "Workers" ("companyId");
    CREATE INDEX IF NOT EXISTS workers_user_id_idx ON "Workers" ("userId");
  `);
};

module.exports = Worker; 