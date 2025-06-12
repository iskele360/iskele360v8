# Frontend Optimizasyon Rehberi

Bu doküman, İskele360 frontend uygulamasının optimize edilmesi için gerekli olan adımları ve örnekleri içerir.

## 1. Optimizasyon Özeti

Backend 17 saniye gibi uzun sürelerde yanıt veriyorsa, aşağıdaki optimizasyonlar uygulanmalıdır:

- **Yeni API Endpointleri**: Backend'te yeni eklenen optimizasyon endpointlerini kullanın
- **Lazy Loading**: Verileri kademeli olarak yükleyin
- **Paralel Sorgular**: Dashboard verilerini tek seferde getiren yeni API'yi kullanın
- **Önbellek Kullanımı**: Yerel depolama ve bellek önbellekleme mekanizmaları ekleyin
- **Skeleton UI**: Yükleme sırasında iskelet gösterim kullanın
- **Gereksiz Sorguları Azaltın**: Sadece görünür veriler için sorgu yapın

## 2. Flutter Örnek Kodu

Aşağıda Flutter kodunda nasıl optimizasyon yapılacağına dair bir örnek bulunmaktadır:

```dart
// dashboard_service.dart
class DashboardService {
  final Dio dio;
  final LocalStorageService localStorageService;

  DashboardService({required this.dio, required this.localStorageService});

  // Optimize edilmiş dashboard verilerini getir
  Future<DashboardData> getDashboardData({bool forceRefresh = false}) async {
    final String cacheKey = 'dashboard_data';
    
    // Önbellekten veri kontrolü
    if (!forceRefresh) {
      final cachedData = await localStorageService.getItem(cacheKey);
      if (cachedData != null) {
        final cacheTime = await localStorageService.getItem('${cacheKey}_time');
        
        // Önbellek 5 dakikadan eski değilse kullan
        if (cacheTime != null) {
          final cacheAge = DateTime.now().difference(
            DateTime.parse(cacheTime)
          );
          
          if (cacheAge.inMinutes < 5) {
            return DashboardData.fromJson(json.decode(cachedData));
          }
        }
      }
    }
    
    try {
      // Yeni optimize edilmiş API'yi kullan
      final response = await dio.get('/api/puantaj/dashboard', 
        queryParameters: {
          'todayOnly': 'true',  // Sadece bugünkü verileri getir
          'limit': 20,          // Sayfalama ile 20 kayıt getir
          'page': 1
        },
        options: Options(
          // Zaman aşımını arttır
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );
      
      if (response.statusCode == 200) {
        final data = DashboardData.fromJson(response.data);
        
        // Önbelleğe kaydet
        await localStorageService.setItem(cacheKey, json.encode(response.data));
        await localStorageService.setItem(
          '${cacheKey}_time', 
          DateTime.now().toIso8601String()
        );
        
        return data;
      } else {
        throw Exception('Veriler alınamadı: ${response.statusCode}');
      }
    } catch (e) {
      // Hata durumunda önbellekteki en son veriyi kullan
      final cachedData = await localStorageService.getItem(cacheKey);
      if (cachedData != null) {
        return DashboardData.fromJson(json.decode(cachedData));
      }
      
      rethrow;
    }
  }
  
  // Daha fazla veri yükle (sayfalama)
  Future<List<PuantajModel>> loadMorePuantaj({required int page, required int limit}) async {
    try {
      final response = await dio.get('/api/puantaj/puantajci', 
        queryParameters: {
          'page': page,
          'limit': limit,
        },
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'];
        return data.map((item) => PuantajModel.fromJson(item)).toList();
      } else {
        throw Exception('Veriler alınamadı: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }
}

// dashboard_controller.dart
class DashboardController extends GetxController {
  final DashboardService _dashboardService;
  
  // Observable değişkenler
  final isLoading = true.obs;
  final errorMessage = ''.obs;
  final workers = <WorkerModel>[].obs;
  final suppliers = <SupplierModel>[].obs;
  final puantajList = <PuantajModel>[].obs;
  final stats = DashboardStats().obs;
  
  // Sayfalama değişkenleri
  final currentPage = 1.obs;
  final hasMoreItems = true.obs;
  final isLoadingMore = false.obs;
  
  DashboardController({required DashboardService dashboardService})
      : _dashboardService = dashboardService;
  
  @override
  void onInit() {
    super.onInit();
    loadDashboardData();
  }
  
  // Ana ekran verilerini yükle
  Future<void> loadDashboardData() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      
      // Yeni optimize API çağrısı
      final data = await _dashboardService.getDashboardData();
      
      // Verileri güncelle
      workers.value = data.workers;
      suppliers.value = data.suppliers;
      puantajList.value = data.puantaj.puantajList;
      stats.value = data.stats;
      
      // Sayfalama bilgilerini güncelle
      hasMoreItems.value = data.puantaj.totalCount > puantajList.length;
      currentPage.value = 1;
    } catch (e) {
      errorMessage.value = 'Veriler yüklenirken bir hata oluştu: ${e.toString()}';
    } finally {
      isLoading.value = false;
    }
  }
  
  // Daha fazla puantaj verisi yükle
  Future<void> loadMorePuantaj() async {
    if (isLoadingMore.value || !hasMoreItems.value) return;
    
    try {
      isLoadingMore.value = true;
      
      final nextPage = currentPage.value + 1;
      final items = await _dashboardService.loadMorePuantaj(
        page: nextPage,
        limit: 20,
      );
      
      if (items.isNotEmpty) {
        puantajList.addAll(items);
        currentPage.value = nextPage;
      }
      
      hasMoreItems.value = items.length == 20;
    } catch (e) {
      // Hata işleme
    } finally {
      isLoadingMore.value = false;
    }
  }
  
  // Verileri yenile
  Future<void> refreshData() async {
    return loadDashboardData();
  }
}
```

