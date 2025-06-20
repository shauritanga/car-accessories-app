import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/order_model.dart';
import '../../providers/order_provider.dart';
import '../../providers/auth_provider.dart';
import 'enhanced_order_details_screen.dart';

class EnhancedOrderHistoryScreen extends ConsumerStatefulWidget {
  const EnhancedOrderHistoryScreen({super.key});

  @override
  ConsumerState<EnhancedOrderHistoryScreen> createState() => _EnhancedOrderHistoryScreenState();
}

class _EnhancedOrderHistoryScreenState extends ConsumerState<EnhancedOrderHistoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedStatus = 'all';
  String _selectedTimeRange = 'all';
  String _sortBy = 'newest';
  List<OrderModel> _filteredOrders = [];
  List<OrderModel> _allOrders = [];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = ref.watch(currentUserProvider);

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in to view order history')),
      );
    }

    final ordersAsync = ref.watch(orderStreamProviderSimple(
      OrderFilter(userId: user.id, role: 'customer'),
    ));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Order History'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterBottomSheet(context, theme),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter Bar
          _buildSearchAndFilterBar(theme),
          
          // Order Statistics
          _buildOrderStatistics(theme),
          
          // Orders List
          Expanded(
            child: ordersAsync.when(
              data: (orders) {
                _allOrders = orders;
                _applyFilters();
                
                if (_filteredOrders.isEmpty) {
                  return _buildEmptyState(theme);
                }
                
                return _buildOrdersList(theme);
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text('Error loading orders: $error'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => ref.refresh(orderStreamProviderSimple(
                        OrderFilter(userId: user.id, role: 'customer'),
                      )),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilterBar(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Search Bar
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search orders by ID, product, or status...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _applyFilters();
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.grey[100],
            ),
            onChanged: (value) => _applyFilters(),
          ),
          
          const SizedBox(height: 12),
          
          // Quick Filters
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('All', _selectedStatus == 'all', () {
                  setState(() => _selectedStatus = 'all');
                  _applyFilters();
                }),
                const SizedBox(width: 8),
                _buildFilterChip('Pending', _selectedStatus == 'pending', () {
                  setState(() => _selectedStatus = 'pending');
                  _applyFilters();
                }),
                const SizedBox(width: 8),
                _buildFilterChip('Processing', _selectedStatus == 'processing', () {
                  setState(() => _selectedStatus = 'processing');
                  _applyFilters();
                }),
                const SizedBox(width: 8),
                _buildFilterChip('Shipped', _selectedStatus == 'shipped', () {
                  setState(() => _selectedStatus = 'shipped');
                  _applyFilters();
                }),
                const SizedBox(width: 8),
                _buildFilterChip('Delivered', _selectedStatus == 'delivered', () {
                  setState(() => _selectedStatus = 'delivered');
                  _applyFilters();
                }),
                const SizedBox(width: 8),
                _buildFilterChip('Cancelled', _selectedStatus == 'cancelled', () {
                  setState(() => _selectedStatus = 'cancelled');
                  _applyFilters();
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[700],
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildOrderStatistics(ThemeData theme) {
    if (_allOrders.isEmpty) return const SizedBox.shrink();

    final totalOrders = _allOrders.length;
    final totalSpent = _allOrders.fold(0.0, (sum, order) => sum + order.total);
    final pendingOrders = _allOrders.where((o) => o.status == 'pending').length;
    final deliveredOrders = _allOrders.where((o) => o.status == 'delivered').length;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Total Orders',
              totalOrders.toString(),
              Icons.receipt_long,
              Colors.blue,
              theme,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Total Spent',
              'TZS ${totalSpent.toStringAsFixed(0)}',
              Icons.attach_money,
              Colors.green,
              theme,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Pending',
              pendingOrders.toString(),
              Icons.pending,
              Colors.orange,
              theme,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Delivered',
              deliveredOrders.toString(),
              Icons.check_circle,
              Colors.green,
              theme,
            ),
          ),
        ],
      ),
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            _searchController.text.isNotEmpty || _selectedStatus != 'all'
                ? 'No orders match your filters'
                : 'No orders found',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchController.text.isNotEmpty || _selectedStatus != 'all'
                ? 'Try adjusting your search or filters'
                : 'Your order history will appear here',
            style: TextStyle(color: Colors.grey[500]),
          ),
          const SizedBox(height: 24),
          if (_searchController.text.isEmpty && _selectedStatus == 'all')
            ElevatedButton.icon(
              icon: const Icon(Icons.shopping_bag_outlined),
              label: const Text('Start Shopping'),
              onPressed: () => Navigator.pushNamed(context, '/product_list'),
            )
          else
            ElevatedButton.icon(
              icon: const Icon(Icons.clear),
              label: const Text('Clear Filters'),
              onPressed: () {
                setState(() {
                  _searchController.clear();
                  _selectedStatus = 'all';
                  _selectedTimeRange = 'all';
                });
                _applyFilters();
              },
            ),
        ],
      ),
    );
  }

  Widget _buildOrdersList(ThemeData theme) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredOrders.length,
      itemBuilder: (context, index) {
        final order = _filteredOrders[index];
        return _buildOrderCard(order, theme);
      },
    );
  }

  Widget _buildOrderCard(OrderModel order, ThemeData theme) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EnhancedOrderDetailsScreen(orderId: order.id),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Order Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Order #${order.shortId}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  _buildStatusChip(order.status),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Order Info
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('MMM dd, yyyy • hh:mm a').format(order.createdAt),
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  const Spacer(),
                  Text(
                    order.formattedTotal,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Items Summary
              Text(
                '${order.itemCount} item${order.itemCount != 1 ? 's' : ''}',
                style: TextStyle(color: Colors.grey[600]),
              ),
              
              if (order.trackingNumber != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.local_shipping, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      'Tracking: ${order.trackingNumber}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
              ],
              
              if (order.estimatedDeliveryDate != null && !order.isDelivered) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.schedule, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      order.estimatedDeliveryText,
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color backgroundColor;
    Color textColor;

    switch (status.toLowerCase()) {
      case 'pending':
        backgroundColor = Colors.orange[100]!;
        textColor = Colors.orange[800]!;
        break;
      case 'processing':
        backgroundColor = Colors.blue[100]!;
        textColor = Colors.blue[800]!;
        break;
      case 'shipped':
        backgroundColor = Colors.purple[100]!;
        textColor = Colors.purple[800]!;
        break;
      case 'delivered':
        backgroundColor = Colors.green[100]!;
        textColor = Colors.green[800]!;
        break;
      case 'cancelled':
        backgroundColor = Colors.red[100]!;
        textColor = Colors.red[800]!;
        break;
      default:
        backgroundColor = Colors.grey[100]!;
        textColor = Colors.grey[800]!;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showFilterBottomSheet(BuildContext context, ThemeData theme) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Filter Orders',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              
              // Time Range Filter
              Text(
                'Time Range',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  _buildFilterOption('All Time', _selectedTimeRange == 'all', () {
                    setModalState(() => _selectedTimeRange = 'all');
                  }),
                  _buildFilterOption('Last 30 Days', _selectedTimeRange == '30days', () {
                    setModalState(() => _selectedTimeRange = '30days');
                  }),
                  _buildFilterOption('Last 3 Months', _selectedTimeRange == '3months', () {
                    setModalState(() => _selectedTimeRange = '3months');
                  }),
                  _buildFilterOption('This Year', _selectedTimeRange == 'year', () {
                    setModalState(() => _selectedTimeRange = 'year');
                  }),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Sort Options
              Text(
                'Sort By',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  _buildFilterOption('Newest First', _sortBy == 'newest', () {
                    setModalState(() => _sortBy = 'newest');
                  }),
                  _buildFilterOption('Oldest First', _sortBy == 'oldest', () {
                    setModalState(() => _sortBy = 'oldest');
                  }),
                  _buildFilterOption('Highest Amount', _sortBy == 'amount_high', () {
                    setModalState(() => _sortBy = 'amount_high');
                  }),
                  _buildFilterOption('Lowest Amount', _sortBy == 'amount_low', () {
                    setModalState(() => _sortBy = 'amount_low');
                  }),
                ],
              ),
              
              const SizedBox(height: 32),
              
              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setModalState(() {
                          _selectedTimeRange = 'all';
                          _sortBy = 'newest';
                        });
                        setState(() {
                          _selectedTimeRange = 'all';
                          _sortBy = 'newest';
                        });
                        _applyFilters();
                      },
                      child: const Text('Reset'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _selectedTimeRange = _selectedTimeRange;
                          _sortBy = _sortBy;
                        });
                        _applyFilters();
                        Navigator.pop(context);
                      },
                      child: const Text('Apply'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterOption(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey[300]!,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[700],
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  void _applyFilters() {
    setState(() {
      _filteredOrders = _allOrders.where((order) {
        // Search filter
        final searchTerm = _searchController.text.toLowerCase();
        if (searchTerm.isNotEmpty) {
          final matchesSearch = order.id.toLowerCase().contains(searchTerm) ||
              order.status.toLowerCase().contains(searchTerm) ||
              order.shortId.toLowerCase().contains(searchTerm);
          if (!matchesSearch) return false;
        }

        // Status filter
        if (_selectedStatus != 'all' && order.status != _selectedStatus) {
          return false;
        }

        // Time range filter
        if (_selectedTimeRange != 'all') {
          final now = DateTime.now();
          final orderDate = order.createdAt;
          
          switch (_selectedTimeRange) {
            case '30days':
              if (now.difference(orderDate).inDays > 30) return false;
              break;
            case '3months':
              if (now.difference(orderDate).inDays > 90) return false;
              break;
            case 'year':
              if (orderDate.year != now.year) return false;
              break;
          }
        }

        return true;
      }).toList();

      // Apply sorting
      switch (_sortBy) {
        case 'newest':
          _filteredOrders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          break;
        case 'oldest':
          _filteredOrders.sort((a, b) => a.createdAt.compareTo(b.createdAt));
          break;
        case 'amount_high':
          _filteredOrders.sort((a, b) => b.total.compareTo(a.total));
          break;
        case 'amount_low':
          _filteredOrders.sort((a, b) => a.total.compareTo(b.total));
          break;
      }
    });
  }
}
