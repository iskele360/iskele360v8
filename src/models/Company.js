const { DataTypes } = require('sequelize');
const { sequelize } = require('../config/database');

const Company = sequelize.define('Company', {
  id: {
    type: DataTypes.UUID,
    defaultValue: DataTypes.UUIDV4,
    primaryKey: true
  },
  name: {
    type: DataTypes.STRING,
    allowNull: false
  },
  taxNumber: {
    type: DataTypes.STRING,
    allowNull: false,
    unique: true
  },
  taxOffice: {
    type: DataTypes.STRING,
    allowNull: true
  },
  address: {
    type: DataTypes.TEXT,
    allowNull: true
  },
  phone: {
    type: DataTypes.STRING,
    allowNull: true
  },
  email: {
    type: DataTypes.STRING,
    allowNull: true,
    validate: {
      isEmail: true
    }
  },
  authorizedPerson: {
    type: DataTypes.STRING,
    allowNull: true
  },
  authorizedPhone: {
    type: DataTypes.STRING,
    allowNull: true
  },
  isActive: {
    type: DataTypes.BOOLEAN,
    defaultValue: true
  },
  notes: {
    type: DataTypes.TEXT,
    allowNull: true
  }
}, {
  timestamps: true,
  paranoid: true // Soft delete
});

// Create indexes
Company.createIndexes = async () => {
  await Company.sync();
  await sequelize.query(`
    CREATE INDEX IF NOT EXISTS companies_tax_number_idx ON "Companies" ("taxNumber");
    CREATE INDEX IF NOT EXISTS companies_name_idx ON "Companies" ("name");
  `);
};

module.exports = Company; 