import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter/foundation.dart';
import 'package:iskele360v7/utils/constants.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  late IO.Socket socket;
  bool isConnected = false;

  factory SocketService() {
    return _instance;
  }

  SocketService._internal();

  void init() {
    socket = IO.io(AppConstants.socketUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
      'reconnection': true,
      'reconnectionDelay': 1000,
      'reconnectionDelayMax': 5000,
      'reconnectionAttempts': 5,
      'forceNew': true,
      'timeout': 10000,
      'extraHeaders': {
        'Access-Control-Allow-Origin': '*',
      }
    });

    _setupSocketListeners();
    _setupPuantajListeners();
  }

  // Puantaj olayları için callback'ler
  Function(dynamic)? _onPuantajCreatedCallback;
  Function(dynamic)? _onPuantajUpdatedCallback;

  // Puantaj olaylarını dinle
  void onPuantajCreated(Function(dynamic) callback) {
    _onPuantajCreatedCallback = callback;
  }

  void onPuantajUpdated(Function(dynamic) callback) {
    _onPuantajUpdatedCallback = callback;
  }

  void _setupPuantajListeners() {
    socket.on(AppConstants.socketEventPuantajCreated, (data) {
      if (kDebugMode) {
        print('Yeni puantaj oluşturuldu: $data');
      }
      if (_onPuantajCreatedCallback != null) {
        _onPuantajCreatedCallback!(data);
      }
    });

    socket.on(AppConstants.socketEventPuantajUpdated, (data) {
      if (kDebugMode) {
        print('Puantaj güncellendi: $data');
      }
      if (_onPuantajUpdatedCallback != null) {
        _onPuantajUpdatedCallback!(data);
      }
    });
  }

  // Puantaj olaylarını emit et
  void emitPuantajCreated(dynamic data) {
    emit(AppConstants.socketEventPuantajCreated, data);
  }

  void emitPuantajUpdated(dynamic data) {
    emit(AppConstants.socketEventPuantajUpdated, data);
  }

  void _setupSocketListeners() {
    socket.onConnect((_) {
      if (kDebugMode) {
        print('Socket bağlantısı kuruldu');
      }
      isConnected = true;
    });

    socket.onDisconnect((_) {
      if (kDebugMode) {
        print('Socket bağlantısı kesildi');
      }
      isConnected = false;
      // Yeniden bağlanmayı dene
      Future.delayed(const Duration(seconds: 5), () {
        if (!isConnected) {
          reconnect();
        }
      });
    });

    socket.onError((error) {
      if (kDebugMode) {
        print('Socket hatası: $error');
      }
    });

    socket.onConnectError((error) {
      if (kDebugMode) {
        print('Socket bağlantı hatası: $error');
      }
      // Bağlantı hatası durumunda yeniden bağlanmayı dene
      Future.delayed(const Duration(seconds: 5), () {
        if (!isConnected) {
          reconnect();
        }
      });
    });
  }

  // Veri gönderme
  void emit(String event, dynamic data) {
    if (isConnected) {
      socket.emit(event, data);
    } else {
      if (kDebugMode) {
        print('Socket bağlı değil, veri gönderilemedi: $event');
      }
      // Bağlı değilse yeniden bağlanmayı dene
      reconnect();
    }
  }

  // Veri dinleme
  void on(String event, Function(dynamic) callback) {
    socket.on(event, callback);
  }

  // Veri dinlemeyi durdurma
  void off(String event) {
    socket.off(event);
  }

  // Belirli bir odaya katılma
  void joinRoom(String room) {
    socket.emit('join', room);
  }

  // Belirli bir odadan ayrılma
  void leaveRoom(String room) {
    socket.emit('leave', room);
  }

  // Bağlantıyı kapatma
  void dispose() {
    socket.dispose();
  }

  // Yeniden bağlanma
  void reconnect() {
    if (!isConnected) {
      socket.connect();
    }
  }

  // Bağlantıyı kesme
  void disconnect() {
    socket.disconnect();
  }
}
