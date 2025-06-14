require('dotenv').config();
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const sequelize = require('./config/database');
const redisClient = require('./config/redis');
const routes = require('./routes');

const app = express();

// Middleware
app.use(cors());
app.use(helmet());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Health check endpoint
app.get('/health', (req, res) => {
  res.status(200).json({ status: 'ok' });
});

// Routes
app.use('/api', routes);

// Test database connection
sequelize.authenticate()
  .then(() => {
    console.log('Connected to PostgreSQL successfully');
    // Sync database
    return sequelize.sync();
  })
  .then(() => {
    console.log('Database synced successfully');
    // Start server
    const PORT = process.env.PORT || 3000;
    app.listen(PORT, () => {
      console.log(`Server is running on port ${PORT}`);
    });
  })
  .catch(err => {
    console.error('Database connection/sync error:', err);
  });

// Basic route
app.get('/', (req, res) => {
  res.json({ message: 'Welcome to Iskele360 Backend API v8' });
});

// Error handling middleware
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({ error: 'Something went wrong!' });
}); 