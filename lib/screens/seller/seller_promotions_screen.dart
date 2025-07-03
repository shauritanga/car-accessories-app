import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/coupon_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/coupon_service.dart';

class SellerPromotionsScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Promotions / Discounts')),
      body: FutureBuilder<List<Coupon>>(
        future: CouponService().getCouponsBySeller(user?.id ?? ''),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No promotions found.'));
          }
          final coupons = snapshot.data!;
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: coupons.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final coupon = coupons[index];
              return Card(
                child: ListTile(
                  leading: Icon(Icons.local_offer, color: coupon.isActive ? Colors.green : Colors.grey),
                  title: Text('${coupon.name} (${coupon.code})'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Type: ${coupon.type.toString().split('.').last}, Value: ${coupon.value}'),
                      Text('Valid: ${coupon.startDate.toLocal().toString().split(' ')[0]} - ${coupon.endDate.toLocal().toString().split(' ')[0]}'),
                      Text('Usage: ${coupon.usageCount}/${coupon.usageLimit ?? '∞'}'),
                      Text('Status: ${coupon.isActive ? 'Active' : 'Inactive'}'),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => _showEditCouponDialog(context, coupon, ref, user!.id),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Add Promotion'),
        onPressed: () => _showEditCouponDialog(context, null, ref, user!.id),
      ),
    );
  }

  void _showEditCouponDialog(BuildContext context, Coupon? coupon, WidgetRef ref, String sellerId) {
    final _formKey = GlobalKey<FormState>();
    final _nameController = TextEditingController(text: coupon?.name ?? '');
    final _codeController = TextEditingController(text: coupon?.code ?? '');
    final _valueController = TextEditingController(text: coupon?.value.toString() ?? '');
    final _descController = TextEditingController(text: coupon?.description ?? '');
    final _type = ValueNotifier<CouponType>(coupon?.type ?? CouponType.percentage);
    final _isActive = ValueNotifier<bool>(coupon?.isActive ?? true);
    final _startDate = ValueNotifier<DateTime>(coupon?.startDate ?? DateTime.now());
    final _endDate = ValueNotifier<DateTime>(coupon?.endDate ?? DateTime.now().add(const Duration(days: 30)));
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(coupon == null ? 'Add Promotion' : 'Edit Promotion'),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                TextFormField(
                  controller: _codeController,
                  decoration: const InputDecoration(labelText: 'Code'),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                TextFormField(
                  controller: _descController,
                  decoration: const InputDecoration(labelText: 'Description'),
                ),
                ValueListenableBuilder<CouponType>(
                  valueListenable: _type,
                  builder: (context, value, _) => DropdownButtonFormField<CouponType>(
                    value: value,
                    items: CouponType.values.map((t) => DropdownMenuItem(value: t, child: Text(t.toString().split('.').last))).toList(),
                    onChanged: (v) => _type.value = v!,
                    decoration: const InputDecoration(labelText: 'Type'),
                  ),
                ),
                TextFormField(
                  controller: _valueController,
                  decoration: const InputDecoration(labelText: 'Value'),
                  keyboardType: TextInputType.number,
                  validator: (v) => v == null || double.tryParse(v) == null ? 'Enter a valid number' : null,
                ),
                Row(
                  children: [
                    Expanded(
                      child: ValueListenableBuilder<DateTime>(
                        valueListenable: _startDate,
                        builder: (context, value, _) => TextButton(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: value,
                              firstDate: DateTime.now().subtract(const Duration(days: 365)),
                              lastDate: DateTime.now().add(const Duration(days: 365)),
                            );
                            if (picked != null) _startDate.value = picked;
                          },
                          child: Text('Start: ${value.toLocal().toString().split(' ')[0]}'),
                        ),
                      ),
                    ),
                    Expanded(
                      child: ValueListenableBuilder<DateTime>(
                        valueListenable: _endDate,
                        builder: (context, value, _) => TextButton(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: value,
                              firstDate: DateTime.now().subtract(const Duration(days: 365)),
                              lastDate: DateTime.now().add(const Duration(days: 365)),
                            );
                            if (picked != null) _endDate.value = picked;
                          },
                          child: Text('End: ${value.toLocal().toString().split(' ')[0]}'),
                        ),
                      ),
                    ),
                  ],
                ),
                ValueListenableBuilder<bool>(
                  valueListenable: _isActive,
                  builder: (context, value, _) => SwitchListTile(
                    value: value,
                    onChanged: (v) => _isActive.value = v,
                    title: const Text('Active'),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                final newCoupon = Coupon(
                  id: coupon?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                  code: _codeController.text.trim().toUpperCase(),
                  name: _nameController.text.trim(),
                  description: _descController.text.trim(),
                  type: _type.value,
                  value: double.parse(_valueController.text.trim()),
                  startDate: _startDate.value,
                  endDate: _endDate.value,
                  isActive: _isActive.value,
                  createdAt: coupon?.createdAt ?? DateTime.now(),
                  updatedAt: DateTime.now(),
                  sellerId: sellerId,
                );
                await CouponService().addCoupon(newCoupon);
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
} 