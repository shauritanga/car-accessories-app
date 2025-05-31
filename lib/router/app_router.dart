import 'package:car_accessories/models/order_model.dart';
import 'package:car_accessories/models/product_model.dart';

import 'package:car_accessories/providers/auth_provider.dart';
import 'package:car_accessories/screens/auth/forgot_password_screen.dart';
import 'package:car_accessories/screens/auth/login_screen.dart';
import 'package:car_accessories/screens/auth/register_screen.dart';
import 'package:car_accessories/screens/customer/order_tracking_screen.dart';
import 'package:car_accessories/screens/customer/product_detail_screen.dart';
import 'package:car_accessories/screens/seller/add_product_screen.dart';
import 'package:car_accessories/screens/main_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final isLoggedIn = authState.user != null;
      final isGoingToAuth =
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/register' ||
          state.matchedLocation == '/forgot-password';

      // If not logged in and not going to auth page, redirect to login
      if (!isLoggedIn && !isGoingToAuth) {
        return '/login';
      }

      // If logged in and going to auth page, redirect to appropriate home
      if (isLoggedIn && isGoingToAuth) {
        final user = authState.user!;
        if (user.role == 'seller') {
          return '/seller';
        } else if (user.role == 'admin') {
          return '/admin';
        } else {
          return '/customer';
        }
      }

      return null;
    },
    routes: [
      // Auth routes
      GoRoute(path: '/login', builder: (context, state) => LoginScreen()),
      GoRoute(path: '/register', builder: (context, state) => RegisterScreen()),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),

      // Customer routes
      GoRoute(
        path: '/customer',
        name: 'customer',
        builder: (context, state) => const MainScreen(userRole: 'customer'),
        routes: [
          GoRoute(
            path: 'product/:id',
            name: 'product_detail',
            builder: (context, state) {
              final product = state.extra as ProductModel;
              return ProductDetailScreen(product: product);
            },
          ),
          GoRoute(
            path: 'order-tracking/:id',
            name: 'order_tracking',
            builder: (context, state) {
              final order = state.extra as OrderModel;
              return OrderTrackingScreen(order: order);
            },
          ),
        ],
      ),

      // Seller routes
      GoRoute(
        path: '/seller',
        builder: (context, state) => const MainScreen(userRole: 'seller'),
        routes: [
          GoRoute(
            path: 'add-product',
            builder: (context, state) => const AddProductScreen(),
          ),
        ],
      ),

      // Admin routes (placeholder)
      GoRoute(
        path: '/admin',
        builder: (context, state) => const MainScreen(userRole: 'admin'),
      ),
    ],
  );
});
