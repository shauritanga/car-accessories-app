import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/coupon_model.dart';
import '../../models/product_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/coupon_service.dart';
import '../../services/product_service.dart';

class SellerPromotionsScreen extends ConsumerWidget {
  const SellerPromotionsScreen({super.key});
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
                  leading: Icon(
                    Icons.local_offer,
                    color: coupon.isActive ? Colors.green : Colors.grey,
                  ),
                  title: Text('${coupon.name} (${coupon.code})'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Type: ${coupon.type.toString().split('.').last}, Value: ${coupon.value}',
                      ),
                      Text(
                        'Valid: ${coupon.startDate.toLocal().toString().split(' ')[0]} - ${coupon.endDate.toLocal().toString().split(' ')[0]}',
                      ),
                      Text(
                        'Usage: ${coupon.usageCount}/${coupon.usageLimit ?? '∞'}',
                      ),
                      Text(
                        'Status: ${coupon.isActive ? 'Active' : 'Inactive'}',
                      ),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed:
                        () => _showEditCouponDialog(
                          context,
                          coupon,
                          ref,
                          user!.id,
                        ),
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

  void _showEditCouponDialog(
    BuildContext context,
    Coupon? coupon,
    WidgetRef ref,
    String sellerId,
  ) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: coupon?.name ?? '');
    final codeController = TextEditingController(text: coupon?.code ?? '');
    final valueController = TextEditingController(
      text: coupon?.value.toString() ?? '',
    );
    final descController = TextEditingController(
      text: coupon?.description ?? '',
    );
    final type = ValueNotifier<CouponType>(
      coupon?.type ?? CouponType.percentage,
    );
    final isActive = ValueNotifier<bool>(coupon?.isActive ?? true);
    final startDate = ValueNotifier<DateTime>(
      coupon?.startDate ?? DateTime.now(),
    );
    final endDate = ValueNotifier<DateTime>(
      coupon?.endDate ?? DateTime.now().add(const Duration(days: 30)),
    );
    final applicableProducts = ValueNotifier<List<String>>(
      coupon?.applicableProducts ?? [],
    );
    final applicableCategories = ValueNotifier<List<String>>(
      coupon?.applicableCategories ?? [],
    );
    final productsFuture = ValueNotifier<Future<List<ProductModel>>?>(null);
    final categoriesFuture = ValueNotifier<Future<List<String>>?>(null);

    // Fetch products and categories for the seller
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final productService = ProductService();
      productsFuture.value = productService.getProducts().first.then((
        products,
      ) {
        return products.where((p) => p.sellerId == sellerId).toList();
      });
      categoriesFuture.value = productService.getCategories();
    });

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(coupon == null ? 'Add Promotion' : 'Edit Promotion'),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Name'),
                      validator:
                          (v) =>
                              v == null || v.trim().isEmpty ? 'Required' : null,
                    ),
                    TextFormField(
                      controller: codeController,
                      decoration: const InputDecoration(labelText: 'Code'),
                      validator:
                          (v) =>
                              v == null || v.trim().isEmpty ? 'Required' : null,
                    ),
                    TextFormField(
                      controller: descController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                      ),
                    ),
                    ValueListenableBuilder<CouponType>(
                      valueListenable: type,
                      builder:
                          (context, value, _) =>
                              DropdownButtonFormField<CouponType>(
                                value: value,
                                items:
                                    CouponType.values
                                        .map(
                                          (t) => DropdownMenuItem(
                                            value: t,
                                            child: Text(
                                              t.toString().split('.').last,
                                            ),
                                          ),
                                        )
                                        .toList(),
                                onChanged: (v) => type.value = v!,
                                decoration: const InputDecoration(
                                  labelText: 'Type',
                                ),
                              ),
                    ),
                    TextFormField(
                      controller: valueController,
                      decoration: const InputDecoration(labelText: 'Value'),
                      keyboardType: TextInputType.number,
                      validator:
                          (v) =>
                              v == null || double.tryParse(v) == null
                                  ? 'Enter a valid number'
                                  : null,
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: ValueListenableBuilder<DateTime>(
                            valueListenable: startDate,
                            builder:
                                (context, value, _) => TextButton(
                                  onPressed: () async {
                                    final picked = await showDatePicker(
                                      context: context,
                                      initialDate: value,
                                      firstDate: DateTime.now().subtract(
                                        const Duration(days: 365),
                                      ),
                                      lastDate: DateTime.now().add(
                                        const Duration(days: 365),
                                      ),
                                    );
                                    if (picked != null)
                                      startDate.value = picked;
                                  },
                                  child: Text(
                                    'Start: ${value.toLocal().toString().split(' ')[0]}',
                                  ),
                                ),
                          ),
                        ),
                        Expanded(
                          child: ValueListenableBuilder<DateTime>(
                            valueListenable: endDate,
                            builder:
                                (context, value, _) => TextButton(
                                  onPressed: () async {
                                    final picked = await showDatePicker(
                                      context: context,
                                      initialDate: value,
                                      firstDate: DateTime.now().subtract(
                                        const Duration(days: 365),
                                      ),
                                      lastDate: DateTime.now().add(
                                        const Duration(days: 365),
                                      ),
                                    );
                                    if (picked != null) endDate.value = picked;
                                  },
                                  child: Text(
                                    'End: ${value.toLocal().toString().split(' ')[0]}',
                                  ),
                                ),
                          ),
                        ),
                      ],
                    ),
                    ValueListenableBuilder<bool>(
                      valueListenable: isActive,
                      builder:
                          (context, value, _) => SwitchListTile(
                            value: value,
                            onChanged: (v) => isActive.value = v,
                            title: const Text('Active'),
                          ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Apply to Specific Products',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    ValueListenableBuilder<Future<List<ProductModel>>?>(
                      valueListenable: productsFuture,
                      builder: (context, future, _) {
                        if (future == null) return const SizedBox.shrink();
                        return FutureBuilder<List<ProductModel>>(
                          future: future,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const CircularProgressIndicator();
                            }
                            if (!snapshot.hasData || snapshot.data!.isEmpty) {
                              return const Text('No products available.');
                            }
                            final products = snapshot.data!;
                            return ValueListenableBuilder<List<String>>(
                              valueListenable: applicableProducts,
                              builder:
                                  (context, selectedProducts, _) => Column(
                                    children: [
                                      DropdownButtonFormField<String>(
                                        decoration: const InputDecoration(
                                          labelText: 'Select Products',
                                        ),
                                        items:
                                            products
                                                .map(
                                                  (p) => DropdownMenuItem(
                                                    value: p.id ?? '',
                                                    child: Text(
                                                      p.name ??
                                                          'Unknown Product',
                                                    ),
                                                  ),
                                                )
                                                .toList(),
                                        onChanged: (value) {
                                          if (value != null &&
                                              !selectedProducts.contains(
                                                value,
                                              )) {
                                            applicableProducts.value = [
                                              ...selectedProducts,
                                              value,
                                            ];
                                          }
                                        },
                                      ),
                                      if (selectedProducts.isNotEmpty)
                                        Wrap(
                                          spacing: 8.0,
                                          children:
                                              selectedProducts.map((id) {
                                                final product = products
                                                    .firstWhere(
                                                      (p) => p.id == id,
                                                    );
                                                return Chip(
                                                  label: Text(
                                                    product.name ??
                                                        'Unknown Product',
                                                  ),
                                                  onDeleted: () {
                                                    applicableProducts.value =
                                                        selectedProducts
                                                            .where(
                                                              (p) => p != id,
                                                            )
                                                            .toList();
                                                  },
                                                );
                                              }).toList(),
                                        ),
                                    ],
                                  ),
                            );
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Apply to Specific Categories',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    ValueListenableBuilder<Future<List<String>>?>(
                      valueListenable: categoriesFuture,
                      builder: (context, future, _) {
                        if (future == null) return const SizedBox.shrink();
                        return FutureBuilder<List<String>>(
                          future: future,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const CircularProgressIndicator();
                            }
                            if (!snapshot.hasData || snapshot.data!.isEmpty) {
                              return const Text('No categories available.');
                            }
                            final categories = snapshot.data!;
                            return ValueListenableBuilder<List<String>>(
                              valueListenable: applicableCategories,
                              builder:
                                  (context, selectedCategories, _) => Column(
                                    children: [
                                      DropdownButtonFormField<String>(
                                        decoration: const InputDecoration(
                                          labelText: 'Select Categories',
                                        ),
                                        items:
                                            categories
                                                .map(
                                                  (c) => DropdownMenuItem(
                                                    value: c,
                                                    child: Text(c),
                                                  ),
                                                )
                                                .toList(),
                                        onChanged: (value) {
                                          if (value != null &&
                                              !selectedCategories.contains(
                                                value,
                                              )) {
                                            applicableCategories.value = [
                                              ...selectedCategories,
                                              value,
                                            ];
                                          }
                                        },
                                      ),
                                      if (selectedCategories.isNotEmpty)
                                        Wrap(
                                          spacing: 8.0,
                                          children:
                                              selectedCategories
                                                  .map(
                                                    (cat) => Chip(
                                                      label: Text(cat),
                                                      onDeleted: () {
                                                        applicableCategories
                                                                .value =
                                                            selectedCategories
                                                                .where(
                                                                  (c) =>
                                                                      c != cat,
                                                                )
                                                                .toList();
                                                      },
                                                    ),
                                                  )
                                                  .toList(),
                                        ),
                                    ],
                                  ),
                            );
                          },
                        );
                      },
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
                  if (formKey.currentState!.validate()) {
                    final newCoupon = Coupon(
                      id:
                          coupon?.id ??
                          DateTime.now().millisecondsSinceEpoch.toString(),
                      code: codeController.text.trim().toUpperCase(),
                      name: nameController.text.trim(),
                      description: descController.text.trim(),
                      type: type.value,
                      value: double.parse(valueController.text.trim()),
                      startDate: startDate.value,
                      endDate: endDate.value,
                      isActive: isActive.value,
                      createdAt: coupon?.createdAt ?? DateTime.now(),
                      updatedAt: DateTime.now(),
                      sellerId: sellerId,
                      applicableProducts:
                          applicableProducts.value.isNotEmpty
                              ? applicableProducts.value
                              : null,
                      applicableCategories:
                          applicableCategories.value.isNotEmpty
                              ? applicableCategories.value
                              : null,
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
