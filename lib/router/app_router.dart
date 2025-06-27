import 'package:car_accessories/models/order_model.dart';
import 'package:car_accessories/models/product_model.dart';
import 'package:car_accessories/providers/auth_provider.dart';
import 'package:car_accessories/router/go_router_refresh_stream.dart';
import 'package:car_accessories/screens/auth/enhanced_login_screen.dart';
import 'package:car_accessories/screens/auth/enhanced_register_screen.dart';
import 'package:car_accessories/screens/auth/forgot_password_screen.dart';
import 'package:car_accessories/screens/customer/order_tracking_screen.dart';
import 'package:car_accessories/screens/customer/product_detail_screen.dart';
import 'package:car_accessories/screens/customer/enhanced_search_screen.dart';
import 'package:car_accessories/screens/splash_screen.dart';
import 'package:car_accessories/screens/onboarding_screen.dart';
import 'package:car_accessories/screens/customer/home_screen.dart';
import 'package:car_accessories/screens/customer/product_list_screen.dart';
import 'package:car_accessories/screens/customer/cart_screen.dart';
import 'package:car_accessories/screens/customer/profile_screen.dart';
import 'package:car_accessories/screens/seller/add_product_screen.dart';
import 'package:car_accessories/screens/seller/seller_dashboard_screen.dart';
import 'package:car_accessories/screens/seller/inventory_screen.dart';
import 'package:car_accessories/screens/seller/seller_orders_screen.dart';
import 'package:car_accessories/screens/seller/seller_profile_screen.dart';
import 'package:car_accessories/screens/admin/admin_shell.dart';
import 'package:car_accessories/screens/admin/admin_dashboard_screen.dart';
import 'package:car_accessories/screens/admin/admin_products_screen.dart';
import 'package:car_accessories/screens/admin/admin_orders_screen.dart';
import 'package:car_accessories/screens/admin/admin_users_screen.dart';
import 'package:car_accessories/screens/admin/admin_analytics_screen.dart';
import 'package:car_accessories/screens/admin/admin_profile_screen.dart';
import 'package:car_accessories/screens/admin/admin_backup_screen.dart';
import 'package:car_accessories/screens/customer/enhanced_order_history_screen.dart';
import 'package:car_accessories/screens/customer/notifications_screen.dart';
import 'package:car_accessories/services/auth_service.dart';
import 'package:car_accessories/widgets/customer_shell.dart';
import 'package:car_accessories/widgets/seller_shell.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

