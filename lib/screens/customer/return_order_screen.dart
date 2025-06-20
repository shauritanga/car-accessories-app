import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../models/order_model.dart';
import '../../models/order_modification_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_modification_provider.dart';

class ReturnOrderScreen extends ConsumerStatefulWidget {
  final OrderModel order;

  const ReturnOrderScreen({
    super.key,
    required this.order,
  });

  @override
  ConsumerState<ReturnOrderScreen> createState() => _ReturnOrderScreenState();
}

class _ReturnOrderScreenState extends ConsumerState<ReturnOrderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  
  String? _selectedReason;
  List<String> _selectedItems = [];
  List<File> _evidenceImages = [];
  bool _isSubmitting = false;

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
        body: Center(child: Text('Please log in to return orders')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Return Items'),
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
              
              // Return Policy
              _buildReturnPolicy(theme),
              const SizedBox(height: 24),
              
              // Item Selection
              _buildItemSelection(theme),
              const SizedBox(height: 24),
              
              // Reason Selection
              _buildReasonSelection(theme),
              const SizedBox(height: 16),
              
              // Additional Description
              _buildDescriptionField(),
              const SizedBox(height: 24),
              
              // Evidence Images
              _buildEvidenceSection(theme),
              const SizedBox(height: 32),
              
              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting || modificationState.isLoading ? null : _submitReturn,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.orange,
                  ),
                  child: _isSubmitting || modificationState.isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Submit Return Request',
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
            Text('Total: TZS ${widget.order.total.toStringAsFixed(0)}'),
            Text('Delivered: ${_formatDate(widget.order.createdAt)}'),
          ],
        ),
      ),
    );
  }

  Widget _buildReturnPolicy(ThemeData theme) {
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
                  'Return Policy',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              '• Items can be returned within 30 days of delivery\n'
              '• Items must be in original condition and packaging\n'
              '• Refund will be processed after item inspection\n'
              '• Return shipping may be charged to customer\n'
              '• Custom items are not eligible for return',
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
              'Select Items to Return',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
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
                },
                contentPadding: EdgeInsets.zero,
              );
            }),
            if (_selectedItems.isEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning, color: Colors.orange),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Please select at least one item to return',
                        style: TextStyle(color: Colors.orange),
                      ),
                    ),
                  ],
                ),
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
          'Reason for Return *',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...ModificationReasons.returnReasons.map((reason) {
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

  Widget _buildDescriptionField() {
    return TextFormField(
      controller: _descriptionController,
      decoration: const InputDecoration(
        labelText: 'Detailed Description *',
        hintText: 'Please describe the issue in detail...',
        border: OutlineInputBorder(),
        alignLabelWithHint: true,
      ),
      maxLines: 4,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please provide a detailed description';
        }
        if (value.trim().length < 20) {
          return 'Description must be at least 20 characters';
        }
        return null;
      },
    );
  }

  Widget _buildEvidenceSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Evidence Photos (Recommended)',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Upload photos showing the issue to help process your return faster',
          style: TextStyle(color: Colors.grey[600]),
        ),
        const SizedBox(height: 12),
        if (_evidenceImages.isNotEmpty) ...[
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _evidenceImages.length,
              itemBuilder: (context, index) {
                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          _evidenceImages[index],
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => setState(() => _evidenceImages.removeAt(index)),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (_evidenceImages.length < 5)
          OutlinedButton.icon(
            onPressed: _pickImages,
            icon: const Icon(Icons.camera_alt),
            label: Text(_evidenceImages.isEmpty ? 'Add Photos' : 'Add More Photos'),
          ),
      ],
    );
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );
      
      if (images.isNotEmpty) {
        final List<File> newImages = images.map((xFile) => File(xFile.path)).toList();
        setState(() {
          _evidenceImages.addAll(newImages);
          if (_evidenceImages.length > 5) {
            _evidenceImages = _evidenceImages.take(5).toList();
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking images: $e')),
        );
      }
    }
  }

  Future<void> _submitReturn() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedReason == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a reason for return')),
      );
      return;
    }

    if (_selectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one item to return')),
      );
      return;
    }

    final user = ref.read(currentUserProvider);
    if (user == null) return;

    setState(() => _isSubmitting = true);

    try {
      await ref.read(orderModificationProvider.notifier).submitReturnRequest(
        orderId: widget.order.id,
        customerId: user.id,
        reason: _selectedReason!,
        description: _descriptionController.text.trim(),
        items: _selectedItems,
        evidenceImages: _evidenceImages,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Return request submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting return request: $e'),
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
