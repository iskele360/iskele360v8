import 'package:flutter/material.dart';
import 'package:iskele360v7/models/worker_model.dart';
import 'package:iskele360v7/models/inventory_model.dart';
import 'package:iskele360v7/screens/supplier/add_inventory_screen.dart';
import 'package:iskele360v7/services/api_service.dart';

class WorkersViewScreen extends StatefulWidget {
  const WorkersViewScreen({super.key});

  @override
  State<WorkersViewScreen> createState() => _WorkersViewScreenState();
}

class _WorkersViewScreenState extends State<WorkersViewScreen> {
  final ApiService _apiService = ApiService();
  List<Worker> _workers = [];
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _userData;
  Worker? _selectedWorker;
  
  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadWorkers();
  }
  
  Future<void> _loadUserData() async {
    try {
      final userData = await _apiService.getUserData();
      setState(() {
        _userData = userData;
      });
      print('Malzemeci verileri: $userData');
    } catch (e) {
      print('Malzemeci verileri yükleme hatası: $e');
    }
  }
  
  Future<void> _loadWorkers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      // Malzemeci puantajcısının işçilerini getir
      final userData = await _apiService.getUserData();
      final supervisorId = userData?['supervisorId'];
      
      if (supervisorId == null) {
        throw Exception('Puantajcı bilgisi bulunamadı');
      }
      
      // Sadece kendi puantajcısının işçilerini görebilir
      final workers = await _apiService.getAllWorkers();
      final filteredWorkers = workers.where((w) => w.supervisorId == supervisorId).toList();
      
      setState(() {
        _workers = filteredWorkers;
      });
      
      print('İşçi listesi: ${filteredWorkers.length} işçi bulundu');
    } catch (e) {
      print('İşçi listesi yükleme hatası: $e');
      setState(() {
        _errorMessage = e.toString();
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
      appBar: AppBar(
        title: const Text('İşçi Listesi'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadWorkers,
            tooltip: 'Yenile',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadWorkers,
                        child: const Text('Tekrar Dene'),
                      ),
                    ],
                  ),
                )
              : _workers.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.person_off,
                            size: 64,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Puantajcınıza ait işçi bulunmuyor',
                            style: TextStyle(fontSize: 18),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadWorkers,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: _workers.length,
                        itemBuilder: (context, index) {
                          final worker = _workers[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: Colors.blue.shade100,
                                        child: Text(
                                          worker.name.substring(0, 1).toUpperCase(),
                                          style: TextStyle(
                                            color: Colors.blue.shade800,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '${worker.name} ${worker.surname}',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                const Text(
                                                  'Kod: ',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                                Expanded(
                                                  child: Text(
                                                    worker.code,
                                                    style: const TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 14,
                                                    ),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      SizedBox(
                                        width: 110,
                                        child: ElevatedButton.icon(
                                          onPressed: () {
                                            _selectedWorker = worker;
                                            _showAddInventoryScreen();
                                          },
                                          icon: const Icon(Icons.add_circle_outline, size: 14),
                                          label: const Text('Zimmet', style: TextStyle(fontSize: 12)),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.green,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                                            visualDensity: VisualDensity.compact,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  const Divider(),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Flexible(
                                        child: Text(
                                          'Oluşturulma: ${_formatDate(worker.createdAt)}',
                                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Flexible(
                                        child: SingleChildScrollView(
                                          scrollDirection: Axis.horizontal,
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              TextButton.icon(
                                                onPressed: () {
                                                  // İşçi detaylarını göster
                                                  showDialog(
                                                    context: context,
                                                    builder: (context) => AlertDialog(
                                                      title: const Text('İşçi Detayları'),
                                                      content: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        mainAxisSize: MainAxisSize.min,
                                                        children: [
                                                          _buildDetailRow('ID', worker.id),
                                                          _buildDetailRow('Ad', worker.name),
                                                          _buildDetailRow('Soyad', worker.surname),
                                                          _buildDetailRow('Kod', worker.code),
                                                          _buildDetailRow('Puantajcı ID', worker.supervisorId),
                                                          _buildDetailRow('Oluşturulma', _formatDate(worker.createdAt)),
                                                        ],
                                                      ),
                                                      actions: [
                                                        TextButton(
                                                          onPressed: () {
                                                            Navigator.of(context).pop();
                                                          },
                                                          child: const Text('Kapat'),
                                                        ),
                                                      ],
                                                    ),
                                                  );
                                                },
                                                icon: const Icon(Icons.info_outline, size: 16),
                                                label: const Text('Detaylar'),
                                                style: TextButton.styleFrom(
                                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                                  visualDensity: VisualDensity.compact,
                                                ),
                                              ),
                                              TextButton.icon(
                                                onPressed: () {
                                                  // Zimmet listesini göster
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (context) => InventoryListScreen(
                                                        workerId: worker.id,
                                                        workerName: '${worker.name} ${worker.surname}',
                                                      ),
                                                    ),
                                                  );
                                                },
                                                icon: const Icon(Icons.assignment, size: 16),
                                                label: const Text('Zimmetler'),
                                                style: TextButton.styleFrom(
                                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                                  visualDensity: VisualDensity.compact,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
  
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
  
  // Detay satırı widget'ı
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  // Zimmet ekleme sayfasını aç
  void _showAddInventoryScreen() {
    if (_selectedWorker == null) {
      setState(() {
        _errorMessage = 'Lütfen önce bir işçi seçin';
      });
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddInventoryScreen(
          selectedWorker: _selectedWorker!,
        ),
      ),
    );
  }
}

// Zimmet listesi ekranı
class InventoryListScreen extends StatefulWidget {
  final String workerId;
  final String workerName;
  
  const InventoryListScreen({
    super.key,
    required this.workerId,
    required this.workerName,
  });
  
  @override
  State<InventoryListScreen> createState() => _InventoryListScreenState();
}

class _InventoryListScreenState extends State<InventoryListScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  String? _errorMessage;
  List<Inventory> _inventories = [];
  
  @override
  void initState() {
    super.initState();
    _loadInventory();
  }
  
  Future<void> _loadInventory() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      // İşçinin zimmetlerini getir
      final result = await _apiService.getWorkerInventories(widget.workerId);
      
      if (result['success'] == true) {
        final List<dynamic> inventoriesJson = result['data']['inventories'];
        final inventories = inventoriesJson
            .map((json) => Inventory.fromJson(json))
            .toList();
        
        setState(() {
          _inventories = inventories;
          _isLoading = false;
        });
        
        print('Zimmet listesi: ${inventories.length} öğe bulundu');
      } else {
        setState(() {
          _errorMessage = result['error'] ?? 'Zimmet verileri yüklenirken bir hata oluştu';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Zimmet listesi yükleme hatası: $e');
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${widget.workerName} Zimmetleri',
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadInventory,
                        child: const Text('Tekrar Dene'),
                      ),
                    ],
                  ),
                )
              : _inventories.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.inventory_2_outlined,
                            size: 64,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text(
                              '${widget.workerName} için zimmet bulunmuyor',
                              style: const TextStyle(fontSize: 18),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () {
                              _showAddInventoryScreen();
                            },
                            icon: const Icon(Icons.add),
                            label: const Text('Zimmet Ekle'),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadInventory,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: _inventories.length,
                        itemBuilder: (context, index) {
                          final inventory = _inventories[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            child: ListTile(
                              leading: const CircleAvatar(
                                backgroundColor: Colors.green,
                                child: Icon(
                                  Icons.inventory,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              title: Text(
                                inventory.itemName,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Miktar: ${inventory.quantity}',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    'Tarih: ${inventory.getFormattedDate()}',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                              isThreeLine: true,
                            ),
                          );
                        },
                      ),
                    ),
      floatingActionButton: !_isLoading && _errorMessage == null
          ? FloatingActionButton(
              onPressed: _showAddInventoryScreen,
              backgroundColor: Colors.green,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
  
  // İşçi için zimmet ekleme sayfasını aç
  void _showAddInventoryScreen() {
    // İşçi model oluştur
    final worker = Worker(
      id: widget.workerId,
      name: widget.workerName.split(' ').first,
      surname: widget.workerName.split(' ').length > 1 ? widget.workerName.split(' ').last : '',
      code: '', // Kod burada önemli değil
      supervisorId: '', // Supervisor ID burada önemli değil
      createdAt: DateTime.now(),
    );
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddInventoryScreen(
          selectedWorker: worker,
        ),
      ),
    ).then((_) => _loadInventory());
  }
} 