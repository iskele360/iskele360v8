import 'dart:convert';

class User {
  final String id;
  final String name;
  final String surname;
  final String? email;
  final String? code;
  final String role;
  final String? supervisorId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? additionalData;
  final String? token;

  User({
    required this.id,
    required this.name,
    required this.surname,
    this.email,
    this.code,
    required this.role,
    this.supervisorId,
    required this.createdAt,
    required this.updatedAt,
    this.additionalData,
    this.token,
  });

  // Getters
  String get firstName => name;
  String get fullName => '$name $surname';

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'surname': surname,
      'email': email,
      'code': code,
      'role': role,
      'supervisorId': supervisorId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'token': token,
      if (additionalData != null) ...additionalData!,
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'] ?? json['id'],
      name: json['name'],
      surname: json['surname'],
      email: json['email'],
      code: json['code'],
      role: json['role'],
      supervisorId: json['supervisorId'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      additionalData: json['additionalData'],
      token: json['token'],
    );
  }

  // Map-like access for backward compatibility
  dynamic operator [](String key) {
    switch (key) {
      case 'id':
        return id;
      case '_id':
        return id;
      case 'name':
        return name;
      case 'surname':
        return surname;
      case 'email':
        return email;
      case 'code':
        return code;
      case 'role':
        return role;
      case 'supervisorId':
        return supervisorId;
      case 'createdAt':
        return createdAt.toIso8601String();
      case 'updatedAt':
        return updatedAt.toIso8601String();
      case 'token':
        return token;
      case 'firstName':
        return firstName;
      case 'fullName':
        return fullName;
      default:
        return additionalData?[key];
    }
  }

  // Convert to Map for backward compatibility
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      '_id': id,
      'name': name,
      'surname': surname,
      'email': email,
      'code': code,
      'role': role,
      'supervisorId': supervisorId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'token': token,
      'firstName': firstName,
      'fullName': fullName,
      if (additionalData != null) ...additionalData!,
    };
  }

  User copyWith({
    String? id,
    String? name,
    String? surname,
    String? email,
    String? code,
    String? role,
    String? supervisorId,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? additionalData,
    String? token,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      surname: surname ?? this.surname,
      email: email ?? this.email,
      code: code ?? this.code,
      role: role ?? this.role,
      supervisorId: supervisorId ?? this.supervisorId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      additionalData: additionalData ?? this.additionalData,
      token: token ?? this.token,
    );
  }

  @override
  String toString() {
    return 'User(id: $id, name: $name, surname: $surname, email: $email, code: $code, role: $role)';
  }
}
