const { sequelize } = require('../config/database');
const User = require('./User');
const Company = require('./Company');
const Worker = require('./Worker');

// User - Worker İlişkisi (1:1)
User.hasOne(Worker);
Worker.belongsTo(User);

// Company - Worker İlişkisi (1:N)
Company.hasMany(Worker, { foreignKey: 'companyId' });
Worker.belongsTo(Company, { foreignKey: 'companyId' });

// Model senkronizasyonu
const syncModels = async () => {
  try {
    await sequelize.sync({ alter: true });
    console.log('Modeller senkronize edildi');
    
    // İndeksleri oluştur
    await Promise.all([
      User.createIndexes(),
      Company.createIndexes(),
      Worker.createIndexes()
    ]);
    console.log('İndeksler oluşturuldu');
  } catch (error) {
    console.error('Model senkronizasyon hatası:', error);
    throw error;
  }
};

module.exports = {
  sequelize,
  User,
  Company,
  Worker,
  syncModels
}; 