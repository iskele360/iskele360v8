# Use Node.js 18 Alpine as base image
FROM node:18-alpine

# Install additional dependencies
RUN apk add --no-cache \
    python3 \
    make \
    g++ \
    jpeg-dev \
    cairo-dev \
    giflib-dev \
    pango-dev \
    libtool \
    autoconf \
    automake

# Set working directory
WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm ci --only=production

# Copy application files
COPY . .

# Create necessary directories
RUN mkdir -p /app/uploads /app/logs

# Set environment variables
ENV NODE_ENV=production \
    PORT=3000 \
    TZ=Europe/Istanbul

# Expose port
EXPOSE 3000

# Set user
USER node

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:3000/healthcheck || exit 1

# Start application
CMD ["node", "src/server.js"]

# Build-time metadata
LABEL maintainer="İskele360 Team" \
      version="8.0.0" \
      description="İskele360 Backend API"
