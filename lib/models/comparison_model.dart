import 'package:cloud_firestore/cloud_firestore.dart';
import 'product_model.dart';

class ComparisonItem {
  final String id;
  final String userId;
  final String productId;
  final String productName;
  final String productImage;
  final double productPrice;
  final String category;
  final double? rating;
  final int reviewCount;
  final Map<String, dynamic> specifications;
  final DateTime addedAt;
  final int position; // For ordering in comparison

  ComparisonItem({
    required this.id,
    required this.userId,
    required this.productId,
    required this.productName,
    required this.productImage,
    required this.productPrice,
    required this.category,
    this.rating,
    this.reviewCount = 0,
    this.specifications = const {},
    required this.addedAt,
    this.position = 0,
  });

  factory ComparisonItem.fromProduct(ProductModel product, String userId, int position) {
    return ComparisonItem(
      id: '${userId}_${product.id}',
      userId: userId,
      productId: product.id,
      productName: product.name,
      productImage: product.images.isNotEmpty ? product.images.first : '',
      productPrice: product.price,
      category: product.category,
      rating: product.rating,
      reviewCount: product.totalReviews ?? 0,
      specifications: _extractSpecifications(product),
      addedAt: DateTime.now(),
      position: position,
    );
  }

  factory ComparisonItem.fromMap(Map<String, dynamic> data, String id) {
    return ComparisonItem(
      id: id,
      userId: data['userId'] ?? '',
      productId: data['productId'] ?? '',
      productName: data['productName'] ?? '',
      productImage: data['productImage'] ?? '',
      productPrice: (data['productPrice'] as num?)?.toDouble() ?? 0.0,
      category: data['category'] ?? '',
      rating: (data['rating'] as num?)?.toDouble(),
      reviewCount: data['reviewCount'] ?? 0,
      specifications: Map<String, dynamic>.from(data['specifications'] ?? {}),
      addedAt: (data['addedAt'] as Timestamp).toDate(),
      position: data['position'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'productId': productId,
      'productName': productName,
      'productImage': productImage,
      'productPrice': productPrice,
      'category': category,
      'rating': rating,
      'reviewCount': reviewCount,
      'specifications': specifications,
      'addedAt': Timestamp.fromDate(addedAt),
      'position': position,
    };
  }

  static Map<String, dynamic> _extractSpecifications(ProductModel product) {
    final specs = <String, dynamic>{};
    
    // Basic specifications
    specs['Price'] = 'TZS ${product.price.toStringAsFixed(0)}';
    specs['Category'] = product.category;
    specs['Brand'] = product.brand ?? 'Unknown';
    specs['Stock'] = product.stock > 0 ? 'In Stock (${product.stock})' : 'Out of Stock';
    specs['Rating'] = product.rating != null ? '${product.rating!.toStringAsFixed(1)} ⭐' : 'No Rating';
    specs['Reviews'] = '${product.totalReviews ?? 0} reviews';
    
    // Compatibility
    if (product.compatibility.isNotEmpty) {
      specs['Compatibility'] = product.compatibility.join(', ');
    }
    
    // Additional specifications from product description
    // This could be enhanced to parse structured specifications
    if (product.description.isNotEmpty) {
      specs['Description Length'] = '${product.description.length} characters';
    }
    
    // Image count
    specs['Images'] = '${product.images.length} image${product.images.length == 1 ? '' : 's'}';
    
    return specs;
  }

  ComparisonItem copyWith({
    String? id,
    String? userId,
    String? productId,
    String? productName,
    String? productImage,
    double? productPrice,
    String? category,
    double? rating,
    int? reviewCount,
    Map<String, dynamic>? specifications,
    DateTime? addedAt,
    int? position,
  }) {
    return ComparisonItem(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      productImage: productImage ?? this.productImage,
      productPrice: productPrice ?? this.productPrice,
      category: category ?? this.category,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      specifications: specifications ?? this.specifications,
      addedAt: addedAt ?? this.addedAt,
      position: position ?? this.position,
    );
  }
}

class ComparisonSet {
  final String id;
  final String userId;
  final String name;
  final String? description;
  final List<String> productIds;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isShared;
  final String? shareCode;

