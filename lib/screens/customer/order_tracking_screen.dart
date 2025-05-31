import 'package:car_accessories/models/product_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart'; // For formatting dates
import '../../models/order_model.dart';
import '../../providers/product_provider.dart';

class OrderTrackingScreen extends ConsumerWidget {
  const OrderTrackingScreen({required this.order, super.key});
  final OrderModel order;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Safely extract the OrderModel from route arguments
    // final Object? arguments = ModalRoute.of(context)?.settings.arguments;
    // if (arguments == null || arguments is! OrderModel) {
    //   return Scaffold(
    //     appBar: AppBar(title: const Text('Track Order')),
    //     body: const Center(child: Text('Invalid order data')),
    //   );
    // }

    // // Use the already validated OrderModel directly
    // final OrderModel order = arguments;

    return Scaffold(
      appBar: AppBar(title: Text('Track Order #${order.id}')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Status: ${order.status}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Ordered on: ${DateFormat.yMMMd().add_jm().format(order.createdAt)}',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              const Text(
                'Items:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...order.items.map((item) {
                // Fetch the product details for this item using the productId
                final productFilter = ProductFilter(
                  query: null,
                  category: null,
                  model: null,
                );
                final productsAsync = ref.watch(
                  productStreamProvider(productFilter),
                );

                return productsAsync.when(
                  data: (products) {
                    final product = products.firstWhere(
                      (p) => p.id == item.productId,
                      orElse:
                          () => ProductModel(
                            id: item.productId,
                            name: 'Unknown Product',
                            description: '',
                            price: item.price,
                            category: '',
                            stock: 0,
                            compatibility: [],
                            sellerId: '',
                            images: [],
                          ),
                    );
                    return ListTile(
                      title: Text(product.name),
                      subtitle: Text(
                        'Quantity: ${item.quantity} | Price: TZS ${item.price.toStringAsFixed(2)}',
                      ),
                    );
                  },
                  loading:
                      () => const ListTile(
                        title: Text('Loading...'),
                        subtitle: Text('Quantity: ... | Price: ...'),
                      ),
                  error:
                      (error, stack) => ListTile(
                        title: const Text('Error loading product'),
                        subtitle: Text('Error: $error'),
                      ),
                );
              }),
              const SizedBox(height: 16),
              Text(
                'Total: TZS ${order.total.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
