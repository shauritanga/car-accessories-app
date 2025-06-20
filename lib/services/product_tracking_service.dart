import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import '../models/product_model.dart';

class ProductTrackingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _recentlyViewedKey = 'recently_viewed_products';
  static const String _searchHistoryKey = 'search_history';
  static const int _maxRecentlyViewed = 20;

  // Track product view
  Future<void> trackProductView(String userId, ProductModel product) async {
    try {
      // Update view count in Firestore
      await _firestore.collection('products').doc(product.id).update({
        'viewCount': FieldValue.increment(1),
        'lastViewed': FieldValue.serverTimestamp(),
      });

      // Track user's recently viewed products locally
      await _addToRecentlyViewed(product);

      // Track in user's view history (if logged in)
      if (userId.isNotEmpty) {
        await _trackUserViewHistory(userId, product.id);
      }
    } catch (e) {
      print('Error tracking product view: $e');
    }
  }

  // Get recently viewed products
  Future<List<ProductModel>> getRecentlyViewedProducts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final recentlyViewedJson = prefs.getStringList(_recentlyViewedKey) ?? [];
      
      final List<ProductModel> products = [];
      for (final json in recentlyViewedJson) {
        try {
          final data = jsonDecode(json);
          products.add(ProductModel.fromMap(data));
        } catch (e) {
          print('Error parsing recently viewed product: $e');
        }
      }
      
      return products;
    } catch (e) {
      print('Error getting recently viewed products: $e');
      return [];
    }
  }

  // Add product to recently viewed
  Future<void> _addToRecentlyViewed(ProductModel product) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final recentlyViewedJson = prefs.getStringList(_recentlyViewedKey) ?? [];
      
      // Convert to list of products
      final List<ProductModel> products = [];
      for (final json in recentlyViewedJson) {
        try {
          final data = jsonDecode(json);
          final existingProduct = ProductModel.fromMap(data);
          // Skip if it's the same product
          if (existingProduct.id != product.id) {
            products.add(existingProduct);
          }
        } catch (e) {
          print('Error parsing existing product: $e');
        }
      }
      
      // Add current product to the beginning
      products.insert(0, product);
      
      // Keep only the most recent items
      if (products.length > _maxRecentlyViewed) {
        products.removeRange(_maxRecentlyViewed, products.length);
      }
      
      // Convert back to JSON and save
      final updatedJson = products.map((p) => jsonEncode(p.toMap())).toList();
      await prefs.setStringList(_recentlyViewedKey, updatedJson);
    } catch (e) {
      print('Error adding to recently viewed: $e');
    }
  }

  // Track user view history in Firestore
  Future<void> _trackUserViewHistory(String userId, String productId) async {
    try {
      await _firestore
          .collection('user_view_history')
          .doc('${userId}_$productId')
          .set({
        'userId': userId,
        'productId': productId,
        'viewedAt': FieldValue.serverTimestamp(),
        'viewCount': FieldValue.increment(1),
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error tracking user view history: $e');
    }
  }

  // Get user's view history
  Future<List<String>> getUserViewHistory(String userId, {int limit = 50}) async {
    try {
      final snapshot = await _firestore
          .collection('user_view_history')
          .where('userId', isEqualTo: userId)
          .orderBy('viewedAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) => doc.data()['productId'] as String).toList();
    } catch (e) {
      print('Error getting user view history: $e');
      return [];
    }
  }

  // Get trending products based on view counts
  Future<List<ProductModel>> getTrendingProducts({int limit = 10}) async {
    try {
      final snapshot = await _firestore
          .collection('products')
          .where('isActive', isEqualTo: true)
          .orderBy('viewCount', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => ProductModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print('Error getting trending products: $e');
      return [];
    }
  }

  // Get related products based on category and compatibility
  Future<List<ProductModel>> getRelatedProducts(
    ProductModel product, {
    int limit = 6,
  }) async {
    try {
      // First try to get products from the same category
      Query query = _firestore
          .collection('products')
          .where('isActive', isEqualTo: true)
          .where('category', isEqualTo: product.category);

      // Exclude the current product
      query = query.where(FieldPath.documentId, isNotEqualTo: product.id);

      final snapshot = await query.limit(limit).get();
      
      List<ProductModel> relatedProducts = snapshot.docs
          .map((doc) => ProductModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();

      // If we don't have enough products, get some from compatible models
      if (relatedProducts.length < limit && product.compatibility.isNotEmpty) {
        final compatibilityQuery = await _firestore
            .collection('products')
            .where('isActive', isEqualTo: true)
            .where('compatibility', arrayContainsAny: product.compatibility)
            .where(FieldPath.documentId, isNotEqualTo: product.id)
            .limit(limit - relatedProducts.length)
            .get();

        final compatibilityProducts = compatibilityQuery.docs
            .map((doc) => ProductModel.fromMap(doc.data()))
            .where((p) => !relatedProducts.any((rp) => rp.id == p.id))
            .toList();

        relatedProducts.addAll(compatibilityProducts);
      }

      return relatedProducts.take(limit).toList();
    } catch (e) {
      print('Error getting related products: $e');
      return [];
    }
  }

  // Clear recently viewed products
  Future<void> clearRecentlyViewed() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_recentlyViewedKey);
    } catch (e) {
      print('Error clearing recently viewed: $e');
    }
  }

  // Get products frequently bought together
  Future<List<ProductModel>> getFrequentlyBoughtTogether(
    String productId, {
    int limit = 4,
  }) async {
    try {
      // This would analyze order data to find products frequently bought together
      // For now, return related products as a placeholder
      final productDoc = await _firestore.collection('products').doc(productId).get();
      if (!productDoc.exists) return [];
      
      final product = ProductModel.fromMap(productDoc.data()!);
      return await getRelatedProducts(product, limit: limit);
    } catch (e) {
      print('Error getting frequently bought together: $e');
      return [];
    }
  }

  // Track product comparison
  Future<void> trackProductComparison(List<String> productIds) async {
    try {
      await _firestore.collection('product_comparisons').add({
        'productIds': productIds,
        'comparedAt': FieldValue.serverTimestamp(),
      });

      // Update comparison count for each product
      for (final productId in productIds) {
        await _firestore.collection('products').doc(productId).update({
          'comparisonCount': FieldValue.increment(1),
        });
      }
    } catch (e) {
      print('Error tracking product comparison: $e');
    }
  }

  // Get product analytics
  Future<Map<String, dynamic>> getProductAnalytics(String productId) async {
    try {
      final productDoc = await _firestore.collection('products').doc(productId).get();
      if (!productDoc.exists) return {};

      final data = productDoc.data()!;
      
      // Get view history for the last 30 days
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      final viewHistorySnapshot = await _firestore
          .collection('user_view_history')
          .where('productId', isEqualTo: productId)
          .where('viewedAt', isGreaterThan: Timestamp.fromDate(thirtyDaysAgo))
          .get();

      return {
        'totalViews': data['viewCount'] ?? 0,
        'recentViews': viewHistorySnapshot.docs.length,
        'comparisonCount': data['comparisonCount'] ?? 0,
        'averageRating': data['averageRating'] ?? 0.0,
        'totalReviews': data['totalReviews'] ?? 0,
        'stock': data['stock'] ?? 0,
        'isActive': data['isActive'] ?? false,
      };
    } catch (e) {
      print('Error getting product analytics: $e');
      return {};
    }
  }

  // Search suggestions based on view history
  Future<List<String>> getPersonalizedSearchSuggestions(String userId) async {
    try {
      final viewHistory = await getUserViewHistory(userId, limit: 20);
      if (viewHistory.isEmpty) return [];

      // Get products from view history
      final productDocs = await _firestore
          .collection('products')
          .where(FieldPath.documentId, whereIn: viewHistory.take(10).toList())
          .get();

      final suggestions = <String>{};
      
      for (final doc in productDocs.docs) {
        final data = doc.data();
        
        // Add product name words
        final nameWords = (data['name'] as String).toLowerCase().split(' ');
        suggestions.addAll(nameWords.where((word) => word.length > 2));
        
        // Add category
        suggestions.add((data['category'] as String).toLowerCase());
        
        // Add brand if available
        if (data['brand'] != null) {
          suggestions.add((data['brand'] as String).toLowerCase());
        }
        
        // Add tags if available
        if (data['tags'] != null) {
          final tags = List<String>.from(data['tags']);
          suggestions.addAll(tags.map((tag) => tag.toLowerCase()));
        }
      }

      return suggestions.take(10).toList();
    } catch (e) {
      print('Error getting personalized search suggestions: $e');
      return [];
    }
  }
}
