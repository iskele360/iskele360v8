enum UserRole {
  admin,
  puantajci,
  isci;

  String get name {
    switch (this) {
      case UserRole.admin:
        return 'Admin';
      case UserRole.puantajci:
        return 'Puantajcı';
      case UserRole.isci:
        return 'İşçi';
    }
  }
} 