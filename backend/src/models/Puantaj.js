const { DataTypes } = require('sequelize');
const sequelize = require('../config/database');

const Puantaj = sequelize.define('Puantaj', {
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
  date: {
    type: DataTypes.DATEONLY,
    allowNull: false
  },
  startTime: {
    type: DataTypes.TIME,
    allowNull: false
  },
  endTime: {
    type: DataTypes.TIME,
    allowNull: false
  },
  breakTime: {
    type: DataTypes.INTEGER, // Minutes
    defaultValue: 60
  },
  overtime: {
    type: DataTypes.INTEGER, // Minutes
    defaultValue: 0
  },
  location: {
    type: DataTypes.STRING,
    allowNull: false
  },
  notes: {
    type: DataTypes.TEXT
  },
  status: {
    type: DataTypes.ENUM('pending', 'approved', 'rejected'),
    defaultValue: 'pending'
  },
  approvedBy: {
    type: DataTypes.UUID,
    references: {
      model: 'Users',
      key: 'id'
    }
  },
  approvedAt: {
    type: DataTypes.DATE
  }
}, {
  timestamps: true,
  indexes: [
    {
      fields: ['userId', 'date'],
      unique: true
    },
    {
      fields: ['date']
    },
    {
      fields: ['status']
    }
  ]
});

// Instance method to calculate total hours
Puantaj.prototype.calculateTotalHours = function() {
  const start = new Date(`2000-01-01T${this.startTime}`);
  const end = new Date(`2000-01-01T${this.endTime}`);
  const totalMinutes = (end - start) / 1000 / 60 - this.breakTime + this.overtime;
  return Math.round(totalMinutes / 60 * 100) / 100; // Round to 2 decimal places
};

module.exports = Puantaj; 