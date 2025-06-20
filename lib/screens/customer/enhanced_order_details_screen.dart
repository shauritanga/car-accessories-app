import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/order_model.dart';
import '../../providers/order_provider.dart';
import '../../providers/cart_provider.dart';
import '../../services/enhanced_order_service.dart';
import 'order_tracking_screen.dart';

// Provider for getting a single order by ID
final singleOrderProvider = StreamProvider.family<OrderModel?, String>((
  ref,
  orderId,
) {
  return FirebaseFirestore.instance
      .collection('orders')
      .doc(orderId)
      .snapshots()
      .map((doc) {
        if (doc.exists) {
          return OrderModel.fromMap(doc.data()!, doc.id);
        }
        return null;
      });
});

class EnhancedOrderDetailsScreen extends ConsumerStatefulWidget {
  final String orderId;

  const EnhancedOrderDetailsScreen({super.key, required this.orderId});

  @override
  ConsumerState<EnhancedOrderDetailsScreen> createState() =>
      _EnhancedOrderDetailsScreenState();
}

class _EnhancedOrderDetailsScreenState
    extends ConsumerState<EnhancedOrderDetailsScreen> {
  final EnhancedOrderService _orderService = EnhancedOrderService();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final orderAsync = ref.watch(singleOrderProvider(widget.orderId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Details'),
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) => _handleMenuAction(value, context),
            itemBuilder:
                (context) => [
                  const PopupMenuItem(
                    value: 'share',
                    child: Row(
                      children: [
                        Icon(Icons.share),
                        SizedBox(width: 8),
                        Text('Share Order'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'receipt',
                    child: Row(
                      children: [
                        Icon(Icons.receipt),
                        SizedBox(width: 8),
                        Text('Download Receipt'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'reorder',
                    child: Row(
                      children: [
                        Icon(Icons.refresh),
                        SizedBox(width: 8),
                        Text('Reorder Items'),
                      ],
                    ),
                  ),
                ],
          ),
        ],
      ),
      body: orderAsync.when(
        data: (order) {
          if (order == null) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text('Order not found'),
                ],
              ),
            );
          }
          return _buildOrderDetails(order, theme);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error:
            (error, stack) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error loading order: $error'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed:
                        () => ref.refresh(singleOrderProvider(widget.orderId)),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
      ),
    );
  }

  Widget _buildOrderDetails(OrderModel order, ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order Header
          _buildOrderHeader(order, theme),
          const SizedBox(height: 24),

          // Order Status Timeline
          _buildOrderStatusTimeline(order, theme),
          const SizedBox(height: 24),

          // Delivery Information
          _buildDeliveryInformation(order, theme),
          const SizedBox(height: 24),

          // Order Items
          _buildOrderItems(order, theme),
          const SizedBox(height: 24),

          // Order Summary
          _buildOrderSummary(order, theme),
          const SizedBox(height: 24),

          // Action Buttons
          _buildActionButtons(order, theme),
        ],
      ),
    );
  }

  Widget _buildOrderHeader(OrderModel order, ThemeData theme) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order #${order.shortId}',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                _buildStatusChip(order.status, theme),
              ],
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  'Placed on ${_formatDate(order.createdAt)}',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),

            if (order.trackingNumber != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.local_shipping, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    'Tracking: ${order.trackingNumber}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _copyToClipboard(order.trackingNumber!),
                    child: Icon(
                      Icons.copy,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 12),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total: ${order.formattedTotal}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                if (order.estimatedDeliveryDate != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Estimated Delivery',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                      Text(
                        _formatDate(order.estimatedDeliveryDate!),
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderStatusTimeline(OrderModel order, ThemeData theme) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order Timeline',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (order.trackingNumber != null)
                  TextButton(
                    onPressed: () => _navigateToTracking(order),
                    child: const Text('Track Order'),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            if (order.statusHistory.isNotEmpty)
              ...order.statusHistory.asMap().entries.map((entry) {
                final index = entry.key;
                final statusUpdate = entry.value;
                final isLast = index == order.statusHistory.length - 1;

                return _buildTimelineItem(statusUpdate, isLast, theme);
              })
            else
              Text(
                'No status updates available',
                style: TextStyle(color: Colors.grey[600]),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineItem(
    OrderStatusUpdate statusUpdate,
    bool isLast,
    ThemeData theme,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                shape: BoxShape.circle,
              ),
            ),
            if (!isLast)
              Container(width: 2, height: 40, color: Colors.grey[300]),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                statusUpdate.status.toUpperCase(),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              Text(statusUpdate.description),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    _formatDateTime(statusUpdate.timestamp),
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  if (statusUpdate.location != null) ...[
                    const SizedBox(width: 8),
                    Icon(Icons.location_on, size: 12, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      statusUpdate.location!,
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ],
              ),
              if (!isLast) const SizedBox(height: 16),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDeliveryInformation(OrderModel order, ThemeData theme) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Delivery Information',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            if (order.deliveryAddress != null) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.location_on, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Delivery Address',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 4),
                        Text(order.deliveryAddress!),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],

            if (order.deliveryInstructions != null &&
                order.deliveryInstructions!.isNotEmpty) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.note, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Delivery Instructions',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 4),
                        Text(order.deliveryInstructions!),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],

            if (order.shippingMethod != null) ...[
              Row(
                children: [
                  Icon(Icons.local_shipping, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    'Shipping Method: ${order.shippingMethod}',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOrderItems(OrderModel order, ThemeData theme) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order Items (${order.itemCount})',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            ...order.items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Item image placeholder
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.image, color: Colors.grey),
                    ),
                    const SizedBox(width: 12),

                    // Item details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Product ID: ${item.productId.substring(0, 8)}...',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Quantity: ${item.quantity}',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Price: TZS ${item.price.toStringAsFixed(0)} each',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),

                    // Item total
                    Text(
                      'TZS ${(item.price * item.quantity).toStringAsFixed(0)}',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderSummary(OrderModel order, ThemeData theme) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order Summary',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            _buildSummaryRow('Subtotal', order.formattedSubtotal),
            _buildSummaryRow('Shipping', order.formattedShipping),
            _buildSummaryRow('Tax (VAT 18%)', order.formattedTax),

            if (order.discount > 0)
              _buildSummaryRow(
                'Discount',
                '-${order.formattedDiscount}',
                isDiscount: true,
              ),

            if (order.couponCode != null)
              _buildSummaryRow(
                'Coupon (${order.couponCode})',
                '-${order.formattedDiscount}',
                isDiscount: true,
              ),

            const Divider(thickness: 2),

            _buildSummaryRow(
              'Total',
              order.formattedTotal,
              isTotal: true,
              color: theme.colorScheme.primary,
            ),

            if (order.paymentMethod != null) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.payment, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    'Payment: ${order.paymentMethod}',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const Spacer(),
                  _buildPaymentStatusChip(order.paymentStatus ?? 'pending'),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value, {
    bool isTotal = false,
    bool isDiscount = false,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
              color: color ?? (isDiscount ? Colors.green : null),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(OrderModel order, ThemeData theme) {
    return Column(
      children: [
        if (order.canBeCancelled) ...[
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.cancel, color: Colors.red),
              label: const Text(
                'Cancel Order',
                style: TextStyle(color: Colors.red),
              ),
              onPressed: () => _cancelOrder(order),
            ),
          ),
          const SizedBox(height: 12),
        ],

        if (order.canBeReturned) ...[
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.keyboard_return),
              label: const Text('Return Order'),
              onPressed: () => _returnOrder(order),
            ),
          ),
          const SizedBox(height: 12),
        ],

        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('Reorder'),
                onPressed: () => _reorderItems(order),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.support_agent),
                label: const Text('Get Help'),
                onPressed: () => _getHelp(order),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusChip(String status, ThemeData theme) {
    Color backgroundColor;
    Color textColor;

    switch (status.toLowerCase()) {
      case 'pending':
        backgroundColor = Colors.orange[100]!;
        textColor = Colors.orange[800]!;
        break;
      case 'processing':
        backgroundColor = Colors.blue[100]!;
        textColor = Colors.blue[800]!;
        break;
      case 'shipped':
        backgroundColor = Colors.purple[100]!;
        textColor = Colors.purple[800]!;
        break;
      case 'delivered':
        backgroundColor = Colors.green[100]!;
        textColor = Colors.green[800]!;
        break;
      case 'cancelled':
        backgroundColor = Colors.red[100]!;
        textColor = Colors.red[800]!;
        break;
      default:
        backgroundColor = Colors.grey[100]!;
        textColor = Colors.grey[800]!;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildPaymentStatusChip(String status) {
    Color backgroundColor;
    Color textColor;

    switch (status.toLowerCase()) {
      case 'pending':
        backgroundColor = Colors.orange[100]!;
        textColor = Colors.orange[800]!;
        break;
      case 'paid':
        backgroundColor = Colors.green[100]!;
        textColor = Colors.green[800]!;
        break;
      case 'failed':
        backgroundColor = Colors.red[100]!;
        textColor = Colors.red[800]!;
        break;
      default:
        backgroundColor = Colors.grey[100]!;
        textColor = Colors.grey[800]!;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // Action methods
  void _handleMenuAction(String action, BuildContext context) async {
    // For now, we'll use a placeholder order
    // In a real implementation, you'd get the order from the provider
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$action feature coming soon!')));
  }

  Future<void> _shareOrder(OrderModel order) async {
    try {
      await _orderService.shareOrderDetails(order);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error sharing order: $e')));
      }
    }
  }

  Future<void> _downloadReceipt(OrderModel order) async {
    setState(() => _isLoading = true);

    try {
      final file = await _orderService.generateOrderReceipt(order);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Receipt saved to ${file.path}'),
            action: SnackBarAction(
              label: 'Share',
              onPressed: () => Share.shareXFiles([XFile(file.path)]),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error generating receipt: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _reorderItems(OrderModel order) async {
    setState(() => _isLoading = true);

    try {
      final cartItems = await _orderService.getReorderItems(order);

      // Add items to cart
      for (final item in cartItems) {
        ref.read(cartProvider.notifier).addItem(item);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${cartItems.length} items added to cart'),
            action: SnackBarAction(
              label: 'View Cart',
              onPressed: () => Navigator.pushNamed(context, '/cart'),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error reordering items: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _navigateToTracking(OrderModel order) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrderTrackingScreen(order: order),
      ),
    );
  }

  Future<void> _cancelOrder(OrderModel order) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Cancel Order'),
            content: Text(
              'Are you sure you want to cancel order #${order.shortId}?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('No'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Yes, Cancel'),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      try {
        await ref
            .read(orderProvider.notifier)
            .updateOrderStatus(order.id, 'cancelled');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Order cancelled successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error cancelling order: $e')));
        }
      }
    }
  }

  Future<void> _returnOrder(OrderModel order) async {
    // Navigate to return order screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Return order feature coming soon!')),
    );
  }

  void _getHelp(OrderModel order) {
    // Navigate to help/support screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Customer support feature coming soon!')),
    );
  }

  void _copyToClipboard(String text) {
    // Copy tracking number to clipboard
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tracking number copied to clipboard')),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatDateTime(DateTime date) {
    return '${_formatDate(date)} at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
