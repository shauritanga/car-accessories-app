import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/payment_model.dart' as payment_models;
import '../models/order_model.dart';

class PaymentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
      // Step 1: Validate card details (1 second)
      await Future.delayed(const Duration(seconds: 1));

      // Update status to processing
      await _firestore.collection('payments').doc(payment.id).update({
        'status': payment_models.PaymentStatus.processing.toString(),
        'transactionId': 'CARD${DateTime.now().millisecondsSinceEpoch}',
        'processingSteps': [
          {
            'step': 'validation',
            'message': 'Validating card details',
            'timestamp': DateTime.now().toIso8601String(),
          },
        ],
      });

      // Step 2: Process with bank (2 seconds)
      await Future.delayed(const Duration(seconds: 2));

      // Update with bank processing step
      await _firestore.collection('payments').doc(payment.id).update({
        'processingSteps': FieldValue.arrayUnion([
          {
            'step': 'bank_processing',
            'message': 'Processing payment with bank',
            'timestamp': DateTime.now().toIso8601String(),
          },
        ]),
      });

      // Step 3: Complete payment (1 second)
      await Future.delayed(const Duration(seconds: 1));

      // Generate realistic transaction reference
      final transactionRef = 'CARD${DateTime.now().millisecondsSinceEpoch}';

      // Update payment status
      final completedPayment = payment_models.PaymentModel(
        id: payment.id,
        orderId: payment.orderId,
        userId: payment.userId,
        amount: payment.amount,
        method: payment.method,
        status: payment_models.PaymentStatus.completed,
        transactionId: transactionRef,
        createdAt: payment.createdAt,
        completedAt: DateTime.now(),
      );

      await _firestore.collection('payments').doc(payment.id).update({
        ...completedPayment.toMap(),
        'processingSteps': FieldValue.arrayUnion([
          {
            'step': 'completed',
            'message': 'Payment completed successfully',
            'timestamp': DateTime.now().toIso8601String(),
          },
        ]),
      });

      return completedPayment;
    } catch (e) {
      throw Exception('Card payment failed: $e');
    }
  }

  Future<payment_models.PaymentModel> _processMobileMoneyPayment(
    payment_models.PaymentModel payment,
  ) async {
    // Simulate realistic mobile money processing with steps

    // Step 1: Initiate payment request (1 second)
    await Future.delayed(const Duration(seconds: 1));

    // Update status to processing
    await _firestore.collection('payments').doc(payment.id).update({
      'status': payment_models.PaymentStatus.processing.toString(),
      'transactionId': 'MM${DateTime.now().millisecondsSinceEpoch}',
      'processingSteps': [
        {
          'step': 'initiated',
          'message': 'Payment request sent to mobile money provider',
          'timestamp': DateTime.now().toIso8601String(),
        },
      ],
    });

    // Step 2: Simulate user confirmation on phone (2 seconds)
    await Future.delayed(const Duration(seconds: 2));

    // Update with confirmation step
    await _firestore.collection('payments').doc(payment.id).update({
      'processingSteps': FieldValue.arrayUnion([
        {
          'step': 'user_confirmation',
          'message': 'Waiting for user confirmation on mobile device',
          'timestamp': DateTime.now().toIso8601String(),
        },
      ]),
    });

    // Step 3: Process payment (1 second)
    await Future.delayed(const Duration(seconds: 1));

    // Generate realistic transaction reference
    final transactionRef = 'TXN${DateTime.now().millisecondsSinceEpoch}';

    final completedPayment = payment_models.PaymentModel(
      id: payment.id,
      orderId: payment.orderId,
      userId: payment.userId,
      amount: payment.amount,
      method: payment.method,
      status: payment_models.PaymentStatus.completed,
      transactionId: transactionRef,
      createdAt: payment.createdAt,
      completedAt: DateTime.now(),
    );

    await _firestore.collection('payments').doc(payment.id).update({
      ...completedPayment.toMap(),
      'processingSteps': FieldValue.arrayUnion([
        {
          'step': 'completed',
          'message': 'Payment completed successfully',
          'timestamp': DateTime.now().toIso8601String(),
        },
      ]),
    });

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
        .snapshots()
        .map((snapshot) {
          final methods =
              snapshot.docs
                  .map(
                    (doc) => payment_models.PaymentMethodModel.fromMap(
                      doc.data(),
                      doc.id,
                    ),
                  )
                  .toList();

          // Sort by createdAt descending on the client side
          methods.sort((a, b) => b.createdAt.compareTo(a.createdAt));

          return methods;
        });
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
        .snapshots()
        .map((snapshot) {
          final payments =
              snapshot.docs
                  .map(
                    (doc) =>
                        payment_models.PaymentModel.fromMap(doc.data(), doc.id),
                  )
                  .toList();

          // Sort by createdAt descending on the client side
          payments.sort((a, b) => b.createdAt.compareTo(a.createdAt));

          return payments;
        });
  }
}
