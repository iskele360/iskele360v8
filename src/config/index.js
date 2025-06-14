require('dotenv').config();

const config = {
  server: {
    port: process.env.PORT || 3000,
    env: process.env.NODE_ENV || 'production'
  },
  database: {
    host: process.env.DB_HOST || 'dpg-d6ikbp5pdvs73fc5pig-a',
    port: process.env.DB_PORT || 5432,
    name: process.env.DB_NAME || 'iskele360_db_v8',
    user: process.env.DB_USER || 'iskele360_db_v8_user',
    password: process.env.DB_PASS || 'K9iWuJiLfXTDyT7tAfdSLWsRWCyXmaUwb'
  },
  redis: {
    url: process.env.UPSTASH_REDIS_REST_URL || 'https://magnetic-malamute-11416.upstash.io',
    token: process.env.UPSTASH_REDIS_REST_TOKEN || 'ASyYAAljcDExZTdjN2M1MTA4YjA0MDJhYWM1Mzg2MGVjZjc3ZTQxNHAxMzg2MGVjZjc3ZTQxNA'
  },
  jwt: {
    secret: process.env.JWT_SECRET || 'iskele360v81257-src-v8-baran',
    expiresIn: process.env.JWT_EXPIRES_IN || '1d'
  },
  cloudinary: {
    cloudName: process.env.CLOUDINARY_CLOUD_NAME || 'dj0gdefhc',
    apiKey: process.env.CLOUDINARY_API_KEY || '814979256919438',
    apiSecret: process.env.CLOUDINARY_API_SECRET || 'HjXB-SE4pUmaGQH8vKlKf2XxH6U'
  },
  logging: {
    level: process.env.LOG_LEVEL || 'info',
    filename: process.env.LOG_FILE || 'app.log'
  },
  cors: {
    origin: process.env.CORS_ORIGIN || '*'
  },
  rateLimiter: {
    windowMs: 15 * 60 * 1000, // 15 minutes
    max: 100 // limit each IP to 100 requests per windowMs
  },
};

module.exports = config; 