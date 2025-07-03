import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';
import '../../models/order_model.dart';
import 'pending_approval_screen.dart';
import '../../services/product_service.dart';
import '../../models/product_model.dart';

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
    if (user?.role == 'seller' && user?.status != 'approved') {
      return const PendingApprovalScreen();
    }
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Orders')),
        body: const Center(child: Text('Please log in to view orders')),
      );
    }

    final OrderFilter filter = OrderFilter(
      userId: user.id,
      role: 'seller',
      status: _selectedFilter == 'all' ? null : _selectedFilter,
    );
    final ordersAsync = ref.watch(orderStreamProvider(filter));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Seller Orders'),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colorScheme.primary,
                  colorScheme.primary.withOpacity(0.85),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'All'),
                Tab(text: 'Pending'),
                Tab(text: 'Processing'),
                Tab(text: 'Completed'),
              ],
              labelColor: colorScheme.onPrimary,
              indicatorColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: colorScheme.primary.withOpacity(0.25),
              ),
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              colorScheme.primary.withOpacity(0.04),
              colorScheme.surface,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: RefreshIndicator(
          onRefresh: () async {
            setState(() => _isRefreshing = true);
            ref.invalidate(orderStreamProvider(filter));
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
                            size: 80,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'No orders found',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _selectedFilter == 'all'
                                ? 'You don\'t have any orders yet'
                                : 'No $_selectedFilter orders',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: colorScheme.onSurface.withOpacity(0.5),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.all(24),
                    itemCount: orders.length,
                    separatorBuilder:
                        (context, index) => const SizedBox(height: 20),
                    itemBuilder: (context, index) {
                      final order = orders[index];
                      return _OrderCard(
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
                loading:
                    () => _LoadingWithTimeout(onTimeout: () => setState(() {})),
                error:
                    (error, stack) => Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 56,
                            color: Colors.red,
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Something went wrong while loading orders.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: Colors.red,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              ref.invalidate(orderStreamProvider(filter));
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colorScheme.primary,
                              foregroundColor: colorScheme.onPrimary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
              ),
              if (_isRefreshing)
                const Center(child: CircularProgressIndicator()),
            ],
          ),
        ),
      ),
    );
  }
}

/// Widget that shows a loading spinner, but after 10 seconds shows an error message.
class _LoadingWithTimeout extends StatefulWidget {
  final VoidCallback? onTimeout;
  const _LoadingWithTimeout({this.onTimeout});

  @override
  State<_LoadingWithTimeout> createState() => _LoadingWithTimeoutState();
}

class _LoadingWithTimeoutState extends State<_LoadingWithTimeout> {
  bool _timedOut = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 10), () {
      if (mounted) {
        setState(() => _timedOut = true);
        widget.onTimeout?.call();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_timedOut) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 56, color: Colors.red),
          const SizedBox(height: 20),
          Text(
            'Unable to load orders. Please check your connection or try again.',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: Colors.red),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              setState(() => _timedOut = false);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Retry'),
          ),
        ],
      );
    }
    return const Center(child: CircularProgressIndicator());
  }
}

class _OrderCard extends StatelessWidget {
  final OrderModel order;
  final Function(String) onStatusChanged;

