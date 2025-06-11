import 'package:flutter/material.dart';
import 'package:iskele360v7/models/inventory_model.dart';
import 'package:iskele360v7/models/worker_model.dart';
import 'package:iskele360v7/services/api_service.dart';
import 'package:intl/intl.dart';

class AddInventoryScreen extends StatefulWidget {
  final Worker selectedWorker;

  const AddInventoryScreen({
    super.key,
    required this.selectedWorker,
  });

  @override
  State<AddInventoryScreen> createState() => _AddInventoryScreenState();
}

class _AddInventoryScreenState extends State<AddInventoryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _itemNameController = TextEditingController();
  final _quantityController = TextEditingController();
  
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  String? _errorMessage;
  Inventory? _createdInventory;
  bool _inventoryAdded = false;

  // İşçi bilgileri
  late String _workerId;
  late String _workerName;
  late String _workerSurname;

  @override
  void initState() {
    super.initState();
    _workerId = widget.selectedWorker.id;
    _workerName = widget.selectedWorker.name;
    _workerSurname = widget.selectedWorker.surname;
  }

  @override
  void dispose() {
    _itemNameController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _addInventory() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        // Kullanıcı verilerini al
        final userData = await _apiService.getUserData();
        if (userData == null) {
          throw Exception('Kullanıcı verileri bulunamadı');
        }

        // Malzemeci bilgilerini al
        final supplierId = userData['id'];
        final supervisorId = userData['supervisorId'];

        // Bugünün tarihini alma
        final now = DateTime.now();
        final formattedDate = DateFormat('yyyy-MM-dd').format(now);

        // Yeni zimmet ekle
        final result = await _apiService.addInventory(
          workerId: _workerId,
          itemName: _itemNameController.text.trim(),
          quantity: int.parse(_quantityController.text.trim()),
          supplierId: supplierId,
          supervisorId: supervisorId,
          date: formattedDate,
        );

        if (result['success'] == true) {
          // Zimmet başarıyla eklendi
          final inventoryJson = result['data']['inventory'] as Map<String, dynamic>;
          final inventory = Inventory.fromJson(inventoryJson);
          
          setState(() {
            _createdInventory = inventory;
            _inventoryAdded = true;
            _isLoading = false;
            // Formu temizle
            _itemNameController.clear();
            _quantityController.clear();
          });
        } else {
          setState(() {
            _errorMessage = result['error'] ?? 'Zimmet eklenirken bir hata oluştu';
            _isLoading = false;
          });
        }
      } catch (e) {
        print('Zimmet eklerken hata: $e');
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Zimmet Ekle'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // İşçi bilgileri kartı
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'İşçi Bilgileri',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('Ad: $_workerName', overflow: TextOverflow.ellipsis),
                      Text('Soyad: $_workerSurname', overflow: TextOverflow.ellipsis),
                      Text('İşçi Kodu: ${widget.selectedWorker.code}', overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Hata mesajı
                if (_errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(8),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade300),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: Colors.red),
                            overflow: TextOverflow.visible,
                            maxLines: 3,
                          ),
                        ),
                      ],
                    ),
                  ),
                
                // Malzeme adı
                TextFormField(
                  controller: _itemNameController,
                  decoration: const InputDecoration(
                    labelText: 'Malzeme Adı',
                    hintText: 'Örn: Baret, Eldiven, Çizme vs.',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.inventory),
                  ),
                  textCapitalization: TextCapitalization.sentences,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Lütfen malzeme adını girin';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Miktar
                TextFormField(
                  controller: _quantityController,
                  decoration: const InputDecoration(
                    labelText: 'Miktar',
                    hintText: 'Örn: 1, 2, 3 vs.',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.numbers),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Lütfen miktarı girin';
                    }
                    if (int.tryParse(value) == null) {
                      return 'Lütfen geçerli bir sayı girin';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 24),
                
                // Ekle butonu
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _addInventory,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Zimmet Ekle'),
                  ),
                ),
                
                // Başarılı mesajı
                if (_createdInventory != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green.shade300),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Zimmet Başarıyla Eklendi',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text('Malzeme: ${_createdInventory!.itemName}', overflow: TextOverflow.ellipsis),
                            Text('Miktar: ${_createdInventory!.quantity}', overflow: TextOverflow.ellipsis),
                            Text('Tarih: ${_createdInventory!.getFormattedDate()}', overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Butonlar
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              child: const Text('İşçi Listesine Dön'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  _createdInventory = null;
                                });
                              },
                              child: const Text('Yeni Zimmet Ekle'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}