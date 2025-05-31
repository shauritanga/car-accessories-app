import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:badges/badges.dart' as badges;
import '../../providers/auth_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/cart_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    ref.read(authProvider.notifier);
    final productState = ref.watch(productProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Redirect to login if user is not authenticated
    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/login');
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Featured categories
    final categories = [
      {'name': 'Interior', 'icon': Icons.airline_seat_recline_normal},
      {'name': 'Exterior', 'icon': Icons.directions_car},
      {'name': 'Electronics', 'icon': Icons.speaker},
      {'name': 'Lighting', 'icon': Icons.lightbulb_outline},
      {'name': 'Maintenance', 'icon': Icons.build},
      {'name': 'Accessories', 'icon': Icons.category},
    ];

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // App Bar
            SliverAppBar(
              floating: true,
              title: Row(
                children: [
                  Icon(Icons.directions_car, color: colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    'AutoAccessories',
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  icon: Icon(
                    Icons.notifications_outlined,
                    color: colorScheme.onSurface,
                  ),
                  onPressed: () {
                    // Navigate to notifications
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Notifications coming soon'),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: Icon(
                    Icons.person_outline,
                    color: colorScheme.onSurface,
                  ),
                  onPressed: () {
                    Navigator.pushNamed(context, '/profile');
                  },
                ),
              ],
              backgroundColor: colorScheme.surface,
              elevation: 0,
            ),

            // Main content
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Welcome message
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: colorScheme.primaryContainer,
                          radius: 24,
                          child: Text(
                            user.name?.substring(0, 1).toUpperCase() ?? 'C',
                            style: TextStyle(
                              color: colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome back,',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: colorScheme.onSurface.withOpacity(0.7),
                              ),
                            ),
                            Text(
                              user.name ?? 'Customer',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Search bar
                    InkWell(
                      onTap:
                          () => Navigator.pushNamed(context, '/product_list'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest
                              .withOpacity(0.5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: colorScheme.outline.withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.search,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Search for car accessories...',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant.withOpacity(
                                  0.8,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Quick actions
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildQuickAction(
                          context,
                          icon: Icons.shopping_cart_outlined,
                          label: 'My Cart',
                          onTap: () => Navigator.pushNamed(context, '/cart'),
                          color: colorScheme.primary,
                          badge:
                              ref
                                  .watch(cartProvider)
                                  .items
                                  .length, // Pass the badge count
                        ),
                        _buildQuickAction(
                          context,
                          icon: Icons.history,
                          label: 'Orders',
                          onTap:
                              () => Navigator.pushNamed(
                                context,
                                '/order_history',
                              ),
                          color: colorScheme.tertiary,
                        ),
                        _buildQuickAction(
                          context,
                          icon: Icons.favorite_border,
                          label: 'Wishlist',
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Wishlist coming soon'),
                              ),
                            );
                          },
                          color: colorScheme.secondary,
                        ),
                        _buildQuickAction(
                          context,
                          icon: Icons.local_shipping_outlined,
                          label: 'Track',
                          onTap:
                              () => Navigator.pushNamed(
                                context,
                                '/order_history',
                              ),
                          color: colorScheme.error,
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Special offers carousel
                    _buildSectionTitle(context, 'Special Offers'),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 160,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _buildOfferCard(
                            context,
                            title: 'Summer Sale',
                            subtitle:
                                'Up to 40% off on all exterior accessories',
                            color: Colors.blue.shade800,
                            assetImage: 'assets/images/summer_sale.jpg',
                          ),
                          _buildOfferCard(
                            context,
                            title: 'New Arrivals',
                            subtitle: 'Check out our latest premium products',
                            color: Colors.orange.shade800,
                            assetImage: 'assets/images/new_arrivals.jpg',
                          ),
                          _buildOfferCard(
                            context,
                            title: 'Bundle Deals',
                            subtitle: 'Save big with our curated packages',
                            color: Colors.green.shade800,
                            assetImage: 'assets/images/bundle_deals.jpg',
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Categories
                    _buildSectionTitle(context, 'Browse Categories'),
                    const SizedBox(height: 12),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            childAspectRatio: 1.1,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                          ),
                      itemCount: categories.length,
                      itemBuilder: (context, index) {
                        return _buildCategoryCard(
                          context,
                          icon: categories[index]['icon'] as IconData,
                          name: categories[index]['name'] as String,
                        );
                      },
                    ),

                    const SizedBox(height: 24),

                    // Popular products
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildSectionTitle(context, 'Popular Products'),
                        TextButton(
                          onPressed:
                              () =>
                                  Navigator.pushNamed(context, '/product_list'),
                          child: Text(
                            'See All',
                            style: TextStyle(color: colorScheme.primary),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 220,
                      child:
                          productState.products.isEmpty
                              ? Center(
                                child: CircularProgressIndicator(
                                  color: colorScheme.primary,
                                ),
                              )
                              : ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount:
                                    productState.products.length > 5
                                        ? 5
                                        : productState.products.length,
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
                                    child: Container(
                                      width: 160,
                                      margin: const EdgeInsets.only(right: 16),
                                      decoration: BoxDecoration(
                                        color: colorScheme.surface,
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(
                                            color: colorScheme.shadow
                                                .withOpacity(0.1),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // Product image
                                          ClipRRect(
                                            borderRadius:
                                                const BorderRadius.vertical(
                                                  top: Radius.circular(12),
                                                ),
                                            child: CachedNetworkImage(
                                              imageUrl:
                                                  product.images.isNotEmpty
                                                      ? product.images[0]
                                                      : '',
                                              height: 120,
                                              width: double.infinity,
                                              fit: BoxFit.cover,
                                              placeholder:
                                                  (context, url) => Container(
                                                    color:
                                                        colorScheme
                                                            .surfaceContainerHighest,
                                                    child: const Center(
                                                      child: SizedBox(
                                                        width: 24,
                                                        height: 24,
                                                        child:
                                                            CircularProgressIndicator(
                                                              strokeWidth: 2,
                                                            ),
                                                      ),
                                                    ),
                                                  ),
                                              errorWidget:
                                                  (
                                                    context,
                                                    url,
                                                    error,
                                                  ) => Container(
                                                    color:
                                                        colorScheme
                                                            .surfaceContainerHighest,
                                                    child: const Icon(
                                                      Icons.error,
                                                    ),
                                                  ),
                                            ),
                                          ),
                                          // Product details
                                          Padding(
                                            padding: const EdgeInsets.all(12),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  product.name,
                                                  style:
                                                      theme
                                                          .textTheme
                                                          .titleSmall,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  'TZS ${product.price.toStringAsFixed(0)}',
                                                  style: TextStyle(
                                                    color: colorScheme.primary,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                Row(
                                                  children: [
                                                    Icon(
                                                      Icons.star,
                                                      size: 16,
                                                      color: Colors.amber,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      product.rating
                                                              ?.toStringAsFixed(
                                                                1,
                                                              ) ??
                                                          '4.5',
                                                      style:
                                                          theme
                                                              .textTheme
                                                              .bodySmall,
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAction(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
    int? badge,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          badges.Badge(
            showBadge: badge != null && badge > 0,
            badgeContent: Text(
              '$badge',
              style: const TextStyle(color: Colors.white, fontSize: 10),
            ),
            badgeStyle: badges.BadgeStyle(
              badgeColor: Colors.red,
              padding: const EdgeInsets.all(5),
            ),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
          ),
          const SizedBox(height: 8),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(
        context,
      ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
    );
  }

  Widget _buildOfferCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required Color color,
    required String assetImage,
  }) {
    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: color,
        image: DecorationImage(
          image: AssetImage(assetImage),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            color.withOpacity(0.8),
            BlendMode.srcOver,
          ),
        ),
      ),
      child: Stack(
        children: [
          // Gradient overlay for better text visibility
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
              ),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Shop Now',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(
    BuildContext context, {
    required IconData icon,
    required String name,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          '/product_list',
          arguments: {'category': name},
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colorScheme.outline.withOpacity(0.1)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: colorScheme.primary, size: 28),
            const SizedBox(height: 8),
            Text(
              name,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
