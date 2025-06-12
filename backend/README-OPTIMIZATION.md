# İskele360 Backend Optimizasyon Rehberi

Bu doküman, İskele360 uygulamasının backend tarafındaki optimizasyon çalışmalarını ve MongoDB Atlas için önerilen yapılandırmaları içerir.

## Performans İyileştirmeleri

### 1. Eklenen Özellikler

- **Paralel Sorgular**: Birden fazla DB sorgusunu eşzamanlı çalıştırarak yanıt süresini azalttık
- **Önbellek Mekanizması**: Sık sorgulanan verileri in-memory cache ile önbellekledik
- **Sayfalama**: Tüm listeleme endpoint'leri için sayfalama ekledik (limit=20)
- **Filtreleme**: Tarih, işçi, proje ve durum bazlı filtreleme özellikleri ekledik
- **MongoDB İndeksleri**: Sorgu performansı için kritik alanlara compound index'ler ekledik
- **Tarih Filtreleme**: Varsayılan olarak sadece bugünkü verileri getiriyoruz
- **Aggregation Pipeline**: İstatistikler için optimize edilmiş pipeline'lar ekledik
- **Performans İzleme**: Yavaş sorguları otomatik olarak loglama sistemi ekledik
- **Bağlantı Havuzu**: MongoDB bağlantı havuzunu optimize ettik
- **Sistem Durumu Endpoint'i**: `/api/health` endpoint'i ile sistem durumunu izleme imkanı ekledik

### 2. MongoDB Atlas İndeks Önerileri

MongoDB Atlas'ta aşağıdaki indekslerin oluşturulması performansı artıracaktır:

```js
// 1. Puantaj kayıtlarını işçi ve tarih bazında indeksle
db.puantaj.createIndex({ isciId: 1, tarih: -1 });

// 2. Puantaj kayıtlarını puantajcı ve tarih bazında indeksle
db.puantaj.createIndex({ puantajciId: 1, tarih: -1 });

// 3. Compound indeks: Puantajcı + İşçi + Tarih
db.puantaj.createIndex({ puantajciId: 1, isciId: 1, tarih: -1 });

// 4. Proje bazlı sorgular için indeks
db.puantaj.createIndex({ puantajciId: 1, projeId: 1, tarih: -1 });

// 5. Durum bazlı sorgular için indeks
db.puantaj.createIndex({ puantajciId: 1, durum: 1, tarih: -1 });

// 6. Aggregation sorgularını hızlandıracak indeks
db.puantaj.createIndex({ puantajciId: 1, tarih: 1, calismaSuresi: 1 });

// 7. Arama işlemleri için text indeksi
db.puantaj.createIndex(
  { projeBilgisi: "text", aciklama: "text" },
  { 
    weights: { 
      projeBilgisi: 10, 
      aciklama: 5 
    },
    name: "text_index" 
  }
);
```

### 3. MongoDB Atlas Cluster Önerileri

Atlas cluster'ınız için aşağıdaki ayarları yapmanız önerilir:

- **Cluster Tier**: M10 veya üzeri (yüksek trafikte M20)
- **Disk Type**: SSD
- **Cluster Config**: 3 node replica set
- **Region**: Kullanıcılarınıza en yakın bölge (örn. eu-central)
- **Backup**: Daily backup + oplog (7 gün)
- **MongoDB Version**: 5.0 veya üzeri
- **Sharding**: Veri büyükse puantajciId'ye göre sharding yapılandırılabilir

## API Performans Optimizasyonları

### Yeni Endpoint'ler

1. **Dashboard API**
   - `GET /api/puantaj/dashboard`
   - Tüm dashboard verilerini tek seferde, parallel olarak getirir
   - Query parametreleri: `page`, `limit`, `todayOnly`, `noCache`

2. **İstatistik API**
   - `GET /api/puantaj/stats`
   - Özet istatistikleri aggregation pipeline ile hesaplar

### Optimize Edilmiş Endpoint'ler

1. **İşçi Puantaj Listesi**
   - `GET /api/puantaj/isci/:isciId`
   - Sayfalama eklendi: `page` ve `limit` parametreleri

2. **Puantajcı Puantaj Listesi**
   - `GET /api/puantaj/puantajci`
   - Sayfalama ve filtreleme eklendi
   - Filtre parametreleri: `baslangicTarihi`, `bitisTarihi`, `projeId`, `isciId`, `durum`

## Sistem Gereksinimleri

Optimum performans için:

- **Node.js**: v18 veya üzeri
- **RAM**: En az 2GB
- **CPU**: 2 çekirdek veya üzeri
- **Network**: Düşük latency
- **MongoDB Atlas**: M10 veya üzeri tier

## Kullanım Kılavuzu

### Frontend Entegrasyonu

Frontend tarafında aşağıdaki değişiklikleri yapmanız gerekebilir:

1. Dashboard verilerini tek API çağrısı ile alacak şekilde güncelleme:

```dart
// Eski yaklaşım (çoklu API çağrısı)
Future<void> loadDashboardData() async {
  await loadWorkers();
  await loadSuppliers();
  await loadPuantaj();
}

// Yeni yaklaşım (tek API çağrısı)
Future<void> loadDashboardData() async {
  final response = await dio.get('/api/puantaj/dashboard', queryParameters: {
    'todayOnly': 'true',
    'page': 1,
    'limit': 20
  });
  
  // Tek seferde tüm verileri al
  final data = response.data;
  workers = data['workers'];
  suppliers = data['suppliers'];
  puantaj = data['puantaj']['puantajList'];
  stats = data['stats'];
}
```

2. Sayfalama için kullanım:

```dart
// Sayfalı puantaj verileri için
Future<void> loadMorePuantaj(int page) async {
  final response = await dio.get('/api/puantaj/puantajci', queryParameters: {
    'page': page,
    'limit': 20,
    'baslangicTarihi': '2023-06-01',
    'bitisTarihi': '2023-06-30',
    'isciId': selectedWorkerId // Opsiyonel filtre
  });
  
  final newItems = response.data['data'];
  puantaj.addAll(newItems);
  
  hasMorePuantaj = response.data['pagination']['hasNextPage'];
}
```

## Bakım ve İzleme

Uygulamanın performansını düzenli olarak izlemek için:

1. `/api/health` endpoint'ini düzenli kontrol edin
2. MongoDB Atlas Dashboard'dan indeks kullanım istatistiklerini takip edin
3. Yavaş sorgu loglarını analiz edin
4. Belirli aralıklarla önbelleği temizleyin (özellikle deployment sonrası)

## Troubleshooting

Performans sorunları devam ederse:

1. MongoDB Profiler'ı aktifleştirin
2. `explain()` ile sorgu planlarını analiz edin
3. Önbellek süresini ve kapsamını genişletin
4. Connection pool boyutunu artırın
5. MongoDB Atlas tier'ını yükseltin

---

Bu optimizasyonlar ile ana ekran yükleme süresi 1-2 saniyenin altına düşecektir. 