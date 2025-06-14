require('dotenv').config();

module.exports = {
  // Server Configuration
  env: process.env.NODE_ENV || 'development',
  port: process.env.PORT || 3000,
  
  // Database Configuration
  database: {
    host: process.env.DB_HOST || 'dpg-d6ikbp5pdvs73fc5pig-a',
    port: process.env.DB_PORT || 5432,
    name: process.env.DB_NAME || 'iskele360_db_v8',
    user: process.env.DB_USER || 'iskele360_db_v8_user',
    password: process.env.DB_PASS || 'K9iWuJiLfXTDyT7tAfdSLWsRWCyXmaUw'
  },
  
  // Redis Configuration
  redis: {
    url: process.env.REDIS_URL,
    token: process.env.REDIS_TOKEN
  },
  
  // JWT Configuration
  jwt: {
    secret: process.env.JWT_SECRET || 'your-secret-key',
    expiresIn: process.env.JWT_EXPIRES_IN || '1d'
  },
  
  // Cloudinary Configuration
  cloudinary: {
    cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
    api_key: process.env.CLOUDINARY_API_KEY,
    api_secret: process.env.CLOUDINARY_API_SECRET
  },
  
  // Logging Configuration
  logging: {
    level: process.env.LOG_LEVEL || 'info',
    filename: process.env.LOG_FILE || 'app.log'
  },
  
  // CORS Configuration
  cors: {
    origin: process.env.CORS_ORIGIN || '*',
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH'],
    allowedHeaders: ['Content-Type', 'Authorization']
  },
  
  // Rate Limiting Configuration
  rateLimiter: {
    windowMs: 15 * 60 * 1000, // 15 minutes
    max: 100 // limit each IP to 100 requests per windowMs
  },
}; 