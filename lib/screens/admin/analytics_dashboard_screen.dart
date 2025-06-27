import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/analytics_provider.dart';
import '../../utils/constants.dart';
import '../../models/analytics_model.dart';

final analyticsProvider = ChangeNotifierProvider<AnalyticsProvider>(
  (ref) => AnalyticsProvider(),
);

class AnalyticsDashboardScreen extends ConsumerStatefulWidget {
  const AnalyticsDashboardScreen({super.key});

  @override
  ConsumerState<AnalyticsDashboardScreen> createState() =>
      _AnalyticsDashboardScreenState();
}

class _AnalyticsDashboardScreenState
    extends ConsumerState<AnalyticsDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(analyticsProvider).initializeAnalytics();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final analytics = ref.watch(analyticsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics Dashboard'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(analyticsProvider).refresh();
            },
          ),
        ],
      ),
      body: Builder(
        builder: (context) {
          if (analytics.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (analytics.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    analytics.error!,
                    style: TextStyle(color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => analytics.refresh(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              _buildOverviewCards(analytics),
              _buildTabBar(),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildPerformanceTab(analytics),
                    _buildCustomerBehaviorTab(analytics),
                    _buildSalesForecastTab(analytics),
                    _buildInventoryTab(analytics),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildOverviewCards(AnalyticsProvider provider) {
    final metrics = provider.getPerformanceMetricsInsights();
    if (metrics.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[50],
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Revenue',
                  metrics['formattedRevenue'] ?? 'TZS 0',
                  Icons.attach_money,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  'Orders',
                  '${metrics['totalOrders'] ?? 0}',
                  Icons.shopping_cart,
                  Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Conversion',
                  metrics['formattedConversionRate'] ?? '0%',
                  Icons.trending_up,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  'Satisfaction',
                  metrics['formattedSatisfactionScore'] ?? '0/5',
                  Icons.star,
                  Colors.purple,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: AppColors.primary,
        unselectedLabelColor: Colors.grey,
        indicatorColor: AppColors.primary,
        isScrollable: true,
        tabs: const [
          Tab(text: 'Performance'),
          Tab(text: 'Customers'),
          Tab(text: 'Forecasts'),
          Tab(text: 'Inventory'),
        ],
      ),
    );
  }

  Widget _buildPerformanceTab(AnalyticsProvider provider) {
    final metrics = provider.getPerformanceMetricsInsights();
    if (metrics.isEmpty) {
      return const Center(child: Text('No performance data available'));
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildPerformanceSection('Revenue & Orders', [
          _buildMetricRow(
            'Total Revenue',
            metrics['formattedRevenue'] ?? 'TZS 0',
          ),
          _buildMetricRow('Total Orders', '${metrics['totalOrders'] ?? 0}'),
          _buildMetricRow(
            'Average Order Value',
            metrics['formattedAverageOrder'] ?? 'TZS 0',
          ),
        ]),
        const SizedBox(height: 16),
        _buildPerformanceSection('Conversion & Engagement', [
          _buildMetricRow(
            'Conversion Rate',
            metrics['formattedConversionRate'] ?? '0%',
          ),
          _buildMetricRow(
            'Cart Abandonment',
            metrics['formattedAbandonmentRate'] ?? '0%',
          ),
          _buildMetricRow(
            'Customer Satisfaction',
            metrics['formattedSatisfactionScore'] ?? '0/5',
          ),
        ]),
        const SizedBox(height: 16),
        _buildPerformanceSection('User Metrics', [
          _buildMetricRow('Active Users', '${metrics['activeUsers'] ?? 0}'),
          _buildMetricRow('New Users', '${metrics['newUsers'] ?? 0}'),
          _buildMetricRow(
            'Retention Rate',
            metrics['formattedRetentionRate'] ?? '0%',
          ),
          _buildMetricRow('Churn Rate', metrics['formattedChurnRate'] ?? '0%'),
        ]),
        const SizedBox(height: 16),
        _buildTopPerformersSection(provider),
      ],
    );
  }

  Widget _buildCustomerBehaviorTab(AnalyticsProvider provider) {
    final behavior = provider.customerBehavior;
    if (behavior == null) {
      return const Center(child: Text('No customer behavior data available'));
    }

    final segmentInsights = provider.getCustomerSegmentInsights();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildCustomerSegmentCard(segmentInsights),
        const SizedBox(height: 16),
        _buildCustomerMetricsSection(behavior),
        const SizedBox(height: 16),
        _buildCustomerPreferencesSection(behavior),
      ],
    );
  }

  Widget _buildSalesForecastTab(AnalyticsProvider provider) {
    final forecasts = provider.getSalesForecastInsights();

    if (forecasts.isEmpty) {
      return const Center(child: Text('No sales forecast data available'));
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [...forecasts.map((forecast) => _buildForecastCard(forecast))],
    );
  }

  Widget _buildInventoryTab(AnalyticsProvider provider) {
    final optimizations = provider.getInventoryOptimizationInsights();

    if (optimizations.isEmpty) {
      return const Center(
        child: Text('No inventory optimization data available'),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ...optimizations.map(
          (optimization) => _buildInventoryCard(optimization),
        ),
      ],
    );
  }

  Widget _buildPerformanceSection(String title, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildMetricRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildTopPerformersSection(AnalyticsProvider provider) {
    final topCategories = provider.getTopPerformingCategories();
    final topProducts = provider.getTopPerformingProducts();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Top Performers',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'Top Categories',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            ...topCategories
                .take(5)
                .map(
                  (category) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(category['category']),
                        Text(
                          category['formattedPerformance'],
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            const SizedBox(height: 16),
            const Text(
              'Top Products',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            ...topProducts
                .take(5)
                .map(
                  (product) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(product['productId']),
                        Text(
                          product['formattedPerformance'],
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerSegmentCard(Map<String, dynamic> insights) {
    if (insights.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Color(insights['color'] ?? 0xFF4CAF50),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        insights['title'] ?? 'Customer Segment',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        insights['description'] ?? '',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Recommendations:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            ...(insights['recommendations'] as List<dynamic>? ?? []).map(
              (rec) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(rec.toString())),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerMetricsSection(CustomerBehavior behavior) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Customer Metrics',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildMetricRow('Total Sessions', '${behavior.totalSessions}'),
            _buildMetricRow('Total Page Views', '${behavior.totalPageViews}'),
            _buildMetricRow(
              'Total Product Views',
              '${behavior.totalProductViews}',
            ),
            _buildMetricRow('Total Add to Cart', '${behavior.totalAddToCart}'),
            _buildMetricRow('Total Purchases', '${behavior.totalPurchases}'),
            _buildMetricRow(
              'Average Session Duration',
              '${behavior.averageSessionDuration.toStringAsFixed(0)}s',
            ),
            _buildMetricRow(
              'Average Order Value',
              'TZS ${behavior.averageOrderValue.toStringAsFixed(0)}',
            ),
            _buildMetricRow(
              'Lifetime Value',
              'TZS ${behavior.lifetimeValue.toStringAsFixed(0)}',
            ),
            _buildMetricRow(
              'Days Since Last Purchase',
              '${behavior.daysSinceLastPurchase}',
            ),
            _buildMetricRow(
              'Churn Probability',
              '${(behavior.churnProbability * 100).toStringAsFixed(1)}%',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerPreferencesSection(CustomerBehavior behavior) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Customer Preferences',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'Favorite Categories:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            ...behavior.favoriteCategories.map(
              (category) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('• $category'),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Favorite Products:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            ...behavior.favoriteProducts
                .take(5)
                .map(
                  (product) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text('• $product'),
                  ),
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildForecastCard(Map<String, dynamic> forecast) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  forecast['date'].toString().split(' ')[0],
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getConfidenceColor(forecast['confidence']),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    forecast['confidenceLevel'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Predicted Revenue',
                        style: TextStyle(color: Colors.grey),
                      ),
                      Text(
                        forecast['formattedRevenue'],
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Predicted Units',
                        style: TextStyle(color: Colors.grey),
                      ),
                      Text(
                        forecast['formattedUnits'],
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (forecast['productId'] != null) ...[
              const SizedBox(height: 8),
              Text(
                'Product: ${forecast['productId']}',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
            if (forecast['category'] != null) ...[
              Text(
                'Category: ${forecast['category']}',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInventoryCard(Map<String, dynamic> optimization) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    optimization['productName'],
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(optimization['status']),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    optimization['status'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Current Stock',
                        style: TextStyle(color: Colors.grey),
                      ),
                      Text(
                        optimization['formattedCurrentStock'],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Optimal Stock',
                        style: TextStyle(color: Colors.grey),
                      ),
                      Text(
                        optimization['formattedOptimalStock'],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Stockout Risk',
                        style: TextStyle(color: Colors.grey),
                      ),
                      Text(
                        '${(optimization['stockoutRisk'] * 100).toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color:
                              optimization['stockoutRisk'] > 0.5
                                  ? Colors.red
                                  : Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Overstock Risk',
                        style: TextStyle(color: Colors.grey),
                      ),
                      Text(
                        '${(optimization['overstockRisk'] * 100).toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color:
                              optimization['overstockRisk'] > 0.5
                                  ? Colors.orange
                                  : Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (optimization['recommendations'] > 0) ...[
              const SizedBox(height: 8),
              Text(
                '${optimization['recommendations']} recommendations available',
                style: TextStyle(
                  color: Colors.blue[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 0.8) return Colors.green;
    if (confidence >= 0.6) return Colors.orange;
    return Colors.red;
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'critical':
        return Colors.red;
      case 'warning':
        return Colors.orange;
      case 'overstocked':
        return Colors.purple;
      case 'optimal':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
