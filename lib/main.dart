import 'package:flutter/material.dart';
import 'package:iskele360v7/screens/auth/login_screen.dart';
import 'package:iskele360v7/screens/auth/worker_login_screen.dart';
import 'package:iskele360v7/screens/auth/supplier_login_screen.dart';
import 'package:iskele360v7/screens/dashboard_screen.dart';
import 'package:iskele360v7/screens/supplier/supplier_home_screen.dart';
import 'package:iskele360v7/screens/worker/worker_home_screen.dart';
import 'package:iskele360v7/services/api_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'İskele 360',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
        textTheme: const TextTheme(
          bodyMedium: TextStyle(overflow: TextOverflow.ellipsis),
          titleMedium: TextStyle(overflow: TextOverflow.ellipsis),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            visualDensity: VisualDensity.compact,
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            visualDensity: VisualDensity.compact,
          ),
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const HomeScreen(),
        '/login': (context) => const LoginScreen(),
        '/worker_login': (context) => const WorkerLoginScreen(),
        '/supplier_login': (context) => const SupplierLoginScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/worker_home': (context) => const WorkerHomeScreen(),
        '/supplier_home': (context) => const SupplierHomeScreen(),
        '/home': (context) => const HomeScreen(),
      },
      onUnknownRoute: (settings) {
        return MaterialPageRoute(
          builder: (context) => const HomeScreen(),
        );
      },
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  bool _isLoggedIn = false;
  String? _userRole;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Önce kullanıcının giriş yapmış olup olmadığını kontrol et
      final isLoggedIn = await _apiService.isLoggedIn();
      
      if (isLoggedIn) {
        // Kullanıcı verilerini al
        final userData = await _apiService.getUserData();
        
        if (userData != null) {
          final role = userData['role'] as String?;
          setState(() {
            _isLoggedIn = true;
            _userRole = role;
          });
          
          print('Kullanıcı giriş yapmış. Rol: $_userRole');
          
          // Kullanıcı rolüne göre ilgili sayfaya yönlendir
          // ignore: use_build_context_synchronously
          if (role == 'supervisor') {
            Navigator.pushReplacementNamed(context, '/dashboard');
          } else if (role == 'worker') {
            Navigator.pushReplacementNamed(context, '/worker_home');
          } else if (role == 'supplier') {
            Navigator.pushReplacementNamed(context, '/supplier_home');
          }
        } else {
          print('Kullanıcı verileri bulunamadı, oturum kapalı sayılıyor');
          setState(() {
            _isLoggedIn = false;
          });
        }
      } else {
        print('Kullanıcı giriş yapmamış');
        setState(() {
          _isLoggedIn = false;
        });
      }
    } catch (e) {
      print('Oturum kontrolü hatası: $e');
      setState(() {
        _isLoggedIn = false;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _isLoggedIn
              ? Center(child: Text('Yönlendiriliyor... Role: $_userRole'))
              : Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.blue.shade700,
                        Colors.blue.shade900,
                      ],
                    ),
                  ),
                  child: SafeArea(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Spacer(),
                        // Logo
                        const Icon(
                          Icons.business,
                          size: 80,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 24),
                        // Uygulama adı
                        const Text(
                          'İSKELE 360',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'İş Yönetim Sistemi',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white70,
                          ),
                        ),
                        const Spacer(),
                        
                        // Giriş butonları
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(30),
                              topRight: Radius.circular(30),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Text(
                                'Hesabınıza Giriş Yapın',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 24),
                              
                              // Puantajcı Girişi
                              ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.pushNamed(context, '/login');
                                },
                                icon: const Icon(Icons.admin_panel_settings),
                                label: const Text('Puantajcı Girişi'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  textStyle: const TextStyle(fontSize: 16),
                                ),
                              ),
                              
                              const SizedBox(height: 16),
                              
                              // İşçi Girişi
                              OutlinedButton.icon(
                                onPressed: () {
                                  Navigator.pushNamed(context, '/worker_login');
                                },
                                icon: const Icon(Icons.person),
                                label: const Text('İşçi Girişi'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.blue,
                                  side: const BorderSide(color: Colors.blue),
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  textStyle: const TextStyle(fontSize: 16),
                                ),
                              ),
                              
                              const SizedBox(height: 16),
                              
                              // Malzemeci Girişi
                              OutlinedButton.icon(
                                onPressed: () {
                                  Navigator.pushNamed(context, '/supplier_login');
                                },
                                icon: const Icon(Icons.inventory),
                                label: const Text('Malzemeci Girişi'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.orange,
                                  side: const BorderSide(color: Colors.orange),
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  textStyle: const TextStyle(fontSize: 16),
                                ),
                              ),
                              
                              const SizedBox(height: 16),
                              
                              // Uygulama bilgisi
                              const Text(
                                'v1.0.0 - İSKELE360 Tüm Hakları Saklıdır',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }
} 