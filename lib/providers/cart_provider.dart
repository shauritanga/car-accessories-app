// import 'package:flutter/material.dart';

// class CartProvider with ChangeNotifier {
//   List<Map<String, dynamic>> _items = [];

//   List<Map<String, dynamic>> get items => _items;

//   void addItem(Map<String, dynamic> product, int quantity) {
//     final existingIndex = _items.indexWhere(
//       (item) => item['productId'] == product['id'],
//     );
//     if (existingIndex >= 0) {
//       _items[existingIndex]['quantity'] += quantity;
//     } else {
//       _items.add({
//         'productId': product['id'],
//         'name': product['name'],
//         'price': product['price'],
//         'quantity': quantity,
//         'sellerId': product['sellerId'],
//       });
//     }
//     notifyListeners();
//   }

//   void removeItem(String productId) {
//     _items.removeWhere((item) => item['productId'] == productId);
//     notifyListeners();
//   }

//   double get total =>
//       _items.fold(0, (sum, item) => sum + item['price'] * item['quantity']);

//   void clearCart() {
//     _items = [];
//     notifyListeners();
//   }
// }
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/cart_item_model.dart';
import '../models/product_model.dart';

class CartState {
  final List<CartItemModel> items;
  final List<CartItemModel> savedForLater;
  final double subtotal;
  final double originalSubtotal; // Before item discounts
  final double itemDiscounts; // Total item-level discounts
  final double deliveryFee;
  final double tax;
  final double couponDiscount;
  final double total;
  final String? appliedCouponCode;
  final String? selectedShippingMethodId;
  final bool isGuestCheckout;
  final Map<String, dynamic>? guestInfo;

  CartState({
    this.items = const [],
    this.savedForLater = const [],
    this.subtotal = 0.0,
    this.originalSubtotal = 0.0,
    this.itemDiscounts = 0.0,
    this.deliveryFee = 5000.0, // TZS 5,000 default
    this.tax = 0.0,
    this.couponDiscount = 0.0,
    this.total = 0.0,
    this.appliedCouponCode,
    this.selectedShippingMethodId,
    this.isGuestCheckout = false,
    this.guestInfo,
  });

  CartState copyWith({
    List<CartItemModel>? items,
    List<CartItemModel>? savedForLater,
    double? subtotal,
    double? originalSubtotal,
    double? itemDiscounts,
    double? deliveryFee,
    double? tax,
    double? couponDiscount,
    double? total,
    String? appliedCouponCode,
    String? selectedShippingMethodId,
    bool? isGuestCheckout,
    Map<String, dynamic>? guestInfo,
  }) {
    return CartState(
      items: items ?? this.items,
      savedForLater: savedForLater ?? this.savedForLater,
      subtotal: subtotal ?? this.subtotal,
      originalSubtotal: originalSubtotal ?? this.originalSubtotal,
      itemDiscounts: itemDiscounts ?? this.itemDiscounts,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      tax: tax ?? this.tax,
      couponDiscount: couponDiscount ?? this.couponDiscount,
      total: total ?? this.total,
      appliedCouponCode: appliedCouponCode ?? this.appliedCouponCode,
      selectedShippingMethodId:
          selectedShippingMethodId ?? this.selectedShippingMethodId,
      isGuestCheckout: isGuestCheckout ?? this.isGuestCheckout,
      guestInfo: guestInfo ?? this.guestInfo,
    );
  }

  // Helper getters
  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);
  int get savedItemCount => savedForLater.length;
  bool get isEmpty => items.isEmpty;
  bool get isNotEmpty => items.isNotEmpty;
  bool get hasSavedItems => savedForLater.isNotEmpty;
  bool get hasDiscount => couponDiscount > 0 || itemDiscounts > 0;
  double get totalSavings => itemDiscounts + couponDiscount;
  double get grandTotal => subtotal + deliveryFee + tax - couponDiscount;

  String get formattedSubtotal => 'TZS ${subtotal.toStringAsFixed(0)}';
  String get formattedDeliveryFee => 'TZS ${deliveryFee.toStringAsFixed(0)}';
  String get formattedTax => 'TZS ${tax.toStringAsFixed(0)}';
  String get formattedCouponDiscount =>
      'TZS ${couponDiscount.toStringAsFixed(0)}';
  String get formattedTotal => 'TZS ${total.toStringAsFixed(0)}';
  String get formattedTotalSavings => 'TZS ${totalSavings.toStringAsFixed(0)}';
}

