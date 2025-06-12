import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iskele360v7/providers/auth_provider.dart';
import 'package:iskele360v7/providers/puantaj_provider.dart';
import 'package:iskele360v7/providers/user_provider.dart';

class SupervisorHome extends StatefulWidget {
  const SupervisorHome({Key? key}) : super(key: key);

  @override
  State<SupervisorHome> createState() => _SupervisorHomeState();
}

class _SupervisorHomeState extends State<SupervisorHome> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // İşçi ve malzemeci listelerini yükle
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      await userProvider.getWorkers();
      await userProvider.getSuppliers();

      // Puantaj verilerini yükle
      final puantajProvider =
          Provider.of<PuantajProvider>(context, listen: false);
      await puantajProvider.getPuantajList();
    } catch (e) {
      // Hata göster
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Veriler yüklenirken hata oluştu: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userProvider = Provider.of<UserProvider>(context);
    final puantajProvider = Provider.of<PuantajProvider>(context);

    final user = authProvider.currentUser;

    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Karşılama kartı
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.blue.shade700,
                          radius: 24,
                          child: Text(
                            user?.firstName.substring(0, 1) ?? 'P',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Hoş Geldiniz, ${user?.fullName}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Puantajcı Paneli',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // İstatistikler
            const Text(
              'Özet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildStatCard(
                  title: 'İşçi Sayısı',
                  value: userProvider.workers.length.toString(),
                  icon: Icons.people,
                  color: Colors.blue,
                ),
                const SizedBox(width: 16),
                _buildStatCard(
                  title: 'Puantaj Sayısı',
                  value: puantajProvider.puantajList.length.toString(),
                  icon: Icons.calendar_today,
                  color: Colors.green,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildStatCard(
                  title: 'Malzemeci Sayısı',
                  value: userProvider.suppliers.length.toString(),
                  icon: Icons.inventory,
                  color: Colors.orange,
                ),
                const SizedBox(width: 16),
                _buildStatCard(
                  title: 'Bugünkü Puantajlar',
                  value: _getTodayPuantajCount(puantajProvider).toString(),
                  icon: Icons.today,
                  color: Colors.purple,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Hızlı Erişim
            const Text(
              'Hızlı Erişim',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            _buildActionButton(
              label: 'Yeni İşçi Oluştur',
              icon: Icons.person_add,
              color: Colors.blue.shade700,
              onTap: () {
                _showCreateWorkerDialog(context);
              },
            ),

            _buildActionButton(
              label: 'Yeni Puantaj Oluştur',
              icon: Icons.add_chart,
              color: Colors.green.shade600,
              onTap: () {
                Navigator.pushNamed(context, '/puantaj-create');
              },
            ),

            _buildActionButton(
              label: 'Yeni Malzemeci Oluştur',
              icon: Icons.person_add_alt_1,
              color: Colors.orange.shade700,
              onTap: () {
                _showCreateSupplierDialog(context);
              },
            ),

            const SizedBox(height: 24),

            // Son puantajlar
            const Text(
              'Son Puantajlar',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            _buildRecentPuantajList(puantajProvider),
          ],
        ),
      ),
    );
  }

  // Bugünkü puantaj sayısını hesapla
  int _getTodayPuantajCount(PuantajProvider provider) {
    final today = DateTime.now();
    return provider.puantajList
        .where((p) =>
            p.date.year == today.year &&
            p.date.month == today.month &&
            p.date.day == today.day)
        .length;
  }

  // İstatistik kartı
  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: color, size: 24),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Hızlı erişim butonu
  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 2,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(Icons.arrow_forward_ios,
                    size: 16, color: Colors.grey),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Son puantajlar listesi
  Widget _buildRecentPuantajList(PuantajProvider provider) {
    final puantajList = provider.puantajList;

    if (puantajList.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(
            child: Text('Henüz puantaj bulunmuyor.'),
          ),
        ),
      );
    }

    // Son 5 puantajı göster
    final recentPuantajList =
        puantajList.length > 5 ? puantajList.sublist(0, 5) : puantajList;

    return Column(
      children: recentPuantajList.map((puantaj) {
        final workerName = puantaj.worker != null
            ? '${puantaj.worker!['firstName']} ${puantaj.worker!['lastName']}'
            : 'İşçi';

        return Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: Colors.blue.shade100,
              child: const Icon(Icons.person, color: Colors.blue),
            ),
            title: Text(
              workerName,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              '${puantaj.formattedTarih} - ${puantaj.hours.toStringAsFixed(1)} saat',
              overflow: TextOverflow.ellipsis,
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // Puantaj detayı sayfasına git
              // Navigator.pushNamed(context, '/puantaj-detail', arguments: puantaj);
            },
          ),
        );
      }).toList(),
    );
  }

  // Yeni işçi oluşturma dialog'u
  void _showCreateWorkerDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final firstNameController = TextEditingController();
    final lastNameController = TextEditingController();
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Yeni İşçi Oluştur'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: firstNameController,
                decoration: const InputDecoration(
                  labelText: 'Ad',
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ad alanı boş bırakılamaz';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: lastNameController,
                decoration: const InputDecoration(
                  labelText: 'Soyad',
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Soyad alanı boş bırakılamaz';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Şifre',
                  prefixIcon: Icon(Icons.lock),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Şifre alanı boş bırakılamaz';
                  }
                  if (value.length < 6) {
                    return 'Şifre en az 6 karakter olmalıdır';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final userProvider =
                    Provider.of<UserProvider>(context, listen: false);

                final success = await userProvider.createWorker(
                  firstName: firstNameController.text.trim(),
                  lastName: lastNameController.text.trim(),
                  password: passwordController.text,
                );

                if (mounted) {
                  Navigator.pop(context);

                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('İşçi başarıyla oluşturuldu'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(userProvider.errorMessage ??
                            'İşçi oluşturulurken bir hata oluştu'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            },
            child: const Text('Oluştur'),
          ),
        ],
      ),
    );
  }

  // Yeni malzemeci oluşturma dialog'u
  void _showCreateSupplierDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final firstNameController = TextEditingController();
    final lastNameController = TextEditingController();
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Yeni Malzemeci Oluştur'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: firstNameController,
                decoration: const InputDecoration(
                  labelText: 'Ad',
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ad alanı boş bırakılamaz';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: lastNameController,
                decoration: const InputDecoration(
                  labelText: 'Soyad',
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Soyad alanı boş bırakılamaz';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Şifre',
                  prefixIcon: Icon(Icons.lock),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Şifre alanı boş bırakılamaz';
                  }
                  if (value.length < 6) {
                    return 'Şifre en az 6 karakter olmalıdır';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final userProvider =
                    Provider.of<UserProvider>(context, listen: false);

                final success = await userProvider.createSupplier(
                  firstName: firstNameController.text.trim(),
                  lastName: lastNameController.text.trim(),
                  password: passwordController.text,
                );

                if (mounted) {
                  Navigator.pop(context);

                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Malzemeci başarıyla oluşturuldu'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(userProvider.errorMessage ??
                            'Malzemeci oluşturulurken bir hata oluştu'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            },
            child: const Text('Oluştur'),
          ),
        ],
      ),
    );
  }
}
