class CartItemModel {
  final String id;
  final String name;
  final double price;
  final int quantity;
  final String sellerId;
  final String? image;
  final String? variant;

  CartItemModel({
    required this.id,
    required this.name,
    required this.price,
    required this.quantity,
    required this.sellerId,
    this.image,
    this.variant,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'quantity': quantity,
      'sellerId': sellerId,
      'image': image,
      'variant': variant,
    };
  }

  factory CartItemModel.fromMap(Map<String, dynamic> map) {
    return CartItemModel(
      id: map['id'] as String,
      name: map['name'] as String,
      price: (map['price'] as num).toDouble(),
      quantity: map['quantity'] as int,
      sellerId: map['sellerId'] as String,
      image: map['image'] as String?,
      variant: map['variant'] as String?,
    );
  }
}
