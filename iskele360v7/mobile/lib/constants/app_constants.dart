class AppConstants {
  static const String apiBaseUrl = 'https://iskele360-backend-v8.onrender.com/api';
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';

  // API Endpoints
  static const String loginEndpoint = '/auth/login';
  static const String registerEndpoint = '/auth/register';
  static const String profileEndpoint = '/users/profile';

  // Validation Rules
  static const int passwordMinLength = 6;
  static const int tcNoLength = 11;
  static const int phoneMinLength = 10;

  // Error Messages
  static const String networkError = 'İnternet bağlantınızı kontrol edin';
  static const String serverError = 'Sunucu hatası oluştu';
  static const String unauthorizedError = 'Oturum süreniz doldu';
  static const String validationError = 'Lütfen tüm alanları kontrol edin';

  // Success Messages
  static const String loginSuccess = 'Giriş başarılı';
  static const String registerSuccess = 'Kayıt başarılı';
  static const String logoutSuccess = 'Çıkış yapıldı';
  static const String updateSuccess = 'Güncelleme başarılı';

  // Role Types
  static const String roleAdmin = 'admin';
  static const String rolePuantajci = 'puantajci';
} 