import 'package:intl/intl.dart';

class Puantaj {
  final String id;
  final String isciId;
  final DateTime baslangicSaati;
  final DateTime bitisSaati;
  final double calismaSuresi;
  final String projeId;
  final String projeBilgisi;
  final String? aciklama;
  final String durum;
  final DateTime tarih;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? additionalData;
  final Map<String, dynamic>? worker;

  Puantaj({
    required this.id,
    required this.isciId,
    required this.baslangicSaati,
    required this.bitisSaati,
    required this.calismaSuresi,
    required this.projeId,
    required this.projeBilgisi,
    this.aciklama,
    required this.durum,
    required this.tarih,
    required this.createdAt,
    required this.updatedAt,
    this.additionalData,
    this.worker,
  });

  // Getters
  DateTime get date => tarih;
  String get description => aciklama ?? '';
  double get hours => calismaSuresi;
  String get formattedTarih => getFormattedDate();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'isciId': isciId,
      'baslangicSaati': baslangicSaati.toIso8601String(),
      'bitisSaati': bitisSaati.toIso8601String(),
      'calismaSuresi': calismaSuresi,
      'projeId': projeId,
      'projeBilgisi': projeBilgisi,
      'aciklama': aciklama,
      'durum': durum,
      'tarih': tarih.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      if (worker != null) 'worker': worker,
      if (additionalData != null) ...additionalData!,
    };
  }

  factory Puantaj.fromJson(Map<String, dynamic> json) {
    return Puantaj(
      id: json['_id'] ?? json['id'],
      isciId: json['isciId'],
      baslangicSaati: DateTime.parse(json['baslangicSaati']),
      bitisSaati: DateTime.parse(json['bitisSaati']),
      calismaSuresi: double.parse(json['calismaSuresi'].toString()),
      projeId: json['projeId'],
      projeBilgisi: json['projeBilgisi'],
      aciklama: json['aciklama'],
      durum: json['durum'],
      tarih: DateTime.parse(json['tarih']),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      worker: json['worker'],
      additionalData: json['additionalData'],
    );
  }

  String getFormattedDate() {
    return DateFormat('dd.MM.yyyy').format(tarih);
  }

  String getFormattedStartTime() {
    return DateFormat('HH:mm').format(baslangicSaati);
  }

  String getFormattedEndTime() {
    return DateFormat('HH:mm').format(bitisSaati);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      '_id': id,
      'isciId': isciId,
      'baslangicSaati': baslangicSaati.toIso8601String(),
      'bitisSaati': bitisSaati.toIso8601String(),
      'calismaSuresi': calismaSuresi,
      'projeId': projeId,
      'projeBilgisi': projeBilgisi,
      'aciklama': aciklama,
      'durum': durum,
      'tarih': tarih.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'formattedDate': getFormattedDate(),
      'formattedStartTime': getFormattedStartTime(),
      'formattedEndTime': getFormattedEndTime(),
      'hours': hours,
      'description': description,
      if (worker != null) 'worker': worker,
      if (additionalData != null) ...additionalData!,
    };
  }

  Puantaj copyWith({
    String? id,
    String? isciId,
    DateTime? baslangicSaati,
    DateTime? bitisSaati,
    double? calismaSuresi,
    String? projeId,
    String? projeBilgisi,
    String? aciklama,
    String? durum,
    DateTime? tarih,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? worker,
    Map<String, dynamic>? additionalData,
  }) {
    return Puantaj(
      id: id ?? this.id,
      isciId: isciId ?? this.isciId,
      baslangicSaati: baslangicSaati ?? this.baslangicSaati,
      bitisSaati: bitisSaati ?? this.bitisSaati,
      calismaSuresi: calismaSuresi ?? this.calismaSuresi,
      projeId: projeId ?? this.projeId,
      projeBilgisi: projeBilgisi ?? this.projeBilgisi,
      aciklama: aciklama ?? this.aciklama,
      durum: durum ?? this.durum,
      tarih: tarih ?? this.tarih,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      worker: worker ?? this.worker,
      additionalData: additionalData ?? this.additionalData,
    );
  }

  @override
  String toString() {
    return 'Puantaj(id: $id, isciId: $isciId, tarih: ${getFormattedDate()})';
  }
}
