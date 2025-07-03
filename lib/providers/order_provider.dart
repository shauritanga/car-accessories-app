import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/order_model.dart';
import '../models/cart_item_model.dart';
import '../models/shipping_model.dart';
import '../models/payment_model.dart';

class OrderFilter {
  final String userId;
  final String role; // 'customer' or 'seller'
  final String? status;
  final int? limit;

  OrderFilter({
    required this.userId,
    required this.role,
    this.status,
    this.limit,
  });
}

class OrderNotifier extends StateNotifier<List<OrderModel>> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  OrderNotifier() : super([]);

  Future<OrderModel> createGuestOrder({
    required Map<String, dynamic> guestInfo,
    required List<CartItemModel> items,
    required ShippingMethod shippingMethod,
    required PaymentMethod paymentMethod,
    String? deliveryInstructions,
  }) async {
    try {
      final orderId = const Uuid().v4();
      final now = DateTime.now();

      // Calculate totals
      final subtotal = items.fold<double>(
        0,
        (sum, item) => sum + (item.price * item.quantity),
      );
      final shippingCost = shippingMethod.cost;
      final total = subtotal + shippingCost;

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

      // Create order
      final order = OrderModel(
        id: orderId,
        customerId: 'guest_${now.millisecondsSinceEpoch}',
        sellerId: orderItems.isNotEmpty ? orderItems.first.sellerId : '',
        items: orderItems,
        subtotal: subtotal,
        shippingCost: shippingCost,
        total: total,
        status: 'pending',
        createdAt: now,
        deliveryAddress: '${guestInfo['address']}, ${guestInfo['city']}',
        deliveryInstructions: deliveryInstructions,
        statusHistory: [
          OrderStatusUpdate(
            status: 'pending',
            description: 'Order placed successfully',
            timestamp: now,
          ),
        ],
      );

      // Save to Firestore
      await _firestore.collection('orders').doc(orderId).set(order.toMap());

      return order;
    } catch (e) {
      print('Error creating guest order: $e');
      throw Exception('Failed to create order: $e');
    }
  }

  Future<OrderModel> createOrder({
    required String customerId,
    required List<CartItemModel> items,
    required String deliveryAddress,
    String? deliveryInstructions,
    required String paymentMethod,
    required String paymentStatus,
  }) async {
    try {
      final orderId = const Uuid().v4();
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

      final subtotal = items.fold(
        0.0,
        (accumulator, item) => accumulator + (item.price * item.quantity),
      );
      final shippingCost = 5000.0; // TZS 5,000 delivery fee
      final tax = subtotal * 0.18; // 18% VAT
      final total = subtotal + shippingCost + tax;

      final order = OrderModel(
        id: orderId,
        customerId: customerId,
        sellerId: items.first.sellerId, // Assuming single seller for now
        items: orderItems,
        subtotal: subtotal,
        shippingCost: shippingCost,
        tax: tax,
        total: total,
        status: 'pending',
        createdAt: DateTime.now(),
        estimatedDeliveryDate: DateTime.now().add(const Duration(days: 3)),
        deliveryAddress: deliveryAddress,
        deliveryInstructions: deliveryInstructions,
        paymentMethod: paymentMethod,
        paymentStatus: paymentStatus,
        statusHistory: [
          OrderStatusUpdate(
            status: 'pending',
            description: 'Order placed successfully',
            timestamp: DateTime.now(),
          ),
        ],
      );

      await _firestore.collection('orders').doc(order.id).set(order.toMap());
      return order;
    } catch (e) {
      throw Exception('Failed to create order: $e');
    }
  }

  Future<void> placeOrder(OrderModel order) async {
    try {
      await _firestore.collection('orders').doc(order.id).set(order.toMap());
    } catch (e) {
      throw Exception('Failed to place order: $e');
    }
  }

  Future<void> updateOrderStatus(String orderId, String status) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update order status: $e');
    }
  }

  Future<void> cancelOrder(String orderId) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({
        'status': 'cancelled',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to cancel order: $e');
    }
  }
}

