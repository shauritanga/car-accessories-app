import 'package:cloud_firestore/cloud_firestore.dart';

class OrderItem {
  final String productId;
  final double price;
  final int quantity;
  final String sellerId;

  OrderItem({
    required this.productId,
    required this.price,
    required this.quantity,
    required this.sellerId,
  });

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      productId: map['productId'],
      price: (map['price'] as num).toDouble(),
      quantity: map['quantity'],
      sellerId: map['sellerId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'price': price,
      'quantity': quantity,
      'sellerId': sellerId,
    };
  }
}

class OrderModel {
  final String id;
  final String customerId;
  final String sellerId;
  final List<OrderItem> items;
  final double total;
  final String status;
  final DateTime createdAt;
  final DateTime? updatedAt;

  OrderModel({
    required this.id,
    required this.customerId,
    required this.sellerId,
    required this.items,
    required this.total,
    required this.status,
    required this.createdAt,
    this.updatedAt,
  });

  factory OrderModel.fromMap(Map<String, dynamic> data, String docId) {
    try {
      // Debug print
      // print('Converting document to OrderModel: $docId');
      // print('Data: $data');

      // Handle Firestore Timestamp conversion to DateTime
      DateTime createdAt;
      if (data['createdAt'] is Timestamp) {
        createdAt = (data['createdAt'] as Timestamp).toDate();
      } else if (data['createdAt'] is DateTime) {
        createdAt = data['createdAt'] as DateTime;
      } else {
        // Default to current time if missing or invalid
        // print('Warning: Invalid createdAt format in order $docId');
        createdAt = DateTime.now();
      }

      // Parse items
      List<OrderItem> items = [];
      if (data['items'] != null) {
        items =
            (data['items'] as List)
                .map((item) => OrderItem.fromMap(item as Map<String, dynamic>))
                .toList();
      }

      // Get total from data or calculate from items
      double total;
      if (data['total'] != null) {
        total =
            (data['total'] is int)
                ? (data['total'] as int).toDouble()
                : (data['total'] as num).toDouble();
      } else {
        // Calculate total from items if not provided
        total = items.fold(
          0,
          (sum, item) => sum + (item.price * item.quantity),
        );
      }

      // Get updatedAt timestamp if available
      DateTime? updatedAt;
      if (data['updatedAt'] is Timestamp) {
        updatedAt = (data['updatedAt'] as Timestamp).toDate();
      } else if (data['updatedAt'] is DateTime) {
        updatedAt = data['updatedAt'] as DateTime;
      }

      return OrderModel(
        id: data['id'] ?? docId,
        customerId: data['customerId'] ?? '',
        sellerId: data['sellerId'] ?? '',
        items: items,
        total: total,
        status: data['status'] ?? 'pending',
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
    } catch (e) {
      // print('Error parsing OrderModel from document $docId: $e');
      // print('Stack trace: $stack');
      rethrow; // Re-throw to be handled by the caller
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'customerId': customerId,
      'sellerId': sellerId,
      'items': items.map((item) => item.toMap()).toList(),
      'total': total,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }
}
