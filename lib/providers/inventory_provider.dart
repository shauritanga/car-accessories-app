import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/inventory_service.dart';
import '../models/inventory_model.dart';

// State class to hold the inventory list
class InventoryState {
  final List<InventoryModel> inventories;

  InventoryState({this.inventories = const []});

  InventoryState copyWith({List<InventoryModel>? inventories}) {
    return InventoryState(inventories: inventories ?? this.inventories);
  }
}

// StateNotifier to manage inventory state
class InventoryNotifier extends StateNotifier<InventoryState> {
  final InventoryService _inventoryService = InventoryService();

  InventoryNotifier() : super(InventoryState());

  // Update or add inventory item
  Future<void> updateInventory(InventoryModel inventory) async {
    try {
      await _inventoryService.updateInventory(inventory);

      // Update local state
      final updatedInventories =
          state.inventories.where((item) => item.id != inventory.id).toList()
            ..add(inventory);
      state = state.copyWith(inventories: updatedInventories);

      // Check for low stock (optional)
      if (inventory.stock < 10) {
        // Trigger notification (requires NotificationService integration)
        // Example: await NotificationService().showNotification(
        //   'Low Stock Alert',
        //   '${inventory.productId} has only ${inventory.stock} units left.',
        // );
      }
    } catch (e) {
      throw Exception('Failed to update inventory: $e');
    }
  }

  // Delete inventory item
  Future<void> deleteInventory(String inventoryId) async {
    try {
      await _inventoryService.deleteInventory(inventoryId);
      final updatedInventories =
          state.inventories.where((item) => item.id != inventoryId).toList();
      state = state.copyWith(inventories: updatedInventories);
    } catch (e) {
      throw Exception('Failed to delete inventory: $e');
    }
  }
}

// StateNotifierProvider for managing inventory state
final inventoryProvider =
    StateNotifierProvider<InventoryNotifier, InventoryState>((ref) {
      return InventoryNotifier();
    });

// StreamProvider for real-time inventory updates
final inventoryStreamProvider =
    StreamProvider.family<List<InventoryModel>, String>((ref, sellerId) {
      final inventoryService = InventoryService();
      return inventoryService.getInventory(sellerId);
    });

// Provider to get the current inventory list (for convenience in UI)
final currentInventoryProvider = Provider<List<InventoryModel>>((ref) {
  return ref.watch(inventoryProvider).inventories;
});
