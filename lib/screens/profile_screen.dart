import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iskele360v7/providers/auth_provider.dart';
import 'package:iskele360v7/models/user_model.dart';
import 'package:iskele360v7/utils/constants.dart';

class ProfileScreen extends StatefulWidget {
  static const String routeName = '/profile';

  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _surnameController = TextEditingController();
  final _emailController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isEditingProfile = false;
  bool _isChangingPassword = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;

    if (user != null) {
      setState(() {
        _nameController.text = user.name ?? '';
        _surnameController.text = user.surname ?? '';
        _emailController.text = user.email ?? '';
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _surnameController.dispose();
    _emailController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.updateProfile(
          _nameController.text, _surnameController.text, _emailController.text);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil başarıyla güncellendi')),
        );
        setState(() {
          _isEditingProfile = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
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

  Future<void> _updatePassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_newPasswordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Yeni şifreler eşleşmiyor')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.updatePassword(
          _currentPasswordController.text, _newPasswordController.text);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Şifre başarıyla güncellendi')),
        );
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
        setState(() {
          _isChangingPassword = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
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

  Future<void> _logout() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.logout();

      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Çıkış yapılırken hata: $e')),
        );
      }
    }
  }

  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hesabı Sil'),
        content: const Text(
            'Hesabınızı silmek istediğinize emin misiniz? Bu işlem geri alınamaz.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Sil', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.deleteAccount();

      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Hesabınız başarıyla silindi')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hesap silinemedi: $e')),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildProfileContent() {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    if (user == null) {
      return const Center(child: Text('Kullanıcı bilgisi bulunamadı'));
    }

    if (_isEditingProfile) {
      return _buildEditProfileForm();
    } else if (_isChangingPassword) {
      return _buildChangePasswordForm();
    } else {
      return _buildProfileDetails(user);
    }
  }

  Widget _buildProfileDetails(User user) {
    final bool isSupervisor = user.role == AppConstants.roleSupervisor;
    final bool isAdmin = user.role == AppConstants.roleAdmin;

    return Column(
      children: [
        const SizedBox(height: 20),
        CircleAvatar(
          radius: 50,
          backgroundColor: Colors.blue.shade100,
          child: Text(
            '${user.name?.substring(0, 1) ?? ''}${user.surname?.substring(0, 1) ?? ''}'
                .toUpperCase(),
            style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          '${user.name ?? ''} ${user.surname ?? ''}'.toUpperCase(),
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 5),
        Text(
          user.email ?? '',
          style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
        ),
        const SizedBox(height: 5),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: isSupervisor || isAdmin
                ? Colors.blue.shade100
                : Colors.orange.shade100,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Text(
            user.role?.toUpperCase() ?? 'ÇALIŞAN',
            style: TextStyle(
              fontSize: 12,
              color: isSupervisor || isAdmin
                  ? Colors.blue.shade800
                  : Colors.orange.shade800,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 30),
        ListTile(
          leading: const Icon(Icons.person),
          title: const Text('Profil Bilgileri'),
          subtitle: const Text('Kişisel bilgilerinizi güncelleyin'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            setState(() {
              _isEditingProfile = true;
              _isChangingPassword = false;
            });
          },
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.lock),
          title: const Text('Şifre Değiştir'),
          subtitle: const Text('Hesap güvenliğinizi artırın'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            setState(() {
              _isChangingPassword = true;
              _isEditingProfile = false;
            });
          },
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.exit_to_app, color: Colors.red),
          title: const Text('Çıkış Yap', style: TextStyle(color: Colors.red)),
          onTap: _logout,
        ),
        if (isAdmin || isSupervisor)
          const SizedBox()
        else
          Column(
            children: [
              const Divider(),
              ListTile(
                leading: const Icon(Icons.delete_forever, color: Colors.red),
                title: const Text('Hesabı Sil',
                    style: TextStyle(color: Colors.red)),
                onTap: _deleteAccount,
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildEditProfileForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'İsim',
              prefixIcon: Icon(Icons.person),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'İsim alanı boş olamaz';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _surnameController,
            decoration: const InputDecoration(
              labelText: 'Soyisim',
              prefixIcon: Icon(Icons.person),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Soyisim alanı boş olamaz';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'E-posta',
              prefixIcon: Icon(Icons.email),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'E-posta alanı boş olamaz';
              }
              if (!value.contains('@')) {
                return 'Geçerli bir e-posta adresi girin';
              }
              return null;
            },
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: _isLoading ? null : _updateProfile,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Güncelle'),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: _isLoading
                ? null
                : () {
                    setState(() {
                      _isEditingProfile = false;
                      _loadUserData();
                    });
                  },
            child: const Text('İptal'),
          ),
        ],
      ),
    );
  }

  Widget _buildChangePasswordForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _currentPasswordController,
            decoration: InputDecoration(
              labelText: 'Mevcut Şifre',
              prefixIcon: const Icon(Icons.lock_outline),
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
            ),
            obscureText: !_isPasswordVisible,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Mevcut şifre alanı boş olamaz';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _newPasswordController,
            decoration: InputDecoration(
              labelText: 'Yeni Şifre',
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
            ),
            obscureText: !_isPasswordVisible,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Yeni şifre alanı boş olamaz';
              }
              if (value.length < 6) {
                return 'Şifre en az 6 karakter olmalıdır';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _confirmPasswordController,
            decoration: InputDecoration(
              labelText: 'Yeni Şifre (Tekrar)',
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
            ),
            obscureText: !_isPasswordVisible,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Şifre tekrar alanı boş olamaz';
              }
              if (value != _newPasswordController.text) {
                return 'Şifreler eşleşmiyor';
              }
              return null;
            },
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: _isLoading ? null : _updatePassword,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Şifreyi Güncelle'),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: _isLoading
                ? null
                : () {
                    setState(() {
                      _isChangingPassword = false;
                      _currentPasswordController.clear();
                      _newPasswordController.clear();
                      _confirmPasswordController.clear();
                    });
                  },
            child: const Text('İptal'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
      ),
      body: _isLoading && !_isEditingProfile && !_isChangingPassword
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: _buildProfileContent(),
            ),
    );
  }
}
