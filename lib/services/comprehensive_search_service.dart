import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/product_model.dart';

class SearchSuggestion {
  final String text;
  final String type; // 'product', 'category', 'brand', 'recent'
  final String? imageUrl;
  final int? resultCount;

  SearchSuggestion({
    required this.text,
    required this.type,
    this.imageUrl,
    this.resultCount,
  });

  Map<String, dynamic> toJson() => {
    'text': text,
    'type': type,
    'imageUrl': imageUrl,
    'resultCount': resultCount,
  };

  factory SearchSuggestion.fromJson(Map<String, dynamic> json) =>
      SearchSuggestion(
        text: json['text'],
        type: json['type'],
        imageUrl: json['imageUrl'],
        resultCount: json['resultCount'],
      );
}

class SearchHistory {
  final String query;
  final DateTime timestamp;
  final int resultCount;

  SearchHistory({
    required this.query,
    required this.timestamp,
    required this.resultCount,
  });

  Map<String, dynamic> toJson() => {
    'query': query,
    'timestamp': timestamp.millisecondsSinceEpoch,
    'resultCount': resultCount,
  };

  factory SearchHistory.fromJson(Map<String, dynamic> json) => SearchHistory(
    query: json['query'],
    timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp']),
    resultCount: json['resultCount'],
  );

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }
}

