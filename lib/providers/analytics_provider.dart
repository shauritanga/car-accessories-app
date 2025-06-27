import 'package:flutter/foundation.dart';
import '../models/analytics_model.dart';
import '../services/analytics_service.dart';

class AnalyticsProvider extends ChangeNotifier {
  final AnalyticsService _analyticsService = AnalyticsService();

  CustomerBehavior? _customerBehavior;
  List<SalesForecast> _salesForecasts = [];
  List<InventoryOptimization> _inventoryOptimizations = [];
  PerformanceMetrics? _performanceMetrics;
  bool _isLoading = false;
  String? _error;

  // Getters
  CustomerBehavior? get customerBehavior => _customerBehavior;
  List<SalesForecast> get salesForecasts => _salesForecasts;
  List<InventoryOptimization> get inventoryOptimizations =>
      _inventoryOptimizations;
  PerformanceMetrics? get performanceMetrics => _performanceMetrics;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Initialize analytics
  Future<void> initializeAnalytics() async {
    _setLoading(true);
    try {
      await Future.wait([
        loadCustomerBehavior(),
        loadSalesForecasts(),
        loadInventoryOptimizations(),
        loadPerformanceMetrics(),
      ]);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // Load customer behavior
  Future<void> loadCustomerBehavior() async {
    try {
      // For now, we'll calculate behavior for the current user
      // In a real app, you might want to pass a specific user ID
      _customerBehavior = await _analyticsService.calculateCustomerBehavior(
        'current_user',
      );
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load customer behavior: $e';
      notifyListeners();
    }
  }

  // Load sales forecasts
  Future<void> loadSalesForecasts({
    DateTime? startDate,
    DateTime? endDate,
    String? productId,
    String? category,
  }) async {
    try {
      _salesForecasts = await _analyticsService.getSalesForecast(
        startDate: startDate,
        endDate: endDate,
        productId: productId,
        category: category,
      );
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load sales forecasts: $e';
      notifyListeners();
    }
  }

  // Load inventory optimizations
  Future<void> loadInventoryOptimizations() async {
    try {
      _inventoryOptimizations =
          await _analyticsService.getInventoryOptimization();
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load inventory optimizations: $e';
      notifyListeners();
    }
  }

  // Load performance metrics
  Future<void> loadPerformanceMetrics({DateTime? date}) async {
    try {
      final targetDate = date ?? DateTime.now();
      _performanceMetrics = await _analyticsService.calculatePerformanceMetrics(
        targetDate,
      );
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load performance metrics: $e';
      notifyListeners();
    }
  }

  // Track events
  Future<void> trackPageView(String pageName) async {
    try {
      await _analyticsService.trackPageView(pageName);
    } catch (e) {
      debugPrint('Error tracking page view: $e');
    }
  }

  Future<void> trackProductView(String productId, String category) async {
    try {
      await _analyticsService.trackProductView(productId, category);
    } catch (e) {
      debugPrint('Error tracking product view: $e');
    }
  }

  Future<void> trackAddToCart(
    String productId,
    int quantity,
    double price,
  ) async {
    try {
      await _analyticsService.trackAddToCart(productId, quantity, price);
    } catch (e) {
      debugPrint('Error tracking add to cart: $e');
    }
  }

  Future<void> trackPurchase(
    String orderId,
    double totalAmount,
    List<String> productIds,
  ) async {
    try {
      await _analyticsService.trackPurchase(orderId, totalAmount, productIds);
    } catch (e) {
      debugPrint('Error tracking purchase: $e');
    }
  }

  // Generate sales forecast
  Future<void> generateSalesForecast({
    required DateTime date,
    String? productId,
    String? category,
  }) async {
    try {
      await _analyticsService.generateSalesForecast(
        date: date,
        productId: productId,
        category: category,
      );

      // Reload forecasts
      await loadSalesForecasts();
    } catch (e) {
      _error = 'Failed to generate sales forecast: $e';
      notifyListeners();
    }
  }

  // Generate inventory optimization
  Future<void> generateInventoryOptimization(String productId) async {
    try {
      await _analyticsService.generateInventoryOptimization(productId);

      // Reload optimizations
      await loadInventoryOptimizations();
    } catch (e) {
      _error = 'Failed to generate inventory optimization: $e';
      notifyListeners();
    }
  }

  // Get customer segment insights
  Map<String, dynamic> getCustomerSegmentInsights() {
    if (_customerBehavior == null) return {};

    final segment = _customerBehavior!.segment;
    final insights = <String, dynamic>{};

    switch (segment) {
      case CustomerSegment.newCustomer:
        insights['title'] = 'New Customer';
        insights['description'] = 'Welcome! Start exploring our products.';
        insights['recommendations'] = [
          'Browse featured products',
          'Complete your first purchase',
          'Read product reviews',
        ];
        insights['color'] = 0xFF4CAF50;
        break;

      case CustomerSegment.returning:
        insights['title'] = 'Returning Customer';
        insights['description'] = 'Great to see you again!';
        insights['recommendations'] = [
          'Check out new arrivals',
          'Explore your favorite categories',
          'Consider loyalty rewards',
        ];
        insights['color'] = 0xFF2196F3;
        break;

      case CustomerSegment.loyal:
        insights['title'] = 'Loyal Customer';
        insights['description'] = 'You\'re one of our valued customers!';
        insights['recommendations'] = [
          'Exclusive member benefits',
          'Early access to sales',
          'Premium customer support',
        ];
        insights['color'] = 0xFFFF9800;
        break;

      case CustomerSegment.atRisk:
        insights['title'] = 'At Risk Customer';
        insights['description'] = 'We miss you! Come back and explore.';
        insights['recommendations'] = [
          'Special comeback offers',
          'Personalized recommendations',
          'Customer support assistance',
        ];
        insights['color'] = 0xFFFF5722;
        break;

      case CustomerSegment.churned:
        insights['title'] = 'Churned Customer';
        insights['description'] = 'We\'d love to have you back!';
        insights['recommendations'] = [
          'Win-back campaigns',
          'Feedback surveys',
          'Special re-engagement offers',
        ];
        insights['color'] = 0xFF9C27B0;
        break;

      case CustomerSegment.highValue:
        insights['title'] = 'High Value Customer';
        insights['description'] = 'Thank you for your continued support!';
        insights['recommendations'] = [
          'VIP treatment',
          'Exclusive products',
          'Dedicated account manager',
        ];
        insights['color'] = 0xFFFFD700;
        break;

      case CustomerSegment.lowValue:
        insights['title'] = 'Low Value Customer';
        insights['description'] = 'Discover more value in our products.';
        insights['recommendations'] = [
          'Product education',
          'Bundle offers',
          'Value-focused promotions',
        ];
        insights['color'] = 0xFF607D8B;
        break;
    }

    return insights;
  }

  // Get sales forecast insights
  List<Map<String, dynamic>> getSalesForecastInsights() {
    return _salesForecasts.map((forecast) {
      return {
        'date': forecast.date,
        'predictedRevenue': forecast.predictedRevenue,
        'predictedUnits': forecast.predictedUnits,
        'confidence': forecast.confidence,
        'productId': forecast.productId,
        'category': forecast.category,
        'formattedRevenue':
            'TZS ${forecast.predictedRevenue.toStringAsFixed(0)}',
        'formattedUnits': '${forecast.predictedUnits} units',
        'confidenceLevel': _getConfidenceLevel(forecast.confidence),
      };
    }).toList();
  }

  // Get inventory optimization insights
  List<Map<String, dynamic>> getInventoryOptimizationInsights() {
    return _inventoryOptimizations.map((optimization) {
      return {
        'productId': optimization.productId,
        'productName': optimization.productName,
        'currentStock': optimization.currentStock,
        'optimalStock': optimization.optimalStock,
        'stockoutRisk': optimization.stockoutRisk,
        'overstockRisk': optimization.overstockRisk,
        'recommendations': optimization.recommendations.length,
        'status': _getInventoryStatus(optimization),
        'formattedCurrentStock': '${optimization.currentStock} units',
        'formattedOptimalStock': '${optimization.optimalStock} units',
        'riskLevel': _getRiskLevel(
          optimization.stockoutRisk,
          optimization.overstockRisk,
        ),
      };
    }).toList();
  }

  // Get performance metrics insights
  Map<String, dynamic> getPerformanceMetricsInsights() {
    if (_performanceMetrics == null) return {};

    final metrics = _performanceMetrics!;
    return {
      'totalRevenue': metrics.totalRevenue,
      'totalOrders': metrics.totalOrders,
      'averageOrderValue': metrics.averageOrderValue,
      'conversionRate': metrics.conversionRate,
      'cartAbandonmentRate': metrics.cartAbandonmentRate,
      'customerSatisfactionScore': metrics.customerSatisfactionScore,
      'activeUsers': metrics.activeUsers,
      'newUsers': metrics.newUsers,
      'retentionRate': metrics.retentionRate,
      'churnRate': metrics.churnRate,
      'formattedRevenue': 'TZS ${metrics.totalRevenue.toStringAsFixed(0)}',
      'formattedAverageOrder':
          'TZS ${metrics.averageOrderValue.toStringAsFixed(0)}',
      'formattedConversionRate':
          '${(metrics.conversionRate * 100).toStringAsFixed(1)}%',
      'formattedAbandonmentRate':
          '${(metrics.cartAbandonmentRate * 100).toStringAsFixed(1)}%',
      'formattedSatisfactionScore':
          '${metrics.customerSatisfactionScore.toStringAsFixed(1)}/5',
      'formattedRetentionRate':
          '${(metrics.retentionRate * 100).toStringAsFixed(1)}%',
      'formattedChurnRate': '${(metrics.churnRate * 100).toStringAsFixed(1)}%',
    };
  }

  // Helper methods
  String _getConfidenceLevel(double confidence) {
    if (confidence >= 0.8) return 'High';
    if (confidence >= 0.6) return 'Medium';
    return 'Low';
  }

  String _getInventoryStatus(InventoryOptimization optimization) {
    if (optimization.stockoutRisk > 0.7) return 'Critical';
    if (optimization.stockoutRisk > 0.5) return 'Warning';
    if (optimization.overstockRisk > 0.7) return 'Overstocked';
    return 'Optimal';
  }

  String _getRiskLevel(double stockoutRisk, double overstockRisk) {
    if (stockoutRisk > 0.7 || overstockRisk > 0.7) return 'High';
    if (stockoutRisk > 0.5 || overstockRisk > 0.5) return 'Medium';
    return 'Low';
  }

  // Get top performing categories
  List<Map<String, dynamic>> getTopPerformingCategories() {
    if (_performanceMetrics == null) return [];

    final categories =
        _performanceMetrics!.categoryPerformance.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

    return categories.take(5).map((entry) {
      return {
        'category': entry.key,
        'performance': entry.value,
        'formattedPerformance': '${(entry.value * 100).toStringAsFixed(1)}%',
      };
    }).toList();
  }

  // Get top performing products
  List<Map<String, dynamic>> getTopPerformingProducts() {
    if (_performanceMetrics == null) return [];

    final products =
        _performanceMetrics!.productPerformance.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

    return products.take(10).map((entry) {
      return {
        'productId': entry.key,
        'performance': entry.value,
        'formattedPerformance': '${(entry.value * 100).toStringAsFixed(1)}%',
      };
    }).toList();
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Refresh all data
  Future<void> refresh() async {
    await initializeAnalytics();
  }
}
