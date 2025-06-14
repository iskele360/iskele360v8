const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const { sequelize } = require('./config/database');
const { syncModels } = require('./models');
const limiter = require('./middlewares/rateLimiter');
const errorHandler = require('./middlewares/errorHandler');
const logger = require('./utils/logger');

// Routes
const authRoutes = require('./routes/auth');
const userRoutes = require('./routes/user');

const app = express();

// Middleware
app.use(helmet());
app.use(cors());
app.use(express.json());
app.use(limiter);

// Routes
app.use('/api/auth', authRoutes);
app.use('/api/users', userRoutes);

// Error handling
app.use(errorHandler);

// Database connection and model sync
const startServer = async () => {
  try {
    await sequelize.authenticate();
    logger.info('PostgreSQL bağlantısı başarılı');

    await syncModels();
    logger.info('Modeller senkronize edildi');

    const PORT = process.env.PORT || 3000;
    app.listen(PORT, () => {
      logger.info(`Server ${PORT} portunda çalışıyor`);
    });
  } catch (error) {
    logger.error('Sunucu başlatılamadı:', error);
    process.exit(1);
  }
};

startServer(); 