class ComprehensiveSearchService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _searchHistoryKey = 'search_history';
  static const String _trendingSearchesKey = 'trending_searches';
  static const int _maxHistoryItems = 20;

  // Enhanced search with autocomplete
  Future<List<SearchSuggestion>> getSearchSuggestions(String query) async {
    final suggestions = <SearchSuggestion>[];

    if (query.isEmpty) {
      // Return recent searches and trending
      final history = await getSearchHistory();
      suggestions.addAll(
        history
            .take(5)
            .map(
              (h) => SearchSuggestion(
                text: h.query,
                type: 'recent',
                resultCount: h.resultCount,
              ),
            ),
      );

      final trending = await getTrendingSearches();
      suggestions.addAll(
        trending
            .take(5)
            .map((t) => SearchSuggestion(text: t, type: 'trending')),
      );

      return suggestions;
    }

    final lowerQuery = query.toLowerCase();

    try {
      // Search in products
      final productQuery =
          await _firestore
              .collection('products')
              .where('searchKeywords', arrayContains: lowerQuery)
              .limit(5)
              .get();

      suggestions.addAll(
        productQuery.docs.map((doc) {
          final data = doc.data();
          final images = data['images'] as List?;
          return SearchSuggestion(
            text: data['name']?.toString() ?? '',
            type: 'product',
            imageUrl:
                images != null && images.isNotEmpty
                    ? images[0]?.toString()
                    : null,
          );
        }),
      );

      // Search in categories
      final categories = await getCategories();
      final matchingCategories =
          categories
              .where((cat) => cat.toLowerCase().contains(lowerQuery))
              .take(3)
              .toList();

      suggestions.addAll(
        matchingCategories.map(
          (category) => SearchSuggestion(text: category, type: 'category'),
        ),
      );

      // Search in brands
      final brands = await getBrands();
      final matchingBrands =
          brands
              .where((brand) => brand.toLowerCase().contains(lowerQuery))
              .take(3)
              .toList();

      suggestions.addAll(
        matchingBrands.map(
          (brand) => SearchSuggestion(text: brand, type: 'brand'),
        ),
      );
    } catch (e) {
      print('Error getting search suggestions: $e');
    }

    return suggestions;
  }

  // Enhanced product search with multiple filters
  Future<List<ProductModel>> searchProducts({
    String? query,
    List<String>? categories,
    double? minPrice,
    double? maxPrice,
    double? minRating,
    List<String>? brands,
    List<String>? compatibility,
    bool? inStockOnly,
    String?
    sortBy, // 'price_asc', 'price_desc', 'rating', 'newest', 'popularity'
    int limit = 50,
  }) async {
    try {
      Query firestoreQuery = _firestore.collection('products');

      // Apply filters
      if (categories != null && categories.isNotEmpty) {
        firestoreQuery = firestoreQuery.where('category', whereIn: categories);
      }

      if (minPrice != null) {
        firestoreQuery = firestoreQuery.where(
          'price',
          isGreaterThanOrEqualTo: minPrice,
        );
      }

      if (maxPrice != null) {
        firestoreQuery = firestoreQuery.where(
          'price',
          isLessThanOrEqualTo: maxPrice,
        );
      }

      if (minRating != null) {
        firestoreQuery = firestoreQuery.where(
          'averageRating',
          isGreaterThanOrEqualTo: minRating,
        );
      }

      if (inStockOnly == true) {
        firestoreQuery = firestoreQuery.where('stock', isGreaterThan: 0);
      }

      if (compatibility != null && compatibility.isNotEmpty) {
        firestoreQuery = firestoreQuery.where(
          'compatibility',
          arrayContainsAny: compatibility,
        );
      }

      // Apply sorting
      switch (sortBy) {
        case 'price_asc':
          firestoreQuery = firestoreQuery.orderBy('price', descending: false);
          break;
        case 'price_desc':
          firestoreQuery = firestoreQuery.orderBy('price', descending: true);
          break;
        case 'rating':
          firestoreQuery = firestoreQuery.orderBy(
            'averageRating',
            descending: true,
          );
          break;
        case 'newest':
          firestoreQuery = firestoreQuery.orderBy(
            'createdAt',
            descending: true,
          );
          break;
        case 'popularity':
          firestoreQuery = firestoreQuery.orderBy(
            'totalReviews',
            descending: true,
          );
          break;
        default:
          // Default sorting by relevance (or creation date)
          firestoreQuery = firestoreQuery.orderBy(
            'createdAt',
            descending: true,
          );
      }

      final snapshot = await firestoreQuery.limit(limit).get();

      List<ProductModel> products =
          snapshot.docs
              .map(
                (doc) =>
                    ProductModel.fromMap(doc.data() as Map<String, dynamic>),
              )
              .toList();

      // Apply text search filter (since Firestore doesn't have full-text search)
      if (query != null && query.isNotEmpty) {
        final searchTerms =
            query
                .toLowerCase()
                .split(' ')
                .where((term) => term.isNotEmpty)
                .toList();
        if (searchTerms.isNotEmpty) {
          products =
              products.where((product) {
                final productText =
                    '${product.name} ${product.description}'.toLowerCase();
                return searchTerms.any((term) => productText.contains(term));
              }).toList();
        }
      }

      // Apply brand filter (if not done in Firestore)
      if (brands != null && brands.isNotEmpty) {
        // Assuming we add brand field to ProductModel
        // products = products.where((product) => brands.contains(product.brand)).toList();
      }

      // Save search to history if it has a query
      if (query != null && query.isNotEmpty) {
        await saveSearchHistory(query, products.length);
      }

      return products;
    } catch (e) {
      throw Exception('Failed to search products: $e');
    }
  }

  // Get available categories
  Future<List<String>> getCategories() async {
    try {
      final snapshot = await _firestore.collection('products').get();
      final categories = <String>{};

      for (final doc in snapshot.docs) {
        final data = doc.data();
        if (data['category'] != null) {
          categories.add(data['category']);
        }
      }

      return categories.toList()..sort();
    } catch (e) {
      return [
        'Interior',
        'Exterior',
        'Electronics',
        'Performance',
        'Safety',
        'Lighting',
      ];
    }
  }

  // Get available brands
  Future<List<String>> getBrands() async {
    try {
      final snapshot = await _firestore.collection('products').get();
      final brands = <String>{};

      for (final doc in snapshot.docs) {
        final data = doc.data();
        if (data['brand'] != null) {
          brands.add(data['brand']);
        }
      }

      return brands.toList()..sort();
    } catch (e) {
      return [
        'Toyota',
        'Honda',
        'Ford',
        'BMW',
        'Mercedes',
        'Audi',
        'Nissan',
        'Mazda',
      ];
    }
  }

  // Get price range for category
  Future<Map<String, double>> getPriceRange([String? category]) async {
    try {
      Query query = _firestore.collection('products');

      if (category != null) {
        query = query.where('category', isEqualTo: category);
      }

      final snapshot = await query.get();

      if (snapshot.docs.isEmpty) {
        return {'min': 0.0, 'max': 1000000.0};
      }

      double minPrice = double.infinity;
      double maxPrice = 0.0;

      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final price = (data['price'] as num?)?.toDouble() ?? 0.0;
        if (price < minPrice) minPrice = price;
        if (price > maxPrice) maxPrice = price;
      }

      return {
        'min': minPrice == double.infinity ? 0.0 : minPrice,
        'max': maxPrice,
      };
    } catch (e) {
      return {'min': 0.0, 'max': 1000000.0};
    }
  }

  // Search history management
  Future<void> saveSearchHistory(String query, int resultCount) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getStringList(_searchHistoryKey) ?? [];

      final history =
          historyJson
              .map((json) => SearchHistory.fromJson(jsonDecode(json)))
              .toList();

      // Remove existing entry if it exists
      history.removeWhere((h) => h.query.toLowerCase() == query.toLowerCase());

      // Add new entry at the beginning
      history.insert(
        0,
        SearchHistory(
          query: query,
          timestamp: DateTime.now(),
          resultCount: resultCount,
        ),
      );

      // Keep only the most recent entries
      if (history.length > _maxHistoryItems) {
        history.removeRange(_maxHistoryItems, history.length);
      }

      // Save back to preferences
      final updatedJson = history.map((h) => jsonEncode(h.toJson())).toList();
      await prefs.setStringList(_searchHistoryKey, updatedJson);

      // Update trending searches
      await _updateTrendingSearches(query);
    } catch (e) {
      print('Failed to save search history: $e');
    }
  }

  Future<List<SearchHistory>> getSearchHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getStringList(_searchHistoryKey) ?? [];

      return historyJson
          .map((json) => SearchHistory.fromJson(jsonDecode(json)))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> clearSearchHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_searchHistoryKey);
    } catch (e) {
      throw Exception('Failed to clear search history: $e');
    }
  }

  Future<void> removeFromSearchHistory(String query) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getStringList(_searchHistoryKey) ?? [];

      final history =
          historyJson
              .map((json) => SearchHistory.fromJson(jsonDecode(json)))
              .where((h) => h.query.toLowerCase() != query.toLowerCase())
              .toList();

      final updatedJson = history.map((h) => jsonEncode(h.toJson())).toList();
      await prefs.setStringList(_searchHistoryKey, updatedJson);
    } catch (e) {
      throw Exception('Failed to remove from search history: $e');
    }
  }

  // Trending searches
  Future<List<String>> getTrendingSearches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getStringList(_trendingSearchesKey) ??
          [
            'brake pads',
            'LED headlights',
            'car mats',
            'air freshener',
            'phone holder',
          ];
    } catch (e) {
      return [];
    }
  }

  Future<void> _updateTrendingSearches(String query) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final trending = prefs.getStringList(_trendingSearchesKey) ?? [];

      // Simple trending algorithm - move to front if exists, add if new
      trending.remove(query.toLowerCase());
      trending.insert(0, query.toLowerCase());

      // Keep only top 10 trending
      if (trending.length > 10) {
        trending.removeRange(10, trending.length);
      }

      await prefs.setStringList(_trendingSearchesKey, trending);
    } catch (e) {
      print('Failed to update trending searches: $e');
    }
  }

  // Voice search placeholder (would integrate with speech_to_text package)
  Future<String?> startVoiceSearch() async {
    // This would integrate with speech_to_text package
    // For now, return null to indicate not implemented
    return null;
  }

  // Barcode search placeholder (would integrate with barcode scanner)
  Future<String?> scanBarcode() async {
    // This would integrate with barcode scanner package
    // For now, return null to indicate not implemented
    return null;
  }
}
