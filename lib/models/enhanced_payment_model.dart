import 'package:cloud_firestore/cloud_firestore.dart';

enum PaymentMethodType {
  creditCard,
  debitCard,
  mobileMoney,
  bankTransfer,
  cashOnDelivery,
  buyNowPayLater,
  subscription,
  cryptocurrency,
  internationalTransfer,
  digitalWallet,
}

enum BuyNowPayLaterProvider {
  klarna,
  afterpay,
  affirm,
  paypalCredit,
  custom,
}

enum SubscriptionStatus {
  active,
  paused,
  cancelled,
  expired,
  pending,
}

enum CryptocurrencyType {
  bitcoin,
  ethereum,
  litecoin,
  bitcoinCash,
  ripple,
  cardano,
  polkadot,
  dogecoin,
}

class BuyNowPayLaterPlan {
  final String id;
  final BuyNowPayLaterProvider provider;
  final String name;
  final String description;
  final int installmentCount;
  final double installmentAmount;
  final double totalAmount;
  final double interestRate;
  final double fees;
  final DateTime dueDate;
  final bool isInterestFree;
  final List<InstallmentPayment> installments;
  final DateTime createdAt;

  BuyNowPayLaterPlan({
    required this.id,
    required this.provider,
    required this.name,
    required this.description,
    required this.installmentCount,
    required this.installmentAmount,
    required this.totalAmount,
    required this.interestRate,
    required this.fees,
    required this.dueDate,
    required this.isInterestFree,
    required this.installments,
    required this.createdAt,
  });

