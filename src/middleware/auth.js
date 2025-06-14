const jwt = require('jsonwebtoken');
const redisClient = require('../config/redis');

const authenticateToken = async (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;
    const token = authHeader && authHeader.split(' ')[1];

    if (!token) {
      return res.status(401).json({ message: 'No token provided' });
    }

    const decoded = jwt.verify(token, process.env.JWT_SECRET || 'your_jwt_secret');
    
    // Check Redis cache
    const cachedUser = await redisClient.get(`user:${decoded.id}`);
    if (cachedUser) {
      req.user = JSON.parse(cachedUser);
    } else {
      req.user = decoded;
    }

    next();
  } catch (error) {
    console.error('Authentication error:', error);
    return res.status(403).json({ message: 'Invalid token' });
  }
};

const isAdmin = (req, res, next) => {
  if (req.user && req.user.role === 'admin') {
    next();
  } else {
    res.status(403).json({ message: 'Access denied. Admin role required.' });
  }
};

module.exports = {
  authenticateToken,
  isAdmin
}; 