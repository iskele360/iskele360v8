import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:iskele360v7/models/user_model.dart';
import 'package:iskele360v7/services/socket_service.dart';
import 'package:iskele360v7/services/cache_service.dart';

class AuthProvider with ChangeNotifier {
  final SocketService _socketService = SocketService();
  final CacheService _cacheService = CacheService();
  final _storage = const FlutterSecureStorage();

  User? _currentUser;
  bool _isLoading = false;
  String? _error;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get errorMessage => _error;
  String? get userRole => _currentUser?.role;

  // Otomatik giriş
  Future<bool> autoLogin() async {
    return await checkAuth();
  }

  // Kullanıcı kaydı
  Future<bool> register(
      String email, String password, String name, String surname) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _socketService.emit('register', {
        'email': email,
        'password': password,
        'name': name,
        'surname': surname,
      });

      final response = await _waitForSocketResponse('registerResponse');

      if (response['success'] == true) {
        final user = User.fromJson(response['user']);
        await _storage.write(key: 'auth_token', value: user.token);
        await _cacheService.put('users', 'current_user', user.toJson());
        _currentUser = user;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = response['message'] ?? 'Kayıt başarısız';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Kayıt yapılamadı: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Profil güncelleme
  Future<bool> updateProfile(String name, String surname, String email) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _socketService.emit('updateProfile', {
        'name': name,
        'surname': surname,
        'email': email,
      });

      final response = await _waitForSocketResponse('updateProfileResponse');

      if (response['success'] == true) {
        final user = User.fromJson(response['user']);
        await _cacheService.put('users', 'current_user', user.toJson());
        _currentUser = user;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = response['message'] ?? 'Profil güncellenemedi';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Profil güncellenemedi: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Şifre güncelleme
  Future<bool> updatePassword(
      String currentPassword, String newPassword) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _socketService.emit('updatePassword', {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      });

      final response = await _waitForSocketResponse('updatePasswordResponse');

      if (response['success'] == true) {
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = response['message'] ?? 'Şifre güncellenemedi';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Şifre güncellenemedi: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Hesap silme
  Future<bool> deleteAccount() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _socketService.emit('deleteAccount', {});

      final response = await _waitForSocketResponse('deleteAccountResponse');

      if (response['success'] == true) {
        await _storage.delete(key: 'auth_token');
        await _cacheService.delete('users', 'current_user');
        _currentUser = null;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = response['message'] ?? 'Hesap silinemedi';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Hesap silinemedi: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Email ile giriş
  Future<bool> loginWithEmail(String email, String password) async {
    return login(email, password);
  }

  // Kullanıcı girişi
  Future<bool> login(String email, String password) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _socketService.emit('login', {
        'email': email,
        'password': password,
      });

      final response = await _waitForSocketResponse('loginResponse');

      if (response['success'] == true) {
        final user = User.fromJson(response['user']);
        await _storage.write(key: 'auth_token', value: user.token);
        await _cacheService.put('users', 'current_user', user.toJson());
        _currentUser = user;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = response['message'] ?? 'Giriş başarısız';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Giriş yapılamadı: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Kod ile giriş
  Future<bool> loginWithCode(String code, String password) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _socketService
          .emit('loginWithCode', {'code': code, 'password': password});

      final response = await _waitForSocketResponse('loginWithCodeResponse');

      if (response['success'] == true) {
        final user = User.fromJson(response['user']);
        await _storage.write(key: 'auth_token', value: user.token);
        await _cacheService.put('users', 'current_user', user.toJson());
        _currentUser = user;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = response['message'] ?? 'Kod ile giriş başarısız';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Kod ile giriş yapılamadı: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Çıkış yap
  Future<void> logout() async {
    try {
      _isLoading = true;
      notifyListeners();

      _socketService.emit('logout', {});

      await _storage.delete(key: 'auth_token');
      await _cacheService.delete('users', 'current_user');

      _currentUser = null;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Çıkış yapılamadı: $e';
      _isLoading = false;
      notifyListeners();
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
          _currentUser = User.fromJson(userData);
          notifyListeners();
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
      final completer = Completer<Map<String, dynamic>>();

      final timer = Timer(const Duration(seconds: 10), () {
        if (!completer.isCompleted) {
          completer.completeError('İstek zaman aşımına uğradı');
        }
      });

      void listener(dynamic data) {
        if (!completer.isCompleted) {
          timer.cancel();
          _socketService.off(event);
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
