import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../providers/payout_provider.dart';

class SellerPayoutsScreen extends ConsumerWidget {
  const SellerPayoutsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final payoutMethodsAsync = ref.watch(
      payoutMethodsProvider(currentUser?.id ?? ''),
    );
    final payoutsAsync = ref.watch(payoutsProvider(currentUser?.id ?? ''));
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payouts & Payment Methods'),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Payout Methods', style: theme.textTheme.titleMedium),
            payoutMethodsAsync.when(
              data:
                  (methods) => Column(
                    children: [
                      ...methods.map(
                        (method) => Card(
                          child: ListTile(
                            title: Text(method['type'] ?? 'Unknown'),
                            subtitle: Text(method['details'] ?? ''),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                await ref
                                    .read(payoutProvider.notifier)
                                    .deletePayoutMethod(
                                      currentUser!.id,
                                      method['id'],
                                    );
                              },
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text('Add Payout Method'),
                        onPressed:
                            () => _showAddPayoutMethodDialog(
                              context,
                              ref,
                              currentUser!.id,
                            ),
                      ),
                    ],
                  ),
              loading: () => const CircularProgressIndicator(),
              error: (e, _) => Text('Error: $e'),
            ),
            const SizedBox(height: 32),
            Text('Payout History', style: theme.textTheme.titleMedium),
            payoutsAsync.when(
              data: (payouts) {
                double totalPaid = 0;
                double totalPending = 0;
                double totalFailed = 0;
                for (final p in payouts) {
                  final status = (p['status'] ?? '').toString().toLowerCase();
                  final amount = (p['amount'] ?? 0).toDouble();
                  if (status == 'completed')
                    totalPaid += amount;
                  else if (status == 'pending')
                    totalPending += amount;
                  else if (status == 'failed')
                    totalFailed += amount;
                }
                return Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStatCard('Total Paid', totalPaid, Colors.green),
                        _buildStatCard('Pending', totalPending, Colors.orange),
                        _buildStatCard('Failed', totalFailed, Colors.red),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.request_page),
                      label: const Text('Request Payout'),
                      onPressed:
                          () => _showRequestPayoutDialog(
                            context,
                            ref,
                            currentUser!.id,
                            payoutMethodsAsync.value ?? [],
                          ),
                    ),
                    payouts.isEmpty
                        ? const Text('No payouts yet.')
                        : ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: payouts.length,
                          separatorBuilder:
                              (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final payout = payouts[index];
                            final status =
                                (payout['status'] ?? '')
                                    .toString()
                                    .toLowerCase();
                            final statusColor =
                                status == 'completed'
                                    ? Colors.green
                                    : status == 'pending'
                                    ? Colors.orange
                                    : status == 'failed'
                                    ? Colors.red
                                    : Colors.grey;
                            return Card(
                              child: ListTile(
                                title: Text('Amount: TZS ${payout['amount']}'),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Status: ${payout['status']}',
                                      style: TextStyle(color: statusColor),
                                    ),
                                    if (payout['method'] != null)
                                      Text('Method: ${payout['method']}'),
                                    if (payout['reference'] != null)
                                      Text('Reference: ${payout['reference']}'),
                                    Text('Date: ${payout['date'] ?? ''}'),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                  ],
                );
              },
              loading: () => const CircularProgressIndicator(),
              error: (e, _) => Text('Error: $e'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddPayoutMethodDialog(
    BuildContext context,
    WidgetRef ref,
    String sellerId,
  ) {
    final typeController = TextEditingController();
    final detailsController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    String? errorText;
    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setState) => AlertDialog(
                  title: const Text('Add Payout Method'),
                  content: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: typeController,
                          decoration: const InputDecoration(
                            labelText: 'Type (e.g. Bank, Mobile Money)',
                          ),
                          validator:
                              (value) =>
                                  (value == null || value.trim().isEmpty)
                                      ? 'Type is required'
                                      : null,
                        ),
                        TextFormField(
                          controller: detailsController,
                          decoration: const InputDecoration(
                            labelText: 'Details (e.g. Account Number)',
                          ),
                          validator:
                              (value) =>
                                  (value == null || value.trim().isEmpty)
                                      ? 'Details are required'
                                      : null,
                        ),
                        if (errorText != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              errorText!,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        if (formKey.currentState!.validate()) {
                          await ref
                              .read(payoutProvider.notifier)
                              .addPayoutMethod(
                                sellerId,
                                typeController.text.trim(),
                                detailsController.text.trim(),
                              );
                          Navigator.pop(context);
                        } else {
                          setState(
                            () =>
                                errorText = 'Please fill all required fields.',
                          );
                        }
                      },
                      child: const Text('Add'),
                    ),
                  ],
                ),
          ),
    );
  }

  void _showRequestPayoutDialog(
    BuildContext context,
    WidgetRef ref,
    String sellerId,
    List<Map<String, dynamic>> methods,
  ) {
    final amountController = TextEditingController();
    String? selectedMethodId;
    String? errorText;
    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setState) => AlertDialog(
                  title: const Text('Request Payout'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: amountController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Amount'),
                      ),
                      DropdownButtonFormField<String>(
                        value: selectedMethodId,
                        items:
                            methods
                                .map<DropdownMenuItem<String>>(
                                  (m) => DropdownMenuItem<String>(
                                    value: m['id'] as String,
                                    child: Text(
                                      '${m['type']} - ${m['details']}',
                                    ),
                                  ),
                                )
                                .toList(),
                        onChanged: (v) => setState(() => selectedMethodId = v),
                        decoration: const InputDecoration(
                          labelText: 'Payout Method',
                        ),
                      ),
                      if (errorText != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            errorText!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        final amount = double.tryParse(
                          amountController.text.trim(),
                        );
                        if (amount == null ||
                            amount <= 0 ||
                            selectedMethodId == null) {
                          setState(
                            () =>
                                errorText =
                                    'Enter a valid amount and select a payout method.',
                          );
                          return;
                        }
                        await ref
                            .read(payoutProvider.notifier)
                            .requestPayout(
                              sellerId: sellerId,
                              amount: amount,
                              methodId: selectedMethodId!,
                            );
                        Navigator.pop(context);
                      },
                      child: const Text('Request'),
                    ),
                  ],
                ),
          ),
    );
  }

  Widget _buildStatCard(String label, double amount, Color color) {
    return Card(
      color: color.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'TZS ${amount.toStringAsFixed(0)}',
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