// Stream provider for orders
final orderStreamProvider = StreamProvider.family<
  List<OrderModel>,
  OrderFilter
>((ref, filter) {
  final firestore = FirebaseFirestore.instance;

  // Debug print
  // print(
  //   'Creating order stream for userId: ${filter.userId}, role: ${filter.role}',
  // );

  Query query;

  if (filter.role == 'customer') {
    query = firestore
        .collection('orders')
        .where('customerId', isEqualTo: filter.userId)
        .limit(filter.limit ?? 3);
  } else {
    query = firestore
        .collection('orders')
        .where('sellerId', isEqualTo: filter.userId);
  }

  // Add status filter if provided
  if (filter.status != null &&
      filter.status!.isNotEmpty &&
      filter.status != 'all') {
    if (filter.status == 'completed') {
      // For completed tab, show both delivered and shipped
      query = query.where('status', whereIn: ['delivered', 'shipped']);
    } else {
      query = query.where('status', isEqualTo: filter.status);
    }
  }

  // Order by creation date, newest first
  query = query.orderBy('createdAt', descending: true);

  // Debug print the query
  // print('Firestore query: ${query.toString()}');

  return query
      .snapshots()
      .map((snapshot) {
        // Debug print
        // print('Received ${snapshot.docs.length} documents from Firestore');

        try {
          final orders =
              snapshot.docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                // Add the document ID if it's not already in the data
                if (!data.containsKey('id')) {
                  data['id'] = doc.id;
                }
                return OrderModel.fromMap(data, doc.id);
              }).toList();

          // print(
          //   'Successfully converted ${orders.length} documents to OrderModel',
          // );
          return orders;
        } catch (e) {
          // print('Error converting Firestore documents to OrderModel: $e');
          // print('Stack trace: $stack');
          rethrow; // Re-throw to be caught by the AsyncValue.error handler
        }
      })
      .handleError((error, stack) {
        print('Error in order stream: $error');
        print('Stack trace: $stack');
        return <OrderModel>[]; // Return empty list on error
      });
}); // Stream provider for orders
final orderStreamProviderSimple = StreamProvider.family<
  List<OrderModel>,
  OrderFilter
>((ref, filter) {
  final firestore = FirebaseFirestore.instance;
  print(
    'OrderStreamProviderSimple: Creating stream for userId: ${filter.userId}, role: ${filter.role}',
  );

  Query query;

  if (filter.role == 'customer') {
    query = firestore
        .collection('orders')
        .where('customerId', isEqualTo: filter.userId);
  } else {
    query = firestore
        .collection('orders')
        .where('sellerId', isEqualTo: filter.userId);
  }

  // Add status filter if provided
  if (filter.status != null &&
      filter.status!.isNotEmpty &&
      filter.status != 'all') {
    if (filter.status == 'completed') {
      // For completed tab, show both delivered and shipped
      query = query.where('status', whereIn: ['delivered', 'shipped']);
    } else {
      query = query.where('status', isEqualTo: filter.status);
    }
  }

  // Order by creation date, newest first
  query = query.orderBy('createdAt', descending: true);

  print('OrderStreamProviderSimple: Query created: ${query.toString()}');

  List<OrderModel> lastProcessedOrders = [];

  return query
      .snapshots()
      .map((snapshot) {
        print(
          'OrderStreamProviderSimple: Received ${snapshot.docs.length} documents',
        );
        print(
          'OrderStreamProviderSimple: Snapshot metadata: ${snapshot.metadata}',
        );

        if (snapshot.docs.isEmpty) {
          print(
            'OrderStreamProviderSimple: No documents found, returning empty list',
          );
          lastProcessedOrders = [];
          return <OrderModel>[];
        }

        try {
          print(
            'OrderStreamProviderSimple: Starting to process ${snapshot.docs.length} documents',
          );
          final orders = <OrderModel>[];

          for (int i = 0; i < snapshot.docs.length; i++) {
            final doc = snapshot.docs[i];
            print(
              'OrderStreamProviderSimple: Processing document ${i + 1}/${snapshot.docs.length}: ${doc.id}',
            );

            final data = doc.data() as Map<String, dynamic>;
            print(
              'OrderStreamProviderSimple: Document data keys: ${data.keys.toList()}',
            );

            try {
              final order = OrderModel.fromMap(data, doc.id);
              print(
                'OrderStreamProviderSimple: Successfully created OrderModel for document ${doc.id}',
              );
              orders.add(order);
            } catch (e, stack) {
              print(
                'OrderStreamProviderSimple: Error processing document ${doc.id}: $e',
              );
              print('OrderStreamProviderSimple: Stack trace: $stack');
              // Continue with other documents instead of failing completely
            }
          }

          print(
            'OrderStreamProviderSimple: Successfully processed ${orders.length}/${snapshot.docs.length} orders',
          );

          // Check if the data has actually changed
          if (orders.length == lastProcessedOrders.length) {
            bool hasChanged = false;
            for (int i = 0; i < orders.length; i++) {
              if (orders[i].id != lastProcessedOrders[i].id ||
                  orders[i].status != lastProcessedOrders[i].status) {
                hasChanged = true;
                break;
              }
            }
            if (!hasChanged) {
              print(
                'OrderStreamProviderSimple: Data unchanged, returning cached result',
              );
              return lastProcessedOrders;
            }
          }

          lastProcessedOrders = orders;
          return orders;
        } catch (e, stack) {
          print(
            'OrderStreamProviderSimple: Error in document processing loop: $e',
          );
          print('OrderStreamProviderSimple: Stack trace: $stack');
          rethrow;
        }
      })
      .handleError((error, stack) {
        print('OrderStreamProviderSimple: Stream error: $error');
        print('OrderStreamProviderSimple: Stack trace: $stack');
        return <OrderModel>[];
      });
});

