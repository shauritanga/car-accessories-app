import 'package:cloud_firestore/cloud_firestore.dart';

enum AddressType {
  home,
  work,
  other,
}

class AddressModel {
  final String id;
  final String userId;
  final String fullName;
  final String phoneNumber;
  final String street;
  final String city;
  final String state;
  final String postalCode;
  final String country;
  final AddressType type;
  final bool isDefault;
  final String? label; // Custom label for "other" type
  final String? instructions; // Delivery instructions
  final double? latitude;
  final double? longitude;
  final DateTime createdAt;
  final DateTime? updatedAt;

  AddressModel({
    required this.id,
    required this.userId,
    required this.fullName,
    required this.phoneNumber,
    required this.street,
    required this.city,
    required this.state,
    required this.postalCode,
    this.country = 'Tanzania',
    required this.type,
    this.isDefault = false,
    this.label,
    this.instructions,
    this.latitude,
    this.longitude,
    required this.createdAt,
    this.updatedAt,
  });

  factory AddressModel.fromMap(Map<String, dynamic> data, String id) {
    return AddressModel(
      id: id,
      userId: data['userId'] ?? '',
      fullName: data['fullName'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
      street: data['street'] ?? '',
      city: data['city'] ?? '',
      state: data['state'] ?? '',
      postalCode: data['postalCode'] ?? '',
      country: data['country'] ?? 'Tanzania',
      type: AddressType.values.firstWhere(
        (e) => e.toString() == data['type'],
        orElse: () => AddressType.home,
      ),
      isDefault: data['isDefault'] ?? false,
      label: data['label'],
      instructions: data['instructions'],
      latitude: data['latitude']?.toDouble(),
      longitude: data['longitude']?.toDouble(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'street': street,
      'city': city,
      'state': state,
      'postalCode': postalCode,
      'country': country,
      'type': type.toString(),
      'isDefault': isDefault,
      'label': label,
      'instructions': instructions,
      'latitude': latitude,
      'longitude': longitude,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  AddressModel copyWith({
    String? id,
    String? userId,
    String? fullName,
    String? phoneNumber,
    String? street,
    String? city,
    String? state,
    String? postalCode,
    String? country,
    AddressType? type,
    bool? isDefault,
    String? label,
    String? instructions,
    double? latitude,
    double? longitude,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AddressModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      street: street ?? this.street,
      city: city ?? this.city,
      state: state ?? this.state,
      postalCode: postalCode ?? this.postalCode,
      country: country ?? this.country,
      type: type ?? this.type,
      isDefault: isDefault ?? this.isDefault,
      label: label ?? this.label,
      instructions: instructions ?? this.instructions,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get displayName {
    switch (type) {
      case AddressType.home:
        return 'Home';
      case AddressType.work:
        return 'Work';
      case AddressType.other:
        return label ?? 'Other';
    }
  }

  String get fullAddress {
    final parts = <String>[];
    if (street.isNotEmpty) parts.add(street);
    if (city.isNotEmpty) parts.add(city);
    if (state.isNotEmpty) parts.add(state);
    if (postalCode.isNotEmpty) parts.add(postalCode);
    if (country.isNotEmpty) parts.add(country);
    return parts.join(', ');
  }

  String get shortAddress {
    final parts = <String>[];
    if (street.isNotEmpty) parts.add(street);
    if (city.isNotEmpty) parts.add(city);
    return parts.join(', ');
  }

  bool get isComplete {
    return fullName.isNotEmpty &&
        phoneNumber.isNotEmpty &&
        street.isNotEmpty &&
        city.isNotEmpty &&
        state.isNotEmpty;
  }
}
