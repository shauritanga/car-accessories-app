import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_stripe/flutter_stripe.dart' as stripe;
import 'package:dio/dio.dart';
import '../models/payment_model.dart' as payment_models;
import '../models/order_model.dart';

class PaymentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Dio _dio = Dio();

  // In production, these should be environment variables
  static const String _stripePublishableKey =
      'pk_test_your_publishable_key_here';
  static const String _stripeSecretKey = 'sk_test_your_secret_key_here';

  Future<void> initializeStripe() async {
    stripe.Stripe.publishableKey = _stripePublishableKey;
    await stripe.Stripe.instance.applySettings();
  }

  // Create payment intent on your backend
  Future<Map<String, dynamic>> createPaymentIntent({
    required double amount,
    required String currency,
    required String customerId,
  }) async {
    try {
      // In production, this should call your backend API
      // For demo purposes, we'll simulate the response
      final response = await _dio.post(
        'https://api.stripe.com/v1/payment_intents',
        data: {
          'amount': (amount * 100).round(), // Stripe uses cents
          'currency': currency.toLowerCase(),
          'customer': customerId,
          'automatic_payment_methods[enabled]': true,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $_stripeSecretKey',
            'Content-Type': 'application/x-www-form-urlencoded',
          },
        ),
      );

      return response.data;
    } catch (e) {
      throw Exception('Failed to create payment intent: $e');
    }
  }

  Future<payment_models.PaymentModel> processPayment({
    required OrderModel order,
    required payment_models.PaymentMethod paymentMethod,
    String? paymentMethodId,
  }) async {
    final paymentId = _firestore.collection('payments').doc().id;

    final payment = payment_models.PaymentModel(
      id: paymentId,
      orderId: order.id,
      userId: order.customerId,
      amount: order.total,
      method: paymentMethod,
      status: payment_models.PaymentStatus.processing,
      createdAt: DateTime.now(),
    );

    try {
      // Save payment record
      await _firestore
          .collection('payments')
          .doc(paymentId)
          .set(payment.toMap());

      // Process based on payment method
      switch (paymentMethod) {
        case payment_models.PaymentMethod.creditCard:
        case payment_models.PaymentMethod.debitCard:
          return await _processCardPayment(payment, paymentMethodId);
        case payment_models.PaymentMethod.mobileMoney:
          return await _processMobileMoneyPayment(payment);
        case payment_models.PaymentMethod.bankTransfer:
          return await _processBankTransferPayment(payment);
        case payment_models.PaymentMethod.cashOnDelivery:
          return await _processCashOnDeliveryPayment(payment);
      }
    } catch (e) {
      // Update payment status to failed
      final failedPayment = payment_models.PaymentModel(
        id: payment.id,
        orderId: payment.orderId,
        userId: payment.userId,
        amount: payment.amount,
        method: payment.method,
        status: payment_models.PaymentStatus.failed,
        failureReason: e.toString(),
        createdAt: payment.createdAt,
      );

      await _firestore
          .collection('payments')
          .doc(paymentId)
          .update(failedPayment.toMap());
      rethrow;
    }
  }

  Future<payment_models.PaymentModel> _processCardPayment(
    payment_models.PaymentModel payment,
    String? paymentMethodId,
  ) async {
    try {
      // Create payment intent (simulated for demo)
      await createPaymentIntent(
        amount: payment.amount,
        currency: 'TZS',
        customerId: payment.userId,
      );

      // Simulate card payment processing
      await Future.delayed(const Duration(seconds: 2));

      // In a real implementation, you would integrate with Stripe here
      // For now, we'll simulate a successful payment

      // Update payment status
      final completedPayment = payment_models.PaymentModel(
        id: payment.id,
        orderId: payment.orderId,
        userId: payment.userId,
        amount: payment.amount,
        method: payment.method,
        status: payment_models.PaymentStatus.completed,
        createdAt: payment.createdAt,
      );

      await _firestore
          .collection('payments')
          .doc(payment.id)
          .update(completedPayment.toMap());
      return completedPayment;
    } catch (e) {
      throw Exception('Card payment failed: $e');
    }
  }

  Future<payment_models.PaymentModel> _processMobileMoneyPayment(
    payment_models.PaymentModel payment,
  ) async {
    // Simulate mobile money processing
    await Future.delayed(const Duration(seconds: 2));

    final completedPayment = payment_models.PaymentModel(
      id: payment.id,
      orderId: payment.orderId,
      userId: payment.userId,
      amount: payment.amount,
      method: payment.method,
      status: payment_models.PaymentStatus.completed,
      createdAt: payment.createdAt,
    );

    await _firestore
        .collection('payments')
        .doc(payment.id)
        .update(completedPayment.toMap());
    return completedPayment;
  }

  Future<payment_models.PaymentModel> _processBankTransferPayment(
    payment_models.PaymentModel payment,
  ) async {
    // Bank transfer requires manual verification
    final pendingPayment = payment_models.PaymentModel(
      id: payment.id,
      orderId: payment.orderId,
      userId: payment.userId,
      amount: payment.amount,
      method: payment.method,
      status: payment_models.PaymentStatus.pending,
      createdAt: payment.createdAt,
    );

    await _firestore
        .collection('payments')
        .doc(payment.id)
        .update(pendingPayment.toMap());
    return pendingPayment;
  }

  Future<payment_models.PaymentModel> _processCashOnDeliveryPayment(
    payment_models.PaymentModel payment,
  ) async {
    final pendingPayment = payment_models.PaymentModel(
      id: payment.id,
      orderId: payment.orderId,
      userId: payment.userId,
      amount: payment.amount,
      method: payment.method,
      status: payment_models.PaymentStatus.pending,
      createdAt: payment.createdAt,
    );

    await _firestore
        .collection('payments')
        .doc(payment.id)
        .update(pendingPayment.toMap());
    return pendingPayment;
  }

  // Payment method management
  Future<void> savePaymentMethod(
    payment_models.PaymentMethodModel paymentMethod,
  ) async {
    await _firestore
        .collection('payment_methods')
        .doc(paymentMethod.id)
        .set(paymentMethod.toMap());
  }

  Stream<List<payment_models.PaymentMethodModel>> getUserPaymentMethods(
    String userId,
  ) {
    return _firestore
        .collection('payment_methods')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map(
                    (doc) => payment_models.PaymentMethodModel.fromMap(
                      doc.data(),
                      doc.id,
                    ),
                  )
                  .toList(),
        );
  }

  Future<void> deletePaymentMethod(String paymentMethodId) async {
    await _firestore
        .collection('payment_methods')
        .doc(paymentMethodId)
        .delete();
  }

  Future<void> setDefaultPaymentMethod(
    String userId,
    String paymentMethodId,
  ) async {
    final batch = _firestore.batch();

    // Remove default from all user's payment methods
    final userMethods =
        await _firestore
            .collection('payment_methods')
            .where('userId', isEqualTo: userId)
            .get();

    for (final doc in userMethods.docs) {
      batch.update(doc.reference, {'isDefault': false});
    }

    // Set new default
    batch.update(
      _firestore.collection('payment_methods').doc(paymentMethodId),
      {'isDefault': true},
    );

    await batch.commit();
  }

  Stream<List<payment_models.PaymentModel>> getPaymentHistory(String userId) {
    return _firestore
        .collection('payments')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map(
                    (doc) =>
                        payment_models.PaymentModel.fromMap(doc.data(), doc.id),
                  )
                  .toList(),
        );
  }
}
