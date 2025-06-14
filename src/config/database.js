const { Sequelize } = require('sequelize');

const sequelize = new Sequelize({
  dialect: 'postgres',
  host: process.env.DB_HOST || 'dpg-d6ikbp5pdvs73fc5pig-a',
  port: process.env.DB_PORT || 5432,
  database: process.env.DB_NAME || 'iskele360_db_v8',
  username: process.env.DB_USER || 'iskele360_db_v8_user',
  password: process.env.DB_PASS || 'K9iWuJiLfXTDyT7tAfdSLWsRWCyXmaUw',
  dialectOptions: {
    ssl: {
      require: true,
      rejectUnauthorized: false
    }
  }
});

module.exports = { sequelize }; 