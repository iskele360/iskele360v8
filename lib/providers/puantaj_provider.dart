import 'package:flutter/foundation.dart';
import 'package:iskele360v7/models/puantaj_model.dart';
import 'package:iskele360v7/services/api_service.dart';
import 'package:iskele360v7/utils/constants.dart';

class PuantajProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<Puantaj> _puantajlar = [];
  bool _isLoading = false;
  String? _error;
  String _sortField = 'tarih';
  bool _sortAscending = false;

  List<Puantaj> get puantajlar => _puantajlar;
  List<Puantaj> get puantajList => _puantajlar;
  List<Puantaj> get allPuantajlar => _puantajlar;
  List<Puantaj> get filteredPuantajlar => _puantajlar;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadPuantajciPuantajlari() async {
    await fetchPuantajlar();
  }

  Future<void> loadIsciPuantajlari(String workerId) async {
    await fetchIsciPuantajlari(workerId);
  }

  Future<void> getPuantajList() async {
    await fetchPuantajlar();
  }

  Future<void> getPuantajByWorkerId(String workerId) async {
    await fetchIsciPuantajlari(workerId);
  }

  Future<void> fetchPuantajlar() async {
    try {
      _setLoading(true);
      _puantajlar = await _apiService.getPuantajciPuantajlari();
      _setError(null);
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchIsciPuantajlari(String workerId) async {
    try {
      _setLoading(true);
      _puantajlar = await _apiService.getIsciPuantajlari(workerId);
      _setError(null);
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  void sortPuantajlar(String field, [bool ascending = true]) {
    _sortField = field;
    _sortAscending = ascending;

    _puantajlar.sort((a, b) {
      var aValue = _getSortValue(a, field);
      var bValue = _getSortValue(b, field);

      if (aValue == null || bValue == null) return 0;

      var comparison = 0;
      if (aValue is String && bValue is String) {
        comparison = aValue.compareTo(bValue);
      } else if (aValue is DateTime && bValue is DateTime) {
        comparison = aValue.compareTo(bValue);
      } else if (aValue is num && bValue is num) {
        comparison = aValue.compareTo(bValue);
      }

      return ascending ? comparison : -comparison;
    });

    notifyListeners();
  }

  dynamic _getSortValue(Puantaj puantaj, String field) {
    switch (field) {
      case 'tarih':
        return puantaj.tarih;
      case 'calismaSuresi':
        return puantaj.calismaSuresi;
      case 'baslangicSaati':
        return puantaj.baslangicSaati;
      case 'bitisSaati':
        return puantaj.bitisSaati;
      case 'durum':
        return puantaj.durum;
      default:
        return null;
    }
  }

  Future<void> createPuantaj({
    required String isciId,
    required DateTime baslangicSaati,
    required DateTime bitisSaati,
    required double calismaSuresi,
    required String projeId,
    required String projeBilgisi,
    String? aciklama,
    required DateTime tarih,
  }) async {
    try {
      _setLoading(true);
      final data = {
        'isciId': isciId,
        'baslangicSaati': baslangicSaati.toIso8601String(),
        'bitisSaati': bitisSaati.toIso8601String(),
        'calismaSuresi': calismaSuresi,
        'projeId': projeId,
        'projeBilgisi': projeBilgisi,
        'aciklama': aciklama,
        'durum': AppConstants.puantajStatusDevamEdiyor,
        'tarih': tarih.toIso8601String(),
      };

      final puantaj = await _apiService.createPuantaj(data);
      _puantajlar.add(puantaj);
      notifyListeners();
      _setError(null);
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updatePuantaj({
    required String id,
    required DateTime baslangicSaati,
    required DateTime bitisSaati,
    required double calismaSuresi,
    required String projeId,
    required String projeBilgisi,
    String? aciklama,
    required String durum,
  }) async {
    try {
      _setLoading(true);
      final data = {
        'baslangicSaati': baslangicSaati.toIso8601String(),
        'bitisSaati': bitisSaati.toIso8601String(),
        'calismaSuresi': calismaSuresi,
        'projeId': projeId,
        'projeBilgisi': projeBilgisi,
        'aciklama': aciklama,
        'durum': durum,
      };

      final updatedPuantaj = await _apiService.updatePuantaj(id, data);
      final index = _puantajlar.indexWhere((p) => p.id == id);
      if (index != -1) {
        _puantajlar[index] = updatedPuantaj;
        notifyListeners();
      }
      _setError(null);
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deletePuantaj(String id) async {
    try {
      _setLoading(true);
      await _apiService.deletePuantaj(id);
      _puantajlar.removeWhere((p) => p.id == id);
      notifyListeners();
      _setError(null);
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? value) {
    _error = value;
    notifyListeners();
  }

  List<Puantaj> filterPuantajlar(String status) {
    return _puantajlar.where((p) => p.durum == status).toList();
  }

  double getTotalHours(String status) {
    return _puantajlar
        .where((p) => p.durum == status)
        .fold(0, (sum, p) => sum + p.calismaSuresi);
  }

  int getPuantajCount(String status) {
    return _puantajlar.where((p) => p.durum == status).length;
  }
}
