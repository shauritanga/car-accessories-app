import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/payment_model.dart';
import '../../models/shipping_model.dart';
import '../../providers/cart_provider.dart';
import '../../providers/order_provider.dart';
import '../../services/shipping_service.dart';
import '../../widgets/payment_progress_dialog.dart';

class GuestCheckoutScreen extends ConsumerStatefulWidget {
  const GuestCheckoutScreen({super.key});

  @override
  ConsumerState<GuestCheckoutScreen> createState() =>
      _GuestCheckoutScreenState();
}

class _GuestCheckoutScreenState extends ConsumerState<GuestCheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _specialInstructionsController = TextEditingController();

  ShippingMethod? _selectedShippingMethod;
  PaymentMethod? _selectedPaymentMethod;
  bool _agreeToTerms = false;
  bool _isProcessingOrder = false;
  bool _saveInfoForFuture = false;

  final List<ShippingMethod> _shippingMethods = [
    ShippingMethod(
      id: 'standard',
      name: 'Standard Delivery',
      description: '3-5 business days',
      type: ShippingType.standard,
      cost: 5000,
      estimatedDaysMin: 3,
      estimatedDaysMax: 5,
    ),
    ShippingMethod(
      id: 'express',
      name: 'Express Delivery',
      description: '1-2 business days',
      type: ShippingType.express,
      cost: 15000,
      estimatedDaysMin: 1,
      estimatedDaysMax: 2,
    ),
    ShippingMethod(
      id: 'pickup',
      name: 'Store Pickup',
      description: 'Pick up from our store',
      type: ShippingType.pickup,
      cost: 0,
      estimatedDaysMin: 1,
      estimatedDaysMax: 1,
    ),
  ];

  final List<PaymentMethod> _paymentMethods = [
    PaymentMethod.creditCard,
    PaymentMethod.debitCard,
    PaymentMethod.mobileMoney,
    PaymentMethod.cashOnDelivery,
  ];

  @override
  void dispose() {
    _emailController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _postalCodeController.dispose();
    _specialInstructionsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Guest Checkout'),
        backgroundColor: colorScheme.surface,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.shopping_cart, color: colorScheme.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Guest Checkout',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Complete your purchase without creating an account',
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

              // Contact Information
              Text(
                'Contact Information',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email Address *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.email),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Email is required';
                          }
                          if (!RegExp(
                            r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                          ).hasMatch(value)) {
                            return 'Please enter a valid email address';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _firstNameController,
                              decoration: const InputDecoration(
                                labelText: 'First Name *',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.person),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'First name is required';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _lastNameController,
                              decoration: const InputDecoration(
                                labelText: 'Last Name *',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Last name is required';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _phoneController,
                        decoration: const InputDecoration(
                          labelText: 'Phone Number *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.phone),
                        ),
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Phone number is required';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Shipping Address
              Text(
                'Shipping Address',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _addressController,
                        decoration: const InputDecoration(
                          labelText: 'Street Address *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.location_on),
                        ),
                        maxLines: 2,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Address is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: _cityController,
                              decoration: const InputDecoration(
                                labelText: 'City *',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.location_city),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'City is required';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _postalCodeController,
                              decoration: const InputDecoration(
                                labelText: 'Postal Code',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _specialInstructionsController,
                        decoration: const InputDecoration(
                          labelText: 'Special Instructions (Optional)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.note),
                        ),
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Shipping Method
              Text(
                'Shipping Method',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              Card(
                child: Column(
                  children:
                      _shippingMethods.map((method) {
                        return RadioListTile<ShippingMethod>(
                          title: Text(method.name),
                          subtitle: Text(
                            '${method.description} • TZS ${method.cost.toStringAsFixed(0)}',
                          ),
                          value: method,
                          groupValue: _selectedShippingMethod,
                          onChanged: (value) {
                            setState(() {
                              _selectedShippingMethod = value;
                            });
                          },
                        );
                      }).toList(),
                ),
              ),

              const SizedBox(height: 24),

              // Payment Method
              Text(
                'Payment Method',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              Card(
                child: Column(
                  children:
                      _paymentMethods.map((method) {
                        return RadioListTile<PaymentMethod>(
                          title: Text(_getPaymentMethodName(method)),
                          subtitle: Text(_getPaymentMethodDescription(method)),
                          value: method,
                          groupValue: _selectedPaymentMethod,
                          onChanged: (value) {
                            setState(() {
                              _selectedPaymentMethod = value;
                            });
                          },
                        );
                      }).toList(),
                ),
              ),

              const SizedBox(height: 24),

              // Order Summary
              Text(
                'Order Summary',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Subtotal (${cart.items.length} items)'),
                          Text('TZS ${cart.subtotal.toStringAsFixed(0)}'),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Shipping'),
                          Text(
                            'TZS ${(_selectedShippingMethod?.cost ?? 0).toStringAsFixed(0)}',
                          ),
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
                            'TZS ${(cart.subtotal + (_selectedShippingMethod?.cost ?? 0)).toStringAsFixed(0)}',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Options
              CheckboxListTile(
                title: const Text(
                  'Save my information for faster checkout next time',
                ),
                subtitle: const Text(
                  'We\'ll create an account for you with this information',
                ),
                value: _saveInfoForFuture,
                onChanged: (value) {
                  setState(() {
                    _saveInfoForFuture = value ?? false;
                  });
                },
                controlAffinity: ListTileControlAffinity.leading,
              ),

              CheckboxListTile(
                title: const Text(
                  'I agree to the Terms of Service and Privacy Policy',
                ),
                value: _agreeToTerms,
                onChanged: (value) {
                  setState(() {
                    _agreeToTerms = value ?? false;
                  });
                },
                controlAffinity: ListTileControlAffinity.leading,
              ),

              const SizedBox(height: 24),

              // Place Order Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed:
                      _canPlaceOrder() && !_isProcessingOrder
                          ? _placeOrder
                          : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
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
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              ),
                              SizedBox(width: 12),
                              Text('Processing Order...'),
                            ],
                          )
                          : Text(
                            'Place Order • TZS ${(cart.subtotal + (_selectedShippingMethod?.cost ?? 0)).toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _canPlaceOrder() {
    return _formKey.currentState?.validate() == true &&
        _selectedShippingMethod != null &&
        _selectedPaymentMethod != null &&
        _agreeToTerms;
  }

  String _getPaymentMethodName(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.creditCard:
        return 'Credit Card';
      case PaymentMethod.debitCard:
        return 'Debit Card';
      case PaymentMethod.mobileMoney:
        return 'Mobile Money';
      case PaymentMethod.cashOnDelivery:
        return 'Cash on Delivery';
      default:
        return method.toString();
    }
  }

  String _getPaymentMethodDescription(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.creditCard:
        return 'Pay with your credit card';
      case PaymentMethod.debitCard:
        return 'Pay with your debit card';
      case PaymentMethod.mobileMoney:
        return 'M-Pesa, Tigo Pesa, Airtel Money';
      case PaymentMethod.cashOnDelivery:
        return 'Pay when your order is delivered';
      default:
        return '';
    }
  }

  Future<void> _placeOrder() async {
    if (!_formKey.currentState!.validate() || !_canPlaceOrder()) {
      return;
    }

    setState(() => _isProcessingOrder = true);

    try {
      final cart = ref.read(cartProvider);

      // Show payment progress dialog if not COD
      if (_selectedPaymentMethod != PaymentMethod.cashOnDelivery && mounted) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder:
              (context) => PaymentProgressDialog(
                paymentId: 'guest_${DateTime.now().millisecondsSinceEpoch}',
                paymentMethod: _selectedPaymentMethod!,
                amount: cart.subtotal + (_selectedShippingMethod?.cost ?? 0),
                onSuccess: () {
                  // Payment completed successfully
                },
                onError: () {
                  // Payment failed
                  throw Exception('Payment failed');
                },
              ),
        );
      }

      // Create guest order (simplified)
      final guestInfo = {
        'email': _emailController.text.trim(),
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
        'city': _cityController.text.trim(),
        'postalCode': _postalCodeController.text.trim(),
        'specialInstructions': _specialInstructionsController.text.trim(),
        'saveInfoForFuture': _saveInfoForFuture,
      };

      // Simulate order creation
      await Future.delayed(const Duration(seconds: 2));

      // Clear cart
      ref.read(cartProvider.notifier).clearCart();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order placed successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate to order confirmation or home
        context.go('/customer/home');
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
