class User {
  final int id;
  final String email;
  final String fullName;
  final String role;
  final bool isActive;

  User({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    required this.isActive,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      fullName: json['full_name'],
      role: json['role'],
      isActive: json['is_active'] ?? true,
    );
  }

  bool get isManager => role == 'manager' || role == 'admin';
  bool get isAdmin => role == 'admin';
}
