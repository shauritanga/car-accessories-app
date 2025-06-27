import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../services/product_service.dart';
import '../models/product_model.dart';

// State class to hold the product list and filter parameters
class ProductState {
  final List<ProductModel> products;
  final List<ProductModel> popularProducts;
  final List<ProductModel> newArrivals;
  final String? query;
  final String? category;
  final String? model;
  final bool isLoading;
  final String? error;
  final bool isRefreshing;

  ProductState({
    this.products = const [],
    this.popularProducts = const [],
    this.newArrivals = const [],
    this.query,
    this.category,
    this.model,
    this.isLoading = false,
    this.error,
    this.isRefreshing = false,
  });

  ProductState copyWith({
    List<ProductModel>? products,
    List<ProductModel>? popularProducts,
    List<ProductModel>? newArrivals,
    String? query,
    String? category,
    String? model,
    bool? isLoading,
    String? error,
    bool? isRefreshing,
  }) {
    return ProductState(
      products: products ?? this.products,
      popularProducts: popularProducts ?? this.popularProducts,
      newArrivals: newArrivals ?? this.newArrivals,
      query: query ?? this.query,
      category: category ?? this.category,
      model: model ?? this.model,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isRefreshing: isRefreshing ?? this.isRefreshing,
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
    int? limit,
    String? sortBy,
    bool? inStockOnly,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      final products = await _productService
          .getProducts(
            query: query,
            category: category,
            model: model,
            limit: limit,
            sortBy: sortBy,
            inStockOnly: inStockOnly,
          )
          .first;
      
      state = state.copyWith(
        products: products,
        query: query,
        category: category,
        model: model,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      throw Exception('Failed to fetch products: $e');
    }
  }

  Future<void> loadPopularProducts({int limit = 10}) async {
    try {
      final products = await _productService
          .getPopularProducts(limit: limit)
          .first;
      
      state = state.copyWith(popularProducts: products);
    } catch (e) {
      print('Failed to load popular products: $e');
    }
  }

  Future<void> loadNewArrivals({int limit = 10}) async {
    try {
      final products = await _productService
          .getNewArrivals(limit: limit)
          .first;
      
      state = state.copyWith(newArrivals: products);
    } catch (e) {
      print('Failed to load new arrivals: $e');
    }
  }

  Future<void> loadProductsByCategory(String category, {int limit = 20}) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      final products = await _productService
          .getProductsByCategory(category, limit: limit)
          .first;
      
      state = state.copyWith(
        products: products,
        category: category,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      throw Exception('Failed to fetch category products: $e');
    }
  }

  Future<void> searchProductsByTerm(String searchTerm, {int limit = 20}) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      final products = await _productService
          .searchProducts(searchTerm, limit: limit)
          .first;
      
      state = state.copyWith(
        products: products,
        query: searchTerm,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      throw Exception('Failed to search products: $e');
    }
  }

  Future<void> addProduct(ProductModel product, List<XFile> images) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      await _productService.addProduct(product, images);
      
      // Refresh the product list after adding
      await searchProducts(
        query: state.query,
        category: state.category,
        model: state.model,
      );
      
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      throw Exception('Failed to add product: $e');
    }
  }

  Future<void> updateProductStock(String productId, int newStock) async {
    try {
      await _productService.updateProductStock(productId, newStock);
      
      // Update the product in the current list
      final updatedProducts = state.products.map((product) {
        if (product.id == productId) {
          return ProductModel(
            id: product.id,
            name: product.name,
            description: product.description,
            price: product.price,
            originalPrice: product.originalPrice,
            stock: newStock,
            category: product.category,
            brand: product.brand,
            model: product.model,
            sku: product.sku,
            compatibility: product.compatibility,
            sellerId: product.sellerId,
            images: product.images,
            videos: product.videos,
            rating: product.rating,
            averageRating: product.averageRating,
            totalReviews: product.totalReviews,
            ratingDistribution: product.ratingDistribution,
            specifications: product.specifications,
            variants: product.variants,
            shippingInfo: product.shippingInfo,
            returnPolicy: product.returnPolicy,
            tags: product.tags,
            createdAt: product.createdAt,
            updatedAt: product.updatedAt,
            isActive: product.isActive,
            viewCount: product.viewCount,
          );
        }
        return product;
      }).toList();
      
      state = state.copyWith(products: updatedProducts);
    } catch (e) {
      throw Exception('Failed to update product stock: $e');
    }
  }

  Future<void> updateProductRating(String productId, double newRating) async {
    try {
      await _productService.updateProductRating(productId, newRating);
      
      // Update the product in the current list
      final updatedProducts = state.products.map((product) {
        if (product.id == productId) {
          return ProductModel(
            id: product.id,
            name: product.name,
            description: product.description,
            price: product.price,
            originalPrice: product.originalPrice,
            stock: product.stock,
            category: product.category,
            brand: product.brand,
            model: product.model,
            sku: product.sku,
            compatibility: product.compatibility,
            sellerId: product.sellerId,
            images: product.images,
            videos: product.videos,
            rating: newRating,
            averageRating: product.averageRating,
            totalReviews: product.totalReviews,
            ratingDistribution: product.ratingDistribution,
            specifications: product.specifications,
            variants: product.variants,
            shippingInfo: product.shippingInfo,
            returnPolicy: product.returnPolicy,
            tags: product.tags,
            createdAt: product.createdAt,
            updatedAt: product.updatedAt,
            isActive: product.isActive,
            viewCount: product.viewCount,
          );
        }
        return product;
      }).toList();
      
      state = state.copyWith(products: updatedProducts);
    } catch (e) {
      throw Exception('Failed to update product rating: $e');
    }
  }

  Future<void> refreshProducts() async {
    try {
      state = state.copyWith(isRefreshing: true, error: null);
      
      await Future.wait([
        searchProducts(
          query: state.query,
          category: state.category,
          model: state.model,
        ),
        loadPopularProducts(),
        loadNewArrivals(),
      ]);
      
      state = state.copyWith(isRefreshing: false);
    } catch (e) {
      state = state.copyWith(
        isRefreshing: false,
        error: e.toString(),
      );
      throw Exception('Failed to refresh products: $e');
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  void clearProducts() {
    state = state.copyWith(products: []);
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

// Provider for popular products
final popularProductsProvider = StreamProvider<List<ProductModel>>((ref) {
  final productService = ProductService();
  return productService.getPopularProducts(limit: 10);
});

// Provider for new arrivals
final newArrivalsProvider = StreamProvider<List<ProductModel>>((ref) {
  final productService = ProductService();
  return productService.getNewArrivals(limit: 10);
});

// Provider for categories
final categoriesProvider = FutureProvider<List<String>>((ref) {
  final productService = ProductService();
  return productService.getCategories();
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

// Provider to get popular products (for convenience in UI)
final currentPopularProductsProvider = Provider<List<ProductModel>>((ref) {
  return ref.watch(productProvider).popularProducts;
});

// Provider to get new arrivals (for convenience in UI)
final currentNewArrivalsProvider = Provider<List<ProductModel>>((ref) {
  return ref.watch(productProvider).newArrivals;
});
