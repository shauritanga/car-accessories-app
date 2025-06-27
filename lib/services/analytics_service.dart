import "package:cloud_firestore/cloud_firestore.dart";
import '../models/analytics_model.dart';

class AnalyticsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Customer Behavior Analysis
  Future<CustomerBehavior> calculateCustomerBehavior(String userId) async {
    try {
      // Get user's order history
      final ordersSnapshot = await _firestore
          .collection('orders')
          .where('customerId', isEqualTo: userId)
          .get();

      final orders = ordersSnapshot.docs;
      final totalPurchases = orders.length;
      final totalRevenue = orders.fold<double>(
        0.0,
        (sum, order) => sum + ((order.data()['total'] as num?)?.toDouble() ?? 0.0),
      );

      // Calculate customer segment based on behavior
      CustomerSegment segment;
      if (totalPurchases == 0) {
        segment = CustomerSegment.newCustomer;
      } else if (totalPurchases >= 10 && totalRevenue >= 1000000) {
        segment = CustomerSegment.highValue;
      } else if (totalPurchases >= 5) {
        segment = CustomerSegment.loyal;
      } else if (totalPurchases >= 2) {
        segment = CustomerSegment.returning;
      } else {
        segment = CustomerSegment.lowValue;
      }

      // Mock data for demonstration
      return CustomerBehavior(
        userId: userId,
        segment: segment,
        totalSessions: 15,
        totalPageViews: 45,
        totalProductViews: 30,
        totalAddToCart: 8,
        totalPurchases: totalPurchases,
        averageSessionDuration: 180.0, // seconds
        averageOrderValue: totalPurchases > 0 ? totalRevenue / totalPurchases : 0.0,
        lifetimeValue: totalRevenue,
        daysSinceLastPurchase: 7,
        churnProbability: 0.2,
        favoriteCategories: ['Interior', 'Exterior', 'Performance'],
        favoriteProducts: ['product1', 'product2', 'product3'],
        categoryPreferences: {'Interior': 5, 'Exterior': 3, 'Performance': 2},
        productPreferences: {'product1': 3, 'product2': 2, 'product3': 1},
      );
    } catch (e) {
      throw Exception('Failed to calculate customer behavior: $e');
    }
  }

  // Sales Analytics
  Future<SalesAnalytics> getSalesAnalytics(DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final ordersSnapshot = await _firestore
          .collection('orders')
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('createdAt', isLessThan: Timestamp.fromDate(endOfDay))
          .get();

      final orders = ordersSnapshot.docs;
      double totalRevenue = 0.0;
      int totalItems = 0;
      Map<String, double> revenueByCategory = {};
      Map<String, int> ordersByCategory = {};
      Map<String, double> revenueBySeller = {};
      Map<String, int> ordersBySeller = {};

      for (final order in orders) {
        final orderData = order.data();
        final revenue = (orderData['total'] as num?)?.toDouble() ?? 0.0;
        totalRevenue += revenue;

        // Process items
        final items = orderData['items'] as List<dynamic>? ?? [];
        totalItems += items.length;

        // Process categories and sellers
        for (final item in items) {
          final category = item['category'] as String? ?? 'Unknown';
          final sellerId = item['sellerId'] as String? ?? 'Unknown';

          revenueByCategory[category] = (revenueByCategory[category] ?? 0.0) + revenue;
          ordersByCategory[category] = (ordersByCategory[category] ?? 0) + 1;
          revenueBySeller[sellerId] = (revenueBySeller[sellerId] ?? 0.0) + revenue;
          ordersBySeller[sellerId] = (ordersBySeller[sellerId] ?? 0) + 1;
        }
      }

      return SalesAnalytics(
        id: date.toIso8601String(),
        date: date,
        totalRevenue: totalRevenue,
        totalOrders: orders.length,
        totalItems: totalItems,
        averageOrderValue: orders.isNotEmpty ? totalRevenue / orders.length : 0.0,
        revenueByCategory: revenueByCategory,
        ordersByCategory: ordersByCategory,
        revenueBySeller: revenueBySeller,
        ordersBySeller: ordersBySeller,
        topProducts: ['product1', 'product2', 'product3'],
        topCategories: (() {
          final sortedCategories = revenueByCategory.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));
          return sortedCategories.take(5).map((e) => e.key).toList();
        })(),
        refundAmount: 0.0,
        refundCount: 0,
        discountAmount: 0.0,
        discountCount: 0,
      );
    } catch (e) {
      throw Exception('Failed to get sales analytics: $e');
    }
  }

  // User Behavior Analytics
  Future<UserBehaviorAnalytics> getUserBehaviorAnalytics(DateTime date) async {
    try {
      // Mock data for demonstration
      return UserBehaviorAnalytics(
        id: date.toIso8601String(),
        date: date,
        totalUsers: 150,
        newUsers: 25,
        activeUsers: 120,
        returningUsers: 95,
        averageSessionDuration: 240.0,
        totalSessions: 300,
        pageViews: {
          'home': 500,
          'products': 800,
          'cart': 200,
          'checkout': 150,
        },
        userActions: {
          'search': 300,
          'filter': 200,
          'add_to_cart': 150,
          'purchase': 100,
        },
        mostViewedProducts: ['product1', 'product2', 'product3'],
        mostSearchedTerms: ['car cover', 'seat cover', 'floor mat'],
        conversionRates: {
          'view_to_cart': 0.15,
          'cart_to_purchase': 0.75,
          'search_to_purchase': 0.08,
        },
        cartAbandonmentRate: 0.25,
        checkoutCompletionRate: 0.75,
      );
    } catch (e) {
      throw Exception('Failed to get user behavior analytics: $e');
    }
  }

  // Sales Forecast
  Future<List<SalesForecast>> getSalesForecast({
    DateTime? startDate,
    DateTime? endDate,
    String? productId,
    String? category,
  }) async {
    try {
      // Mock sales forecast data
      final forecasts = <SalesForecast>[];
      final start = startDate ?? DateTime.now();
      final end = endDate ?? start.add(const Duration(days: 30));

      for (int i = 0; i < 7; i++) {
        final date = start.add(Duration(days: i));
        forecasts.add(SalesForecast(
          id: 'forecast_$i',
          date: date,
          predictedRevenue: 500000 + (i * 50000),
          predictedUnits: 50 + (i * 5),
          confidence: 0.7 + (i * 0.02),
          productId: productId,
          category: category,
          description: 'Predicted sales for ${date.day}/${date.month}/${date.year}',
        ));
      }

      return forecasts;
    } catch (e) {
      throw Exception('Failed to get sales forecast: $e');
    }
  }

  // Inventory Optimization
  Future<List<InventoryOptimization>> getInventoryOptimization() async {
    try {
      // Mock inventory optimization data
      return [
        InventoryOptimization(
          id: 'opt_1',
          productId: 'product1',
          productName: 'Car Seat Cover',
          currentStock: 15,
          optimalStock: 25,
          stockoutRisk: 0.3,
          overstockRisk: 0.1,
          recommendations: [
            'Increase stock by 10 units',
            'Monitor sales velocity',
            'Consider bulk pricing',
          ],
          createdAt: DateTime.now(),
        ),
        InventoryOptimization(
          id: 'opt_2',
          productId: 'product2',
          productName: 'Floor Mats',
          currentStock: 5,
          optimalStock: 20,
          stockoutRisk: 0.8,
          overstockRisk: 0.05,
          recommendations: [
            'Urgent: Restock immediately',
            'Increase safety stock',
            'Review supplier lead time',
          ],
          createdAt: DateTime.now(),
        ),
        InventoryOptimization(
          id: 'opt_3',
          productId: 'product3',
          productName: 'Car Cover',
          currentStock: 50,
          optimalStock: 30,
          stockoutRisk: 0.1,
          overstockRisk: 0.6,
          recommendations: [
            'Reduce stock by 20 units',
            'Run promotional campaign',
            'Review pricing strategy',
          ],
          createdAt: DateTime.now(),
        ),
      ];
    } catch (e) {
      throw Exception('Failed to get inventory optimization: $e');
    }
  }

  // Performance Metrics
  Future<PerformanceMetrics> calculatePerformanceMetrics(DateTime date) async {
    try {
      // Mock performance metrics
      return PerformanceMetrics(
        id: date.toIso8601String(),
        date: date,
        totalRevenue: 2500000.0,
        totalOrders: 150,
        averageOrderValue: 16666.67,
        conversionRate: 0.12,
        cartAbandonmentRate: 0.25,
        customerSatisfactionScore: 4.2,
        activeUsers: 120,
        newUsers: 25,
        retentionRate: 0.75,
        churnRate: 0.15,
        categoryPerformance: {
          'Interior': 0.85,
          'Exterior': 0.72,
          'Performance': 0.68,
          'Electronics': 0.91,
        },
        productPerformance: {
          'product1': 0.92,
          'product2': 0.88,
          'product3': 0.85,
          'product4': 0.78,
        },
        appLoadTime: 2.5,
        searchResponseTime: 1.2,
        errorCount: 5,
        uptimePercentage: 99.8,
      );
    } catch (e) {
      throw Exception('Failed to calculate performance metrics: $e');
    }
  }

  // Event Tracking Methods
  Future<void> trackPageView(String pageName) async {
    try {
      await _firestore.collection('analytics_events').add({
        'type': 'page_view',
        'pageName': pageName,
        'timestamp': Timestamp.now(),
        'userId': 'current_user', // Replace with actual user ID
      });
    } catch (e) {
      print('Error tracking page view: $e');
    }
  }

  Future<void> trackProductView(String productId, String category) async {
    try {
      await _firestore.collection('analytics_events').add({
        'type': 'product_view',
        'productId': productId,
        'category': category,
        'timestamp': Timestamp.now(),
        'userId': 'current_user', // Replace with actual user ID
      });
    } catch (e) {
      print('Error tracking product view: $e');
    }
  }

  Future<void> trackAddToCart(String productId, int quantity, double price) async {
    try {
      await _firestore.collection('analytics_events').add({
        'type': 'add_to_cart',
        'productId': productId,
        'quantity': quantity,
        'price': price,
        'timestamp': Timestamp.now(),
        'userId': 'current_user', // Replace with actual user ID
      });
    } catch (e) {
      print('Error tracking add to cart: $e');
    }
  }

  Future<void> trackPurchase(String orderId, double totalAmount, List<String> productIds) async {
    try {
      await _firestore.collection('analytics_events').add({
        'type': 'purchase',
        'orderId': orderId,
        'totalAmount': totalAmount,
        'productIds': productIds,
        'timestamp': Timestamp.now(),
        'userId': 'current_user', // Replace with actual user ID
      });
    } catch (e) {
      print('Error tracking purchase: $e');
    }
  }

  // Generate Sales Forecast
  Future<void> generateSalesForecast({
    required DateTime date,
    String? productId,
    String? category,
  }) async {
    try {
      // This would typically involve ML models or statistical analysis
      // For now, we'll just create a mock forecast
      final forecast = SalesForecast(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        date: date,
        predictedRevenue: 750000.0,
        predictedUnits: 75,
        confidence: 0.85,
        productId: productId,
        category: category,
        description: 'Generated forecast for ${date.day}/${date.month}/${date.year}',
      );

      await _firestore.collection('sales_forecasts').doc(forecast.id).set(forecast.toMap());
    } catch (e) {
      throw Exception('Failed to generate sales forecast: $e');
    }
  }

  // Generate Inventory Optimization
  Future<void> generateInventoryOptimization(String productId) async {
    try {
      // This would typically involve analyzing sales patterns, lead times, etc.
      // For now, we'll create a mock optimization
      final optimization = InventoryOptimization(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        productId: productId,
        productName: 'Product $productId',
        currentStock: 20,
        optimalStock: 30,
        stockoutRisk: 0.4,
        overstockRisk: 0.2,
        recommendations: [
          'Increase stock by 10 units',
          'Monitor weekly sales',
          'Review supplier reliability',
        ],
        createdAt: DateTime.now(),
      );

      await _firestore.collection('inventory_optimizations').doc(optimization.id).set(optimization.toMap());
    } catch (e) {
      throw Exception('Failed to generate inventory optimization: $e');
    }
  }
}
