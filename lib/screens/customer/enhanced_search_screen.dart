import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/comprehensive_search_service.dart';
import '../../models/product_model.dart';
import '../../widgets/product_grid.dart';
import 'dart:async';

class EnhancedSearchScreen extends ConsumerStatefulWidget {
  const EnhancedSearchScreen({super.key});

  @override
  ConsumerState<EnhancedSearchScreen> createState() => _EnhancedSearchScreenState();
}

class _EnhancedSearchScreenState extends ConsumerState<EnhancedSearchScreen> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  final _searchService = ComprehensiveSearchService();
  
  List<SearchSuggestion> _suggestions = [];
  List<SearchHistory> _searchHistory = [];
  List<ProductModel> _searchResults = [];
  List<String> _trendingSearches = [];
  
  bool _isLoading = false;
  bool _showSuggestions = false;
  bool _showResults = false;
  Timer? _debounceTimer;

  // Filter states
  List<String> _selectedCategories = [];
  List<String> _selectedBrands = [];
  List<String> _selectedCompatibility = [];
  double? _minPrice;
  double? _maxPrice;
  double? _minRating;
  bool _inStockOnly = false;
  String _sortBy = 'relevance';

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus && !_showResults) {
      setState(() => _showSuggestions = true);
    }
  }

  Future<void> _loadInitialData() async {
    final history = await _searchService.getSearchHistory();
    final trending = await _searchService.getTrendingSearches();
    
    setState(() {
      _searchHistory = history;
      _trendingSearches = trending;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: _buildSearchBar(theme, colorScheme),
        elevation: 0,
        actions: [
          if (_showResults) ...[
            IconButton(
              icon: const Icon(Icons.tune),
              onPressed: _showFilterBottomSheet,
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.sort),
              onSelected: (value) {
                setState(() => _sortBy = value);
                _performSearch();
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'relevance', child: Text('Relevance')),
                const PopupMenuItem(value: 'price_asc', child: Text('Price: Low to High')),
                const PopupMenuItem(value: 'price_desc', child: Text('Price: High to Low')),
                const PopupMenuItem(value: 'rating', child: Text('Highest Rated')),
                const PopupMenuItem(value: 'newest', child: Text('Newest First')),
                const PopupMenuItem(value: 'popularity', child: Text('Most Popular')),
              ],
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          // Active filters display
          if (_hasActiveFilters()) _buildActiveFilters(),
          
          // Content
          Expanded(
            child: _showResults
                ? _buildSearchResults()
                : _showSuggestions
                    ? _buildSuggestions()
                    : _buildSearchHome(),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: "voice_search",
            mini: true,
            onPressed: _startVoiceSearch,
            child: const Icon(Icons.mic),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: "barcode_search",
            mini: true,
            onPressed: _scanBarcode,
            child: const Icon(Icons.qr_code_scanner),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(ThemeData theme, ColorScheme colorScheme) {
    return TextField(
      controller: _searchController,
      focusNode: _focusNode,
      decoration: InputDecoration(
        hintText: 'Search for car accessories...',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _showResults = false;
                    _showSuggestions = true;
                    _searchResults.clear();
                  });
                },
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      onChanged: _onSearchChanged,
      onSubmitted: (value) => _performSearch(),
    );
  }

  Widget _buildActiveFilters() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          ..._selectedCategories.map((category) => _buildFilterChip(
            label: category,
            onDeleted: () {
              setState(() => _selectedCategories.remove(category));
              _performSearch();
            },
          )),
          ..._selectedBrands.map((brand) => _buildFilterChip(
            label: brand,
            onDeleted: () {
              setState(() => _selectedBrands.remove(brand));
              _performSearch();
            },
          )),
          if (_minPrice != null || _maxPrice != null)
            _buildFilterChip(
              label: 'Price: ${_minPrice?.toStringAsFixed(0) ?? '0'} - ${_maxPrice?.toStringAsFixed(0) ?? '∞'}',
              onDeleted: () {
                setState(() {
                  _minPrice = null;
                  _maxPrice = null;
                });
                _performSearch();
              },
            ),
          if (_minRating != null)
            _buildFilterChip(
              label: '${_minRating!.toStringAsFixed(1)}+ stars',
              onDeleted: () {
                setState(() => _minRating = null);
                _performSearch();
              },
            ),
          if (_inStockOnly)
            _buildFilterChip(
              label: 'In Stock',
              onDeleted: () {
                setState(() => _inStockOnly = false);
                _performSearch();
              },
            ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({required String label, required VoidCallback onDeleted}) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: Chip(
        label: Text(label),
        deleteIcon: const Icon(Icons.close, size: 18),
        onDeleted: onDeleted,
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text('No products found'),
            const SizedBox(height: 8),
            const Text('Try adjusting your search or filters'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _clearAllFilters,
              child: const Text('Clear Filters'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Results count
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Text(
                '${_searchResults.length} results found',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              const Spacer(),
              Text('Sorted by: $_sortBy'),
            ],
          ),
        ),
        
        // Results grid
        Expanded(
          child: ProductGrid(products: _searchResults),
        ),
      ],
    );
  }

  Widget _buildSuggestions() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search suggestions
          if (_suggestions.isNotEmpty) ...[
            const Text(
              'Suggestions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ..._suggestions.map((suggestion) => ListTile(
              leading: _getSuggestionIcon(suggestion.type),
              title: Text(suggestion.text),
              subtitle: suggestion.resultCount != null
                  ? Text('${suggestion.resultCount} results')
                  : null,
              onTap: () => _selectSuggestion(suggestion),
            )),
            const SizedBox(height: 24),
          ],

          // Recent searches
          if (_searchHistory.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Searches',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: _clearSearchHistory,
                  child: const Text('Clear All'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ..._searchHistory.take(5).map((history) => ListTile(
              leading: const Icon(Icons.history),
              title: Text(history.query),
              subtitle: Text('${history.resultCount} results • ${history.timeAgo}'),
              trailing: IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () => _removeFromHistory(history.query),
              ),
              onTap: () => _selectHistoryItem(history),
            )),
            const SizedBox(height: 24),
          ],

          // Trending searches
          if (_trendingSearches.isNotEmpty) ...[
            const Text(
              'Trending Searches',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _trendingSearches.map((trending) => ActionChip(
                label: Text(trending),
                onPressed: () => _selectTrending(trending),
              )).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSearchHome() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'What are you looking for?',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          
          // Quick search categories
          const Text(
            'Popular Categories',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              'Interior', 'Exterior', 'Electronics', 'Performance', 'Safety', 'Lighting'
            ].map((category) => ActionChip(
              label: Text(category),
              onPressed: () => _quickSearchCategory(category),
            )).toList(),
          ),
          
          const SizedBox(height: 24),
          
          // Search tips
          const Text(
            'Search Tips',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            '• Use specific keywords like "brake pads" or "LED headlights"\n'
            '• Filter by your car model for compatible parts\n'
            '• Use voice search for hands-free searching\n'
            '• Scan barcodes to find exact products',
            style: TextStyle(height: 1.5),
          ),
        ],
      ),
    );
  }

  // Helper methods
  void _onSearchChanged(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _getSuggestions(value);
    });
  }

  Future<void> _getSuggestions(String query) async {
    if (query.isEmpty) {
      setState(() {
        _suggestions.clear();
        _showSuggestions = true;
      });
      return;
    }

    final suggestions = await _searchService.getSearchSuggestions(query);
    setState(() {
      _suggestions = suggestions;
      _showSuggestions = true;
    });
  }

  Future<void> _performSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty && !_hasActiveFilters()) return;

    setState(() {
      _isLoading = true;
      _showSuggestions = false;
      _showResults = true;
    });

    try {
      final results = await _searchService.searchProducts(
        query: query.isNotEmpty ? query : null,
        categories: _selectedCategories.isNotEmpty ? _selectedCategories : null,
        brands: _selectedBrands.isNotEmpty ? _selectedBrands : null,
        compatibility: _selectedCompatibility.isNotEmpty ? _selectedCompatibility : null,
        minPrice: _minPrice,
        maxPrice: _maxPrice,
        minRating: _minRating,
        inStockOnly: _inStockOnly,
        sortBy: _sortBy,
      );

      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _searchResults.clear();
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Search failed: $e')),
        );
      }
    }
  }

  void _selectSuggestion(SearchSuggestion suggestion) {
    _searchController.text = suggestion.text;
    _performSearch();
  }

  void _selectHistoryItem(SearchHistory history) {
    _searchController.text = history.query;
    _performSearch();
  }

  void _selectTrending(String trending) {
    _searchController.text = trending;
    _performSearch();
  }

  void _quickSearchCategory(String category) {
    setState(() {
      _selectedCategories = [category];
    });
    _performSearch();
  }

  Future<void> _clearSearchHistory() async {
    await _searchService.clearSearchHistory();
    setState(() => _searchHistory.clear());
  }

  Future<void> _removeFromHistory(String query) async {
    await _searchService.removeFromSearchHistory(query);
    final updatedHistory = await _searchService.getSearchHistory();
    setState(() => _searchHistory = updatedHistory);
  }

  void _clearAllFilters() {
    setState(() {
      _selectedCategories.clear();
      _selectedBrands.clear();
      _selectedCompatibility.clear();
      _minPrice = null;
      _maxPrice = null;
      _minRating = null;
      _inStockOnly = false;
      _sortBy = 'relevance';
    });
    _performSearch();
  }

  bool _hasActiveFilters() {
    return _selectedCategories.isNotEmpty ||
        _selectedBrands.isNotEmpty ||
        _selectedCompatibility.isNotEmpty ||
        _minPrice != null ||
        _maxPrice != null ||
        _minRating != null ||
        _inStockOnly;
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => _buildFilterSheet(scrollController),
      ),
    );
  }

  Widget _buildFilterSheet(ScrollController scrollController) {
    // This would be a comprehensive filter sheet
    // For brevity, showing a simplified version
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Text(
            'Filters',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              controller: scrollController,
              child: Column(
                children: [
                  // Categories
                  const Text('Categories', style: TextStyle(fontWeight: FontWeight.bold)),
                  // Add category selection widgets
                  
                  // Price range
                  const Text('Price Range', style: TextStyle(fontWeight: FontWeight.bold)),
                  // Add price range slider
                  
                  // Rating
                  const Text('Minimum Rating', style: TextStyle(fontWeight: FontWeight.bold)),
                  // Add rating selection
                  
                  // Stock availability
                  CheckboxListTile(
                    title: const Text('In Stock Only'),
                    value: _inStockOnly,
                    onChanged: (value) => setState(() => _inStockOnly = value ?? false),
                  ),
                ],
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _clearAllFilters,
                  child: const Text('Clear All'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _performSearch();
                  },
                  child: const Text('Apply Filters'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _getSuggestionIcon(String type) {
    switch (type) {
      case 'product':
        return const Icon(Icons.shopping_bag);
      case 'category':
        return const Icon(Icons.category);
      case 'brand':
        return const Icon(Icons.business);
      case 'recent':
        return const Icon(Icons.history);
      case 'trending':
        return const Icon(Icons.trending_up);
      default:
        return const Icon(Icons.search);
    }
  }

  Future<void> _startVoiceSearch() async {
    // Placeholder for voice search
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Voice search feature coming soon!')),
    );
  }

  Future<void> _scanBarcode() async {
    // Placeholder for barcode scanning
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Barcode scanning feature coming soon!')),
    );
  }
}
