const cloudinary = require('cloudinary').v2;
const dotenv = require('dotenv');

dotenv.config();

class CloudinaryService {
  constructor() {
    cloudinary.config({
      cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
      api_key: process.env.CLOUDINARY_API_KEY,
      api_secret: process.env.CLOUDINARY_API_SECRET
    });
  }

  async uploadImage(file, folder = 'iskele360') {
    try {
      const result = await cloudinary.uploader.upload(file, {
        folder: folder,
        resource_type: 'auto',
        allowed_formats: ['jpg', 'jpeg', 'png', 'gif'],
        transformation: [
          { width: 1000, crop: 'limit' },
          { quality: 'auto' },
          { fetch_format: 'auto' }
        ]
      });

      return {
        url: result.secure_url,
        publicId: result.public_id,
        width: result.width,
        height: result.height,
        format: result.format,
        resourceType: result.resource_type
      };
    } catch (error) {
      console.error('Cloudinary upload hatası:', error);
      throw new Error('Dosya yükleme hatası');
    }
  }

  async uploadMultipleImages(files, folder = 'iskele360') {
    try {
      const uploadPromises = files.map(file => this.uploadImage(file, folder));
      return await Promise.all(uploadPromises);
    } catch (error) {
      console.error('Cloudinary çoklu yükleme hatası:', error);
      throw new Error('Dosyalar yüklenirken hata oluştu');
    }
  }

  async deleteImage(publicId) {
    try {
      const result = await cloudinary.uploader.destroy(publicId);
      return result.result === 'ok';
    } catch (error) {
      console.error('Cloudinary silme hatası:', error);
      throw new Error('Dosya silinirken hata oluştu');
    }
  }

  async deleteMultipleImages(publicIds) {
    try {
      const result = await cloudinary.api.delete_resources(publicIds);
      return result.deleted;
    } catch (error) {
      console.error('Cloudinary çoklu silme hatası:', error);
      throw new Error('Dosyalar silinirken hata oluştu');
    }
  }

  getImageUrl(publicId, options = {}) {
    try {
      const transformation = {
        width: options.width,
        height: options.height,
        crop: options.crop || 'fill',
        quality: options.quality || 'auto',
        fetch_format: options.format || 'auto'
      };

      return cloudinary.url(publicId, transformation);
    } catch (error) {
      console.error('Cloudinary URL oluşturma hatası:', error);
      throw new Error('URL oluşturulurken hata oluştu');
    }
  }

  async optimizeImage(publicId, options = {}) {
    try {
      const result = await cloudinary.uploader.explicit(publicId, {
        type: 'upload',
        transformation: [
          { width: options.width || 'auto' },
          { quality: options.quality || 'auto' },
          { fetch_format: options.format || 'auto' },
          { crop: options.crop || 'limit' }
        ]
      });

      return {
        url: result.secure_url,
        publicId: result.public_id,
        width: result.width,
        height: result.height,
        format: result.format,
        resourceType: result.resource_type
      };
    } catch (error) {
      console.error('Cloudinary optimizasyon hatası:', error);
      throw new Error('Görsel optimize edilirken hata oluştu');
    }
  }

  async createImageThumbnail(publicId, width = 150, height = 150) {
    try {
      const result = await cloudinary.uploader.explicit(publicId, {
        type: 'upload',
        transformation: [
          { width: width, height: height, crop: 'fill' },
          { quality: 'auto' },
          { fetch_format: 'auto' }
        ]
      });

      return {
        url: result.secure_url,
        publicId: result.public_id,
        width: result.width,
        height: result.height
      };
    } catch (error) {
      console.error('Cloudinary thumbnail oluşturma hatası:', error);
      throw new Error('Thumbnail oluşturulurken hata oluştu');
    }
  }

  // Folder management
  async createFolder(folderName) {
    try {
      await cloudinary.api.create_folder(folderName);
      return true;
    } catch (error) {
      console.error('Cloudinary klasör oluşturma hatası:', error);
      throw new Error('Klasör oluşturulurken hata oluştu');
    }
  }

  async deleteFolder(folderName) {
    try {
      await cloudinary.api.delete_folder(folderName);
      return true;
    } catch (error) {
      console.error('Cloudinary klasör silme hatası:', error);
      throw new Error('Klasör silinirken hata oluştu');
    }
  }

  // Resource management
  async getFolderResources(folderName) {
    try {
      const result = await cloudinary.api.resources({
        type: 'upload',
        prefix: folderName,
        max_results: 500
      });
      return result.resources;
    } catch (error) {
      console.error('Cloudinary klasör içeriği alma hatası:', error);
      throw new Error('Klasör içeriği alınırken hata oluştu');
    }
  }

  async searchResources(query) {
    try {
      const result = await cloudinary.search
        .expression(query)
        .max_results(30)
        .execute();
      return result.resources;
    } catch (error) {
      console.error('Cloudinary arama hatası:', error);
      throw new Error('Arama yapılırken hata oluştu');
    }
  }
}

// Singleton instance
const cloudinaryService = new CloudinaryService();

module.exports = cloudinaryService;
