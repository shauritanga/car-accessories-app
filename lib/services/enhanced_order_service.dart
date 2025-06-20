import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import '../models/order_model.dart';
import '../models/cart_item_model.dart';
import '../models/product_model.dart';
import '../services/notification_service.dart';

class EnhancedOrderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();

  // Enhanced order creation with all features
  Future<OrderModel> createEnhancedOrder({
    required String customerId,
    required List<CartItemModel> items,
    required String deliveryAddress,
    String? deliveryInstructions,
    String? shippingMethodId,
    String? paymentMethodId,
    String? couponCode,
    double? discount,
    Map<String, dynamic>? guestInfo,
  }) async {
    try {
      final orderId = _firestore.collection('orders').doc().id;

      // Calculate totals
      final subtotal = items.fold(
        0.0,
        (total, item) => total + item.totalPrice,
      );
      final shippingCost = await _calculateShippingCost(
        shippingMethodId,
        items,
      );
      final tax = _calculateTax(subtotal);
      final totalDiscount = discount ?? 0.0;
      final total = subtotal + shippingCost + tax - totalDiscount;

      // Create order items
      final orderItems =
          items
              .map(
                (item) => OrderItem(
                  productId: item.id,
                  price: item.price,
                  quantity: item.quantity,
                  sellerId: item.sellerId,
                ),
              )
              .toList();

      // Estimate delivery date
      final estimatedDelivery = await _calculateEstimatedDelivery(
        shippingMethodId,
      );

      // Generate tracking number
      final trackingNumber = _generateTrackingNumber();

      final order = OrderModel(
        id: orderId,
        customerId: customerId,
        sellerId: items.first.sellerId,
        items: orderItems,
        subtotal: subtotal,
        shippingCost: shippingCost,
        tax: tax,
        discount: totalDiscount,
        total: total,
        status: 'pending',
        createdAt: DateTime.now(),
        estimatedDeliveryDate: estimatedDelivery,
        deliveryAddress: deliveryAddress,
        deliveryInstructions: deliveryInstructions,
        trackingNumber: trackingNumber,
        shippingMethod: shippingMethodId,
        paymentMethod: paymentMethodId,
        paymentStatus: 'pending',
        couponCode: couponCode,
        metadata: guestInfo,
        statusHistory: [
          OrderStatusUpdate(
            status: 'pending',
            description: 'Order placed successfully',
            timestamp: DateTime.now(),
          ),
        ],
      );

      // Save to Firestore
      await _firestore.collection('orders').doc(orderId).set(order.toMap());

      // Send order confirmation notification
      await _notificationService.sendOrderConfirmation(order);

      return order;
    } catch (e) {
      throw Exception('Failed to create order: $e');
    }
  }

  // Update order status with notifications
  Future<void> updateOrderStatus({
    required String orderId,
    required String newStatus,
    String? description,
    String? location,
    String? updatedBy,
  }) async {
    try {
      final orderRef = _firestore.collection('orders').doc(orderId);
      final orderDoc = await orderRef.get();

      if (!orderDoc.exists) {
        throw Exception('Order not found');
      }

      final order = OrderModel.fromMap(orderDoc.data()!, orderDoc.id);

      // Create status update
      final statusUpdate = OrderStatusUpdate(
        status: newStatus,
        description: description ?? _getDefaultStatusDescription(newStatus),
        timestamp: DateTime.now(),
        location: location,
        updatedBy: updatedBy,
      );

      // Update order
      final updatedStatusHistory = [...order.statusHistory, statusUpdate];

      final updateData = {
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
        'statusHistory':
            updatedStatusHistory.map((update) => update.toMap()).toList(),
      };

      // Add actual delivery date if delivered
      if (newStatus == 'delivered') {
        updateData['actualDeliveryDate'] = FieldValue.serverTimestamp();
      }

      await orderRef.update(updateData);

      // Send status update notification
      final updatedOrder = order.copyWith(
        status: newStatus,
        statusHistory: updatedStatusHistory,
        actualDeliveryDate: newStatus == 'delivered' ? DateTime.now() : null,
      );

      await _notificationService.sendOrderStatusUpdate(
        updatedOrder,
        statusUpdate,
      );
    } catch (e) {
      throw Exception('Failed to update order status: $e');
    }
  }

  // Generate order receipt/invoice
  Future<File> generateOrderReceipt(OrderModel order) async {
    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Car Accessories',
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      'INVOICE',
                      style: pw.TextStyle(
                        fontSize: 20,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                pw.SizedBox(height: 20),

                // Order details
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Order ID: #${order.shortId}'),
                        pw.Text(
                          'Date: ${order.createdAt.toString().split(' ')[0]}',
                        ),
                        pw.Text('Status: ${order.statusDisplayName}'),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          'Customer ID: ${order.customerId.substring(0, 8)}',
                        ),
                        if (order.trackingNumber != null)
                          pw.Text('Tracking: ${order.trackingNumber}'),
                      ],
                    ),
                  ],
                ),

                pw.SizedBox(height: 30),

                // Items table
                pw.Table(
                  border: pw.TableBorder.all(),
                  children: [
                    // Header
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(
                        color: PdfColors.grey300,
                      ),
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            'Item',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            'Qty',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            'Price',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            'Total',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    // Items
                    ...order.items.map(
                      (item) => pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(item.productId.substring(0, 8)),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(item.quantity.toString()),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(
                              'TZS ${item.price.toStringAsFixed(0)}',
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(
                              'TZS ${(item.price * item.quantity).toStringAsFixed(0)}',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                pw.SizedBox(height: 20),

                // Totals
                pw.Align(
                  alignment: pw.Alignment.centerRight,
                  child: pw.Container(
                    width: 200,
                    child: pw.Column(
                      children: [
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('Subtotal:'),
                            pw.Text(order.formattedSubtotal),
                          ],
                        ),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('Shipping:'),
                            pw.Text(order.formattedShipping),
                          ],
                        ),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('Tax (VAT 18%):'),
                            pw.Text(order.formattedTax),
                          ],
                        ),
                        if (order.discount > 0)
                          pw.Row(
                            mainAxisAlignment:
                                pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text('Discount:'),
                              pw.Text('-${order.formattedDiscount}'),
                            ],
                          ),
                        pw.Divider(),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text(
                              'Total:',
                              style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                            pw.Text(
                              order.formattedTotal,
                              style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                pw.SizedBox(height: 30),

                // Footer
                pw.Text(
                  'Thank you for your business!',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  'For support, contact us at support@caraccessories.com',
                ),
              ],
            );
          },
        ),
      );

      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/order_${order.shortId}_receipt.pdf');
      await file.writeAsBytes(await pdf.save());

      return file;
    } catch (e) {
      throw Exception('Failed to generate receipt: $e');
    }
  }

  // Share order details
  Future<void> shareOrderDetails(OrderModel order) async {
    try {
      final orderDetails = '''
Order Details - Car Accessories

Order ID: #${order.shortId}
Date: ${order.createdAt.toString().split(' ')[0]}
Status: ${order.statusDisplayName}
${order.trackingNumber != null ? 'Tracking: ${order.trackingNumber}' : ''}

Items: ${order.itemCount} items
Total: ${order.formattedTotal}

${order.estimatedDeliveryDate != null ? 'Estimated Delivery: ${order.estimatedDeliveryText}' : ''}

Thank you for shopping with Car Accessories!
''';

      await Share.share(orderDetails);
    } catch (e) {
      throw Exception('Failed to share order details: $e');
    }
  }

  // Reorder functionality
  Future<List<CartItemModel>> getReorderItems(OrderModel order) async {
    try {
      final cartItems = <CartItemModel>[];

      for (final orderItem in order.items) {
        // Get current product details
        final productDoc =
            await _firestore
                .collection('products')
                .doc(orderItem.productId)
                .get();

        if (productDoc.exists) {
          final product = ProductModel.fromMap(productDoc.data()!);

          // Check if product is still available
          if (product.stock > 0) {
            cartItems.add(
              CartItemModel(
                id: product.id,
                name: product.name,
                price: product.price, // Use current price
                originalPrice:
                    orderItem.price, // Show original price if different
                quantity: orderItem.quantity,
                sellerId: product.sellerId,
                image: product.images.isNotEmpty ? product.images.first : null,
                category: product.category,
                isAvailable: product.stock >= orderItem.quantity,
                maxQuantity: product.stock,
                addedAt: DateTime.now(),
              ),
            );
          }
        }
      }

      return cartItems;
    } catch (e) {
      throw Exception('Failed to get reorder items: $e');
    }
  }

  // Helper methods
  Future<double> _calculateShippingCost(
    String? shippingMethodId,
    List<CartItemModel> items,
  ) async {
    // This would integrate with shipping service
    return 5000.0; // Default shipping cost
  }

  double _calculateTax(double subtotal) {
    return subtotal * 0.18; // 18% VAT for Tanzania
  }

  Future<DateTime> _calculateEstimatedDelivery(String? shippingMethodId) async {
    // This would integrate with shipping service
    return DateTime.now().add(const Duration(days: 3)); // Default 3 days
  }

  String _generateTrackingNumber() {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final random = (timestamp.hashCode % 10000).toString().padLeft(4, '0');
    return 'CAR${timestamp.substring(timestamp.length - 6)}$random';
  }

  String _getDefaultStatusDescription(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Order placed successfully';
      case 'processing':
        return 'Order is being processed';
      case 'shipped':
        return 'Order has been shipped';
      case 'delivered':
        return 'Order has been delivered';
      case 'cancelled':
        return 'Order has been cancelled';
      default:
        return 'Order status updated';
    }
  }
}

