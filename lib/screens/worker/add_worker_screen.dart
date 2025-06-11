import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iskele360v7/models/worker_model.dart';
import 'package:iskele360v7/services/api_service.dart';

class AddWorkerScreen extends StatefulWidget {
  const AddWorkerScreen({super.key});

  @override
  State<AddWorkerScreen> createState() => _AddWorkerScreenState();
}

class _AddWorkerScreenState extends State<AddWorkerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _surnameController = TextEditingController();
  
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  String? _errorMessage;
  Worker? _createdWorker;

  @override
  void dispose() {
    _nameController.dispose();
    _surnameController.dispose();
    super.dispose();
  }

  Future<void> _addWorker() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
        _createdWorker = null;
      });

      try {
        final worker = await _apiService.addWorker(
          name: _nameController.text,
          surname: _surnameController.text,
        );

        // Debug: işçi bilgilerini konsola yazdır
        print('İşçi oluşturuldu: ${worker.name} ${worker.surname} - Kod: ${worker.code}');
        
        setState(() {
          _createdWorker = worker;
          _nameController.clear();
          _surnameController.clear();
        });
      } catch (e) {
        print('İşçi ekleme hatası: $e');
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
        title: const Text('İşçi Ekle'),
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
            
            if (_createdWorker != null)
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'İşçi başarıyla eklendi!',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Ad: ${_createdWorker!.name}'),
                    Text('Soyad: ${_createdWorker!.surname}'),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Text(
                          'İşçi Kodu: ',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          _createdWorker!.code,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy, size: 20),
                          onPressed: () => _copyCodeToClipboard(_createdWorker!.code),
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
                          Text('- Ad: ${_createdWorker!.name}'),
                          Text('- Soyad: ${_createdWorker!.surname}'),
                          Text('- Kod: ${_createdWorker!.code}'),
                          const SizedBox(height: 4),
                          const Text(
                            'İşçi yukarıdaki bilgilerle giriş yapabilecek. Lütfen bu bilgileri not edin.',
                            style: TextStyle(
                              fontStyle: FontStyle.italic,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        OutlinedButton(
                          onPressed: () {
                            Navigator.pushReplacementNamed(context, '/workers_list');
                          },
                          child: const Text('İşçi Listesine Dön'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _createdWorker = null;
                            });
                          },
                          child: const Text('Yeni İşçi Ekle'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            
            if (_createdWorker == null)
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'İşçi Ekleme',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'İşçi bilgilerini girin. Sistem otomatik olarak 6 haneli benzersiz bir kod oluşturacaktır.',
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
                      onPressed: _isLoading ? null : _addWorker,
                      icon: const Icon(Icons.add_circle),
                      label: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('İşçi Ekle ve Kod Oluştur'),
                      style: ElevatedButton.styleFrom(
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