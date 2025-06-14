# Base image
FROM node:20-slim

# Set working directory
WORKDIR /usr/src/app

# Install dependencies
COPY package*.json ./
RUN npm install

# Copy source code
COPY . .

# Set environment variables
ENV NODE_ENV=production
ENV PORT=3000

# Expose port
EXPOSE 3000

# Start application
CMD ["npm", "start"] 