class CartNotifier extends StateNotifier<CartState> {
  CartNotifier() : super(CartState()) {
    _calculateTotals();
  }

  void addItem(CartItemModel item) {
    final List<CartItemModel> updatedItems = List.from(state.items);
    final index = updatedItems.indexWhere((i) => i.id == item.id);
    if (index >= 0) {
      updatedItems[index] = CartItemModel(
        id: updatedItems[index].id,
        name: updatedItems[index].name,

        price: updatedItems[index].price,
        quantity: updatedItems[index].quantity + item.quantity,
        image: updatedItems[index].image,
        sellerId: updatedItems[index].sellerId,
        variant: updatedItems[index].variant,
      );
    } else {
      updatedItems.add(item);
    }
    state = state.copyWith(items: updatedItems);
    _calculateTotals();
  }

  void addProduct(ProductModel product, int quantity) {
    final cartItem = CartItemModel(
      id: product.id,
      name: product.name,
      price: product.price,
      quantity: quantity,
      sellerId: product.sellerId,
      image: product.images.isNotEmpty ? product.images[0] : null,
      variant: 'N/A', // Add variant logic if needed
    );
    addItem(cartItem);
  }

  void updateQuantity(String itemId, int quantity) {
    if (quantity <= 0) return;
    final List<CartItemModel> updatedItems = List<CartItemModel>.from(
      state.items,
    );
    final index = updatedItems.indexWhere((i) => i.id == itemId);
    if (index >= 0) {
      updatedItems[index] = CartItemModel(
        id: updatedItems[index].id,
        name: updatedItems[index].name,
        price: updatedItems[index].price,
        quantity: quantity,
        sellerId: updatedItems[index].sellerId,
        image: updatedItems[index].image,
        variant: updatedItems[index].variant,
      );
      state = state.copyWith(items: updatedItems);
      _calculateTotals();
    }
  }

  void removeItem(String itemId) {
    final updatedItems = state.items.where((i) => i.id != itemId).toList();
    state = state.copyWith(items: updatedItems);
    _calculateTotals();
  }

  void clearCart() {
    state = CartState();
  }

  // Save for later functionality
  void saveForLater(String itemId) {
    final item = state.items.firstWhere((i) => i.id == itemId);
    final updatedItems = state.items.where((i) => i.id != itemId).toList();
    final updatedSavedItems = [
      ...state.savedForLater,
      item.copyWith(isSavedForLater: true),
    ];

    state = state.copyWith(
      items: updatedItems,
      savedForLater: updatedSavedItems,
    );
    _calculateTotals();
  }

  void moveToCart(String itemId) {
    final item = state.savedForLater.firstWhere((i) => i.id == itemId);
    final updatedSavedItems =
        state.savedForLater.where((i) => i.id != itemId).toList();
    final updatedItems = [
      ...state.items,
      item.copyWith(isSavedForLater: false),
    ];

    state = state.copyWith(
      items: updatedItems,
      savedForLater: updatedSavedItems,
    );
    _calculateTotals();
  }

  void removeSavedItem(String itemId) {
    final updatedSavedItems =
        state.savedForLater.where((i) => i.id != itemId).toList();
    state = state.copyWith(savedForLater: updatedSavedItems);
  }

  // Coupon functionality
  void applyCoupon(String couponCode, double discountAmount) {
    state = state.copyWith(
      appliedCouponCode: couponCode,
      couponDiscount: discountAmount,
    );
    _calculateTotals();
  }

  void removeCoupon() {
    state = state.copyWith(appliedCouponCode: null, couponDiscount: 0.0);
    _calculateTotals();
  }

