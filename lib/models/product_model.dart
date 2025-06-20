import 'package:cloud_firestore/cloud_firestore.dart';

// Supporting classes for enhanced product information
class ProductVariant {
  final String id;
  final String name;
  final String type; // 'color', 'size', 'material', etc.
  final String value;
  final double? priceAdjustment;
  final int stock;
  final String? image;

  ProductVariant({
    required this.id,
    required this.name,
    required this.type,
    required this.value,
    this.priceAdjustment,
    required this.stock,
    this.image,
  });

  factory ProductVariant.fromMap(Map<String, dynamic> data) {
    return ProductVariant(
      id: data['id'] ?? '',
      name: data['name'] ?? '',
      type: data['type'] ?? '',
      value: data['value'] ?? '',
      priceAdjustment: (data['priceAdjustment'] as num?)?.toDouble(),
      stock: data['stock'] ?? 0,
      image: data['image'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'value': value,
      'priceAdjustment': priceAdjustment,
      'stock': stock,
      'image': image,
    };
  }
}

class ShippingInfo {
  final double weight;
  final Map<String, double> dimensions; // width, height, depth
  final List<String> shippingMethods;
  final Map<String, double> shippingCosts;
  final int estimatedDeliveryDays;
  final bool freeShippingEligible;

  ShippingInfo({
    required this.weight,
    required this.dimensions,
    required this.shippingMethods,
    required this.shippingCosts,
    required this.estimatedDeliveryDays,
    this.freeShippingEligible = false,
  });

  factory ShippingInfo.fromMap(Map<String, dynamic> data) {
    return ShippingInfo(
      weight: (data['weight'] as num?)?.toDouble() ?? 0.0,
      dimensions: Map<String, double>.from(data['dimensions'] ?? {}),
      shippingMethods: List<String>.from(data['shippingMethods'] ?? []),
      shippingCosts: Map<String, double>.from(data['shippingCosts'] ?? {}),
      estimatedDeliveryDays: data['estimatedDeliveryDays'] ?? 7,
      freeShippingEligible: data['freeShippingEligible'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'weight': weight,
      'dimensions': dimensions,
      'shippingMethods': shippingMethods,
      'shippingCosts': shippingCosts,
      'estimatedDeliveryDays': estimatedDeliveryDays,
      'freeShippingEligible': freeShippingEligible,
    };
  }
}

class ReturnPolicy {
  final bool returnable;
  final int returnPeriodDays;
  final String returnConditions;
  final bool freeReturns;
  final String returnInstructions;

  ReturnPolicy({
    required this.returnable,
    required this.returnPeriodDays,
    required this.returnConditions,
    this.freeReturns = false,
    required this.returnInstructions,
  });

  factory ReturnPolicy.fromMap(Map<String, dynamic> data) {
    return ReturnPolicy(
      returnable: data['returnable'] ?? false,
      returnPeriodDays: data['returnPeriodDays'] ?? 30,
      returnConditions: data['returnConditions'] ?? '',
      freeReturns: data['freeReturns'] ?? false,
      returnInstructions: data['returnInstructions'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'returnable': returnable,
      'returnPeriodDays': returnPeriodDays,
      'returnConditions': returnConditions,
      'freeReturns': freeReturns,
      'returnInstructions': returnInstructions,
    };
  }
}

class ProductModel {
  final String id;
  final String name;
  final String description;
  final double price;
  final double? originalPrice; // For showing discounts
  final int stock;
  final String category;
  final String? brand;
  final String? model;
  final String? sku;
  final List<String> compatibility; // Car models
  final String sellerId;
  final List<String> images;
  final List<String>? videos; // Product videos
  final double? rating;
  final double? averageRating;
  final int? totalReviews;
  final Map<int, int>? ratingDistribution;
  final Map<String, dynamic>? specifications; // Detailed specs
  final List<ProductVariant>? variants; // Size, color, etc.
  final ShippingInfo? shippingInfo;
  final ReturnPolicy? returnPolicy;
  final List<String>? tags; // Search tags
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool isActive;
  final int viewCount; // Track popularity

  ProductModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.originalPrice,
    required this.stock,
    required this.category,
    this.brand,
    this.model,
    this.sku,
    required this.compatibility,
    required this.sellerId,
    required this.images,
    this.videos,
    this.rating,
    this.averageRating,
    this.totalReviews,
    this.ratingDistribution,
    this.specifications,
    this.variants,
    this.shippingInfo,
    this.returnPolicy,
    this.tags,
    this.createdAt,
    this.updatedAt,
    this.isActive = true,
    this.viewCount = 0,
  });

  factory ProductModel.fromMap(Map<String, dynamic> data) {
    return ProductModel(
      id: data['id'] ?? '',
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      originalPrice: (data['originalPrice'] as num?)?.toDouble(),
      category: data['category'] ?? '',
      brand: data['brand'],
      model: data['model'],
      sku: data['sku'],
      stock: data['stock'] ?? 0,
      compatibility: List<String>.from(data['compatibility'] ?? []),
      sellerId: data['sellerId'] ?? '',
      images: List<String>.from(data['images'] ?? []),
      videos: data['videos'] != null ? List<String>.from(data['videos']) : null,
      rating: (data['rating'] as num?)?.toDouble(),
      averageRating: (data['averageRating'] as num?)?.toDouble(),
      totalReviews: data['totalReviews'],
      ratingDistribution:
          data['ratingDistribution'] != null
              ? Map<int, int>.from(data['ratingDistribution'])
              : null,
      specifications:
          data['specifications'] != null
              ? Map<String, dynamic>.from(data['specifications'])
              : null,
      variants:
          data['variants'] != null
              ? (data['variants'] as List)
                  .map((v) => ProductVariant.fromMap(v))
                  .toList()
              : null,
      shippingInfo:
          data['shippingInfo'] != null
              ? ShippingInfo.fromMap(data['shippingInfo'])
              : null,
      returnPolicy:
          data['returnPolicy'] != null
              ? ReturnPolicy.fromMap(data['returnPolicy'])
              : null,
      tags: data['tags'] != null ? List<String>.from(data['tags']) : null,
      createdAt:
          data['createdAt'] != null
              ? (data['createdAt'] as Timestamp).toDate()
              : null,
      updatedAt:
          data['updatedAt'] != null
              ? (data['updatedAt'] as Timestamp).toDate()
              : null,
      isActive: data['isActive'] ?? true,
      viewCount: data['viewCount'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'originalPrice': originalPrice,
      'category': category,
      'brand': brand,
      'model': model,
      'sku': sku,
      'compatibility': compatibility,
      'stock': stock,
      'sellerId': sellerId,
      'images': images,
      'videos': videos,
      'rating': rating,
      'averageRating': averageRating,
      'totalReviews': totalReviews,
      'ratingDistribution': ratingDistribution,
      'specifications': specifications,
      'variants': variants?.map((v) => v.toMap()).toList(),
      'shippingInfo': shippingInfo?.toMap(),
      'returnPolicy': returnPolicy?.toMap(),
      'tags': tags,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'isActive': isActive,
      'viewCount': viewCount,
    };
  }

  // Helper methods
  bool get hasDiscount => originalPrice != null && originalPrice! > price;

  double get discountPercentage {
    if (!hasDiscount) return 0.0;
    return ((originalPrice! - price) / originalPrice!) * 100;
  }

  double get discountAmount {
    if (!hasDiscount) return 0.0;
    return originalPrice! - price;
  }

  bool get isInStock => stock > 0;

  bool get isLowStock => stock > 0 && stock <= 5;

  String get stockStatus {
    if (stock == 0) return 'Out of Stock';
    if (stock <= 5) return 'Low Stock';
    return 'In Stock';
  }
}
