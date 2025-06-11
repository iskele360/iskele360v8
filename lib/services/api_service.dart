import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:iskele360v7/models/models.dart';
import 'package:iskele360v7/utils/constants.dart';
import 'package:logger/logger.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  
  factory ApiService() {
    return _instance;
  }
  
  final Dio _dio = Dio();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final Logger _logger = Logger();
  
  ApiService._internal() {
    _initDio();
  }
  
  // Dio istemcisini başlat ve interceptor'ları ayarla
  void _initDio() {
    _dio.options.baseUrl = AppConstants.apiBaseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 10);
    _dio.options.receiveTimeout = const Duration(seconds: 10);
    _dio.options.headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    
    // Request interceptor - her istekte token kontrolü yap
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _secureStorage.read(key: AppConstants.tokenKey);
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (error, handler) {
          _handleApiError(error);
          return handler.next(error);
        },
      ),
    );
    
    // Log interceptor - DEBUG modda request ve responseları logla
    if (kDebugMode) {
      _dio.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
      ));
    }
  }
  
  // GET isteği
  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) async {
    try {
      final response = await _dio.get(
        path,
        queryParameters: queryParameters,
      );
      return response;
    } catch (e) {
      if (e is DioException) {
        _handleApiError(e);
      }
      rethrow;
    }
  }
  
  // POST isteği
  Future<Response> post(String path, {dynamic data, Map<String, dynamic>? queryParameters}) async {
    try {
      final response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
      );
      return response;
    } catch (e) {
      if (e is DioException) {
        _handleApiError(e);
      }
      rethrow;
    }
  }
  
  // PUT isteği
  Future<Response> put(String path, {dynamic data, Map<String, dynamic>? queryParameters}) async {
    try {
      final response = await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
      );
      return response;
    } catch (e) {
      if (e is DioException) {
        _handleApiError(e);
      }
      rethrow;
    }
  }
  
  // DELETE isteği
  Future<Response> delete(String path, {dynamic data, Map<String, dynamic>? queryParameters}) async {
    try {
      final response = await _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
      );
      return response;
    } catch (e) {
      if (e is DioException) {
        _handleApiError(e);
      }
      rethrow;
    }
  }
  
  // Token'ı ayarla
  void setToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }
  
  // Hata yönetimi
  void _handleApiError(DioException error) {
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      _logger.e('Bağlantı zaman aşımına uğradı: ${error.message}');
    } else if (error.type == DioExceptionType.badResponse) {
      final statusCode = error.response?.statusCode;
      final responseData = error.response?.data;
      
      if (statusCode == 401) {
        _logger.e('Yetkilendirme hatası: Oturum süresi dolmuş olabilir');
        // Burada oturum süresinin dolduğuna dair işlemler yapılabilir
        // Örneğin: AuthProvider üzerinden logout() çağrılabilir
      } else {
        _logger.e('Sunucu hatası ($statusCode): $responseData');
      }
    } else if (error.type == DioExceptionType.connectionError) {
      _logger.e('Ağ bağlantısı hatası: ${error.message}');
    } else {
      _logger.e('API hatası: ${error.message}');
    }
  }
  
  // Token kaydetme
  Future<void> saveToken(String token) async {
    await _secureStorage.write(key: AppConstants.tokenKey, value: token);
    setToken(token);
  }
  
  // Token silme
  Future<void> deleteToken() async {
    await _secureStorage.delete(key: AppConstants.tokenKey);
    _dio.options.headers.remove('Authorization');
  }
  
  // Token varlığını kontrol etme (oturum açık mı?)
  Future<bool> hasToken() async {
    final token = await _secureStorage.read(key: AppConstants.tokenKey);
    return token != null && token.isNotEmpty;
  }
  
  // Kullanıcı kaydı
  Future<User> register({
    required String name,
    required String surname,
    required String email,
    required String password,
    String? role,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/register',
        data: {
          'name': name,
          'surname': surname,
          'email': email,
          'password': password,
          if (role != null) 'role': role,
        },
      );
      
      final data = response.data;
      
      // Token'ı kaydet
      if (data['token'] != null) {
        await saveToken(data['token']);
      }
      
      return User.fromJson(data['data']);
    } on DioException catch (e) {
      throw _formatError(e);
    }
  }
  
  // Puantajcı (supervisor) kaydı
  Future<User> registerSupervisor({
    required String name,
    required String surname,
    required String email,
    required String password,
  }) async {
    return register(
      name: name,
      surname: surname,
      email: email,
      password: password,
      role: AppConstants.roleSupervisor,
    );
  }
  
  // Kullanıcı girişi (email ile)
  Future<User> loginWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/login',
        data: {
          'email': email,
          'password': password,
        },
      );
      
      final data = response.data;
      
      // Token'ı kaydet
      if (data['token'] != null) {
        await saveToken(data['token']);
      }
      
      return User.fromJson(data['data']);
    } on DioException catch (e) {
      throw _formatError(e);
    }
  }
  
  // Kullanıcı girişi (kod ile - işçi ve malzemeci için)
  Future<User> loginWithCode({
    required String code,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/login',
        data: {
          'code': code,
          'password': password,
        },
      );
      
      final data = response.data;
      
      // Token'ı kaydet
      if (data['token'] != null) {
        await saveToken(data['token']);
      }
      
      return User.fromJson(data['data']);
    } on DioException catch (e) {
      throw _formatError(e);
    }
  }
  
  // Kullanıcı çıkışı
  Future<void> logout() async {
    await deleteToken();
  }
  
  // Kullanıcı profili alma
  Future<User> getUserProfile() async {
    try {
      final response = await _dio.get('/users/profile');
      return User.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw _formatError(e);
    }
  }
  
  // Kendi hesabını silme
  Future<void> deleteAccount() async {
    try {
      await _dio.delete('/users/delete');
      await deleteToken();
    } on DioException catch (e) {
      throw _formatError(e);
    }
  }
  
  // Başka bir kullanıcıyı silme (puantajcı için)
  Future<void> deleteUser(String userId) async {
    try {
      await _dio.delete('/users/delete/$userId');
    } on DioException catch (e) {
      throw _formatError(e);
    }
  }
  
  // Kullanıcı profilini güncelleme
  Future<User> updateProfile({
    String? name,
    String? surname,
    String? email,
  }) async {
    try {
      final response = await _dio.put(
        '/users/update',
        data: {
          if (name != null) 'name': name,
          if (surname != null) 'surname': surname,
          if (email != null) 'email': email,
        },
      );
      
      return User.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw _formatError(e);
    }
  }
  
  // Şifre güncelleme
  Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await _dio.put(
        '/users/update-password',
        data: {
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        },
      );
    } on DioException catch (e) {
      throw _formatError(e);
    }
  }
  
  // Tüm kullanıcıları getir (puantajcı için)
  Future<List<User>> getAllUsers() async {
    try {
      final response = await _dio.get('/users');
      
      final List<dynamic> userList = response.data['data'];
      return userList.map((user) => User.fromJson(user)).toList();
    } on DioException catch (e) {
      throw _formatError(e);
    }
  }
  
  // Puantaj kaydı oluştur
  Future<Puantaj> createPuantaj({
    required String isciId,
    required String baslangicSaati,
    required String bitisSaati,
    required double calismaSuresi,
    required String projeId,
    required String projeBilgisi,
    String? aciklama,
    DateTime? tarih,
  }) async {
    try {
      final response = await _dio.post(
        '/puantaj',
        data: {
          'isciId': isciId,
          'baslangicSaati': baslangicSaati,
          'bitisSaati': bitisSaati,
          'calismaSuresi': calismaSuresi,
          'projeId': projeId,
          'projeBilgisi': projeBilgisi,
          if (aciklama != null) 'aciklama': aciklama,
          if (tarih != null) 'tarih': tarih.toIso8601String(),
        },
      );
      
      return Puantaj.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw _formatError(e);
    }
  }
  
  // Puantaj kaydı güncelle
  Future<Puantaj> updatePuantaj({
    required String puantajId,
    String? baslangicSaati,
    String? bitisSaati,
    double? calismaSuresi,
    String? projeId,
    String? projeBilgisi,
    String? aciklama,
    String? durum,
  }) async {
    try {
      final response = await _dio.put(
        '/puantaj/$puantajId',
        data: {
          if (baslangicSaati != null) 'baslangicSaati': baslangicSaati,
          if (bitisSaati != null) 'bitisSaati': bitisSaati,
          if (calismaSuresi != null) 'calismaSuresi': calismaSuresi,
          if (projeId != null) 'projeId': projeId,
          if (projeBilgisi != null) 'projeBilgisi': projeBilgisi,
          if (aciklama != null) 'aciklama': aciklama,
          if (durum != null) 'durum': durum,
        },
      );
      
      return Puantaj.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw _formatError(e);
    }
  }
  
  // Puantaj kaydı sil
  Future<void> deletePuantaj(String puantajId) async {
    try {
      await _dio.delete('/puantaj/$puantajId');
    } on DioException catch (e) {
      throw _formatError(e);
    }
  }
  
  // İşçinin puantaj kayıtlarını getir
  Future<List<Puantaj>> getIsciPuantajlari(String isciId) async {
    try {
      final response = await _dio.get('/puantaj/isci/$isciId');
      
      final List<dynamic> puantajList = response.data['data'];
      return puantajList.map((puantaj) => Puantaj.fromJson(puantaj)).toList();
    } on DioException catch (e) {
      throw _formatError(e);
    }
  }
  
  // Puantajcının tüm puantaj kayıtlarını getir
  Future<List<Puantaj>> getPuantajciPuantajlari() async {
    try {
      final response = await _dio.get('/puantaj/puantajci');
      
      final List<dynamic> puantajList = response.data['data'];
      return puantajList.map((puantaj) => Puantaj.fromJson(puantaj)).toList();
    } on DioException catch (e) {
      throw _formatError(e);
    }
  }
  
  // Zimmet oluştur
  Future<Zimmet> createZimmet({
    required String supervisorId,
    required String supplierId,
    required String workerId,
    required String itemName,
    required int quantity,
    required String date,
  }) async {
    try {
      final response = await _dio.post(
        '/zimmet',
        data: {
          'supervisorId': supervisorId,
          'supplierId': supplierId,
          'workerId': workerId,
          'itemName': itemName,
          'quantity': quantity,
          'date': date,
        },
      );
      
      return Zimmet.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw _formatError(e);
    }
  }
  
  // Zimmet listesini getir
  Future<List<Zimmet>> getZimmetler() async {
    try {
      final response = await _dio.get('/zimmet');
      
      final List<dynamic> zimmetList = response.data['data'];
      return zimmetList.map((zimmet) => Zimmet.fromJson(zimmet)).toList();
    } on DioException catch (e) {
      throw _formatError(e);
    }
  }
  
  // İşçinin zimmetlerini getir
  Future<List<Zimmet>> getIsciZimmetleri(String workerId) async {
    try {
      final response = await _dio.get('/zimmet/isci/$workerId');
      
      final List<dynamic> zimmetList = response.data['data'];
      return zimmetList.map((zimmet) => Zimmet.fromJson(zimmet)).toList();
    } on DioException catch (e) {
      throw _formatError(e);
    }
  }
  
  // Bir DioException'ı kullanıcı dostu hata mesajına dönüştür
  String _formatError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return 'Bağlantı zaman aşımına uğradı. Lütfen internet bağlantınızı kontrol edin.';
    } else if (e.type == DioExceptionType.badResponse) {
      final statusCode = e.response?.statusCode;
      final responseData = e.response?.data;
      
      if (statusCode == 401) {
        return 'Oturum süreniz dolmuş. Lütfen tekrar giriş yapın.';
      } else if (statusCode == 403) {
        return 'Bu işlem için yetkiniz bulunmuyor.';
      } else if (statusCode == 404) {
        return 'İstenilen kaynak bulunamadı.';
      } else if (statusCode == 400) {
        if (responseData is Map && responseData['message'] != null) {
          return responseData['message'];
        }
        return 'Geçersiz istek. Lütfen bilgileri kontrol edin.';
      } else {
        return 'Sunucu hatası: ${responseData?['message'] ?? 'Bilinmeyen hata'}';
      }
    } else if (e.type == DioExceptionType.connectionError) {
      return 'İnternet bağlantısı yok. Lütfen bağlantınızı kontrol edin.';
    } else {
      return 'Bir hata oluştu: ${e.message}';
    }
  }
} 