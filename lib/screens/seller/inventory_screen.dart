import 'package:car_accessories/router/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/inventory_provider.dart';
import '../../models/inventory_model.dart';
import '../../widgets/inventory_product_card.dart';
import '../../widgets/custom_button.dart';
import 'pending_approval_screen.dart';
import '../../services/product_service.dart';
import '../../models/product_model.dart';

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    if (user?.role == 'seller' && user?.status != 'approved') {
      return const PendingApprovalScreen();
    }
    final inventoryAsync =
        user != null
            ? ref.watch(inventoryStreamProvider(user.id))
            : const AsyncValue.data(<InventoryModel>[]);
    final inventoryNotifier = ref.read(inventoryProvider.notifier);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory'),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: inventoryAsync.when(
          data: (items) {
            if (items.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.inventory_2,
                      size: 80,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'No inventory items',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: colorScheme.onBackground.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add products to start selling!',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onBackground.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              );
            }
            return GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.85,
              ),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return FutureBuilder<ProductModel>(
                  future: ProductService().getProduct(item.productId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.hasError) {
                      return Material(
                        color: Colors.white,
                        elevation: 4,
                        borderRadius: BorderRadius.circular(18),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Center(
                            child: Text('Product not found'),
                          ),
                        ),
                      );
                    }
                    final product = snapshot.data!;
                    Color stockColor;
                    String stockStatus;
                    if (item.stock == 0) {
                      stockColor = Colors.red;
                      stockStatus = 'Out of Stock';
                    } else if (item.stock <= 5) {
                      stockColor = Colors.orange;
                      stockStatus = 'Low Stock';
                    } else {
                      stockColor = Colors.green;
                      stockStatus = 'In Stock';
                    }
                    return Material(
                      color: Colors.white,
                      elevation: 4,
                      borderRadius: BorderRadius.circular(18),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: () {
                          _showEditInventoryDialog(
                            context,
                            item,
                            inventoryNotifier,
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: product.images.isNotEmpty
                                        ? Image.network(
                                            product.images.first,
                                            width: 60,
                                            height: 60,
                                            fit: BoxFit.cover,
                                          )
                                        : Container(
                                            width: 60,
                                            height: 60,
                                            color: Colors.grey[300],
                                            child: const Icon(Icons.image_not_supported),
                                          ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.blueAccent),
                                    onPressed: () {
                                      _showEditInventoryDialog(
                                        context,
                                        item,
                                        inventoryNotifier,
                                      );
                                    },
                                    tooltip: 'Edit',
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                product.name,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onBackground,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Stock: ${item.stock}',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: stockColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                stockStatus,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: stockColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Last Updated:',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onBackground.withOpacity(0.5),
                                ),
                              ),
                              Text(
                                '${item.lastUpdated.toLocal()}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onBackground.withOpacity(0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(child: Text('Error: $error')),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.goNamed(AppRoute.addProduct.name),
        icon: const Icon(Icons.add),
        label: const Text('Add Product'),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  void _showEditInventoryDialog(
    BuildContext context,
    InventoryModel item,
    InventoryNotifier inventoryNotifier,
  ) {
    final TextEditingController stockController = TextEditingController(
      text: item.stock.toString(),
    );

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Edit Inventory'),
            content: TextField(
              controller: stockController,
              decoration: const InputDecoration(
                labelText: 'Stock',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              CustomButton(
                text: 'Save',
                onPressed: () async {
                  try {
                    final updatedInventory = InventoryModel(
                      id: item.id,
                      productId: item.productId,
                      sellerId: item.sellerId,
                      stock: int.parse(stockController.text),
                      lastUpdated: DateTime.now(),
                    );
                    await inventoryNotifier.updateInventory(updatedInventory);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Inventory updated successfully'),
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to update: $e')),
                    );
                  }
                },
              ),
            ],
          ),
    );
  }
}
