import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/product_model.dart';
import '../services/product_tracking_service.dart';

class RelatedProductsWidget extends StatefulWidget {
  final ProductModel currentProduct;
  final Function(ProductModel)? onProductTap;

  const RelatedProductsWidget({
    super.key,
    required this.currentProduct,
    this.onProductTap,
  });

  @override
  State<RelatedProductsWidget> createState() => _RelatedProductsWidgetState();
}

class _RelatedProductsWidgetState extends State<RelatedProductsWidget> {
  final ProductTrackingService _trackingService = ProductTrackingService();
  List<ProductModel> _relatedProducts = [];
  List<ProductModel> _frequentlyBoughtTogether = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRelatedProducts();
  }

  Future<void> _loadRelatedProducts() async {
    try {
      final related = await _trackingService.getRelatedProducts(widget.currentProduct);
      final frequentlyBought = await _trackingService.getFrequentlyBoughtTogether(
        widget.currentProduct.id,
      );

      setState(() {
        _relatedProducts = related;
        _frequentlyBoughtTogether = frequentlyBought;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Frequently Bought Together
        if (_frequentlyBoughtTogether.isNotEmpty) ...[
          _buildSectionHeader('Frequently Bought Together'),
          const SizedBox(height: 12),
          _buildFrequentlyBoughtTogether(),
          const SizedBox(height: 24),
        ],

        // Related Products
        if (_relatedProducts.isNotEmpty) ...[
          _buildSectionHeader('Related Products'),
          const SizedBox(height: 12),
          _buildRelatedProductsList(),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildFrequentlyBoughtTogether() {
    return Container(
      height: 280,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Buy together and save',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Row(
                  children: [
                    // Current product
                    Expanded(
                      child: _buildFrequentlyBoughtItem(widget.currentProduct, isMain: true),
                    ),
                    const Icon(Icons.add, color: Colors.grey),
                    // Related products
                    ...(_frequentlyBoughtTogether.take(2).map((product) => Expanded(
                      child: _buildFrequentlyBoughtItem(product),
                    ))),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Total price and add all button
              _buildBuyTogetherFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFrequentlyBoughtItem(ProductModel product, {bool isMain = false}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: isMain ? Colors.blue : Colors.grey[300]!,
                  width: isMain ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: product.images.isNotEmpty ? product.images.first : '',
                  fit: BoxFit.cover,
                  width: double.infinity,
                  placeholder: (context, url) => Container(
                    color: Colors.grey[200],
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey[200],
                    child: const Icon(Icons.image),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            product.name,
            style: const TextStyle(fontSize: 12),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            'TZS ${product.price.toStringAsFixed(0)}',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBuyTogetherFooter() {
    final totalPrice = widget.currentProduct.price +
        _frequentlyBoughtTogether.take(2).fold<double>(
          0,
          (sum, product) => sum + product.price,
        );

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Total:',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              Text(
                'TZS ${totalPrice.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
        ),
        ElevatedButton(
          onPressed: () => _addAllToCart(),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text('Add All to Cart'),
        ),
      ],
    );
  }

  Widget _buildRelatedProductsList() {
    return SizedBox(
      height: 220,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _relatedProducts.length,
        itemBuilder: (context, index) {
          final product = _relatedProducts[index];
          return _buildRelatedProductCard(product);
        },
      ),
    );
  }

  Widget _buildRelatedProductCard(ProductModel product) {
    final theme = Theme.of(context);
    
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 12),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          onTap: () => widget.onProductTap?.call(product),
          borderRadius: BorderRadius.circular(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product image
              Expanded(
                flex: 3,
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    child: Stack(
                      children: [
                        CachedNetworkImage(
                          imageUrl: product.images.isNotEmpty ? product.images.first : '',
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          placeholder: (context, url) => Container(
                            color: Colors.grey[200],
                            child: const Center(child: CircularProgressIndicator()),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: Colors.grey[200],
                            child: const Icon(Icons.image),
                          ),
                        ),
                        // Rating badge
                        if (product.rating != null)
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.7),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.star, size: 12, color: Colors.amber),
                                  const SizedBox(width: 2),
                                  Text(
                                    product.rating!.toStringAsFixed(1),
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              
              // Product details
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Product name
                      Text(
                        product.name,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Spacer(),
                      
                      // Price
                      Row(
                        children: [
                          if (product.hasDiscount) ...[
                            Text(
                              'TZS ${product.originalPrice!.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.grey,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                            const SizedBox(width: 4),
                          ],
                          Expanded(
                            child: Text(
                              'TZS ${product.price.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _addAllToCart() {
    // This would add all frequently bought together items to cart
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All items added to cart!'),
        backgroundColor: Colors.green,
      ),
    );
  }
}
