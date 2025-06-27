import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../models/product_model.dart';
import 'dart:io';

class ProductService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<void> addProduct(ProductModel product, List<XFile> images) async {
    try {
      List<String> imageUrls = [];

      // Upload images with progress tracking
      for (int i = 0; i < images.length; i++) {
        String fileName =
            'product_images/${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
        Reference ref = _storage.ref().child(fileName);

        // Add metadata for better organization
        await ref.putFile(
          File(images[i].path),
          SettableMetadata(
            contentType: 'image/jpeg',
            customMetadata: {
              'productId': product.id,
              'uploadedAt': DateTime.now().toIso8601String(),
            },
          ),
        );

        String url = await ref.getDownloadURL();
        imageUrls.add(url);
      }

      // Create a new product with the image URLs and additional metadata
      product = ProductModel(
        id: product.id,
        name: product.name,
        description: product.description,
        price: product.price,
        category: product.category,
        compatibility: product.compatibility,
        sellerId: product.sellerId,
        stock: product.stock,
        images: imageUrls,
        rating: product.rating,
      );

      // Add the product to Firestore with timestamp
      await _firestore.collection('products').doc(product.id).set({
        ...product.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'isActive': true,
      });
    } catch (e) {
      throw Exception('Failed to add product: $e');
    }
  }

  Stream<List<ProductModel>> getProducts({
    String? query,
    String? category,
    String? model,
    int? limit,
    String? sortBy,
    bool? inStockOnly,
  }) {
    print(
      'ProductService: Fetching products with filters - query: $query, category: $category, model: $model, sortBy: $sortBy',
    );

    Query queryRef = _firestore.collection('products');

    // Apply filters
    if (category != null && category.isNotEmpty) {
      queryRef = queryRef.where('category', isEqualTo: category);
    }

    if (model != null && model.isNotEmpty) {
      queryRef = queryRef.where('compatibility', arrayContains: model);
    }

    if (inStockOnly == true) {
      queryRef = queryRef.where('stock', isGreaterThan: 0);
    }

    // Apply sorting
    if (sortBy != null) {
      switch (sortBy) {
        case 'price_low':
          queryRef = queryRef.orderBy('price', descending: false);
          break;
        case 'price_high':
          queryRef = queryRef.orderBy('price', descending: true);
          break;
        case 'rating':
          queryRef = queryRef.orderBy('rating', descending: true);
          break;
        case 'newest':
          queryRef = queryRef.orderBy('createdAt', descending: true);
          break;
        case 'popular':
          queryRef = queryRef.orderBy('rating', descending: true);
          break;
      }
    } else {
      // Default sorting by creation date
      queryRef = queryRef.orderBy('createdAt', descending: true);
    }

    // Apply limit
    if (limit != null) {
      queryRef = queryRef.limit(limit);
    }

    return queryRef.snapshots().map((snapshot) {
      print(
        'ProductService: Received ${snapshot.docs.length} documents from Firestore',
      );
      List<ProductModel> products = [];
      for (var doc in snapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          print(
            'ProductService: Processing document ${doc.id} with data: ${data.keys}',
          );

          // Filter out inactive products in the client side
          if (data['isActive'] == false) {
            continue;
          }

          final product = ProductModel.fromMap({...data, 'id': doc.id});

          // Apply text search filter if query is provided
          if (query == null ||
              query.isEmpty ||
              product.name.toLowerCase().contains(query.toLowerCase()) ||
              product.description.toLowerCase().contains(query.toLowerCase()) ||
              product.category.toLowerCase().contains(query.toLowerCase())) {
            products.add(product);
          }
        } catch (e) {
          // Log error and continue processing other documents
          print('Error parsing product document ${doc.id}: $e');
        }
      }
      print(
        'ProductService: Returning ${products.length} products after filtering',
      );
      return products;
    });
  }

  Future<ProductModel> getProduct(String id) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('products').doc(id).get();

      if (!doc.exists) {
        throw Exception('Product not found');
      }

      final data = doc.data() as Map<String, dynamic>;
      if (data['isActive'] == false) {
        throw Exception('Product is not available');
      }

      return ProductModel.fromMap({...data, 'id': doc.id});
    } catch (e) {
      throw Exception('Failed to get product: $e');
    }
  }

  Stream<List<ProductModel>> getPopularProducts({int limit = 10}) {
    return _firestore
        .collection('products')
        .orderBy('rating', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
          List<ProductModel> products = [];
          for (var doc in snapshot.docs) {
            try {
              final data = doc.data();

              // Filter out inactive products and products with no stock
              if (data['isActive'] == false || (data['stock'] ?? 0) <= 0) {
                continue;
              }

              final product = ProductModel.fromMap({
                ...doc.data(),
                'id': doc.id,
              });
              products.add(product);
            } catch (e) {
              print('Error parsing popular product document ${doc.id}: $e');
            }
          }
          return products;
        });
  }

  Stream<List<ProductModel>> getNewArrivals({int limit = 10}) {
    return _firestore
        .collection('products')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
          List<ProductModel> products = [];
          for (var doc in snapshot.docs) {
            try {
              final data = doc.data();

              // Filter out inactive products
              if (data['isActive'] == false) {
                continue;
              }

              final product = ProductModel.fromMap({
                ...doc.data(),
                'id': doc.id,
              });
              products.add(product);
            } catch (e) {
              print('Error parsing new arrival document ${doc.id}: $e');
            }
          }
          return products;
        });
  }

  Stream<List<ProductModel>> getProductsByCategory(
    String category, {
    int limit = 20,
  }) {
    return _firestore
        .collection('products')
        .where('category', isEqualTo: category)
        .orderBy('rating', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
          List<ProductModel> products = [];
          for (var doc in snapshot.docs) {
            try {
              final data = doc.data();

              // Filter out inactive products
              if (data['isActive'] == false) {
                continue;
              }

              final product = ProductModel.fromMap({
                ...doc.data(),
                'id': doc.id,
              });
              products.add(product);
            } catch (e) {
              print('Error parsing category product document ${doc.id}: $e');
            }
          }
          return products;
        });
  }

  Future<void> updateProductStock(String productId, int newStock) async {
    try {
      await _firestore.collection('products').doc(productId).update({
        'stock': newStock,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update product stock: $e');
    }
  }

  Future<void> updateProductRating(String productId, double newRating) async {
    try {
      await _firestore.collection('products').doc(productId).update({
        'rating': newRating,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update product rating: $e');
    }
  }

  Stream<List<ProductModel>> searchProducts(
    String searchTerm, {
    int limit = 20,
  }) {
    if (searchTerm.isEmpty) {
      return getProducts(limit: limit);
    }

    return _firestore.collection('products').snapshots().map((snapshot) {
      List<ProductModel> products = [];
      final searchLower = searchTerm.toLowerCase();

      for (var doc in snapshot.docs) {
        try {
          final data = doc.data();

          // Filter out inactive products
          if (data['isActive'] == false) {
            continue;
          }

          final product = ProductModel.fromMap({...doc.data(), 'id': doc.id});

          // Check if product matches search term
          if (product.name.toLowerCase().contains(searchLower) ||
              product.description.toLowerCase().contains(searchLower) ||
              product.category.toLowerCase().contains(searchLower) ||
              product.compatibility.any(
                (model) => model.toLowerCase().contains(searchLower),
              )) {
            products.add(product);
          }
        } catch (e) {
          print('Error parsing search result document ${doc.id}: $e');
        }
      }

      // Sort by relevance (exact matches first)
      products.sort((a, b) {
        bool aExactMatch = a.name.toLowerCase() == searchLower;
        bool bExactMatch = b.name.toLowerCase() == searchLower;

        if (aExactMatch && !bExactMatch) return -1;
        if (!aExactMatch && bExactMatch) return 1;

        return (b.rating ?? 0.0).compareTo(a.rating ?? 0.0); // Then by rating
      });

      return products.take(limit).toList();
    });
  }

  Future<List<String>> getCategories() async {
    try {
      final snapshot = await _firestore.collection('products').get();

      Set<String> categories = {};
      for (var doc in snapshot.docs) {
        final data = doc.data();
        // Only include categories from active products
        if (data['isActive'] == true && data['category'] != null) {
          categories.add(data['category'] as String);
        }
      }

      return categories.toList()..sort();
    } catch (e) {
      throw Exception('Failed to get categories: $e');
    }
  }

  Future<void> deleteProduct(String productId) async {
    try {
      await _firestore.collection('products').doc(productId).update({
        'isActive': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to delete product: $e');
    }
  }
}
