import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:iskele360v7/models/user_model.dart';
import 'package:iskele360v7/utils/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _apiService;
  final SharedPreferences _prefs;
  final _storage = const FlutterSecureStorage();

  User? _currentUser;
  bool _isLoading = false;
  String? _error;

  AuthProvider(this._apiService, this._prefs) {
    _loadStoredData();
  }

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _currentUser != null;
  String? get userRole => _currentUser?.role;

  bool get isAdmin => _currentUser?.role == AppConstants.roleAdmin;
  bool get isPuantajci => _currentUser?.role == AppConstants.rolePuantajci;

  Future<void> _loadStoredData() async {
    try {
      final token = await _storage.read(key: AppConstants.tokenKey);
      if (token != null) {
        await _apiService.setToken(token);
        await _loadUserData();
      }
    } catch (e) {
      _error = 'Oturum bilgileri yüklenemedi: $e';
      notifyListeners();
    }
  }

  Future<void> _loadUserData() async {
    try {
      final user = await _apiService.getUserData();
      _currentUser = user;
      notifyListeners();
    } catch (e) {
      _error = 'Kullanıcı bilgileri yüklenemedi: $e';
      notifyListeners();
    }
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    try {
      _setLoading(true);

      final user = await _apiService.login(
        email: email,
        password: password,
      );

      _currentUser = user;
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _handleError('Giriş başarısız: $e');
      return false;
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String role,
  }) async {
    try {
      _setLoading(true);

      final user = await _apiService.register(
        name: name,
        email: email,
        password: password,
        phone: phone,
        role: role,
      );

      // Kayıt başarılı, şimdi login deneyelim
      final loginSuccess = await login(
        email: email,
        password: password,
      );

      if (!loginSuccess) {
        _handleError('Kayıt başarılı fakat otomatik giriş yapılamadı. Lütfen giriş yapın.');
        return true; // Kayıt başarılı olduğu için true döndür
      }

      _currentUser = user;
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _handleError('Kayıt işlemi sırasında bir hata oluştu. Lütfen tüm bilgileri doğru girdiğinizden emin olun ve tekrar deneyin.');
      return false;
    }
  }

  Future<bool> loginWithSupplierCode({
    required String code,
  }) async {
    try {
      _setLoading(true);

      final user = await _apiService.loginWithSupplierCode(
        code: code,
      );

      _currentUser = user;
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _handleError('Tedarikçi girişi başarısız: $e');
      return false;
    }
  }

  Future<bool> loginWithWorkerCode({
    required String code,
  }) async {
    try {
      _setLoading(true);

      final user = await _apiService.loginWithWorkerCode(
        code: code,
      );

      _currentUser = user;
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _handleError('İşçi girişi başarısız: $e');
      return false;
    }
  }

  Future<void> logout() async {
    try {
      _setLoading(true);
      await _apiService.logout();
      await _storage.delete(key: AppConstants.tokenKey);
      _currentUser = null;
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _handleError('Çıkış yapılamadı: $e');
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    _error = null;
    notifyListeners();
  }

  void _handleError(String message) {
    _error = message;
    _isLoading = false;
    notifyListeners();
  }
}
