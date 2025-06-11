import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:iskele360v7/models/models.dart';
import 'package:iskele360v7/services/services.dart';
import 'package:flutter/foundation.dart';
import 'package:iskele360v7/models/user_model.dart';
import 'package:iskele360v7/services/api_service.dart';
import 'package:iskele360v7/services/socket_service.dart';
import 'package:iskele360v7/utils/constants.dart';

enum AuthStatus {
  uninitialized, // Başlangıç durumu
  authenticated, // Oturum açık
  unauthenticated, // Oturum kapalı
}

class AuthProvider with ChangeNotifier {
  final ApiService _apiService;
  final SocketService _socketService = SocketService();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  
  AuthStatus _status = AuthStatus.uninitialized;
  User? _user;
  String? _errorMessage;
  bool _isLoading = false;
  
  // Getters
  AuthStatus get status => _status;
  User? get user => _user;
  User? get currentUser => _user;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isLoading => _isLoading;
  String? get token => _user?.token;
  String? get userRole => _user?.role;
  
  AuthProvider(this._apiService);
  
  // Başlangıçta token ve kullanıcı durumunu kontrol et
  Future<void> checkAuthStatus() async {
    try {
      final savedToken = await _secureStorage.read(key: AppConstants.tokenKey);
      final hasToken = savedToken != null && savedToken.isNotEmpty;
      
      if (hasToken) {
        if (AppConstants.useMockApi) {
          // Mock API için, token varsa demo kullanıcı oluştur
          _user = User(
            id: '1',
            name: 'Demo',
            surname: 'Kullanıcı',
            email: 'demo@example.com',
            role: AppConstants.roleSupervisor,
            token: savedToken,
            createdAt: DateTime.now(),
          );
          
          _status = AuthStatus.authenticated;
          notifyListeners();
          return;
        }
        
        // Token var, profil bilgilerini al
        final user = await _apiService.getUserProfile();
        _user = user;
        _status = AuthStatus.authenticated;
        
        // WebSocket bağlantısını başlat
        await _socketService.initSocket();
        
        // Kullanıcı verilerini güvenli depolamaya kaydet
        await _saveUserData(user);
      } else {
        _status = AuthStatus.unauthenticated;
      }
    } catch (e) {
      if (AppConstants.useMockApi) {
        // Hata durumunda mock için sadece oturumu kapat
        _status = AuthStatus.unauthenticated;
      } else {
        _status = AuthStatus.unauthenticated;
        _errorMessage = e.toString();
      }
    }
    
    notifyListeners();
  }
  
