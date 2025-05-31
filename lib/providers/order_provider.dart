import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/order_model.dart';

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
  if (filter.status != null && filter.status != 'all') {
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
final orderStreamProviderSimple =
    StreamProvider.family<List<OrderModel>, OrderFilter>((ref, filter) {
      final firestore = FirebaseFirestore.instance;
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
      if (filter.status != null && filter.status != 'all') {
        if (filter.status == 'completed') {
          // For completed tab, show both delivered and shipped
          query = query.where('status', whereIn: ['delivered', 'shipped']);
        } else {
          query = query.where('status', isEqualTo: filter.status);
        }
      }

      // Order by creation date, newest first
      query = query.orderBy('createdAt', descending: true);

      return query.snapshots().map((snapshot) {
        return snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return OrderModel.fromMap(data, doc.id);
        }).toList();
      });
    });

// Provider for order operations
final orderProvider = StateNotifierProvider<OrderNotifier, List<OrderModel>>((
  ref,
) {
  return OrderNotifier();
});
