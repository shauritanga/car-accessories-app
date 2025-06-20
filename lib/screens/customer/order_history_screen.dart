import 'package:car_accessories/providers/order_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../models/order_model.dart';
import 'order_modification_screen.dart';

class OrderHistoryScreen extends ConsumerStatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  ConsumerState<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends ConsumerState<OrderHistoryScreen> {
  bool _isRefreshing = false;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);

    // Debug print to check user ID
    print('Current user: ${user?.id}');

    // Create the filter
    final filter =
        user != null ? OrderFilter(userId: user.id, role: 'customer') : null;

    // Debug print the filter
    print('Order filter: ${filter?.userId}, role: ${filter?.role}');

    // Watch the orders stream only if we have a valid filter
    final ordersAsync =
        filter != null
            ? ref.watch(orderStreamProviderSimple(filter))
            : const AsyncValue.loading();

    // Redirect to login if user is not authenticated
    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/login');
      });
      return Scaffold(
        appBar: AppBar(title: const Text('Order History')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Order History')),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() => _isRefreshing = true);
          // Invalidate the stream provider to force a refresh
          if (filter != null) {
            ref.invalidate(orderStreamProviderSimple(filter));
          }
          // Wait a moment to allow the stream to reconnect
          await Future.delayed(const Duration(seconds: 1));
          if (mounted) {
            setState(() => _isRefreshing = false);
          }
        },
        child: Stack(
          children: [
            ordersAsync.when(
              data: (orders) {
                // Debug print the orders
                print('Received ${orders.length} orders');

                if (orders.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No orders found',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Your order history will appear here',
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.shopping_bag_outlined),
                          label: const Text('Start Shopping'),
                          onPressed:
                              () =>
                                  Navigator.pushNamed(context, '/product_list'),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    return OrderCard(order: order);
                  },
                );
              },
              loading: () {
                print('Orders are loading...');
                return const Center(child: CircularProgressIndicator());
              },
              error: (error, stack) {
                print('Error loading orders: $error');
                print('Stack trace: $stack');
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      Text('Error: $error'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          if (filter != null) {
                            ref.invalidate(orderStreamProviderSimple(filter));
                          }
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              },
            ),
            if (_isRefreshing) const Center(child: CircularProgressIndicator()),
          ],
        ),
      ),
    );
  }
}

class OrderCard extends StatelessWidget {
  final OrderModel order;

  const OrderCard({required this.order, super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final dateFormat = DateFormat('MMM dd, yyyy • hh:mm a');

    // Status color mapping
    final statusColors = {
      'pending': Colors.orange,
      'processing': Colors.blue,
      'shipped': Colors.indigo,
      'delivered': Colors.green,
      'cancelled': Colors.red,
    };

    final statusColor = statusColors[order.status] ?? Colors.grey;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap:
            () => Navigator.pushNamed(
              context,
              '/order_tracking',
              arguments: order,
            ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Order header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Order #${order.id.substring(0, 8)}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      order.status.toUpperCase(),
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Order date
              Text(
                'Placed on ${dateFormat.format(order.createdAt)}',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),

              const Divider(height: 24),

              // Order items
              Text(
                'Items (${order.items.length})',
                style: theme.textTheme.titleSmall,
              ),

              const SizedBox(height: 8),

              ...List.generate(
                order.items.length > 3 ? 3 : order.items.length,
                (index) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Product ID: ${order.items[index].productId.substring(0, 8)}',
                          style: const TextStyle(fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        'x${order.items[index].quantity}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              if (order.items.length > 3)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '+ ${order.items.length - 3} more items',
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontSize: 14,
                    ),
                  ),
                ),

              const Divider(height: 24),

              // Order total
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total Amount', style: theme.textTheme.titleSmall),
                  Text(
                    'TZS ${order.total.toStringAsFixed(2)}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.local_shipping_outlined),
                      label: const Text('Track Order'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(color: colorScheme.primary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed:
                          () => Navigator.pushNamed(
                            context,
                            '/order_tracking',
                            arguments: order,
                          ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.more_horiz),
                      label: const Text('Options'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(color: Colors.grey[400]!),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed:
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) =>
                                      OrderModificationScreen(order: order),
                            ),
                          ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
