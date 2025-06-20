import 'package:cloud_firestore/cloud_firestore.dart';

// Address model for address book
class UserAddress {
  final String id;
  final String label; // Home, Work, Other
  final String fullName;
  final String phoneNumber;
  final String addressLine1;
  final String addressLine2;
  final String city;
  final String state;
  final String postalCode;
  final String country;
  final bool isDefault;
  final DateTime createdAt;
  final DateTime? updatedAt;

  UserAddress({
    required this.id,
    required this.label,
    required this.fullName,
    required this.phoneNumber,
    required this.addressLine1,
    this.addressLine2 = '',
    required this.city,
    required this.state,
    required this.postalCode,
    required this.country,
    this.isDefault = false,
    required this.createdAt,
    this.updatedAt,
  });

  factory UserAddress.fromMap(Map<String, dynamic> data, String id) {
    return UserAddress(
      id: id,
      label: data['label'] ?? '',
      fullName: data['fullName'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
      addressLine1: data['addressLine1'] ?? '',
      addressLine2: data['addressLine2'] ?? '',
      city: data['city'] ?? '',
      state: data['state'] ?? '',
      postalCode: data['postalCode'] ?? '',
      country: data['country'] ?? '',
      isDefault: data['isDefault'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'label': label,
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'addressLine1': addressLine1,
      'addressLine2': addressLine2,
      'city': city,
      'state': state,
      'postalCode': postalCode,
      'country': country,
      'isDefault': isDefault,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  String get formattedAddress {
    final parts = [
      addressLine1,
      if (addressLine2.isNotEmpty) addressLine2,
      city,
      state,
      postalCode,
      country,
    ];
    return parts.join(', ');
  }

  UserAddress copyWith({
    String? id,
    String? label,
    String? fullName,
    String? phoneNumber,
    String? addressLine1,
    String? addressLine2,
    String? city,
    String? state,
    String? postalCode,
    String? country,
    bool? isDefault,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserAddress(
      id: id ?? this.id,
      label: label ?? this.label,
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      addressLine1: addressLine1 ?? this.addressLine1,
      addressLine2: addressLine2 ?? this.addressLine2,
      city: city ?? this.city,
      state: state ?? this.state,
      postalCode: postalCode ?? this.postalCode,
      country: country ?? this.country,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

// Payment method model
class PaymentMethod {
  final String id;
  final String type; // card, mobile_money, bank_transfer
  final String label; // Personal Card, Business Card, etc.
  final String? cardNumber; // Last 4 digits for display
  final String? cardHolderName;
  final String? expiryMonth;
  final String? expiryYear;
  final String? cardBrand; // Visa, Mastercard, etc.
  final String? mobileNumber; // For mobile money
  final String? bankName; // For bank transfers
  final String? accountNumber; // Last 4 digits for display
  final bool isDefault;
  final DateTime createdAt;
  final DateTime? updatedAt;

  PaymentMethod({
    required this.id,
    required this.type,
    required this.label,
    this.cardNumber,
    this.cardHolderName,
    this.expiryMonth,
    this.expiryYear,
    this.cardBrand,
    this.mobileNumber,
    this.bankName,
    this.accountNumber,
    this.isDefault = false,
    required this.createdAt,
    this.updatedAt,
  });

  factory PaymentMethod.fromMap(Map<String, dynamic> data, String id) {
    return PaymentMethod(
      id: id,
      type: data['type'] ?? '',
      label: data['label'] ?? '',
      cardNumber: data['cardNumber'],
      cardHolderName: data['cardHolderName'],
      expiryMonth: data['expiryMonth'],
      expiryYear: data['expiryYear'],
      cardBrand: data['cardBrand'],
      mobileNumber: data['mobileNumber'],
      bankName: data['bankName'],
      accountNumber: data['accountNumber'],
      isDefault: data['isDefault'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'label': label,
      'cardNumber': cardNumber,
      'cardHolderName': cardHolderName,
      'expiryMonth': expiryMonth,
      'expiryYear': expiryYear,
      'cardBrand': cardBrand,
      'mobileNumber': mobileNumber,
      'bankName': bankName,
      'accountNumber': accountNumber,
      'isDefault': isDefault,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  String get displayName {
    switch (type) {
      case 'card':
        return '$cardBrand •••• $cardNumber';
      case 'mobile_money':
        return 'Mobile Money •••• ${mobileNumber?.substring(mobileNumber!.length - 4)}';
      case 'bank_transfer':
        return '$bankName •••• $accountNumber';
      default:
        return label;
    }
  }

  bool get isExpired {
    if (expiryMonth == null || expiryYear == null) return false;
    final now = DateTime.now();
    final expiry = DateTime(int.parse(expiryYear!), int.parse(expiryMonth!));
    return now.isAfter(expiry);
  }
}

// User preferences model
class UserPreferences {
  final String userId;
  final String language;
  final String currency;
  final String timezone;
  final bool emailNotifications;
  final bool pushNotifications;
  final bool smsNotifications;
  final bool marketingEmails;
  final bool orderUpdates;
  final bool promotionalOffers;
  final bool productRecommendations;
  final bool priceAlerts;
  final String defaultShippingAddressId;
  final String defaultBillingAddressId;
  final String defaultPaymentMethodId;
  final DateTime createdAt;
  final DateTime? updatedAt;

  UserPreferences({
    required this.userId,
    this.language = 'en',
    this.currency = 'TZS',
    this.timezone = 'Africa/Dar_es_Salaam',
    this.emailNotifications = true,
    this.pushNotifications = true,
    this.smsNotifications = false,
    this.marketingEmails = false,
    this.orderUpdates = true,
    this.promotionalOffers = false,
    this.productRecommendations = true,
    this.priceAlerts = true,
    this.defaultShippingAddressId = '',
    this.defaultBillingAddressId = '',
    this.defaultPaymentMethodId = '',
    required this.createdAt,
    this.updatedAt,
  });

  factory UserPreferences.fromMap(Map<String, dynamic> data) {
    return UserPreferences(
      userId: data['userId'] ?? '',
      language: data['language'] ?? 'en',
      currency: data['currency'] ?? 'TZS',
      timezone: data['timezone'] ?? 'Africa/Dar_es_Salaam',
      emailNotifications: data['emailNotifications'] ?? true,
      pushNotifications: data['pushNotifications'] ?? true,
      smsNotifications: data['smsNotifications'] ?? false,
      marketingEmails: data['marketingEmails'] ?? false,
      orderUpdates: data['orderUpdates'] ?? true,
      promotionalOffers: data['promotionalOffers'] ?? false,
      productRecommendations: data['productRecommendations'] ?? true,
      priceAlerts: data['priceAlerts'] ?? true,
      defaultShippingAddressId: data['defaultShippingAddressId'] ?? '',
      defaultBillingAddressId: data['defaultBillingAddressId'] ?? '',
      defaultPaymentMethodId: data['defaultPaymentMethodId'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'language': language,
      'currency': currency,
      'timezone': timezone,
      'emailNotifications': emailNotifications,
      'pushNotifications': pushNotifications,
      'smsNotifications': smsNotifications,
      'marketingEmails': marketingEmails,
      'orderUpdates': orderUpdates,
      'promotionalOffers': promotionalOffers,
      'productRecommendations': productRecommendations,
      'priceAlerts': priceAlerts,
      'defaultShippingAddressId': defaultShippingAddressId,
      'defaultBillingAddressId': defaultBillingAddressId,
      'defaultPaymentMethodId': defaultPaymentMethodId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  UserPreferences copyWith({
    String? userId,
    String? language,
    String? currency,
    String? timezone,
    bool? emailNotifications,
    bool? pushNotifications,
    bool? smsNotifications,
    bool? marketingEmails,
    bool? orderUpdates,
    bool? promotionalOffers,
    bool? productRecommendations,
    bool? priceAlerts,
    String? defaultShippingAddressId,
    String? defaultBillingAddressId,
    String? defaultPaymentMethodId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserPreferences(
      userId: userId ?? this.userId,
      language: language ?? this.language,
      currency: currency ?? this.currency,
      timezone: timezone ?? this.timezone,
      emailNotifications: emailNotifications ?? this.emailNotifications,
      pushNotifications: pushNotifications ?? this.pushNotifications,
      smsNotifications: smsNotifications ?? this.smsNotifications,
      marketingEmails: marketingEmails ?? this.marketingEmails,
      orderUpdates: orderUpdates ?? this.orderUpdates,
      promotionalOffers: promotionalOffers ?? this.promotionalOffers,
      productRecommendations: productRecommendations ?? this.productRecommendations,
      priceAlerts: priceAlerts ?? this.priceAlerts,
      defaultShippingAddressId: defaultShippingAddressId ?? this.defaultShippingAddressId,
      defaultBillingAddressId: defaultBillingAddressId ?? this.defaultBillingAddressId,
      defaultPaymentMethodId: defaultPaymentMethodId ?? this.defaultPaymentMethodId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
