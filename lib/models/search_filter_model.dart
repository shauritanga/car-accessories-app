enum SortOption {
  relevance,
  priceAsc,
  priceDesc,
  nameAsc,
  nameDesc,
  ratingDesc,
  newest,
  oldest,
  popularity,
}

enum AvailabilityFilter {
  all,
  inStock,
  outOfStock,
}

class SearchFilterModel {
  final String query;
  final List<String> categories;
  final double? minPrice;
  final double? maxPrice;
  final double? minRating;
  final List<String> compatibility; // Car models
  final List<String> brands;
  final List<String> sellers;
  final SortOption sortBy;
  final AvailabilityFilter availability;
  final bool freeShipping;
  final bool onSale;
  final Map<String, List<String>> customFilters; // For extensible filtering

  SearchFilterModel({
    this.query = '',
    this.categories = const [],
    this.minPrice,
    this.maxPrice,
    this.minRating,
    this.compatibility = const [],
    this.brands = const [],
    this.sellers = const [],
    this.sortBy = SortOption.relevance,
    this.availability = AvailabilityFilter.all,
    this.freeShipping = false,
    this.onSale = false,
    this.customFilters = const {},
  });

  SearchFilterModel copyWith({
    String? query,
    List<String>? categories,
    double? minPrice,
    double? maxPrice,
    double? minRating,
    List<String>? compatibility,
    List<String>? brands,
    List<String>? sellers,
    SortOption? sortBy,
    AvailabilityFilter? availability,
    bool? freeShipping,
    bool? onSale,
    Map<String, List<String>>? customFilters,
  }) {
    return SearchFilterModel(
      query: query ?? this.query,
      categories: categories ?? this.categories,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      minRating: minRating ?? this.minRating,
      compatibility: compatibility ?? this.compatibility,
      brands: brands ?? this.brands,
      sellers: sellers ?? this.sellers,
      sortBy: sortBy ?? this.sortBy,
      availability: availability ?? this.availability,
      freeShipping: freeShipping ?? this.freeShipping,
      onSale: onSale ?? this.onSale,
      customFilters: customFilters ?? this.customFilters,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'query': query,
      'categories': categories,
      'minPrice': minPrice,
      'maxPrice': maxPrice,
      'minRating': minRating,
      'compatibility': compatibility,
      'brands': brands,
      'sellers': sellers,
      'sortBy': sortBy.toString(),
      'availability': availability.toString(),
      'freeShipping': freeShipping,
      'onSale': onSale,
      'customFilters': customFilters,
    };
  }

  factory SearchFilterModel.fromMap(Map<String, dynamic> map) {
    return SearchFilterModel(
      query: map['query'] ?? '',
      categories: List<String>.from(map['categories'] ?? []),
      minPrice: map['minPrice']?.toDouble(),
      maxPrice: map['maxPrice']?.toDouble(),
      minRating: map['minRating']?.toDouble(),
      compatibility: List<String>.from(map['compatibility'] ?? []),
      brands: List<String>.from(map['brands'] ?? []),
      sellers: List<String>.from(map['sellers'] ?? []),
      sortBy: SortOption.values.firstWhere(
        (e) => e.toString() == map['sortBy'],
        orElse: () => SortOption.relevance,
      ),
      availability: AvailabilityFilter.values.firstWhere(
        (e) => e.toString() == map['availability'],
        orElse: () => AvailabilityFilter.all,
      ),
      freeShipping: map['freeShipping'] ?? false,
      onSale: map['onSale'] ?? false,
      customFilters: Map<String, List<String>>.from(
        map['customFilters']?.map((key, value) => 
          MapEntry(key, List<String>.from(value))) ?? {},
      ),
    );
  }

  bool get hasActiveFilters {
    return query.isNotEmpty ||
        categories.isNotEmpty ||
        minPrice != null ||
        maxPrice != null ||
        minRating != null ||
        compatibility.isNotEmpty ||
        brands.isNotEmpty ||
        sellers.isNotEmpty ||
        availability != AvailabilityFilter.all ||
        freeShipping ||
        onSale ||
        customFilters.isNotEmpty;
  }

