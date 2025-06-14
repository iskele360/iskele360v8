import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iskele360v7/providers/auth_provider.dart';
import 'package:iskele360v7/providers/puantaj_provider.dart';
import 'package:iskele360v7/providers/malzeme_provider.dart';
import 'package:intl/intl.dart';

class WorkerHome extends StatefulWidget {
  const WorkerHome({Key? key}) : super(key: key);

  @override
  State<WorkerHome> createState() => _WorkerHomeState();
}

class _WorkerHomeState extends State<WorkerHome> {
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
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.currentUser;
      
      if (user != null) {
        // İşçinin puantaj verilerini yükle
        final puantajProvider = Provider.of<PuantajProvider>(context, listen: false);
        await puantajProvider.getPuantajByWorkerId(user.id);
        
        // İşçinin zimmet verilerini yükle
        final malzemeProvider = Provider.of<MalzemeProvider>(context, listen: false);
        await malzemeProvider.getZimmetByWorkerId(user.id);
      }
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
    final puantajProvider = Provider.of<PuantajProvider>(context);
    final malzemeProvider = Provider.of<MalzemeProvider>(context);
    
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
                          backgroundColor: Colors.green.shade700,
                          radius: 24,
                          child: Text(
                            user?.firstName.substring(0, 1) ?? 'İ',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hoş Geldiniz, ${user?.fullName}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'İşçi Paneli',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // İşçi kodu (Kopyalanabilir)
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.qr_code, color: Colors.grey),
                          const SizedBox(width: 8),
                          Text(
                            'İşçi Kodu: ${user?.code ?? 'Belirtilmemiş'}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            iconSize: 18,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            icon: const Icon(Icons.copy, color: Colors.grey),
                            onPressed: () {
                              // Kodu panoya kopyala
                              if (user?.code != null) {
                                // Implement clipboard functionality
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Kod panoya kopyalandı'),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              }
                            },
                          ),
                        ],
                      ),
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
                  title: 'Toplam Puantaj',
                  value: puantajProvider.puantajList.length.toString(),
                  icon: Icons.calendar_today,
                  color: Colors.green,
                ),
                const SizedBox(width: 16),
                _buildStatCard(
                  title: 'Bu Ayki Çalışma',
                  value: _getCurrentMonthHours(puantajProvider).toStringAsFixed(1) + ' saat',
                  icon: Icons.access_time,
                  color: Colors.blue,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildStatCard(
                  title: 'Toplam Zimmet',
                  value: malzemeProvider.zimmetList.length.toString(),
                  icon: Icons.inventory,
                  color: Colors.orange,
                ),
                const SizedBox(width: 16),
                _buildStatCard(
                  title: 'Aktif Zimmetler',
                  value: _getActiveZimmetCount(malzemeProvider).toString(),
                  icon: Icons.assignment,
                  color: Colors.purple,
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Son puantajlar başlığı
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Son Puantajlar',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/worker-puantaj');
                  },
                  child: const Text('Tümünü Gör'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // Son puantajlar listesi
            _buildRecentPuantajList(puantajProvider),
            
            const SizedBox(height: 24),
            
            // Zimmetler başlığı
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Zimmetlerim',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/worker-zimmet');
                  },
                  child: const Text('Tümünü Gör'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // Zimmetler listesi
            _buildZimmetList(malzemeProvider),
          ],
        ),
      ),
    );
  }
  
  // Bu ayki toplam çalışma saati
  double _getCurrentMonthHours(PuantajProvider provider) {
    final now = DateTime.now();
    final currentMonth = now.month;
    final currentYear = now.year;
    
    return provider.puantajList
        .where((p) => p.date.month == currentMonth && p.date.year == currentYear)
        .fold(0.0, (sum, puantaj) => sum + puantaj.hours);
  }
  
  // Aktif zimmet sayısı
  int _getActiveZimmetCount(MalzemeProvider provider) {
    return provider.zimmetList
        .where((z) => z.status == 'assigned') // Teslim edilmemiş zimmetler
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
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
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
    
    // Son 3 puantajı göster
    final recentPuantajList = puantajList.length > 3 
        ? puantajList.sublist(0, 3) 
        : puantajList;
    
    return Column(
      children: recentPuantajList.map((puantaj) {
        return Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: Colors.green.shade100,
              child: const Icon(Icons.calendar_today, color: Colors.green),
            ),
            title: Text(
              DateFormat('dd MMMM yyyy', 'tr_TR').format(puantaj.date),
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text('${puantaj.hours.toStringAsFixed(1)} saat çalışma'),
                if (puantaj.description != null && puantaj.description!.isNotEmpty)
                  Text(
                    puantaj.description!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // Puantaj detayı sayfasına git
              // Navigator.pushNamed(context, '/worker-puantaj-detail', arguments: puantaj);
            },
          ),
        );
      }).toList(),
    );
  }
  
  // Zimmetler listesi
  Widget _buildZimmetList(MalzemeProvider provider) {
    final zimmetList = provider.zimmetList;
    
    if (zimmetList.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(
            child: Text('Henüz zimmet bulunmuyor.'),
          ),
        ),
      );
    }
    
    // Son 3 zimmeti göster
    final recentZimmetList = zimmetList.length > 3 
        ? zimmetList.sublist(0, 3) 
        : zimmetList;
    
    return Column(
      children: recentZimmetList.map((zimmet) {
        final isActive = zimmet.status == 'assigned';
        
        return Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: isActive ? Colors.orange.shade100 : Colors.grey.shade200,
              child: Icon(
                Icons.inventory,
                color: isActive ? Colors.orange : Colors.grey,
              ),
            ),
            title: Text(
              zimmet.malzeme?.name ?? 'Malzeme',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text('${zimmet.quantity} adet'),
                Text(
                  DateFormat('dd MMMM yyyy', 'tr_TR').format(zimmet.assignedDate),
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isActive ? Colors.green.shade100 : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                isActive ? 'Aktif' : 'İade Edildi',
                style: TextStyle(
                  color: isActive ? Colors.green.shade700 : Colors.grey.shade700,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            onTap: () {
              // Zimmet detayı sayfasına git
              // Navigator.pushNamed(context, '/worker-zimmet-detail', arguments: zimmet);
            },
          ),
        );
      }).toList(),
    );
  }
} 