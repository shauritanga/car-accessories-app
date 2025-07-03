import 'package:cloud_firestore/cloud_firestore.dart';

enum CouponType { percentage, fixedAmount, freeShipping, buyOneGetOne }

enum CouponStatus { active, inactive, expired, used }

class Coupon {
  final String id;
  final String code;
  final String name;
  final String description;
  final CouponType type;
  final double value; // Percentage or fixed amount
  final double? minimumOrderAmount;
  final double? maximumDiscountAmount;
  final int? usageLimit;
  final int usageCount;
  final int? userUsageLimit; // Per user limit
  final List<String>? applicableCategories;
  final List<String>? applicableProducts;
  final List<String>? excludedCategories;
  final List<String>? excludedProducts;
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;
  final bool isFirstTimeUser;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? sellerId;

  Coupon({
    required this.id,
    required this.code,
    required this.name,
    required this.description,
    required this.type,
    required this.value,
    this.minimumOrderAmount,
    this.maximumDiscountAmount,
    this.usageLimit,
    this.usageCount = 0,
    this.userUsageLimit,
    this.applicableCategories,
    this.applicableProducts,
    this.excludedCategories,
    this.excludedProducts,
    required this.startDate,
    required this.endDate,
    this.isActive = true,
    this.isFirstTimeUser = false,
    this.createdBy,
    required this.createdAt,
    this.updatedAt,
    this.sellerId,
  });

  factory Coupon.fromMap(Map<String, dynamic> data, String id) {
    return Coupon(
      id: id,
      code: data['code'] ?? '',
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      type: CouponType.values.firstWhere(
        (e) => e.toString() == data['type'],
        orElse: () => CouponType.percentage,
      ),
      value: (data['value'] as num?)?.toDouble() ?? 0.0,
      minimumOrderAmount: (data['minimumOrderAmount'] as num?)?.toDouble(),
      maximumDiscountAmount:
          (data['maximumDiscountAmount'] as num?)?.toDouble(),
      usageLimit: data['usageLimit'],
      usageCount: data['usageCount'] ?? 0,
      userUsageLimit: data['userUsageLimit'],
      applicableCategories:
          (data['applicableCategories'] as List?)?.cast<String>(),
      applicableProducts: (data['applicableProducts'] as List?)?.cast<String>(),
      excludedCategories: (data['excludedCategories'] as List?)?.cast<String>(),
      excludedProducts: (data['excludedProducts'] as List?)?.cast<String>(),
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp).toDate(),
      isActive: data['isActive'] ?? true,
      isFirstTimeUser: data['isFirstTimeUser'] ?? false,
      createdBy: data['createdBy'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt:
          data['updatedAt'] != null
              ? (data['updatedAt'] as Timestamp).toDate()
              : null,
      sellerId: data['sellerId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'code': code,
      'name': name,
      'description': description,
      'type': type.toString(),
      'value': value,
      'minimumOrderAmount': minimumOrderAmount,
      'maximumDiscountAmount': maximumDiscountAmount,
      'usageLimit': usageLimit,
      'usageCount': usageCount,
      'userUsageLimit': userUsageLimit,
      'applicableCategories': applicableCategories,
      'applicableProducts': applicableProducts,
      'excludedCategories': excludedCategories,
      'excludedProducts': excludedProducts,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'isActive': isActive,
      'isFirstTimeUser': isFirstTimeUser,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      if (sellerId != null) 'sellerId': sellerId,
    };
  }

  bool get isExpired => DateTime.now().isAfter(endDate);
  bool get isNotStarted => DateTime.now().isBefore(startDate);
  bool get isUsageLimitReached =>
      usageLimit != null && usageCount >= usageLimit!;

  CouponStatus get status {
    if (!isActive) return CouponStatus.inactive;
    if (isExpired) return CouponStatus.expired;
    if (isUsageLimitReached) return CouponStatus.used;
    return CouponStatus.active;
  }

  bool get isValid {
    return isActive && !isExpired && !isNotStarted && !isUsageLimitReached;
  }

  String get formattedValue {
    switch (type) {
      case CouponType.percentage:
        return '${value.toInt()}% OFF';
      case CouponType.fixedAmount:
        return 'TZS ${value.toStringAsFixed(0)} OFF';
      case CouponType.freeShipping:
        return 'FREE SHIPPING';
      case CouponType.buyOneGetOne:
        return 'BUY 1 GET 1';
    }
  }

  String get formattedMinimumOrder {
    if (minimumOrderAmount == null) return '';
    return 'Min. order TZS ${minimumOrderAmount!.toStringAsFixed(0)}';
  }

  Coupon copyWith({
    String? id,
    String? code,
    String? name,
    String? description,
    CouponType? type,
    double? value,
    double? minimumOrderAmount,
    double? maximumDiscountAmount,
    int? usageLimit,
    int? usageCount,
    int? userUsageLimit,
    List<String>? applicableCategories,
    List<String>? applicableProducts,
    List<String>? excludedCategories,
    List<String>? excludedProducts,
    DateTime? startDate,
    DateTime? endDate,
    bool? isActive,
    bool? isFirstTimeUser,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? sellerId,
  }) {
    return Coupon(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      value: value ?? this.value,
      minimumOrderAmount: minimumOrderAmount ?? this.minimumOrderAmount,
      maximumDiscountAmount:
          maximumDiscountAmount ?? this.maximumDiscountAmount,
      usageLimit: usageLimit ?? this.usageLimit,
      usageCount: usageCount ?? this.usageCount,
      userUsageLimit: userUsageLimit ?? this.userUsageLimit,
      applicableCategories: applicableCategories ?? this.applicableCategories,
      applicableProducts: applicableProducts ?? this.applicableProducts,
      excludedCategories: excludedCategories ?? this.excludedCategories,
      excludedProducts: excludedProducts ?? this.excludedProducts,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isActive: isActive ?? this.isActive,
      isFirstTimeUser: isFirstTimeUser ?? this.isFirstTimeUser,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      sellerId: sellerId ?? this.sellerId,
    );
  }
}

class CouponUsage {
  final String id;
  final String couponId;
  final String userId;
  final String orderId;
  final double discountAmount;
  final DateTime usedAt;

