class CartItemModel {
  final String id;
  final String name;
  final double price;
  final double? originalPrice; // For showing discounts
  final int quantity;
  final String sellerId;
  final String? image;
  final String? variant;
  final String? category;
  final double? weight; // For shipping calculations
  final Map<String, dynamic>? specifications;
  final bool isAvailable;
  final int? maxQuantity; // Stock limit
  final DateTime? addedAt;
  final bool isSavedForLater;

  CartItemModel({
    required this.id,
    required this.name,
    required this.price,
    this.originalPrice,
    required this.quantity,
    required this.sellerId,
    this.image,
    this.variant,
    this.category,
    this.weight,
    this.specifications,
    this.isAvailable = true,
    this.maxQuantity,
    this.addedAt,
    this.isSavedForLater = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'originalPrice': originalPrice,
      'quantity': quantity,
      'sellerId': sellerId,
      'image': image,
      'variant': variant,
      'category': category,
      'weight': weight,
      'specifications': specifications,
      'isAvailable': isAvailable,
      'maxQuantity': maxQuantity,
      'addedAt': addedAt?.millisecondsSinceEpoch,
      'isSavedForLater': isSavedForLater,
    };
  }

  factory CartItemModel.fromMap(Map<String, dynamic> map) {
    return CartItemModel(
      id: map['id'] as String,
      name: map['name'] as String,
      price: (map['price'] as num).toDouble(),
      originalPrice: (map['originalPrice'] as num?)?.toDouble(),
      quantity: map['quantity'] as int,
      sellerId: map['sellerId'] as String,
      image: map['image'] as String?,
      variant: map['variant'] as String?,
      category: map['category'] as String?,
      weight: (map['weight'] as num?)?.toDouble(),
      specifications: map['specifications'] as Map<String, dynamic>?,
      isAvailable: map['isAvailable'] ?? true,
      maxQuantity: map['maxQuantity'] as int?,
      addedAt:
          map['addedAt'] != null
              ? DateTime.fromMillisecondsSinceEpoch(map['addedAt'])
              : null,
      isSavedForLater: map['isSavedForLater'] ?? false,
    );
  }

  // Helper methods
  bool get hasDiscount => originalPrice != null && originalPrice! > price;

  double get discountAmount => hasDiscount ? originalPrice! - price : 0.0;

  double get discountPercentage =>
      hasDiscount ? ((originalPrice! - price) / originalPrice!) * 100 : 0.0;

  double get totalPrice => price * quantity;

  double get totalOriginalPrice => (originalPrice ?? price) * quantity;

  double get totalSavings => totalOriginalPrice - totalPrice;

  bool get isOutOfStock => !isAvailable;

  bool get isQuantityExceeded => maxQuantity != null && quantity > maxQuantity!;

  String get formattedPrice => 'TZS ${price.toStringAsFixed(0)}';

  String get formattedOriginalPrice =>
      originalPrice != null ? 'TZS ${originalPrice!.toStringAsFixed(0)}' : '';

  String get formattedTotalPrice => 'TZS ${totalPrice.toStringAsFixed(0)}';

  CartItemModel copyWith({
    String? id,
    String? name,
    double? price,
    double? originalPrice,
    int? quantity,
    String? sellerId,
    String? image,
    String? variant,
    String? category,
    double? weight,
    Map<String, dynamic>? specifications,
    bool? isAvailable,
    int? maxQuantity,
    DateTime? addedAt,
    bool? isSavedForLater,
  }) {
    return CartItemModel(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      originalPrice: originalPrice ?? this.originalPrice,
      quantity: quantity ?? this.quantity,
      sellerId: sellerId ?? this.sellerId,
      image: image ?? this.image,
      variant: variant ?? this.variant,
      category: category ?? this.category,
      weight: weight ?? this.weight,
      specifications: specifications ?? this.specifications,
      isAvailable: isAvailable ?? this.isAvailable,
      maxQuantity: maxQuantity ?? this.maxQuantity,
      addedAt: addedAt ?? this.addedAt,
      isSavedForLater: isSavedForLater ?? this.isSavedForLater,
    );
  }
}
