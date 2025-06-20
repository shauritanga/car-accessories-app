import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product_model.dart';
import '../models/search_filter_model.dart';
import '../services/search_service.dart';

class SearchState {
  final List<ProductModel> results;
  final SearchFilterModel filter;
  final bool isLoading;
  final String? error;
  final List<SearchSuggestion> suggestions;
  final List<SearchHistory> history;
  final bool showSuggestions;

  SearchState({
    this.results = const [],
    SearchFilterModel? filter,
    this.isLoading = false,
    this.error,
    this.suggestions = const [],
    this.history = const [],
    this.showSuggestions = false,
  }) : filter = filter ?? SearchFilterModel();

  SearchState copyWith({
    List<ProductModel>? results,
    SearchFilterModel? filter,
    bool? isLoading,
    String? error,
    List<SearchSuggestion>? suggestions,
    List<SearchHistory>? history,
    bool? showSuggestions,
  }) {
    return SearchState(
      results: results ?? this.results,
      filter: filter ?? this.filter,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      suggestions: suggestions ?? this.suggestions,
      history: history ?? this.history,
      showSuggestions: showSuggestions ?? this.showSuggestions,
    );
  }
}

class SearchNotifier extends StateNotifier<SearchState> {
  final SearchService _searchService = SearchService();

  SearchNotifier() : super(SearchState()) {
    _loadSearchHistory();
  }

  Future<void> search([SearchFilterModel? newFilter]) async {
    final filter = newFilter ?? state.filter;
    state = state.copyWith(
      isLoading: true,
      error: null,
      filter: filter,
      showSuggestions: false,
    );

    try {
      final results = await _searchService.searchProducts(filter);
      state = state.copyWith(results: results, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void updateFilter(SearchFilterModel filter) {
    state = state.copyWith(filter: filter);
  }

  void updateQuery(String query) {
    final newFilter = state.filter.copyWith(query: query);
    state = state.copyWith(filter: newFilter);

    if (query.isNotEmpty) {
      _getSuggestions(query);
    } else {
      state = state.copyWith(suggestions: [], showSuggestions: false);
    }
  }

  void clearQuery() {
    final newFilter = state.filter.clearQuery();
    state = state.copyWith(
      filter: newFilter,
      suggestions: [],
      showSuggestions: false,
    );
  }

  void addCategory(String category) {
    final categories = List<String>.from(state.filter.categories);
    if (!categories.contains(category)) {
      categories.add(category);
      final newFilter = state.filter.copyWith(categories: categories);
      state = state.copyWith(filter: newFilter);
    }
  }

  void removeCategory(String category) {
    final categories = List<String>.from(state.filter.categories);
    categories.remove(category);
    final newFilter = state.filter.copyWith(categories: categories);
    state = state.copyWith(filter: newFilter);
  }

  void setPriceRange(double? minPrice, double? maxPrice) {
    final newFilter = state.filter.copyWith(
      minPrice: minPrice,
      maxPrice: maxPrice,
    );
    state = state.copyWith(filter: newFilter);
  }

  void setMinRating(double? rating) {
    final newFilter = state.filter.copyWith(minRating: rating);
    state = state.copyWith(filter: newFilter);
  }

  void addCompatibility(String carModel) {
    final compatibility = List<String>.from(state.filter.compatibility);
    if (!compatibility.contains(carModel)) {
      compatibility.add(carModel);
      final newFilter = state.filter.copyWith(compatibility: compatibility);
      state = state.copyWith(filter: newFilter);
    }
  }

  void removeCompatibility(String carModel) {
    final compatibility = List<String>.from(state.filter.compatibility);
    compatibility.remove(carModel);
    final newFilter = state.filter.copyWith(compatibility: compatibility);
    state = state.copyWith(filter: newFilter);
  }

  void setSortOption(SortOption sortBy) {
    final newFilter = state.filter.copyWith(sortBy: sortBy);
    state = state.copyWith(filter: newFilter);
  }

  void setAvailability(AvailabilityFilter availability) {
    final newFilter = state.filter.copyWith(availability: availability);
    state = state.copyWith(filter: newFilter);
  }

  void toggleFreeShipping() {
    final newFilter = state.filter.copyWith(
      freeShipping: !state.filter.freeShipping,
    );
    state = state.copyWith(filter: newFilter);
  }

  void toggleOnSale() {
    final newFilter = state.filter.copyWith(onSale: !state.filter.onSale);
    state = state.copyWith(filter: newFilter);
  }

  void clearAllFilters() {
    state = state.copyWith(filter: SearchFilterModel(), results: []);
  }

  void showSuggestions() {
    state = state.copyWith(showSuggestions: true);
    if (state.filter.query.isNotEmpty) {
      _getSuggestions(state.filter.query);
    } else {
      _loadSearchHistory();
    }
  }

  void hideSuggestions() {
    state = state.copyWith(showSuggestions: false);
  }

  Future<void> _getSuggestions(String query) async {
    try {
      final suggestions = await _searchService.getSearchSuggestions(query);
      state = state.copyWith(suggestions: suggestions);
    } catch (e) {
      // Fail silently for suggestions
      state = state.copyWith(suggestions: []);
    }
  }

  Future<void> _loadSearchHistory() async {
    try {
      final history = await _searchService.getSearchHistory();
      state = state.copyWith(history: history);
    } catch (e) {
      // Fail silently for history
      state = state.copyWith(history: []);
    }
  }

  Future<void> clearSearchHistory() async {
    try {
      await _searchService.clearSearchHistory();
      state = state.copyWith(history: []);
    } catch (e) {
      // Handle error if needed
    }
  }

  Future<void> removeFromHistory(String query) async {
    try {
      await _searchService.removeFromSearchHistory(query);
      await _loadSearchHistory();
    } catch (e) {
      // Handle error if needed
    }
  }

  void selectSuggestion(SearchSuggestion suggestion) {
    switch (suggestion.type) {
      case SearchSuggestionType.query:
      case SearchSuggestionType.recent:
      case SearchSuggestionType.product:
        updateQuery(suggestion.text);
        search();
        break;
      case SearchSuggestionType.category:
        final newFilter = state.filter.copyWith(
          categories: [suggestion.text],
          query: '',
        );
        search(newFilter);
        break;
      case SearchSuggestionType.brand:
        final newFilter = state.filter.copyWith(
          brands: [suggestion.text],
          query: '',
        );
        search(newFilter);
        break;
    }
    hideSuggestions();
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Providers
final searchProvider = StateNotifierProvider<SearchNotifier, SearchState>((
  ref,
) {
  return SearchNotifier();
});

// Future providers for filter options
final categoriesProvider = FutureProvider<List<String>>((ref) {
  final searchService = SearchService();
  return searchService.getCategories();
});

final brandsProvider = FutureProvider<List<String>>((ref) {
  final searchService = SearchService();
  return searchService.getBrands();
});

final priceRangeProvider = FutureProvider.family<Map<String, double>, String?>((
  ref,
  category,
) {
  final searchService = SearchService();
  return searchService.getPriceRange(category);
});

final popularCategoriesProvider = FutureProvider<List<String>>((ref) {
  final searchService = SearchService();
  return searchService.getPopularCategories();
});
