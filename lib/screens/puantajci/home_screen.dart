import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';
import '../auth/login_screen.dart';

class PuantajciHomeScreen extends StatelessWidget {
  const PuantajciHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Puantajcı Paneli'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authService.logout();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Hoş Geldiniz',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'İşçi yönetimi ve puantaj işlemlerini buradan yapabilirsiniz.',
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              // TODO: İşçi ekleme sayfasına yönlendir
                            },
                            icon: const Icon(Icons.person_add),
                            label: const Text('İşçi Ekle'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hızlı İşlemler',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),
                    ListTile(
                      leading: Icon(Icons.assignment),
                      title: Text('Günlük Puantaj'),
                      subtitle: Text('Günlük işçi devam durumu girişi'),
                    ),
                    ListTile(
                      leading: Icon(Icons.people),
                      title: Text('İşçi Listesi'),
                      subtitle: Text('Tüm işçileri görüntüle ve yönet'),
                    ),
                    ListTile(
                      leading: Icon(Icons.summarize),
                      title: Text('Raporlar'),
                      subtitle: Text('Puantaj raporları ve istatistikler'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
