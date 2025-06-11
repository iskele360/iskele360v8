const socketIO = require('socket.io');

let io;

// Socket.IO servisini başlat
const initSocketIO = (server) => {
  io = socketIO(server, {
    cors: {
      origin: '*', // Gerçek projede daha spesifik olmalı
      methods: ['GET', 'POST']
    }
  });

  // Bağlantıları dinle
  io.on('connection', (socket) => {
    console.log('Yeni kullanıcı bağlandı:', socket.id);

    // Kullanıcıya özel oda oluştur (kullanıcı kimliği ile)
    socket.on('join', (userId) => {
      if (userId) {
        socket.join(`user_${userId}`);
        console.log(`Kullanıcı ${userId} kendi odasına katıldı`);
      }
    });

    // Puantajcı kendi oluşturduğu işçilerin odasına katılabilir
    socket.on('join_supervisor', (supervisorId) => {
      if (supervisorId) {
        socket.join(`supervisor_${supervisorId}`);
        console.log(`Puantajcı ${supervisorId} odasına katıldı`);
      }
    });

    // Bağlantı koptuğunda
    socket.on('disconnect', () => {
      console.log('Kullanıcı ayrıldı:', socket.id);
    });
  });

  return io;
};

// Tüm kullanıcılara mesaj gönder
const emitToAll = (event, data) => {
  if (io) {
    io.emit(event, data);
  }
};

// Belirli bir kullanıcıya mesaj gönder
const emitToUser = (userId, event, data) => {
  if (io && userId) {
    io.to(`user_${userId}`).emit(event, data);
  }
};

// Belirli bir puantajcının tüm işçilerine mesaj gönder
const emitToSupervisorWorkers = (supervisorId, event, data) => {
  if (io && supervisorId) {
    io.to(`supervisor_${supervisorId}`).emit(event, data);
  }
};

module.exports = {
  initSocketIO,
  emitToAll,
  emitToUser,
  emitToSupervisorWorkers,
  getIO: () => io
}; 