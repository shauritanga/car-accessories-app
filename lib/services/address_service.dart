import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/address_model.dart';

class AddressService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Add a new address
  Future<void> addAddress(AddressModel address) async {
    try {
      // If this is set as default, remove default from other addresses
      if (address.isDefault) {
        await _removeDefaultFromOtherAddresses(address.userId);
      }

      await _firestore.collection('addresses').doc(address.id).set(address.toMap());
    } catch (e) {
      throw Exception('Failed to add address: $e');
    }
  }

  // Update an existing address
  Future<void> updateAddress(AddressModel address) async {
    try {
      // If this is set as default, remove default from other addresses
      if (address.isDefault) {
        await _removeDefaultFromOtherAddresses(address.userId, excludeId: address.id);
      }

      await _firestore.collection('addresses').doc(address.id).update(
        address.copyWith(updatedAt: DateTime.now()).toMap(),
      );
    } catch (e) {
      throw Exception('Failed to update address: $e');
    }
  }

  // Delete an address
  Future<void> deleteAddress(String addressId) async {
    try {
      await _firestore.collection('addresses').doc(addressId).delete();
    } catch (e) {
      throw Exception('Failed to delete address: $e');
    }
  }

  // Get all addresses for a user
  Stream<List<AddressModel>> getUserAddresses(String userId) {
    return _firestore
        .collection('addresses')
        .where('userId', isEqualTo: userId)
        .orderBy('isDefault', descending: true)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AddressModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Get default address for a user
  Future<AddressModel?> getDefaultAddress(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('addresses')
          .where('userId', isEqualTo: userId)
          .where('isDefault', isEqualTo: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        return AddressModel.fromMap(doc.data(), doc.id);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get default address: $e');
    }
  }

  // Set an address as default
  Future<void> setDefaultAddress(String userId, String addressId) async {
    try {
      final batch = _firestore.batch();

      // Remove default from all user's addresses
      await _removeDefaultFromOtherAddresses(userId);

      // Set new default
      batch.update(
        _firestore.collection('addresses').doc(addressId),
        {
          'isDefault': true,
          'updatedAt': FieldValue.serverTimestamp(),
        },
      );

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to set default address: $e');
    }
  }

  // Get address by ID
  Future<AddressModel?> getAddressById(String addressId) async {
    try {
      final doc = await _firestore.collection('addresses').doc(addressId).get();
      if (doc.exists) {
        return AddressModel.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get address: $e');
    }
  }

  // Search addresses by query
  Future<List<AddressModel>> searchAddresses(String userId, String query) async {
    try {
      final querySnapshot = await _firestore
          .collection('addresses')
          .where('userId', isEqualTo: userId)
          .get();

      final addresses = querySnapshot.docs
          .map((doc) => AddressModel.fromMap(doc.data(), doc.id))
          .toList();

      // Filter addresses based on search query
      final filteredAddresses = addresses.where((address) {
        final searchText = query.toLowerCase();
        return address.fullName.toLowerCase().contains(searchText) ||
            address.street.toLowerCase().contains(searchText) ||
            address.city.toLowerCase().contains(searchText) ||
            address.state.toLowerCase().contains(searchText) ||
            address.displayName.toLowerCase().contains(searchText);
      }).toList();

      return filteredAddresses;
    } catch (e) {
      throw Exception('Failed to search addresses: $e');
    }
  }

  // Get addresses by type
  Stream<List<AddressModel>> getAddressesByType(String userId, AddressType type) {
    return _firestore
        .collection('addresses')
        .where('userId', isEqualTo: userId)
        .where('type', isEqualTo: type.toString())
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AddressModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Validate address completeness
  bool isAddressComplete(AddressModel address) {
    return address.isComplete;
  }

  // Get address suggestions based on partial input
  Future<List<String>> getAddressSuggestions(String partialAddress) async {
    // This would typically integrate with a geocoding service like Google Places API
    // For now, return some common Tanzanian locations
    final suggestions = <String>[
      'Dar es Salaam, Tanzania',
      'Arusha, Tanzania',
      'Mwanza, Tanzania',
      'Dodoma, Tanzania',
      'Mbeya, Tanzania',
      'Morogoro, Tanzania',
      'Tanga, Tanzania',
      'Kahama, Tanzania',
      'Tabora, Tanzania',
      'Kigoma, Tanzania',
    ];

    if (partialAddress.isEmpty) return suggestions;

    return suggestions
        .where((suggestion) =>
            suggestion.toLowerCase().contains(partialAddress.toLowerCase()))
        .toList();
  }

  // Private helper method to remove default from other addresses
  Future<void> _removeDefaultFromOtherAddresses(String userId, {String? excludeId}) async {
    final querySnapshot = await _firestore
        .collection('addresses')
        .where('userId', isEqualTo: userId)
        .where('isDefault', isEqualTo: true)
        .get();

    final batch = _firestore.batch();
    for (final doc in querySnapshot.docs) {
      if (excludeId == null || doc.id != excludeId) {
        batch.update(doc.reference, {
          'isDefault': false,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    }

    if (querySnapshot.docs.isNotEmpty) {
      await batch.commit();
    }
  }

  // Estimate delivery time based on address (mock implementation)
  String estimateDeliveryTime(AddressModel address) {
    // This would typically integrate with a delivery service API
    // For now, provide estimates based on city
    switch (address.city.toLowerCase()) {
      case 'dar es salaam':
        return '1-2 business days';
      case 'arusha':
      case 'mwanza':
      case 'dodoma':
        return '2-3 business days';
      default:
        return '3-5 business days';
    }
  }

  // Calculate delivery fee based on address (mock implementation)
  double calculateDeliveryFee(AddressModel address) {
    // This would typically integrate with a delivery service API
    // For now, provide fees based on city
    switch (address.city.toLowerCase()) {
      case 'dar es salaam':
        return 5000.0; // TZS 5,000
      case 'arusha':
      case 'mwanza':
      case 'dodoma':
        return 8000.0; // TZS 8,000
      default:
        return 12000.0; // TZS 12,000
    }
  }
}
