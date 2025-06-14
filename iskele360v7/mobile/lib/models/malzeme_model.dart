import 'package:iskele360v7/models/user_model.dart';

class Malzeme {
  final String id;
  final String name;
  final String? description;
  final String supplierId;
  final DateTime createdAt;
  final User? supplier;

  Malzeme({
    required this.id,
    required this.name,
    this.description,
    required this.supplierId,
    required this.createdAt,
    this.supplier,
  });

  factory Malzeme.fromJson(Map<String, dynamic> json) {
    return Malzeme(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      supplierId: json['supplierId'],
      createdAt: DateTime.parse(json['createdAt']),
      supplier: json['supplier'] != null ? User.fromJson(json['supplier']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'supplierId': supplierId,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class Zimmet {
  final String id;
  final String malzemeId;
  final String workerId;
  final String supplierId;
  final int quantity;
  final DateTime assignedDate;
  final DateTime? returnDate;
  final String status; // 'assigned', 'returned'
  final String? note;
  final Malzeme? malzeme;
  final User? worker;
  final User? supplier;

  Zimmet({
    required this.id,
    required this.malzemeId,
    required this.workerId,
    required this.supplierId,
    required this.quantity,
    required this.assignedDate,
    this.returnDate,
    required this.status,
    this.note,
    this.malzeme,
    this.worker,
    this.supplier,
  });

  factory Zimmet.fromJson(Map<String, dynamic> json) {
    return Zimmet(
      id: json['id'],
      malzemeId: json['malzemeId'],
      workerId: json['workerId'],
      supplierId: json['supplierId'],
      quantity: json['quantity'],
      assignedDate: DateTime.parse(json['assignedDate']),
      returnDate: json['returnDate'] != null ? DateTime.parse(json['returnDate']) : null,
      status: json['status'] ?? 'assigned',
      note: json['note'],
      malzeme: json['malzeme'] != null ? Malzeme.fromJson(json['malzeme']) : null,
      worker: json['worker'] != null ? User.fromJson(json['worker']) : null,
      supplier: json['supplier'] != null ? User.fromJson(json['supplier']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'malzemeId': malzemeId,
      'workerId': workerId,
      'supplierId': supplierId,
      'quantity': quantity,
      'assignedDate': assignedDate.toIso8601String(),
      'returnDate': returnDate?.toIso8601String(),
      'status': status,
      'note': note,
    };
  }
} 