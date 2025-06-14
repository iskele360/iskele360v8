import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iskele360v7/providers/auth_provider.dart';
import 'package:iskele360v7/providers/malzeme_provider.dart';
import 'package:iskele360v7/providers/user_provider.dart';
import 'package:intl/intl.dart';

class SupplierHome extends StatefulWidget {
  const SupplierHome({Key? key}) : super(key: key);

  @override
  State<SupplierHome> createState() => _SupplierHomeState();
}

class _SupplierHomeState extends State<SupplierHome> {
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
        // Malzemeci ve zimmet verilerini yükle
        final malzemeProvider = Provider.of<MalzemeProvider>(context, listen: false);
        await malzemeProvider.getMalzemeList();
        await malzemeProvider.getZimmetList();
        
        // İşçi listesini yükle
        await malzemeProvider.getIsciList();
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
                          backgroundColor: Colors.orange.shade700,
                          radius: 24,
                          child: Text(
                            user?.firstName.substring(0, 1) ?? 'M',
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
                              'Malzemeci Paneli',
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
                    
                    // Malzemeci kodu (Kopyalanabilir)
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
                            'Malzemeci Kodu: ${user?.code ?? 'Belirtilmemiş'}',
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
                  title: 'Toplam Malzeme',
                  value: malzemeProvider.malzemeList.length.toString(),
                  icon: Icons.category,
                  color: Colors.orange,
                ),
                const SizedBox(width: 16),
                _buildStatCard(
                  title: 'Toplam Zimmet',
                  value: malzemeProvider.zimmetList.length.toString(),
                  icon: Icons.assignment,
                  color: Colors.blue,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildStatCard(
                  title: 'İşçi Sayısı',
                  value: malzemeProvider.isciList.length.toString(),
                  icon: Icons.people,
                  color: Colors.green,
                ),
                const SizedBox(width: 16),
                _buildStatCard(
                  title: 'Aktif Zimmetler',
                  value: _getActiveZimmetCount(malzemeProvider).toString(),
                  icon: Icons.inventory,
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
              label: 'Yeni Malzeme Ekle',
              icon: Icons.add_circle,
              color: Colors.orange.shade700,
              onTap: () {
                _showCreateMalzemeDialog(context);
              },
            ),
            
            _buildActionButton(
              label: 'Yeni Zimmet Oluştur',
              icon: Icons.assignment_add,
              color: Colors.blue.shade700,
              onTap: () {
                Navigator.pushNamed(context, '/zimmet-create');
              },
            ),
            
            _buildActionButton(
              label: 'İşçi Listesini Görüntüle',
              icon: Icons.people,
              color: Colors.green.shade700,
              onTap: () {
                Navigator.pushNamed(context, '/supplier-workers');
              },
            ),
            
            const SizedBox(height: 24),
            
            // Son zimmetler başlığı
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Son Zimmetler',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/zimmet');
                  },
                  child: const Text('Tümünü Gör'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // Son zimmetler listesi
            _buildZimmetList(malzemeProvider),
            
            const SizedBox(height: 24),
            
            // Malzemeler başlığı
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Malzemeler',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/malzeme');
                  },
                  child: const Text('Tümünü Gör'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // Malzeme listesi
            _buildMalzemeList(malzemeProvider),
          ],
        ),
      ),
    );
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
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
              ],
            ),
          ),
        ),
      ),
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
              backgroundColor: isActive ? Colors.blue.shade100 : Colors.grey.shade200,
              child: Icon(
                Icons.inventory,
                color: isActive ? Colors.blue : Colors.grey,
              ),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    zimmet.malzeme?.name ?? 'Malzeme',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isActive ? Colors.blue.shade100 : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isActive ? 'Aktif' : 'İade Edildi',
                    style: TextStyle(
                      color: isActive ? Colors.blue.shade700 : Colors.grey.shade700,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text('${zimmet.quantity} adet - ${zimmet.worker?.fullName ?? 'İşçi'}'),
                Text(
                  DateFormat('dd MMMM yyyy', 'tr_TR').format(zimmet.assignedDate),
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
            trailing: isActive
                ? IconButton(
                    icon: Icon(Icons.check_circle_outline, color: Colors.green.shade700),
                    onPressed: () {
                      _showReturnZimmetDialog(context, zimmet.id);
                    },
                  )
                : null,
            onTap: () {
              // Zimmet detayı sayfasına git
              // Navigator.pushNamed(context, '/zimmet-detail', arguments: zimmet);
            },
          ),
        );
      }).toList(),
    );
  }
  
  // Malzeme listesi
  Widget _buildMalzemeList(MalzemeProvider provider) {
    final malzemeList = provider.malzemeList;
    
    if (malzemeList.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(
            child: Text('Henüz malzeme bulunmuyor.'),
          ),
        ),
      );
    }
    
    // Son 3 malzemeyi göster
    final recentMalzemeList = malzemeList.length > 3 
        ? malzemeList.sublist(0, 3) 
        : malzemeList;
    
    return Column(
      children: recentMalzemeList.map((malzeme) {
        return Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: Colors.orange.shade100,
              child: const Icon(Icons.category, color: Colors.orange),
            ),
            title: Text(
              malzeme.name,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            subtitle: malzeme.description != null && malzeme.description!.isNotEmpty
                ? Text(
                    malzeme.description!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  )
                : null,
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // Malzeme detayı sayfasına git
              // Navigator.pushNamed(context, '/malzeme-detail', arguments: malzeme);
            },
          ),
        );
      }).toList(),
    );
  }
  
  // Yeni malzeme oluşturma dialog'u
  void _showCreateMalzemeDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Yeni Malzeme Ekle'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Malzeme Adı',
                  prefixIcon: Icon(Icons.category),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Malzeme adı boş bırakılamaz';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Açıklama (İsteğe Bağlı)',
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 2,
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
                final malzemeProvider = Provider.of<MalzemeProvider>(context, listen: false);
                
                final success = await malzemeProvider.createMalzeme(
                  name: nameController.text.trim(),
                  description: descriptionController.text.trim().isNotEmpty
                      ? descriptionController.text.trim()
                      : null,
                );
                
                if (mounted) {
                  Navigator.pop(context);
                  
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Malzeme başarıyla oluşturuldu'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(malzemeProvider.errorMessage ?? 'Malzeme oluşturulurken bir hata oluştu'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            },
            child: const Text('Ekle'),
          ),
        ],
      ),
    );
  }
  
  // Zimmet iade dialog'u
  void _showReturnZimmetDialog(BuildContext context, String zimmetId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Zimmeti İade Et'),
        content: const Text('Bu zimmeti iade etmek istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final malzemeProvider = Provider.of<MalzemeProvider>(context, listen: false);
              
              final success = await malzemeProvider.returnZimmet(zimmetId);
              
              if (mounted) {
                Navigator.pop(context);
                
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Zimmet başarıyla iade edildi'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(malzemeProvider.errorMessage ?? 'Zimmet iade edilirken bir hata oluştu'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('İade Et'),
          ),
        ],
      ),
    );
  }
} 