  const _OrderCard({
    required this.order,
    required this.onStatusChanged,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final dateFormat = DateFormat('MMM dd, yyyy • hh:mm a');
    final statusColors = {
      'pending': Colors.orange,
      'processing': Colors.blue,
      'shipped': Colors.indigo,
      'delivered': Colors.green,
      'cancelled': Colors.red,
    };
    final statusColor = statusColors[order.status] ?? Colors.grey;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                    horizontal: 10,
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
            Text(
              'Placed on ${dateFormat.format(order.createdAt)}',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
            const Divider(height: 24),
            Text(
              'Items (${order.items.length})',
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            ...List.generate(
              order.items.length > 3 ? 3 : order.items.length,
              (index) => FutureBuilder<ProductModel>(
                future: ProductService().getProduct(order.items[index].productId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: LinearProgressIndicator(),
                    );
                  }
                  if (!snapshot.hasData || snapshot.hasError) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            color: Colors.grey[300],
                            child: const Icon(Icons.image_not_supported),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Product not found',
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
                    );
                  }
                  final product = snapshot.data!;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: product.images.isNotEmpty
                              ? Image.network(
                                  product.images.first,
                                  width: 32,
                                  height: 32,
                                  fit: BoxFit.cover,
                                )
                              : Container(
                                  width: 32,
                                  height: 32,
                                  color: Colors.grey[300],
                                  child: const Icon(Icons.image_not_supported),
                                ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            product.name,
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
                  );
                },
              ),
            ),
            if (order.items.length > 3)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '+ ${order.items.length - 3} more items',
                  style: TextStyle(color: colorScheme.primary, fontSize: 14),
                ),
              ),
            const Divider(height: 24),
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
                  onChanged: (value) async {
                    if (value != null && value != order.status) {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Confirm Status Change'),
                          content: Text('Are you sure you want to change the order status to "${value[0].toUpperCase()}${value.substring(1)}"?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel'),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Confirm'),
                            ),
                          ],
                        ),
                      );
                      if (confirmed == true) {
                        onStatusChanged(value);
                      }
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                icon: const Icon(Icons.info_outline),
                label: const Text('View Details'),
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    builder: (context) => _OrderDetailsSheet(order: order),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderDetailsSheet extends StatelessWidget {
  final OrderModel order;
  const _OrderDetailsSheet({required this.order});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final dateFormat = DateFormat('MMM dd, yyyy • hh:mm a');
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) => SingleChildScrollView(
        controller: scrollController,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text('Order Details', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Text('Order ID: ${order.shortId}', style: theme.textTheme.bodyMedium),
            Text('Placed on: ${dateFormat.format(order.createdAt)}', style: theme.textTheme.bodyMedium),
            const SizedBox(height: 16),
            Text('Status: ${order.statusDisplayName}', style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.primary)),
            const Divider(height: 32),
            Text('Items', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...order.items.map((item) => FutureBuilder<ProductModel>(
              future: ProductService().getProduct(item.productId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: LinearProgressIndicator(),
                  );
                }
                final product = snapshot.data!;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: product.images.isNotEmpty
                        ? Image.network(product.images.first, width: 48, height: 48, fit: BoxFit.cover)
                        : Container(width: 48, height: 48, color: Colors.grey[300], child: const Icon(Icons.image_not_supported)),
                  ),
                  title: Text(product.name, style: theme.textTheme.bodyLarge),
                  subtitle: Text('Qty: ${item.quantity}  |  TZS ${item.price.toStringAsFixed(0)}'),
                  trailing: Text('TZS ${(item.price * item.quantity).toStringAsFixed(0)}', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                );
              },
            )),
            const Divider(height: 32),
            Text('Customer & Delivery', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (order.deliveryAddress != null)
              Text('Address: ${order.deliveryAddress}', style: theme.textTheme.bodyMedium),
            if (order.deliveryInstructions != null && order.deliveryInstructions!.isNotEmpty)
              Text('Instructions: ${order.deliveryInstructions}', style: theme.textTheme.bodyMedium),
            if (order.shippingMethod != null)
              Text('Shipping: ${order.shippingMethod}', style: theme.textTheme.bodyMedium),
            if (order.trackingNumber != null)
              Text('Tracking #: ${order.trackingNumber}', style: theme.textTheme.bodyMedium),
            const Divider(height: 32),
            Text('Payment', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (order.paymentMethod != null)
              Text('Method: ${order.paymentMethod}', style: theme.textTheme.bodyMedium),
            if (order.paymentStatus != null)
              Text('Status: ${order.paymentStatus}', style: theme.textTheme.bodyMedium),
            if (order.couponCode != null)
              Text('Coupon: ${order.couponCode}', style: theme.textTheme.bodyMedium),
            const Divider(height: 32),
            Text('Order Status History', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (order.statusHistory.isEmpty)
              Text('No status updates yet.', style: theme.textTheme.bodyMedium),
            ...order.statusHistory.map((update) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.check_circle, color: colorScheme.primary),
              title: Text(update.status, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
              subtitle: Text('${update.description}\n${dateFormat.format(update.timestamp)}'),
            )),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Subtotal:', style: theme.textTheme.bodyMedium),
                Text(order.formattedSubtotal, style: theme.textTheme.bodyMedium),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Shipping:', style: theme.textTheme.bodyMedium),
                Text(order.formattedShipping, style: theme.textTheme.bodyMedium),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Tax:', style: theme.textTheme.bodyMedium),
                Text(order.formattedTax, style: theme.textTheme.bodyMedium),
              ],
            ),
            if (order.discount > 0)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Discount:', style: theme.textTheme.bodyMedium),
                  Text('-${order.formattedDiscount}', style: theme.textTheme.bodyMedium?.copyWith(color: Colors.green)),
                ],
              ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total:', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                Text(order.formattedTotal, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.primary)),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
