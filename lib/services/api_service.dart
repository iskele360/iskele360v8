import 'dart:io';

import 'package:dio/dio.dart';
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

  final Dio _dio = Dio();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final Logger _logger = Logger();

  ApiService._internal() {
    _initDio();
  }

  void _initDio() {
    _dio.options.baseUrl = AppConstants.apiBaseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 10);
    _dio.options.receiveTimeout = const Duration(seconds: 10);
    _dio.options.headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

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

  Future<Response> get(String path,
      {Map<String, dynamic>? queryParameters}) async {
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

  Future<Response> post(String path,
      {dynamic data, Map<String, dynamic>? queryParameters}) async {
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

  Future<Response> put(String path,
      {dynamic data, Map<String, dynamic>? queryParameters}) async {
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

  Future<Response> delete(String path,
      {dynamic data, Map<String, dynamic>? queryParameters}) async {
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

  void setToken(String token) {
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

  Future<void> saveToken(String token) async {
    await _secureStorage.write(key: AppConstants.tokenKey, value: token);
    setToken(token);
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
      final response = await get('/users/me');
      return User.fromJson(response.data['data']);
    } catch (e) {
      rethrow;
    }
  }

  Future<User> loginWithSupplierCode({
    required String name,
    required String surname,
    required String code,
  }) async {
    try {
      final response = await post('/auth/supplier/login', data: {
        'name': name,
        'surname': surname,
        'code': code,
      });
      if (response.data['token'] != null) {
        await saveToken(response.data['token']);
      }
      return User.fromJson(response.data['data']);
    } catch (e) {
      rethrow;
    }
  }

  Future<User> loginWithWorkerCode({
    required String name,
    required String surname,
    required String code,
  }) async {
    try {
      final response = await post('/auth/worker/login', data: {
        'name': name,
        'surname': surname,
        'code': code,
      });
      if (response.data['token'] != null) {
        await saveToken(response.data['token']);
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

  // Worker Methods
  Future<List<Worker>> getAllWorkers() async {
    try {
      final response = await get('/workers');
      final List<dynamic> workers = response.data['data'];
      return workers.map((w) => Worker.fromJson(w)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Worker>> getWorkers() async {
    try {
      final response = await get('/workers');
      final List<dynamic> workers = response.data['data'];
      return workers.map((w) => Worker.fromJson(w)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<Worker> addWorker(Map<String, dynamic> data) async {
    try {
      final response = await post('/workers', data: data);
      return Worker.fromJson(response.data['data']);
    } catch (e) {
      rethrow;
    }
  }

  // Inventory Methods
  Future<List<Inventory>> getWorkerInventories(String workerId) async {
    try {
      final response = await get('/inventories/worker/$workerId');
      final List<dynamic> inventories = response.data['data'];
      return inventories.map((i) => Inventory.fromJson(i)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<Inventory> addInventory(Map<String, dynamic> data) async {
    try {
      final response = await post('/inventories', data: data);
      return Inventory.fromJson(response.data['data']);
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Inventory>> getCurrentWorkerInventories() async {
    try {
      final response = await get('/inventories/current');
      final List<dynamic> inventories = response.data['data'];
      return inventories.map((i) => Inventory.fromJson(i)).toList();
    } catch (e) {
      rethrow;
    }
  }

  // Supplier Methods
  Future<List<Supplier>> getSuppliers() async {
    try {
      final response = await get('/suppliers');
      final List<dynamic> suppliers = response.data['data'];
      return suppliers.map((s) => Supplier.fromJson(s)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<Supplier> addSupplier(Map<String, dynamic> data) async {
    try {
      final response = await post('/suppliers', data: data);
      return Supplier.fromJson(response.data['data']);
    } catch (e) {
      rethrow;
    }
  }

  // Puantaj Methods
  Future<List<Puantaj>> getPuantajciPuantajlari() async {
    try {
      final response = await get('/puantaj/supervisor');
      final List<dynamic> puantajList = response.data['data'];
      return puantajList.map((p) => Puantaj.fromJson(p)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Puantaj>> getIsciPuantajlari(String workerId) async {
    try {
      final response = await get('/puantaj/worker/$workerId');
      final List<dynamic> puantajList = response.data['data'];
      return puantajList.map((p) => Puantaj.fromJson(p)).toList();
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
