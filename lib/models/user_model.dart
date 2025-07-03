class UserModel {
  final String id;
  final String? email;
  final String? name;
  final String? phone;
  final String role;
  final String status;
  final String? fcmToken;
  final String? profileImageUrl;

  UserModel({
    required this.id,
    this.email,
    this.name,
    this.phone,
    this.role = 'customer',
    this.status = 'active',
    this.fcmToken,
    this.profileImageUrl,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      id: id,
      email: map['email'],
      name: map['name'],
      phone: map['phone'],
      role: map['role'] ?? 'customer',
      status: map['status'] ?? 'active',
      fcmToken: map['fcmToken'],
      profileImageUrl: map['profileImageUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'phone': phone,
      'role': role,
      'status': status,
      if (fcmToken != null) 'fcmToken': fcmToken,
      if (profileImageUrl != null) 'profileImageUrl': profileImageUrl,
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    String? phone,
    String? role,
    String? status,
    String? fcmToken,
    String? profileImageUrl,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      status: status ?? this.status,
      fcmToken: fcmToken ?? this.fcmToken,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
    );
  }
}
