import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import '../models/order_modification_model.dart';
import '../services/order_modification_service.dart';

class OrderModificationState {
  final List<OrderModificationModel> requests;
  final bool isLoading;
  final String? error;

  OrderModificationState({
    this.requests = const [],
    this.isLoading = false,
    this.error,
  });

  OrderModificationState copyWith({
    List<OrderModificationModel>? requests,
    bool? isLoading,
    String? error,
  }) {
    return OrderModificationState(
      requests: requests ?? this.requests,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class OrderModificationNotifier extends StateNotifier<OrderModificationState> {
  final OrderModificationService _service = OrderModificationService();

  OrderModificationNotifier() : super(OrderModificationState());

  Future<void> submitCancellationRequest({
    required String orderId,
    required String customerId,
    required String reason,
    String? description,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final requestId = DateTime.now().millisecondsSinceEpoch.toString();
      
      final request = OrderModificationModel(
        id: requestId,
        orderId: orderId,
        customerId: customerId,
        type: ModificationType.cancellation,
        status: ModificationStatus.pending,
        reason: reason,
        description: description,
        requestedAt: DateTime.now(),
      );

      await _service.submitModificationRequest(request);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> submitReturnRequest({
    required String orderId,
    required String customerId,
    required String reason,
    String? description,
    List<String>? items,
    List<File>? evidenceImages,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final requestId = DateTime.now().millisecondsSinceEpoch.toString();
      
      // Upload evidence images if provided
      List<String> imageUrls = [];
      if (evidenceImages != null && evidenceImages.isNotEmpty) {
        imageUrls = await _service.uploadEvidenceImages(evidenceImages, requestId);
      }

      final request = OrderModificationModel(
        id: requestId,
        orderId: orderId,
        customerId: customerId,
        type: ModificationType.return_,
        status: ModificationStatus.pending,
        reason: reason,
        description: description,
        items: items ?? [],
        images: imageUrls,
        requestedAt: DateTime.now(),
      );

      await _service.submitModificationRequest(request);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> submitRefundRequest({
    required String orderId,
    required String customerId,
    required String reason,
    String? description,
    List<String>? items,
    RefundMethod? refundMethod,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final requestId = DateTime.now().millisecondsSinceEpoch.toString();
      
      // Calculate refund amount
      final refundAmount = await _service.calculateRefundAmount(orderId, items ?? []);

      final request = OrderModificationModel(
        id: requestId,
        orderId: orderId,
        customerId: customerId,
        type: ModificationType.refund,
        status: ModificationStatus.pending,
        reason: reason,
        description: description,
        items: items ?? [],
        refundAmount: refundAmount,
        refundMethod: refundMethod ?? RefundMethod.originalPayment,
        requestedAt: DateTime.now(),
      );

      await _service.submitModificationRequest(request);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> cancelModificationRequest(String requestId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _service.cancelModificationRequest(requestId);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<bool> canCancelOrder(String orderId) async {
    try {
      return await _service.canCancelOrder(orderId);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> canReturnOrder(String orderId) async {
    try {
      return await _service.canReturnOrder(orderId);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<double> calculateRefundAmount(String orderId, List<String> itemIds) async {
    try {
      return await _service.calculateRefundAmount(orderId, itemIds);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return 0.0;
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Providers
final orderModificationProvider = StateNotifierProvider<OrderModificationNotifier, OrderModificationState>((ref) {
  return OrderModificationNotifier();
});

// Stream provider for customer modification requests
final customerModificationRequestsStreamProvider = StreamProvider.family<List<OrderModificationModel>, String>((ref, customerId) {
  final service = OrderModificationService();
  return service.getCustomerModificationRequests(customerId);
});

// Stream provider for order modification requests
final orderModificationRequestsStreamProvider = StreamProvider.family<List<OrderModificationModel>, String>((ref, orderId) {
  final service = OrderModificationService();
  return service.getOrderModificationRequests(orderId);
});

// Future provider for modification statistics (admin)
final modificationStatisticsProvider = FutureProvider<Map<String, int>>((ref) {
  final service = OrderModificationService();
  return service.getModificationStatistics();
});
