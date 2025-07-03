import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import 'pending_approval_screen.dart';
import '../../providers/analytics_provider.dart';
import '../../services/product_service.dart';

class SalesAnalyticsScreen extends ConsumerStatefulWidget {
  const SalesAnalyticsScreen({super.key});

  @override
  ConsumerState<SalesAnalyticsScreen> createState() =>
      _SalesAnalyticsScreenState();
}

class _SalesAnalyticsScreenState extends ConsumerState<SalesAnalyticsScreen> {
  String _selectedPeriod = 'This Month';
  final List<String> _periods = [
    'This Week',
    'This Month',
    'Last 3 Months',
    'This Year',
  ];

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    if (user?.role == 'seller' && user?.status != 'approved') {
      return const PendingApprovalScreen();
    }
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final analyticsAsync = ref.watch(sellerAnalyticsProvider(user?.id ?? ''));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales Analytics'),
        backgroundColor: colorScheme.surface,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.date_range),
            onSelected: (value) {
              setState(() {
                _selectedPeriod = value;
              });
            },
            itemBuilder:
                (context) =>
                    _periods.map((period) {
                      return PopupMenuItem(value: period, child: Text(period));
                    }).toList(),
          ),
        ],
      ),
      body: analyticsAsync.when(
        data:
            (analytics) => SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Period selector
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer.withValues(
                        alpha: 0.3,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.analytics, color: colorScheme.primary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Analytics Overview',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                _selectedPeriod,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Key metrics
                  Text(
                    'Key Metrics',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricCard(
                          'Total Sales',
                          'TZS ${analytics.totalSales.toStringAsFixed(0)}',
                          '',
                          Icons.trending_up,
                          Colors.green,
                          true,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildMetricCard(
                          'Orders',
                          analytics.totalOrders.toString(),
                          '',
                          Icons.shopping_bag,
                          Colors.blue,
                          true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricCard(
                          'Avg Order',
                          'TZS ${analytics.avgOrderValue.toStringAsFixed(0)}',
                          '',
                          Icons.receipt,
                          Colors.orange,
                          true,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildMetricCard(
                          'Unique Customers',
                          analytics.uniqueCustomers.toString(),
                          '',
                          Icons.person,
                          Colors.purple,
                          true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  // Sales chart
                  Text(
                    'Sales Trend',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    height: 250,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: colorScheme.outline.withValues(alpha: 0.2),
                      ),
                    ),
                    child: LineChart(
                      LineChartData(
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          horizontalInterval: 20000,
                          getDrawingHorizontalLine: (value) {
                            return FlLine(
                              color: colorScheme.outline.withValues(alpha: 0.2),
                              strokeWidth: 1,
                            );
                          },
                        ),
                        titlesData: FlTitlesData(
                          show: true,
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 30,
                              interval: 1,
                              getTitlesWidget: (double value, TitleMeta meta) {
                                final weeks =
                                    analytics.salesByWeek.keys.toList()..sort();
                                if (value.toInt() < weeks.length) {
                                  return SideTitleWidget(
                                    meta: meta,
                                    child: Text(
                                      weeks[value.toInt()],
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  );
                                }
                                return const SizedBox.shrink();
                              },
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              interval: 20000,
                              getTitlesWidget: (double value, TitleMeta meta) {
                                return Text(
                                  '${(value / 1000).toInt()}K',
                                  style: const TextStyle(fontSize: 12),
                                );
                              },
                              reservedSize: 42,
                            ),
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        minX: 0,
                        maxX: (analytics.salesByWeek.length - 1).toDouble(),
                        minY: 0,
                        maxY:
                            analytics.salesByWeek.values.isNotEmpty
                                ? analytics.salesByWeek.values.reduce(
                                      (a, b) => a > b ? a : b,
                                    ) *
                                    1.2
                                : 1000,
                        lineBarsData: [
                          LineChartBarData(
                            spots: [
                              for (
                                var i = 0;
                                i < analytics.salesByWeek.length;
                                i++
                              )
                                FlSpot(
                                  i.toDouble(),
                                  analytics.salesByWeek.values.toList()[i],
                                ),
                            ],
                            isCurved: true,
                            gradient: LinearGradient(
                              colors: [
                                colorScheme.primary,
                                colorScheme.primary.withOpacity(0.3),
                              ],
                            ),
                            barWidth: 3,
                            isStrokeCapRound: true,
                            dotData: FlDotData(show: true),
                            belowBarData: BarAreaData(
                              show: true,
                              gradient: LinearGradient(
                                colors: [
                                  colorScheme.primary.withOpacity(0.3),
                                  colorScheme.primary.withOpacity(0.1),
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Top products
                  Text(
                    'Top Selling Products',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildTopProductsList(analytics.topProducts),
                ],
              ),
            ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error loading analytics: $e')),
      ),
    );
  }

  Widget _buildMetricCard(
    String title,
    String value,
    String change,
    IconData icon,
    Color color,
    bool isPositive,
  ) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: (isPositive ? Colors.green : Colors.red).withValues(
                      alpha: 0.1,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    change,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: isPositive ? Colors.green : Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopProductsList(List<Map<String, dynamic>> products) {
    if (products.isEmpty) {
      return const Text('No sales data yet.');
    }
    return Card(
      child: Column(
        children:
            products.asMap().entries.map((entry) {
              final index = entry.key;
              final product = entry.value;
              return FutureBuilder(
                future: ProductService().getProduct(product['productId']),
                builder: (context, snapshot) {
                  final productName =
                      snapshot.hasData
                          ? snapshot.data?.name ?? product['productId']
                          : product['productId'];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          Theme.of(context).colorScheme.primaryContainer,
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          color:
                              Theme.of(context).colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      productName,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text('Units: ${product['units'] ?? 0}'),
                    trailing: Text(
                      'TZS ${product['revenue']?.toStringAsFixed(0) ?? '0'}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                  );
                },
              );
            }).toList(),
      ),
    );
  }
}
