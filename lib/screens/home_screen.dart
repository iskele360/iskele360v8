import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iskele360v7/providers/auth_provider.dart';
import 'package:iskele360v7/utils/constants.dart';
import 'package:iskele360v7/widgets/supervisor_home.dart';
import 'package:iskele360v7/widgets/worker_home.dart';
import 'package:iskele360v7/widgets/supplier_home.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    if (user == null) {
      // Kullanıcı bilgisi alınamadıysa login ekranına yönlendir
      Future.microtask(() => Navigator.pushReplacementNamed(context, '/login'));
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Kullanıcı rolüne göre uygun ana ekranı göster
    return Scaffold(
      appBar: AppBar(
        title: Text('${AppConstants.appName} - ${_getRoleTitle(user.role)}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.pushNamed(context, '/profile');
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              _showLogoutDialog(context);
            },
          ),
        ],
      ),
      body: _buildHomeContent(user.role),
      drawer: _buildDrawer(context, user.role),
    );
  }

  String _getRoleTitle(String role) {
    switch (role) {
      case 'supervisor':
        return 'Puantajcı';
      case 'isci':
        return 'İşçi';
      case 'supplier':
        return 'Malzemeci';
      default:
        return 'Kullanıcı';
    }
  }

  Widget _buildHomeContent(String role) {
    switch (role) {
      case 'supervisor':
        return const SupervisorHome();
      case 'isci':
        return const WorkerHome();
      case 'supplier':
        return const SupplierHome();
      default:
        return const Center(
          child: Text('Rolünüz için uygun bir ekran bulunamadı.'),
        );
    }
  }

  Widget _buildDrawer(BuildContext context, String role) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.blue,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.business,
                  size: 60,
                  color: Colors.white,
                ),
                const SizedBox(height: 8),
                Text(
                  AppConstants.appName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _getRoleTitle(role),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          // Tüm roller için ortak menü öğeleri
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Ana Sayfa'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Profil'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/profile');
            },
          ),
          const Divider(),
          // Role özel menü öğeleri
          if (role == 'supervisor') ...[
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text('İşçi Yönetimi'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/workers');
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('Puantaj Yönetimi'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/puantaj');
              },
            ),
            ListTile(
              leading: const Icon(Icons.inventory),
              title: const Text('Malzemeci Yönetimi'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/suppliers');
              },
            ),
          ],
          if (role == 'isci') ...[
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('Puantajlarım'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/worker-puantaj');
              },
            ),
            ListTile(
              leading: const Icon(Icons.inventory),
              title: const Text('Zimmetlerim'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/worker-zimmet');
              },
            ),
          ],
          if (role == 'supplier') ...[
            ListTile(
              leading: const Icon(Icons.category),
              title: const Text('Malzeme Yönetimi'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/malzeme');
              },
            ),
            ListTile(
              leading: const Icon(Icons.assignment),
              title: const Text('Zimmet Yönetimi'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/zimmet');
              },
            ),
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text('İşçi Listesi'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/supplier-workers');
              },
            ),
          ],
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Çıkış Yap'),
            onTap: () {
              Navigator.pop(context);
              _showLogoutDialog(context);
            },
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Çıkış Yap'),
        content: const Text('Hesabınızdan çıkış yapmak istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Provider.of<AuthProvider>(context, listen: false).logout();
              Navigator.pushReplacementNamed(context, '/login');
            },
            child: const Text('Çıkış Yap'),
          ),
        ],
      ),
    );
  }
} 