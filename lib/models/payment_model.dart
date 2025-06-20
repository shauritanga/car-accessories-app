import 'package:cloud_firestore/cloud_firestore.dart';

enum PaymentMethod {
  creditCard,
  debitCard,
  mobileMoney,
  bankTransfer,
  cashOnDelivery,
}

enum PaymentStatus {
  pending,
  processing,
  completed,
  failed,
  refunded,
  cancelled,
}

class PaymentMethodModel {
  final String id;
  final String userId;
  final PaymentMethod type;
  final String? cardNumber; // Last 4 digits only
  final String? cardHolderName;
  final String? expiryDate;
  final String? brand; // Visa, Mastercard, etc.
  final String? mobileNumber; // For mobile money
  final String? bankName;
  final bool isDefault;
  final DateTime createdAt;

  PaymentMethodModel({
    required this.id,
    required this.userId,
    required this.type,
    this.cardNumber,
    this.cardHolderName,
    this.expiryDate,
    this.brand,
    this.mobileNumber,
    this.bankName,
    this.isDefault = false,
    required this.createdAt,
  });

  factory PaymentMethodModel.fromMap(Map<String, dynamic> data, String id) {
    return PaymentMethodModel(
      id: id,
      userId: data['userId'] ?? '',
      type: PaymentMethod.values.firstWhere(
        (e) => e.toString() == data['type'],
        orElse: () => PaymentMethod.creditCard,
      ),
      cardNumber: data['cardNumber'],
      cardHolderName: data['cardHolderName'],
      expiryDate: data['expiryDate'],
      brand: data['brand'],
      mobileNumber: data['mobileNumber'],
      bankName: data['bankName'],
      isDefault: data['isDefault'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'type': type.toString(),
      'cardNumber': cardNumber,
      'cardHolderName': cardHolderName,
      'expiryDate': expiryDate,
      'brand': brand,
      'mobileNumber': mobileNumber,
      'bankName': bankName,
      'isDefault': isDefault,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  String get displayName {
    switch (type) {
      case PaymentMethod.creditCard:
      case PaymentMethod.debitCard:
        return '$brand •••• $cardNumber';
      case PaymentMethod.mobileMoney:
        return 'Mobile Money ($mobileNumber)';
      case PaymentMethod.bankTransfer:
        return 'Bank Transfer ($bankName)';
      case PaymentMethod.cashOnDelivery:
        return 'Cash on Delivery';
    }
  }
}

class PaymentModel {
  final String id;
  final String orderId;
  final String userId;
  final double amount;
  final String currency;
  final PaymentMethod method;
  final PaymentStatus status;
  final String? stripePaymentIntentId;
  final String? transactionId;
  final String? failureReason;
  final DateTime createdAt;
  final DateTime? completedAt;

  PaymentModel({
    required this.id,
    required this.orderId,
    required this.userId,
    required this.amount,
    this.currency = 'TZS',
    required this.method,
    required this.status,
    this.stripePaymentIntentId,
    this.transactionId,
    this.failureReason,
    required this.createdAt,
    this.completedAt,
  });

  factory PaymentModel.fromMap(Map<String, dynamic> data, String id) {
    return PaymentModel(
      id: id,
      orderId: data['orderId'] ?? '',
      userId: data['userId'] ?? '',
      amount: (data['amount'] as num).toDouble(),
      currency: data['currency'] ?? 'TZS',
      method: PaymentMethod.values.firstWhere(
        (e) => e.toString() == data['method'],
        orElse: () => PaymentMethod.creditCard,
      ),
      status: PaymentStatus.values.firstWhere(
        (e) => e.toString() == data['status'],
        orElse: () => PaymentStatus.pending,
      ),
      stripePaymentIntentId: data['stripePaymentIntentId'],
      transactionId: data['transactionId'],
      failureReason: data['failureReason'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      completedAt: data['completedAt'] != null
          ? (data['completedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'orderId': orderId,
      'userId': userId,
      'amount': amount,
      'currency': currency,
      'method': method.toString(),
      'status': status.toString(),
      'stripePaymentIntentId': stripePaymentIntentId,
      'transactionId': transactionId,
      'failureReason': failureReason,
      'createdAt': Timestamp.fromDate(createdAt),
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
    };
  }
}
