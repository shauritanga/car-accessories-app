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
  final double subtotal;
  final double deliveryFee;
  final double discountPercentage;
  final double total;

  CartState({
    this.items = const [],
    this.subtotal = 0.0,
    this.deliveryFee = 5.0,
    this.discountPercentage = 20.0,
    this.total = 0.0,
  });

  CartState copyWith({
    List<CartItemModel>? items,
    double? subtotal,
    double? deliveryFee,
    double? discountPercentage,
    double? total,
  }) {
    return CartState(
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      discountPercentage: discountPercentage ?? this.discountPercentage,
      total: total ?? this.total,
    );
  }
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

  void _calculateTotals() {
    double subtotal = 0.0;
    for (var item in state.items) {
      subtotal += item.price * item.quantity;
    }
    final discountAmount = subtotal * (state.discountPercentage / 100);
    final total = subtotal + state.deliveryFee - discountAmount;

    state = state.copyWith(subtotal: subtotal, total: total);
  }
}

final cartProvider = StateNotifierProvider<CartNotifier, CartState>((ref) {
  return CartNotifier();
});
