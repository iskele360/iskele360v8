import 'package:flutter/material.dart';
import 'package:iskele360v7/models/user_model.dart';
import 'package:iskele360v7/services/api_service.dart';

class UserProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  List<User> _workers = [];
  List<User> _suppliers = [];
  bool _isLoading = false;
  String? _errorMessage;
  
  // Getter methods
  List<User> get workers => _workers;
  List<User> get suppliers => _suppliers;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  
  // Puantajcı: Yeni işçi oluştur
  Future<bool> createWorker({
    required String firstName, 
    required String lastName,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      final response = await _apiService.post(
        '/users/create-worker',
        data: {
          'firstName': firstName,
          'lastName': lastName,
          'password': password,
        },
      );
      
      if (response.statusCode == 201) {
        // Kod oluşturulduğunda ekrana göster
        final workerCode = response.data['code'];
        // İşçi listesini güncelle
        await getWorkers();
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
  
  // Puantajcı: Yeni malzemeci oluştur
  Future<bool> createSupplier({
    required String firstName, 
    required String lastName,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      final response = await _apiService.post(
        '/users/create-supplier',
        data: {
          'firstName': firstName,
          'lastName': lastName,
          'password': password,
        },
      );
      
      if (response.statusCode == 201) {
        // Kod oluşturulduğunda ekrana göster
        final supplierCode = response.data['code'];
        // Malzemeci listesini güncelle
        await getSuppliers();
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
  
  // İşçileri getir
  Future<void> getWorkers() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      final response = await _apiService.get('/users/workers');
      
      if (response.statusCode == 200) {
        final List<dynamic> workersData = response.data['workers'];
        _workers = workersData.map((data) => User.fromJson(data)).toList();
        _isLoading = false;
        notifyListeners();
      } else {
        _errorMessage = 'İşçi listesi alınamadı: ${response.data['message'] ?? 'Bilinmeyen hata'}';
        _isLoading = false;
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'İşçi listesi alınırken hata oluştu: $e';
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Malzemecileri getir
  Future<void> getSuppliers() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      final response = await _apiService.get('/users/suppliers');
      
      if (response.statusCode == 200) {
        final List<dynamic> suppliersData = response.data['suppliers'];
        _suppliers = suppliersData.map((data) => User.fromJson(data)).toList();
        _isLoading = false;
        notifyListeners();
      } else {
        _errorMessage = 'Malzemeci listesi alınamadı: ${response.data['message'] ?? 'Bilinmeyen hata'}';
        _isLoading = false;
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Malzemeci listesi alınırken hata oluştu: $e';
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Kullanıcıyı (İşçi/Malzemeci) koda göre al
  Future<User?> getUserByCode(String code) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      final response = await _apiService.get('/users/by-code/$code');
      
      if (response.statusCode == 200) {
        final userData = response.data['user'];
        final user = User.fromJson(userData);
        _isLoading = false;
        notifyListeners();
        return user;
      } else {
        _errorMessage = 'Kullanıcı bulunamadı: ${response.data['message'] ?? 'Bilinmeyen hata'}';
        _isLoading = false;
        notifyListeners();
        return null;
      }
    } catch (e) {
      _errorMessage = 'Kullanıcı aranırken hata oluştu: $e';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }
} 