// Extension to add copyWith method to OrderModel
extension OrderModelExtension on OrderModel {
  OrderModel copyWith({
    String? id,
    String? customerId,
    String? sellerId,
    List<OrderItem>? items,
    double? subtotal,
    double? shippingCost,
    double? tax,
    double? discount,
    double? total,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? estimatedDeliveryDate,
    DateTime? actualDeliveryDate,
    String? deliveryAddress,
    String? deliveryInstructions,
    String? trackingNumber,
    String? shippingMethod,
    String? paymentMethod,
    String? paymentStatus,
    String? couponCode,
    Map<String, dynamic>? metadata,
    List<OrderStatusUpdate>? statusHistory,
  }) {
    return OrderModel(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      sellerId: sellerId ?? this.sellerId,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      shippingCost: shippingCost ?? this.shippingCost,
      tax: tax ?? this.tax,
      discount: discount ?? this.discount,
      total: total ?? this.total,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      estimatedDeliveryDate:
          estimatedDeliveryDate ?? this.estimatedDeliveryDate,
      actualDeliveryDate: actualDeliveryDate ?? this.actualDeliveryDate,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      deliveryInstructions: deliveryInstructions ?? this.deliveryInstructions,
      trackingNumber: trackingNumber ?? this.trackingNumber,
      shippingMethod: shippingMethod ?? this.shippingMethod,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      couponCode: couponCode ?? this.couponCode,
      metadata: metadata ?? this.metadata,
      statusHistory: statusHistory ?? this.statusHistory,
    );
  }
}
