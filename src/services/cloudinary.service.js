const cloudinary = require('cloudinary').v2;
const logger = require('../utils/logger');

// Cloudinary configuration
cloudinary.config({
  cloud_name: process.env.CLOUDINARY_CLOUD_NAME || 'iskele360',
  api_key: process.env.CLOUDINARY_API_KEY,
  api_secret: process.env.CLOUDINARY_API_SECRET
});

class CloudinaryService {
  async uploadImage(file, folder = 'workers') {
    try {
      const result = await cloudinary.uploader.upload(file, {
        folder: folder,
        resource_type: 'auto',
        allowed_formats: ['jpg', 'jpeg', 'png', 'gif'],
        transformation: [
          { width: 800, height: 800, crop: 'limit' },
          { quality: 'auto' }
        ]
      });

      return {
        url: result.secure_url,
        publicId: result.public_id
      };
    } catch (error) {
      logger.error('Cloudinary upload error:', error);
      throw new Error('Resim yükleme hatası');
    }
  }

  async deleteImage(publicId) {
    try {
      const result = await cloudinary.uploader.destroy(publicId);
      return result.result === 'ok';
    } catch (error) {
      logger.error('Cloudinary delete error:', error);
      return false;
    }
  }

  getImageUrl(publicId, options = {}) {
    try {
      return cloudinary.url(publicId, {
        secure: true,
        transformation: [
          { width: options.width || 800 },
          { height: options.height || 800 },
          { crop: options.crop || 'limit' },
          { quality: 'auto' }
        ]
      });
    } catch (error) {
      logger.error('Cloudinary URL generation error:', error);
      return null;
    }
  }

  async optimizeImage(publicId, options = {}) {
    try {
      const result = await cloudinary.uploader.explicit(publicId, {
        type: 'upload',
        transformation: [
          { width: options.width || 800 },
          { height: options.height || 800 },
          { crop: options.crop || 'limit' },
          { quality: 'auto' },
          { fetch_format: 'auto' }
        ]
      });

      return {
        url: result.secure_url,
        publicId: result.public_id
      };
    } catch (error) {
      logger.error('Cloudinary optimization error:', error);
      throw new Error('Resim optimizasyon hatası');
    }
  }
}

module.exports = new CloudinaryService(); 