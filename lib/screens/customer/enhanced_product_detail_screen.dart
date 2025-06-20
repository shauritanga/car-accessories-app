import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:badges/badges.dart' as badges;
import '../../models/product_model.dart';
import '../../providers/cart_provider.dart';
import '../../providers/review_provider.dart';

import '../../providers/auth_provider.dart';
import '../../widgets/review_widget.dart';
import 'product_reviews_screen.dart';

class EnhancedProductDetailScreen extends ConsumerStatefulWidget {
  final ProductModel product;

  const EnhancedProductDetailScreen({required this.product, super.key});

  @override
  ConsumerState<EnhancedProductDetailScreen> createState() =>
      _EnhancedProductDetailScreenState();
}

class _EnhancedProductDetailScreenState
    extends ConsumerState<EnhancedProductDetailScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  late TabController _tabController;
  int _currentPage = 0;
  int _quantity = 1;
  ProductVariant? _selectedVariant;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _pageController.addListener(() {
      setState(() {
        _currentPage = _pageController.page?.round() ?? 0;
      });
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.3),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        actions: [
          // Cart button
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
                child: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.shopping_cart_outlined,
                      color: Colors.white,
                    ),
                    onPressed: () => Navigator.pushNamed(context, '/cart'),
                  ),
                ),
              );
            },
          ),

          // Share button
          Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.share, color: Colors.white),
              onPressed: () => _shareProduct(),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Product images and basic info
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Image carousel with enhanced features
                  _buildImageCarousel(),

                  // Product info card
                  _buildProductInfoCard(theme, colorScheme),
                ],
              ),
            ),
          ),

          // Bottom action bar
          _buildBottomActionBar(theme, colorScheme),
        ],
      ),
    );
  }

  Widget _buildImageCarousel() {
    final images = widget.product.images;
    final hasVideos = widget.product.videos?.isNotEmpty == true;

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.5,
      child: Stack(
        children: [
          // Main Image Carousel
          Positioned.fill(
            child: Hero(
              tag: 'product-${widget.product.id}',
              child: PageView.builder(
                controller: _pageController,
                itemCount:
                    images.length +
                    (hasVideos ? widget.product.videos!.length : 0),
                itemBuilder: (context, index) {
                  if (index < images.length) {
                    // Image
                    return GestureDetector(
                      onTap: () => _showImageViewer(index),
                      child: CachedNetworkImage(
                        imageUrl: images[index],
                        fit: BoxFit.cover,
                        width: double.infinity,
                        placeholder:
                            (context, url) => Container(
                              color: Colors.grey[200],
                              child: const Center(
                                child: CircularProgressIndicator(),
                              ),
                            ),
                        errorWidget:
                            (context, url, error) => Container(
                              color: Colors.grey[200],
                              child: const Icon(Icons.error, size: 50),
                            ),
                      ),
                    );
                  } else {
                    // Video placeholder (would integrate with video player)
                    return Container(
                      color: Colors.black,
                      child: const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.play_circle_outline,
                              size: 64,
                              color: Colors.white,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Product Video',
                              style: TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                },
              ),
            ),
          ),

          // Discount badge
          if (widget.product.hasDiscount)
            Positioned(
              top: 60,
              left: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${widget.product.discountPercentage.toStringAsFixed(0)}% OFF',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),

          // Stock status badge
          Positioned(
            top: 60,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: widget.product.isInStock ? Colors.green : Colors.red,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                widget.product.stockStatus,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),

          // Page indicator
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: SmoothPageIndicator(
                  controller: _pageController,
                  count:
                      images.length +
                      (hasVideos ? widget.product.videos!.length : 0),
                  effect: const WormEffect(
                    dotHeight: 8,
                    dotWidth: 8,
                    activeDotColor: Colors.white,
                    dotColor: Colors.grey,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductInfoCard(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product name and rating
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.product.brand != null) ...[
                      Text(
                        widget.product.brand!,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],
                    Text(
                      widget.product.name,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (widget.product.sku != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'SKU: ${widget.product.sku}',
                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
              // Rating
              if (widget.product.rating != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 18),
                      const SizedBox(width: 4),
                      Text(
                        widget.product.rating!.toStringAsFixed(1),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (widget.product.totalReviews != null) ...[
                        const SizedBox(width: 4),
                        Text(
                          '(${widget.product.totalReviews})',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
            ],
          ),

          const SizedBox(height: 16),

          // Price section
          _buildPriceSection(theme, colorScheme),

          const SizedBox(height: 20),

          // Variants selection
          if (widget.product.variants?.isNotEmpty == true)
            _buildVariantsSection(theme),

          const SizedBox(height: 20),

          // Tabs for detailed information
          _buildDetailTabs(theme, colorScheme),
        ],
      ),
    );
  }

  Widget _buildPriceSection(ThemeData theme, ColorScheme colorScheme) {
    return Row(
      children: [
        if (widget.product.hasDiscount) ...[
          Text(
            'TZS ${widget.product.originalPrice!.toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[500],
              decoration: TextDecoration.lineThrough,
            ),
          ),
          const SizedBox(width: 8),
        ],
        Text(
          'TZS ${widget.product.price.toStringAsFixed(0)}',
          style: theme.textTheme.titleLarge?.copyWith(
            color: colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (widget.product.hasDiscount) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'Save TZS ${widget.product.discountAmount.toStringAsFixed(0)}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ],
    );
  }

  // Continue with more methods...
  Widget _buildVariantsSection(ThemeData theme) {
    // Group variants by type
    final variantGroups = <String, List<ProductVariant>>{};
    for (final variant in widget.product.variants!) {
      variantGroups.putIfAbsent(variant.type, () => []).add(variant);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children:
          variantGroups.entries.map((entry) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.key.toUpperCase(),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children:
                      entry.value.map((variant) {
                        final isSelected = _selectedVariant?.id == variant.id;
                        return GestureDetector(
                          onTap:
                              () => setState(() => _selectedVariant = variant),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color:
                                    isSelected
                                        ? theme.colorScheme.primary
                                        : Colors.grey[300]!,
                                width: isSelected ? 2 : 1,
                              ),
                              borderRadius: BorderRadius.circular(8),
                              color:
                                  isSelected
                                      ? theme.colorScheme.primary.withValues(
                                        alpha: 0.1,
                                      )
                                      : null,
                            ),
                            child: Text(
                              variant.value,
                              style: TextStyle(
                                color:
                                    isSelected
                                        ? theme.colorScheme.primary
                                        : null,
                                fontWeight: isSelected ? FontWeight.bold : null,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                ),
                const SizedBox(height: 16),
              ],
            );
          }).toList(),
    );
  }

  Widget _buildDetailTabs(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: colorScheme.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: colorScheme.primary,
          tabs: const [
            Tab(text: 'Description'),
            Tab(text: 'Specifications'),
            Tab(text: 'Shipping'),
            Tab(text: 'Returns'),
            Tab(text: 'Reviews'),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 300,
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildDescriptionTab(),
              _buildSpecificationsTab(),
              _buildShippingTab(),
              _buildReturnsTab(),
              _buildReviewsTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionTab() {
    return SingleChildScrollView(
      child: Text(
        widget.product.description,
        style: const TextStyle(height: 1.6),
      ),
    );
  }

  Widget _buildSpecificationsTab() {
    final specs = widget.product.specifications ?? {};

    if (specs.isEmpty) {
      return const Center(child: Text('No specifications available'));
    }

    return SingleChildScrollView(
      child: Column(
        children:
            specs.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        entry.key,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                    Expanded(flex: 3, child: Text(entry.value.toString())),
                  ],
                ),
              );
            }).toList(),
      ),
    );
  }

  Widget _buildShippingTab() {
    final shipping = widget.product.shippingInfo;

    if (shipping == null) {
      return const Center(child: Text('Shipping information not available'));
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow('Weight', '${shipping.weight} kg'),
          _buildInfoRow(
            'Estimated Delivery',
            '${shipping.estimatedDeliveryDays} days',
          ),
          if (shipping.freeShippingEligible)
            _buildInfoRow('Free Shipping', 'Eligible'),
          const SizedBox(height: 16),
          const Text(
            'Shipping Methods:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...shipping.shippingMethods.map((method) {
            final cost = shipping.shippingCosts[method] ?? 0.0;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(method),
                  Text('TZS ${cost.toStringAsFixed(0)}'),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildReturnsTab() {
    final returns = widget.product.returnPolicy;

    if (returns == null) {
      return const Center(child: Text('Return policy not available'));
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow('Returnable', returns.returnable ? 'Yes' : 'No'),
          if (returns.returnable) ...[
            _buildInfoRow('Return Period', '${returns.returnPeriodDays} days'),
            _buildInfoRow('Free Returns', returns.freeReturns ? 'Yes' : 'No'),
            const SizedBox(height: 16),
            const Text(
              'Conditions:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(returns.returnConditions),
            const SizedBox(height: 16),
            const Text(
              'Instructions:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(returns.returnInstructions),
          ],
        ],
      ),
    );
  }

  Widget _buildReviewsTab() {
    // This would integrate with the existing review system
    return const Center(child: Text('Reviews will be loaded here'));
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value),
        ],
      ),
    );
  }

  Widget _buildBottomActionBar(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Quantity selector
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove),
                  onPressed:
                      _quantity > 1 ? () => setState(() => _quantity--) : null,
                ),
                Text(
                  _quantity.toString(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed:
                      _quantity < widget.product.stock
                          ? () => setState(() => _quantity++)
                          : null,
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),

          // Add to cart button
          Expanded(
            child: ElevatedButton(
              onPressed: widget.product.isInStock ? () => _addToCart() : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                widget.product.isInStock ? 'Add to Cart' : 'Out of Stock',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Action methods

  void _addToCart() {
    final cartNotifier = ref.read(cartProvider.notifier);
    cartNotifier.addProduct(widget.product, _quantity);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${widget.product.name} added to cart'),
        action: SnackBarAction(
          label: 'View Cart',
          onPressed: () => Navigator.pushNamed(context, '/cart'),
        ),
      ),
    );
  }

  void _shareProduct() {
    // Implement product sharing
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Share functionality coming soon!')),
    );
  }

  void _showImageViewer(int initialIndex) {
    // Implement full-screen image viewer
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => Scaffold(
              backgroundColor: Colors.black,
              appBar: AppBar(
                backgroundColor: Colors.transparent,
                iconTheme: const IconThemeData(color: Colors.white),
              ),
              body: PageView.builder(
                controller: PageController(initialPage: initialIndex),
                itemCount: widget.product.images.length,
                itemBuilder: (context, index) {
                  return InteractiveViewer(
                    child: CachedNetworkImage(
                      imageUrl: widget.product.images[index],
                      fit: BoxFit.contain,
                      placeholder:
                          (context, url) => const Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                            ),
                          ),
                    ),
                  );
                },
              ),
            ),
      ),
    );
  }
}
