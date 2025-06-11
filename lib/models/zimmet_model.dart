import 'package:equatable/equatable.dart';
import 'package:intl/intl.dart';

class Zimmet extends Equatable {
  final String? id;
  final String supervisorId;
  final String supplierId;
  final String workerId;
  final String itemName;
  final int quantity;
  final String date;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Zimmet({
    this.id,
    required this.supervisorId,
    required this.supplierId,
    required this.workerId,
    required this.itemName,
    required this.quantity,
    required this.date,
    this.createdAt,
    this.updatedAt,
  });

  @override
  List<Object?> get props => [
    id,
    supervisorId,
    supplierId,
    workerId,
    itemName,
    quantity,
    date,
    createdAt,
    updatedAt
  ];

  // Görüntüleme için formatlı tarih
  String get formattedDate {
    try {
      final dateTime = DateTime.parse(date);
      return DateFormat('dd.MM.yyyy').format(dateTime);
    } catch (e) {
      return date;
    }
  }

  // Backend'den gelen JSON'dan Zimmet nesnesi oluştur
  factory Zimmet.fromJson(Map<String, dynamic> json) {
    return Zimmet(
      id: json['_id'] ?? json['id'],
      supervisorId: json['supervisorId'] ?? '',
      supplierId: json['supplierId'] ?? '',
      workerId: json['workerId'] ?? '',
      itemName: json['itemName'] ?? '',
      quantity: json['quantity'] ?? 0,
      date: json['date'] ?? DateTime.now().toIso8601String(),
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : null,
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt']) 
          : null,
    );
  }

  // Zimmet nesnesini JSON'a dönüştür
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'supervisorId': supervisorId,
      'supplierId': supplierId,
      'workerId': workerId,
      'itemName': itemName,
      'quantity': quantity,
      'date': date,
    };
  }

  // Zimmet nesnesinin kopyasını oluştur
  Zimmet copyWith({
    String? id,
    String? supervisorId,
    String? supplierId,
    String? workerId,
    String? itemName,
    int? quantity,
    String? date,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Zimmet(
      id: id ?? this.id,
      supervisorId: supervisorId ?? this.supervisorId,
      supplierId: supplierId ?? this.supplierId,
      workerId: workerId ?? this.workerId,
      itemName: itemName ?? this.itemName,
      quantity: quantity ?? this.quantity,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
} 