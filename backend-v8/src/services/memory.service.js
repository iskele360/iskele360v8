class MemoryService {
  constructor() {
    this.store = new Map();
    this.users = new Map();
    this.puantaj = new Map();
    this.tokens = new Map();
    console.log('In-memory veri servisi başlatıldı');
  }

  // User operations
  async createUser(userData) {
    const userId = Date.now().toString();
    this.users.set(userId, { ...userData, id: userId });
    return { ...userData, id: userId };
  }

  async getUser(userId) {
    return this.users.get(userId) || null;
  }

  async getUserByEmail(email) {
    return Array.from(this.users.values()).find(user => user.email === email) || null;
  }

  async updateUser(userId, userData) {
    if (!this.users.has(userId)) return null;
    const updatedUser = { ...this.users.get(userId), ...userData };
    this.users.set(userId, updatedUser);
    return updatedUser;
  }

  async deleteUser(userId) {
    return this.users.delete(userId);
  }

  // Puantaj operations
  async createPuantaj(puantajData) {
    const puantajId = Date.now().toString();
    this.puantaj.set(puantajId, { ...puantajData, id: puantajId });
    return { ...puantajData, id: puantajId };
  }

  async getPuantaj(puantajId) {
    return this.puantaj.get(puantajId) || null;
  }

  async getPuantajByUserId(userId) {
    return Array.from(this.puantaj.values()).filter(p => p.userId === userId);
  }

  async updatePuantaj(puantajId, puantajData) {
    if (!this.puantaj.has(puantajId)) return null;
    const updatedPuantaj = { ...this.puantaj.get(puantajId), ...puantajData };
    this.puantaj.set(puantajId, updatedPuantaj);
    return updatedPuantaj;
  }

  async deletePuantaj(puantajId) {
    return this.puantaj.delete(puantajId);
  }

  // Token operations
  async setToken(userId, token, expiresIn) {
    const expiry = Date.now() + (expiresIn * 1000);
    this.tokens.set(userId, { token, expiry });
    return true;
  }

  async getToken(userId) {
    const tokenData = this.tokens.get(userId);
    if (!tokenData) return null;
    if (tokenData.expiry < Date.now()) {
      this.tokens.delete(userId);
      return null;
    }
    return tokenData.token;
  }

  async invalidateToken(userId) {
    return this.tokens.delete(userId);
  }

  // Cache operations
  async get(key) {
    const item = this.store.get(key);
    if (!item) return null;
    if (item.expiry && item.expiry < Date.now()) {
      this.store.delete(key);
      return null;
    }
    return item.value;
  }

  async set(key, value, expireSeconds = 3600) {
    const expiry = Date.now() + (expireSeconds * 1000);
    this.store.set(key, { value, expiry });
    return true;
  }

  async delete(key) {
    return this.store.delete(key);
  }

  // Cleanup expired items
  cleanup() {
    const now = Date.now();
    
    // Cleanup tokens
    for (const [userId, tokenData] of this.tokens.entries()) {
      if (tokenData.expiry < now) {
        this.tokens.delete(userId);
      }
    }

    // Cleanup cache
    for (const [key, item] of this.store.entries()) {
      if (item.expiry && item.expiry < now) {
        this.store.delete(key);
      }
    }
  }
}

// Start cleanup interval
const memoryService = new MemoryService();
setInterval(() => memoryService.cleanup(), 60000); // Cleanup every minute

module.exports = memoryService;
