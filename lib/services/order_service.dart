import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order_model.dart';

class OrderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> placeOrder(OrderModel order) async {
    try {
      await _firestore.collection('orders').doc(order.id).set(order.toMap());
    } catch (e) {
      throw Exception('Failed to place order: $e');
    }
  }

  Stream<List<OrderModel>> getOrders(String userId, String role) {
    try {
      return _firestore
          .collection('orders')
          .where(
            role == 'customer' ? 'customerId' : 'sellerId',
            isEqualTo: userId,
          )
          .snapshots()
          .map(
            (snapshot) =>
                snapshot.docs
                    .map((doc) => OrderModel.fromMap(doc.data(), doc.id))
                    .toList(),
          )
          .handleError((error) {
            print('Firestore error: $error');
            throw error; // Ensure errors are propagated
          });
    } catch (e) {
      print('Error setting up Firestore stream: $e');
      return Stream.value([]); // Fallback to empty list
    }
  }

  Future<void> updateOrderStatus(String orderId, String status) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({
        'status': status,
      });
    } catch (e) {
      throw Exception('Failed to update order: $e');
    }
  }

  // Stream<List<OrderModel>> getOrders(String userId, String role) {
  //   return _firestore
  //       .collection('orders')
  //       .where(role == 'customer' ? 'customerId' : 'sellerId', isEqualTo: userId)
  //       .snapshots()
  //       .map((snapshot) => snapshot.docs
  //           .map((doc) => OrderModel.fromMap(doc.data()))
  //           .toList());
  // }

  Future<void> updateOrder(OrderModel order) async {
    await _firestore.collection('orders').doc(order.id).set(order.toMap());
  }
}
