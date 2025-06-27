import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/social_provider.dart';
import '../../services/product_service.dart';
import '../../models/product_model.dart';

final socialProvider = ChangeNotifierProvider<SocialProvider>(
  (ref) => SocialProvider(),
);

class WishlistScreen extends ConsumerStatefulWidget {
  const WishlistScreen({super.key});

  @override
  ConsumerState<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends ConsumerState<WishlistScreen> {
  final ProductService _productService = ProductService();

  @override
  void initState() {
    super.initState();
    // Load wishlist when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(socialProvider).loadWishlist('current_user_id');
    });
  }

  @override
  Widget build(BuildContext context) {
    final socialProviderValue = ref.watch(socialProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Wishlist'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Builder(
        builder: (context) {
          if (socialProviderValue.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (socialProviderValue.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading wishlist',
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    socialProviderValue.error!,
                    style: TextStyle(color: Colors.grey[500], fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      socialProviderValue.clearError();
                      socialProviderValue.loadWishlist('current_user_id');
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (socialProviderValue.wishlist.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.favorite_border,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Your wishlist is empty',
                    style: TextStyle(color: Colors.grey[600], fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start adding products to your wishlist!',
                    style: TextStyle(color: Colors.grey[500], fontSize: 14),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: socialProviderValue.wishlist.length,
            itemBuilder: (context, index) {
              final wishlistItem = socialProviderValue.wishlist[index];
              return FutureBuilder<ProductModel?>(
                future: _getProduct(wishlistItem.productId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Card(
                      child: ListTile(
                        leading: CircularProgressIndicator(),
                        title: Text('Loading...'),
                      ),
                    );
                  }

                  if (snapshot.hasError || !snapshot.hasData) {
                    return Card(
                      child: ListTile(
                        leading: Icon(Icons.error, color: Colors.red),
                        title: Text('Product not found'),
                        subtitle: Text('ID: ${wishlistItem.productId}'),
                        trailing: IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            socialProviderValue.removeFromWishlist(
                              wishlistItem.id,
                            );
                          },
                        ),
                      ),
                    );
                  }

                  final product = snapshot.data!;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading:
                          product.images.isNotEmpty
                              ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  product.images.first,
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      width: 60,
                                      height: 60,
                                      decoration: BoxDecoration(
                                        color: Colors.grey[300],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        Icons.image,
                                        color: Colors.grey[600],
                                      ),
                                    );
                                  },
                                ),
                              )
                              : Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.image,
                                  color: Colors.grey[600],
                                ),
                              ),
                      title: Text(
                        product.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'TZS ${product.price.toStringAsFixed(0)}',
                            style: TextStyle(
                              color: Colors.green[700],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Added on ${_formatDate(wishlistItem.addedAt)}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.shopping_cart, color: Colors.blue),
                            onPressed: () {
                              // Add to cart functionality
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Added ${product.name} to cart',
                                  ),
                                ),
                              );
                            },
                          ),
                          IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              _showRemoveDialog(
                                context,
                                socialProviderValue,
                                wishlistItem,
                                product,
                              );
                            },
                          ),
                        ],
                      ),
                      onTap: () {
                        // Navigate to product detail
                        Navigator.pushNamed(
                          context,
                          '/product-detail',
                          arguments: product,
                        );
                      },
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Future<ProductModel?> _getProduct(String productId) async {
    try {
      // Use the product service directly to get a single product
      final products = await _productService.getProducts().first;
      return products.firstWhere((product) => product.id == productId);
    } catch (e) {
      return null;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showRemoveDialog(
    BuildContext context,
    SocialProvider socialProvider,
    wishlistItem,
    ProductModel product,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Remove from Wishlist'),
          content: Text(
            'Are you sure you want to remove "${product.name}" from your wishlist?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                socialProvider.removeFromWishlist(wishlistItem.id);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Removed ${product.name} from wishlist'),
                  ),
                );
              },
              child: const Text('Remove', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}
