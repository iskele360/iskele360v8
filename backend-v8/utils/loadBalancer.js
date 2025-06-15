const os = require('os');

class LoadBalancer {
  constructor() {
    this.workers = new Map();
    this.currentIndex = 0;
  }

  // Round-robin algoritması
  getNextWorker() {
    const workers = Array.from(this.workers.values());
    if (workers.length === 0) return null;

    const worker = workers[this.currentIndex];
    this.currentIndex = (this.currentIndex + 1) % workers.length;
    return worker;
  }

  // Worker yük durumu
  getWorkerLoad(workerId) {
    const worker = this.workers.get(workerId);
    if (!worker) return null;

    return {
      cpu: os.loadavg()[0], // 1 dakikalık CPU yükü
      memory: process.memoryUsage().heapUsed / 1024 / 1024, // MB cinsinden
      connections: worker.connections || 0
    };
  }

  // En az yüklü worker'ı bul
  getLeastLoadedWorker() {
    let leastLoaded = null;
    let minLoad = Infinity;

    for (const [id, worker] of this.workers) {
      const load = this.getWorkerLoad(id);
      if (load && load.cpu < minLoad) {
        minLoad = load.cpu;
        leastLoaded = worker;
      }
    }

    return leastLoaded || this.getNextWorker();
  }

  // Worker ekle
  addWorker(workerId, worker) {
    worker.connections = 0;
    this.workers.set(workerId, worker);
  }

  // Worker çıkar
  removeWorker(workerId) {
    this.workers.delete(workerId);
  }

  // Bağlantı sayısını güncelle
  updateConnections(workerId, delta) {
    const worker = this.workers.get(workerId);
    if (worker) {
      worker.connections = (worker.connections || 0) + delta;
    }
  }
}

module.exports = new LoadBalancer(); 