import { v2 as cloudinary } from 'cloudinary';
import dotenv from 'dotenv';

dotenv.config();

class CloudinaryService {
  constructor() {
    this.init();
  }

  init() {
    cloudinary.config({
      cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
      api_key: process.env.CLOUDINARY_API_KEY,
      api_secret: process.env.CLOUDINARY_API_SECRET
    });
  }

  // Upload a file to Cloudinary
  async uploadFile(file, folder = 'iskele360') {
    try {
      const result = await cloudinary.uploader.upload(file.path, {
        folder,
        resource_type: 'auto',
        allowed_formats: ['jpg', 'jpeg', 'png', 'gif', 'pdf', 'doc', 'docx'],
        transformation: {
          quality: 'auto:good',
          fetch_format: 'auto'
        }
      });

      return {
        url: result.secure_url,
        publicId: result.public_id,
        format: result.format,
        type: result.resource_type,
        size: result.bytes,
        width: result.width,
        height: result.height
      };
    } catch (error) {
      console.error('❌ Cloudinary yükleme hatası:', error.message);
      throw new Error('Dosya yükleme başarısız');
    }
  }

  // Upload a profile image with specific transformations
  async uploadProfileImage(file, userId) {
    try {
      const result = await cloudinary.uploader.upload(file.path, {
        folder: 'iskele360/profiles',
        public_id: `user_${userId}`,
        overwrite: true,
        resource_type: 'image',
        allowed_formats: ['jpg', 'jpeg', 'png'],
        transformation: [
          { width: 400, height: 400, crop: 'fill', gravity: 'face' },
          { quality: 'auto:good', fetch_format: 'auto' }
        ]
      });

      return {
        url: result.secure_url,
        publicId: result.public_id,
        format: result.format
      };
    } catch (error) {
      console.error('❌ Cloudinary profil resmi yükleme hatası:', error.message);
      throw new Error('Profil resmi yükleme başarısız');
    }
  }

  // Upload multiple files
  async uploadMultipleFiles(files, folder = 'iskele360') {
    try {
      const uploadPromises = files.map(file => this.uploadFile(file, folder));
      const results = await Promise.all(uploadPromises);
      
      return results.map(result => ({
        url: result.url,
        publicId: result.publicId,
        format: result.format,
        type: result.type
      }));
    } catch (error) {
      console.error('❌ Cloudinary çoklu yükleme hatası:', error.message);
      throw new Error('Çoklu dosya yükleme başarısız');
    }
  }

  // Delete a file from Cloudinary
  async deleteFile(publicId) {
    try {
      const result = await cloudinary.uploader.destroy(publicId);
      return result.result === 'ok';
    } catch (error) {
      console.error('❌ Cloudinary dosya silme hatası:', error.message);
      throw new Error('Dosya silme başarısız');
    }
  }

  // Delete multiple files
  async deleteMultipleFiles(publicIds) {
    try {
      const result = await cloudinary.api.delete_resources(publicIds);
      return result.deleted;
    } catch (error) {
      console.error('❌ Cloudinary çoklu dosya silme hatası:', error.message);
      throw new Error('Çoklu dosya silme başarısız');
    }
  }

  // Generate a signed URL for secure file access
  async generateSignedUrl(publicId, options = {}) {
    try {
      const defaultOptions = {
        expireAt: Math.floor(Date.now() / 1000) + 3600, // 1 hour from now
        ...options
      };

      const signedUrl = cloudinary.url(publicId, {
        secure: true,
        sign_url: true,
        ...defaultOptions
      });

      return signedUrl;
    } catch (error) {
      console.error('❌ Cloudinary imzalı URL oluşturma hatası:', error.message);
      throw new Error('İmzalı URL oluşturma başarısız');
    }
  }

  // Create a zip archive of multiple files
  async createArchive(publicIds, options = {}) {
    try {
      const defaultOptions = {
        resource_type: 'image',
        target_format: 'zip',
        ...options
      };

      const result = await cloudinary.utils.download_zip_url({
        public_ids: publicIds,
        ...defaultOptions
      });

      return result;
    } catch (error) {
      console.error('❌ Cloudinary arşiv oluşturma hatası:', error.message);
      throw new Error('Arşiv oluşturma başarısız');
    }
  }

  // Get resource details
  async getResourceInfo(publicId) {
    try {
      const result = await cloudinary.api.resource(publicId);
      return {
        url: result.secure_url,
        publicId: result.public_id,
        format: result.format,
        type: result.resource_type,
        size: result.bytes,
        width: result.width,
        height: result.height,
        createdAt: result.created_at
      };
    } catch (error) {
      console.error('❌ Cloudinary dosya bilgisi alma hatası:', error.message);
      throw new Error('Dosya bilgisi alma başarısız');
    }
  }

  // Update resource access mode
  async updateAccessMode(publicId, accessMode) {
    try {
      const result = await cloudinary.api.update(publicId, {
        access_mode: accessMode // 'public' or 'authenticated'
      });
      return result;
    } catch (error) {
      console.error('❌ Cloudinary erişim modu güncelleme hatası:', error.message);
      throw new Error('Erişim modu güncelleme başarısız');
    }
  }
}

// Create and export a singleton instance
const cloudinaryService = new CloudinaryService();
export default cloudinaryService;
