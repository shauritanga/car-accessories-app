import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../models/order_modification_model.dart';
import '../models/order_model.dart';

class OrderModificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Submit a new modification request
  Future<void> submitModificationRequest(OrderModificationModel request) async {
    try {
      await _firestore.collection('order_modifications').doc(request.id).set(request.toMap());
      
      // Update order status if it's a cancellation
      if (request.type == ModificationType.cancellation) {
        await _firestore.collection('orders').doc(request.orderId).update({
          'status': 'cancellation_requested',
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      throw Exception('Failed to submit modification request: $e');
    }
  }

  // Update modification request status (admin function)
  Future<void> updateModificationStatus({
    required String requestId,
    required ModificationStatus status,
    String? adminNotes,
    String? processedBy,
    String? trackingNumber,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'status': status.toString(),
        'processedAt': FieldValue.serverTimestamp(),
      };

      if (adminNotes != null) updateData['adminNotes'] = adminNotes;
      if (processedBy != null) updateData['processedBy'] = processedBy;
      if (trackingNumber != null) updateData['trackingNumber'] = trackingNumber;

      if (status == ModificationStatus.completed) {
        updateData['completedAt'] = FieldValue.serverTimestamp();
      }

      await _firestore.collection('order_modifications').doc(requestId).update(updateData);

      // Update order status based on modification type and status
      final request = await getModificationRequest(requestId);
      if (request != null) {
        await _updateOrderStatusBasedOnModification(request, status);
      }
    } catch (e) {
      throw Exception('Failed to update modification status: $e');
    }
  }

  // Get modification request by ID
  Future<OrderModificationModel?> getModificationRequest(String requestId) async {
    try {
      final doc = await _firestore.collection('order_modifications').doc(requestId).get();
      if (doc.exists) {
        return OrderModificationModel.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get modification request: $e');
    }
  }

  // Get modification requests for a customer
  Stream<List<OrderModificationModel>> getCustomerModificationRequests(String customerId) {
    return _firestore
        .collection('order_modifications')
        .where('customerId', isEqualTo: customerId)
        .orderBy('requestedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => OrderModificationModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Get modification requests for an order
  Stream<List<OrderModificationModel>> getOrderModificationRequests(String orderId) {
    return _firestore
        .collection('order_modifications')
        .where('orderId', isEqualTo: orderId)
        .orderBy('requestedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => OrderModificationModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Check if order can be cancelled
  Future<bool> canCancelOrder(String orderId) async {
    try {
      final orderDoc = await _firestore.collection('orders').doc(orderId).get();
      if (!orderDoc.exists) return false;

      final orderData = orderDoc.data()!;
      final status = orderData['status'] as String;

      // Can only cancel if order is pending or processing
      return status == 'pending' || status == 'processing';
    } catch (e) {
      return false;
    }
  }

  // Check if order can be returned
  Future<bool> canReturnOrder(String orderId) async {
    try {
      final orderDoc = await _firestore.collection('orders').doc(orderId).get();
      if (!orderDoc.exists) return false;

      final orderData = orderDoc.data()!;
      final status = orderData['status'] as String;
      final createdAt = (orderData['createdAt'] as Timestamp).toDate();

      // Can only return if order is delivered and within return window (30 days)
      final daysSinceDelivery = DateTime.now().difference(createdAt).inDays;
      return status == 'delivered' && daysSinceDelivery <= 30;
    } catch (e) {
      return false;
    }
  }

  // Upload evidence images for modification request
  Future<List<String>> uploadEvidenceImages(List<File> images, String requestId) async {
    try {
      final List<String> imageUrls = [];
      
      for (int i = 0; i < images.length; i++) {
        final file = images[i];
        final fileName = '${requestId}_evidence_$i.jpg';
        final ref = _storage.ref().child('order_modifications').child(fileName);
        
        final uploadTask = ref.putFile(file);
        final snapshot = await uploadTask;
        final downloadUrl = await snapshot.ref.getDownloadURL();
        
        imageUrls.add(downloadUrl);
      }
      
      return imageUrls;
    } catch (e) {
      throw Exception('Failed to upload evidence images: $e');
    }
  }

  // Calculate refund amount
  Future<double> calculateRefundAmount(String orderId, List<String> itemIds) async {
    try {
      final orderDoc = await _firestore.collection('orders').doc(orderId).get();
      if (!orderDoc.exists) return 0.0;

      final orderData = orderDoc.data()!;
      final items = orderData['items'] as List<dynamic>;
      
      double refundAmount = 0.0;
      
      if (itemIds.isEmpty) {
        // Full order refund
        refundAmount = (orderData['total'] as num).toDouble();
      } else {
        // Partial refund for specific items
        for (final item in items) {
          final itemMap = item as Map<String, dynamic>;
          if (itemIds.contains(itemMap['productId'])) {
            final price = (itemMap['price'] as num).toDouble();
            final quantity = itemMap['quantity'] as int;
            refundAmount += price * quantity;
          }
        }
      }
      
      return refundAmount;
    } catch (e) {
      throw Exception('Failed to calculate refund amount: $e');
    }
  }

  // Process refund (mock implementation)
  Future<void> processRefund({
    required String requestId,
    required double amount,
    required RefundMethod method,
  }) async {
    try {
      // In a real implementation, this would integrate with payment processors
      // For now, we'll just update the modification request
      await _firestore.collection('order_modifications').doc(requestId).update({
        'status': ModificationStatus.completed.toString(),
        'completedAt': FieldValue.serverTimestamp(),
        'metadata': {
          'refund_processed': true,
          'refund_amount': amount,
          'refund_method': method.toString(),
          'refund_transaction_id': 'REF_${DateTime.now().millisecondsSinceEpoch}',
        },
      });
    } catch (e) {
      throw Exception('Failed to process refund: $e');
    }
  }

  // Cancel modification request
  Future<void> cancelModificationRequest(String requestId) async {
    try {
      await _firestore.collection('order_modifications').doc(requestId).update({
        'status': ModificationStatus.cancelled.toString(),
        'completedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to cancel modification request: $e');
    }
  }

  // Get modification statistics for admin
  Future<Map<String, int>> getModificationStatistics() async {
    try {
      final snapshot = await _firestore.collection('order_modifications').get();
      
      final stats = <String, int>{
        'total': 0,
        'pending': 0,
        'approved': 0,
        'rejected': 0,
        'completed': 0,
        'cancellations': 0,
        'returns': 0,
        'refunds': 0,
      };
      
      for (final doc in snapshot.docs) {
        final data = doc.data();
        stats['total'] = (stats['total'] ?? 0) + 1;
        
        final status = data['status'] as String;
        final type = data['type'] as String;
        
        // Count by status
        if (status.contains('pending')) stats['pending'] = (stats['pending'] ?? 0) + 1;
        if (status.contains('approved')) stats['approved'] = (stats['approved'] ?? 0) + 1;
        if (status.contains('rejected')) stats['rejected'] = (stats['rejected'] ?? 0) + 1;
        if (status.contains('completed')) stats['completed'] = (stats['completed'] ?? 0) + 1;
        
        // Count by type
        if (type.contains('cancellation')) stats['cancellations'] = (stats['cancellations'] ?? 0) + 1;
        if (type.contains('return')) stats['returns'] = (stats['returns'] ?? 0) + 1;
        if (type.contains('refund')) stats['refunds'] = (stats['refunds'] ?? 0) + 1;
      }
      
      return stats;
    } catch (e) {
      throw Exception('Failed to get modification statistics: $e');
    }
  }

  // Private helper to update order status based on modification
  Future<void> _updateOrderStatusBasedOnModification(
    OrderModificationModel request,
    ModificationStatus status,
  ) async {
    String? newOrderStatus;
    
    if (request.type == ModificationType.cancellation) {
      switch (status) {
        case ModificationStatus.approved:
          newOrderStatus = 'cancelled';
          break;
        case ModificationStatus.rejected:
          newOrderStatus = 'processing'; // Revert to processing
          break;
        default:
          break;
      }
    } else if (request.type == ModificationType.return_) {
      switch (status) {
        case ModificationStatus.approved:
          newOrderStatus = 'return_approved';
          break;
        case ModificationStatus.completed:
          newOrderStatus = 'returned';
          break;
        default:
          break;
      }
    }
    
    if (newOrderStatus != null) {
      await _firestore.collection('orders').doc(request.orderId).update({
        'status': newOrderStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }
}
