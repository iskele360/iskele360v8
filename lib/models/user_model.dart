import 'package:equatable/equatable.dart';

class User extends Equatable {
  final String id;
  final String name;
  final String surname;
  final String? email;
  final String? code;
  final String role; // 'supervisor', 'isci', 'supplier'
  String? _token;
  final DateTime createdAt;

  User({
    required this.id,
    required this.name,
    required this.surname,
    this.email,
    this.code,
    required this.role,
    String? token,
    required this.createdAt,
  }) : _token = token;

  // Getter for token
  String? get token => _token;

  // Setter for token
  set token(String? value) {
    _token = value;
  }

  @override
  List<Object?> get props => [
    id, 
    name, 
    surname, 
    email, 
    code, 
    role, 
    _token, 
    createdAt
  ];

  // Kullanıcının tam adını döndüren yardımcı metod
  String get fullName => '$name $surname';

  // Getters for firstName, lastName for backward compatibility
  String get firstName => name;
  String get lastName => surname;

  bool get isSupervisor => role == 'supervisor';
  bool get isWorker => role == 'isci';
  bool get isSupplier => role == 'supplier';
  bool get isLoggedIn => _token != null && _token!.isNotEmpty;

  // Backend'den gelen JSON'dan User nesnesi oluştur
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'] ?? json['firstName'] ?? '',
      surname: json['surname'] ?? json['lastName'] ?? '',
      email: json['email'],
      code: json['code'],
      role: json['role'] ?? 'isci',
      token: json['token'],
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
    );
  }

  // User nesnesini JSON'a dönüştür
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'surname': surname,
      'email': email,
      'code': code,
      'role': role,
      'token': _token,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // User nesnesinin kopyasını oluştur
  User copyWith({
    String? id,
    String? name,
    String? surname,
    String? email,
    String? code,
    String? role,
    String? token,
    DateTime? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      surname: surname ?? this.surname,
      email: email ?? this.email,
      code: code ?? this.code,
      role: role ?? this.role,
      token: token ?? _token,
      createdAt: createdAt ?? this.createdAt,
    );
  }
} 