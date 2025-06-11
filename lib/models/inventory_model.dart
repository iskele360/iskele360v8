import 'package:intl/intl.dart';

class Inventory {
  final String id;
  final String supervisorId;
  final String supplierId;
  final String workerId;
  final String itemName;
  final int quantity;
  final String date;

  Inventory({
    required this.id,
    required this.supervisorId,
    required this.supplierId,
    required this.workerId,
    required this.itemName,
    required this.quantity,
    required this.date,
  });

  // JSON'dan Inventory nesnesi oluşturma
  factory Inventory.fromJson(Map<String, dynamic> json) {
    return Inventory(
      id: json['id'] as String,
      supervisorId: json['supervisorId'] as String,
      supplierId: json['supplierId'] as String,
      workerId: json['workerId'] as String,
      itemName: json['itemName'] as String,
      quantity: json['quantity'] as int,
      date: json['date'] as String,
    );
  }

  // Inventory nesnesinden JSON oluşturma
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'supervisorId': supervisorId,
      'supplierId': supplierId,
      'workerId': workerId,
      'itemName': itemName,
      'quantity': quantity,
      'date': date,
    };
  }

  // Tarihi formatlama
  String getFormattedDate() {
    try {
      final dateTime = DateTime.parse(date);
      return DateFormat('dd.MM.yyyy').format(dateTime);
    } catch (e) {
      return date;
    }
  }

  @override
  String toString() {
    return 'Inventory{id: $id, itemName: $itemName, workerId: $workerId, supplierId: $supplierId}';
  }
} 