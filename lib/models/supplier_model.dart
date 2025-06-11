class Supplier {
  final String id;
  final String name;
  final String surname;
  final String code;
  final String supervisorId;
  final DateTime createdAt;

  Supplier({
    required this.id,
    required this.name,
    required this.surname,
    required this.code,
    required this.supervisorId,
    required this.createdAt,
  });

  factory Supplier.fromJson(Map<String, dynamic> json) {
    try {
      return Supplier(
        id: json['id'] as String,
        name: json['name'] as String,
        surname: json['surname'] as String,
        code: json['code'] as String,
        supervisorId: json['supervisorId'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
    } catch (e) {
      print('Supplier.fromJson hatası: $e');
      print('Hatalı JSON: $json');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    try {
      return {
        'id': id,
        'name': name,
        'surname': surname,
        'code': code,
        'supervisorId': supervisorId,
        'createdAt': createdAt.toIso8601String(),
      };
    } catch (e) {
      print('Supplier.toJson hatası: $e');
      rethrow;
    }
  }
  
  @override
  String toString() {
    return 'Supplier{id: $id, name: $name, surname: $surname, code: $code, supervisorId: $supervisorId}';
  }
} 