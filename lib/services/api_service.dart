import 'dart:io';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:iskele360v7/models/inventory_model.dart';
import 'package:iskele360v7/models/puantaj_model.dart';
import 'package:iskele360v7/models/supplier_model.dart';
import 'package:iskele360v7/models/user_model.dart';
import 'package:iskele360v7/models/worker_model.dart';
import 'package:iskele360v7/utils/constants.dart';
import 'package:logger/logger.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();

  factory ApiService() {
    return _instance;
  }

  late final Dio _dio;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final Logger _logger = Logger();
  late final SharedPreferences _prefs;

  ApiService._internal() {
    _initDio();
    _initPrefs();
  }

  Future<void> _initPrefs() async {
    _prefs = await SharedPreferences.getInstance();
  }

  void _initDio() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConstants.apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

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

    if (kDebugMode) {
      _dio.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
      ));
    }
  }

  Future<Response<T>> get<T>(String path,
      {Map<String, dynamic>? queryParameters}) async {
    try {
      final response = await _dio.get<T>(
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

  Future<Response<T>> post<T>(String path,
      {dynamic data, Map<String, dynamic>? queryParameters}) async {
    try {
      final response = await _dio.post<T>(
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

  Future<Response<T>> put<T>(String path,
      {dynamic data, Map<String, dynamic>? queryParameters}) async {
    try {
      final response = await _dio.put<T>(
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

  Future<Response<T>> delete<T>(String path,
      {dynamic data, Map<String, dynamic>? queryParameters}) async {
    try {
      final response = await _dio.delete<T>(
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

  Future<void> setToken(String token) async {
    await _secureStorage.write(key: AppConstants.tokenKey, value: token);
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

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
      } else {
        _logger.e('Sunucu hatası ($statusCode): $responseData');
      }
    } else if (error.type == DioExceptionType.connectionError) {
      _logger.e('Ağ bağlantısı hatası: ${error.message}');
    } else {
      _logger.e('API hatası: ${error.message}');
    }
  }

  Future<void> deleteToken() async {
    await _secureStorage.delete(key: AppConstants.tokenKey);
    _dio.options.headers.remove('Authorization');
  }

  Future<bool> hasToken() async {
    final token = await _secureStorage.read(key: AppConstants.tokenKey);
    return token != null && token.isNotEmpty;
  }

  // Auth Methods
  Future<User> getUserData() async {
    try {
      final response = await get('/api/users/me');
      return User.fromJson(response.data['data']);
    } catch (e) {
      rethrow;
    }
  }

  Future<User> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await post('/api/auth/login', data: {
        'email': email,
        'password': password,
      });

      if (response.data['token'] != null) {
        await setToken(response.data['token']);
      }

      // Token alındıktan sonra kullanıcı bilgilerini al
      final userResponse = await get('/api/users/me');
      return User.fromJson(userResponse.data['data']);
    } catch (e) {
      rethrow;
    }
  }

  Future<User> register({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String role,
  }) async {
    try {
      final response = await post('/api/auth/register', data: {
        'name': name.split(' ')[0],
        'surname': name.split(' ').length > 1 ? name.split(' ').sublist(1).join(' ') : '',
        'email': email,
        'password': password,
        'phone': phone,
        'role': role,
      });

      return User(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name.split(' ')[0],
        surname: name.split(' ').length > 1 ? name.split(' ').sublist(1).join(' ') : '',
        email: email,
        role: role,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<User> loginWithSupplierCode({
    required String code,
  }) async {
    try {
      final response = await post('/api/auth/supplier/login', data: {
        'code': code,
      });
      if (response.data['token'] != null) {
        await setToken(response.data['token']);
      }
      return User.fromJson(response.data['data']);
    } catch (e) {
      rethrow;
    }
  }

  Future<User> loginWithWorkerCode({
    required String code,
  }) async {
    try {
      final response = await post('/api/auth/worker/login', data: {
        'code': code,
      });
      if (response.data['token'] != null) {
        await setToken(response.data['token']);
      }
      return User.fromJson(response.data['data']);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      await post('/auth/logout');
      await deleteToken();
    } catch (e) {
      rethrow;
    }
  }

  // Puantaj Methods
  Future<List<Puantaj>> getPuantajList() async {
    try {
      final response = await get('/puantaj');
      final List<dynamic> data = response.data['data'];
      return data.map((json) => Puantaj.fromJson(json)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<Puantaj> createPuantaj(Map<String, dynamic> data) async {
    try {
      final response = await post('/puantaj', data: data);
      return Puantaj.fromJson(response.data['data']);
    } catch (e) {
      rethrow;
    }
  }

  Future<Puantaj> updatePuantaj(String id, Map<String, dynamic> data) async {
    try {
      final response = await put('/puantaj/$id', data: data);
      return Puantaj.fromJson(response.data['data']);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deletePuantaj(String id) async {
    try {
      await delete('/puantaj/$id');
    } catch (e) {
      rethrow;
    }
  }

  // Worker Methods
  Future<List<Worker>> getWorkerList() async {
    try {
      final response = await get('/workers');
      final List<dynamic> data = response.data['data'];
      return data.map((json) => Worker.fromJson(json)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<Worker> createWorker(Map<String, dynamic> data) async {
    try {
      final response = await post('/workers', data: data);
      return Worker.fromJson(response.data['data']);
    } catch (e) {
      rethrow;
    }
  }

  Future<Worker> updateWorker(String id, Map<String, dynamic> data) async {
    try {
      final response = await put('/workers/$id', data: data);
      return Worker.fromJson(response.data['data']);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteWorker(String id) async {
    try {
      await delete('/workers/$id');
    } catch (e) {
      rethrow;
    }
  }

  // Supplier Methods
  Future<List<Supplier>> getSupplierList() async {
    try {
      final response = await get('/suppliers');
      final List<dynamic> data = response.data['data'];
      return data.map((json) => Supplier.fromJson(json)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<Supplier> createSupplier(Map<String, dynamic> data) async {
    try {
      final response = await post('/suppliers', data: data);
      return Supplier.fromJson(response.data['data']);
    } catch (e) {
      rethrow;
    }
  }

  Future<Supplier> updateSupplier(String id, Map<String, dynamic> data) async {
    try {
      final response = await put('/suppliers/$id', data: data);
      return Supplier.fromJson(response.data['data']);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteSupplier(String id) async {
    try {
      await delete('/suppliers/$id');
    } catch (e) {
      rethrow;
    }
  }

  // Inventory Methods
  Future<List<Inventory>> getInventoryList() async {
    try {
      final response = await get('/inventory');
      final List<dynamic> data = response.data['data'];
      return data.map((json) => Inventory.fromJson(json)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<Inventory> createInventory(Map<String, dynamic> data) async {
    try {
      final response = await post('/inventory', data: data);
      return Inventory.fromJson(response.data['data']);
    } catch (e) {
      rethrow;
    }
  }

  Future<Inventory> updateInventory(String id, Map<String, dynamic> data) async {
    try {
      final response = await put('/inventory/$id', data: data);
      return Inventory.fromJson(response.data['data']);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteInventory(String id) async {
    try {
      await delete('/inventory/$id');
    } catch (e) {
      rethrow;
    }
  }
}
