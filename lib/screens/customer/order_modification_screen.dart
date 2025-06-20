import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/order_model.dart';
import '../../models/order_modification_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_modification_provider.dart';
import 'cancel_order_screen.dart';
import 'return_order_screen.dart';
import 'refund_request_screen.dart';

class OrderModificationScreen extends ConsumerWidget {
  final OrderModel order;

  const OrderModificationScreen({
    super.key,
    required this.order,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final user = ref.watch(currentUserProvider);
    
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in to manage orders')),
      );
    }

    final modificationsAsync = ref.watch(orderModificationRequestsStreamProvider(order.id));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Options'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order Summary
            _buildOrderSummary(theme),
            const SizedBox(height: 24),
            
            // Available Actions
            _buildAvailableActions(context, ref, theme, user),
            const SizedBox(height: 24),
            
            // Existing Modification Requests
            Text(
              'Modification History',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            modificationsAsync.when(
              data: (modifications) => _buildModificationHistory(modifications, theme),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Text('Error loading modifications: $error'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderSummary(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order #${order.id.substring(0, 8)}',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text('Status: '),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getStatusColor(order.status).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    order.status.toUpperCase(),
                    style: TextStyle(
                      color: _getStatusColor(order.status),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text('Total: TZS ${order.total.toStringAsFixed(0)}'),
            Text('Ordered: ${_formatDate(order.createdAt)}'),
          ],
        ),
      ),
    );
  }

  Widget _buildAvailableActions(BuildContext context, WidgetRef ref, ThemeData theme, user) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Available Actions',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            // Cancel Order
            FutureBuilder<bool>(
              future: ref.read(orderModificationProvider.notifier).canCancelOrder(order.id),
              builder: (context, snapshot) {
                final canCancel = snapshot.data ?? false;
                return ListTile(
                  leading: Icon(
                    Icons.cancel_outlined,
                    color: canCancel ? Colors.red : Colors.grey,
                  ),
                  title: const Text('Cancel Order'),
                  subtitle: Text(
                    canCancel 
                        ? 'Cancel this order before it ships'
                        : 'Order cannot be cancelled at this stage',
                  ),
                  trailing: canCancel ? const Icon(Icons.arrow_forward_ios) : null,
                  enabled: canCancel,
                  onTap: canCancel ? () => _navigateToCancelOrder(context, user) : null,
                );
              },
            ),
            
            const Divider(),
            
            // Return Order
            FutureBuilder<bool>(
              future: ref.read(orderModificationProvider.notifier).canReturnOrder(order.id),
              builder: (context, snapshot) {
                final canReturn = snapshot.data ?? false;
                return ListTile(
                  leading: Icon(
                    Icons.keyboard_return,
                    color: canReturn ? Colors.orange : Colors.grey,
                  ),
                  title: const Text('Return Items'),
                  subtitle: Text(
                    canReturn 
                        ? 'Return items within 30 days of delivery'
                        : 'Return window has expired or order not delivered',
                  ),
                  trailing: canReturn ? const Icon(Icons.arrow_forward_ios) : null,
                  enabled: canReturn,
                  onTap: canReturn ? () => _navigateToReturnOrder(context, user) : null,
                );
              },
            ),
            
            const Divider(),
            
            // Request Refund
            ListTile(
              leading: const Icon(Icons.money_off, color: Colors.blue),
              title: const Text('Request Refund'),
              subtitle: const Text('Request a refund for payment issues'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () => _navigateToRefundRequest(context, user),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModificationHistory(List<OrderModificationModel> modifications, ThemeData theme) {
    if (modifications.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: Text('No modification requests yet'),
        ),
      );
    }

    return Column(
      children: modifications.map((modification) => Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: _getModificationStatusColor(modification.status).withValues(alpha: 0.1),
            child: Icon(
              _getModificationIcon(modification.type),
              color: _getModificationStatusColor(modification.status),
              size: 20,
            ),
          ),
          title: Text(modification.typeDisplayName),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(modification.reason),
              const SizedBox(height: 2),
              Text(
                '${modification.statusDisplayName} • ${modification.timeAgo}',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ],
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: _getModificationStatusColor(modification.status).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              modification.statusDisplayName,
              style: TextStyle(
                color: _getModificationStatusColor(modification.status),
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          isThreeLine: true,
        ),
      )).toList(),
    );
  }

  void _navigateToCancelOrder(BuildContext context, user) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CancelOrderScreen(order: order),
      ),
    );
  }

  void _navigateToReturnOrder(BuildContext context, user) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReturnOrderScreen(order: order),
      ),
    );
  }

  void _navigateToRefundRequest(BuildContext context, user) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RefundRequestScreen(order: order),
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
        return Colors.purple;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getModificationStatusColor(ModificationStatus status) {
    switch (status) {
      case ModificationStatus.pending:
        return Colors.orange;
      case ModificationStatus.approved:
        return Colors.green;
      case ModificationStatus.rejected:
        return Colors.red;
      case ModificationStatus.processing:
        return Colors.blue;
      case ModificationStatus.completed:
        return Colors.green;
      case ModificationStatus.cancelled:
        return Colors.grey;
    }
  }

  IconData _getModificationIcon(ModificationType type) {
    switch (type) {
      case ModificationType.cancellation:
        return Icons.cancel;
      case ModificationType.return_:
        return Icons.keyboard_return;
      case ModificationType.refund:
        return Icons.money_off;
      case ModificationType.exchange:
        return Icons.swap_horiz;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
