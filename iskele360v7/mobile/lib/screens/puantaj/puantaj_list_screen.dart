import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iskele360v7/providers/puantaj_provider.dart';
import 'package:iskele360v7/models/puantaj_model.dart';
import 'package:iskele360v7/utils/constants.dart';

class PuantajListScreen extends StatefulWidget {
  final String? workerId;

  const PuantajListScreen({Key? key, this.workerId}) : super(key: key);

  @override
  _PuantajListScreenState createState() => _PuantajListScreenState();
}

class _PuantajListScreenState extends State<PuantajListScreen> {
  String _sortField = 'tarih';
  bool _sortAscending = false;

  @override
  void initState() {
    super.initState();
    _loadPuantajlar();
  }

  Future<void> _loadPuantajlar() async {
    final provider = Provider.of<PuantajProvider>(context, listen: false);
    if (widget.workerId != null) {
      await provider.loadIsciPuantajlari(widget.workerId!);
    } else {
      await provider.loadPuantajciPuantajlari();
    }
    provider.sortPuantajlar(_sortField);
  }

  void _handleSort(String field) {
    final provider = Provider.of<PuantajProvider>(context, listen: false);
    setState(() {
      if (_sortField == field) {
        _sortAscending = !_sortAscending;
      } else {
        _sortField = field;
        _sortAscending = true;
      }
    });
    provider.sortPuantajlar(field, _sortAscending);
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
        ],
      ),
      body: Consumer<PuantajProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(child: Text('Hata: ${provider.error}'));
          }

          final puantajlar = provider.puantajlar;
          if (puantajlar.isEmpty) {
            return const Center(child: Text('Puantaj bulunamadı'));
          }

          return ListView.builder(
            itemCount: puantajlar.length,
            itemBuilder: (context, index) {
              final puantaj = puantajlar[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ListTile(
                  title: Text('Tarih: ${puantaj.getFormattedDate()}'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Başlangıç: ${puantaj.getFormattedStartTime()}'),
                      Text('Bitiş: ${puantaj.getFormattedEndTime()}'),
                      Text('Süre: ${puantaj.calismaSuresi} saat'),
                      Text('Durum: ${puantaj.durum}'),
                      if (puantaj.aciklama != null &&
                          puantaj.aciklama!.isNotEmpty)
                        Text('Açıklama: ${puantaj.aciklama}'),
                    ],
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) async {
                      switch (value) {
                        case 'edit':
                          await _showEditDialog(puantaj);
                          break;
                        case 'delete':
                          await _showDeleteDialog(puantaj);
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Text('Düzenle'),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Sil'),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _showEditDialog(Puantaj puantaj) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Puantaj Düzenle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Başlangıç: ${puantaj.getFormattedStartTime()}'),
            Text('Bitiş: ${puantaj.getFormattedEndTime()}'),
            Text('Süre: ${puantaj.calismaSuresi} saat'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop({
                'id': puantaj.id,
                'baslangicSaati': puantaj.baslangicSaati,
                'bitisSaati': puantaj.bitisSaati,
                'calismaSuresi': puantaj.calismaSuresi,
                'projeId': puantaj.projeId,
                'projeBilgisi': puantaj.projeBilgisi,
                'aciklama': puantaj.aciklama,
                'durum': AppConstants.puantajStatusTamamlandi,
              });
            },
            child: const Text('Tamamlandı'),
          ),
        ],
      ),
    );

    if (result != null) {
      final provider = Provider.of<PuantajProvider>(context, listen: false);
      await provider.updatePuantaj(
        id: result['id'] as String,
        baslangicSaati: result['baslangicSaati'] as DateTime,
        bitisSaati: result['bitisSaati'] as DateTime,
        calismaSuresi: result['calismaSuresi'] as double,
        projeId: result['projeId'] as String,
        projeBilgisi: result['projeBilgisi'] as String,
        aciklama: result['aciklama'] as String?,
        durum: result['durum'] as String,
      );
    }
  }

  Future<void> _showDeleteDialog(Puantaj puantaj) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Puantaj Sil'),
        content: const Text('Bu puantajı silmek istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (result == true) {
      final provider = Provider.of<PuantajProvider>(context, listen: false);
      await provider.deletePuantaj(puantaj.id);
    }
  }
}
