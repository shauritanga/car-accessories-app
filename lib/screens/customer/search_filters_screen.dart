import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/search_filter_model.dart';
import '../../providers/search_provider.dart';

class SearchFiltersScreen extends ConsumerStatefulWidget {
  const SearchFiltersScreen({super.key});

  @override
  ConsumerState<SearchFiltersScreen> createState() => _SearchFiltersScreenState();
}

class _SearchFiltersScreenState extends ConsumerState<SearchFiltersScreen> {
  late SearchFilterModel _filter;
  final _minPriceController = TextEditingController();
  final _maxPriceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filter = ref.read(searchProvider).filter;
    _minPriceController.text = _filter.minPrice?.toString() ?? '';
    _maxPriceController.text = _filter.maxPrice?.toString() ?? '';
  }

  @override
  void dispose() {
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categoriesAsync = ref.watch(categoriesProvider);
    final priceRangeAsync = ref.watch(priceRangeProvider(null));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Filters'),
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _hasChanges() ? _resetFilters : null,
            child: const Text('Reset'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Categories
            _buildCategoriesSection(theme, categoriesAsync),
            const SizedBox(height: 24),

            // Price Range
            _buildPriceRangeSection(theme, priceRangeAsync),
            const SizedBox(height: 24),

            // Rating
            _buildRatingSection(theme),
            const SizedBox(height: 24),

            // Car Compatibility
            _buildCompatibilitySection(theme),
            const SizedBox(height: 24),

            // Availability
            _buildAvailabilitySection(theme),
            const SizedBox(height: 24),

            // Additional Filters
            _buildAdditionalFiltersSection(theme),
            const SizedBox(height: 32),

            // Apply Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _applyFilters,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  'Apply Filters${_filter.hasActiveFilters ? ' (${_filter.activeFilterCount})' : ''}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoriesSection(ThemeData theme, AsyncValue<List<String>> categoriesAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Categories',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        categoriesAsync.when(
          data: (categories) => Wrap(
            spacing: 8,
            runSpacing: 8,
            children: categories.map((category) {
              final isSelected = _filter.categories.contains(category);
              return FilterChip(
                label: Text(category),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _filter = _filter.copyWith(
                        categories: [..._filter.categories, category],
                      );
                    } else {
                      final newCategories = List<String>.from(_filter.categories);
                      newCategories.remove(category);
                      _filter = _filter.copyWith(categories: newCategories);
                    }
                  });
                },
              );
            }).toList(),
          ),
          loading: () => const CircularProgressIndicator(),
          error: (error, stack) => Text('Error loading categories: $error'),
        ),
      ],
    );
  }

  Widget _buildPriceRangeSection(ThemeData theme, AsyncValue<Map<String, double>> priceRangeAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Price Range (TZS)',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        priceRangeAsync.when(
          data: (priceRange) {
            final minPrice = priceRange['min'] ?? 0.0;
            final maxPrice = priceRange['max'] ?? 1000000.0;
            
            return Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _minPriceController,
                        decoration: const InputDecoration(
                          labelText: 'Min Price',
                          border: OutlineInputBorder(),
                          prefixText: 'TZS ',
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          final price = double.tryParse(value);
                          setState(() {
                            _filter = _filter.copyWith(minPrice: price);
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _maxPriceController,
                        decoration: const InputDecoration(
                          labelText: 'Max Price',
                          border: OutlineInputBorder(),
                          prefixText: 'TZS ',
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          final price = double.tryParse(value);
                          setState(() {
                            _filter = _filter.copyWith(maxPrice: price);
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Available range: TZS ${minPrice.toStringAsFixed(0)} - TZS ${maxPrice.toStringAsFixed(0)}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            );
          },
          loading: () => const CircularProgressIndicator(),
          error: (error, stack) => Text('Error loading price range: $error'),
        ),
      ],
    );
  }

  Widget _buildRatingSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Minimum Rating',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: [1.0, 2.0, 3.0, 4.0, 4.5].map((rating) {
            final isSelected = _filter.minRating == rating;
            return FilterChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.star, size: 16, color: Colors.amber),
                  const SizedBox(width: 4),
                  Text('${rating.toStringAsFixed(rating == rating.toInt() ? 0 : 1)}+'),
                ],
              ),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _filter = _filter.copyWith(
                    minRating: selected ? rating : null,
                  );
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCompatibilitySection(ThemeData theme) {
    final commonCarModels = [
      'Toyota Corolla',
      'Toyota Camry',
      'Toyota RAV4',
      'Honda Civic',
      'Honda Accord',
      'Nissan Sentra',
      'Mazda 3',
      'Subaru Outback',
      'Ford Focus',
      'Volkswagen Golf',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Car Compatibility',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: commonCarModels.map((carModel) {
            final isSelected = _filter.compatibility.contains(carModel);
            return FilterChip(
              label: Text(carModel),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _filter = _filter.copyWith(
                      compatibility: [..._filter.compatibility, carModel],
                    );
                  } else {
                    final newCompatibility = List<String>.from(_filter.compatibility);
                    newCompatibility.remove(carModel);
                    _filter = _filter.copyWith(compatibility: newCompatibility);
                  }
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildAvailabilitySection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Availability',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...AvailabilityFilter.values.map((availability) {
          return RadioListTile<AvailabilityFilter>(
            title: Text(_getAvailabilityDisplayName(availability)),
            value: availability,
            groupValue: _filter.availability,
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _filter = _filter.copyWith(availability: value);
                });
              }
            },
            contentPadding: EdgeInsets.zero,
          );
        }),
      ],
    );
  }

  Widget _buildAdditionalFiltersSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Additional Filters',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        CheckboxListTile(
          title: const Text('Free Shipping'),
          subtitle: const Text('Products with free shipping'),
          value: _filter.freeShipping,
          onChanged: (value) {
            setState(() {
              _filter = _filter.copyWith(freeShipping: value ?? false);
            });
          },
          contentPadding: EdgeInsets.zero,
        ),
        CheckboxListTile(
          title: const Text('On Sale'),
          subtitle: const Text('Products currently on sale'),
          value: _filter.onSale,
          onChanged: (value) {
            setState(() {
              _filter = _filter.copyWith(onSale: value ?? false);
            });
          },
          contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }

  String _getAvailabilityDisplayName(AvailabilityFilter availability) {
    switch (availability) {
      case AvailabilityFilter.all:
        return 'All Products';
      case AvailabilityFilter.inStock:
        return 'In Stock Only';
      case AvailabilityFilter.outOfStock:
        return 'Out of Stock';
    }
  }

  bool _hasChanges() {
    final originalFilter = ref.read(searchProvider).filter;
    return _filter != originalFilter;
  }

  void _resetFilters() {
    setState(() {
      _filter = SearchFilterModel(query: _filter.query);
      _minPriceController.clear();
      _maxPriceController.clear();
    });
  }

  void _applyFilters() {
    ref.read(searchProvider.notifier).updateFilter(_filter);
    Navigator.pop(context, true);
  }
}
