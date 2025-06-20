import 'package:cloud_firestore/cloud_firestore.dart';

enum ModificationType {
  cancellation,
  return_,
  refund,
  exchange,
}

enum ModificationStatus {
  pending,
  approved,
  rejected,
  processing,
  completed,
  cancelled,
}

enum RefundMethod {
  originalPayment,
  storeCredit,
  bankTransfer,
}

class OrderModificationModel {
  final String id;
  final String orderId;
  final String customerId;
  final ModificationType type;
  final ModificationStatus status;
  final String reason;
  final String? description;
  final List<String> items; // Product IDs or order item IDs
  final double? refundAmount;
  final RefundMethod? refundMethod;
  final List<String> images; // Evidence images
  final DateTime requestedAt;
  final DateTime? processedAt;
  final DateTime? completedAt;
  final String? processedBy; // Admin/staff ID
  final String? adminNotes;
  final String? trackingNumber; // For returns
  final Map<String, dynamic>? metadata;

  OrderModificationModel({
    required this.id,
    required this.orderId,
    required this.customerId,
    required this.type,
    required this.status,
    required this.reason,
    this.description,
    this.items = const [],
    this.refundAmount,
    this.refundMethod,
    this.images = const [],
    required this.requestedAt,
    this.processedAt,
    this.completedAt,
    this.processedBy,
    this.adminNotes,
    this.trackingNumber,
    this.metadata,
  });

  factory OrderModificationModel.fromMap(Map<String, dynamic> data, String id) {
    return OrderModificationModel(
      id: id,
      orderId: data['orderId'] ?? '',
      customerId: data['customerId'] ?? '',
      type: ModificationType.values.firstWhere(
        (e) => e.toString() == data['type'],
        orElse: () => ModificationType.cancellation,
      ),
      status: ModificationStatus.values.firstWhere(
        (e) => e.toString() == data['status'],
        orElse: () => ModificationStatus.pending,
      ),
      reason: data['reason'] ?? '',
      description: data['description'],
      items: List<String>.from(data['items'] ?? []),
      refundAmount: data['refundAmount']?.toDouble(),
      refundMethod: data['refundMethod'] != null
          ? RefundMethod.values.firstWhere(
              (e) => e.toString() == data['refundMethod'],
              orElse: () => RefundMethod.originalPayment,
            )
          : null,
      images: List<String>.from(data['images'] ?? []),
      requestedAt: (data['requestedAt'] as Timestamp).toDate(),
      processedAt: data['processedAt'] != null
          ? (data['processedAt'] as Timestamp).toDate()
          : null,
      completedAt: data['completedAt'] != null
          ? (data['completedAt'] as Timestamp).toDate()
          : null,
      processedBy: data['processedBy'],
      adminNotes: data['adminNotes'],
      trackingNumber: data['trackingNumber'],
      metadata: data['metadata'] != null
          ? Map<String, dynamic>.from(data['metadata'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'orderId': orderId,
      'customerId': customerId,
      'type': type.toString(),
      'status': status.toString(),
      'reason': reason,
      'description': description,
      'items': items,
      'refundAmount': refundAmount,
      'refundMethod': refundMethod?.toString(),
      'images': images,
      'requestedAt': Timestamp.fromDate(requestedAt),
      'processedAt': processedAt != null ? Timestamp.fromDate(processedAt!) : null,
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'processedBy': processedBy,
      'adminNotes': adminNotes,
      'trackingNumber': trackingNumber,
      'metadata': metadata,
    };
  }

  OrderModificationModel copyWith({
    String? id,
    String? orderId,
    String? customerId,
    ModificationType? type,
    ModificationStatus? status,
    String? reason,
    String? description,
    List<String>? items,
    double? refundAmount,
    RefundMethod? refundMethod,
    List<String>? images,
    DateTime? requestedAt,
    DateTime? processedAt,
    DateTime? completedAt,
    String? processedBy,
    String? adminNotes,
    String? trackingNumber,
    Map<String, dynamic>? metadata,
  }) {
    return OrderModificationModel(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      customerId: customerId ?? this.customerId,
      type: type ?? this.type,
      status: status ?? this.status,
      reason: reason ?? this.reason,
      description: description ?? this.description,
      items: items ?? this.items,
      refundAmount: refundAmount ?? this.refundAmount,
      refundMethod: refundMethod ?? this.refundMethod,
      images: images ?? this.images,
      requestedAt: requestedAt ?? this.requestedAt,
      processedAt: processedAt ?? this.processedAt,
      completedAt: completedAt ?? this.completedAt,
      processedBy: processedBy ?? this.processedBy,
      adminNotes: adminNotes ?? this.adminNotes,
      trackingNumber: trackingNumber ?? this.trackingNumber,
      metadata: metadata ?? this.metadata,
    );
  }

  String get typeDisplayName {
    switch (type) {
      case ModificationType.cancellation:
        return 'Cancellation';
      case ModificationType.return_:
        return 'Return';
      case ModificationType.refund:
        return 'Refund';
      case ModificationType.exchange:
        return 'Exchange';
    }
  }

  String get statusDisplayName {
    switch (status) {
      case ModificationStatus.pending:
        return 'Pending Review';
      case ModificationStatus.approved:
        return 'Approved';
      case ModificationStatus.rejected:
        return 'Rejected';
      case ModificationStatus.processing:
        return 'Processing';
      case ModificationStatus.completed:
        return 'Completed';
      case ModificationStatus.cancelled:
        return 'Cancelled';
    }
  }

  bool get canBeCancelled {
    return status == ModificationStatus.pending;
  }

  bool get isCompleted {
    return status == ModificationStatus.completed ||
           status == ModificationStatus.rejected ||
           status == ModificationStatus.cancelled;
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(requestedAt);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }
}

// Predefined cancellation/return reasons
class ModificationReasons {
  static const List<String> cancellationReasons = [
    'Changed my mind',
    'Found a better price elsewhere',
    'Ordered by mistake',
    'No longer needed',
    'Delivery taking too long',
    'Payment issues',
    'Other',
  ];

  static const List<String> returnReasons = [
    'Item not as described',
    'Wrong item received',
    'Damaged during shipping',
    'Defective product',
    'Poor quality',
    'Doesn\'t fit',
    'Changed my mind',
    'Other',
  ];

  static const List<String> refundReasons = [
    'Duplicate payment',
    'Cancelled order',
    'Returned item',
    'Defective product',
    'Service not provided',
    'Billing error',
    'Other',
  ];
}
