import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/inventory_model.dart';

class InventoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> updateInventory(InventoryModel inventory) async {
    try {
      await _firestore
          .collection('inventory')
          .doc(inventory.id)
          .set(inventory.toMap());
    } catch (e) {
      throw Exception('Failed to update inventory: $e');
    }
  }

  Stream<List<InventoryModel>> getInventory(String sellerId) {
    return _firestore
        .collection('inventory')
        .where('sellerId', isEqualTo: sellerId)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map(
                    (doc) =>
                        InventoryModel.fromMap({...doc.data(), 'id': doc.id}),
                  )
                  .toList(),
        );
  }

  Future<void> deleteInventory(String inventoryId) async {
    try {
      await _firestore.collection('inventory').doc(inventoryId).delete();
    } catch (e) {
      throw Exception('Failed to delete inventory: $e');
    }
  }
}