  // Shipping method selection
  void selectShippingMethod(String shippingMethodId, double shippingCost) {
    state = state.copyWith(
      selectedShippingMethodId: shippingMethodId,
      deliveryFee: shippingCost,
    );
    _calculateTotals();
  }

  // Guest checkout
  void enableGuestCheckout(Map<String, dynamic> guestInfo) {
    state = state.copyWith(isGuestCheckout: true, guestInfo: guestInfo);
  }

  void disableGuestCheckout() {
    state = state.copyWith(isGuestCheckout: false, guestInfo: null);
  }

  // Bulk operations
  void updateMultipleQuantities(Map<String, int> quantities) {
    final updatedItems =
        state.items.map((item) {
          final newQuantity = quantities[item.id];
          if (newQuantity != null && newQuantity > 0) {
            return item.copyWith(quantity: newQuantity);
          }
          return item;
        }).toList();

    state = state.copyWith(items: updatedItems);
    _calculateTotals();
  }

  void removeMultipleItems(List<String> itemIds) {
    final updatedItems =
        state.items.where((item) => !itemIds.contains(item.id)).toList();
    state = state.copyWith(items: updatedItems);
    _calculateTotals();
  }

  // Cart validation
  bool validateCart() {
    for (final item in state.items) {
      if (item.isOutOfStock) return false;
      if (item.isQuantityExceeded) return false;
    }
    return true;
  }

  List<String> getCartIssues() {
    final issues = <String>[];

    for (final item in state.items) {
      if (item.isOutOfStock) {
        issues.add('${item.name} is out of stock');
      }
      if (item.isQuantityExceeded) {
        issues.add('${item.name} quantity exceeds available stock');
      }
    }

    return issues;
  }

  // Cart persistence (for session storage)
  Map<String, dynamic> toJson() {
    return {
      'items': state.items.map((item) => item.toMap()).toList(),
      'savedForLater': state.savedForLater.map((item) => item.toMap()).toList(),
      'appliedCouponCode': state.appliedCouponCode,
      'couponDiscount': state.couponDiscount,
      'selectedShippingMethodId': state.selectedShippingMethodId,
      'deliveryFee': state.deliveryFee,
      'isGuestCheckout': state.isGuestCheckout,
      'guestInfo': state.guestInfo,
    };
  }

  void fromJson(Map<String, dynamic> json) {
    final items =
        (json['items'] as List?)
            ?.map((item) => CartItemModel.fromMap(item))
            .toList() ??
        [];

    final savedForLater =
        (json['savedForLater'] as List?)
            ?.map((item) => CartItemModel.fromMap(item))
            .toList() ??
        [];

    state = state.copyWith(
      items: items,
      savedForLater: savedForLater,
      appliedCouponCode: json['appliedCouponCode'],
      couponDiscount: json['couponDiscount']?.toDouble() ?? 0.0,
      selectedShippingMethodId: json['selectedShippingMethodId'],
      deliveryFee: json['deliveryFee']?.toDouble() ?? 5000.0,
      isGuestCheckout: json['isGuestCheckout'] ?? false,
      guestInfo: json['guestInfo'],
    );

    _calculateTotals();
  }

  void _calculateTotals() {
    double subtotal = 0.0;
    double originalSubtotal = 0.0;
    double itemDiscounts = 0.0;

    for (var item in state.items) {
      subtotal += item.totalPrice;
      originalSubtotal += item.totalOriginalPrice;
      itemDiscounts += item.totalSavings;
    }

    // Calculate tax (18% VAT for Tanzania)
    final tax = subtotal * 0.18;

    // Calculate final total
    final total = subtotal + state.deliveryFee + tax - state.couponDiscount;

    state = state.copyWith(
      subtotal: subtotal,
      originalSubtotal: originalSubtotal,
      itemDiscounts: itemDiscounts,
      tax: tax,
      total: total,
    );
  }
}

final cartProvider = StateNotifierProvider<CartNotifier, CartState>((ref) {
  return CartNotifier();
});