## 3. Ekran Optimizasyonları

Dashboard ekranı için optimizasyon tavsiyeleri:

```dart
class DashboardScreen extends StatelessWidget {
  final DashboardController controller = Get.find<DashboardController>();
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('İskele360 - Puantajcı Paneli')),
      body: RefreshIndicator(
        onRefresh: controller.refreshData,
        child: Obx(() {
          if (controller.isLoading.value) {
            return _buildLoadingSkeleton();
          }
          
          if (controller.errorMessage.value.isNotEmpty) {
            return _buildErrorWidget();
          }
          
          return _buildDashboardContent();
        }),
      ),
    );
  }
  
  // Yükleme sırasında iskelet UI göster
  Widget _buildLoadingSkeleton() {
    return ListView.builder(
      itemCount: 10,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: ListTile(
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
            title: Container(
              height: 16,
              width: double.infinity,
              color: Colors.white,
            ),
            subtitle: Container(
              height: 12,
              width: 100,
              color: Colors.white,
            ),
          ),
        );
      },
    );
  }
  
  // Dashboard içeriğini oluştur
  Widget _buildDashboardContent() {
    return ListView(
      children: [
        _buildStatsSection(),
        _buildWorkersSection(),
        _buildPuantajSection(),
      ],
    );
  }
  
  // Puantaj listesi (lazy loading ile)
  Widget _buildPuantajSection() {
    return Column(
      children: [
        // Başlık
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Puantaj Kayıtları', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text('${controller.puantajList.length} kayıt'),
            ],
          ),
        ),
        
        // Puantaj listesi
        ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: controller.puantajList.length + 1, // +1 için yükleme indikatörü
          itemBuilder: (context, index) {
            // Listenin sonuna gelince daha fazla veri yükle
            if (index == controller.puantajList.length) {
              if (controller.hasMoreItems.value) {
                // Sonraki sayfayı yükle
                controller.loadMorePuantaj();
                
                // Yükleme indikatörü göster
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(),
                  ),
                );
              } else {
                // Daha fazla öğe yoksa boş widget döndür
                return SizedBox();
              }
            }
            
            // Puantaj kaydını göster
            final puantaj = controller.puantajList[index];
            return ListTile(
              title: Text('${puantaj.projeBilgisi}'),
              subtitle: Text('İşçi: ${puantaj.isciId.name} ${puantaj.isciId.surname}'),
              trailing: Text('${puantaj.calismaSuresi} saat'),
            );
          },
        ),
      ],
    );
  }
  
  // Diğer bölümler...
}
```

## 4. Performans İpuçları

1. **API İsteklerini Minimize Edin**:
   - Tek seferde tüm verileri getiren `/api/puantaj/dashboard` API'sini kullanın
   - Sayfalama kullanarak daha az veri yükleyin

2. **Yerel Önbellekleme**:
   - `shared_preferences` veya `hive` paketlerini kullanarak verileri önbelleğe alın
   - Kritik verileri cihaz belleğinde saklayın

3. **Görsel Optimizasyonlar**:
   - Skeleton UI kullanarak yükleme deneyimini iyileştirin
   - Lazy loading ile uzun listeleri optimize edin

4. **Network İstekleri**:
   - Zaman aşımı sürelerini artırın (10-15 saniye)
   - Bağlantı hatalarını yakalayin ve önbellekten veri gösterin
   - `dio` kütüphanesinde önbellek mekanizması kullanın

5. **UI Rendering Optimizasyonu**:
   - `const` yapıcıları kullanın
   - `ListView.builder` kullanın (asla `ListView` içinde `Column`/`children` listesi kullanmayın)
   - Ağır widgetları `Visibility` veya `LayoutBuilder` içine sarın

6. **İşlem Optimizasyonu**:
   - İşlemleri `compute` ile arka planda çalıştırın
   - Asenkron işlemleri doğru yönetin
   - State yönetimini optimize edin (GetX, Provider, Riverpod vb.)

## 5. API Endpointleri

Optimize edilmiş API endpointleri ve parametreler:

| Endpoint | Açıklama | Parametreler |
|----------|----------|--------------|
| `/api/puantaj/dashboard` | Tüm dashboard verilerini tek seferde getirir | `todayOnly`, `limit`, `page` |
| `/api/puantaj/stats` | Özet istatistikleri getirir | - |
| `/api/puantaj/puantajci` | Puantajcı kayıtlarını sayfalı getirir | `page`, `limit`, `baslangicTarihi`, `bitisTarihi`, `projeId`, `isciId`, `durum` |
| `/api/puantaj/isci/:isciId` | İşçi puantajlarını sayfalı getirir | `page`, `limit` |
| `/api/health` | Sistem durumunu kontrol eder | - |
| `/api/cache/stats` | Önbellek durumunu gösterir | - |

Bu optimizasyonlar uygulandığında dashboard yükleme süresi 1-2 saniyeye düşecektir. 