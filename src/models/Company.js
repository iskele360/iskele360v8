const { DataTypes } = require('sequelize');
const sequelize = require('../config/database');

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
  address: {
    type: DataTypes.TEXT
  },
  phone: {
    type: DataTypes.STRING
  },
  email: {
    type: DataTypes.STRING,
    validate: {
      isEmail: true
    }
  },
  taxNumber: {
    type: DataTypes.STRING
  },
  isActive: {
    type: DataTypes.BOOLEAN,
    defaultValue: true
  }
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