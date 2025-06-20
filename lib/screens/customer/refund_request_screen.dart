import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/order_model.dart';
import '../../models/order_modification_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_modification_provider.dart';

class RefundRequestScreen extends ConsumerStatefulWidget {
  final OrderModel order;

  const RefundRequestScreen({
    super.key,
    required this.order,
  });

  @override
  ConsumerState<RefundRequestScreen> createState() => _RefundRequestScreenState();
}

class _RefundRequestScreenState extends ConsumerState<RefundRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  
  String? _selectedReason;
  List<String> _selectedItems = [];
  RefundMethod _refundMethod = RefundMethod.originalPayment;
  bool _isSubmitting = false;
  double _estimatedRefund = 0.0;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = ref.watch(currentUserProvider);
    final modificationState = ref.watch(orderModificationProvider);

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in to request refunds')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Request Refund'),
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Order Information
              _buildOrderInfo(theme),
              const SizedBox(height: 24),
              
              // Refund Policy
              _buildRefundPolicy(theme),
              const SizedBox(height: 24),
              
              // Item Selection
              _buildItemSelection(theme),
              const SizedBox(height: 24),
              
              // Estimated Refund
              if (_estimatedRefund > 0) ...[
                _buildEstimatedRefund(theme),
                const SizedBox(height: 24),
              ],
              
              // Reason Selection
              _buildReasonSelection(theme),
              const SizedBox(height: 16),
              
              // Refund Method
              _buildRefundMethodSelection(theme),
              const SizedBox(height: 16),
              
              // Additional Description
              _buildDescriptionField(),
              const SizedBox(height: 32),
              
              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting || modificationState.isLoading ? null : _submitRefund,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.blue,
                  ),
                  child: _isSubmitting || modificationState.isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Submit Refund Request',
                          style: TextStyle(
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
      ),
    );
  }

  Widget _buildOrderInfo(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order Details',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text('Order ID: #${widget.order.id.substring(0, 8)}'),
            Text('Total Paid: TZS ${widget.order.total.toStringAsFixed(0)}'),
            Text('Order Date: ${_formatDate(widget.order.createdAt)}'),
          ],
        ),
      ),
    );
  }

  Widget _buildRefundPolicy(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Refund Policy',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              '• Refunds are processed within 5-7 business days\n'
              '• Refund amount may exclude shipping charges\n'
              '• Processing fees may apply for certain payment methods\n'
              '• Refunds can be issued to original payment method or store credit',
              style: TextStyle(height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemSelection(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Items for Refund',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            CheckboxListTile(
              title: const Text('Full Order Refund'),
              subtitle: Text('Refund entire order (TZS ${widget.order.total.toStringAsFixed(0)})'),
              value: _selectedItems.isEmpty,
              onChanged: (value) {
                setState(() {
                  if (value == true) {
                    _selectedItems.clear();
                    _estimatedRefund = widget.order.total;
                  }
                });
                _calculateRefund();
              },
              contentPadding: EdgeInsets.zero,
            ),
            const Divider(),
            const Text('Or select specific items:'),
            const SizedBox(height: 8),
            ...widget.order.items.map((item) {
              final isSelected = _selectedItems.contains(item.productId);
              return CheckboxListTile(
                title: Text('Product ID: ${item.productId}'),
                subtitle: Text('Quantity: ${item.quantity} • Price: TZS ${item.price.toStringAsFixed(0)}'),
                value: isSelected,
                onChanged: (value) {
                  setState(() {
                    if (value == true) {
                      _selectedItems.add(item.productId);
                    } else {
                      _selectedItems.remove(item.productId);
                    }
                  });
                  _calculateRefund();
                },
                contentPadding: EdgeInsets.zero,
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildEstimatedRefund(ThemeData theme) {
    return Card(
      color: Colors.green.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.money, color: Colors.green[700]),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Estimated Refund Amount',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'TZS ${_estimatedRefund.toStringAsFixed(0)}',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.green[700],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReasonSelection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Reason for Refund *',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...ModificationReasons.refundReasons.map((reason) {
          return RadioListTile<String>(
            title: Text(reason),
            value: reason,
            groupValue: _selectedReason,
            onChanged: (value) => setState(() => _selectedReason = value),
            contentPadding: EdgeInsets.zero,
          );
        }),
      ],
    );
  }

  Widget _buildRefundMethodSelection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Preferred Refund Method',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        RadioListTile<RefundMethod>(
          title: const Text('Original Payment Method'),
          subtitle: const Text('Refund to the card/account used for payment'),
          value: RefundMethod.originalPayment,
          groupValue: _refundMethod,
          onChanged: (value) => setState(() => _refundMethod = value!),
          contentPadding: EdgeInsets.zero,
        ),
        RadioListTile<RefundMethod>(
          title: const Text('Store Credit'),
          subtitle: const Text('Receive credit to use for future purchases'),
          value: RefundMethod.storeCredit,
          groupValue: _refundMethod,
          onChanged: (value) => setState(() => _refundMethod = value!),
          contentPadding: EdgeInsets.zero,
        ),
        RadioListTile<RefundMethod>(
          title: const Text('Bank Transfer'),
          subtitle: const Text('Direct transfer to your bank account'),
          value: RefundMethod.bankTransfer,
          groupValue: _refundMethod,
          onChanged: (value) => setState(() => _refundMethod = value!),
          contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }

  Widget _buildDescriptionField() {
    return TextFormField(
      controller: _descriptionController,
      decoration: const InputDecoration(
        labelText: 'Additional Details',
        hintText: 'Please provide any additional information...',
        border: OutlineInputBorder(),
        alignLabelWithHint: true,
      ),
      maxLines: 4,
      validator: (value) {
        if (_selectedReason == 'Other' && (value == null || value.trim().isEmpty)) {
          return 'Please provide details for "Other" reason';
        }
        return null;
      },
    );
  }

  Future<void> _calculateRefund() async {
    if (_selectedItems.isEmpty) {
      setState(() => _estimatedRefund = widget.order.total);
    } else {
      final refund = await ref.read(orderModificationProvider.notifier)
          .calculateRefundAmount(widget.order.id, _selectedItems);
      setState(() => _estimatedRefund = refund);
    }
  }

  Future<void> _submitRefund() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedReason == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a reason for refund')),
      );
      return;
    }

    if (_estimatedRefund <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select items for refund')),
      );
      return;
    }

    final user = ref.read(currentUserProvider);
    if (user == null) return;

    setState(() => _isSubmitting = true);

    try {
      await ref.read(orderModificationProvider.notifier).submitRefundRequest(
        orderId: widget.order.id,
        customerId: user.id,
        reason: _selectedReason!,
        description: _descriptionController.text.trim().isNotEmpty 
            ? _descriptionController.text.trim() 
            : null,
        items: _selectedItems.isEmpty ? null : _selectedItems,
        refundMethod: _refundMethod,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Refund request submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting refund request: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
