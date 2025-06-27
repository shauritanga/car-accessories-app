import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/product_provider.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  bool _isLoading = true;
  Map<String, dynamic> _stats = {};
  List<Map<String, dynamic>> _recentActivities = [];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);

    try {
      final firestore = FirebaseFirestore.instance;

      // Load statistics
      final stats = await _loadStatistics(firestore);

      // Load recent activities
      final activities = await _loadRecentActivities(firestore);

      setState(() {
        _stats = stats;
        _recentActivities = activities;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading dashboard: $e')));
      }
    }
  }

  Future<Map<String, dynamic>> _loadStatistics(
    FirebaseFirestore firestore,
  ) async {
    final stats = <String, dynamic>{};

    try {
      // User statistics
      final usersSnapshot = await firestore.collection('users').get();
      final customers =
          usersSnapshot.docs
              .where((doc) => doc.data()['role'] == 'customer')
              .length;
      final sellers =
          usersSnapshot.docs
              .where((doc) => doc.data()['role'] == 'seller')
              .length;
      final admins =
          usersSnapshot.docs
              .where((doc) => doc.data()['role'] == 'admin')
              .length;

      stats['totalUsers'] = usersSnapshot.docs.length;
      stats['customers'] = customers;
      stats['sellers'] = sellers;
      stats['admins'] = admins;

      // Order statistics
      final ordersSnapshot = await firestore.collection('orders').get();
      final totalOrders = ordersSnapshot.docs.length;
      final pendingOrders =
          ordersSnapshot.docs
              .where((doc) => doc.data()['status'] == 'pending')
              .length;
      final completedOrders =
          ordersSnapshot.docs
              .where((doc) => doc.data()['status'] == 'delivered')
              .length;

      double totalRevenue = 0;
      for (final doc in ordersSnapshot.docs) {
        totalRevenue += (doc.data()['total'] ?? 0).toDouble();
      }

      stats['totalOrders'] = totalOrders;
      stats['pendingOrders'] = pendingOrders;
      stats['completedOrders'] = completedOrders;
      stats['totalRevenue'] = totalRevenue;

      // Product statistics
      final productsSnapshot = await firestore.collection('products').get();
      stats['totalProducts'] = productsSnapshot.docs.length;

      // Active sellers (with products)
      final activeSellers = <String>{};
      for (final doc in productsSnapshot.docs) {
        activeSellers.add(doc.data()['sellerId'] ?? '');
      }
      stats['activeSellers'] = activeSellers.length;
    } catch (e) {
      print('Error loading statistics: $e');
    }

    return stats;
  }

  Future<List<Map<String, dynamic>>> _loadRecentActivities(
    FirebaseFirestore firestore,
  ) async {
    final activities = <Map<String, dynamic>>[];

    try {
      // Recent orders
      final recentOrders =
          await firestore
              .collection('orders')
              .orderBy('createdAt', descending: true)
              .limit(5)
              .get();

      for (final doc in recentOrders.docs) {
        final data = doc.data();
        activities.add({
          'type': 'order',
          'title': 'New Order #${doc.id.substring(0, 8)}',
          'description': 'Order placed by customer',
          'timestamp': data['createdAt'],
          'status': data['status'],
          'amount': data['total'],
        });
      }

      // Recent user registrations
      final recentUsers =
          await firestore
              .collection('users')
              .orderBy('createdAt', descending: true)
              .limit(3)
              .get();

      for (final doc in recentUsers.docs) {
        final data = doc.data();
        activities.add({
          'type': 'user',
          'title': 'New ${data['role']} registered',
          'description': '${data['name'] ?? 'User'} joined the platform',
          'timestamp': data['createdAt'],
          'role': data['role'],
        });
      }

      // Sort by timestamp
      activities.sort((a, b) {
        final aTime = a['timestamp'] as Timestamp?;
        final bTime = b['timestamp'] as Timestamp?;
        if (aTime == null || bTime == null) return 0;
        return bTime.compareTo(aTime);
      });
    } catch (e) {
      print('Error loading activities: $e');
    }

    return activities.take(8).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final user = ref.watch(currentUserProvider);

    if (user?.role != 'admin') {
      return Scaffold(
        appBar: AppBar(title: const Text('Access Denied')),
        body: const Center(
          child: Text('You do not have permission to access this area.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboardData,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authProvider.notifier).signOut();
              if (mounted) {
                Navigator.of(context).pushReplacementNamed('/login');
              }
            },
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                onRefresh: _loadDashboardData,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Welcome Section
                      _buildWelcomeSection(theme, user),
                      const SizedBox(height: 24),

                      // Statistics Cards
                      _buildStatisticsSection(theme),
                      const SizedBox(height: 24),

                      // Quick Actions
                      _buildQuickActionsSection(theme),
                      const SizedBox(height: 24),

                      // Recent Activities
                      _buildRecentActivitiesSection(theme),
                    ],
                  ),
                ),
              ),
    );
  }

  Widget _buildWelcomeSection(ThemeData theme, user) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.white.withOpacity(0.2),
                child: Icon(
                  Icons.admin_panel_settings,
                  size: 30,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back, Admin!',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Manage your car accessories platform',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Last updated: ${DateFormat('MMM dd, yyyy • hh:mm a').format(DateTime.now())}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.white.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Platform Statistics',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.5,
          children: [
            _buildStatCard(
              'Total Users',
              '${_stats['totalUsers'] ?? 0}',
              Icons.people,
              Colors.blue,
              theme,
            ),
            _buildStatCard(
              'Total Orders',
              '${_stats['totalOrders'] ?? 0}',
              Icons.shopping_cart,
              Colors.green,
              theme,
            ),
            _buildStatCard(
              'Total Revenue',
              'TZS ${NumberFormat('#,##0').format(_stats['totalRevenue'] ?? 0)}',
              Icons.attach_money,
              Colors.orange,
              theme,
            ),
            _buildStatCard(
              'Active Sellers',
              '${_stats['activeSellers'] ?? 0}',
              Icons.store,
              Colors.purple,
              theme,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
    ThemeData theme,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const Spacer(),
              Icon(Icons.trending_up, color: color.withOpacity(0.7), size: 16),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 2.5,
          children: [
            _buildActionCard(
              'Manage Users',
              Icons.people,
              Colors.blue,
              () => Navigator.pushNamed(context, '/admin/users'),
              theme,
            ),
            _buildActionCard(
              'View Orders',
              Icons.receipt_long,
              Colors.green,
              () => Navigator.pushNamed(context, '/admin/orders'),
              theme,
            ),
            _buildActionCard(
              'Product Management',
              Icons.inventory_2,
              Colors.orange,
              () => Navigator.pushNamed(context, '/admin/products'),
              theme,
            ),
            _buildActionCard(
              'Analytics',
              Icons.bar_chart,
              Colors.purple,
              () => Navigator.pushNamed(context, '/admin/analytics'),
              theme,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
    ThemeData theme,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: color.withOpacity(0.7),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivitiesSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Activities',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        if (_recentActivities.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.history, size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No recent activities',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _recentActivities.length,
            itemBuilder: (context, index) {
              final activity = _recentActivities[index];
              return _buildActivityCard(activity, theme);
            },
          ),
      ],
    );
  }

  Widget _buildActivityCard(Map<String, dynamic> activity, ThemeData theme) {
    final type = activity['type'] as String?;
    final title = activity['title'] as String?;
    final description = activity['description'] as String?;
    final timestamp = activity['timestamp'] as Timestamp?;

    IconData icon;
    Color color;

    switch (type) {
      case 'order':
        icon = Icons.shopping_cart;
        color = Colors.green;
        break;
      case 'user':
        icon = Icons.person_add;
        color = Colors.blue;
        break;
      default:
        icon = Icons.info;
        color = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(
          title ?? 'Activity',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(description ?? ''),
            if (timestamp != null)
              Text(
                DateFormat('MMM dd, hh:mm a').format(timestamp.toDate()),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
          ],
        ),
        trailing:
            activity['amount'] != null
                ? Text(
                  'TZS ${NumberFormat('#,##0').format(activity['amount'])}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                )
                : null,
      ),
    );
  }
}
