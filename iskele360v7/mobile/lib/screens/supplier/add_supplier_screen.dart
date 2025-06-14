import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iskele360v7/models/supplier_model.dart';
import 'package:iskele360v7/services/api_service.dart';

class AddSupplierScreen extends StatefulWidget {
  const AddSupplierScreen({super.key});

  @override
  State<AddSupplierScreen> createState() => _AddSupplierScreenState();
}

class _AddSupplierScreenState extends State<AddSupplierScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _surnameController = TextEditingController();
  
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  String? _errorMessage;
  Supplier? _createdSupplier;

  @override
  void dispose() {
    _nameController.dispose();
    _surnameController.dispose();
    super.dispose();
  }

  Future<void> _addSupplier() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
        _createdSupplier = null;
      });

      try {
        final supplier = await _apiService.addSupplier(
          name: _nameController.text,
          surname: _surnameController.text,
        );

        // Debug: malzemeci bilgilerini konsola yazdır
        print('Malzemeci oluşturuldu: ${supplier.name} ${supplier.surname} - Kod: ${supplier.code}');
        
        setState(() {
          _createdSupplier = supplier;
          _nameController.clear();
          _surnameController.clear();
        });
      } catch (e) {
        print('Malzemeci ekleme hatası: $e');
        setState(() {
          _errorMessage = e.toString();
        });
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Kodu panoya kopyala
  Future<void> _copyCodeToClipboard(String code) async {
    await Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Kod panoya kopyalandı'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Malzemeci Ekle'),
        backgroundColor: Colors.orange.shade700,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(8),
                margin: const EdgeInsets.only(bottom: 16),
                color: Colors.red.withOpacity(0.1),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            
            if (_createdSupplier != null)
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Malzemeci başarıyla eklendi!',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.orange,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Ad: ${_createdSupplier!.name}'),
                    Text('Soyad: ${_createdSupplier!.surname}'),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Text(
                          'Malzemeci Kodu: ',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          _createdSupplier!.code,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy, size: 20),
                          onPressed: () => _copyCodeToClipboard(_createdSupplier!.code),
                          tooltip: 'Kodu kopyala',
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.yellow.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.yellow.shade700),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Giriş Bilgileri:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '- Ad: ${_createdSupplier!.name}',
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '- Soyad: ${_createdSupplier!.surname}',
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '- Kod: ${_createdSupplier!.code}',
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Malzemeci yukarıdaki bilgilerle giriş yapabilecek. Lütfen bu bilgileri not edin.',
                            style: TextStyle(
                              fontStyle: FontStyle.italic,
                              color: Colors.black54,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.pushReplacementNamed(context, '/suppliers_list');
                            },
                            child: const Text('Malzemeci Listesine Dön'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _createdSupplier = null;
                              });
                            },
                            child: const Text('Yeni Malzemeci Ekle'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            
            if (_createdSupplier == null)
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Malzemeci Ekleme',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Malzemeci bilgilerini girin. Sistem otomatik olarak 6 haneli benzersiz bir kod oluşturacaktır.',
                            style: TextStyle(
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Ad',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                      textCapitalization: TextCapitalization.words,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Lütfen adı girin';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      controller: _surnameController,
                      decoration: const InputDecoration(
                        labelText: 'Soyad',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                      textCapitalization: TextCapitalization.words,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Lütfen soyadı girin';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 24),
                    
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _addSupplier,
                      icon: const Icon(Icons.add_circle),
                      label: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Malzemeci Ekle ve Kod Oluştur'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
} 