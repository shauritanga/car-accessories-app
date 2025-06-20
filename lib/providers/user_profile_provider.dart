import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_profile_model.dart';
import '../models/user_model.dart';
import '../services/user_profile_service.dart';

// User Profile State
class UserProfileState {
  final UserModel? user;
  final List<UserAddress> addresses;
  final List<PaymentMethod> paymentMethods;
  final UserPreferences? preferences;
  final bool isLoading;
  final String? error;

  UserProfileState({
    this.user,
    this.addresses = const [],
    this.paymentMethods = const [],
    this.preferences,
    this.isLoading = false,
    this.error,
  });

  UserProfileState copyWith({
    UserModel? user,
    List<UserAddress>? addresses,
    List<PaymentMethod>? paymentMethods,
    UserPreferences? preferences,
    bool? isLoading,
    String? error,
  }) {
    return UserProfileState(
      user: user ?? this.user,
      addresses: addresses ?? this.addresses,
      paymentMethods: paymentMethods ?? this.paymentMethods,
      preferences: preferences ?? this.preferences,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }

  UserAddress? get defaultAddress =>
      addresses.where((a) => a.isDefault).isNotEmpty
          ? addresses.firstWhere((a) => a.isDefault)
          : addresses.isNotEmpty
          ? addresses.first
          : null;

  PaymentMethod? get defaultPaymentMethod =>
      paymentMethods.where((p) => p.isDefault).isNotEmpty
          ? paymentMethods.firstWhere((p) => p.isDefault)
          : paymentMethods.isNotEmpty
          ? paymentMethods.first
          : null;
}

// User Profile Notifier
class UserProfileNotifier extends StateNotifier<UserProfileState> {
  final UserProfileService _profileService = UserProfileService();

  UserProfileNotifier() : super(UserProfileState());

  // Load user profile data
  Future<void> loadUserProfile(String userId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final user = await _profileService.getUserProfile(userId);
      final addresses = await _profileService.getUserAddresses(userId);
      final paymentMethods = await _profileService.getUserPaymentMethods(
        userId,
      );
      final preferences = await _profileService.getUserPreferences(userId);

      state = state.copyWith(
        user: user,
        addresses: addresses,
        paymentMethods: paymentMethods,
        preferences: preferences,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // Update user profile
  Future<void> updateProfile({
    required String userId,
    String? firstName,
    String? lastName,
    String? phoneNumber,
    String? dateOfBirth,
    String? gender,
    String? profileImageUrl,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _profileService.updateUserProfile(
        userId: userId,
        firstName: firstName,
        lastName: lastName,
        phoneNumber: phoneNumber,
        dateOfBirth: dateOfBirth,
        gender: gender,
        profileImageUrl: profileImageUrl,
      );

      // Reload profile
      await loadUserProfile(userId);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  // Address Management
  Future<void> addAddress({
    required String userId,
    required String label,
    required String fullName,
    required String phoneNumber,
    required String addressLine1,
    String addressLine2 = '',
    required String city,
    required String stateProvince,
    required String postalCode,
    required String country,
    bool isDefault = false,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _profileService.addAddress(
        userId: userId,
        label: label,
        fullName: fullName,
        phoneNumber: phoneNumber,
        addressLine1: addressLine1,
        addressLine2: addressLine2,
        city: city,
        state: stateProvince,
        postalCode: postalCode,
        country: country,
        isDefault: isDefault,
      );

      // Reload addresses
      final addresses = await _profileService.getUserAddresses(userId);
      state = state.copyWith(addresses: addresses, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> updateAddress(String userId, UserAddress address) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _profileService.updateAddress(userId, address);

      // Reload addresses
      final addresses = await _profileService.getUserAddresses(userId);
      state = state.copyWith(addresses: addresses, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> deleteAddress(String userId, String addressId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _profileService.deleteAddress(userId, addressId);

      // Reload addresses
      final addresses = await _profileService.getUserAddresses(userId);
      state = state.copyWith(addresses: addresses, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  // Payment Methods Management
  Future<void> addPaymentMethod({
    required String userId,
    required String type,
    required String label,
    String? cardNumber,
    String? cardHolderName,
    String? expiryMonth,
    String? expiryYear,
    String? cardBrand,
    String? mobileNumber,
    String? bankName,
    String? accountNumber,
    bool isDefault = false,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _profileService.addPaymentMethod(
        userId: userId,
        type: type,
        label: label,
        cardNumber: cardNumber,
        cardHolderName: cardHolderName,
        expiryMonth: expiryMonth,
        expiryYear: expiryYear,
        cardBrand: cardBrand,
        mobileNumber: mobileNumber,
        bankName: bankName,
        accountNumber: accountNumber,
        isDefault: isDefault,
      );

      // Reload payment methods
      final paymentMethods = await _profileService.getUserPaymentMethods(
        userId,
      );
      state = state.copyWith(paymentMethods: paymentMethods, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> updatePaymentMethod(
    String userId,
    PaymentMethod paymentMethod,
  ) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _profileService.updatePaymentMethod(userId, paymentMethod);

      // Reload payment methods
      final paymentMethods = await _profileService.getUserPaymentMethods(
        userId,
      );
      state = state.copyWith(paymentMethods: paymentMethods, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> deletePaymentMethod(
    String userId,
    String paymentMethodId,
  ) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _profileService.deletePaymentMethod(userId, paymentMethodId);

      // Reload payment methods
      final paymentMethods = await _profileService.getUserPaymentMethods(
        userId,
      );
      state = state.copyWith(paymentMethods: paymentMethods, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  // Preferences Management
  Future<void> updatePreferences(UserPreferences preferences) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _profileService.updateUserPreferences(preferences);
      state = state.copyWith(preferences: preferences, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  // Account Security
  Future<void> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _profileService.changePassword(currentPassword, newPassword);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> updateEmail(String newEmail, String password) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _profileService.updateEmail(newEmail, password);

      // Reload user profile
      if (state.user != null) {
        await loadUserProfile(state.user!.id);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> deleteAccount(String password) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _profileService.deleteAccount(password);
      // Clear state after successful deletion
      state = UserProfileState();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  // Data Export
  Future<Map<String, dynamic>> exportUserData(String userId) async {
    try {
      return await _profileService.exportUserData(userId);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  // Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Providers
final userProfileProvider =
    StateNotifierProvider<UserProfileNotifier, UserProfileState>((ref) {
      return UserProfileNotifier();
    });

// Stream providers for real-time updates
final userAddressesStreamProvider =
    StreamProvider.family<List<UserAddress>, String>((ref, userId) {
      return FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('addresses')
          .orderBy('isDefault', descending: true)
          .orderBy('createdAt', descending: false)
          .snapshots()
          .map(
            (snapshot) =>
                snapshot.docs
                    .map((doc) => UserAddress.fromMap(doc.data(), doc.id))
                    .toList(),
          );
    });

final userPaymentMethodsStreamProvider =
    StreamProvider.family<List<PaymentMethod>, String>((ref, userId) {
      return FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('payment_methods')
          .orderBy('isDefault', descending: true)
          .orderBy('createdAt', descending: false)
          .snapshots()
          .map(
            (snapshot) =>
                snapshot.docs
                    .map((doc) => PaymentMethod.fromMap(doc.data(), doc.id))
                    .toList(),
          );
    });

final userPreferencesStreamProvider =
    StreamProvider.family<UserPreferences?, String>((ref, userId) {
      return FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('preferences')
          .doc('settings')
          .snapshots()
          .map(
            (snapshot) =>
                snapshot.exists
                    ? UserPreferences.fromMap(snapshot.data()!)
                    : null,
          );
    });
