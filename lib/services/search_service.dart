import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/product_model.dart';
import '../models/search_filter_model.dart';

class SearchService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _searchHistoryKey = 'search_history';
  static const int _maxHistoryItems = 20;

  // Search products with filters
  Future<List<ProductModel>> searchProducts(SearchFilterModel filter) async {
    try {
      Query query = _firestore.collection('products');

      // Apply text search
      if (filter.query.isNotEmpty) {
        // For better text search, we'd typically use Algolia or similar
        // For now, we'll search in name and description fields
        final searchTerms = filter.query.toLowerCase().split(' ');
        
        // This is a simplified approach - in production, use proper full-text search
        query = query.where('searchKeywords', arrayContainsAny: searchTerms);
      }

      // Apply category filter
      if (filter.categories.isNotEmpty) {
        query = query.where('category', whereIn: filter.categories);
      }

      // Apply price range filter
      if (filter.minPrice != null) {
        query = query.where('price', isGreaterThanOrEqualTo: filter.minPrice);
      }
      if (filter.maxPrice != null) {
        query = query.where('price', isLessThanOrEqualTo: filter.maxPrice);
      }

      // Apply rating filter
      if (filter.minRating != null) {
        query = query.where('averageRating', isGreaterThanOrEqualTo: filter.minRating);
      }

      // Apply compatibility filter
      if (filter.compatibility.isNotEmpty) {
        query = query.where('compatibility', arrayContainsAny: filter.compatibility);
      }

      // Apply availability filter
      switch (filter.availability) {
        case AvailabilityFilter.inStock:
          query = query.where('stock', isGreaterThan: 0);
          break;
        case AvailabilityFilter.outOfStock:
          query = query.where('stock', isEqualTo: 0);
          break;
        case AvailabilityFilter.all:
          break;
      }

      // Apply sorting
      switch (filter.sortBy) {
        case SortOption.priceAsc:
          query = query.orderBy('price', descending: false);
          break;
        case SortOption.priceDesc:
          query = query.orderBy('price', descending: true);
          break;
        case SortOption.nameAsc:
          query = query.orderBy('name', descending: false);
          break;
        case SortOption.nameDesc:
          query = query.orderBy('name', descending: true);
          break;
        case SortOption.ratingDesc:
          query = query.orderBy('averageRating', descending: true);
          break;
        case SortOption.newest:
          query = query.orderBy('createdAt', descending: true);
          break;
        case SortOption.oldest:
          query = query.orderBy('createdAt', descending: false);
          break;
        case SortOption.popularity:
          query = query.orderBy('totalReviews', descending: true);
          break;
        case SortOption.relevance:
        default:
          // For relevance, we might use a combination of factors
          // For now, just order by a relevance score if available
          break;
      }

      final snapshot = await query.limit(100).get(); // Limit results
      
      List<ProductModel> products = snapshot.docs
          .map((doc) => ProductModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();

      // Apply additional filters that can't be done in Firestore query
      products = _applyAdditionalFilters(products, filter);

      // Save search to history if it has a query
      if (filter.query.isNotEmpty) {
        await _saveSearchHistory(filter.query, products.length);
      }

      return products;
    } catch (e) {
      throw Exception('Failed to search products: $e');
    }
  }

  // Get search suggestions
  Future<List<SearchSuggestion>> getSearchSuggestions(String query) async {
    try {
      final suggestions = <SearchSuggestion>[];

      if (query.isEmpty) {
        // Return recent searches and popular categories
        final history = await getSearchHistory();
        suggestions.addAll(
          history.take(5).map((h) => SearchSuggestion(
            text: h.query,
            type: SearchSuggestionType.recent,
            resultCount: h.resultCount,
          )),
        );

        // Add popular categories
        final categories = await getPopularCategories();
        suggestions.addAll(
          categories.take(5).map((category) => SearchSuggestion(
            text: category,
            type: SearchSuggestionType.category,
          )),
        );

        return suggestions;
      }

      final lowerQuery = query.toLowerCase();

      // Search in products for matching names
      final productQuery = await _firestore
          .collection('products')
          .where('searchKeywords', arrayContains: lowerQuery)
          .limit(5)
          .get();

      suggestions.addAll(
        productQuery.docs.map((doc) {
          final data = doc.data();
          return SearchSuggestion(
            text: data['name'] ?? '',
            type: SearchSuggestionType.product,
            category: data['category'],
          );
        }),
      );

      // Search in categories
      final categories = await getCategories();
      final matchingCategories = categories
          .where((cat) => cat.toLowerCase().contains(lowerQuery))
          .take(3)
          .toList();

      suggestions.addAll(
        matchingCategories.map((category) => SearchSuggestion(
          text: category,
          type: SearchSuggestionType.category,
        )),
      );

      // Search in brands (if we have a brands collection)
      final brands = await getBrands();
      final matchingBrands = brands
          .where((brand) => brand.toLowerCase().contains(lowerQuery))
          .take(3)
          .toList();

      suggestions.addAll(
        matchingBrands.map((brand) => SearchSuggestion(
          text: brand,
          type: SearchSuggestionType.brand,
        )),
      );

      return suggestions;
    } catch (e) {
      throw Exception('Failed to get search suggestions: $e');
    }
  }

  // Get available categories
  Future<List<String>> getCategories() async {
    try {
      final snapshot = await _firestore
          .collection('products')
          .get();

      final categories = <String>{};
      for (final doc in snapshot.docs) {
        final data = doc.data();
        if (data['category'] != null) {
          categories.add(data['category']);
        }
      }

      return categories.toList()..sort();
    } catch (e) {
      throw Exception('Failed to get categories: $e');
    }
  }

  // Get available brands
  Future<List<String>> getBrands() async {
    try {
      final snapshot = await _firestore
          .collection('products')
          .get();

      final brands = <String>{};
      for (final doc in snapshot.docs) {
        final data = doc.data();
        if (data['brand'] != null) {
          brands.add(data['brand']);
        }
      }

      return brands.toList()..sort();
    } catch (e) {
      throw Exception('Failed to get brands: $e');
    }
  }

  // Get popular categories
  Future<List<String>> getPopularCategories() async {
    try {
      // This would typically be based on analytics data
      // For now, return categories with most products
      final snapshot = await _firestore
          .collection('products')
          .get();

      final categoryCount = <String, int>{};
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final category = data['category'] as String?;
        if (category != null) {
          categoryCount[category] = (categoryCount[category] ?? 0) + 1;
        }
      }

      final sortedCategories = categoryCount.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      return sortedCategories.map((e) => e.key).toList();
    } catch (e) {
      throw Exception('Failed to get popular categories: $e');
    }
  }

  // Get price range for a category
  Future<Map<String, double>> getPriceRange([String? category]) async {
    try {
      Query query = _firestore.collection('products');
      
      if (category != null) {
        query = query.where('category', isEqualTo: category);
      }

      final snapshot = await query.get();
      
      if (snapshot.docs.isEmpty) {
        return {'min': 0.0, 'max': 0.0};
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
      throw Exception('Failed to get price range: $e');
    }
  }

  // Search history management
  Future<void> _saveSearchHistory(String query, int resultCount) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getStringList(_searchHistoryKey) ?? [];
      
      final history = historyJson
          .map((json) => SearchHistory.fromMap(jsonDecode(json)))
          .toList();

      // Remove existing entry if it exists
      history.removeWhere((h) => h.query.toLowerCase() == query.toLowerCase());

      // Add new entry at the beginning
      history.insert(0, SearchHistory(
        query: query,
        timestamp: DateTime.now(),
        resultCount: resultCount,
      ));

      // Keep only the most recent entries
      if (history.length > _maxHistoryItems) {
        history.removeRange(_maxHistoryItems, history.length);
      }

      // Save back to preferences
      final updatedJson = history.map((h) => jsonEncode(h.toMap())).toList();
      await prefs.setStringList(_searchHistoryKey, updatedJson);
    } catch (e) {
      // Fail silently for search history
      print('Failed to save search history: $e');
    }
  }

  Future<List<SearchHistory>> getSearchHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getStringList(_searchHistoryKey) ?? [];
      
      return historyJson
          .map((json) => SearchHistory.fromMap(jsonDecode(json)))
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
      
      final history = historyJson
          .map((json) => SearchHistory.fromMap(jsonDecode(json)))
          .where((h) => h.query.toLowerCase() != query.toLowerCase())
          .toList();

      final updatedJson = history.map((h) => jsonEncode(h.toMap())).toList();
      await prefs.setStringList(_searchHistoryKey, updatedJson);
    } catch (e) {
      throw Exception('Failed to remove from search history: $e');
    }
  }

  // Apply filters that can't be done in Firestore query
  List<ProductModel> _applyAdditionalFilters(
    List<ProductModel> products,
    SearchFilterModel filter,
  ) {
    return products.where((product) {
      // Apply brand filter
      if (filter.brands.isNotEmpty) {
        // Assuming we add brand field to ProductModel
        // For now, skip this filter
      }

      // Apply seller filter
      if (filter.sellers.isNotEmpty && !filter.sellers.contains(product.sellerId)) {
        return false;
      }

      // Apply free shipping filter
      if (filter.freeShipping) {
        // This would require shipping info in product model
        // For now, skip this filter
      }

      // Apply on sale filter
      if (filter.onSale) {
        // This would require sale info in product model
        // For now, skip this filter
      }

      return true;
    }).toList();
  }
}
