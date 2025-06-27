import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/enhanced_payment_model.dart';
import '../services/enhanced_payment_service.dart';

class EnhancedPaymentState {
  final List<PaymentMethod> paymentMethods;
  final Wallet? wallet;
  final List<PaymentTransaction> transactions;
  final bool isLoading;
  final String? error;

  EnhancedPaymentState({
    this.paymentMethods = const [],
    this.wallet,
    this.transactions = const [],
    this.isLoading = false,
    this.error,
  });

  EnhancedPaymentState copyWith({
    List<PaymentMethod>? paymentMethods,
    Wallet? wallet,
    List<PaymentTransaction>? transactions,
    bool? isLoading,
    String? error,
  }) {
    return EnhancedPaymentState(
      paymentMethods: paymentMethods ?? this.paymentMethods,
      wallet: wallet ?? this.wallet,
      transactions: transactions ?? this.transactions,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class EnhancedPaymentNotifier extends StateNotifier<EnhancedPaymentState> {
  final EnhancedPaymentService _paymentService = EnhancedPaymentService();

  EnhancedPaymentNotifier() : super(EnhancedPaymentState());

  // Payment Methods operations
  Future<void> loadPaymentMethods(String userId) async {
    print(
      'EnhancedPaymentNotifier: loadPaymentMethods called for user: $userId',
    );
    print(
      'EnhancedPaymentNotifier: Current state - isLoading: ${state.isLoading}, paymentMethods: ${state.paymentMethods.length}',
    );

    state = state.copyWith(isLoading: true, error: null);
    print('EnhancedPaymentNotifier: Set isLoading to true');

    try {
      final paymentMethods = await _paymentService.getUserPaymentMethods(
        userId,
      );
      print(
        'EnhancedPaymentNotifier: Got ${paymentMethods.length} payment methods from service',
      );
      state = state.copyWith(paymentMethods: paymentMethods, isLoading: false);
      print(
        'EnhancedPaymentNotifier: Updated state - isLoading: ${state.isLoading}, paymentMethods: ${state.paymentMethods.length}',
      );
    } catch (e) {
      print('EnhancedPaymentNotifier: Error loading payment methods: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load payment methods: $e',
      );
      print(
        'EnhancedPaymentNotifier: Set error state - isLoading: ${state.isLoading}, error: ${state.error}',
      );
    }
  }

  Future<void> addPaymentMethod(PaymentMethod method) async {
    try {
      await _paymentService.addPaymentMethod(method);
      final updatedMethods = [...state.paymentMethods, method];
      state = state.copyWith(paymentMethods: updatedMethods);
    } catch (e) {
      state = state.copyWith(error: 'Failed to add payment method: $e');
    }
  }

  Future<void> removePaymentMethod(String methodId) async {
    try {
      await _paymentService.removePaymentMethod(methodId);
      final updatedMethods =
          state.paymentMethods
              .where((method) => method.id != methodId)
              .toList();
      state = state.copyWith(paymentMethods: updatedMethods);
    } catch (e) {
      state = state.copyWith(error: 'Failed to remove payment method: $e');
    }
  }

  PaymentMethod? getDefaultPaymentMethod() {
    if (state.paymentMethods.isEmpty) return null;

    return state.paymentMethods.firstWhere(
      (method) => method.isDefault,
      orElse: () => state.paymentMethods.first,
    );
  }

  // Wallet operations
  Future<void> loadWallet(String userId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final wallet = await _paymentService.getWallet(userId);
      state = state.copyWith(wallet: wallet, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load wallet: $e',
      );
    }
  }

  Future<void> createWallet(String userId, {String currency = 'TZS'}) async {
    try {
      final wallet = Wallet(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: userId,
        balance: 0.0,
        currency: currency,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await _paymentService.createWallet(wallet);
      state = state.copyWith(wallet: wallet);
    } catch (e) {
      state = state.copyWith(error: 'Failed to create wallet: $e');
    }
  }

  Future<void> updateWalletBalance(double newBalance) async {
    if (state.wallet == null) return;

    try {
      await _paymentService.updateWalletBalance(state.wallet!.id, newBalance);
      final updatedWallet = Wallet(
        id: state.wallet!.id,
        userId: state.wallet!.userId,
        balance: newBalance,
        currency: state.wallet!.currency,
        createdAt: state.wallet!.createdAt,
        updatedAt: DateTime.now(),
      );
      state = state.copyWith(wallet: updatedWallet);
    } catch (e) {
      state = state.copyWith(error: 'Failed to update wallet balance: $e');
    }
  }

  // Transaction operations
  Future<void> loadTransactions(String userId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final transactions = await _paymentService.getUserTransactions(userId);
      state = state.copyWith(transactions: transactions, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load transactions: $e',
      );
    }
  }

  Future<void> createTransaction(PaymentTransaction transaction) async {
    try {
      await _paymentService.createTransaction(transaction);
      final updatedTransactions = [transaction, ...state.transactions];
      state = state.copyWith(transactions: updatedTransactions);
    } catch (e) {
      state = state.copyWith(error: 'Failed to create transaction: $e');
    }
  }

  Future<void> loadOrderTransactions(String orderId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final transactions = await _paymentService.getOrderTransactions(orderId);
      state = state.copyWith(transactions: transactions, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load order transactions: $e',
      );
    }
  }

  List<PaymentTransaction> getTransactionsByStatus(String status) {
    return state.transactions
        .where((transaction) => transaction.status == status)
        .toList();
  }

  double getTotalSpent() {
    return state.transactions
        .where((transaction) => transaction.status == 'completed')
        .fold(0.0, (sum, transaction) => sum + transaction.amount);
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Provider
final enhancedPaymentProvider =
    StateNotifierProvider<EnhancedPaymentNotifier, EnhancedPaymentState>((ref) {
      return EnhancedPaymentNotifier();
    });
