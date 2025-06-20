import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/payment_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/payment_provider.dart';
import 'add_payment_method_screen.dart';
import 'package:uuid/uuid.dart';

class PaymentMethodsScreen extends ConsumerWidget {
  const PaymentMethodsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final paymentMethodsAsync = ref.watch(
      paymentMethodsStreamProvider(user.id),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Payment Methods'), elevation: 0),
      body: paymentMethodsAsync.when(
        data: (paymentMethods) {
          if (paymentMethods.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.payment_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No payment methods',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add a payment method to make purchases',
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Add Payment Method'),
                    onPressed: () => _navigateToAddPaymentMethod(context),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: paymentMethods.length,
                  itemBuilder: (context, index) {
                    final paymentMethod = paymentMethods[index];
                    return PaymentMethodCard(
                      paymentMethod: paymentMethod,
                      onTap:
                          () => _showPaymentMethodOptions(
                            context,
                            ref,
                            paymentMethod,
                          ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Add New Payment Method'),
                    onPressed: () => _navigateToAddPaymentMethod(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: colorScheme.primary),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error:
            (error, stack) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error loading payment methods: $error'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed:
                        () =>
                            ref.refresh(paymentMethodsStreamProvider(user.id)),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
      ),
    );
  }

  void _navigateToAddPaymentMethod(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddPaymentMethodScreen()),
    );
  }

  void _showPaymentMethodOptions(
    BuildContext context,
    WidgetRef ref,
    PaymentMethodModel paymentMethod,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => PaymentMethodOptionsSheet(
            paymentMethod: paymentMethod,
            onSetDefault: () async {
              Navigator.pop(context);
              final user = ref.read(currentUserProvider);
              if (user != null) {
                try {
                  await ref
                      .read(paymentProvider.notifier)
                      .setDefaultPaymentMethod(user.id, paymentMethod.id);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Default payment method updated'),
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                }
              }
            },
            onDelete: () async {
              Navigator.pop(context);
              final confirmed = await showDialog<bool>(
                context: context,
                builder:
                    (context) => AlertDialog(
                      title: const Text('Delete Payment Method'),
                      content: const Text(
                        'Are you sure you want to delete this payment method?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
              );

              if (confirmed == true) {
                try {
                  await ref
                      .read(paymentProvider.notifier)
                      .deletePaymentMethod(paymentMethod.id);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Payment method deleted')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                }
              }
            },
          ),
    );
  }
}

class PaymentMethodCard extends StatelessWidget {
  final PaymentMethodModel paymentMethod;
  final VoidCallback onTap;

  const PaymentMethodCard({
    super.key,
    required this.paymentMethod,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: colorScheme.primaryContainer,
          child: Icon(_getPaymentMethodIcon(), color: colorScheme.primary),
        ),
        title: Text(paymentMethod.displayName),
        subtitle:
            paymentMethod.isDefault
                ? Text(
                  'Default',
                  style: TextStyle(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                )
                : null,
        trailing: const Icon(Icons.more_vert),
        onTap: onTap,
      ),
    );
  }

  IconData _getPaymentMethodIcon() {
    switch (paymentMethod.type) {
      case PaymentMethod.creditCard:
      case PaymentMethod.debitCard:
        return Icons.credit_card;
      case PaymentMethod.mobileMoney:
        return Icons.phone_android;
      case PaymentMethod.bankTransfer:
        return Icons.account_balance;
      case PaymentMethod.cashOnDelivery:
        return Icons.money;
    }
  }
}

class PaymentMethodOptionsSheet extends StatelessWidget {
  final PaymentMethodModel paymentMethod;
  final VoidCallback onSetDefault;
  final VoidCallback onDelete;

  const PaymentMethodOptionsSheet({
    super.key,
    required this.paymentMethod,
    required this.onSetDefault,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            paymentMethod.displayName,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          if (!paymentMethod.isDefault)
            ListTile(
              leading: const Icon(Icons.star_outline),
              title: const Text('Set as Default'),
              onTap: onSetDefault,
            ),
          ListTile(
            leading: const Icon(Icons.delete_outline, color: Colors.red),
            title: const Text('Delete', style: TextStyle(color: Colors.red)),
            onTap: onDelete,
          ),
        ],
      ),
    );
  }
}
