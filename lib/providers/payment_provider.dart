import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/payment_model.dart';
import '../models/order_model.dart';
import '../services/payment_service.dart';

class PaymentState {
  final List<PaymentMethodModel> paymentMethods;
  final List<PaymentModel> paymentHistory;
  final PaymentMethodModel? selectedPaymentMethod;
  final bool isLoading;
  final String? error;

  PaymentState({
    this.paymentMethods = const [],
    this.paymentHistory = const [],
    this.selectedPaymentMethod,
    this.isLoading = false,
    this.error,
  });

  PaymentState copyWith({
    List<PaymentMethodModel>? paymentMethods,
    List<PaymentModel>? paymentHistory,
    PaymentMethodModel? selectedPaymentMethod,
    bool? isLoading,
    String? error,
  }) {
    return PaymentState(
      paymentMethods: paymentMethods ?? this.paymentMethods,
      paymentHistory: paymentHistory ?? this.paymentHistory,
      selectedPaymentMethod: selectedPaymentMethod ?? this.selectedPaymentMethod,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class PaymentNotifier extends StateNotifier<PaymentState> {
  final PaymentService _paymentService = PaymentService();

  PaymentNotifier() : super(PaymentState()) {
    _initializeStripe();
  }

  Future<void> _initializeStripe() async {
    try {
      await _paymentService.initializeStripe();
    } catch (e) {
      state = state.copyWith(error: 'Failed to initialize payment system: $e');
    }
  }

  Future<PaymentModel> processPayment({
    required OrderModel order,
    required PaymentMethod paymentMethod,
    String? paymentMethodId,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final payment = await _paymentService.processPayment(
        order: order,
        paymentMethod: paymentMethod,
        paymentMethodId: paymentMethodId,
      );
      
      state = state.copyWith(isLoading: false);
      return payment;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> savePaymentMethod(PaymentMethodModel paymentMethod) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      await _paymentService.savePaymentMethod(paymentMethod);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> deletePaymentMethod(String paymentMethodId) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      await _paymentService.deletePaymentMethod(paymentMethodId);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> setDefaultPaymentMethod(String userId, String paymentMethodId) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      await _paymentService.setDefaultPaymentMethod(userId, paymentMethodId);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  void selectPaymentMethod(PaymentMethodModel? paymentMethod) {
    state = state.copyWith(selectedPaymentMethod: paymentMethod);
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Providers
final paymentProvider = StateNotifierProvider<PaymentNotifier, PaymentState>((ref) {
  return PaymentNotifier();
});

final paymentMethodsStreamProvider = StreamProvider.family<List<PaymentMethodModel>, String>((ref, userId) {
  final paymentService = PaymentService();
  return paymentService.getUserPaymentMethods(userId);
});

final paymentHistoryStreamProvider = StreamProvider.family<List<PaymentModel>, String>((ref, userId) {
  final paymentService = PaymentService();
  return paymentService.getPaymentHistory(userId);
});
