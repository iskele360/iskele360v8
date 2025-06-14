import 'package:flutter/material.dart';

class MainLoginScreen extends StatelessWidget {
  const MainLoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue.shade50,
              Colors.white,
            ],
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'İskele 360',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Puantaj ve Zimmet Yönetimi',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 64),
                
                // Puantajcı kartı
                _buildLoginCard(
                  context,
                  title: 'Puantajcı Girişi',
                  description: 'İşçi ve malzemeci kaydı, puantaj oluşturma',
                  icon: Icons.admin_panel_settings,
                  color: Colors.blue,
                  onTap: () => Navigator.pushNamed(context, '/login'),
                ),
                
                const SizedBox(height: 16),
                
                // İşçi kartı
                _buildLoginCard(
                  context,
                  title: 'İşçi Girişi',
                  description: 'Puantaj ve zimmet görüntüleme',
                  icon: Icons.engineering,
                  color: Colors.green,
                  onTap: () => Navigator.pushNamed(context, '/worker_login'),
                ),
                
                const SizedBox(height: 16),
                
                // Malzemeci kartı (henüz aktif değil)
                _buildLoginCard(
                  context,
                  title: 'Malzemeci Girişi',
                  description: 'İşçi listesi ve zimmet oluşturma',
                  icon: Icons.inventory,
                  color: Colors.orange,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Malzemeci girişi yakında eklenecek'),
                      ),
                    );
                  },
                  isDisabled: true,
                ),
                
                const SizedBox(height: 32),
                
                // Kayıt ol butonu
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(context, '/register');
                  },
                  icon: const Icon(Icons.person_add),
                  label: const Text('Puantajcı olarak kayıt ol'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade50,
                    foregroundColor: Colors.blue.shade700,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginCard(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool isDisabled = false,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isDisabled ? Colors.grey.shade300 : color.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: isDisabled ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: isDisabled ? Colors.grey.shade100 : color.withOpacity(0.05),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: isDisabled ? Colors.grey.shade200 : color.withOpacity(0.2),
                child: Icon(
                  icon,
                  color: isDisabled ? Colors.grey : color,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDisabled ? Colors.grey : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDisabled ? Colors.grey.shade600 : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: isDisabled ? Colors.grey.shade400 : color.withOpacity(0.7),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
} 