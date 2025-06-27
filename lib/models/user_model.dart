class UserModel {
  final String id;
  final String? email;
  final String? name;
  final String? phone;
  final String role;

  UserModel({
    required this.id,
    this.email,
    this.name,
    this.phone,
    this.role = 'customer',
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      id: id,
      email: map['email'],
      name: map['name'],
      phone: map['phone'],
      role: map['role'] ?? 'customer',
    );
  }

  Map<String, dynamic> toMap() {
    return {'email': email, 'name': name, 'phone': phone, 'role': role};
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    String? phone,
    String? role,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      role: role ?? this.role,
    );
  }
}
