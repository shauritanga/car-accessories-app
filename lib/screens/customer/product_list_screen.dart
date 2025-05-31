import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:badges/badges.dart' as badges;
import '../../providers/product_provider.dart';
import '../../providers/cart_provider.dart';
import '../../widgets/product_card.dart';

class ProductListScreen extends ConsumerStatefulWidget {
  const ProductListScreen({super.key});

  @override
  ConsumerState<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends ConsumerState<ProductListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedCategory;
  String? _selectedModel;
  String _sortBy = 'popularity';
  RangeValues _priceRange = const RangeValues(0, 100000);
  bool _showFilters = false;

  final List<String> _categories = [
    'Interior',
    'Exterior',
    'Electronics',
    'Performance',
    'Safety',
    'Lighting',
  ];

  final List<String> _carModels = [
    'Toyota',
    'Honda',
    'Ford',
    'BMW',
    'Mercedes',
    'Audi',
  ];

  @override
  void initState() {
    super.initState();
    ref.read(productProvider.notifier).searchProducts();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    _applyFilters();
  }

  void _applyFilters() {
    print(
      'Applying filters - Category: $_selectedCategory, Model: $_selectedModel, Query: ${_searchController.text}',
    );
    ref
        .read(productProvider.notifier)
        .searchProducts(
          query: _searchController.text,
          category: _selectedCategory,
          model: _selectedModel,
        );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productState = ref.watch(productProvider);
    final cartNotifier = ref.read(cartProvider.notifier);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Browse Accessories'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              setState(() {
                _showFilters = !_showFilters;
              });
            },
          ),
          Consumer(
            builder: (context, ref, child) {
              final cart = ref.watch(cartProvider);
              return badges.Badge(
                showBadge: cart.items.isNotEmpty,
                position: badges.BadgePosition.topEnd(top: 0, end: 3),
                badgeContent: Text(
                  '${cart.items.length}',
                  style: const TextStyle(color: Colors.white, fontSize: 10),
                ),
                badgeStyle: const badges.BadgeStyle(
                  badgeColor: Colors.red,
                  padding: EdgeInsets.all(5),
                ),
                child: IconButton(
                  icon: const Icon(Icons.shopping_cart),
                  onPressed: () {
                    Navigator.pushNamed(context, '/cart');
                  },
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search accessories...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey.shade200,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),

          // Expandable filters section
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: _showFilters ? 280 : 0,
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Categories',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children:
                          _categories.map((category) {
                            final isSelected = _selectedCategory == category;
                            return FilterChip(
                              label: Text(category),
                              selected: isSelected,
                              onSelected: (selected) {
                                setState(() {
                                  _selectedCategory =
                                      selected ? category : null;
                                });
                                _applyFilters();
                              },
                              backgroundColor: Colors.grey.shade200,
                              selectedColor: theme.colorScheme.primary
                                  .withOpacity(0.2),
                              checkmarkColor: theme.colorScheme.primary,
                            );
                          }).toList(),
                    ),

                    const SizedBox(height: 16),
                    const Text(
                      'Car Models',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children:
                          _carModels.map((model) {
                            final isSelected = _selectedModel == model;
                            return FilterChip(
                              label: Text(model),
                              selected: isSelected,
                              onSelected: (selected) {
                                setState(() {
                                  _selectedModel = selected ? model : null;
                                });
                                _applyFilters();
                              },
                              backgroundColor: Colors.grey.shade200,
                              selectedColor: theme.colorScheme.primary
                                  .withOpacity(0.2),
                              checkmarkColor: theme.colorScheme.primary,
                            );
                          }).toList(),
                    ),

                    const SizedBox(height: 16),
                    const Text(
                      'Price Range',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    RangeSlider(
                      values: _priceRange,
                      min: 0,
                      max: 100000,
                      divisions: 20,
                      labels: RangeLabels(
                        'TZS ${_priceRange.start.round()}',
                        'TZS ${_priceRange.end.round()}',
                      ),
                      onChanged: (values) {
                        setState(() {
                          _priceRange = values;
                        });
                      },
                      onChangeEnd: (values) {
                        _applyFilters();
                      },
                    ),

                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        OutlinedButton.icon(
                          icon: const Icon(Icons.clear_all),
                          label: const Text('Clear All'),
                          onPressed: () {
                            setState(() {
                              _selectedCategory = null;
                              _selectedModel = null;
                              _priceRange = const RangeValues(0, 100000);
                              _searchController.clear();
                            });
                            _applyFilters();
                          },
                        ),
                        DropdownButton<String>(
                          value: _sortBy,
                          hint: const Text('Sort by'),
                          items: const [
                            DropdownMenuItem(
                              value: 'popularity',
                              child: Text('Popularity'),
                            ),
                            DropdownMenuItem(
                              value: 'price_low',
                              child: Text('Price: Low to High'),
                            ),
                            DropdownMenuItem(
                              value: 'price_high',
                              child: Text('Price: High to Low'),
                            ),
                            DropdownMenuItem(
                              value: 'rating',
                              child: Text('Rating'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _sortBy = value;
                              });
                              _applyFilters();
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Results count and loading indicator
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${productState.products.length} results',
                  style: TextStyle(color: Colors.grey.shade700),
                ),
                if (productState.products.isNotEmpty)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
          ),

          // Product grid
          Expanded(
            child:
                productState.products.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No products found',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    )
                    : GridView.builder(
                      padding: const EdgeInsets.all(12.0),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.85,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                      itemCount: productState.products.length,
                      itemBuilder: (context, index) {
                        final product = productState.products[index];
                        return GestureDetector(
                          onTap: () {
                            context.goNamed(
                              'product_detail',
                              pathParameters: {'id': product.id},
                              extra: product,
                            );
                          },
                          child: ProductCard(product: product),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }
}