  factory BuyNowPayLaterPlan.fromMap(Map<String, dynamic> data, String id) {
    return BuyNowPayLaterPlan(
      id: id,
      provider: BuyNowPayLaterProvider.values.firstWhere(
        (e) => e.toString() == data['provider'],
        orElse: () => BuyNowPayLaterProvider.custom,
      ),
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      installmentCount: data['installmentCount'] ?? 0,
      installmentAmount: (data['installmentAmount'] as num?)?.toDouble() ?? 0.0,
      totalAmount: (data['totalAmount'] as num?)?.toDouble() ?? 0.0,
      interestRate: (data['interestRate'] as num?)?.toDouble() ?? 0.0,
      fees: (data['fees'] as num?)?.toDouble() ?? 0.0,
      dueDate: (data['dueDate'] as Timestamp).toDate(),
      isInterestFree: data['isInterestFree'] ?? false,
      installments: (data['installments'] as List<dynamic>?)
              ?.map((e) => InstallmentPayment.fromMap(e))
              .toList() ??
          [],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'provider': provider.toString(),
      'name': name,
      'description': description,
      'installmentCount': installmentCount,
      'installmentAmount': installmentAmount,
      'totalAmount': totalAmount,
      'interestRate': interestRate,
      'fees': fees,
      'dueDate': Timestamp.fromDate(dueDate),
      'isInterestFree': isInterestFree,
      'installments': installments.map((e) => e.toMap()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  double get totalCost => totalAmount + fees;
  bool get isOverdue => DateTime.now().isAfter(dueDate);
  int get remainingInstallments {
    return installments.where((i) => i.status == InstallmentStatus.pending).length;
  }
}

class InstallmentPayment {
  final String id;
  final int installmentNumber;
  final double amount;
  final DateTime dueDate;
  final InstallmentStatus status;
  final DateTime? paidAt;
  final String? transactionId;

  InstallmentPayment({
    required this.id,
    required this.installmentNumber,
    required this.amount,
    required this.dueDate,
    required this.status,
    this.paidAt,
    this.transactionId,
  });

  factory InstallmentPayment.fromMap(Map<String, dynamic> data) {
    return InstallmentPayment(
      id: data['id'] ?? '',
      installmentNumber: data['installmentNumber'] ?? 0,
      amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
      dueDate: (data['dueDate'] as Timestamp).toDate(),
      status: InstallmentStatus.values.firstWhere(
        (e) => e.toString() == data['status'],
        orElse: () => InstallmentStatus.pending,
      ),
      paidAt: data['paidAt'] != null ? (data['paidAt'] as Timestamp).toDate() : null,
      transactionId: data['transactionId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'installmentNumber': installmentNumber,
      'amount': amount,
      'dueDate': Timestamp.fromDate(dueDate),
      'status': status.toString(),
      'paidAt': paidAt != null ? Timestamp.fromDate(paidAt!) : null,
      'transactionId': transactionId,
    };
  }

  bool get isOverdue => status == InstallmentStatus.pending && DateTime.now().isAfter(dueDate);
}

enum InstallmentStatus {
  pending,
  paid,
  overdue,
  defaulted,
}

class SubscriptionPlan {
  final String id;
  final String name;
  final String description;
  final double price;
  final String billingCycle; // monthly, quarterly, yearly
  final int billingInterval; // 1, 3, 12 months
  final List<String> features;
  final bool isActive;
  final int? maxUsers;
  final double? setupFee;
  final double? cancellationFee;
  final DateTime createdAt;

  SubscriptionPlan({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.billingCycle,
    required this.billingInterval,
    required this.features,
    this.isActive = true,
    this.maxUsers,
    this.setupFee,
    this.cancellationFee,
    required this.createdAt,
  });

  factory SubscriptionPlan.fromMap(Map<String, dynamic> data, String id) {
    return SubscriptionPlan(
      id: id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      billingCycle: data['billingCycle'] ?? 'monthly',
      billingInterval: data['billingInterval'] ?? 1,
      features: List<String>.from(data['features'] ?? []),
      isActive: data['isActive'] ?? true,
      maxUsers: data['maxUsers'],
      setupFee: (data['setupFee'] as num?)?.toDouble(),
      cancellationFee: (data['cancellationFee'] as num?)?.toDouble(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'billingCycle': billingCycle,
      'billingInterval': billingInterval,
      'features': features,
      'isActive': isActive,
      'maxUsers': maxUsers,
      'setupFee': setupFee,
      'cancellationFee': cancellationFee,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  double get yearlyPrice => price * (12 / billingInterval);
  String get formattedPrice => 'TZS ${price.toStringAsFixed(0)}/$billingCycle';
}

class UserSubscription {
  final String id;
  final String userId;
  final String planId;
  final SubscriptionStatus status;
  final DateTime startDate;
  final DateTime? endDate;
  final DateTime nextBillingDate;
  final double currentAmount;
  final int billingCycleCount;
  final bool autoRenew;
  final String? cancellationReason;
  final DateTime? cancelledAt;
  final List<SubscriptionPayment> payments;
  final DateTime createdAt;
  final DateTime? updatedAt;

  UserSubscription({
    required this.id,
    required this.userId,
    required this.planId,
    required this.status,
    required this.startDate,
    this.endDate,
    required this.nextBillingDate,
    required this.currentAmount,
    required this.billingCycleCount,
    required this.autoRenew,
    this.cancellationReason,
    this.cancelledAt,
    required this.payments,
    required this.createdAt,
    this.updatedAt,
  });

  factory UserSubscription.fromMap(Map<String, dynamic> data, String id) {
    return UserSubscription(
      id: id,
      userId: data['userId'] ?? '',
      planId: data['planId'] ?? '',
      status: SubscriptionStatus.values.firstWhere(
        (e) => e.toString() == data['status'],
        orElse: () => SubscriptionStatus.pending,
      ),
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: data['endDate'] != null ? (data['endDate'] as Timestamp).toDate() : null,
      nextBillingDate: (data['nextBillingDate'] as Timestamp).toDate(),
      currentAmount: (data['currentAmount'] as num?)?.toDouble() ?? 0.0,
      billingCycleCount: data['billingCycleCount'] ?? 0,
      autoRenew: data['autoRenew'] ?? true,
      cancellationReason: data['cancellationReason'],
      cancelledAt: data['cancelledAt'] != null ? (data['cancelledAt'] as Timestamp).toDate() : null,
      payments: (data['payments'] as List<dynamic>?)
              ?.map((e) => SubscriptionPayment.fromMap(e))
              .toList() ??
          [],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null ? (data['updatedAt'] as Timestamp).toDate() : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'planId': planId,
      'status': status.toString(),
      'startDate': Timestamp.fromDate(startDate),
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'nextBillingDate': Timestamp.fromDate(nextBillingDate),
      'currentAmount': currentAmount,
      'billingCycleCount': billingCycleCount,
      'autoRenew': autoRenew,
      'cancellationReason': cancellationReason,
      'cancelledAt': cancelledAt != null ? Timestamp.fromDate(cancelledAt!) : null,
      'payments': payments.map((e) => e.toMap()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  bool get isActive => status == SubscriptionStatus.active;
  bool get isOverdue => nextBillingDate.isBefore(DateTime.now()) && isActive;
  double get totalPaid => payments.fold(0.0, (sum, payment) => sum + payment.amount);
}

class SubscriptionPayment {
  final String id;
  final String subscriptionId;
  final double amount;
  final DateTime billingDate;
  final DateTime? paidAt;
  final String? transactionId;
  final PaymentStatus status;
  final String? failureReason;

  SubscriptionPayment({
    required this.id,
    required this.subscriptionId,
    required this.amount,
    required this.billingDate,
    this.paidAt,
    this.transactionId,
    required this.status,
    this.failureReason,
  });

  factory SubscriptionPayment.fromMap(Map<String, dynamic> data) {
    return SubscriptionPayment(
      id: data['id'] ?? '',
      subscriptionId: data['subscriptionId'] ?? '',
      amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
      billingDate: (data['billingDate'] as Timestamp).toDate(),
      paidAt: data['paidAt'] != null ? (data['paidAt'] as Timestamp).toDate() : null,
      transactionId: data['transactionId'],
      status: PaymentStatus.values.firstWhere(
        (e) => e.toString() == data['status'],
        orElse: () => PaymentStatus.pending,
      ),
      failureReason: data['failureReason'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'subscriptionId': subscriptionId,
      'amount': amount,
      'billingDate': Timestamp.fromDate(billingDate),
      'paidAt': paidAt != null ? Timestamp.fromDate(paidAt!) : null,
      'transactionId': transactionId,
      'status': status.toString(),
      'failureReason': failureReason,
    };
  }
}

class CryptocurrencyPayment {
  final String id;
  final String orderId;
  final String userId;
  final CryptocurrencyType cryptocurrency;
  final double amountInCrypto;
  final double amountInFiat;
  final String walletAddress;
  final String? transactionHash;
  final PaymentStatus status;
  final DateTime createdAt;
  final DateTime? confirmedAt;
  final int confirmations;
  final int requiredConfirmations;
  final double exchangeRate;
  final String? failureReason;

  CryptocurrencyPayment({
    required this.id,
    required this.orderId,
    required this.userId,
    required this.cryptocurrency,
    required this.amountInCrypto,
    required this.amountInFiat,
    required this.walletAddress,
    this.transactionHash,
    required this.status,
    required this.createdAt,
    this.confirmedAt,
    this.confirmations = 0,
    this.requiredConfirmations = 3,
    required this.exchangeRate,
    this.failureReason,
  });

  factory CryptocurrencyPayment.fromMap(Map<String, dynamic> data, String id) {
    return CryptocurrencyPayment(
      id: id,
      orderId: data['orderId'] ?? '',
      userId: data['userId'] ?? '',
      cryptocurrency: CryptocurrencyType.values.firstWhere(
        (e) => e.toString() == data['cryptocurrency'],
        orElse: () => CryptocurrencyType.bitcoin,
      ),
      amountInCrypto: (data['amountInCrypto'] as num?)?.toDouble() ?? 0.0,
      amountInFiat: (data['amountInFiat'] as num?)?.toDouble() ?? 0.0,
      walletAddress: data['walletAddress'] ?? '',
      transactionHash: data['transactionHash'],
      status: PaymentStatus.values.firstWhere(
        (e) => e.toString() == data['status'],
        orElse: () => PaymentStatus.pending,
      ),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      confirmedAt: data['confirmedAt'] != null ? (data['confirmedAt'] as Timestamp).toDate() : null,
      confirmations: data['confirmations'] ?? 0,
      requiredConfirmations: data['requiredConfirmations'] ?? 3,
      exchangeRate: (data['exchangeRate'] as num?)?.toDouble() ?? 0.0,
      failureReason: data['failureReason'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'orderId': orderId,
      'userId': userId,
      'cryptocurrency': cryptocurrency.toString(),
      'amountInCrypto': amountInCrypto,
      'amountInFiat': amountInFiat,
      'walletAddress': walletAddress,
      'transactionHash': transactionHash,
      'status': status.toString(),
      'createdAt': Timestamp.fromDate(createdAt),
      'confirmedAt': confirmedAt != null ? Timestamp.fromDate(confirmedAt!) : null,
      'confirmations': confirmations,
      'requiredConfirmations': requiredConfirmations,
      'exchangeRate': exchangeRate,
      'failureReason': failureReason,
    };
  }

  bool get isConfirmed => confirmations >= requiredConfirmations;
  bool get isPending => status == PaymentStatus.pending && !isConfirmed;
  String get cryptoSymbol {
    switch (cryptocurrency) {
      case CryptocurrencyType.bitcoin:
        return 'BTC';
      case CryptocurrencyType.ethereum:
        return 'ETH';
      case CryptocurrencyType.litecoin:
        return 'LTC';
      case CryptocurrencyType.bitcoinCash:
        return 'BCH';
      case CryptocurrencyType.ripple:
        return 'XRP';
      case CryptocurrencyType.cardano:
        return 'ADA';
      case CryptocurrencyType.polkadot:
        return 'DOT';
      case CryptocurrencyType.dogecoin:
        return 'DOGE';
    }
  }
}

class InternationalPayment {
  final String id;
  final String orderId;
  final String userId;
  final String sourceCurrency;
  final String targetCurrency;
  final double sourceAmount;
  final double targetAmount;
  final double exchangeRate;
  final double transferFee;
  final String transferMethod;
  final String? referenceNumber;
  final PaymentStatus status;
  final DateTime createdAt;
  final DateTime? completedAt;
  final String? failureReason;
  final Map<String, dynamic> transferDetails;

  InternationalPayment({
    required this.id,
    required this.orderId,
    required this.userId,
    required this.sourceCurrency,
    required this.targetCurrency,
    required this.sourceAmount,
    required this.targetAmount,
    required this.exchangeRate,
    required this.transferFee,
    required this.transferMethod,
    this.referenceNumber,
    required this.status,
    required this.createdAt,
    this.completedAt,
    this.failureReason,
    this.transferDetails = const {},
  });

  factory InternationalPayment.fromMap(Map<String, dynamic> data, String id) {
    return InternationalPayment(
      id: id,
      orderId: data['orderId'] ?? '',
      userId: data['userId'] ?? '',
      sourceCurrency: data['sourceCurrency'] ?? '',
      targetCurrency: data['targetCurrency'] ?? '',
      sourceAmount: (data['sourceAmount'] as num?)?.toDouble() ?? 0.0,
      targetAmount: (data['targetAmount'] as num?)?.toDouble() ?? 0.0,
      exchangeRate: (data['exchangeRate'] as num?)?.toDouble() ?? 0.0,
      transferFee: (data['transferFee'] as num?)?.toDouble() ?? 0.0,
      transferMethod: data['transferMethod'] ?? '',
      referenceNumber: data['referenceNumber'],
      status: PaymentStatus.values.firstWhere(
        (e) => e.toString() == data['status'],
        orElse: () => PaymentStatus.pending,
      ),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      completedAt: data['completedAt'] != null ? (data['completedAt'] as Timestamp).toDate() : null,
      failureReason: data['failureReason'],
      transferDetails: Map<String, dynamic>.from(data['transferDetails'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'orderId': orderId,
      'userId': userId,
      'sourceCurrency': sourceCurrency,
      'targetCurrency': targetCurrency,
      'sourceAmount': sourceAmount,
      'targetAmount': targetAmount,
      'exchangeRate': exchangeRate,
      'transferFee': transferFee,
      'transferMethod': transferMethod,
      'referenceNumber': referenceNumber,
      'status': status.toString(),
      'createdAt': Timestamp.fromDate(createdAt),
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'failureReason': failureReason,
      'transferDetails': transferDetails,
    };
  }

  double get totalAmount => sourceAmount + transferFee;
  String get formattedAmount => '$sourceCurrency ${sourceAmount.toStringAsFixed(2)}';
}

enum PaymentStatus {
  pending,
  processing,
  completed,
  failed,
  cancelled,
  refunded,
}

class PaymentMethod {
  final String id;
  final String userId;
  final String type; // 'card', 'mobile_money', 'paypal', 'bank_transfer', etc.
  final String? provider;
  final String? last4;
  final String? cardBrand;
  final String? accountNumber;
  final String? accountName;
  final bool isDefault;
  final DateTime addedAt;

  PaymentMethod({
    required this.id,
    required this.userId,
    required this.type,
    this.provider,
    this.last4,
    this.cardBrand,
    this.accountNumber,
    this.accountName,
    this.isDefault = false,
    required this.addedAt,
  });

  factory PaymentMethod.fromMap(Map<String, dynamic> data, String docId) {
    try {
      return PaymentMethod(
        id: docId,
        userId: data['userId'] ?? '',
        type: data['type'] ?? '',
        provider: data['provider'],
        last4: data['last4'],
        cardBrand: data['cardBrand'],
        accountNumber: data['accountNumber'],
        accountName: data['accountName'],
        isDefault: data['isDefault'] ?? false,
        addedAt: data['addedAt'] != null 
            ? (data['addedAt'] as Timestamp).toDate()
            : DateTime.now(),
      );
    } catch (e) {
      print('PaymentMethod.fromMap error: $e for data: $data');
      // Return a default payment method if parsing fails
      return PaymentMethod(
        id: docId,
        userId: data['userId'] ?? '',
        type: data['type'] ?? 'unknown',
        provider: data['provider'],
        last4: data['last4'],
        cardBrand: data['cardBrand'],
        accountNumber: data['accountNumber'],
        accountName: data['accountName'],
        isDefault: data['isDefault'] ?? false,
        addedAt: DateTime.now(),
      );
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'type': type,
      'provider': provider,
      'last4': last4,
      'cardBrand': cardBrand,
      'accountNumber': accountNumber,
      'accountName': accountName,
      'isDefault': isDefault,
      'addedAt': Timestamp.fromDate(addedAt),
    };
  }
}

class Wallet {
  final String id;
  final String userId;
  final double balance;
  final String currency;
  final DateTime createdAt;
  final DateTime updatedAt;

  Wallet({
    required this.id,
    required this.userId,
    required this.balance,
    required this.currency,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Wallet.fromMap(Map<String, dynamic> data, String docId) {
    return Wallet(
      id: docId,
      userId: data['userId'] ?? '',
      balance: (data['balance'] as num?)?.toDouble() ?? 0.0,
      currency: data['currency'] ?? 'TZS',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'balance': balance,
      'currency': currency,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}

class PaymentTransaction {
  final String id;
  final String userId;
  final String orderId;
  final String paymentMethodId;
  final double amount;
  final String currency;
  final String status; // 'pending', 'completed', 'failed', 'refunded', etc.
  final String? provider;
  final String? reference;
  final String? description;
  final DateTime createdAt;
  final DateTime? completedAt;
  final DateTime? failedAt;
  final DateTime? refundedAt;

  PaymentTransaction({
    required this.id,
    required this.userId,
    required this.orderId,
    required this.paymentMethodId,
    required this.amount,
    required this.currency,
    required this.status,
    this.provider,
    this.reference,
    this.description,
    required this.createdAt,
    this.completedAt,
    this.failedAt,
    this.refundedAt,
  });

  factory PaymentTransaction.fromMap(Map<String, dynamic> data, String docId) {
    return PaymentTransaction(
      id: docId,
      userId: data['userId'] ?? '',
      orderId: data['orderId'] ?? '',
      paymentMethodId: data['paymentMethodId'] ?? '',
      amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
      currency: data['currency'] ?? 'TZS',
      status: data['status'] ?? 'pending',
      provider: data['provider'],
      reference: data['reference'],
      description: data['description'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      completedAt: data['completedAt'] != null ? (data['completedAt'] as Timestamp).toDate() : null,
      failedAt: data['failedAt'] != null ? (data['failedAt'] as Timestamp).toDate() : null,
      refundedAt: data['refundedAt'] != null ? (data['refundedAt'] as Timestamp).toDate() : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'orderId': orderId,
      'paymentMethodId': paymentMethodId,
      'amount': amount,
      'currency': currency,
      'status': status,
      'provider': provider,
      'reference': reference,
      'description': description,
      'createdAt': Timestamp.fromDate(createdAt),
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'failedAt': failedAt != null ? Timestamp.fromDate(failedAt!) : null,
      'refundedAt': refundedAt != null ? Timestamp.fromDate(refundedAt!) : null,
    };
  }
} 