# İskele360 Backend v8

Modern Node.js backend for İskele360 project, built with Express.js and PostgreSQL.

## Features

- 🔐 JWT Authentication
- 📊 PostgreSQL Database
- 🚀 Redis Caching
- ☁️ Cloudinary Integration
- 🔒 Rate Limiting
- 📝 Detailed Logging
- 🛡️ Security Headers
- 🌐 CORS Support

## Tech Stack

- Node.js v20.19.2
- Express.js
- PostgreSQL (via Sequelize ORM)
- Redis (via Upstash)
- Cloudinary
- JWT

## Prerequisites

- Node.js v20.19.2
- PostgreSQL
- Redis

## Setup

1. Clone the repository:
```bash
git clone https://github.com/yourusername/iskele360-backend-v8.git
cd iskele360-backend-v8
```

2. Install dependencies:
```bash
npm install
```

3. Create .env file:
```bash
cp .env.example .env
```

4. Update environment variables in .env file with your values.

5. Start the development server:
```bash
npm run dev
```

## Project Structure

```
src/
├── config/
│   └── database.js
├── controllers/
│   ├── authController.js
│   ├── userController.js
│   └── puantajController.js
├── models/
│   ├── User.js
│   └── Puantaj.js
├── routes/
│   ├── auth.js
│   ├── userRoutes.js
│   └── puantaj.js
├── middleware/
│   └── verifyToken.js
├── services/
│   ├── redisService.js
│   └── cloudinaryService.js
└── server.js
```

## API Endpoints

### Authentication
- POST /api/auth/register - Register new user
- POST /api/auth/login - Login user
- POST /api/auth/logout - Logout user
- GET /api/auth/me - Get current user

### Users
- GET /api/users - Get all users (admin only)
- GET /api/users/:id - Get user by ID
- PUT /api/users/:id - Update user
- DELETE /api/users/:id - Delete user (admin only)
- POST /api/users/profile-image - Update profile image

### Puantaj
- GET /api/puantaj - Get all puantaj records
- GET /api/puantaj/:id - Get puantaj by ID
- POST /api/puantaj - Create new puantaj
- PUT /api/puantaj/:id - Update puantaj
- DELETE /api/puantaj/:id - Delete puantaj
- POST /api/puantaj/:id/approve - Approve puantaj (manager only)
- POST /api/puantaj/:id/reject - Reject puantaj (manager only)
- GET /api/puantaj/user/:userId - Get user's puantaj records
- GET /api/puantaj/stats/overview - Get puantaj statistics

## Deployment

The application is configured for deployment on Render.com. The deployment configuration is in `render.yaml`.

### Deployment Steps

1. Create a new Web Service on Render
2. Connect your GitHub repository
3. Use the following settings:
   - Environment: Node
   - Build Command: `npm install`
   - Start Command: `npm start`
   - Auto-Deploy: Yes

### Environment Variables

Make sure to set all environment variables in Render dashboard as specified in `.env.example`.

## License

This project is private and confidential. All rights reserved. 