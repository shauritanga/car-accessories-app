import 'package:car_accessories/providers/cart_provider.dart';
import 'package:car_accessories/screens/customer/cart_screen.dart';
import 'package:car_accessories/screens/customer/home_screen.dart';
import 'package:car_accessories/screens/customer/product_list_screen.dart';
import 'package:car_accessories/screens/customer/profile_screen.dart';
import 'package:car_accessories/screens/seller/inventory_screen.dart';
import 'package:car_accessories/screens/seller/seller_dashboard_screen.dart';
import 'package:car_accessories/screens/seller/seller_orders_screen.dart';
import 'package:car_accessories/screens/seller/seller_profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:badges/badges.dart' as badges;
import 'package:car_accessories/screens/customer/enhanced_order_history_screen.dart';
import 'package:car_accessories/widgets/debug_onboarding_reset.dart';

class MainScreen extends ConsumerStatefulWidget {
  final String userRole;

  const MainScreen({required this.userRole, super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);

    final List<Widget> customerScreens = [
      const HomeScreen(),
      const ProductListScreen(),
      const CartScreen(),
      const EnhancedOrderHistoryScreen(),
      const ProfileScreen(),
    ];

    final List<Widget> sellerScreens = [
      const SellerDashboardScreen(),
      const InventoryScreen(),
      const SellerOrdersScreen(),
      const SellerProfileScreen(),
    ];

    // Admin screens would be defined here
    final List<Widget> adminScreens = [
      // Admin dashboard and other screens
    ];

    // Select the appropriate screens based on user role
    List<Widget> screens;
    List<BottomNavigationBarItem> navItems;

    if (widget.userRole == 'seller') {
      screens = sellerScreens;
      navItems = [
        const BottomNavigationBarItem(
          icon: Icon(Icons.dashboard),
          label: 'Dashboard',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.inventory),
          label: 'Inventory',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.shopping_bag),
          label: 'Orders',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profile',
        ),
      ];
    } else if (widget.userRole == 'admin') {
      screens = adminScreens;
      navItems = [
        // Admin navigation items
      ];
    } else {
      // Default to customer
      screens = customerScreens;
      navItems = [
        const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        const BottomNavigationBarItem(
          icon: Icon(Icons.search),
          label: 'Browse',
        ),
        BottomNavigationBarItem(
          icon: badges.Badge(
            showBadge: cart.items.isNotEmpty,
            badgeContent: Text(
              '${cart.items.length}',
              style: const TextStyle(color: Colors.white, fontSize: 10),
            ),
            badgeStyle: const badges.BadgeStyle(
              badgeColor: Colors.red,
              padding: EdgeInsets.all(5),
            ),
            child: const Icon(Icons.shopping_cart),
          ),
          label: 'Cart',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.history),
          label: 'History',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profile',
        ),
      ];
    }

    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(index: _selectedIndex, children: screens),
          const DebugOnboardingReset(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        items: navItems,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
      ),
    );
  }
}
