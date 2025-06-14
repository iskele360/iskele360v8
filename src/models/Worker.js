const { DataTypes } = require('sequelize');
const { sequelize } = require('../config/database');

const Worker = sequelize.define('Worker', {
  id: {
    type: DataTypes.UUID,
    defaultValue: DataTypes.UUIDV4,
    primaryKey: true
  },
  userId: {
    type: DataTypes.UUID,
    allowNull: false,
    references: {
      model: 'Users',
      key: 'id'
    }
  },
  companyId: {
    type: DataTypes.UUID,
    allowNull: false,
    references: {
      model: 'Companies',
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
  isActive: {
    type: DataTypes.BOOLEAN,
    defaultValue: true
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
  address: {
    type: DataTypes.TEXT,
    allowNull: true
  },
  notes: {
    type: DataTypes.TEXT,
    allowNull: true
  },
  photoUrl: {
    type: DataTypes.STRING,
    allowNull: true
  }
}, {
  timestamps: true,
  paranoid: true // Soft delete
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