import 'package:equatable/equatable.dart';
import 'package:intl/intl.dart';
import 'package:iskele360v7/models/user_model.dart';

class Puantaj extends Equatable {
  final String id;
  final String workerId; // İşçi ID'si
  final String supervisorId; // Puantajcı ID'si
  final DateTime date;
  final double hours;
  final String? description;
  final DateTime createdAt;
  final User? worker; // İlişkili işçi
  final User? supervisor; // İlişkili puantajcı
  final String? projeId;
  final String? projeBilgisi;
  final String? durum;
  final String? baslangicSaati;
  final String? bitisSaati;
  final double calismaSuresi;
  final String? aciklama;

  const Puantaj({
    required this.id,
    required this.workerId,
    required this.supervisorId,
    required this.date,
    required this.hours,
    this.description,
    required this.createdAt,
    this.worker,
    this.supervisor,
    this.projeId,
    this.projeBilgisi,
    this.durum,
    this.baslangicSaati,
    this.bitisSaati,
    required this.calismaSuresi,
    this.aciklama,
  });

  @override
  List<Object?> get props => [
    id,
    workerId,
    supervisorId,
    date,
    hours,
    description,
    createdAt,
    worker,
    supervisor,
    projeId,
    projeBilgisi,
    durum,
    baslangicSaati,
    bitisSaati,
    calismaSuresi,
    aciklama,
  ];

  // Görüntüleme için formatlı tarih
  String get formattedTarih => DateFormat('dd.MM.yyyy').format(date);
  
  // Getter for tarih (alias for date)
  DateTime get tarih => date;

  // Backend'den gelen JSON'dan Puantaj nesnesi oluştur
  factory Puantaj.fromJson(Map<String, dynamic> json) {
    return Puantaj(
      id: json['id'],
      workerId: json['workerId'],
      supervisorId: json['supervisorId'],
      date: DateTime.parse(json['date']),
      hours: double.parse(json['hours'].toString()),
      description: json['description'],
      createdAt: DateTime.parse(json['createdAt']),
      worker: json['worker'] != null ? User.fromJson(json['worker']) : null,
      supervisor: json['supervisor'] != null ? User.fromJson(json['supervisor']) : null,
      projeId: json['projeId'],
      projeBilgisi: json['projeBilgisi'],
      durum: json['durum'],
      baslangicSaati: json['baslangicSaati'],
      bitisSaati: json['bitisSaati'],
      calismaSuresi: json['calismaSuresi'] != null ? double.parse(json['calismaSuresi'].toString()) : 0.0,
      aciklama: json['aciklama'] ?? json['description'],
    );
  }

  // Puantaj nesnesini JSON'a dönüştür
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'workerId': workerId,
      'supervisorId': supervisorId,
      'date': date.toIso8601String(),
      'hours': hours,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'projeId': projeId,
      'projeBilgisi': projeBilgisi,
      'durum': durum,
      'baslangicSaati': baslangicSaati,
      'bitisSaati': bitisSaati,
      'calismaSuresi': calismaSuresi,
      'aciklama': aciklama,
    };
  }

  // Puantaj nesnesinin kopyasını oluştur
  Puantaj copyWith({
    String? id,
    String? workerId,
    String? supervisorId,
    DateTime? date,
    double? hours,
    String? description,
    DateTime? createdAt,
    User? worker,
    User? supervisor,
    String? projeId,
    String? projeBilgisi,
    String? durum,
    String? baslangicSaati,
    String? bitisSaati,
    double? calismaSuresi,
    String? aciklama,
  }) {
    return Puantaj(
      id: id ?? this.id,
      workerId: workerId ?? this.workerId,
      supervisorId: supervisorId ?? this.supervisorId,
      date: date ?? this.date,
      hours: hours ?? this.hours,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      worker: worker ?? this.worker,
      supervisor: supervisor ?? this.supervisor,
      projeId: projeId ?? this.projeId,
      projeBilgisi: projeBilgisi ?? this.projeBilgisi,
      durum: durum ?? this.durum,
      baslangicSaati: baslangicSaati ?? this.baslangicSaati,
      bitisSaati: bitisSaati ?? this.bitisSaati,
      calismaSuresi: calismaSuresi ?? this.calismaSuresi,
      aciklama: aciklama ?? this.aciklama,
    );
  }
} 