import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/search_filter_model.dart';
import '../../providers/search_provider.dart';
import '../../widgets/product_grid.dart';
import 'search_filters_screen.dart';

class AdvancedSearchScreen extends ConsumerStatefulWidget {
  const AdvancedSearchScreen({super.key});

  @override
  ConsumerState<AdvancedSearchScreen> createState() => _AdvancedSearchScreenState();
}

class _AdvancedSearchScreenState extends ConsumerState<AdvancedSearchScreen> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  bool _showResults = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus) {
      ref.read(searchProvider.notifier).showSuggestions();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final searchState = ref.watch(searchProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Products'),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: _buildSearchBar(theme, searchState),
          ),
        ),
      ),
      body: Column(
        children: [
          // Filter bar
          if (_showResults) _buildFilterBar(theme, searchState),
          
          // Content
          Expanded(
            child: _showResults
                ? _buildSearchResults(searchState)
                : _buildSearchSuggestions(theme, searchState),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(ThemeData theme, SearchState searchState) {
    return Row(
      children: [
        Expanded(
          child: TextField(
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
                        ref.read(searchProvider.notifier).clearQuery();
                        setState(() => _showResults = false);
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
            onChanged: (value) {
              ref.read(searchProvider.notifier).updateQuery(value);
            },
            onSubmitted: (value) {
              if (value.isNotEmpty) {
                _performSearch();
              }
            },
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: Stack(
            children: [
              const Icon(Icons.tune),
              if (searchState.filter.hasActiveFilters)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '${searchState.filter.activeFilterCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          onPressed: () => _openFilters(context),
        ),
      ],
    );
  }

  Widget _buildFilterBar(ThemeData theme, SearchState searchState) {
    final filter = searchState.filter;
    
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Sort dropdown
          Expanded(
            child: DropdownButtonFormField<SortOption>(
              value: filter.sortBy,
              decoration: const InputDecoration(
                labelText: 'Sort by',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: SortOption.values.map((option) {
                return DropdownMenuItem(
                  value: option,
                  child: Text(
                    option.name,
                    style: const TextStyle(fontSize: 14),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  ref.read(searchProvider.notifier).setSortOption(value);
                  _performSearch();
                }
              },
            ),
          ),
          const SizedBox(width: 8),
          
          // Results count
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${searchState.results.length} results',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults(SearchState searchState) {
    if (searchState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (searchState.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: ${searchState.error}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _performSearch(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (searchState.results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text(
              'No products found',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            const Text('Try adjusting your search or filters'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref.read(searchProvider.notifier).clearAllFilters();
                setState(() => _showResults = false);
              },
              child: const Text('Clear Filters'),
            ),
          ],
        ),
      );
    }

    return ProductGrid(products: searchState.results);
  }

  Widget _buildSearchSuggestions(ThemeData theme, SearchState searchState) {
    if (!searchState.showSuggestions) {
      return _buildSearchHome(theme);
    }

    final suggestions = searchState.suggestions;
    final history = searchState.history;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search suggestions
          if (suggestions.isNotEmpty) ...[
            Text(
              'Suggestions',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...suggestions.map((suggestion) => ListTile(
              leading: Icon(_getSuggestionIcon(suggestion.type)),
              title: Text(suggestion.text),
              subtitle: suggestion.category != null
                  ? Text('in ${suggestion.category}')
                  : suggestion.resultCount != null
                      ? Text('${suggestion.resultCount} results')
                      : null,
              onTap: () {
                ref.read(searchProvider.notifier).selectSuggestion(suggestion);
                _searchController.text = suggestion.text;
                _performSearch();
              },
            )),
            const SizedBox(height: 24),
          ],

          // Search history
          if (history.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Searches',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    ref.read(searchProvider.notifier).clearSearchHistory();
                  },
                  child: const Text('Clear All'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...history.take(10).map((historyItem) => ListTile(
              leading: const Icon(Icons.history),
              title: Text(historyItem.query),
              subtitle: Text('${historyItem.resultCount} results • ${historyItem.timeAgo}'),
              trailing: IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () {
                  ref.read(searchProvider.notifier).removeFromHistory(historyItem.query);
                },
              ),
              onTap: () {
                _searchController.text = historyItem.query;
                ref.read(searchProvider.notifier).updateQuery(historyItem.query);
                _performSearch();
              },
            )),
          ],
        ],
      ),
    );
  }

  Widget _buildSearchHome(ThemeData theme) {
    final categoriesAsync = ref.watch(popularCategoriesProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Popular Categories',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          categoriesAsync.when(
            data: (categories) => Wrap(
              spacing: 8,
              runSpacing: 8,
              children: categories.take(10).map((category) => ActionChip(
                label: Text(category),
                onPressed: () {
                  ref.read(searchProvider.notifier).addCategory(category);
                  _performSearch();
                },
              )).toList(),
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Text('Error loading categories: $error'),
          ),
          const SizedBox(height: 32),
          Text(
            'Search Tips',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '• Use specific keywords like "brake pads" or "LED headlights"\n'
            '• Filter by your car model for compatible parts\n'
            '• Sort by price or rating to find the best deals\n'
            '• Use filters to narrow down your search',
            style: TextStyle(height: 1.5),
          ),
        ],
      ),
    );
  }

  IconData _getSuggestionIcon(SearchSuggestionType type) {
    switch (type) {
      case SearchSuggestionType.query:
        return Icons.search;
      case SearchSuggestionType.category:
        return Icons.category;
      case SearchSuggestionType.brand:
        return Icons.business;
      case SearchSuggestionType.product:
        return Icons.shopping_bag;
      case SearchSuggestionType.recent:
        return Icons.history;
    }
  }

  void _performSearch() {
    ref.read(searchProvider.notifier).search();
    ref.read(searchProvider.notifier).hideSuggestions();
    setState(() => _showResults = true);
    _focusNode.unfocus();
  }

  void _openFilters(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SearchFiltersScreen(),
      ),
    );

    if (result == true && _showResults) {
      _performSearch();
    }
  }
}