  int get activeFilterCount {
    int count = 0;
    if (query.isNotEmpty) count++;
    if (categories.isNotEmpty) count++;
    if (minPrice != null || maxPrice != null) count++;
    if (minRating != null) count++;
    if (compatibility.isNotEmpty) count++;
    if (brands.isNotEmpty) count++;
    if (sellers.isNotEmpty) count++;
    if (availability != AvailabilityFilter.all) count++;
    if (freeShipping) count++;
    if (onSale) count++;
    count += customFilters.length;
    return count;
  }

  String get sortDisplayName {
    switch (sortBy) {
      case SortOption.relevance:
        return 'Relevance';
      case SortOption.priceAsc:
        return 'Price: Low to High';
      case SortOption.priceDesc:
        return 'Price: High to Low';
      case SortOption.nameAsc:
        return 'Name: A to Z';
      case SortOption.nameDesc:
        return 'Name: Z to A';
      case SortOption.ratingDesc:
        return 'Highest Rated';
      case SortOption.newest:
        return 'Newest First';
      case SortOption.oldest:
        return 'Oldest First';
      case SortOption.popularity:
        return 'Most Popular';
    }
  }

  SearchFilterModel clearAll() {
    return SearchFilterModel();
  }

  SearchFilterModel clearQuery() {
    return copyWith(query: '');
  }

  SearchFilterModel clearPriceRange() {
    return copyWith(minPrice: null, maxPrice: null);
  }

  SearchFilterModel clearCategory() {
    return copyWith(categories: []);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SearchFilterModel &&
          runtimeType == other.runtimeType &&
          query == other.query &&
          _listEquals(categories, other.categories) &&
          minPrice == other.minPrice &&
          maxPrice == other.maxPrice &&
          minRating == other.minRating &&
          _listEquals(compatibility, other.compatibility) &&
          _listEquals(brands, other.brands) &&
          _listEquals(sellers, other.sellers) &&
          sortBy == other.sortBy &&
          availability == other.availability &&
          freeShipping == other.freeShipping &&
          onSale == other.onSale;

  @override
  int get hashCode =>
      query.hashCode ^
      categories.hashCode ^
      minPrice.hashCode ^
      maxPrice.hashCode ^
      minRating.hashCode ^
      compatibility.hashCode ^
      brands.hashCode ^
      sellers.hashCode ^
      sortBy.hashCode ^
      availability.hashCode ^
      freeShipping.hashCode ^
      onSale.hashCode;

  bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

// Search suggestions model
class SearchSuggestion {
  final String text;
  final SearchSuggestionType type;
  final String? category;
  final int? resultCount;

  SearchSuggestion({
    required this.text,
    required this.type,
    this.category,
    this.resultCount,
  });

  factory SearchSuggestion.fromMap(Map<String, dynamic> map) {
    return SearchSuggestion(
      text: map['text'] ?? '',
      type: SearchSuggestionType.values.firstWhere(
        (e) => e.toString() == map['type'],
        orElse: () => SearchSuggestionType.query,
      ),
      category: map['category'],
      resultCount: map['resultCount'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'type': type.toString(),
      'category': category,
      'resultCount': resultCount,
    };
  }
}

enum SearchSuggestionType {
  query,
  category,
  brand,
  product,
  recent,
}

// Search history model
class SearchHistory {
  final String query;
  final DateTime timestamp;
  final int resultCount;

  SearchHistory({
    required this.query,
    required this.timestamp,
    required this.resultCount,
  });

  factory SearchHistory.fromMap(Map<String, dynamic> map) {
    return SearchHistory(
      query: map['query'] ?? '',
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
      resultCount: map['resultCount'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'query': query,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'resultCount': resultCount,
    };
  }

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