enum AppRoute {
  splash,
  onboarding,
  login,
  register,
  forgotPassword,
  customerHome,
  customerBrowse,
  customerProductDetail,
  productDetail,
  customerOrderTracking,
  customerEnhancedSearch,
  customerCart,
  customerHistory,
  customerProfile,
  customerNotifications,
  sellerDashboard,
  sellerInventory,
  sellerOrders,
  sellerProfile,
  addProduct,
  adminDashboard,
  adminProducts,
  adminOrders,
  adminUsers,
  adminBackup,
  adminAnalytics,
  adminProfile,
}

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    refreshListenable: GoRouterRefreshStream(
      ref.watch(authServiceProvider).authStateChanges,
    ),
    initialLocation: '/splash',
    redirect: (context, state) {
      final isLoggedIn = authState.user != null;
      final isGoingToAuth =
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/register' ||
          state.matchedLocation == '/forgot-password';
      final isGoingToSplash = state.matchedLocation == '/splash';
      final isGoingToOnboarding = state.matchedLocation == '/onboarding';

      // If going to splash or onboarding, allow it
      if (isGoingToSplash || isGoingToOnboarding) {
        return null;
      }

      // If not logged in and not going to auth page, redirect to login
      if (!isLoggedIn && !isGoingToAuth) {
        return '/login';
      }

      // If logged in and going to auth page, redirect to appropriate home
      if (isLoggedIn && isGoingToAuth) {
        final user = authState.user!;

        if (user.role == 'seller') {
          print('Seller role detected');
          return '/seller/dashboard';
        } else if (user.role == 'admin') {
          return '/admin/dashboard';
        } else {
          return '/customer/home';
        }
      }

      // Role-based access control
      if (isLoggedIn) {
        final user = authState.user!;
        final location = state.matchedLocation;

        // Admin routes - only accessible by admin users
        if (location.startsWith('/admin') && user.role != 'admin') {
          if (user.role == 'seller') {
            return '/seller/dashboard';
          } else {
            return '/customer/home';
          }
        }

        // Seller routes - only accessible by seller users
        if (location.startsWith('/seller') && user.role != 'seller') {
          if (user.role == 'admin') {
            return '/admin/dashboard';
          } else {
            return '/customer/home';
          }
        }

        // Customer routes - accessible by customer users (default)
        if (location.startsWith('/customer') && user.role != 'customer') {
          if (user.role == 'admin') {
            return '/admin/dashboard';
          } else if (user.role == 'seller') {
            return '/seller/dashboard';
          }
        }
      }

      return null;
    },
    routes: [
      // Splash and Onboarding routes
      GoRoute(
        path: '/splash',
        name: AppRoute.splash.name,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        name: AppRoute.onboarding.name,
        builder: (context, state) => const OnboardingScreen(),
      ),

      // Auth routes
      GoRoute(
        path: '/login',
        builder: (context, state) => EnhancedLoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => EnhancedRegisterScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),

      // Customer Shell with indexed stack
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return CustomerShell(navigationShell: navigationShell);
        },
        branches: [
          // Home tab
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/customer/home',
                name: AppRoute.customerHome.name,
                builder: (context, state) => const HomeScreen(),
                routes: [
                  GoRoute(
                    path: 'product/:id',
                    name: AppRoute.customerProductDetail.name,
                    builder: (context, state) {
                      final product = state.extra as ProductModel;
                      return ProductDetailScreen(product: product);
                    },
                  ),
                  GoRoute(
                    path: 'order-tracking/:id',
                    name: AppRoute.customerOrderTracking.name,
                    builder: (context, state) {
                      final order = state.extra as OrderModel;
                      return OrderTrackingScreen(order: order);
                    },
                  ),
                  GoRoute(
                    path: 'notifications',
                    name: AppRoute.customerNotifications.name,
                    builder: (context, state) => const NotificationsScreen(),
                  ),
                ],
              ),
            ],
          ),
          // Browse tab
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/customer/browse',
                name: AppRoute.customerBrowse.name,
                builder: (context, state) => const ProductListScreen(),
                routes: [
                  GoRoute(
                    path: 'product/:id',
                    name: AppRoute.productDetail.name,
                    builder: (context, state) {
                      final product = state.extra as ProductModel;
                      return ProductDetailScreen(product: product);
                    },
                  ),
                  GoRoute(
                    path: 'enhanced-search',
                    name: AppRoute.customerEnhancedSearch.name,
                    builder: (context, state) => const EnhancedSearchScreen(),
                  ),
                ],
              ),
            ],
          ),
          // Cart tab
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/customer/cart',
                name: AppRoute.customerCart.name,
                builder: (context, state) => const CartScreen(),
              ),
            ],
          ),
          // History tab
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/customer/history',
                name: AppRoute.customerHistory.name,
                builder: (context, state) => const EnhancedOrderHistoryScreen(),
              ),
            ],
          ),
          // Profile tab
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/customer/profile',
                name: AppRoute.customerProfile.name,
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),

      // Seller Shell with indexed stack
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return SellerShell(navigationShell: navigationShell);
        },
        branches: [
          // Dashboard tab
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/seller/dashboard',
                name: AppRoute.sellerDashboard.name,
                builder: (context, state) => const SellerDashboardScreen(),
              ),
            ],
          ),
          // Inventory tab
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/seller/inventory',
                name: AppRoute.sellerInventory.name,
                builder: (context, state) => const InventoryScreen(),
                routes: [
                  GoRoute(
                    path: 'add-product',
                    name: AppRoute.addProduct.name,
                    builder: (context, state) => const AddProductScreen(),
                  ),
                ],
              ),
            ],
          ),
          // Orders tab
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/seller/orders',
                name: AppRoute.sellerOrders.name,
                builder: (context, state) => const SellerOrdersScreen(),
              ),
            ],
          ),
          // Profile tab
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/seller/profile',
                name: AppRoute.sellerProfile.name,
                builder: (context, state) => const SellerProfileScreen(),
              ),
            ],
          ),
        ],
      ),

      // Admin Shell with indexed stack
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AdminShell(navigationShell: navigationShell);
        },
        branches: [
          // Dashboard tab
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/admin/dashboard',
                name: AppRoute.adminDashboard.name,
                builder: (context, state) => const AdminDashboardScreen(),
              ),
            ],
          ),
          // Users tab
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/admin/users',
                name: AppRoute.adminUsers.name,
                builder: (context, state) => const AdminUsersScreen(),
              ),
            ],
          ),
          // Products tab
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/admin/products',
                name: AppRoute.adminProducts.name,
                builder: (context, state) => const AdminProductsScreen(),
              ),
            ],
          ),
          // Orders tab
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/admin/orders',
                name: AppRoute.adminOrders.name,
                builder: (context, state) => const AdminOrdersScreen(),
              ),
            ],
          ),
          // Backup tab
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/admin/backup',
                name: AppRoute.adminBackup.name,
                builder: (context, state) => const AdminBackupScreen(),
              ),
            ],
          ),
          // Analytics tab
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/admin/analytics',
                name: AppRoute.adminAnalytics.name,
                builder: (context, state) => const AdminAnalyticsScreen(),
              ),
            ],
          ),
          // Profile tab
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/admin/profile',
                name: AppRoute.adminProfile.name,
                builder: (context, state) => const AdminProfileScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
