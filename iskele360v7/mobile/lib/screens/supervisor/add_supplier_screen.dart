import 'dart:math';

class AddSupplierScreen extends StatefulWidget {
  // ... (existing code)
}

class _AddSupplierScreenState extends State<AddSupplierScreen> {
  // ... (existing code)

  Future<void> _addSupplier() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        // Girilen değerleri temizleyelim (trim)
        final name = _nameController.text.trim();
        final surname = _surnameController.text.trim();
        
        // 6 haneli rastgele bir kod oluşturalım
        final code = _generateRandomCode();
        
        // Kullanıcı bilgilerini SharedPreferences'dan alalım
        final userData = await _apiService.getUserData();
        final supervisorId = userData?['id'] as String?;
        
        if (supervisorId == null) {
          throw Exception('Puantajcı ID bulunamadı');
        }
        
        // Malzemeciyi ekleyelim
        final result = await _apiService.addSupplier(
          name: name,
          surname: surname,
          code: code,
          supervisorId: supervisorId,
        );
        
        if (result['success'] == true) {
          final createdSupplier = Supplier.fromJson(result['data']['supplier']);
          
          // Konsola bilgileri yazdıralım (debug)
          print('Malzemeci eklendi: ${createdSupplier.name} ${createdSupplier.surname}');
          print('Malzemeci kodu: ${createdSupplier.code}');
          
          setState(() {
            _createdSupplier = createdSupplier;
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = result['error'] ?? 'Malzemeci eklenirken bir hata oluştu';
            _isLoading = false;
          });
        }
      } catch (e) {
        print('Malzemeci eklerken hata: $e');
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }
  
  // 6 haneli rastgele bir kod oluşturur
  String _generateRandomCode() {
    const length = 6;
    const chars = '0123456789';
    final random = Random();
    return String.fromCharCodes(
      Iterable.generate(
        length, 
        (_) => chars.codeUnitAt(random.nextInt(chars.length))
      )
    );
  }

  // ... (rest of the existing code)
} 