  ComparisonSet({
    required this.id,
    required this.userId,
    required this.name,
    this.description,
    this.productIds = const [],
    required this.createdAt,
    this.updatedAt,
    this.isShared = false,
    this.shareCode,
  });

  factory ComparisonSet.fromMap(Map<String, dynamic> data, String id) {
    return ComparisonSet(
      id: id,
      userId: data['userId'] ?? '',
      name: data['name'] ?? '',
      description: data['description'],
      productIds: List<String>.from(data['productIds'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
      isShared: data['isShared'] ?? false,
      shareCode: data['shareCode'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'description': description,
      'productIds': productIds,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'isShared': isShared,
      'shareCode': shareCode,
    };
  }

  ComparisonSet copyWith({
    String? id,
    String? userId,
    String? name,
    String? description,
    List<String>? productIds,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isShared,
    String? shareCode,
  }) {
    return ComparisonSet(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      description: description ?? this.description,
      productIds: productIds ?? this.productIds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isShared: isShared ?? this.isShared,
      shareCode: shareCode ?? this.shareCode,
    );
  }

  int get itemCount => productIds.length;
  bool get isEmpty => productIds.isEmpty;
  bool get isNotEmpty => productIds.isNotEmpty;
  bool get isFull => productIds.length >= 4; // Max 4 products for comparison
}

// Comparison analysis result
class ComparisonAnalysis {
  final String bestValue; // Product ID with best price/feature ratio
  final String highestRated; // Product ID with highest rating
  final String cheapest; // Product ID with lowest price
  final String mostExpensive; // Product ID with highest price
  final Map<String, List<String>> categoryWinners; // Category -> List of product IDs
  final List<String> commonFeatures; // Features all products share
  final Map<String, String> uniqueFeatures; // Product ID -> unique feature

  ComparisonAnalysis({
    required this.bestValue,
    required this.highestRated,
    required this.cheapest,
    required this.mostExpensive,
    required this.categoryWinners,
    required this.commonFeatures,
    required this.uniqueFeatures,
  });

  static ComparisonAnalysis analyze(List<ComparisonItem> items) {
    if (items.isEmpty) {
      return ComparisonAnalysis(
        bestValue: '',
        highestRated: '',
        cheapest: '',
        mostExpensive: '',
        categoryWinners: {},
        commonFeatures: [],
        uniqueFeatures: {},
      );
    }

    // Find cheapest and most expensive
    final sortedByPrice = List<ComparisonItem>.from(items)
      ..sort((a, b) => a.productPrice.compareTo(b.productPrice));
    final cheapest = sortedByPrice.first.productId;
    final mostExpensive = sortedByPrice.last.productId;

    // Find highest rated
    final ratedItems = items.where((item) => item.rating != null).toList();
    String highestRated = '';
    if (ratedItems.isNotEmpty) {
      ratedItems.sort((a, b) => (b.rating ?? 0).compareTo(a.rating ?? 0));
      highestRated = ratedItems.first.productId;
    }

    // Calculate best value (rating/price ratio)
    String bestValue = '';
    double bestRatio = 0;
    for (final item in ratedItems) {
      if (item.rating != null && item.productPrice > 0) {
        final ratio = item.rating! / item.productPrice;
        if (ratio > bestRatio) {
          bestRatio = ratio;
          bestValue = item.productId;
        }
      }
    }

    // Find common features
    final allSpecs = items.map((item) => item.specifications.keys.toSet()).toList();
    final commonFeatures = allSpecs.isNotEmpty
        ? allSpecs.reduce((a, b) => a.intersection(b)).toList()
        : <String>[];

    // Find unique features
    final uniqueFeatures = <String, String>{};
    for (final item in items) {
      final uniqueKeys = item.specifications.keys
          .where((key) => !commonFeatures.contains(key))
          .toList();
      if (uniqueKeys.isNotEmpty) {
        uniqueFeatures[item.productId] = uniqueKeys.join(', ');
      }
    }

    return ComparisonAnalysis(
      bestValue: bestValue,
      highestRated: highestRated,
      cheapest: cheapest,
      mostExpensive: mostExpensive,
      categoryWinners: {}, // Could be enhanced for specific categories
      commonFeatures: commonFeatures,
      uniqueFeatures: uniqueFeatures,
    );
  }
}
