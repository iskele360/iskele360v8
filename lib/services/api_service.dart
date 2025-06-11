import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:iskele360v7/models/worker_model.dart';
import 'package:iskele360v7/models/supplier_model.dart';
import 'package:iskele360v7/models/inventory_model.dart';

class ApiService {
  // API URL'i (gerçek bir API olduğunda kullanılacak)
  // static const String baseUrl = 'http://192.168.1.105:5050/api';
  
  // Token'ı SharedPreferences'a kaydetmek için key
  static const String _tokenKey = 'auth_token';
  static const String _userDataKey = 'user_data';
  static const String _workersKey = 'workers_data';
  static const String _suppliersKey = 'suppliers_data';
  static const String _inventoryKey = 'inventory_data';
  static const String _supervisorsKey = 'supervisors_data';
  
  // HTTP istekleri için headers
  Future<Map<String, String>> _getHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }
  
  // Token'ı kaydet
  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }
  
  // Token'ı getir
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }
  
  // Kullanıcı verilerini kaydet
  Future<void> saveUserData(Map<String, dynamic> userData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataString = json.encode(userData);
      await prefs.setString(_userDataKey, userDataString);
      
      // Ayrıca oturum durumunu da kaydet
      await prefs.setBool('is_logged_in', true);
      
      print('Kullanıcı verileri kaydedildi: $userDataString');
    } catch (e) {
      print('Kullanıcı verileri kaydedilirken hata: $e');
      rethrow;
    }
  }
  
  // Kullanıcı verilerini getir
  Future<Map<String, dynamic>?> getUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataString = prefs.getString(_userDataKey);
      
      if (userDataString == null || userDataString.isEmpty) {
        print('Kayıtlı kullanıcı verisi bulunamadı');
        return null;
      }
      
      print('Kullanıcı verileri getirildi: $userDataString');
      return json.decode(userDataString) as Map<String, dynamic>;
    } catch (e) {
      print('Kullanıcı verileri getirilirken hata: $e');
      return null;
    }
  }
  
  // Token ve kullanıcı verisini temizle (çıkış yapma)
  Future<void> clearAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userDataKey);
  }
  
  // Puantajcı kaydı - Yerel olarak kayıt oluşturur
  Future<Map<String, dynamic>> registerSupervisor({
    required String name,
    required String surname,
    required String email,
    required String password,
  }) async {
    // API yerine yerel depolamada saklıyoruz
    final supervisorId = DateTime.now().millisecondsSinceEpoch.toString();
    final supervisorData = {
      'id': supervisorId,
      'name': name,
      'surname': surname,
      'email': email,
      'password': password, // Gerçek uygulamada şifre böyle saklanmaz, hashlenmelidir
      'role': 'supervisor',
      'createdAt': DateTime.now().toIso8601String(),
    };
    
    // Supervisor'ı yerel depolamaya ekle
    await _saveSupervisor(supervisorData);
    
    // Token oluştur (basit bir token)
    final token = 'token_$supervisorId';
    
    // Token ve kullanıcı verisini kaydet
    await saveToken(token);
    await saveUserData(supervisorData);
    
    return {
      'token': token,
      'data': {
        'user': supervisorData,
      }
    };
  }
  
  // Supervisor'ı kaydet
  Future<void> _saveSupervisor(Map<String, dynamic> supervisorData) async {
    final prefs = await SharedPreferences.getInstance();
    final supervisorsString = prefs.getString(_supervisorsKey) ?? '[]';
    final List<dynamic> supervisorsJson = json.decode(supervisorsString);
    
    // Mevcut supervisor'ları al
    final supervisors = List<Map<String, dynamic>>.from(supervisorsJson);
    
    // Yeni supervisor'ı ekle
    supervisors.add(supervisorData);
    
    // Tüm supervisor'ları JSON'a dönüştür ve kaydet
    await prefs.setString(_supervisorsKey, json.encode(supervisors));
  }
  
  // Email ile giriş - Yerel olarak doğrulama yapar
  Future<Map<String, dynamic>> loginWithEmail({
    required String email,
    required String password,
  }) async {
    // Tüm supervisor'ları al
    final prefs = await SharedPreferences.getInstance();
    final supervisorsString = prefs.getString(_supervisorsKey) ?? '[]';
    final List<dynamic> supervisorsJson = json.decode(supervisorsString);
    
    // Email ve şifre ile eşleşen supervisor'ı bul
    final supervisor = supervisorsJson.firstWhere(
      (s) => s['email'] == email && s['password'] == password,
      orElse: () => throw Exception('Geçersiz email veya şifre'),
    );
    
    // Token oluştur (basit bir token)
    final token = 'token_${supervisor['id']}';
    
    // Token ve kullanıcı verisini kaydet
    await saveToken(token);
    await saveUserData(supervisor);
    
    return {
      'token': token,
      'data': {
        'user': supervisor,
      }
    };
  }
  
  // Kullanıcı profili
  Future<Map<String, dynamic>> getUserProfile() async {
    final userData = await getUserData();
    if (userData == null) {
      throw Exception('Kullanıcı bulunamadı');
    }
    return userData;
  }
  
  // Kullanıcının giriş yapmış olup olmadığını kontrol et
  Future<bool> isLoggedIn() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('is_logged_in') ?? false;
    } catch (e) {
      print('Oturum durumu kontrol edilirken hata: $e');
      return false;
    }
  }
  
  // Kullanıcı rolünü getir
  Future<String?> getUserRole() async {
    final userData = await getUserData();
    return userData?['role'];
  }
  
  // 6 haneli rastgele kod oluştur
  String generateRandomCode() {
    final random = Random();
    String code = '';
    for (int i = 0; i < 6; i++) {
      code += random.nextInt(10).toString();
    }
    return code;
  }
  
  // İşçi ekle
  Future<Worker> addWorker({
    required String name,
    required String surname,
  }) async {
    // Puantajcı bilgilerini al
    final userData = await getUserData();
    final supervisorId = userData?['id'] ?? 'unknown_supervisor';
    
    print('İşçi ekleyen puantajcı ID: $supervisorId');
    
    // 6 haneli benzersiz kod oluştur
    final code = generateRandomCode();
    
    // İşçi oluştur
    final worker = Worker(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      surname: surname,
      code: code,
      password: null,
      supervisorId: supervisorId, // Puantajcının ID'sini kullan
      createdAt: DateTime.now(),
    );
    
    // İşçiyi doğrudan SharedPreferences'a kaydedelim
    await _saveWorkerDirectly(worker);
    
    return worker;
  }
  
  // İşçiyi doğrudan SharedPreferences'a kaydet
  Future<void> _saveWorkerDirectly(Worker worker) async {
    final prefs = await SharedPreferences.getInstance();
    final workersString = prefs.getString(_workersKey) ?? '[]';
    
    print('Mevcut işçi verisi: $workersString');
    
    List<dynamic> workersJson = [];
    try {
      workersJson = json.decode(workersString) as List<dynamic>;
    } catch (e) {
      print('JSON çözümlemede hata: $e');
      workersJson = [];
    }
    
    // Yeni işçiyi ekle
    final workerJson = worker.toJson();
    workersJson.add(workerJson);
    
    // Güncellenmiş listeyi kaydet
    final updatedWorkersString = json.encode(workersJson);
    await prefs.setString(_workersKey, updatedWorkersString);
    
    print('İşçi başarıyla kaydedildi: ${worker.name} ${worker.surname}, Kod: ${worker.code}');
    print('Güncellenmiş işçi verisi: $updatedWorkersString');
    
    // Veri kalıcılığını kontrol et
    final verifyData = prefs.getString(_workersKey);
    print('Kalıcılık kontrolü: ${verifyData != null && verifyData.isNotEmpty}');
  }
  
  // İşçileri getir - Tüm işçileri döndürür, supervisor filtresi uygulanmaz
  Future<List<Worker>> getAllWorkers() async {
    final prefs = await SharedPreferences.getInstance();
    final workersString = prefs.getString(_workersKey) ?? '[]';
    
    print('Tüm işçi verisi: $workersString');
    
    final List<dynamic> workersJson = json.decode(workersString);
    
    // Tüm işçileri döndür, filtreleme yok
    final allWorkers = workersJson.map((w) {
      try {
        return Worker.fromJson(w as Map<String, dynamic>);
      } catch (e) {
        print('İşçi dönüştürme hatası: $e');
        return null;
      }
    }).whereType<Worker>().toList();
    
    print('Toplam işçi sayısı: ${allWorkers.length}');
    return allWorkers;
  }
  
  // İşçileri getir - Sadece belirli bir puantajcıya ait işçileri döndürür
  Future<List<Worker>> getWorkers() async {
    final userData = await getUserData();
    if (userData == null) {
      print('Oturum açılmamış, tüm işçiler döndürülüyor');
      return getAllWorkers();
    }
    
    final supervisorId = userData['id'];
    print('Puantajcı ID: $supervisorId için işçiler getiriliyor');
    
    final allWorkers = await getAllWorkers();
    
    // Sadece bu puantajcıya ait işçileri filtrele
    final supervisorWorkers = allWorkers.where((w) => w.supervisorId == supervisorId).toList();
    
    print('Bu puantajcıya ait işçi sayısı: ${supervisorWorkers.length}');
    return supervisorWorkers;
  }
  
  // Malzemeci ekle
  Future<Supplier> addSupplier({
    required String name,
    required String surname,
  }) async {
    // Puantajcı bilgilerini al
    final userData = await getUserData();
    final supervisorId = userData?['id'] ?? 'unknown_supervisor';
    
    print('Malzemeci ekleyen puantajcı ID: $supervisorId');
    
    // 6 haneli benzersiz kod oluştur
    final code = generateRandomCode();
    
    // Malzemeci oluştur
    final supplier = Supplier(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      surname: surname,
      code: code,
      supervisorId: supervisorId,
      createdAt: DateTime.now(),
    );
    
    // Malzemeciyi doğrudan SharedPreferences'a kaydedelim
    await _saveSupplierDirectly(supplier);
    
    return supplier;
  }
  
  // Malzemeciyi doğrudan SharedPreferences'a kaydet
  Future<void> _saveSupplierDirectly(Supplier supplier) async {
    final prefs = await SharedPreferences.getInstance();
    final suppliersString = prefs.getString(_suppliersKey) ?? '[]';
    
    print('Mevcut malzemeci verisi: $suppliersString');
    
    List<dynamic> suppliersJson = [];
    try {
      suppliersJson = json.decode(suppliersString) as List<dynamic>;
    } catch (e) {
      print('JSON çözümlemede hata: $e');
      suppliersJson = [];
    }
    
    // Yeni malzemeciyi ekle
    final supplierJson = supplier.toJson();
    suppliersJson.add(supplierJson);
    
    // Güncellenmiş listeyi kaydet
    final updatedSuppliersString = json.encode(suppliersJson);
    await prefs.setString(_suppliersKey, updatedSuppliersString);
    
    print('Malzemeci başarıyla kaydedildi: ${supplier.name} ${supplier.surname}, Kod: ${supplier.code}');
    print('Güncellenmiş malzemeci verisi: $updatedSuppliersString');
  }
  
  // Tüm malzemecileri getir
  Future<List<Supplier>> getAllSuppliers() async {
    final prefs = await SharedPreferences.getInstance();
    final suppliersString = prefs.getString(_suppliersKey) ?? '[]';
    
    print('Tüm malzemeci verisi: $suppliersString');
    
    final List<dynamic> suppliersJson = json.decode(suppliersString);
    
    // Tüm malzemecileri döndür, filtreleme yok
    final allSuppliers = suppliersJson.map((s) {
      try {
        return Supplier.fromJson(s as Map<String, dynamic>);
      } catch (e) {
        print('Malzemeci dönüştürme hatası: $e');
        return null;
      }
    }).whereType<Supplier>().toList();
    
    print('Toplam malzemeci sayısı: ${allSuppliers.length}');
    return allSuppliers;
  }
  
  // Sadece belirli bir puantajcıya ait malzemecileri getir
  Future<List<Supplier>> getSuppliers() async {
    final userData = await getUserData();
    if (userData == null) {
      print('Oturum açılmamış, tüm malzemeciler döndürülüyor');
      return getAllSuppliers();
    }
    
    final supervisorId = userData['id'];
    print('Puantajcı ID: $supervisorId için malzemeciler getiriliyor');
    
    final allSuppliers = await getAllSuppliers();
    
    // Sadece bu puantajcıya ait malzemecileri filtrele
    final supervisorSuppliers = allSuppliers.where((s) => s.supervisorId == supervisorId).toList();
    
    print('Bu puantajcıya ait malzemeci sayısı: ${supervisorSuppliers.length}');
    return supervisorSuppliers;
  }
  
  // Malzemeci kodu ile giriş
  Future<Map<String, dynamic>> loginWithSupplierCode({
    required String name,
    required String surname,
    required String code,
  }) async {
    try {
      print('Malzemeci girişi deneniyor: Ad: $name, Soyad: $surname, Kod: $code');
      
      // Giriş bilgilerini düzenle - trim ile boşlukları kaldır, toLowerCase ile küçük harfe çevir
      final trimmedName = name.trim().toLowerCase();
      final trimmedSurname = surname.trim().toLowerCase();
      final trimmedCode = code.trim();
      
      // Tüm malzemecileri al
      final allSuppliers = await getAllSuppliers();
      print('Toplam malzemeci sayısı: ${allSuppliers.length}');
      
      // Tüm malzemecileri konsola yazdır (debug için)
      for (var s in allSuppliers) {
        print('Malzemeci: ${s.name} ${s.surname}, Kod: ${s.code}');
      }
      
      // Kod ve isim/soyisim ile eşleşen malzemeciyi bul
      // Büyük/küçük harf ve boşluk farkını önemsememek için trim ve toLowerCase kullan
      final supplier = allSuppliers.firstWhere(
        (s) => 
          s.code.trim() == trimmedCode && 
          s.name.trim().toLowerCase() == trimmedName &&
          s.surname.trim().toLowerCase() == trimmedSurname,
        orElse: () {
          print('Eşleşen malzemeci bulunamadı');
          throw Exception('Geçersiz malzemeci bilgileri');
        },
      );
      
      print('Malzemeci bulundu: ${supplier.name} ${supplier.surname}, Kod: ${supplier.code}');
      
      // Malzemeci bilgilerini kullanıcı verisi olarak kaydet
      await saveUserData({
        'id': supplier.id,
        'name': supplier.name,
        'surname': supplier.surname,
        'code': supplier.code,
        'supervisorId': supplier.supervisorId,
        'role': 'supplier',
      });
      
      return {
        'success': true,
        'data': {
          'user': supplier.toJson(),
        }
      };
    } catch (e) {
      print('Malzemeci giriş hatası: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
  
  // İşçi kodu ile giriş
  Future<Map<String, dynamic>> loginWithWorkerCode({
    required String name,
    required String surname,
    required String code,
  }) async {
    try {
      print('İşçi girişi deneniyor: Ad: $name, Soyad: $surname, Kod: $code');
      
      // Giriş bilgilerini düzenle - trim ile boşlukları kaldır, toLowerCase ile küçük harfe çevir
      final trimmedName = name.trim().toLowerCase();
      final trimmedSurname = surname.trim().toLowerCase();
      final trimmedCode = code.trim();
      
      // Tüm işçileri al
      final allWorkers = await getAllWorkers();
      print('Toplam işçi sayısı: ${allWorkers.length}');
      
      // Tüm işçileri konsola yazdır (debug için)
      for (var w in allWorkers) {
        print('İşçi: ${w.name} ${w.surname}, Kod: ${w.code}');
      }
      
      // Kod ve isim/soyisim ile eşleşen işçiyi bul
      // Büyük/küçük harf ve boşluk farkını önemsememek için trim ve toLowerCase kullan
      final worker = allWorkers.firstWhere(
        (w) => 
          w.code.trim() == trimmedCode && 
          w.name.trim().toLowerCase() == trimmedName &&
          w.surname.trim().toLowerCase() == trimmedSurname,
        orElse: () {
          print('Eşleşen işçi bulunamadı');
          throw Exception('Geçersiz işçi bilgileri');
        },
      );
      
      print('İşçi bulundu: ${worker.name} ${worker.surname}, Kod: ${worker.code}');
      
      // İşçi bilgilerini kullanıcı verisi olarak kaydet
      await saveUserData({
        'id': worker.id,
        'name': worker.name,
        'surname': worker.surname,
        'code': worker.code,
        'supervisorId': worker.supervisorId,
        'role': 'worker',
      });
      
      return {
        'success': true,
        'data': {
          'user': worker.toJson(),
        }
      };
    } catch (e) {
      print('İşçi giriş hatası: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
  
  // Zimmet ekleme
  Future<Map<String, dynamic>> addInventory({
    required String workerId,
    required String itemName,
    required int quantity,
    required String supplierId,
    required String supervisorId,
    required String date,
  }) async {
    try {
      print('Zimmet ekleniyor: $itemName, Miktar: $quantity, İşçi ID: $workerId');
      
      // Rastgele bir ID oluştur
      final id = _generateRandomId();
      
      // Yeni zimmet oluştur
      final newInventory = Inventory(
        id: id,
        supervisorId: supervisorId,
        supplierId: supplierId,
        workerId: workerId,
        itemName: itemName,
        quantity: quantity,
        date: date,
      );

      // Mevcut zimmetleri al
      final allInventories = await getAllInventories();
      
      // Yeni zimmeti ekle
      allInventories.add(newInventory);
      
      // Zimmetleri kaydet
      await _saveInventoriesData(allInventories);
      
      print('Zimmet başarıyla eklendi. ID: $id');
      
      return {
        'success': true,
        'data': {
          'inventory': newInventory.toJson(),
        }
      };
    } catch (e) {
      print('Zimmet ekleme hatası: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
  
  // İşçiye ait zimmetleri getir
  Future<List<Inventory>> getWorkerInventory(String workerId) async {
    final prefs = await SharedPreferences.getInstance();
    final inventoryString = prefs.getString(_inventoryKey) ?? '[]';
    
    final List<dynamic> inventoryJson = json.decode(inventoryString);
    
    // Tüm zimmetleri oluştur
    final allInventory = inventoryJson.map((i) {
      try {
        return Inventory.fromJson(i as Map<String, dynamic>);
      } catch (e) {
        print('Zimmet dönüştürme hatası: $e');
        return null;
      }
    }).whereType<Inventory>().toList();
    
    // İşçiye ait zimmetleri filtrele
    return allInventory.where((i) => i.workerId == workerId).toList();
  }
  
  // Malzemeciye ait zimmetleri getir
  Future<List<Inventory>> getSupplierInventory(String supplierId) async {
    final prefs = await SharedPreferences.getInstance();
    final inventoryString = prefs.getString(_inventoryKey) ?? '[]';
    
    final List<dynamic> inventoryJson = json.decode(inventoryString);
    
    // Tüm zimmetleri oluştur
    final allInventory = inventoryJson.map((i) {
      try {
        return Inventory.fromJson(i as Map<String, dynamic>);
      } catch (e) {
        print('Zimmet dönüştürme hatası: $e');
        return null;
      }
    }).whereType<Inventory>().toList();
    
    // Malzemeciye ait zimmetleri filtrele
    return allInventory.where((i) => i.supplierId == supplierId).toList();
  }
  
  // Kullanıcı çıkışı
  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Sadece oturum durumunu false yap, verileri silme
      await prefs.setBool('is_logged_in', false);
      print('Kullanıcı çıkışı yapıldı');
    } catch (e) {
      print('Çıkış yapılırken hata: $e');
      rethrow;
    }
  }
  
  // Belirli bir işçinin zimmetlerini getir
  Future<Map<String, dynamic>> getWorkerInventories(String workerId) async {
    try {
      print('İşçi için zimmetler getiriliyor. İşçi ID: $workerId');
      
      // Tüm zimmetleri al
      final allInventories = await getAllInventories();
      print('Toplam zimmet sayısı: ${allInventories.length}');
      
      // Bu işçiye ait zimmetleri filtrele
      final workerInventories = allInventories.where((inv) => inv.workerId == workerId).toList();
      print('İşçiye ait zimmet sayısı: ${workerInventories.length}');
      
      return {
        'success': true,
        'data': {
          'inventories': workerInventories.map((inv) => inv.toJson()).toList(),
        }
      };
    } catch (e) {
      print('İşçi zimmetleri getirme hatası: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // İşçi koduna göre zimmetleri getir (giriş yapmış işçi için)
  Future<Map<String, dynamic>> getCurrentWorkerInventories() async {
    try {
      // Giriş yapmış işçinin bilgilerini al
      final userData = await getUserData();
      if (userData == null) {
        throw Exception('Kullanıcı verileri bulunamadı');
      }
      
      if (userData['role'] != 'worker') {
        throw Exception('Bu işlem sadece işçi rolü için geçerlidir');
      }
      
      final workerId = userData['id'] as String;
      print('Giriş yapan işçi için zimmetler getiriliyor. İşçi ID: $workerId');
      
      // İşçinin zimmetlerini getir
      return await getWorkerInventories(workerId);
    } catch (e) {
      print('Giriş yapan işçi için zimmet getirme hatası: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Tüm zimmetleri getir
  Future<List<Inventory>> getAllInventories() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final inventoriesString = prefs.getString('inventories_data') ?? '[]';
      
      // JSON verisini parse et
      final List<dynamic> inventoriesJson = json.decode(inventoriesString);
      
      // Inventory nesnelerini oluştur
      final inventories = inventoriesJson
          .map((json) => Inventory.fromJson(json as Map<String, dynamic>))
          .toList();
      
      return inventories;
    } catch (e) {
      print('Zimmet verileri getirme hatası: $e');
      return [];
    }
  }
  
  // Zimmet verilerini kaydet
  Future<void> _saveInventoriesData(List<Inventory> inventories) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final inventoriesJson = inventories.map((inv) => inv.toJson()).toList();
      await prefs.setString('inventories_data', json.encode(inventoriesJson));
      print('Zimmet verileri kaydedildi: ${inventories.length} zimmet');
    } catch (e) {
      print('Zimmet verileri kaydetme hatası: $e');
      throw Exception('Zimmet verileri kaydedilemedi: $e');
    }
  }

  // Rastgele bir ID oluşturma
  String _generateRandomId() {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random();
    final id = String.fromCharCodes(
      Iterable.generate(
        20, // ID uzunluğu
        (_) => chars.codeUnitAt(random.nextInt(chars.length)),
      ),
    );
    return id;
  }
} 