// Simple FutureProvider as backup for orders
final ordersFutureProvider = FutureProvider.family<
  List<OrderModel>,
  OrderFilter
>((ref, filter) async {
  final firestore = FirebaseFirestore.instance;
  print(
    'OrdersFutureProvider: Loading orders for userId: ${filter.userId}, role: ${filter.role}',
  );

  try {
    Query query;

    if (filter.role == 'customer') {
      query = firestore
          .collection('orders')
          .where('customerId', isEqualTo: filter.userId);
    } else {
      query = firestore
          .collection('orders')
          .where('sellerId', isEqualTo: filter.userId);
    }

    // Add status filter if provided
    if (filter.status != null &&
        filter.status!.isNotEmpty &&
        filter.status != 'all') {
      if (filter.status == 'completed') {
        query = query.where('status', whereIn: ['delivered', 'shipped']);
      } else {
        query = query.where('status', isEqualTo: filter.status);
      }
    }

    // Order by creation date, newest first
    query = query.orderBy('createdAt', descending: true);

    final snapshot = await query.get();
    print('OrdersFutureProvider: Found ${snapshot.docs.length} orders');

    final orders =
        snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return OrderModel.fromMap(data, doc.id);
        }).toList();

    print(
      'OrdersFutureProvider: Successfully converted ${orders.length} orders',
    );
    return orders;
  } catch (e) {
    print('OrdersFutureProvider: Error loading orders: $e');
    return <OrderModel>[];
  }
});

// Simple test provider to check if orders exist
final testOrdersProvider = FutureProvider.family<bool, String>((
  ref,
  userId,
) async {
  final firestore = FirebaseFirestore.instance;
  print('TestOrdersProvider: Checking for orders for user: $userId');

  try {
    final snapshot =
        await firestore
            .collection('orders')
            .where('customerId', isEqualTo: userId)
            .limit(1)
            .get();

    print(
      'TestOrdersProvider: Found ${snapshot.docs.length} orders for user: $userId',
    );
    return snapshot.docs.isNotEmpty;
  } catch (e) {
    print('TestOrdersProvider: Error checking orders: $e');
    return false;
  }
});

// Provider for order operations
final orderProvider = StateNotifierProvider<OrderNotifier, List<OrderModel>>((
  ref,
) {
  return OrderNotifier();
});
