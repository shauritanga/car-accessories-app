import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';
import '../../models/order_model.dart';

class SellerOrdersScreen extends ConsumerStatefulWidget {
  const SellerOrdersScreen({super.key});

  @override
  ConsumerState<SellerOrdersScreen> createState() => _SellerOrdersScreenState();
}

class _SellerOrdersScreenState extends ConsumerState<SellerOrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isRefreshing = false;
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      // Update filter based on tab
      setState(() {
        switch (_tabController.index) {
          case 0:
            _selectedFilter = 'all';
            break;
          case 1:
            _selectedFilter = 'pending';
            break;
          case 2:
            _selectedFilter = 'processing';
            break;
          case 3:
            _selectedFilter = 'completed';
            break;
        }
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Orders')),
        body: Center(child: Text('Please log in to view orders')),
      );
    }

    // Create filter based on selected tab
    final OrderFilter filter = OrderFilter(
      userId: user.id,
      role: 'seller',
      status: _selectedFilter == 'all' ? null : _selectedFilter,
    );

    // Watch orders with the filter
    final ordersAsync = ref.watch(orderStreamProvider(filter));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Seller Orders'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Pending'),
            Tab(text: 'Processing'),
            Tab(text: 'Completed'),
          ],
          labelColor: Theme.of(context).colorScheme.primary,
          indicatorColor: Theme.of(context).colorScheme.primary,
          unselectedLabelColor: Colors.grey,
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() => _isRefreshing = true);
          // Invalidate the stream provider to force a refresh
          ref.invalidate(orderStreamProvider(filter));
          // Wait for the stream to emit new data
          ordersAsync.whenData((_) => setState(() => _isRefreshing = false));
        },
        child: Stack(
          children: [
            ordersAsync.when(
              data: (orders) {
                if (orders.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inbox_outlined,
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
                          _selectedFilter == 'all'
                              ? 'You don\'t have any orders yet'
                              : 'No $_selectedFilter orders',
                          style: TextStyle(color: Colors.grey[500]),
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
                    return OrderCard(
                      order: order,
                      onStatusChanged: (newStatus) async {
                        await ref
                            .read(orderProvider.notifier)
                            .updateOrderStatus(order.id, newStatus);
                      },
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error:
                  (error, stack) => Center(
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
                            ref.invalidate(orderStreamProvider(filter));
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
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
  final Function(String) onStatusChanged;

  const OrderCard({
    required this.order,
    required this.onStatusChanged,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!),
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

            // Status update dropdown
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: order.status,
                  isExpanded: true,
                  hint: const Text('Update Status'),
                  items: [
                    DropdownMenuItem(
                      value: 'pending',
                      child: const Text('Pending'),
                    ),
                    DropdownMenuItem(
                      value: 'processing',
                      child: const Text('Processing'),
                    ),
                    DropdownMenuItem(
                      value: 'shipped',
                      child: const Text('Shipped'),
                    ),
                    DropdownMenuItem(
                      value: 'delivered',
                      child: const Text('Delivered'),
                    ),
                    DropdownMenuItem(
                      value: 'cancelled',
                      child: const Text('Cancelled'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null && value != order.status) {
                      onStatusChanged(value);
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
