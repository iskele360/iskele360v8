import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iskele360v7/providers/auth_provider.dart';
import 'package:iskele360v7/utils/constants.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isCodeLogin = false; // İşçi ve malzemeci için kod ile giriş
  String _selectedRole = 'supervisor'; // Varsayılan rol

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      bool success;

      if (_isCodeLogin) {
        // Kod ile giriş (işçi veya malzemeci)
        success = await authProvider.loginWithCode(
            _codeController.text.trim(), _passwordController.text);
      } else {
        // Email ile giriş (puantajcı)
        success = await authProvider.loginWithEmail(
            _emailController.text.trim(), _passwordController.text);
      }

      if (mounted) {
        if (success) {
          Navigator.pushReplacementNamed(context, '/home');
        } else if (!AppConstants.useMockApi) {
          // Sadece gerçek API kullanırken hata mesajını göster
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                authProvider.errorMessage ?? 'Giriş başarısız',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted && !AppConstants.useMockApi) {
        // Sadece gerçek API kullanırken hata mesajını göster
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: Colors.red,
          ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue.shade700,
              Colors.blue.shade900,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 40),
              // Logo
              const Icon(
                Icons.business,
                size: 80,
                color: Colors.white,
              ),
              const SizedBox(height: 16),
              // Uygulama adı
              const Text(
                'İSKELE 360',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'İş Yönetim Sistemi',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 40),

              // Giriş formu
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Giriş seçenekleri (Sekmeler)
                        _buildLoginTabs(),
                        const SizedBox(height: 24),

                        // Giriş formu
                        _buildLoginForm(),
                        const SizedBox(height: 32),

                        // Giriş butonu
                        ElevatedButton(
                          onPressed: _isLoading ? null : _login,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor:
                                Colors.blue.withOpacity(0.5),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.0,
                                  ),
                                )
                              : const Text(
                                  'Giriş Yap',
                                  style: TextStyle(fontSize: 16),
                                ),
                        ),
                        const SizedBox(height: 24),

                        // Puantajcı kaydı butonu (sadece puantajcı sekmesindeyken görünecek)
                        if (_selectedRole == 'supervisor')
                          TextButton.icon(
                            onPressed: () {
                              Navigator.pushNamed(context, '/register');
                            },
                            icon: const Icon(Icons.person_add),
                            label: const Text('Puantajcı Kaydı Oluştur'),
                          ),

                        // Ana ekrana dön
                        TextButton.icon(
                          onPressed: () {
                            Navigator.pushReplacementNamed(context, '/');
                          },
                          icon: const Icon(Icons.arrow_back),
                          label: const Text('Ana Ekrana Dön'),
                        ),

                        // Sürüm bilgisi
                        const SizedBox(height: 16),
                        const Text(
                          'v1.0.0 - İSKELE360 Tüm Hakları Saklıdır',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoginTabs() {
    return Row(
      children: [
        Expanded(
          child: _buildRoleTab(
            'Puantajcı',
            Icons.admin_panel_settings,
            'supervisor',
            Colors.blue,
          ),
        ),
        Expanded(
          child: _buildRoleTab(
            'İşçi',
            Icons.person,
            'isci',
            Colors.green,
          ),
        ),
        Expanded(
          child: _buildRoleTab(
            'Malzemeci',
            Icons.inventory,
            'supplier',
            Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildRoleTab(String title, IconData icon, String role, Color color) {
    final isSelected = _selectedRole == role;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedRole = role;
          _isCodeLogin = role == 'isci' || role == 'supplier';
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? color : Colors.grey.shade300,
              width: 2,
            ),
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? color : Colors.grey,
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? color : Colors.grey,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _isCodeLogin ? 'Kodu Girin' : 'E-posta Girin',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),

          // Email veya kod girişi
          if (_isCodeLogin)
            TextFormField(
              controller: _codeController,
              decoration: InputDecoration(
                hintText: '10 haneli kodu girin',
                prefixIcon: const Icon(Icons.code),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Lütfen kodunuzu girin';
                }
                if (value.length != 10) {
                  return 'Kod 10 haneli olmalıdır';
                }
                return null;
              },
            )
          else
            TextFormField(
              controller: _emailController,
              decoration: InputDecoration(
                hintText: 'E-posta adresinizi girin',
                prefixIcon: const Icon(Icons.email),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Lütfen e-posta adresinizi girin';
                }
                if (!value.contains('@')) {
                  return 'Geçerli bir e-posta adresi girin';
                }
                return null;
              },
            ),

          const SizedBox(height: 16),
          const Text(
            'Şifre',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),

          // Şifre girişi
          TextFormField(
            controller: _passwordController,
            obscureText: !_isPasswordVisible,
            decoration: InputDecoration(
              hintText: 'Şifrenizi girin',
              prefixIcon: const Icon(Icons.lock),
              suffixIcon: IconButton(
                icon: Icon(
                  _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () {
                  setState(() {
                    _isPasswordVisible = !_isPasswordVisible;
                  });
                },
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey.shade100,
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Lütfen şifrenizi girin';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }
}
