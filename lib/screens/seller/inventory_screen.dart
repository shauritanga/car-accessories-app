import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../../providers/auth_provider.dart';
import '../../providers/inventory_provider.dart';
import '../../models/inventory_model.dart';
import '../../widgets/inventory_product_card.dart';
import '../../widgets/custom_button.dart';

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen>
    with SingleTickerProviderStateMixin {
  late final SlidableController controller;

  @override
  void initState() {
    super.initState();
    controller = SlidableController(this);
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final inventoryAsync =
        user != null
            ? ref.watch(inventoryStreamProvider(user.id))
            : const AsyncValue.data(
              <InventoryModel>[],
            ); // Empty list if no user
    final inventoryNotifier = ref.read(inventoryProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Inventory')),
      body: inventoryAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return const Center(child: Text('No inventory items'));
          }
          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return Dismissible(
                key: ValueKey(item.id),
                confirmDismiss: (direction) async {
                  if (direction == DismissDirection.endToStart) {
                    return await showDialog(
                      context: context,
                      builder:
                          (context) => AlertDialog(
                            title: const Text('Delete Inventory'),
                            content: const Text(
                              'Are you sure you want to delete this item?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () async {
                                  try {
                                    await inventoryNotifier.deleteInventory(
                                      item.id,
                                    );
                                    Navigator.pop(context, true);
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Failed to delete: $e'),
                                      ),
                                    );
                                    Navigator.pop(context, false);
                                  }
                                },
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                    );
                  }
                  return false;
                },
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                child: InventoryProductCard(
                  inventory: item,
                  onPressed: () {
                    _showEditInventoryDialog(context, item, inventoryNotifier);
                  },
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/add_product'),
        child: const Icon(Icons.add),
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