  CouponUsage({
    required this.id,
    required this.couponId,
    required this.userId,
    required this.orderId,
    required this.discountAmount,
    required this.usedAt,
  });

  factory CouponUsage.fromMap(Map<String, dynamic> data, String id) {
    return CouponUsage(
      id: id,
      couponId: data['couponId'] ?? '',
      userId: data['userId'] ?? '',
      orderId: data['orderId'] ?? '',
      discountAmount: (data['discountAmount'] as num?)?.toDouble() ?? 0.0,
      usedAt: (data['usedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'couponId': couponId,
      'userId': userId,
      'orderId': orderId,
      'discountAmount': discountAmount,
      'usedAt': Timestamp.fromDate(usedAt),
    };
  }
}

class DiscountCalculation {
  final double originalAmount;
  final double discountAmount;
  final double finalAmount;
  final String? couponCode;
  final CouponType? discountType;
  final String description;

  DiscountCalculation({
    required this.originalAmount,
    required this.discountAmount,
    required this.finalAmount,
    this.couponCode,
    this.discountType,
    required this.description,
  });

  bool get hasDiscount => discountAmount > 0;

  double get discountPercentage {
    if (originalAmount == 0) return 0;
    return (discountAmount / originalAmount) * 100;
  }

  String get formattedDiscount {
    if (discountType == CouponType.percentage) {
      return '${discountPercentage.toStringAsFixed(1)}% OFF';
    }
    return 'TZS ${discountAmount.toStringAsFixed(0)} OFF';
  }
}

// Predefined coupons for the app
class PredefinedCoupons {
  static List<Coupon> getDefaultCoupons() {
    final now = DateTime.now();
    final futureDate = now.add(const Duration(days: 30));

    return [
      Coupon(
        id: 'welcome10',
        code: 'WELCOME10',
        name: 'Welcome Discount',
        description: 'Get 10% off your first order',
        type: CouponType.percentage,
        value: 10,
        minimumOrderAmount: 50000,
        maximumDiscountAmount: 20000,
        usageLimit: 1000,
        userUsageLimit: 1,
        startDate: now,
        endDate: futureDate,
        isFirstTimeUser: true,
        createdAt: now,
      ),
      Coupon(
        id: 'freeship',
        code: 'FREESHIP',
        name: 'Free Shipping',
        description: 'Free shipping on orders over TZS 100,000',
        type: CouponType.freeShipping,
        value: 0,
        minimumOrderAmount: 100000,
        startDate: now,
        endDate: futureDate,
        createdAt: now,
      ),
      Coupon(
        id: 'save20',
        code: 'SAVE20',
        name: 'Save TZS 20,000',
        description: 'Get TZS 20,000 off orders over TZS 200,000',
        type: CouponType.fixedAmount,
        value: 20000,
        minimumOrderAmount: 200000,
        usageLimit: 500,
        startDate: now,
        endDate: futureDate,
        createdAt: now,
      ),
    ];
  }
}
