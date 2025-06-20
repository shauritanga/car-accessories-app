import 'package:cloud_firestore/cloud_firestore.dart';

class OrderStatusUpdate {
  final String status;
  final String description;
  final DateTime timestamp;
  final String? location;
  final String? updatedBy;

  OrderStatusUpdate({
    required this.status,
    required this.description,
    required this.timestamp,
    this.location,
    this.updatedBy,
  });

  factory OrderStatusUpdate.fromMap(Map<String, dynamic> map) {
    return OrderStatusUpdate(
      status: map['status'] ?? '',
      description: map['description'] ?? '',
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      location: map['location'],
      updatedBy: map['updatedBy'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'status': status,
      'description': description,
      'timestamp': Timestamp.fromDate(timestamp),
      'location': location,
      'updatedBy': updatedBy,
    };
  }
}

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
  final double subtotal;
  final double shippingCost;
  final double tax;
  final double discount;
  final double total;
  final String status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? estimatedDeliveryDate;
  final DateTime? actualDeliveryDate;
  final String? deliveryAddress;
  final String? deliveryInstructions;
  final String? trackingNumber;
  final String? shippingMethod;
  final String? paymentMethod;
  final String? paymentStatus;
  final String? couponCode;
  final Map<String, dynamic>? metadata;
  final List<OrderStatusUpdate> statusHistory;

  OrderModel({
    required this.id,
    required this.customerId,
    required this.sellerId,
    required this.items,
    required this.subtotal,
    this.shippingCost = 0.0,
    this.tax = 0.0,
    this.discount = 0.0,
    required this.total,
    required this.status,
    required this.createdAt,
    this.updatedAt,
    this.estimatedDeliveryDate,
    this.actualDeliveryDate,
    this.deliveryAddress,
    this.deliveryInstructions,
    this.trackingNumber,
    this.shippingMethod,
    this.paymentMethod,
    this.paymentStatus,
    this.couponCode,
    this.metadata,
    this.statusHistory = const [],
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
          (accumulator, item) => accumulator + (item.price * item.quantity),
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
        subtotal: (data['subtotal'] as num?)?.toDouble() ?? total,
        shippingCost: (data['shippingCost'] as num?)?.toDouble() ?? 0.0,
        tax: (data['tax'] as num?)?.toDouble() ?? 0.0,
        discount: (data['discount'] as num?)?.toDouble() ?? 0.0,
        total: total,
        status: data['status'] ?? 'pending',
        createdAt: createdAt,
        updatedAt: updatedAt,
        estimatedDeliveryDate:
            data['estimatedDeliveryDate'] != null
                ? (data['estimatedDeliveryDate'] as Timestamp).toDate()
                : null,
        actualDeliveryDate:
            data['actualDeliveryDate'] != null
                ? (data['actualDeliveryDate'] as Timestamp).toDate()
                : null,
        deliveryAddress: data['deliveryAddress'],
        deliveryInstructions: data['deliveryInstructions'],
        trackingNumber: data['trackingNumber'],
        shippingMethod: data['shippingMethod'],
        paymentMethod: data['paymentMethod'],
        paymentStatus: data['paymentStatus'],
        couponCode: data['couponCode'],
        metadata: data['metadata'],
        statusHistory:
            (data['statusHistory'] as List?)
                ?.map((item) => OrderStatusUpdate.fromMap(item))
                .toList() ??
            [],
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
      'subtotal': subtotal,
      'shippingCost': shippingCost,
      'tax': tax,
      'discount': discount,
      'total': total,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'estimatedDeliveryDate':
          estimatedDeliveryDate != null
              ? Timestamp.fromDate(estimatedDeliveryDate!)
              : null,
      'actualDeliveryDate':
          actualDeliveryDate != null
              ? Timestamp.fromDate(actualDeliveryDate!)
              : null,
      'deliveryAddress': deliveryAddress,
      'deliveryInstructions': deliveryInstructions,
      'trackingNumber': trackingNumber,
      'shippingMethod': shippingMethod,
      'paymentMethod': paymentMethod,
      'paymentStatus': paymentStatus,
      'couponCode': couponCode,
      'metadata': metadata,
      'statusHistory': statusHistory.map((update) => update.toMap()).toList(),
    };
  }

  // Helper methods
  bool get isDelivered => status == 'delivered';
  bool get isShipped => status == 'shipped' || status == 'delivered';
  bool get isCancelled => status == 'cancelled';
  bool get canBeCancelled => status == 'pending' || status == 'processing';
  bool get canBeReturned =>
      isDelivered &&
      actualDeliveryDate != null &&
      DateTime.now().difference(actualDeliveryDate!).inDays <= 30;

  String get formattedTotal => 'TZS ${total.toStringAsFixed(0)}';
  String get formattedSubtotal => 'TZS ${subtotal.toStringAsFixed(0)}';
  String get formattedShipping => 'TZS ${shippingCost.toStringAsFixed(0)}';
  String get formattedTax => 'TZS ${tax.toStringAsFixed(0)}';
  String get formattedDiscount => 'TZS ${discount.toStringAsFixed(0)}';

  String get statusDisplayName {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Order Placed';
      case 'processing':
        return 'Processing';
      case 'shipped':
        return 'Shipped';
      case 'delivered':
        return 'Delivered';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }

  String get estimatedDeliveryText {
    if (estimatedDeliveryDate == null) return 'Delivery date not available';

    final now = DateTime.now();
    final difference = estimatedDeliveryDate!.difference(now).inDays;

    if (difference < 0) {
      return 'Delivery was expected ${(-difference)} days ago';
    } else if (difference == 0) {
      return 'Expected delivery today';
    } else if (difference == 1) {
      return 'Expected delivery tomorrow';
    } else {
      return 'Expected delivery in $difference days';
    }
  }

  int get itemCount => items.fold(0, (total, item) => total + item.quantity);

  String get shortId => id.length > 8 ? id.substring(0, 8) : id;
}
