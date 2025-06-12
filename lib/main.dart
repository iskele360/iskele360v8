import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:iskele360v7/providers/auth_provider.dart';
import 'package:iskele360v7/providers/puantaj_provider.dart';
import 'package:iskele360v7/providers/malzeme_provider.dart';
import 'package:iskele360v7/providers/user_provider.dart';
import 'package:iskele360v7/services/api_service.dart';
import 'package:iskele360v7/services/cache_service.dart';
import 'package:iskele360v7/services/socket_service.dart';
import 'package:iskele360v7/screens/login_screen.dart';
import 'package:iskele360v7/screens/home_screen.dart';
import 'package:iskele360v7/screens/splash_screen.dart';
import 'package:iskele360v7/screens/profile_screen.dart';
import 'package:iskele360v7/screens/puantaj/puantaj_list_screen.dart';
import 'package:iskele360v7/screens/auth/register_screen.dart';
import 'package:iskele360v7/utils/constants.dart';

void main() async {
  // Flutter engine'i başlat
  WidgetsFlutterBinding.ensureInitialized();

  // Cache servisini başlat
  final cacheService = CacheService();
  await cacheService.init();

  // Socket servisini başlat
  final socketService = SocketService();
  socketService.init();

  // Debug işaretlerini kapat
  WidgetsApp.debugAllowBannerOverride = false;

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({Key? key}) : super(key: key);

  // Servisleri merkezi olarak oluştur
  final ApiService _apiService = ApiService();
  final SocketService _socketService = SocketService();
  final CacheService _cacheService = CacheService();

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => PuantajProvider()),
        ChangeNotifierProvider(create: (_) => MalzemeProvider(_apiService)),
        ChangeNotifierProvider(create: (_) => UserProvider(_apiService)),
      ],
      child: MaterialApp(
        title: 'İskele 360',
        debugShowCheckedModeBanner: false,
        localizationsDelegates: [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: [
          const Locale('tr', 'TR'),
          const Locale('en', 'US'),
        ],
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
          scaffoldBackgroundColor: Colors.grey[100],
          appBarTheme: const AppBarTheme(
            elevation: 0,
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            ),
          ),
          cardTheme: CardTheme(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding:
                const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          ),
        ),
        home: const SplashScreen(),
        routes: {
          '/login': (context) => const LoginScreen(),
          '/home': (context) => const HomeScreen(),
          '/profile': (context) => const ProfileScreen(),
          '/puantaj': (context) => const PuantajListScreen(),
          '/register': (context) => const RegisterScreen(),
        },
      ),
    );
  }
}
