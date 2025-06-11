import 'package:flutter/material.dart';
import 'package:iskele360v7/models/malzeme_model.dart';
import 'package:iskele360v7/models/user_model.dart';
import 'package:iskele360v7/services/api_service.dart';

class MalzemeProvider with ChangeNotifier {
  final ApiService _apiService;
  
  List<Malzeme> _malzemeList = [];
  List<Zimmet> _zimmetList = [];
  List<User> _isciList = [];
  
  bool _isLoading = false;
  String? _errorMessage;
  
  // Getter methods
  List<Malzeme> get malzemeList => _malzemeList;
  List<Zimmet> get zimmetList => _zimmetList;
  List<User> get isciList => _isciList;
  
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  
  MalzemeProvider(this._apiService);
  
  // Malzemeci: Yeni malzeme ekle
  Future<bool> createMalzeme({
    required String name,
    String? description,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      final response = await _apiService.post(
        '/malzeme/create',
        data: {
          'name': name,
          'description': description,
        },
      );
      
      if (response.statusCode == 201) {
        // Yeni malzeme oluşturuldu, listeyi güncelle
        await getMalzemeList();
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Malzeme oluşturma başarısız: ${response.data['message'] ?? 'Bilinmeyen hata'}';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Malzeme oluşturma sırasında hata oluştu: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  // Tüm malzemeleri getir
  Future<void> getMalzemeList() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      final response = await _apiService.get('/malzeme/list');
      
      if (response.statusCode == 200) {
        final List<dynamic> malzemeData = response.data['malzemeler'];
        _malzemeList = malzemeData.map((data) => Malzeme.fromJson(data)).toList();
        _isLoading = false;
        notifyListeners();
      } else {
        _errorMessage = 'Malzeme listesi alınamadı: ${response.data['message'] ?? 'Bilinmeyen hata'}';
        _isLoading = false;
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Malzeme listesi alınırken hata oluştu: $e';
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Malzeme zimmet oluştur
  Future<bool> createZimmet({
    required String malzemeId,
    required String workerId,
    required int quantity,
    String? note,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      final response = await _apiService.post(
        '/zimmet/create',
        data: {
          'malzemeId': malzemeId,
          'workerId': workerId,
          'quantity': quantity,
          'note': note,
        },
      );
      
      if (response.statusCode == 201) {
        // Yeni zimmet oluşturuldu, listeyi güncelle
        await getZimmetList();
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Zimmet oluşturma başarısız: ${response.data['message'] ?? 'Bilinmeyen hata'}';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Zimmet oluşturma sırasında hata oluştu: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  // Tüm zimmetleri getir
  Future<void> getZimmetList() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      final response = await _apiService.get('/zimmet/list');
      
      if (response.statusCode == 200) {
        final List<dynamic> zimmetData = response.data['zimmetler'];
        _zimmetList = zimmetData.map((data) => Zimmet.fromJson(data)).toList();
        _isLoading = false;
        notifyListeners();
      } else {
        _errorMessage = 'Zimmet listesi alınamadı: ${response.data['message'] ?? 'Bilinmeyen hata'}';
        _isLoading = false;
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Zimmet listesi alınırken hata oluştu: $e';
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // İşçiye göre zimmetleri getir
  Future<void> getZimmetByWorkerId(String workerId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      final response = await _apiService.get('/zimmet/worker/$workerId');
      
      if (response.statusCode == 200) {
        final List<dynamic> zimmetData = response.data['zimmetler'];
        _zimmetList = zimmetData.map((data) => Zimmet.fromJson(data)).toList();
        _isLoading = false;
        notifyListeners();
      } else {
        _errorMessage = 'İşçi zimmetleri alınamadı: ${response.data['message'] ?? 'Bilinmeyen hata'}';
        _isLoading = false;
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'İşçi zimmetleri alınırken hata oluştu: $e';
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Malzemeciye göre zimmetleri getir
  Future<void> getZimmetBySupplierId(String supplierId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      final response = await _apiService.get('/zimmet/supplier/$supplierId');
      
      if (response.statusCode == 200) {
        final List<dynamic> zimmetData = response.data['zimmetler'];
        _zimmetList = zimmetData.map((data) => Zimmet.fromJson(data)).toList();
        _isLoading = false;
        notifyListeners();
      } else {
        _errorMessage = 'Malzemeci zimmetleri alınamadı: ${response.data['message'] ?? 'Bilinmeyen hata'}';
        _isLoading = false;
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Malzemeci zimmetleri alınırken hata oluştu: $e';
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // İşçi listesini getir (malzeme zimmetlemek için)
  Future<void> getIsciList() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      final response = await _apiService.get('/users/workers');
      
      if (response.statusCode == 200) {
        final List<dynamic> isciData = response.data['workers'];
        _isciList = isciData.map((data) => User.fromJson(data)).toList();
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
  
  // Zimmeti iade et
  Future<bool> returnZimmet(String zimmetId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      final response = await _apiService.put(
        '/zimmet/return/$zimmetId',
        data: {'returnDate': DateTime.now().toIso8601String()},
      );
      
      if (response.statusCode == 200) {
        // Zimmet güncellendi, listeyi güncelle
        await getZimmetList();
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Zimmet iadesi başarısız: ${response.data['message'] ?? 'Bilinmeyen hata'}';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Zimmet iadesi sırasında hata oluştu: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
} 