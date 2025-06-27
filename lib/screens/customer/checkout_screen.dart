import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/enhanced_payment_model.dart' as enhanced;
import '../../models/order_model.dart';
import '../../models/address_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/enhanced_payment_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/address_provider.dart';
import 'payment_methods_screen.dart';
import 'address_book_screen.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  AddressModel? _selectedAddress;
  enhanced.PaymentMethod? _selectedPaymentMethod;
  bool _hasAttemptedToLoadPaymentMethods = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDefaultAddress();
      _loadPaymentMethods();
    });
  }

  Future<void> _loadDefaultAddress() async {
    final user = ref.read(currentUserProvider);
    if (user != null) {
      final defaultAddress = await ref
          .read(addressProvider.notifier)
          .getDefaultAddress(user.id);
      if (defaultAddress != null && mounted) {
        setState(() => _selectedAddress = defaultAddress);
      }
    }
  }

  Future<void> _loadPaymentMethods() async {
    final user = ref.read(currentUserProvider);
    print('CheckoutScreen: _loadPaymentMethods called for user: ${user?.id}');
    if (user != null) {
      try {
        await ref
            .read(enhancedPaymentProvider.notifier)
            .loadPaymentMethods(user.id);
        print('CheckoutScreen: Payment methods loaded successfully');
      } catch (e) {
        print('CheckoutScreen: Error loading payment methods: $e');
        // Reset the flag so we can retry
        setState(() {
          _hasAttemptedToLoadPaymentMethods = false;
        });
      }
    } else {
      print('CheckoutScreen: No user available for loading payment methods');
      // Reset the flag so we can retry when user becomes available
      setState(() {
        _hasAttemptedToLoadPaymentMethods = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final cart = ref.watch(cartProvider);
    final paymentState = ref.watch(enhancedPaymentProvider);
    final theme = Theme.of(context);

    print(
      'CheckoutScreen: Build - User: ${user?.id}, Payment methods: ${paymentState.paymentMethods.length}, Loading: ${paymentState.isLoading}, Error: ${paymentState.error}',
    );

    // Load payment methods if user is available but payment methods haven't been loaded
    if (user != null &&
        paymentState.paymentMethods.isEmpty &&
        !paymentState.isLoading &&
        paymentState.error == null &&
        !_hasAttemptedToLoadPaymentMethods) {
      print('CheckoutScreen: Triggering payment methods load');
      _hasAttemptedToLoadPaymentMethods = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadPaymentMethods();
      });
    }

    if (user == null || cart.items.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Checkout')),
        body: const Center(child: Text('No items in cart')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout'), elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order Summary
            _buildOrderSummary(cart, theme),
            const SizedBox(height: 24),

            // Delivery Address
            _buildDeliveryAddressSection(theme, user),
            const SizedBox(height: 24),

            // Payment Method
            _buildPaymentMethodSection(paymentState, theme),
            const SizedBox(height: 24),

            // Order Total
            _buildOrderTotal(cart, theme),
            const SizedBox(height: 32),

            // Place Order Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: paymentState.isLoading ? null : _placeOrder,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: theme.colorScheme.primary,
                ),
                child:
                    paymentState.isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                          'Place Order - TZS ${cart.total.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderSummary(CartState cart, ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order Summary',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...cart.items.map(
              (item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '${item.name} x${item.quantity}',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                    Text(
                      'TZS ${(item.price * item.quantity).toStringAsFixed(0)}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'TZS ${cart.total.toStringAsFixed(0)}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryAddressSection(ThemeData theme, user) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Delivery Address',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () => _navigateToAddressBook(context, user),
                  child: Text(_selectedAddress == null ? 'Add' : 'Change'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_selectedAddress != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _getAddressIcon(_selectedAddress!.type),
                          size: 16,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _selectedAddress!.displayName,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        if (_selectedAddress!.isDefault) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Default',
                              style: TextStyle(
                                color: theme.colorScheme.primary,
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _selectedAddress!.fullName,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    Text(_selectedAddress!.phoneNumber),
                    Text(_selectedAddress!.fullAddress),
                    if (_selectedAddress!.instructions != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Instructions: ${_selectedAddress!.instructions}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.location_off,
                      size: 48,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 8),
                    const Text('No delivery address selected'),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () => _navigateToAddressBook(context, user),
                      child: const Text('Select Address'),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodSection(
    EnhancedPaymentState paymentState,
    ThemeData theme,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Payment Method',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () => _navigateToPaymentMethods(context),
                  child: const Text('Manage'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (paymentState.isLoading)
              const CircularProgressIndicator()
            else if (paymentState.error != null)
              Column(
                children: [
                  Text('Error loading payment methods: ${paymentState.error}'),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _hasAttemptedToLoadPaymentMethods = false;
                      });
                      ref.read(enhancedPaymentProvider.notifier).clearError();
                      _loadPaymentMethods();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              )
            else if (paymentState.paymentMethods.isEmpty)
              Column(
                children: [
                  const Text('No payment methods available'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _navigateToPaymentMethods(context),
                          child: const Text('Add Payment Method'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _hasAttemptedToLoadPaymentMethods = false;
                          });
                          _loadPaymentMethods();
                        },
                        child: const Text('Refresh'),
                      ),
                    ],
                  ),
                ],
              )
            else
              Builder(
                builder: (context) {
                  // Auto-select default payment method
                  _selectedPaymentMethod ??= paymentState.paymentMethods
                      .firstWhere(
                        (method) => method.isDefault,
                        orElse: () => paymentState.paymentMethods.first,
                      );

                  return Column(
                    children: [
                      ...paymentState.paymentMethods.map(
                        (method) => RadioListTile<enhanced.PaymentMethod>(
                          title: Text(_getPaymentMethodDisplayName(method)),
                          value: method,
                          groupValue: _selectedPaymentMethod,
                          onChanged:
                              (value) => setState(
                                () => _selectedPaymentMethod = value,
                              ),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      // Cash on Delivery option
                      RadioListTile<enhanced.PaymentMethod>(
                        title: const Text('Cash on Delivery'),
                        subtitle: const Text('Pay when you receive your order'),
                        value: enhanced.PaymentMethod(
                          id: 'cod',
                          userId: '',
                          type: 'cash_on_delivery',
                          addedAt: DateTime.now(),
                        ),
                        groupValue: _selectedPaymentMethod,
                        onChanged:
                            (value) =>
                                setState(() => _selectedPaymentMethod = value),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ],
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  String _getPaymentMethodDisplayName(enhanced.PaymentMethod method) {
    switch (method.type) {
      case 'card':
        return '${method.cardBrand ?? 'Card'} •••• ${method.last4 ?? ''}';
      case 'mobile_money':
        return 'Mobile Money (${method.accountNumber ?? ''})';
      case 'bank_transfer':
        return 'Bank Transfer (${method.accountName ?? ''})';
      case 'cash_on_delivery':
        return 'Cash on Delivery';
      default:
        return method.type;
    }
  }

  Widget _buildOrderTotal(CartState cart, ThemeData theme) {
    const deliveryFee = 5000.0; // TZS 5,000 delivery fee
    final total = cart.total + deliveryFee;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Subtotal'),
                Text('TZS ${cart.total.toStringAsFixed(0)}'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Delivery Fee'),
                Text('TZS ${deliveryFee.toStringAsFixed(0)}'),
              ],
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'TZS ${total.toStringAsFixed(0)}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _placeOrder() async {
    if (_selectedPaymentMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a payment method')),
      );
      return;
    }

    if (_selectedAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a delivery address')),
      );
      return;
    }

    final user = ref.read(currentUserProvider);
    final cart = ref.read(cartProvider);

    if (user == null || cart.items.isEmpty) return;

    try {
      print('CheckoutScreen: Creating order for user: ${user.id}');
      print('CheckoutScreen: Cart items: ${cart.items.length}');
      
      // Create order
      final order = await ref
          .read(orderProvider.notifier)
          .createOrder(
            customerId: user.id,
            items: cart.items,
            deliveryAddress: _selectedAddress!.fullAddress,
            deliveryInstructions: _selectedAddress!.instructions,
          );

      print('CheckoutScreen: Order created successfully with ID: ${order.id}');

      // Clear cart
      ref.read(cartProvider.notifier).clearCart();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order placed successfully!')),
        );
        context.go('/customer/history');
      }
    } catch (e) {
      print('CheckoutScreen: Error creating order: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error placing order: $e')));
      }
    }
  }

  void _navigateToAddressBook(BuildContext context, user) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddressBookScreen()),
    );

    // Reload default address after returning from address book
    if (result != null) {
      _loadDefaultAddress();
    }
  }

  void _navigateToPaymentMethods(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PaymentMethodsScreen()),
    );

    // Reload payment methods after returning from payment methods screen
    if (result != null) {
      _loadPaymentMethods();
    }
  }

  IconData _getAddressIcon(AddressType type) {
    switch (type) {
      case AddressType.home:
        return Icons.home;
      case AddressType.work:
        return Icons.work;
      case AddressType.other:
        return Icons.location_on;
    }
  }
}