  // Email ile giriş (Puantajcı)
  Future<bool> loginWithEmail(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      if (AppConstants.useMockApi) {
        // API olmadığında demo kullanıcı ile giriş yap
        await Future.delayed(const Duration(seconds: 1)); // Gerçek giriş hissi için kısa gecikme
        
        // Demo kullanıcı oluştur
        _user = User(
          id: '1',
          name: 'Demo',
          surname: 'Puantajcı',
          email: email,
          role: AppConstants.roleSupervisor,
          token: 'demo_token_${DateTime.now().millisecondsSinceEpoch}',
          createdAt: DateTime.now(),
        );
        
        // Token'ı güvenli depolamaya kaydet
        await _secureStorage.write(key: AppConstants.tokenKey, value: _user?.token);
        
        _status = AuthStatus.authenticated;
        _isLoading = false;
        notifyListeners();
        return true;
      }
      
      try {
        // ApiService sınıfındaki yöntem kullanarak giriş yapmayı dene
        final user = await _apiService.loginWithEmail(
          email: email,
          password: password,
        );
        
        _user = user;
        _status = AuthStatus.authenticated;
        _isLoading = false;
        notifyListeners();
        return true;
      } catch (e) {
        // Eğer doğrudan ApiService metodu çalışmazsa, manuel olarak API isteği yapalım
        final response = await _apiService.post(
          '/auth/login',
          data: {'email': email, 'password': password},
        );
        
        if (response.statusCode == 200) {
          final data = response.data;
          if (data['data'] != null) {
            _user = User.fromJson(data['data']);
            _user?.token = data['token'];
            
            // Token'ı güvenli depolamaya kaydet
            await _secureStorage.write(key: AppConstants.tokenKey, value: _user?.token);
            
            _status = AuthStatus.authenticated;
            _isLoading = false;
            notifyListeners();
            return true;
          } else {
            _errorMessage = 'Kullanıcı bilgileri alınamadı';
            _isLoading = false;
            notifyListeners();
            return false;
          }
        } else {
          _errorMessage = 'Giriş başarısız: ${response.data['message'] ?? 'Bilinmeyen hata'}';
          _isLoading = false;
          notifyListeners();
          return false;
        }
      }
    } catch (e) {
      if (AppConstants.useMockApi) {
        // Hata durumunda bile demo kullanıcı ile giriş yap
        _user = User(
          id: '1',
          name: 'Demo',
          surname: 'Puantajcı',
          email: email,
          role: AppConstants.roleSupervisor,
          token: 'demo_token_${DateTime.now().millisecondsSinceEpoch}',
          createdAt: DateTime.now(),
        );
        
        // Token'ı güvenli depolamaya kaydet
        await _secureStorage.write(key: AppConstants.tokenKey, value: _user?.token);
        
        _status = AuthStatus.authenticated;
        _isLoading = false;
        notifyListeners();
        return true;
      }
      
      _errorMessage = 'Giriş sırasında hata oluştu: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  // Kod ile giriş (İşçi/Malzemeci)
  Future<bool> loginWithCode(String code, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      if (AppConstants.useMockApi) {
        // API olmadığında demo kullanıcı ile giriş yap
        await Future.delayed(const Duration(seconds: 1)); // Gerçek giriş hissi için kısa gecikme
        
        // Demo kullanıcı oluştur - rol koda göre belirlenir
        String role = code.startsWith('1') ? AppConstants.roleWorker : AppConstants.roleSupplier;
        
        _user = User(
          id: '2',
          name: 'Demo',
          surname: role == AppConstants.roleWorker ? 'İşçi' : 'Malzemeci',
          code: code,
          role: role,
          token: 'demo_token_${DateTime.now().millisecondsSinceEpoch}',
          createdAt: DateTime.now(),
        );
        
        // Token'ı güvenli depolamaya kaydet
        await _secureStorage.write(key: AppConstants.tokenKey, value: _user?.token);
        
        _status = AuthStatus.authenticated;
        _isLoading = false;
        notifyListeners();
        return true;
      }
      
      // Normal API isteği
      final response = await _apiService.post(
        '/auth/login-with-code',
        data: {'code': code, 'password': password},
      );
      
      if (response.statusCode == 200) {
        final data = response.data;
        _user = User.fromJson(data['user']);
        _user?.token = data['token'];
        
        // Token'ı güvenli depolamaya kaydet
        await _secureStorage.write(key: AppConstants.tokenKey, value: _user?.token);
        
        // Kullanıcı bilgilerini al
        await getUserProfile();
        
        _status = AuthStatus.authenticated;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Giriş başarısız: ${response.data['message'] ?? 'Bilinmeyen hata'}';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      if (AppConstants.useMockApi) {
        // Hata durumunda bile demo kullanıcı ile giriş yap
        String role = code.startsWith('1') ? AppConstants.roleWorker : AppConstants.roleSupplier;
        
        _user = User(
          id: '2',
          name: 'Demo',
          surname: role == AppConstants.roleWorker ? 'İşçi' : 'Malzemeci',
          code: code,
          role: role,
          token: 'demo_token_${DateTime.now().millisecondsSinceEpoch}',
          createdAt: DateTime.now(),
        );
        
        // Token'ı güvenli depolamaya kaydet
        await _secureStorage.write(key: AppConstants.tokenKey, value: _user?.token);
        
        _status = AuthStatus.authenticated;
        _isLoading = false;
        notifyListeners();
        return true;
      }
      
      _errorMessage = 'Giriş sırasında hata oluştu: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  // Yeni işçi oluştur (Puantajcı)
  Future<bool> createWorker(String firstName, String lastName) async {
    if (_user?.role != 'supervisor') {
      _errorMessage = 'Bu işlemi yapmaya yetkiniz yok';
      notifyListeners();
      return false;
    }
    
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      final response = await _apiService.post(
        '/users/create-worker',
        data: {'firstName': firstName, 'lastName': lastName},
      );
      
      if (response.statusCode == 201) {
        final data = response.data;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'İşçi oluşturma başarısız: ${response.data['message'] ?? 'Bilinmeyen hata'}';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'İşçi oluşturma sırasında hata oluştu: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  // Kullanıcı kaydı
  Future<bool> register({
    required String name,
    required String surname,
    required String email,
    required String password,
    required String role,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      if (AppConstants.useMockApi) {
        // API olmadığında demo kayıt işlemi yap
        await Future.delayed(const Duration(seconds: 1)); // Gerçek kayıt hissi için kısa gecikme
        
        _isLoading = false;
        notifyListeners();
        return true;
      }
      
      final response = await _apiService.post(
        '/auth/register',
        data: {
          'name': name,
          'surname': surname,
          'email': email,
          'password': password,
          'role': role,
        },
      );
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Kayıt başarısız: ${response.data['message'] ?? 'Bilinmeyen hata'}';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      if (AppConstants.useMockApi) {
        // Hata durumunda bile başarılı kayıt göster
        _isLoading = false;
        notifyListeners();
        return true;
      }
      
      _errorMessage = 'Kayıt sırasında hata oluştu: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  // Yeni malzemeci oluştur (Puantajcı)
  Future<bool> createSupplier(String firstName, String lastName) async {
    if (_user?.role != 'supervisor') {
      _errorMessage = 'Bu işlemi yapmaya yetkiniz yok';
      notifyListeners();
      return false;
    }
    
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      final response = await _apiService.post(
        '/users/create-supplier',
        data: {'firstName': firstName, 'lastName': lastName},
      );
      
      if (response.statusCode == 201) {
        final data = response.data;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Malzemeci oluşturma başarısız: ${response.data['message'] ?? 'Bilinmeyen hata'}';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Malzemeci oluşturma sırasında hata oluştu: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Oturum açmış kullanıcının profilini al
  Future<bool> getUserProfile() async {
    if (_user?.token == null) return false;
    
    try {
      final response = await _apiService.get('/users/profile');
      
      if (response.statusCode == 200) {
        final userData = response.data['user'];
        _user = User.fromJson(userData);
        notifyListeners();
        return true;
      } else {
        return false;
      }
    } catch (e) {
      print('Kullanıcı profili alınamadı: $e');
      return false;
    }
  }

  // Güvenli depolamadan token'ı kontrol ederek otomatik giriş
  Future<bool> autoLogin() async {
    final savedToken = await _secureStorage.read(key: 'auth_token');
    
    if (savedToken == null) {
      return false;
    }
    
    _user?.token = savedToken;
    _apiService.setToken(savedToken);
    
    final success = await getUserProfile();
    return success;
  }
  
  // Çıkış yap
  Future<void> logout() async {
    try {
      if (AppConstants.useMockApi) {
        // Mock API için sadece token ve kullanıcı bilgilerini temizle
        await _secureStorage.delete(key: AppConstants.tokenKey);
        await _secureStorage.delete(key: 'user_data');
        
        _user = null;
        _status = AuthStatus.unauthenticated;
        _errorMessage = null;
        
        notifyListeners();
        return;
      }
      
      await _apiService.logout();
      
      // WebSocket bağlantısını kapat
      _socketService.disconnect();
      
      // Kullanıcı verilerini temizle
      await _secureStorage.delete(key: AppConstants.tokenKey);
      await _secureStorage.delete(key: 'user_data');
      
      _user = null;
      _status = AuthStatus.unauthenticated;
      _errorMessage = null;
      
      notifyListeners();
    } catch (e) {
      if (AppConstants.useMockApi) {
        // Mock API için hata durumunda da token ve kullanıcı bilgilerini temizle
        await _secureStorage.delete(key: AppConstants.tokenKey);
        await _secureStorage.delete(key: 'user_data');
        
        _user = null;
        _status = AuthStatus.unauthenticated;
        _errorMessage = null;
        
        notifyListeners();
        return;
      }
      
      _errorMessage = e.toString();
      notifyListeners();
    }
  }
  
  // Profil bilgilerini güncelle
  Future<bool> updateProfile({
    String? name,
    String? surname,
    String? email,
  }) async {
    try {
      final updatedUser = await _apiService.updateProfile(
        name: name,
        surname: surname,
        email: email,
      );
      
      _user = updatedUser;
      
      // Kullanıcı verilerini güvenli depolamaya kaydet
      await _saveUserData(updatedUser);
      
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
  
  // Şifre güncelleme
  Future<bool> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await _apiService.updatePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
  
  // Hesabı sil
  Future<bool> deleteAccount() async {
    try {
      await _apiService.deleteAccount();
      
      // WebSocket bağlantısını kapat
      _socketService.disconnect();
      
      // Kullanıcı verilerini temizle
      await _secureStorage.delete(key: 'user_data');
      
      _user = null;
      _status = AuthStatus.unauthenticated;
      _errorMessage = null;
      
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
  
  // Kullanıcı verilerini güvenli depolamaya kaydet
  Future<void> _saveUserData(User user) async {
    final userData = jsonEncode(user.toJson());
    await _secureStorage.write(key: 'user_data', value: userData);
  }
} 