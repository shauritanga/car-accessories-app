import 'package:cloud_firestore/cloud_firestore.dart';

enum ShippingType {
  standard,
  express,
  overnight,
  sameDay,
  pickup,
}

enum ShippingStatus {
  pending,
  processing,
  shipped,
  inTransit,
  outForDelivery,
  delivered,
  failed,
  returned,
}

class ShippingMethod {
  final String id;
  final String name;
  final String description;
  final ShippingType type;
  final double cost;
  final int estimatedDaysMin;
  final int estimatedDaysMax;
  final bool isAvailable;
  final String? trackingProvider;
  final Map<String, dynamic>? restrictions; // Weight, size, location restrictions
  final String? icon;

  ShippingMethod({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.cost,
    required this.estimatedDaysMin,
    required this.estimatedDaysMax,
    this.isAvailable = true,
    this.trackingProvider,
    this.restrictions,
    this.icon,
  });

  factory ShippingMethod.fromMap(Map<String, dynamic> data, String id) {
    return ShippingMethod(
      id: id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      type: ShippingType.values.firstWhere(
        (e) => e.toString() == data['type'],
        orElse: () => ShippingType.standard,
      ),
      cost: (data['cost'] as num?)?.toDouble() ?? 0.0,
      estimatedDaysMin: data['estimatedDaysMin'] ?? 1,
      estimatedDaysMax: data['estimatedDaysMax'] ?? 3,
      isAvailable: data['isAvailable'] ?? true,
      trackingProvider: data['trackingProvider'],
      restrictions: data['restrictions'],
      icon: data['icon'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'type': type.toString(),
      'cost': cost,
      'estimatedDaysMin': estimatedDaysMin,
      'estimatedDaysMax': estimatedDaysMax,
      'isAvailable': isAvailable,
      'trackingProvider': trackingProvider,
      'restrictions': restrictions,
      'icon': icon,
    };
  }

  String get estimatedDelivery {
    if (estimatedDaysMin == estimatedDaysMax) {
      return '$estimatedDaysMin ${estimatedDaysMin == 1 ? 'day' : 'days'}';
    }
    return '$estimatedDaysMin-$estimatedDaysMax days';
  }

  DateTime get estimatedDeliveryDate {
    return DateTime.now().add(Duration(days: estimatedDaysMax));
  }

  String get formattedCost {
    return 'TZS ${cost.toStringAsFixed(0)}';
  }
}

class ShippingAddress {
  final String id;
  final String userId;
  final String fullName;
  final String phoneNumber;
  final String addressLine1;
  final String addressLine2;
  final String city;
  final String state;
  final String postalCode;
  final String country;
  final double? latitude;
  final double? longitude;
  final bool isDefault;
  final DateTime createdAt;
  final DateTime? updatedAt;

  ShippingAddress({
    required this.id,
    required this.userId,
    required this.fullName,
    required this.phoneNumber,
    required this.addressLine1,
    this.addressLine2 = '',
    required this.city,
    required this.state,
    required this.postalCode,
    required this.country,
    this.latitude,
    this.longitude,
    this.isDefault = false,
    required this.createdAt,
    this.updatedAt,
  });

  factory ShippingAddress.fromMap(Map<String, dynamic> data, String id) {
    return ShippingAddress(
      id: id,
      userId: data['userId'] ?? '',
      fullName: data['fullName'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
      addressLine1: data['addressLine1'] ?? '',
      addressLine2: data['addressLine2'] ?? '',
      city: data['city'] ?? '',
      state: data['state'] ?? '',
      postalCode: data['postalCode'] ?? '',
      country: data['country'] ?? '',
      latitude: data['latitude']?.toDouble(),
      longitude: data['longitude']?.toDouble(),
      isDefault: data['isDefault'] ?? false,
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
      'addressLine1': addressLine1,
      'addressLine2': addressLine2,
      'city': city,
      'state': state,
      'postalCode': postalCode,
      'country': country,
      'latitude': latitude,
      'longitude': longitude,
      'isDefault': isDefault,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  String get formattedAddress {
    final parts = <String>[
      addressLine1,
      if (addressLine2.isNotEmpty) addressLine2,
      city,
      state,
      postalCode,
      country,
    ];
    return parts.join(', ');
  }

  String get shortAddress {
    return '$city, $state $postalCode';
  }
}

class ShippingTracking {
  final String id;
  final String orderId;
  final String trackingNumber;
  final String carrier;
  final ShippingStatus status;
  final List<TrackingEvent> events;
  final DateTime? estimatedDelivery;
  final DateTime? actualDelivery;
  final String? deliveryNotes;
  final DateTime createdAt;
  final DateTime? updatedAt;

  ShippingTracking({
    required this.id,
    required this.orderId,
    required this.trackingNumber,
    required this.carrier,
    required this.status,
    this.events = const [],
    this.estimatedDelivery,
    this.actualDelivery,
    this.deliveryNotes,
    required this.createdAt,
    this.updatedAt,
  });

  factory ShippingTracking.fromMap(Map<String, dynamic> data, String id) {
    return ShippingTracking(
      id: id,
      orderId: data['orderId'] ?? '',
      trackingNumber: data['trackingNumber'] ?? '',
      carrier: data['carrier'] ?? '',
      status: ShippingStatus.values.firstWhere(
        (e) => e.toString() == data['status'],
        orElse: () => ShippingStatus.pending,
      ),
      events: (data['events'] as List?)
              ?.map((e) => TrackingEvent.fromMap(e))
              .toList() ??
          [],
      estimatedDelivery: data['estimatedDelivery'] != null
          ? (data['estimatedDelivery'] as Timestamp).toDate()
          : null,
      actualDelivery: data['actualDelivery'] != null
          ? (data['actualDelivery'] as Timestamp).toDate()
          : null,
      deliveryNotes: data['deliveryNotes'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'orderId': orderId,
      'trackingNumber': trackingNumber,
      'carrier': carrier,
      'status': status.toString(),
      'events': events.map((e) => e.toMap()).toList(),
      'estimatedDelivery': estimatedDelivery != null
          ? Timestamp.fromDate(estimatedDelivery!)
          : null,
      'actualDelivery': actualDelivery != null
          ? Timestamp.fromDate(actualDelivery!)
          : null,
      'deliveryNotes': deliveryNotes,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  bool get isDelivered => status == ShippingStatus.delivered;
  bool get isInTransit => status == ShippingStatus.inTransit || status == ShippingStatus.outForDelivery;
  bool get hasIssue => status == ShippingStatus.failed || status == ShippingStatus.returned;
}

class TrackingEvent {
  final String status;
  final String description;
  final String? location;
  final DateTime timestamp;

  TrackingEvent({
    required this.status,
    required this.description,
    this.location,
    required this.timestamp,
  });

  factory TrackingEvent.fromMap(Map<String, dynamic> data) {
    return TrackingEvent(
      status: data['status'] ?? '',
      description: data['description'] ?? '',
      location: data['location'],
      timestamp: (data['timestamp'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'status': status,
      'description': description,
      'location': location,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}
