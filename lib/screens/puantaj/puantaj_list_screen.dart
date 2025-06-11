import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:iskele360v7/models/puantaj_model.dart';
import 'package:iskele360v7/providers/auth_provider.dart';
import 'package:iskele360v7/providers/puantaj_provider.dart';
import 'package:iskele360v7/utils/constants.dart';

class PuantajListScreen extends StatefulWidget {
  static const String routeName = '/puantaj';
  
  const PuantajListScreen({Key? key}) : super(key: key);

  @override
  State<PuantajListScreen> createState() => _PuantajListScreenState();
}

class _PuantajListScreenState extends State<PuantajListScreen> {
  bool _isLoading = false;
  String _sortBy = 'tarih';
  bool _ascending = false;
  String _filterStatus = 'all';
  String? _selectedProjeId;
  
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');
  final DateFormat _timeFormat = DateFormat('HH:mm');
  
  @override
  void initState() {
    super.initState();
    _loadPuantajlar();
  }
  
  Future<void> _loadPuantajlar() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final puantajProvider = Provider.of<PuantajProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      final user = authProvider.currentUser;
      if (user == null) return;
      
      final isSupervisor = user.role == AppConstants.roleSupervisor || user.role == AppConstants.roleAdmin;
      
      if (isSupervisor) {
        await puantajProvider.loadPuantajciPuantajlari();
      } else {
        await puantajProvider.loadIsciPuantajlari(user.id);
      }
      
