import 'package:cloud_firestore/cloud_firestore.dart';

// Loyalty tier enum
enum LoyaltyTier { bronze, silver, gold, platinum, diamond }

// Reward type enum
enum RewardType {
  discount,
  freeShipping,
  freeProduct,
  cashback,
  bonusPoints,
  exclusiveAccess,
}

// Transaction type enum
enum TransactionType { earned, redeemed, expired, bonus, adjustment }

// User loyalty account model
class UserLoyaltyAccount {
  final String id;
  final String userId;
  final LoyaltyTier currentTier;
  final int currentPoints;
  final int lifetimePoints;
  final double totalSpent;
  final int pointsToNextTier;
  final DateTime? lastPurchaseDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserLoyaltyAccount({
    required this.id,
    required this.userId,
    required this.currentTier,
    required this.currentPoints,
    required this.lifetimePoints,
    required this.totalSpent,
    required this.pointsToNextTier,
    this.lastPurchaseDate,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserLoyaltyAccount.fromMap(Map<String, dynamic> data, String docId) {
    return UserLoyaltyAccount(
      id: docId,
      userId: data['userId'] ?? '',
      currentTier: LoyaltyTier.values.firstWhere(
        (e) => e.toString().split('.').last == data['currentTier'],
        orElse: () => LoyaltyTier.bronze,
      ),
      currentPoints: data['currentPoints'] ?? 0,
      lifetimePoints: data['lifetimePoints'] ?? 0,
      totalSpent: (data['totalSpent'] as num?)?.toDouble() ?? 0.0,
      pointsToNextTier: data['pointsToNextTier'] ?? 0,
      lastPurchaseDate:
          data['lastPurchaseDate'] != null
              ? (data['lastPurchaseDate'] as Timestamp).toDate()
              : null,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'currentTier': currentTier.toString().split('.').last,
      'currentPoints': currentPoints,
      'lifetimePoints': lifetimePoints,
      'totalSpent': totalSpent,
      'pointsToNextTier': pointsToNextTier,
      'lastPurchaseDate':
          lastPurchaseDate != null
              ? Timestamp.fromDate(lastPurchaseDate!)
              : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}

// Loyalty program configuration
class LoyaltyProgram {
  final String id;
  final String name;
  final String description;
  final double pointsPerCurrency;
  final double currencyPerPoint;
  final int pointsExpiryDays;
  final double minimumSpendForPoints;
  final List<LoyaltyTier> tiers;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  LoyaltyProgram({
    required this.id,
    required this.name,
    required this.description,
    required this.pointsPerCurrency,
    required this.currencyPerPoint,
    required this.pointsExpiryDays,
    required this.minimumSpendForPoints,
    required this.tiers,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory LoyaltyProgram.fromMap(Map<String, dynamic> data, String docId) {
    return LoyaltyProgram(
      id: docId,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      pointsPerCurrency: (data['pointsPerCurrency'] as num?)?.toDouble() ?? 0.0,
      currencyPerPoint: (data['currencyPerPoint'] as num?)?.toDouble() ?? 0.0,
      pointsExpiryDays: data['pointsExpiryDays'] ?? 365,
      minimumSpendForPoints:
          (data['minimumSpendForPoints'] as num?)?.toDouble() ?? 0.0,
      tiers:
          (data['tiers'] as List<dynamic>? ?? [])
              .map(
                (tier) => LoyaltyTier.values.firstWhere(
                  (e) => e.toString().split('.').last == tier,
                  orElse: () => LoyaltyTier.bronze,
                ),
              )
              .toList(),
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'pointsPerCurrency': pointsPerCurrency,
      'currencyPerPoint': currencyPerPoint,
      'pointsExpiryDays': pointsExpiryDays,
      'minimumSpendForPoints': minimumSpendForPoints,
      'tiers': tiers.map((tier) => tier.toString().split('.').last).toList(),
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}

// Loyalty transaction model
class LoyaltyTransaction {
  final String id;
  final String userId;
  final TransactionType type;
  final int points;
  final String description;
  final String? orderId;
  final String? rewardId;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final bool isExpired;

  LoyaltyTransaction({
    required this.id,
    required this.userId,
    required this.type,
    required this.points,
    required this.description,
    this.orderId,
    this.rewardId,
    required this.createdAt,
    this.expiresAt,
    this.isExpired = false,
  });

  factory LoyaltyTransaction.fromMap(Map<String, dynamic> data, String docId) {
    return LoyaltyTransaction(
      id: docId,
      userId: data['userId'] ?? '',
      type: TransactionType.values.firstWhere(
        (e) => e.toString().split('.').last == data['type'],
        orElse: () => TransactionType.earned,
      ),
      points: data['points'] ?? 0,
      description: data['description'] ?? '',
      orderId: data['orderId'],
      rewardId: data['rewardId'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      expiresAt:
          data['expiresAt'] != null
              ? (data['expiresAt'] as Timestamp).toDate()
              : null,
      isExpired: data['isExpired'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'type': type.toString().split('.').last,
      'points': points,
      'description': description,
      'orderId': orderId,
      'rewardId': rewardId,
      'createdAt': Timestamp.fromDate(createdAt),
      'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
      'isExpired': isExpired,
    };
  }
}

class LoyaltyTierConfig {
  final String id;
  final String name;
  final String description;
  final int minPoints;
  final int maxPoints;
  final double discountPercentage;
  final List<String> benefits;
  final String? iconUrl;
  final String? color;

  LoyaltyTierConfig({
    required this.id,
    required this.name,
    required this.description,
    required this.minPoints,
    required this.maxPoints,
    required this.discountPercentage,
    required this.benefits,
    this.iconUrl,
    this.color,
  });

  factory LoyaltyTierConfig.fromMap(Map<String, dynamic> data) {
    return LoyaltyTierConfig(
      id: data['id'] ?? '',
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      minPoints: data['minPoints'] ?? 0,
      maxPoints: data['maxPoints'] ?? 0,
      discountPercentage: (data['discountPercentage'] as num?)?.toDouble() ?? 0.0,
      benefits: List<String>.from(data['benefits'] ?? []),
      iconUrl: data['iconUrl'],
      color: data['color'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'minPoints': minPoints,
      'maxPoints': maxPoints,
      'discountPercentage': discountPercentage,
      'benefits': benefits,
      'iconUrl': iconUrl,
      'color': color,
    };
  }
}

class LoyaltyPoints {
  final String id;
  final String userId;
  final int currentPoints;
  final int lifetimePoints;
  final int pointsEarned;
  final int pointsRedeemed;
  final int pointsExpired;
  final DateTime? lastEarnedDate;
  final DateTime? lastRedeemedDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  LoyaltyPoints({
    required this.id,
    required this.userId,
    required this.currentPoints,
    required this.lifetimePoints,
    required this.pointsEarned,
    required this.pointsRedeemed,
    required this.pointsExpired,
    this.lastEarnedDate,
    this.lastRedeemedDate,
    required this.createdAt,
    required this.updatedAt,
  });

  factory LoyaltyPoints.fromMap(Map<String, dynamic> data, String docId) {
    return LoyaltyPoints(
      id: docId,
      userId: data['userId'] ?? '',
      currentPoints: data['currentPoints'] ?? 0,
      lifetimePoints: data['lifetimePoints'] ?? 0,
      pointsEarned: data['pointsEarned'] ?? 0,
      pointsRedeemed: data['pointsRedeemed'] ?? 0,
      pointsExpired: data['pointsExpired'] ?? 0,
      lastEarnedDate:
          data['lastEarnedDate'] != null
              ? (data['lastEarnedDate'] as Timestamp).toDate()
              : null,
      lastRedeemedDate:
          data['lastRedeemedDate'] != null
              ? (data['lastRedeemedDate'] as Timestamp).toDate()
              : null,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'currentPoints': currentPoints,
      'lifetimePoints': lifetimePoints,
      'pointsEarned': pointsEarned,
      'pointsRedeemed': pointsRedeemed,
      'pointsExpired': pointsExpired,
      'lastEarnedDate':
          lastEarnedDate != null ? Timestamp.fromDate(lastEarnedDate!) : null,
      'lastRedeemedDate':
          lastRedeemedDate != null
              ? Timestamp.fromDate(lastRedeemedDate!)
              : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}

class PointsTransaction {
  final String id;
  final String userId;
  final String type; // 'earned', 'redeemed', 'expired', 'bonus'
  final int points;
  final String description;
  final String? orderId;
  final String? productId;
  final String? campaignId;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final bool isExpired;

  PointsTransaction({
    required this.id,
    required this.userId,
    required this.type,
    required this.points,
    required this.description,
    this.orderId,
    this.productId,
    this.campaignId,
    required this.createdAt,
    this.expiresAt,
    this.isExpired = false,
  });

  factory PointsTransaction.fromMap(Map<String, dynamic> data, String docId) {
    return PointsTransaction(
      id: docId,
      userId: data['userId'] ?? '',
      type: data['type'] ?? '',
      points: data['points'] ?? 0,
      description: data['description'] ?? '',
      orderId: data['orderId'],
      productId: data['productId'],
      campaignId: data['campaignId'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      expiresAt:
          data['expiresAt'] != null
              ? (data['expiresAt'] as Timestamp).toDate()
              : null,
      isExpired: data['isExpired'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'type': type,
      'points': points,
      'description': description,
      'orderId': orderId,
      'productId': productId,
      'campaignId': campaignId,
      'createdAt': Timestamp.fromDate(createdAt),
      'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
      'isExpired': isExpired,
    };
  }
}

class LoyaltyReward {
  final String id;
  final String name;
  final String description;
  final int pointsRequired;
  final String type; // 'discount', 'free_shipping', 'free_product', 'cashback'
  final double value;
  final String? productId;
  final int? maxRedemptions;
  final int currentRedemptions;
  final DateTime? validFrom;
  final DateTime? validUntil;
  final bool isActive;
  final String? imageUrl;
  final List<String>? applicableCategories;
  final double? minimumOrderValue;

  LoyaltyReward({
    required this.id,
    required this.name,
    required this.description,
    required this.pointsRequired,
    required this.type,
    required this.value,
    this.productId,
    this.maxRedemptions,
    required this.currentRedemptions,
    this.validFrom,
    this.validUntil,
    required this.isActive,
    this.imageUrl,
    this.applicableCategories,
    this.minimumOrderValue,
  });

  factory LoyaltyReward.fromMap(Map<String, dynamic> data, String docId) {
    return LoyaltyReward(
      id: docId,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      pointsRequired: data['pointsRequired'] ?? 0,
      type: data['type'] ?? '',
      value: (data['value'] as num?)?.toDouble() ?? 0.0,
      productId: data['productId'],
      maxRedemptions: data['maxRedemptions'],
      currentRedemptions: data['currentRedemptions'] ?? 0,
      validFrom:
          data['validFrom'] != null
              ? (data['validFrom'] as Timestamp).toDate()
              : null,
      validUntil:
          data['validUntil'] != null
              ? (data['validUntil'] as Timestamp).toDate()
              : null,
      isActive: data['isActive'] ?? true,
      imageUrl: data['imageUrl'],
      applicableCategories:
          data['applicableCategories'] != null
              ? List<String>.from(data['applicableCategories'])
              : null,
      minimumOrderValue: (data['minimumOrderValue'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'pointsRequired': pointsRequired,
      'type': type,
      'value': value,
      'productId': productId,
      'maxRedemptions': maxRedemptions,
      'currentRedemptions': currentRedemptions,
      'validFrom': validFrom != null ? Timestamp.fromDate(validFrom!) : null,
      'validUntil': validUntil != null ? Timestamp.fromDate(validUntil!) : null,
      'isActive': isActive,
      'imageUrl': imageUrl,
      'applicableCategories': applicableCategories,
      'minimumOrderValue': minimumOrderValue,
    };
  }

  // Computed properties for provider compatibility
  int get pointsCost => pointsRequired;
  bool get isAvailable =>
      isActive &&
      (maxRedemptions == null || currentRedemptions < maxRedemptions!);
  RewardType get rewardType {
    switch (type) {
      case 'discount':
        return RewardType.discount;
      case 'free_shipping':
        return RewardType.freeShipping;
      case 'free_product':
        return RewardType.freeProduct;
      case 'cashback':
        return RewardType.cashback;
      case 'bonus_points':
        return RewardType.bonusPoints;
      case 'exclusive_access':
        return RewardType.exclusiveAccess;
      default:
        return RewardType.discount;
    }
  }
}

class RewardRedemption {
  final String id;
  final String userId;
  final String rewardId;
  final String rewardName;
  final int pointsSpent;
  final DateTime redeemedAt;
  final DateTime? usedAt;
  final bool isUsed;
  final String? orderId;
  final String? code;

  RewardRedemption({
    required this.id,
    required this.userId,
    required this.rewardId,
    required this.rewardName,
    required this.pointsSpent,
    required this.redeemedAt,
    this.usedAt,
    required this.isUsed,
    this.orderId,
    this.code,
  });

  factory RewardRedemption.fromMap(Map<String, dynamic> data, String docId) {
    return RewardRedemption(
      id: docId,
      userId: data['userId'] ?? '',
      rewardId: data['rewardId'] ?? '',
      rewardName: data['rewardName'] ?? '',
      pointsSpent: data['pointsSpent'] ?? 0,
      redeemedAt: (data['redeemedAt'] as Timestamp).toDate(),
      usedAt:
          data['usedAt'] != null
              ? (data['usedAt'] as Timestamp).toDate()
              : null,
      isUsed: data['isUsed'] ?? false,
      orderId: data['orderId'],
      code: data['code'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'rewardId': rewardId,
      'rewardName': rewardName,
      'pointsSpent': pointsSpent,
      'redeemedAt': Timestamp.fromDate(redeemedAt),
      'usedAt': usedAt != null ? Timestamp.fromDate(usedAt!) : null,
      'isUsed': isUsed,
      'orderId': orderId,
      'code': code,
    };
  }
}
