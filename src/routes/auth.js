const express = require('express');
const router = express.Router();
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { User } = require('../models');
const config = require('../config');
const logger = require('../utils/logger');
const memoryService = require('../services/memory.service');

// Register
router.post('/register', async (req, res, next) => {
  try {
    const { email, password, firstName, lastName, role = 'puantajci' } = req.body;

    const user = await User.create({
      email,
      password,
      firstName,
      lastName,
      role
    });

    // Remove password from response
    const userResponse = user.toJSON();
    delete userResponse.password;

    // Cache user data
    await memoryService.cacheUserData(user.id, userResponse);

    res.status(201).json({
      message: 'Kayıt başarılı',
      user: userResponse
    });
  } catch (error) {
    next(error);
  }
});

// Login
router.post('/login', async (req, res, next) => {
  try {
    const { email, password } = req.body;

    // Check cache first
    const cachedUser = await memoryService.get(`email:${email}`);
    let user;

    if (cachedUser) {
      user = await User.findByPk(cachedUser.id);
    } else {
      user = await User.findOne({ where: { email } });
      if (user) {
        const userData = user.toJSON();
        delete userData.password;
        await memoryService.set(`email:${email}`, userData);
      }
    }

    if (!user) {
      return res.status(401).json({ message: 'Geçersiz email veya şifre' });
    }

    const isValidPassword = await user.comparePassword(password);
    if (!isValidPassword) {
      return res.status(401).json({ message: 'Geçersiz email veya şifre' });
    }

    // Update last login
    user.lastLogin = new Date();
    await user.save();

    // Generate token
    const token = jwt.sign(
      { id: user.id, role: user.role },
      config.jwt.secret,
      { expiresIn: config.jwt.expiresIn }
    );

    // Remove password from response
    const userResponse = user.toJSON();
    delete userResponse.password;

    // Update cache
    await memoryService.cacheUserData(user.id, userResponse);

    res.json({
      message: 'Giriş başarılı',
      token,
      user: userResponse
    });
  } catch (error) {
    next(error);
  }
});

module.exports = router; 