      puantajProvider.sortPuantajlar(_sortBy, _ascending);
      puantajProvider.filterPuantajlar(_filterStatus, _selectedProjeId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Puantaj kayıtları yüklenirken hata: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  void _sortPuantajlar(String field) {
    final puantajProvider = Provider.of<PuantajProvider>(context, listen: false);
    
    setState(() {
      if (_sortBy == field) {
        _ascending = !_ascending;
      } else {
        _sortBy = field;
        _ascending = true;
      }
      
      puantajProvider.sortPuantajlar(_sortBy, _ascending);
    });
  }
  
  void _filterByStatus(String status) {
    final puantajProvider = Provider.of<PuantajProvider>(context, listen: false);
    
    setState(() {
      _filterStatus = status;
      puantajProvider.filterPuantajlar(_filterStatus, _selectedProjeId);
    });
  }
  
  void _filterByProje(String? projeId) {
    final puantajProvider = Provider.of<PuantajProvider>(context, listen: false);
    
    setState(() {
      _selectedProjeId = projeId;
      puantajProvider.filterPuantajlar(_filterStatus, _selectedProjeId);
    });
  }
  
  Widget _buildFilterChips() {
    return Wrap(
      spacing: 8.0,
      children: [
        FilterChip(
          label: const Text('Tümü'),
          selected: _filterStatus == 'all',
          onSelected: (selected) {
            if (selected) _filterByStatus('all');
          },
        ),
        FilterChip(
          label: const Text('Tamamlandı'),
          selected: _filterStatus == AppConstants.puantajStatusTamamlandi,
          onSelected: (selected) {
            if (selected) _filterByStatus(AppConstants.puantajStatusTamamlandi);
          },
        ),
        FilterChip(
          label: const Text('Devam Ediyor'),
          selected: _filterStatus == AppConstants.puantajStatusDevamEdiyor,
          onSelected: (selected) {
            if (selected) _filterByStatus(AppConstants.puantajStatusDevamEdiyor);
          },
        ),
        FilterChip(
          label: const Text('İptal'),
          selected: _filterStatus == AppConstants.puantajStatusIptal,
          onSelected: (selected) {
            if (selected) _filterByStatus(AppConstants.puantajStatusIptal);
          },
        ),
      ],
    );
  }
  
  Widget _buildProjeDropdown(List<String?> projeler) {
    // Null olmayan projeleri filtrele ve String listesine dönüştür
    final nonNullProjeler = projeler.where((p) => p != null).map((p) => p!).toList();
    
    final items = [
      const DropdownMenuItem<String>(
        value: null,
        child: Text('Tüm Projeler'),
      ),
      ...nonNullProjeler.map((projeId) => DropdownMenuItem<String>(
        value: projeId,
        child: Text('Proje $projeId'),
      )).toList(),
    ];
    
    return DropdownButton<String>(
      value: _selectedProjeId,
      hint: const Text('Projeye göre filtrele'),
      isExpanded: true,
      items: items,
      onChanged: (value) {
        _filterByProje(value);
      },
    );
  }
  
  Widget _buildPuantajList() {
    return Consumer<PuantajProvider>(
      builder: (context, puantajProvider, _) {
        final filteredPuantajlar = puantajProvider.filteredPuantajlar;
        
        if (filteredPuantajlar.isEmpty) {
          return const Center(
            child: Text('Puantaj kaydı bulunamadı'),
          );
        }
        
        // Mevcut projeleri bul
        final projeler = puantajProvider.allPuantajlar
            .map((p) => p.projeId)
            .toSet()
            .toList();
        
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFilterChips(),
                  const SizedBox(height: 8),
                  _buildProjeDropdown(projeler),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: filteredPuantajlar.length,
                itemBuilder: (context, index) {
                  final puantaj = filteredPuantajlar[index];
                  return _buildPuantajCard(puantaj);
                },
              ),
            ),
          ],
        );
      },
    );
  }
  
  Widget _buildPuantajCard(Puantaj puantaj) {
    Color statusColor;
    IconData statusIcon;
    
    switch (puantaj.durum) {
      case AppConstants.puantajStatusTamamlandi:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case AppConstants.puantajStatusDevamEdiyor:
        statusColor = Colors.blue;
        statusIcon = Icons.timelapse;
        break;
      case AppConstants.puantajStatusIptal:
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help_outline;
    }
    
    final tarih = puantaj.tarih != null ? _dateFormat.format(puantaj.tarih!) : 'Belirtilmemiş';
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      child: InkWell(
        onTap: () => _showPuantajDetails(puantaj),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Proje: ${puantaj.projeBilgisi ?? 'Belirtilmemiş'}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Row(
                    children: [
                      Icon(statusIcon, color: statusColor, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        puantaj.durum?.toUpperCase() ?? 'BELİRTİLMEMİŞ',
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text('Tarih: $tarih'),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Başlangıç: ${puantaj.baslangicSaati ?? 'Belirtilmemiş'}'),
                  Text('Bitiş: ${puantaj.bitisSaati ?? '-'}'),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Çalışma Süresi: ${puantaj.calismaSuresi.toStringAsFixed(1)} saat',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              if (puantaj.aciklama != null && puantaj.aciklama!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Açıklama: ${puantaj.aciklama}',
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
  
  void _showPuantajDetails(Puantaj puantaj) async {
    final isSupervisor = Provider.of<AuthProvider>(context, listen: false)
        .currentUser?.role == AppConstants.roleSupervisor;
    
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.8,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    'Puantaj Detayları',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(),
                _buildDetailRow('Proje', puantaj.projeBilgisi ?? 'Belirtilmemiş'),
                _buildDetailRow('Tarih', puantaj.tarih != null ? _dateFormat.format(puantaj.tarih!) : 'Belirtilmemiş'),
                _buildDetailRow('Başlangıç Saati', puantaj.baslangicSaati ?? 'Belirtilmemiş'),
                _buildDetailRow('Bitiş Saati', puantaj.bitisSaati ?? '-'),
                _buildDetailRow('Çalışma Süresi', '${puantaj.calismaSuresi.toStringAsFixed(1)} saat'),
                _buildDetailRow('Durum', puantaj.durum?.toUpperCase() ?? 'Belirtilmemiş'),
                if (puantaj.aciklama != null && puantaj.aciklama!.isNotEmpty)
                  _buildDetailRow('Açıklama', puantaj.aciklama!),
                
                if (isSupervisor && puantaj.durum != AppConstants.puantajStatusIptal) ...[
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => _updatePuantajStatus(puantaj, AppConstants.puantajStatusTamamlandi),
                        icon: const Icon(Icons.check_circle, color: Colors.green),
                        label: const Text('Tamamlandı'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade50,
                          foregroundColor: Colors.green.shade800,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _updatePuantajStatus(puantaj, AppConstants.puantajStatusIptal),
                        icon: const Icon(Icons.cancel, color: Colors.red),
                        label: const Text('İptal Et'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade50,
                          foregroundColor: Colors.red.shade800,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
  
  Future<void> _updatePuantajStatus(Puantaj puantaj, String newStatus) async {
    Navigator.pop(context); // Detay sayfasını kapat
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final puantajProvider = Provider.of<PuantajProvider>(context, listen: false);
      await puantajProvider.updatePuantaj(
        puantajId: puantaj.id,
        durum: newStatus,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Puantaj durumu güncellendi: ${newStatus.toUpperCase()}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Durum güncellenirken hata: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  Widget _buildSortButton(String label, String field) {
    final isActive = _sortBy == field;
    
    return TextButton.icon(
      onPressed: () => _sortPuantajlar(field),
      icon: Icon(
        isActive
            ? (_ascending ? Icons.arrow_upward : Icons.arrow_downward)
            : Icons.swap_vert,
        size: 16,
      ),
      label: Text(label),
      style: TextButton.styleFrom(
        foregroundColor: isActive ? Colors.blue : Colors.grey.shade700,
        textStyle: TextStyle(
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Puantaj Listesi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPuantajlar,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            tooltip: 'Sırala',
            onSelected: _sortPuantajlar,
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'tarih',
                child: Row(
                  children: [
                    Icon(
                      _sortBy == 'tarih'
                          ? (_ascending ? Icons.arrow_upward : Icons.arrow_downward)
                          : Icons.swap_vert,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    const Text('Tarihe Göre'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'calismaSuresi',
                child: Row(
                  children: [
                    Icon(
                      _sortBy == 'calismaSuresi'
                          ? (_ascending ? Icons.arrow_upward : Icons.arrow_downward)
                          : Icons.swap_vert,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    const Text('Çalışma Süresine Göre'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'durum',
                child: Row(
                  children: [
                    Icon(
                      _sortBy == 'durum'
                          ? (_ascending ? Icons.arrow_upward : Icons.arrow_downward)
                          : Icons.swap_vert,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    const Text('Duruma Göre'),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(40),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSortButton('Tarih', 'tarih'),
                _buildSortButton('Süre', 'calismaSuresi'),
                _buildSortButton('Durum', 'durum'),
              ],
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildPuantajList(),
      floatingActionButton: Provider.of<AuthProvider>(context).currentUser?.role == AppConstants.roleSupervisor
          ? FloatingActionButton(
              onPressed: () {
                // Yeni puantaj ekleme sayfasına git
                // Navigator.of(context).pushNamed('/puantaj/create');
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
} 