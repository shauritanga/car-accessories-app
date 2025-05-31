class ProductModel {
  final String id;
  final String name;
  final String description;
  final double price;
  final int stock;
  final String category;
  final List<String> compatibility; // Car models
  final String sellerId;
  final List<String> images;
  final double? rating;

  ProductModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.stock,
    required this.category,
    required this.compatibility,
    required this.sellerId,
    required this.images,
    this.rating,
  });

  factory ProductModel.fromMap(Map<String, dynamic> data) {
    return ProductModel(
      id: data['id'],
      name: data['name'],
      description: data['description'],
      price: data['price'].toDouble(),
      category: data['category'],
      stock: data['stock'] ?? 0, // Add default value if missing
      compatibility: List<String>.from(data['compatibility']),
      sellerId: data['sellerId'],
      images: List<String>.from(data['images']),
      rating: data['rating']?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'category': category,
      'compatibility': compatibility,
      'stock': stock,
      'sellerId': sellerId,
      'images': images,
      'rating': rating,
    };
  }
}
