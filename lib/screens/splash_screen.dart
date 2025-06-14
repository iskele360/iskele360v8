import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iskele360v7/providers/auth_provider.dart';
import 'package:iskele360v7/utils/constants.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late Timer _timer;
  
  @override
  void initState() {
    super.initState();
    
    _timer = Timer(const Duration(seconds: 2), () {
      _checkAuth();
    });
  }
  
  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }
  
  Future<void> _checkAuth() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    // Otomatik giriş kontrol et
    if (authProvider.isAuthenticated) {
      // Role göre uygun ekrana yönlendir
      _navigateBasedOnRole(authProvider.userRole);
    } else {
      // Giriş ekranına yönlendir
      Navigator.pushReplacementNamed(context, '/login');
    }
  }
  
  void _navigateBasedOnRole(String? role) {
    if (role == AppConstants.rolePuantajci) {
      // Puantajcı ana ekranına yönlendir
      Navigator.pushReplacementNamed(context, '/home');
    } else if (role == AppConstants.roleWorker) {
      // İşçi ana ekranına yönlendir
      Navigator.pushReplacementNamed(context, '/home');
    } else if (role == AppConstants.roleSupplier) {
      // Malzemeci ana ekranına yönlendir
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      // Rol tanımlanmamış, giriş ekranına yönlendir
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
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
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(60),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.business,
                  size: 80,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 24),
              
              // Uygulama adı
              const Text(
                AppConstants.appName,
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
              const SizedBox(height: 48),
              
              // Yükleniyor animasyonu
              const CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 3,
              ),
              const SizedBox(height: 24),
              const Text(
                'Yükleniyor...',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 