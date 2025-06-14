import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:iskele360v7/services/socket_service.dart';
import 'package:iskele360v7/services/cache_service.dart';
import 'package:iskele360v7/models/user_model.dart';

class AuthService {
  final SocketService _socketService = SocketService();
  final CacheService _cacheService = CacheService();
  final _storage = const FlutterSecureStorage();

  User? _currentUser;
  User? get currentUser => _currentUser;

  // Kullanıcı girişi
  Future<User> login(String email, String password) async {
    try {
      // Socket üzerinden giriş isteği gönder
      _socketService.emit('login', {
        'email': email,
        'password': password,
      });

      // Giriş cevabını bekle
      final response = await _waitForSocketResponse('loginResponse');

      if (response['success'] == true) {
        final user = User.fromJson(response['user']);
        final token = response['token'];

        // Token'ı güvenli depolamaya kaydet
        await _storage.write(key: 'auth_token', value: token);

        // Kullanıcı bilgilerini önbelleğe kaydet
        await _cacheService.put('users', 'current_user', user.toJson());

        _currentUser = user;
        return user;
      } else {
        throw response['message'] ?? 'Giriş başarısız';
      }
    } catch (e) {
      if (kDebugMode) {
        print('Login error: $e');
      }
      throw 'Giriş yapılamadı: $e';
    }
  }

  // Kod ile giriş (işçi ve malzemeci için)
  Future<User> loginWithCode(String code) async {
    try {
      _socketService.emit('loginWithCode', {'code': code});

      final response = await _waitForSocketResponse('loginWithCodeResponse');

      if (response['success'] == true) {
        final user = User.fromJson(response['user']);
        final token = response['token'];

        await _storage.write(key: 'auth_token', value: token);
        await _cacheService.put('users', 'current_user', user.toJson());

        _currentUser = user;
        return user;
      } else {
        throw response['message'] ?? 'Kod ile giriş başarısız';
      }
    } catch (e) {
      if (kDebugMode) {
        print('Login with code error: $e');
      }
      throw 'Kod ile giriş yapılamadı: $e';
    }
  }

  // Kullanıcı kaydı
  Future<User> register(String email, String password, String name) async {
    try {
      _socketService.emit('register', {
        'email': email,
        'password': password,
        'name': name,
      });

      final response = await _waitForSocketResponse('registerResponse');

      if (response['success'] == true) {
        final user = User.fromJson(response['user']);
        final token = response['token'];

        await _storage.write(key: 'auth_token', value: token);
        await _cacheService.put('users', 'current_user', user.toJson());

        _currentUser = user;
        return user;
      } else {
        throw response['message'] ?? 'Kayıt başarısız';
      }
    } catch (e) {
      if (kDebugMode) {
        print('Register error: $e');
      }
      throw 'Kayıt yapılamadı: $e';
    }
  }

  // Çıkış yap
  Future<void> logout() async {
    try {
      _socketService.emit('logout', {});

      await _storage.delete(key: 'auth_token');
      await _cacheService.delete('users', 'current_user');

      _currentUser = null;
    } catch (e) {
      if (kDebugMode) {
        print('Logout error: $e');
      }
      throw 'Çıkış yapılamadı: $e';
    }
  }

  // Oturum kontrolü
  Future<bool> checkAuth() async {
    try {
      final token = await _storage.read(key: 'auth_token');
      if (token == null) return false;

      _socketService.emit('verifyToken', {'token': token});

      final response = await _waitForSocketResponse('verifyTokenResponse');

      if (response['success'] == true) {
        final userData = await _cacheService.get('users', 'current_user');
        if (userData != null) {
          _currentUser = User.fromJson(jsonDecode(userData));
          return true;
        }
      }

      return false;
    } catch (e) {
      if (kDebugMode) {
        print('Check auth error: $e');
      }
      return false;
    }
  }

  // Socket yanıtını bekle
  Future<Map<String, dynamic>> _waitForSocketResponse(String event) async {
    try {
      Completer<Map<String, dynamic>> completer = Completer();

      // Timeout için timer
      Timer timeoutTimer = Timer(const Duration(seconds: 10), () {
        if (!completer.isCompleted) {
          completer.completeError('İstek zaman aşımına uğradı');
        }
      });

      // Event listener ekle
      void listener(dynamic data) {
        if (!completer.isCompleted) {
          timeoutTimer.cancel();
          _socketService.off(event); // Listener'ı kaldır
          completer.complete(data as Map<String, dynamic>);
        }
      }

      _socketService.on(event, listener);

      return await completer.future;
    } catch (e) {
      throw 'Socket yanıtı alınamadı: $e';
    }
  }
}
