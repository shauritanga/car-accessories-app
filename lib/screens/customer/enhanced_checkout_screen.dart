import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/payment_model.dart';

import '../../models/shipping_model.dart';

import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/payment_provider.dart';
import '../../providers/order_provider.dart';
import '../../services/shipping_service.dart';
import '../../services/coupon_service.dart';

// import 'guest_checkout_screen.dart';
// import 'coupon_selection_screen.dart';

class EnhancedCheckoutScreen extends ConsumerStatefulWidget {
  const EnhancedCheckoutScreen({super.key});

  @override
  ConsumerState<EnhancedCheckoutScreen> createState() =>
      _EnhancedCheckoutScreenState();
}

class _EnhancedCheckoutScreenState
    extends ConsumerState<EnhancedCheckoutScreen> {
  PaymentMethodModel? _selectedPaymentMethod;
  ShippingMethod? _selectedShippingMethod;
  String? _appliedCouponCode;
  bool _isProcessingOrder = false;
  bool _agreeToTerms = false;

  final _couponController = TextEditingController();
  final _specialInstructionsController = TextEditingController();

  List<ShippingMethod> _availableShippingMethods = [];
  final ShippingService _shippingService = ShippingService();
  final CouponService _couponService = CouponService();

  @override
  void initState() {
    super.initState();
    _loadShippingMethods();
  }

  @override
  void dispose() {
    _couponController.dispose();
    _specialInstructionsController.dispose();
    super.dispose();
  }

  Future<void> _loadShippingMethods() async {
    try {
      final cart = ref.read(cartProvider);
      final totalWeight = cart.items.fold<double>(
        0.0,
        (sum, item) => sum + ((item.weight ?? 1.0) * item.quantity),
      );

      final methods = await _shippingService.getAvailableShippingMethods(
        city: 'Dar es Salaam', // This would come from user's address
        totalWeight: totalWeight,
        totalValue: cart.subtotal,
      );

      setState(() {
        _availableShippingMethods = methods;
        if (methods.isNotEmpty) {
          _selectedShippingMethod = methods.first;
          ref
              .read(cartProvider.notifier)
              .selectShippingMethod(methods.first.id, methods.first.cost);
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading shipping methods: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final cart = ref.watch(cartProvider);
    final theme = Theme.of(context);

    if (cart.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Checkout')),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text('Your cart is empty'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
        elevation: 0,
        actions: [
          if (user == null)
            TextButton(
              onPressed: () => _navigateToGuestCheckout(),
              child: const Text('Guest Checkout'),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order Summary with enhanced details
            _buildEnhancedOrderSummary(cart, theme),
            const SizedBox(height: 24),

            // Shipping Methods Selection
            _buildShippingMethodsSection(theme),
            const SizedBox(height: 24),

            // Delivery Address (if user is logged in)
            if (user != null) ...[
              _buildDeliveryAddressSection(theme, user),
              const SizedBox(height: 24),
            ],

            // Coupon/Promo Code Section
            _buildCouponSection(theme),
            const SizedBox(height: 24),

            // Payment Method Selection
            if (user != null) ...[
              _buildPaymentMethodSection(theme, user),
              const SizedBox(height: 24),
            ],

            // Special Instructions
            _buildSpecialInstructionsSection(theme),
            const SizedBox(height: 24),

            // Enhanced Order Total with Tax Breakdown
            _buildEnhancedOrderTotal(cart, theme),
            const SizedBox(height: 24),

            // Terms and Conditions
            _buildTermsAndConditions(theme),
            const SizedBox(height: 32),

            // Place Order Button
            _buildPlaceOrderButton(cart, theme),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedOrderSummary(CartState cart, ThemeData theme) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order Summary',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${cart.itemCount} items',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Items list
            ...cart.items.map(
              (item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Item image
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: 50,
                        height: 50,
                        color: Colors.grey[200],
                        child:
                            item.image != null
                                ? Image.network(item.image!, fit: BoxFit.cover)
                                : const Icon(Icons.image, color: Colors.grey),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Item details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (item.variant != null && item.variant != 'N/A')
                            Text(
                              'Variant: ${item.variant}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text('Qty: ${item.quantity}'),
                              const Spacer(),
                              if (item.hasDiscount) ...[
                                Text(
                                  item.formattedOriginalPrice,
                                  style: const TextStyle(
                                    decoration: TextDecoration.lineThrough,
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(width: 4),
                              ],
                              Text(
                                item.formattedTotalPrice,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            if (cart.hasSavedItems) ...[
              const SizedBox(height: 16),
              const Divider(),
              TextButton.icon(
                icon: const Icon(Icons.favorite_border),
                label: Text('${cart.savedItemCount} items saved for later'),
                onPressed: () {
                  // Navigate to saved items or show dialog
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildShippingMethodsSection(ThemeData theme) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Shipping Method',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            if (_availableShippingMethods.isEmpty)
              const Center(child: CircularProgressIndicator())
            else
              Column(
                children:
                    _availableShippingMethods.map((method) {
                      return RadioListTile<ShippingMethod>(
                        title: Text(method.name),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(method.description),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.access_time,
                                  size: 16,
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Delivery: ${method.estimatedDelivery}',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  method.formattedCost,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        value: method,
                        groupValue: _selectedShippingMethod,
                        onChanged: (value) {
                          setState(() => _selectedShippingMethod = value);
                          if (value != null) {
                            ref
                                .read(cartProvider.notifier)
                                .selectShippingMethod(value.id, value.cost);
                          }
                        },
                        contentPadding: EdgeInsets.zero,
                      );
                    }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryAddressSection(ThemeData theme, UserModel user) {
    // This would integrate with the user profile provider to get addresses
    return Card(
      elevation: 2,
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
                  onPressed: () {
                    // Navigate to address selection
                  },
                  child: const Text('Change'),
                ),
              ],
            ),
            const SizedBox(height: 12),
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
                        Icons.home,
                        size: 16,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Home',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
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
                  ),
                  const SizedBox(height: 8),
                  Text(
                    user.name ?? 'User Name',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  Text(user.phone ?? '+255 123 456 789'),
                  const Text('123 Main Street, Dar es Salaam, Tanzania'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCouponSection(ThemeData theme) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Promo Code / Coupon',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _couponController,
                    decoration: InputDecoration(
                      hintText: 'Enter promo code',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.local_offer),
                    ),
                    textCapitalization: TextCapitalization.characters,
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _applyCoupon,
                  child: const Text('Apply'),
                ),
              ],
            ),

            if (_appliedCouponCode != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green[300]!),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Colors.green[600],
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Coupon "$_appliedCouponCode" applied successfully!',
                        style: TextStyle(color: Colors.green[700]),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: _removeCoupon,
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 12),
            TextButton.icon(
              icon: const Icon(Icons.local_offer),
              label: const Text('Browse available coupons'),
              onPressed: () => _navigateToCouponSelection(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodSection(ThemeData theme, UserModel user) {
    return Card(
      elevation: 2,
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
                  onPressed: () {
                    // Navigate to payment methods management
                  },
                  child: const Text('Manage'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Payment options
            Column(
              children: [
                _buildPaymentOption(
                  'Credit/Debit Card',
                  'Visa, Mastercard, etc.',
                  Icons.credit_card,
                  'card',
                  theme,
                ),
                _buildPaymentOption(
                  'Mobile Money',
                  'M-Pesa, Tigo Pesa, Airtel Money',
                  Icons.phone_android,
                  'mobile_money',
                  theme,
                ),
                _buildPaymentOption(
                  'Bank Transfer',
                  'Direct bank transfer',
                  Icons.account_balance,
                  'bank_transfer',
                  theme,
                ),
                _buildPaymentOption(
                  'Cash on Delivery',
                  'Pay when you receive your order',
                  Icons.money,
                  'cod',
                  theme,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentOption(
    String title,
    String subtitle,
    IconData icon,
    String value,
    ThemeData theme,
  ) {
    final isSelected =
        _selectedPaymentMethod?.type.toString().split('.').last == value;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        border: Border.all(
          color: isSelected ? theme.colorScheme.primary : Colors.grey[300]!,
          width: isSelected ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? theme.colorScheme.primary : Colors.grey[600],
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing:
            isSelected
                ? Icon(Icons.check_circle, color: theme.colorScheme.primary)
                : null,
        onTap: () {
          setState(() {
            _selectedPaymentMethod = PaymentMethodModel(
              id: value,
              userId: '',
              type: _getPaymentMethodType(value),
              createdAt: DateTime.now(),
            );
          });
        },
      ),
    );
  }

  Widget _buildSpecialInstructionsSection(ThemeData theme) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Special Instructions',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _specialInstructionsController,
              decoration: InputDecoration(
                hintText: 'Any special delivery instructions...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedOrderTotal(CartState cart, ThemeData theme) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order Total',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Detailed breakdown
            _buildTotalRow('Subtotal', cart.formattedSubtotal, false),
            if (cart.itemDiscounts > 0)
              _buildTotalRow(
                'Item Discounts',
                '-TZS ${cart.itemDiscounts.toStringAsFixed(0)}',
                false,
                isDiscount: true,
              ),
            _buildTotalRow('Shipping', cart.formattedDeliveryFee, false),
            _buildTotalRow('Tax (VAT 18%)', cart.formattedTax, false),
            if (cart.couponDiscount > 0)
              _buildTotalRow(
                'Coupon Discount',
                '-${cart.formattedCouponDiscount}',
                false,
                isDiscount: true,
              ),

            const Divider(thickness: 2),

            _buildTotalRow('Total', cart.formattedTotal, true),

            if (cart.hasDiscount) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.savings, color: Colors.green[600], size: 16),
                  const SizedBox(width: 4),
                  Text(
                    'You saved TZS ${cart.totalSavings.toStringAsFixed(0)}!',
                    style: TextStyle(
                      color: Colors.green[600],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTotalRow(
    String label,
    String value,
    bool isTotal, {
    bool isDiscount = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
              color:
                  isDiscount
                      ? Colors.green[600]
                      : isTotal
                      ? Theme.of(context).colorScheme.primary
                      : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTermsAndConditions(ThemeData theme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Checkbox(
          value: _agreeToTerms,
          onChanged: (value) => setState(() => _agreeToTerms = value ?? false),
        ),
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _agreeToTerms = !_agreeToTerms),
            child: RichText(
              text: TextSpan(
                style: theme.textTheme.bodySmall,
                children: [
                  const TextSpan(text: 'I agree to the '),
                  TextSpan(
                    text: 'Terms and Conditions',
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  const TextSpan(text: ' and '),
                  TextSpan(
                    text: 'Privacy Policy',
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceOrderButton(CartState cart, ThemeData theme) {
    final canPlaceOrder =
        _agreeToTerms &&
        _selectedShippingMethod != null &&
        (!cart.isGuestCheckout || _selectedPaymentMethod != null);

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: canPlaceOrder && !_isProcessingOrder ? _placeOrder : null,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: theme.colorScheme.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child:
            _isProcessingOrder
                ? const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Processing...',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                )
                : Text(
                  'Place Order - ${cart.formattedTotal}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
      ),
    );
  }

  // Action methods
  Future<void> _applyCoupon() async {
    final couponCode = _couponController.text.trim().toUpperCase();
    if (couponCode.isEmpty) return;

    try {
      final user = ref.read(currentUserProvider);
      final cart = ref.read(cartProvider);

      final coupon = await _couponService.validateCoupon(
        couponCode,
        user?.id ?? 'guest',
        cart.items,
        cart.subtotal,
      );

      if (coupon != null) {
        final discount = _couponService.calculateDiscount(
          coupon,
          cart.items,
          cart.subtotal,
          cart.deliveryFee,
        );

        ref
            .read(cartProvider.notifier)
            .applyCoupon(couponCode, discount.discountAmount);

        setState(() => _appliedCouponCode = couponCode);
        _couponController.clear();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(discount.description),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _removeCoupon() {
    ref.read(cartProvider.notifier).removeCoupon();
    setState(() => _appliedCouponCode = null);
  }

  void _navigateToGuestCheckout() {
    // For now, just show a message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Guest checkout feature coming soon!')),
    );
  }

  void _navigateToCouponSelection() {
    // For now, just show a message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Coupon selection feature coming soon!')),
    );
  }

  PaymentMethod _getPaymentMethodType(String value) {
    switch (value) {
      case 'card':
        return PaymentMethod.creditCard;
      case 'mobile_money':
        return PaymentMethod.mobileMoney;
      case 'bank_transfer':
        return PaymentMethod.bankTransfer;
      case 'cod':
        return PaymentMethod.cashOnDelivery;
      default:
        return PaymentMethod.cashOnDelivery;
    }
  }

  Future<void> _placeOrder() async {
    if (!_agreeToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please agree to terms and conditions')),
      );
      return;
    }

    if (_selectedShippingMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a shipping method')),
      );
      return;
    }

    setState(() => _isProcessingOrder = true);

    try {
      final user = ref.read(currentUserProvider);
      final cart = ref.read(cartProvider);

      // Validate cart before placing order
      if (!ref.read(cartProvider.notifier).validateCart()) {
        final issues = ref.read(cartProvider.notifier).getCartIssues();
        throw Exception('Cart validation failed: ${issues.join(', ')}');
      }

      // Create order
      final order = await ref
          .read(orderProvider.notifier)
          .createOrder(
            customerId: user?.id ?? 'guest',
            items: cart.items,
            deliveryAddress:
                'Default Address', // This would come from selected address
            deliveryInstructions: _specialInstructionsController.text.trim(),
          );

      // Process payment if not COD
      if (_selectedPaymentMethod?.type != PaymentMethod.cashOnDelivery) {
        await ref
            .read(paymentProvider.notifier)
            .processPayment(
              order: order,
              paymentMethod: _selectedPaymentMethod!.type,
              paymentMethodId: _selectedPaymentMethod!.id,
            );
      }

      // Clear cart
      ref.read(cartProvider.notifier).clearCart();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order placed successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate to order confirmation or orders list
        if (user != null) {
          context.go('/customer/history');
        } else {
          context.go('/customer/home');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to place order: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessingOrder = false);
      }
    }
  }
}
