import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/inventory_provider.dart';
import 'package:intl/intl.dart';

class SellerDashboardScreen extends ConsumerWidget {
  const SellerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Create filter for recent orders
    final orderFilter = OrderFilter(
      userId: currentUser?.id ?? '',
      role: 'seller',
      limit: 5,
    );

    final recentOrdersAsync = ref.watch(orderStreamProvider(orderFilter));
    final inventoryAsync = ref.watch(
      inventoryStreamProvider(currentUser?.id ?? ''),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Seller Dashboard'),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authProvider.notifier).signOut();
              if (context.mounted) {
                context.go('/login');
              }
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [colorScheme.primary.withOpacity(0.04), colorScheme.background],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                elevation: 6,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [colorScheme.primary.withOpacity(0.12), Colors.white],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(28.0),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 36,
                          backgroundColor: colorScheme.primary,
                          child: Text(
                            currentUser?.name?.substring(0, 1).toUpperCase() ?? 'S',
                            style: const TextStyle(fontSize: 32, color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Welcome back,', style: theme.textTheme.bodyLarge?.copyWith(color: colorScheme.primary)),
                              Text(
                                currentUser?.name ?? 'Seller',
                                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.onBackground),
                              ),
                              Text(
                                DateFormat('EEEE, MMMM d, yyyy').format(DateTime.now()),
                                style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Text('Overview', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.primary)),
              const SizedBox(height: 14),
              Row(
                children: [
                  _buildStatCard(
                    context,
                    title: 'Products',
                    value: inventoryAsync.when(
                      data: (inventory) => inventory.length.toString(),
                      loading: () => '...',
                      error: (_, __) => 'N/A',
                    ),
                    icon: Icons.inventory_2,
                    color: Colors.purple,
                  ),
                  const SizedBox(width: 18),
                  _buildStatCard(
                    context,
                    title: 'Orders',
                    value: recentOrdersAsync.when(
                      data: (orders) => orders.length.toString(),
                      loading: () => '...',
                      error: (_, __) => 'N/A',
                    ),
                    icon: Icons.shopping_bag,
                    color: Colors.blue,
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Text('Quick Actions', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.primary)),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _buildActionButton(
                      context,
                      title: 'Add Product',
                      icon: Icons.add_circle_outline,
                      onTap: () => context.go('/seller/inventory/add-product'),
                    ),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: _buildActionButton(
                      context,
                      title: 'Manage Inventory',
                      icon: Icons.inventory,
                      onTap: () => context.go('/seller/inventory'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _buildActionButton(
                      context,
                      title: 'View Orders',
                      icon: Icons.receipt_long,
                      onTap: () => context.go('/seller/orders'),
                    ),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: _buildActionButton(
                      context,
                      title: 'Profile',
                      icon: Icons.person,
                      onTap: () => context.go('/seller/profile'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Text('Recent Orders', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.primary)),
              const SizedBox(height: 10),
              recentOrdersAsync.when(
                data: (orders) {
                  if (orders.isEmpty) {
                    return Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey[300]!),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Center(child: Text('No recent orders')),
                      ),
                    );
                  }
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: orders.length,
                    itemBuilder: (context, index) {
                      final order = orders[index];
                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.only(bottom: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(color: Colors.grey[200]!),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                          leading: CircleAvatar(
                            backgroundColor: _getStatusColor(order.status).withOpacity(0.18),
                            child: Icon(Icons.shopping_bag, color: _getStatusColor(order.status)),
                          ),
                          title: Text('Order #${order.id.substring(0, 8)}', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                          subtitle: Text('${DateFormat('MMM dd').format(order.createdAt)} • ${order.items.length} items'),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('TZS ${order.total.toStringAsFixed(2)}', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(order.status).withOpacity(0.13),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(order.status.toUpperCase(), style: TextStyle(color: _getStatusColor(order.status), fontSize: 10, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                          onTap: () {
                            // Navigate to order details (implement as needed)
                          },
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(child: Text('Error loading orders: $error')),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, {required String title, required String value, required IconData icon, required Color color}) {
    return Expanded(
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, color: color),
              ),
              const SizedBox(height: 16),
              Text(value, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(title, style: TextStyle(color: Colors.grey[600])),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, {required String title, required IconData icon, required VoidCallback onTap}) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20.0),
          child: Column(
            children: [
              Icon(icon, color: Theme.of(context).colorScheme.primary, size: 28),
              const SizedBox(height: 8),
              Text(title, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'processing':
        return Colors.blue;
      case 'shipped':
        return Colors.indigo;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
