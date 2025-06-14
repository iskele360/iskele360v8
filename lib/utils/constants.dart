class AppConstants {
  // Mock API kullanımı (Cloud API aktif olduğunda false olarak ayarlayın)
  static const bool useMockApi = false;

  // API Base URL
  static const String _realApiBaseUrl =
      'https://iskele360v8-2.onrender.com';
  static const String _mockApiBaseUrl =
      'http://10.0.2.2:3000'; // Emülatör için localhost
  static const String _firebaseApiBaseUrl =
      'http://127.0.0.1:5001/iskele360v7-7d5d6/us-central1';

  // WebSocket URL
  static const String _realSocketUrl = 'wss://iskele360v8-2.onrender.com';
  static const String _mockSocketUrl = 'ws://10.0.2.2:3000';
  static const String _firebaseSocketUrl = 'ws://127.0.0.1:5001';

  // Redis URL
  static const String _realRedisUrl = 'redis://iskele360v8-2.onrender.com';
  static const String _mockRedisUrl = 'redis://10.0.2.2';
  static const int redisPort = 6379;

  // Firebase API kullanımı
  static const bool useFirebaseApi = false;

  // Aktif URL'ler
  static String get apiBaseUrl => useFirebaseApi
      ? _firebaseApiBaseUrl
      : (useMockApi ? _mockApiBaseUrl : _realApiBaseUrl);

  static String get socketUrl => useFirebaseApi
      ? _firebaseSocketUrl
      : (useMockApi ? _mockSocketUrl : _realSocketUrl);

  static String get redisUrl => useMockApi ? _mockRedisUrl : _realRedisUrl;

  // API Endpoints
  static const String loginEndpoint = '/api/auth/login';
  static const String loginWithCodeEndpoint = '/api/auth/login-with-code';
  static const String registerEndpoint = '/api/auth/register';
  static const String profileEndpoint = '/api/users/profile';

  // Kullanıcı Rolleri
  static const String roleAdmin = 'admin'; // Admin
  static const String rolePuantajci = 'supervisor'; // Puantajcı
  static const String roleWorker = 'worker'; // İşçi
  static const String roleSupplier = 'supplier'; // Tedarikçi

  // Puantaj Durumları
  static const String puantajStatusTamamlandi = 'completed';
  static const String puantajStatusDevamEdiyor = 'pending';
  static const String puantajStatusIptal = 'cancelled';

  // Socket Events
  static const String eventNewPuantaj = 'new_puantaj';
  static const String eventUpdatePuantaj = 'update_puantaj';
  static const String eventNewZimmet = 'new_zimmet';
  static const String eventUpdateZimmet = 'update_zimmet';
  static const String socketEventPuantajCreated = 'puantaj_created';
  static const String socketEventPuantajUpdated = 'puantaj_updated';
  static const String socketEventZimmetCreated = 'zimmet_created';

  // Uygulama Sabitleri
  static const String appName = 'İSKELE 360';
  static const String appVersion = '1.0.0';

  // Hata Mesajları
  static const String errorConnection =
      'Bağlantı hatası! Lütfen internet bağlantınızı kontrol edin.';
  static const String errorUnauthorized =
      'Yetkisiz erişim! Lütfen tekrar giriş yapın.';
  static const String errorServer =
      'Sunucu hatası! Lütfen daha sonra tekrar deneyin.';

  // Başarı Mesajları
  static const String successLogin = 'Giriş başarılı!';
  static const String successLogout = 'Çıkış başarılı!';
  static const String successCreate = 'Kayıt başarıyla oluşturuldu!';
  static const String successUpdate = 'Kayıt başarıyla güncellendi!';
  static const String successDelete = 'Kayıt başarıyla silindi!';

  // Secure Storage Keys
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';
}
