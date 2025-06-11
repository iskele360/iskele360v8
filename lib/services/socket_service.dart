import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:iskele360v7/models/models.dart';
import 'package:iskele360v7/utils/constants.dart';
import 'package:logger/logger.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  
  factory SocketService() {
    return _instance;
  }
  
  // Socket istemcisi
  io.Socket? _socket;
  
  // Logger
  final Logger _logger = Logger();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  
  // Event stream controllers
  final StreamController<Puantaj> _puantajCreatedController = StreamController<Puantaj>.broadcast();
  final StreamController<Puantaj> _puantajUpdatedController = StreamController<Puantaj>.broadcast();
  final StreamController<Zimmet> _zimmetCreatedController = StreamController<Zimmet>.broadcast();
  final StreamController<bool> _connectionStatusController = StreamController<bool>.broadcast();
  
  // Event streams
  Stream<Puantaj> get onPuantajCreated => _puantajCreatedController.stream;
  Stream<Puantaj> get onPuantajUpdated => _puantajUpdatedController.stream;
  Stream<Zimmet> get onZimmetCreated => _zimmetCreatedController.stream;
  Stream<bool> get connectionStatus => _connectionStatusController.stream;
  
  // Bağlantı durumu
  bool _isConnected = false;
  bool get isConnected => _isConnected;
  
  SocketService._internal();
  
  // Socket bağlantısını başlat
  Future<void> initSocket() async {
    if (_socket != null) {
      _socket!.disconnect();
      _socket = null;
    }
    
    try {
      // Token'ı secure storage'dan oku
      final token = await _secureStorage.read(key: AppConstants.tokenKey);
      
      if (token == null) {
        _logger.w('Socket bağlantısı başlatılamadı: Token bulunamadı');
        return;
      }
      
      _socket = io.io(
        AppConstants.socketUrl,
        io.OptionBuilder()
            .setTransports(['websocket'])
            .disableAutoConnect()
            .setAuth({'token': token})
            .setReconnectionAttempts(5)
            .setReconnectionDelay(5000)
            .enableReconnection()
            .enableForceNew()
            .build(),
      );
      
      _setupSocketListeners();
      _socket!.connect();
      
      _logger.i('Socket bağlantı başlatıldı');
    } catch (e) {
      _logger.e('Socket bağlantısı başlatılırken hata: $e');
    }
  }
  
  // Socket dinleyicilerini ayarla
  void _setupSocketListeners() {
    _socket!.onConnect((_) {
      _logger.i('Socket.IO bağlantısı kuruldu');
      _isConnected = true;
      _connectionStatusController.add(true);
    });
    
    _socket!.onDisconnect((_) {
      _logger.i('Socket.IO bağlantısı kesildi');
      _isConnected = false;
      _connectionStatusController.add(false);
    });
    
    _socket!.onConnectError((error) {
      _logger.e('Socket.IO bağlantı hatası: $error');
      _isConnected = false;
      _connectionStatusController.add(false);
    });
    
    _socket!.onError((error) {
      _logger.e('Socket.IO hatası: $error');
    });
    
    // Puantaj oluşturulduğunda
    _socket!.on(AppConstants.socketEventPuantajCreated, (data) {
      try {
        final puantajData = data is String ? jsonDecode(data) : data;
        final puantaj = Puantaj.fromJson(puantajData);
        _puantajCreatedController.add(puantaj);
        _logger.i('Yeni puantaj alındı: ${puantaj.id}');
      } catch (e) {
        _logger.e('Puantaj verisi işlenirken hata: $e');
      }
    });
    
    // Puantaj güncellendiğinde
    _socket!.on(AppConstants.socketEventPuantajUpdated, (data) {
      try {
        final puantajData = data is String ? jsonDecode(data) : data;
        final puantaj = Puantaj.fromJson(puantajData);
        _puantajUpdatedController.add(puantaj);
        _logger.i('Puantaj güncellendi: ${puantaj.id}');
      } catch (e) {
        _logger.e('Puantaj güncelleme verisi işlenirken hata: $e');
      }
    });
    
    // Zimmet oluşturulduğunda
    _socket!.on(AppConstants.socketEventZimmetCreated, (data) {
      try {
        final zimmetData = data is String ? jsonDecode(data) : data;
        final zimmet = Zimmet.fromJson(zimmetData);
        _zimmetCreatedController.add(zimmet);
        _logger.i('Yeni zimmet alındı: ${zimmet.id}');
      } catch (e) {
        _logger.e('Zimmet verisi işlenirken hata: $e');
      }
    });
  }
  
  // Odaya katılma (özel bildirimler için)
  void joinRoom(String roomName) {
    if (_socket != null && _isConnected) {
      _socket!.emit('join_room', roomName);
      _logger.i('Odaya katılındı: $roomName');
    } else {
      _logger.w('Odaya katılınamadı: Socket bağlı değil');
    }
  }
  
  // Odadan ayrılma
  void leaveRoom(String roomName) {
    if (_socket != null && _isConnected) {
      _socket!.emit('leave_room', roomName);
      _logger.i('Odadan ayrılındı: $roomName');
    }
  }
  
  // Puantaj oluşturma olayı gönderme
  void emitPuantajCreated(Puantaj puantaj) {
    if (_socket != null && _isConnected) {
      _socket!.emit(AppConstants.socketEventPuantajCreated, puantaj.toJson());
      _logger.i('Puantaj oluşturma olayı gönderildi: ${puantaj.id}');
    }
  }
  
  // Puantaj güncelleme olayı gönderme
  void emitPuantajUpdated(Puantaj puantaj) {
    if (_socket != null && _isConnected) {
      _socket!.emit(AppConstants.socketEventPuantajUpdated, puantaj.toJson());
      _logger.i('Puantaj güncelleme olayı gönderildi: ${puantaj.id}');
    }
  }
  
  // Zimmet oluşturma olayı gönderme
  void emitZimmetCreated(Zimmet zimmet) {
    if (_socket != null && _isConnected) {
      _socket!.emit(AppConstants.socketEventZimmetCreated, zimmet.toJson());
      _logger.i('Zimmet oluşturma olayı gönderildi: ${zimmet.id}');
    }
  }
  
  // Bağlantıyı kapat
  void disconnect() {
    if (_socket != null) {
      _socket!.disconnect();
      _socket = null;
      _isConnected = false;
      _connectionStatusController.add(false);
      _logger.i('Socket bağlantısı kapatıldı');
    }
  }
  
  // Servisi temizle
  void dispose() {
    disconnect();
    _puantajCreatedController.close();
    _puantajUpdatedController.close();
    _zimmetCreatedController.close();
    _connectionStatusController.close();
  }
} 