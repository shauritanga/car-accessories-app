import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/enhanced_payment_provider.dart';
import '../../models/enhanced_payment_model.dart' as enhanced;
import '../../providers/auth_provider.dart';

class PaymentMethodsScreen extends ConsumerStatefulWidget {
  const PaymentMethodsScreen({super.key});

  @override
  ConsumerState<PaymentMethodsScreen> createState() =>
      _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends ConsumerState<PaymentMethodsScreen> {
  @override
  void initState() {
    super.initState();
    // Load payment methods when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(currentUserProvider);
      if (user != null) {
        ref.read(enhancedPaymentProvider.notifier).loadPaymentMethods(user.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final paymentState = ref.watch(enhancedPaymentProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Methods'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddPaymentMethodDialog(context),
          ),
        ],
      ),
      body: Builder(
        builder: (context) {
          if (paymentState.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (paymentState.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading payment methods',
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    paymentState.error!,
                    style: TextStyle(color: Colors.grey[500], fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      ref.read(enhancedPaymentProvider.notifier).clearError();
                      final user = ref.read(currentUserProvider);
                      if (user != null) {
                        ref
                            .read(enhancedPaymentProvider.notifier)
                            .loadPaymentMethods(user.id);
                      }
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (paymentState.paymentMethods.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.credit_card, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No payment methods saved',
                    style: TextStyle(color: Colors.grey[600], fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add a payment method to make checkout faster',
                    style: TextStyle(color: Colors.grey[500], fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => _showAddPaymentMethodDialog(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Payment Method'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: paymentState.paymentMethods.length,
            itemBuilder: (context, index) {
              final method = paymentState.paymentMethods[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _getPaymentMethodColor(method.type),
                    child: Icon(
                      _getPaymentMethodIcon(method.type),
                      color: Colors.white,
                    ),
                  ),
                  title: Text(
                    _getPaymentMethodTitle(method),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_getPaymentMethodSubtitle(method)),
                      if (method.isDefault)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Default',
                            style: TextStyle(
                              color: Colors.green[700],
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'default' && !method.isDefault) {
                        _setDefaultPaymentMethod(method);
                      } else if (value == 'delete') {
                        _showDeleteDialog(context, method);
                      }
                    },
                    itemBuilder:
                        (context) => [
                          if (!method.isDefault)
                            const PopupMenuItem(
                              value: 'default',
                              child: Row(
                                children: [
                                  Icon(Icons.star, size: 16),
                                  SizedBox(width: 8),
                                  Text('Set as Default'),
                                ],
                              ),
                            ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, size: 16, color: Colors.red),
                                SizedBox(width: 8),
                                Text(
                                  'Delete',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ],
                            ),
                          ),
                        ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Color _getPaymentMethodColor(String type) {
    switch (type) {
      case 'card':
        return Colors.blue;
      case 'mobile_money':
        return Colors.green;
      case 'paypal':
        return Colors.indigo;
      case 'bank_transfer':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getPaymentMethodIcon(String type) {
    switch (type) {
      case 'card':
        return Icons.credit_card;
      case 'mobile_money':
        return Icons.phone_android;
      case 'paypal':
        return Icons.payment;
      case 'bank_transfer':
        return Icons.account_balance;
      default:
        return Icons.payment;
    }
  }

  String _getPaymentMethodTitle(enhanced.PaymentMethod method) {
    switch (method.type) {
      case 'card':
        return '${method.cardBrand ?? 'Card'} •••• ${method.last4 ?? ''}';
      case 'mobile_money':
        return method.provider ?? 'Mobile Money';
      case 'paypal':
        return 'PayPal';
      case 'bank_transfer':
        return 'Bank Transfer';
      default:
        return method.type;
    }
  }

  String _getPaymentMethodSubtitle(enhanced.PaymentMethod method) {
    switch (method.type) {
      case 'card':
        return 'Expires ${method.accountName ?? ''}';
      case 'mobile_money':
        return method.accountNumber ?? '';
      case 'paypal':
        return method.accountName ?? '';
      case 'bank_transfer':
        return '${method.accountName ?? ''} - ${method.accountNumber ?? ''}';
      default:
        return '';
    }
  }

  void _setDefaultPaymentMethod(enhanced.PaymentMethod method) {
    final notifier = ref.read(enhancedPaymentProvider.notifier);
    final currentState = ref.read(enhancedPaymentProvider);

    for (final existingMethod in currentState.paymentMethods) {
      final updatedMethod = enhanced.PaymentMethod(
        id: existingMethod.id,
        userId: existingMethod.userId,
        type: existingMethod.type,
        provider: existingMethod.provider,
        last4: existingMethod.last4,
        cardBrand: existingMethod.cardBrand,
        accountNumber: existingMethod.accountNumber,
        accountName: existingMethod.accountName,
        isDefault: existingMethod.id == method.id,
        addedAt: existingMethod.addedAt,
      );
      notifier.addPaymentMethod(updatedMethod);
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Default payment method updated')),
    );
  }

  void _showDeleteDialog(BuildContext context, enhanced.PaymentMethod method) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Payment Method'),
          content: Text('Are you sure you want to delete this payment method?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                ref
                    .read(enhancedPaymentProvider.notifier)
                    .removePaymentMethod(method.id);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Payment method deleted')),
                );
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _showAddPaymentMethodDialog(BuildContext context) {
    String selectedType = 'card';
    final providerController = TextEditingController();
    final accountNumberController = TextEditingController();
    final accountNameController = TextEditingController();
    final last4Controller = TextEditingController();
    final cardBrandController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Add Payment Method'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: selectedType,
                      decoration: const InputDecoration(
                        labelText: 'Payment Type',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'card',
                          child: Text('Credit/Debit Card'),
                        ),
                        DropdownMenuItem(
                          value: 'mobile_money',
                          child: Text('Mobile Money'),
                        ),
                        DropdownMenuItem(
                          value: 'paypal',
                          child: Text('PayPal'),
                        ),
                        DropdownMenuItem(
                          value: 'bank_transfer',
                          child: Text('Bank Transfer'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          selectedType = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: providerController,
                      decoration: const InputDecoration(
                        labelText: 'Provider',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (selectedType == 'card') ...[
                      TextField(
                        controller: cardBrandController,
                        decoration: const InputDecoration(
                          labelText: 'Card Brand',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: last4Controller,
                        decoration: const InputDecoration(
                          labelText: 'Last 4 Digits',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    TextField(
                      controller: accountNumberController,
                      decoration: InputDecoration(
                        labelText:
                            selectedType == 'card'
                                ? 'Card Number'
                                : 'Account Number',
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: accountNameController,
                      decoration: InputDecoration(
                        labelText:
                            selectedType == 'card'
                                ? 'Cardholder Name'
                                : 'Account Name',
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final notifier = ref.read(enhancedPaymentProvider.notifier);
                    final currentState = ref.read(enhancedPaymentProvider);
                    final user = ref.read(currentUserProvider);
                    if (user == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('User not found')),
                      );
                      return;
                    }
                    final method = enhanced.PaymentMethod(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      userId: user.id,
                      type: selectedType,
                      provider: providerController.text.trim(),
                      last4: last4Controller.text.trim(),
                      cardBrand: cardBrandController.text.trim(),
                      accountNumber: accountNumberController.text.trim(),
                      accountName: accountNameController.text.trim(),
                      isDefault: currentState.paymentMethods.isEmpty,
                      addedAt: DateTime.now(),
                    );
                    notifier.addPaymentMethod(method);
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Payment method added successfully'),
                      ),
                    );
                  },
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
