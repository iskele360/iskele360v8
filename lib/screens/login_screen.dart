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
  final _passwordController = TextEditingController();
  final _codeController = TextEditingController();

  bool _isLoading = false;
  String _selectedRole = AppConstants.rolePuantajci;
  bool _isCodeLogin = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _codeController.dispose();
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
        if (_selectedRole == AppConstants.roleSupplier) {
          success = await authProvider.loginWithSupplierCode(
            code: _codeController.text.trim(),
          );
        } else if (_selectedRole == AppConstants.roleWorker) {
          success = await authProvider.loginWithWorkerCode(
            code: _codeController.text.trim(),
          );
        } else {
          throw Exception('Geçersiz rol seçimi');
        }
      } else {
        success = await authProvider.login(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      }

      if (mounted) {
        if (success) {
          Navigator.pushReplacementNamed(context, '/home');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                authProvider.error ?? 'Giriş başarısız',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
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
                AppConstants.appName,
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
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Giriş tipi seçimi
                          SegmentedButton<bool>(
                            segments: const [
                              ButtonSegment<bool>(
                                value: false,
                                label: Text('E-posta'),
                                icon: Icon(Icons.email),
                              ),
                              ButtonSegment<bool>(
                                value: true,
                                label: Text('Kod'),
                                icon: Icon(Icons.key),
                              ),
                            ],
                            selected: {_isCodeLogin},
                            onSelectionChanged: (Set<bool> newSelection) {
                              setState(() {
                                _isCodeLogin = newSelection.first;
                              });
                            },
                          ),
                          const SizedBox(height: 24),

                          if (_isCodeLogin) ...[
                            // Rol seçimi
                            SegmentedButton<String>(
                              segments: const [
                                ButtonSegment<String>(
                                  value: AppConstants.roleSupplier,
                                  label: Text('Tedarikçi'),
                                  icon: Icon(Icons.business),
                                ),
                                ButtonSegment<String>(
                                  value: AppConstants.roleWorker,
                                  label: Text('İşçi'),
                                  icon: Icon(Icons.person),
                                ),
                              ],
                              selected: {_selectedRole},
                              onSelectionChanged: (Set<String> newSelection) {
                                setState(() {
                                  _selectedRole = newSelection.first;
                                });
                              },
                            ),
                            const SizedBox(height: 24),

                            // Kod
                            TextFormField(
                              controller: _codeController,
                              decoration: const InputDecoration(
                                labelText: 'Kod',
                                prefixIcon: Icon(Icons.key),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Lütfen kodunuzu girin';
                                }
                                return null;
                              },
                            ),
                          ] else ...[
                            // E-posta
                            TextFormField(
                              controller: _emailController,
                              decoration: const InputDecoration(
                                labelText: 'E-posta',
                                prefixIcon: Icon(Icons.email),
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

                            // Şifre
                            TextFormField(
                              controller: _passwordController,
                              decoration: const InputDecoration(
                                labelText: 'Şifre',
                                prefixIcon: Icon(Icons.lock),
                              ),
                              obscureText: true,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Lütfen şifrenizi girin';
                                }
                                return null;
                              },
                            ),
                          ],

                          const SizedBox(height: 24),

                          // Giriş butonu
                          ElevatedButton(
                            onPressed: _isLoading ? null : _login,
                            child: _isLoading
                                ? const CircularProgressIndicator()
                                : const Text('Giriş Yap'),
                          ),

                          if (!_isCodeLogin) ...[
                            const SizedBox(height: 16),
                            TextButton(
                              onPressed: () =>
                                  Navigator.pushNamed(context, '/register'),
                              child: const Text('Hesabınız yok mu? Kayıt olun'),
                            ),
                          ],
                        ],
                      ),
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
}
