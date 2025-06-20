import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/address_model.dart';
import '../services/address_service.dart';

class AddressState {
  final List<AddressModel> addresses;
  final AddressModel? selectedAddress;
  final bool isLoading;
  final String? error;

  AddressState({
    this.addresses = const [],
    this.selectedAddress,
    this.isLoading = false,
    this.error,
  });

  AddressState copyWith({
    List<AddressModel>? addresses,
    AddressModel? selectedAddress,
    bool? isLoading,
    String? error,
  }) {
    return AddressState(
      addresses: addresses ?? this.addresses,
      selectedAddress: selectedAddress ?? this.selectedAddress,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class AddressNotifier extends StateNotifier<AddressState> {
  final AddressService _addressService = AddressService();

  AddressNotifier() : super(AddressState());

  Future<void> addAddress(AddressModel address) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _addressService.addAddress(address);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> updateAddress(AddressModel address) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _addressService.updateAddress(address);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> deleteAddress(String addressId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _addressService.deleteAddress(addressId);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> setDefaultAddress(String userId, String addressId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _addressService.setDefaultAddress(userId, addressId);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  void selectAddress(AddressModel? address) {
    state = state.copyWith(selectedAddress: address);
  }

  Future<AddressModel?> getDefaultAddress(String userId) async {
    try {
      return await _addressService.getDefaultAddress(userId);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  Future<List<AddressModel>> searchAddresses(String userId, String query) async {
    try {
      return await _addressService.searchAddresses(userId, query);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return [];
    }
  }

  Future<List<String>> getAddressSuggestions(String partialAddress) async {
    try {
      return await _addressService.getAddressSuggestions(partialAddress);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return [];
    }
  }

  String estimateDeliveryTime(AddressModel address) {
    return _addressService.estimateDeliveryTime(address);
  }

  double calculateDeliveryFee(AddressModel address) {
    return _addressService.calculateDeliveryFee(address);
  }

  bool isAddressComplete(AddressModel address) {
    return _addressService.isAddressComplete(address);
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Providers
final addressProvider = StateNotifierProvider<AddressNotifier, AddressState>((ref) {
  return AddressNotifier();
});

// Stream provider for user addresses
final userAddressesStreamProvider = StreamProvider.family<List<AddressModel>, String>((ref, userId) {
  final addressService = AddressService();
  return addressService.getUserAddresses(userId);
});

// Stream provider for addresses by type
final addressesByTypeStreamProvider = StreamProvider.family<List<AddressModel>, AddressTypeFilter>((ref, filter) {
  final addressService = AddressService();
  return addressService.getAddressesByType(filter.userId, filter.type);
});

// Future provider for default address
final defaultAddressProvider = FutureProvider.family<AddressModel?, String>((ref, userId) {
  final addressService = AddressService();
  return addressService.getDefaultAddress(userId);
});

// Address type filter class
class AddressTypeFilter {
  final String userId;
  final AddressType type;

  AddressTypeFilter({
    required this.userId,
    required this.type,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AddressTypeFilter &&
          runtimeType == other.runtimeType &&
          userId == other.userId &&
          type == other.type;

  @override
  int get hashCode => userId.hashCode ^ type.hashCode;
}
