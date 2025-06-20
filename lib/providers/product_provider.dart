import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../services/product_service.dart';
import '../models/product_model.dart';

// State class to hold the product list and filter parameters
class ProductState {
  final List<ProductModel> products;
  final String? query;
  final String? category;
  final String? model;

  ProductState({
    this.products = const [],
    this.query,
    this.category,
    this.model,
  });

  ProductState copyWith({
    List<ProductModel>? products,
    String? query,
    String? category,
    String? model,
  }) {
    return ProductState(
      products: products ?? this.products,
      query: query ?? this.query,
      category: category ?? this.category,
      model: model ?? this.model,
    );
  }
}

// StateNotifier to manage product state
class ProductNotifier extends StateNotifier<ProductState> {
  final ProductService _productService = ProductService();

  ProductNotifier() : super(ProductState());

  Future<void> searchProducts({
    String? query,
    String? category,
    String? model,
  }) async {
    try {
      final products =
          await _productService
              .getProducts(query: query, category: category, model: model)
              .first;
      state = state.copyWith(
        products: products,
        query: query,
        category: category,
        model: model,
      );
    } catch (e) {
      throw Exception('Failed to fetch products: $e');
    }
  }

  Future<void> addProduct(ProductModel product, List<XFile> images) async {
    try {
      await _productService.addProduct(product, images);
      // Optionally, fetch the updated product list after adding
      final products =
          await _productService
              .getProducts(
                query: state.query,
                category: state.category,
                model: state.model,
              )
              .first;
      state = state.copyWith(products: products);
    } catch (e) {
      throw Exception('Failed to add product: $e');
    }
  }
}

// StateNotifierProvider for managing product state
final productProvider = StateNotifierProvider<ProductNotifier, ProductState>((
  ref,
) {
  return ProductNotifier();
});

// StreamProvider for real-time product updates
final productStreamProvider =
    StreamProvider.family<List<ProductModel>, ProductFilter>((ref, filter) {
      final productService = ProductService();
      return productService.getProducts(
        query: filter.query,
        category: filter.category,
        model: filter.model,
      );
    });

// Helper class to pass filter parameters to StreamProvider.family
class ProductFilter {
  final String? query;
  final String? category;
  final String? model;

  ProductFilter({this.query, this.category, this.model});
}

// Provider to get the current product list (for convenience in UI)
final currentProductsProvider = Provider<List<ProductModel>>((ref) {
  return ref.watch(productProvider).products;
});
