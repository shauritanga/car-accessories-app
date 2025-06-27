import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/enhanced_payment_model.dart';

class EnhancedPaymentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Buy Now Pay Later
  Future<BuyNowPayLaterPlan?> createBuyNowPayLaterPlan({
    required String orderId,
    required double orderAmount,
    required BuyNowPayLaterProvider provider,
    required int installmentCount,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Calculate installment details
      final installmentAmount = orderAmount / installmentCount;
      final fees = _calculateBNPLFees(orderAmount, provider);
      final totalAmount = orderAmount + fees;
      final dueDate = DateTime.now().add(Duration(days: 30 * installmentCount));

      // Create installments
      final installments = <InstallmentPayment>[];
      for (int i = 1; i <= installmentCount; i++) {
        final installmentDueDate = DateTime.now().add(Duration(days: 30 * i));
        installments.add(
          InstallmentPayment(
            id: '',
            installmentNumber: i,
            amount: installmentAmount,
            dueDate: installmentDueDate,
            status: InstallmentStatus.pending,
          ),
        );
      }

      final plan = BuyNowPayLaterPlan(
        id: '',
        provider: provider,
        name: '${provider.toString().split('.').last} Payment Plan',
        description: 'Pay in $installmentCount installments',
        installmentCount: installmentCount,
        installmentAmount: installmentAmount,
        totalAmount: totalAmount,
        interestRate: _getBNPLInterestRate(provider),
        fees: fees,
        dueDate: dueDate,
        isInterestFree: _isBNPLInterestFree(provider),
        installments: installments,
        createdAt: DateTime.now(),
      );

      final docRef = await _firestore
          .collection('buy_now_pay_later_plans')
          .add(plan.toMap());

      return BuyNowPayLaterPlan.fromMap(plan.toMap(), docRef.id);
    } catch (e) {
      print('Error creating BNPL plan: $e');
      rethrow;
    }
  }

  Future<List<BuyNowPayLaterPlan>> getUserBNPLPlans() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      final querySnapshot =
          await _firestore
              .collection('buy_now_pay_later_plans')
              .where('userId', isEqualTo: user.uid)
              .get();

      final plans =
          querySnapshot.docs
              .map((doc) => BuyNowPayLaterPlan.fromMap(doc.data(), doc.id))
              .toList();

      // Sort by createdAt descending on the client side
      plans.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return plans;
    } catch (e) {
      print('Error getting BNPL plans: $e');
      return [];
    }
  }

  Future<bool> payInstallment(String planId, int installmentNumber) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final planDoc =
          await _firestore
              .collection('buy_now_pay_later_plans')
              .doc(planId)
              .get();

      if (!planDoc.exists) throw Exception('Plan not found');

      final plan = BuyNowPayLaterPlan.fromMap(planDoc.data()!, planDoc.id);
      final installment = plan.installments.firstWhere(
        (i) => i.installmentNumber == installmentNumber,
        orElse: () => throw Exception('Installment not found'),
      );

      if (installment.status != InstallmentStatus.pending) {
        throw Exception('Installment already paid');
      }

      // Process payment (simplified)
      final updatedInstallment = InstallmentPayment(
        id: installment.id,
        installmentNumber: installment.installmentNumber,
        amount: installment.amount,
        dueDate: installment.dueDate,
        status: InstallmentStatus.paid,
        paidAt: DateTime.now(),
        transactionId: 'txn_${DateTime.now().millisecondsSinceEpoch}',
      );

      // Update installment in plan
      final updatedInstallments =
          plan.installments.map((i) {
            if (i.installmentNumber == installmentNumber) {
              return updatedInstallment;
            }
            return i;
          }).toList();

      await _firestore
          .collection('buy_now_pay_later_plans')
          .doc(planId)
          .update({
            'installments': updatedInstallments.map((i) => i.toMap()).toList(),
            'usageCount': FieldValue.increment(1),
          });

      return true;
    } catch (e) {
      print('Error paying installment: $e');
      return false;
    }
  }

  // Subscription Management
  Future<List<SubscriptionPlan>> getAvailableSubscriptionPlans() async {
    try {
      final querySnapshot =
          await _firestore
              .collection('subscription_plans')
              .where('isActive', isEqualTo: true)
              .get();

      return querySnapshot.docs
          .map((doc) => SubscriptionPlan.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Error getting subscription plans: $e');
      return [];
    }
  }

  Future<UserSubscription> subscribeToPlan(String planId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Get plan details
      final planDoc =
          await _firestore.collection('subscription_plans').doc(planId).get();

      if (!planDoc.exists) throw Exception('Plan not found');

      final plan = SubscriptionPlan.fromMap(planDoc.data()!, planId);

      // Calculate billing dates
      final startDate = DateTime.now();
      final nextBillingDate = _calculateNextBillingDate(
        startDate,
        plan.billingInterval,
      );

      final subscription = UserSubscription(
        id: '',
        userId: user.uid,
        planId: planId,
        status: SubscriptionStatus.active,
        startDate: startDate,
        nextBillingDate: nextBillingDate,
        currentAmount: plan.price,
        billingCycleCount: 0,
        autoRenew: true,
        payments: [],
        createdAt: DateTime.now(),
      );

      final docRef = await _firestore
          .collection('user_subscriptions')
          .add(subscription.toMap());

      return UserSubscription.fromMap(subscription.toMap(), docRef.id);
    } catch (e) {
      print('Error subscribing to plan: $e');
      rethrow;
    }
  }

  Future<List<UserSubscription>> getUserSubscriptions() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      final querySnapshot =
          await _firestore
              .collection('user_subscriptions')
              .where('userId', isEqualTo: user.uid)
              .get();

      final subscriptions =
          querySnapshot.docs
              .map((doc) => UserSubscription.fromMap(doc.data(), doc.id))
              .toList();

      // Sort by createdAt descending on the client side
      subscriptions.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return subscriptions;
    } catch (e) {
      print('Error getting user subscriptions: $e');
      return [];
    }
  }

  Future<void> cancelSubscription(String subscriptionId, String reason) async {
    try {
      await _firestore
          .collection('user_subscriptions')
          .doc(subscriptionId)
          .update({
            'status': SubscriptionStatus.cancelled.toString(),
            'cancellationReason': reason,
            'cancelledAt': Timestamp.now(),
            'autoRenew': false,
          });
    } catch (e) {
      print('Error cancelling subscription: $e');
      rethrow;
    }
  }

  Future<void> pauseSubscription(String subscriptionId) async {
    try {
      await _firestore
          .collection('user_subscriptions')
          .doc(subscriptionId)
          .update({
            'status': SubscriptionStatus.paused.toString(),
            'updatedAt': Timestamp.now(),
          });
    } catch (e) {
      print('Error pausing subscription: $e');
      rethrow;
    }
  }

  // Cryptocurrency Payments
  Future<CryptocurrencyPayment> createCryptocurrencyPayment({
    required String orderId,
    required CryptocurrencyType cryptocurrency,
    required double amountInFiat,
    required String walletAddress,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Get current exchange rate
      final exchangeRate = await _getCryptocurrencyExchangeRate(cryptocurrency);
      final amountInCrypto = amountInFiat / exchangeRate;

      final payment = CryptocurrencyPayment(
        id: '',
        orderId: orderId,
        userId: user.uid,
        cryptocurrency: cryptocurrency,
        amountInCrypto: amountInCrypto,
        amountInFiat: amountInFiat,
        walletAddress: walletAddress,
        status: PaymentStatus.pending,
        createdAt: DateTime.now(),
        exchangeRate: exchangeRate,
      );

      final docRef = await _firestore
          .collection('cryptocurrency_payments')
          .add(payment.toMap());

      return CryptocurrencyPayment.fromMap(payment.toMap(), docRef.id);
    } catch (e) {
      print('Error creating cryptocurrency payment: $e');
      rethrow;
    }
  }

  Future<List<CryptocurrencyPayment>> getUserCryptocurrencyPayments() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      final querySnapshot =
          await _firestore
              .collection('cryptocurrency_payments')
              .where('userId', isEqualTo: user.uid)
              .get();

      final payments =
          querySnapshot.docs
              .map((doc) => CryptocurrencyPayment.fromMap(doc.data(), doc.id))
              .toList();

      // Sort by createdAt descending on the client side
      payments.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return payments;
    } catch (e) {
      print('Error getting cryptocurrency payments: $e');
      return [];
    }
  }

  Future<void> updateCryptocurrencyPaymentStatus(
    String paymentId,
    PaymentStatus status, {
    String? transactionHash,
    int? confirmations,
  }) async {
    try {
      final updates = <String, dynamic>{'status': status.toString()};

      if (transactionHash != null) {
        updates['transactionHash'] = transactionHash;
      }

      if (confirmations != null) {
        updates['confirmations'] = confirmations;
      }

      if (status == PaymentStatus.completed) {
        updates['confirmedAt'] = Timestamp.now();
      }

      await _firestore
          .collection('cryptocurrency_payments')
          .doc(paymentId)
          .update(updates);
    } catch (e) {
      print('Error updating cryptocurrency payment status: $e');
      rethrow;
    }
  }

  // International Payments
  Future<InternationalPayment> createInternationalPayment({
    required String orderId,
    required String sourceCurrency,
    required String targetCurrency,
    required double sourceAmount,
    required String transferMethod,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Get exchange rate
      final exchangeRate = await _getExchangeRate(
        sourceCurrency,
        targetCurrency,
      );
      final targetAmount = sourceAmount * exchangeRate;
      final transferFee = _calculateTransferFee(sourceAmount, transferMethod);

      final payment = InternationalPayment(
        id: '',
        orderId: orderId,
        userId: user.uid,
        sourceCurrency: sourceCurrency,
        targetCurrency: targetCurrency,
        sourceAmount: sourceAmount,
        targetAmount: targetAmount,
        exchangeRate: exchangeRate,
        transferFee: transferFee,
        transferMethod: transferMethod,
        referenceNumber: _generateReferenceNumber(),
        status: PaymentStatus.pending,
        createdAt: DateTime.now(),
      );

      final docRef = await _firestore
          .collection('international_payments')
          .add(payment.toMap());

      return InternationalPayment.fromMap(payment.toMap(), docRef.id);
    } catch (e) {
      print('Error creating international payment: $e');
      rethrow;
    }
  }

  Future<List<InternationalPayment>> getUserInternationalPayments() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      final querySnapshot =
          await _firestore
              .collection('international_payments')
              .where('userId', isEqualTo: user.uid)
              .get();

      final payments =
          querySnapshot.docs
              .map((doc) => InternationalPayment.fromMap(doc.data(), doc.id))
              .toList();

      // Sort by createdAt descending on the client side
      payments.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return payments;
    } catch (e) {
      print('Error getting international payments: $e');
      return [];
    }
  }

  // Helper methods
  double _calculateBNPLFees(double amount, BuyNowPayLaterProvider provider) {
    switch (provider) {
      case BuyNowPayLaterProvider.klarna:
        return amount * 0.05; // 5% fee
      case BuyNowPayLaterProvider.afterpay:
        return amount * 0.04; // 4% fee
      case BuyNowPayLaterProvider.affirm:
        return amount * 0.06; // 6% fee
      case BuyNowPayLaterProvider.paypalCredit:
        return amount * 0.03; // 3% fee
      case BuyNowPayLaterProvider.custom:
        return amount * 0.05; // 5% fee
    }
  }

  double _getBNPLInterestRate(BuyNowPayLaterProvider provider) {
    switch (provider) {
      case BuyNowPayLaterProvider.klarna:
        return 0.0; // Interest-free
      case BuyNowPayLaterProvider.afterpay:
        return 0.0; // Interest-free
      case BuyNowPayLaterProvider.affirm:
        return 0.15; // 15% APR
      case BuyNowPayLaterProvider.paypalCredit:
        return 0.0; // Interest-free
      case BuyNowPayLaterProvider.custom:
        return 0.10; // 10% APR
    }
  }

  bool _isBNPLInterestFree(BuyNowPayLaterProvider provider) {
    return _getBNPLInterestRate(provider) == 0.0;
  }

  DateTime _calculateNextBillingDate(DateTime startDate, int billingInterval) {
    return DateTime(
      startDate.year,
      startDate.month + billingInterval,
      startDate.day,
    );
  }

  Future<double> _getCryptocurrencyExchangeRate(
    CryptocurrencyType cryptocurrency,
  ) async {
    // In a real app, this would fetch from a crypto exchange API
    switch (cryptocurrency) {
      case CryptocurrencyType.bitcoin:
        return 45000.0; // USD per BTC
      case CryptocurrencyType.ethereum:
        return 3000.0; // USD per ETH
      case CryptocurrencyType.litecoin:
        return 150.0; // USD per LTC
      case CryptocurrencyType.bitcoinCash:
        return 300.0; // USD per BCH
      case CryptocurrencyType.ripple:
        return 0.8; // USD per XRP
      case CryptocurrencyType.cardano:
        return 1.2; // USD per ADA
      case CryptocurrencyType.polkadot:
        return 25.0; // USD per DOT
      case CryptocurrencyType.dogecoin:
        return 0.15; // USD per DOGE
    }
  }

  Future<double> _getExchangeRate(
    String sourceCurrency,
    String targetCurrency,
  ) async {
    // In a real app, this would fetch from a forex API
    if (sourceCurrency == 'USD' && targetCurrency == 'TZS') {
      return 2500.0; // 1 USD = 2500 TZS
    } else if (sourceCurrency == 'EUR' && targetCurrency == 'TZS') {
      return 2700.0; // 1 EUR = 2700 TZS
    } else if (sourceCurrency == 'GBP' && targetCurrency == 'TZS') {
      return 3200.0; // 1 GBP = 3200 TZS
    }
    return 1.0; // Default 1:1 rate
  }

  double _calculateTransferFee(double amount, String transferMethod) {
    switch (transferMethod.toLowerCase()) {
      case 'bank_transfer':
        return amount * 0.02; // 2% fee
      case 'wire_transfer':
        return amount * 0.03; // 3% fee
      case 'paypal':
        return amount * 0.025; // 2.5% fee
      case 'western_union':
        return amount * 0.04; // 4% fee
      default:
        return amount * 0.025; // 2.5% default fee
    }
  }

  String _generateReferenceNumber() {
    return 'INT_${DateTime.now().millisecondsSinceEpoch}';
  }

  // Payment validation methods
  bool isValidCryptocurrencyAddress(
    String address,
    CryptocurrencyType cryptocurrency,
  ) {
    // Simplified validation - in real app, use proper validation libraries
    switch (cryptocurrency) {
      case CryptocurrencyType.bitcoin:
        return address.startsWith('1') ||
            address.startsWith('3') ||
            address.startsWith('bc1');
      case CryptocurrencyType.ethereum:
        return address.startsWith('0x') && address.length == 42;
      default:
        return address.isNotEmpty;
    }
  }

  bool isValidInternationalTransferMethod(String method) {
    final validMethods = [
      'bank_transfer',
      'wire_transfer',
      'paypal',
      'western_union',
      'moneygram',
    ];
    return validMethods.contains(method.toLowerCase());
  }

  // Get payment methods available for user
  List<PaymentMethodType> getAvailablePaymentMethods() {
    return [
      PaymentMethodType.creditCard,
      PaymentMethodType.debitCard,
      PaymentMethodType.mobileMoney,
      PaymentMethodType.bankTransfer,
      PaymentMethodType.cashOnDelivery,
      PaymentMethodType.buyNowPayLater,
      PaymentMethodType.cryptocurrency,
      PaymentMethodType.internationalTransfer,
    ];
  }

  // Payment Methods
  Future<void> addPaymentMethod(PaymentMethod method) async {
    await _firestore
        .collection('payment_methods')
        .doc(method.id)
        .set(method.toMap());
  }

  Future<void> removePaymentMethod(String methodId) async {
    await _firestore.collection('payment_methods').doc(methodId).delete();
  }

  Future<List<PaymentMethod>> getUserPaymentMethods(String userId) async {
    print(
      'EnhancedPaymentService: getUserPaymentMethods called for user: $userId',
    );
    try {
      final snapshot = await _firestore
          .collection('payment_methods')
          .where('userId', isEqualTo: userId)
          .get()
          .timeout(const Duration(seconds: 10));

      print(
        'EnhancedPaymentService: Firestore query completed, found ${snapshot.docs.length} documents',
      );

      final methods =
          snapshot.docs
              .map((doc) => PaymentMethod.fromMap(doc.data(), doc.id))
              .toList();

      print('EnhancedPaymentService: Parsed ${methods.length} payment methods');
      return methods;
    } catch (e) {
      print(
        'EnhancedPaymentService: Error getting payment methods for user $userId: $e',
      );
      rethrow;
    }
  }

  // Wallets
  Future<void> createWallet(Wallet wallet) async {
    await _firestore.collection('wallets').doc(wallet.id).set(wallet.toMap());
  }

  Future<Wallet?> getWallet(String userId) async {
    final snapshot =
        await _firestore
            .collection('wallets')
            .where('userId', isEqualTo: userId)
            .limit(1)
            .get();
    if (snapshot.docs.isEmpty) return null;
    final doc = snapshot.docs.first;
    return Wallet.fromMap(doc.data(), doc.id);
  }

  Future<void> updateWalletBalance(String walletId, double newBalance) async {
    await _firestore.collection('wallets').doc(walletId).update({
      'balance': newBalance,
      'updatedAt': Timestamp.now(),
    });
  }

  // Payment Transactions
  Future<void> createTransaction(PaymentTransaction transaction) async {
    await _firestore
        .collection('payment_transactions')
        .doc(transaction.id)
        .set(transaction.toMap());
  }

  Future<List<PaymentTransaction>> getUserTransactions(String userId) async {
    final snapshot =
        await _firestore
            .collection('payment_transactions')
            .where('userId', isEqualTo: userId)
            .get();

    final transactions =
        snapshot.docs
            .map((doc) => PaymentTransaction.fromMap(doc.data(), doc.id))
            .toList();

    // Sort by createdAt descending on the client side
    transactions.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return transactions;
  }

  Future<List<PaymentTransaction>> getOrderTransactions(String orderId) async {
    final snapshot =
        await _firestore
            .collection('payment_transactions')
            .where('orderId', isEqualTo: orderId)
            .get();
    return snapshot.docs
        .map((doc) => PaymentTransaction.fromMap(doc.data(), doc.id))
        .toList();
  }
}
