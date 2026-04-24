enum UserRole {
  host,
  singer,
  audience,
  publicDisplay,
  none,
}

class AppUser {
  final String id;
  final String name;
  final UserRole role;
  final String? email;
  final String? phone;

  AppUser({
    required this.id, 
    required this.name, 
    required this.role,
    this.email,
    this.phone,
  });

  AppUser copyWith({
    String? id, 
    String? name, 
    UserRole? role,
    String? email,
    String? phone,
  }) {
    return AppUser(
      id: id ?? this.id,
      name: name ?? this.name,
      role: role ?? this.role,
      email: email ?? this.email,
      phone: phone ?? this.phone,
    );
  }
}
