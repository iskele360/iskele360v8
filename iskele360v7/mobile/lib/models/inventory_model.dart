import 'package:intl/intl.dart';

class Inventory {
  final String id;
  final String workerId;
  final String supplierId;
  final String supervisorId;
  final String itemName;
  final int quantity;
  final DateTime date;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? additionalData;

  Inventory({
    required this.id,
    required this.workerId,
    required this.supplierId,
    required this.supervisorId,
    required this.itemName,
    required this.quantity,
    required this.date,
    required this.createdAt,
    required this.updatedAt,
    this.additionalData,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'workerId': workerId,
      'supplierId': supplierId,
      'supervisorId': supervisorId,
      'itemName': itemName,
      'quantity': quantity,
      'date': date.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      if (additionalData != null) ...additionalData!,
    };
  }

  factory Inventory.fromJson(Map<String, dynamic> json) {
    return Inventory(
      id: json['_id'] ?? json['id'],
      workerId: json['workerId'].toString(),
      supplierId: json['supplierId'].toString(),
      supervisorId: json['supervisorId'].toString(),
      itemName: json['itemName'],
      quantity: int.parse(json['quantity'].toString()),
      date: DateTime.parse(json['date']),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      additionalData: json['additionalData'],
    );
  }

  // Map-like access for backward compatibility
  dynamic operator [](String key) {
    switch (key) {
      case 'id':
        return id;
      case '_id':
        return id;
      case 'workerId':
        return workerId;
      case 'supplierId':
        return supplierId;
      case 'supervisorId':
        return supervisorId;
      case 'itemName':
        return itemName;
      case 'quantity':
        return quantity;
      case 'date':
        return date.toIso8601String();
      case 'createdAt':
        return createdAt.toIso8601String();
      case 'updatedAt':
        return updatedAt.toIso8601String();
      case 'formattedDate':
        return getFormattedDate();
      default:
        return additionalData?[key];
    }
  }

  // Convert to Map for backward compatibility
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      '_id': id,
      'workerId': workerId,
      'supplierId': supplierId,
      'supervisorId': supervisorId,
      'itemName': itemName,
      'quantity': quantity,
      'date': date.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'formattedDate': getFormattedDate(),
      if (additionalData != null) ...additionalData!,
    };
  }

  String getFormattedDate() {
    return DateFormat('dd.MM.yyyy').format(date);
  }

  Inventory copyWith({
    String? id,
    String? workerId,
    String? supplierId,
    String? supervisorId,
    String? itemName,
    int? quantity,
    DateTime? date,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? additionalData,
  }) {
    return Inventory(
      id: id ?? this.id,
      workerId: workerId ?? this.workerId,
      supplierId: supplierId ?? this.supplierId,
      supervisorId: supervisorId ?? this.supervisorId,
      itemName: itemName ?? this.itemName,
      quantity: quantity ?? this.quantity,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      additionalData: additionalData ?? this.additionalData,
    );
  }

  @override
  String toString() {
    return 'Inventory(id: $id, itemName: $itemName, quantity: $quantity)';
  }
}
