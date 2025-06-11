import 'package:flutter/foundation.dart';
import 'package:iskele360v7/models/puantaj_model.dart';
import 'package:iskele360v7/services/api_service.dart';
import 'package:iskele360v7/services/socket_service.dart';

class PuantajProvider with ChangeNotifier {
  final ApiService _apiService;
  final SocketService _socketService = SocketService();
  
  List<Puantaj> _allPuantajlar = [];
  List<Puantaj> _filteredPuantajlar = [];
  bool _isLoading = false;
  String? _errorMessage;
  
  // Getters
  List<Puantaj> get allPuantajlar => _allPuantajlar;
  List<Puantaj> get filteredPuantajlar => _filteredPuantajlar;
  List<Puantaj> get puantajList => _filteredPuantajlar;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  
  PuantajProvider(this._apiService) {
    // Socket.IO üzerinden gelen puantaj güncellemelerini dinle
    _socketService.onPuantajCreated.listen((puantaj) {
      _handleNewPuantaj(puantaj);
    });
    
    _socketService.onPuantajUpdated.listen((puantaj) {
      _handlePuantajUpdate(puantaj);
    });
  }
  
  // Puantajcının tüm puantaj kayıtlarını getir
  Future<void> loadPuantajciPuantajlari() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      final puantajlar = await _apiService.getPuantajciPuantajlari();
      _allPuantajlar = puantajlar;
      _filteredPuantajlar = List.from(_allPuantajlar);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }
  
  // İşçinin puantaj kayıtlarını getir
  Future<void> loadIsciPuantajlari(String isciId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      final puantajlar = await _apiService.getIsciPuantajlari(isciId);
      _allPuantajlar = puantajlar;
      _filteredPuantajlar = List.from(_allPuantajlar);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }
  
  // Tüm puantaj kayıtlarını getir (getPuantajList metodu)
  Future<void> getPuantajList() async {
    return loadPuantajciPuantajlari();
  }
  
  // İşçinin puantaj kayıtlarını getir (getPuantajByWorkerId metodu)
  Future<void> getPuantajByWorkerId(String workerId) async {
    return loadIsciPuantajlari(workerId);
  }
  
  // Yeni puantaj kaydı oluştur
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
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      final puantaj = await _apiService.createPuantaj(
        isciId: isciId,
        baslangicSaati: baslangicSaati,
        bitisSaati: bitisSaati,
        calismaSuresi: calismaSuresi,
        projeId: projeId,
        projeBilgisi: projeBilgisi,
        aciklama: aciklama,
        tarih: tarih,
      );
      
      // Socket.IO üzerinden bildirim gönder
      _socketService.emitPuantajCreated(puantaj);
      
      // Listeye ekle
      _allPuantajlar.add(puantaj);
      _filteredPuantajlar = List.from(_allPuantajlar);
      _isLoading = false;
      notifyListeners();
      return puantaj;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
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
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      final updatedPuantaj = await _apiService.updatePuantaj(
        puantajId: puantajId,
        baslangicSaati: baslangicSaati,
        bitisSaati: bitisSaati,
        calismaSuresi: calismaSuresi,
        projeId: projeId,
        projeBilgisi: projeBilgisi,
        aciklama: aciklama,
        durum: durum,
      );
      
      // Socket.IO üzerinden bildirim gönder
      _socketService.emitPuantajUpdated(updatedPuantaj);
      
      // Listeyi güncelle
      final index = _allPuantajlar.indexWhere((p) => p.id == puantajId);
      if (index != -1) {
        _allPuantajlar[index] = updatedPuantaj;
        
        // Filtrelenmiş listede de güncelle
        final filteredIndex = _filteredPuantajlar.indexWhere((p) => p.id == puantajId);
        if (filteredIndex != -1) {
          _filteredPuantajlar[filteredIndex] = updatedPuantaj;
        }
      }
      
      _isLoading = false;
      notifyListeners();
      return updatedPuantaj;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }
  
  // Socket.IO ile gelen yeni puantaj'ı işle
  void _handleNewPuantaj(Puantaj puantaj) {
    // Eğer bu puantaj zaten listedeyse, güncelle
    final index = _allPuantajlar.indexWhere((p) => p.id == puantaj.id);
    if (index != -1) {
      _allPuantajlar[index] = puantaj;
    } else {
      // Yoksa ekle
      _allPuantajlar.add(puantaj);
    }
    
    // Filtrelenmiş listeyi güncelle
    _updateFilteredList();
    
    notifyListeners();
  }
  
  // Socket.IO ile gelen puantaj güncellemesini işle
  void _handlePuantajUpdate(Puantaj puantaj) {
    final index = _allPuantajlar.indexWhere((p) => p.id == puantaj.id);
    if (index != -1) {
      _allPuantajlar[index] = puantaj;
      
      // Filtrelenmiş listeyi güncelle
      _updateFilteredList();
      
      notifyListeners();
    }
  }
  
  // Filtrelenmiş listeyi güncelle
  void _updateFilteredList() {
    // Eğer filtre yoksa, tüm listeyi göster
    if (_filteredPuantajlar.length == _allPuantajlar.length) {
      _filteredPuantajlar = List.from(_allPuantajlar);
    } else {
      // Filtre varsa, mevcut filtreyi uygula
      // Not: Burada daha karmaşık bir filtre mantığı gerekebilir
      _filteredPuantajlar = _filteredPuantajlar
          .where((fp) => _allPuantajlar.any((ap) => ap.id == fp.id))
          .toList();
    }
  }
  
  // Puantaj kaydını sil
  Future<void> deletePuantaj(String puantajId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      await _apiService.deletePuantaj(puantajId);
      
      // Listeden kaldır
      _allPuantajlar.removeWhere((p) => p.id == puantajId);
      _filteredPuantajlar.removeWhere((p) => p.id == puantajId);
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }
  
  // Puantajları filtreleme
  void filterPuantajlar(String status, String? projeId) {
    if (status == 'all' && projeId == null) {
      _filteredPuantajlar = List.from(_allPuantajlar);
    } else {
      _filteredPuantajlar = _allPuantajlar.where((puantaj) {
        bool statusMatch = status == 'all' || puantaj.durum == status;
        bool projeMatch = projeId == null || puantaj.projeId == projeId;
        return statusMatch && projeMatch;
      }).toList();
    }
    notifyListeners();
  }
  
  // Puantajları sıralama
  void sortPuantajlar(String field, bool ascending) {
    switch (field) {
      case 'tarih':
        _filteredPuantajlar.sort((a, b) {
          if (a.tarih == null && b.tarih == null) return 0;
          if (a.tarih == null) return ascending ? -1 : 1;
          if (b.tarih == null) return ascending ? 1 : -1;
          return ascending ? a.tarih!.compareTo(b.tarih!) : b.tarih!.compareTo(a.tarih!);
        });
        break;
      case 'calismaSuresi':
        _filteredPuantajlar.sort((a, b) {
          return ascending
              ? a.calismaSuresi.compareTo(b.calismaSuresi)
              : b.calismaSuresi.compareTo(a.calismaSuresi);
        });
        break;
      case 'durum':
        _filteredPuantajlar.sort((a, b) {
          if (a.durum == null && b.durum == null) return 0;
          if (a.durum == null) return ascending ? -1 : 1;
          if (b.durum == null) return ascending ? 1 : -1;
          return ascending ? a.durum!.compareTo(b.durum!) : b.durum!.compareTo(a.durum!);
        });
        break;
      default:
        break;
    }
    notifyListeners();
  }
  
  // Tarihe göre filtreleme
  List<Puantaj> filterByDate(DateTime date) {
    return _allPuantajlar.where((puantaj) {
      if (puantaj.tarih == null) return false;
      return puantaj.tarih!.year == date.year &&
             puantaj.tarih!.month == date.month &&
             puantaj.tarih!.day == date.day;
    }).toList();
  }
  
  // Tarih aralığına göre filtreleme
  List<Puantaj> filterByDateRange(DateTime startDate, DateTime endDate) {
    return _allPuantajlar.where((puantaj) {
      if (puantaj.tarih == null) return false;
      return puantaj.tarih!.isAfter(startDate.subtract(const Duration(days: 1))) &&
             puantaj.tarih!.isBefore(endDate.add(const Duration(days: 1)));
    }).toList();
  }
  
  @override
  void dispose() {
    super.dispose();
  }
} 