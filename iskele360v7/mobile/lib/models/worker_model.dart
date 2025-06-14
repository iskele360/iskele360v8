class Worker {
  final String id;
  final String name;
  final String surname;
  final String code;
  final String? password;
  final String supervisorId;
  final DateTime createdAt;

  Worker({
    required this.id,
    required this.name,
    required this.surname,
    required this.code,
    this.password,
    required this.supervisorId,
    required this.createdAt,
  });

  factory Worker.fromJson(Map<String, dynamic> json) {
    try {
      return Worker(
        id: json['id'] as String,
        name: json['name'] as String,
        surname: json['surname'] as String,
        code: json['code'] as String,
        password: json['password'] as String?,
        supervisorId: json['supervisorId'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
    } catch (e) {
      print('Worker.fromJson hatası: $e');
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
        'password': password,
        'supervisorId': supervisorId,
        'createdAt': createdAt.toIso8601String(),
      };
    } catch (e) {
      print('Worker.toJson hatası: $e');
      rethrow;
    }
  }
  
  @override
  String toString() {
    return 'Worker{id: $id, name: $name, surname: $surname, code: $code, supervisorId: $supervisorId}';
  }
} 