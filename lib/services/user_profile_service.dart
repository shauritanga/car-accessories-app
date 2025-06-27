import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import '../models/user_profile_model.dart';
import '../models/user_model.dart';

class UserProfileService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Uuid _uuid = const Uuid();

  // Profile Management
  Future<void> updateUserProfile({
    required String userId,
    String? firstName,
    String? lastName,
    String? phoneNumber,
    String? dateOfBirth,
    String? gender,
    String? profileImageUrl,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (firstName != null) updateData['firstName'] = firstName;
      if (lastName != null) updateData['lastName'] = lastName;
      if (phoneNumber != null) updateData['phoneNumber'] = phoneNumber;
      if (dateOfBirth != null) updateData['dateOfBirth'] = dateOfBirth;
      if (gender != null) updateData['gender'] = gender;
      if (profileImageUrl != null)
        updateData['profileImageUrl'] = profileImageUrl;

      await _firestore.collection('users').doc(userId).update(updateData);
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  Future<UserModel?> getUserProfile(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user profile: $e');
    }
  }

  // Address Management
  Future<UserAddress> addAddress({
    required String userId,
    required String label,
    required String fullName,
    required String phoneNumber,
    required String addressLine1,
    String addressLine2 = '',
    required String city,
    required String state,
    required String postalCode,
    required String country,
    bool isDefault = false,
  }) async {
    try {
      final addressId = _uuid.v4();
      final address = UserAddress(
        id: addressId,
        label: label,
        fullName: fullName,
        phoneNumber: phoneNumber,
        addressLine1: addressLine1,
        addressLine2: addressLine2,
        city: city,
        state: state,
        postalCode: postalCode,
        country: country,
        isDefault: isDefault,
        createdAt: DateTime.now(),
      );

      // If this is set as default, unset other defaults
      if (isDefault) {
        await _unsetDefaultAddresses(userId);
      }

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('addresses')
          .doc(addressId)
          .set(address.toMap());

      return address;
    } catch (e) {
      throw Exception('Failed to add address: $e');
    }
  }

  Future<List<UserAddress>> getUserAddresses(String userId) async {
    try {
      final snapshot =
          await _firestore
              .collection('users')
              .doc(userId)
              .collection('addresses')
              .orderBy('isDefault', descending: true)
              .orderBy('createdAt', descending: false)
              .get();

      return snapshot.docs
          .map((doc) => UserAddress.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to get addresses: $e');
    }
  }

  Future<void> updateAddress(String userId, UserAddress address) async {
    try {
      // If this is set as default, unset other defaults
      if (address.isDefault) {
        await _unsetDefaultAddresses(userId);
      }

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('addresses')
          .doc(address.id)
          .update(address.copyWith(updatedAt: DateTime.now()).toMap());
    } catch (e) {
      throw Exception('Failed to update address: $e');
    }
  }

  Future<void> deleteAddress(String userId, String addressId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('addresses')
          .doc(addressId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete address: $e');
    }
  }

  Future<void> _unsetDefaultAddresses(String userId) async {
    final addresses = await getUserAddresses(userId);
    final batch = _firestore.batch();

    for (final address in addresses.where((a) => a.isDefault)) {
      final ref = _firestore
          .collection('users')
          .doc(userId)
          .collection('addresses')
          .doc(address.id);
      batch.update(ref, {'isDefault': false});
    }

    await batch.commit();
  }

  // Payment Methods Management
  Future<PaymentMethod> addPaymentMethod({
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
    try {
      final paymentId = _uuid.v4();
      final paymentMethod = PaymentMethod(
        id: paymentId,
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
        createdAt: DateTime.now(),
      );

      // If this is set as default, unset other defaults
      if (isDefault) {
        await _unsetDefaultPaymentMethods(userId);
      }

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('payment_methods')
          .doc(paymentId)
          .set(paymentMethod.toMap());

      return paymentMethod;
    } catch (e) {
      throw Exception('Failed to add payment method: $e');
    }
  }

  Future<List<PaymentMethod>> getUserPaymentMethods(String userId) async {
    try {
      final snapshot =
          await _firestore
              .collection('users')
              .doc(userId)
              .collection('payment_methods')
              .orderBy('isDefault', descending: true)
              .orderBy('createdAt', descending: false)
              .get();

      return snapshot.docs
          .map((doc) => PaymentMethod.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to get payment methods: $e');
    }
  }

  Future<void> updatePaymentMethod(
    String userId,
    PaymentMethod paymentMethod,
  ) async {
    try {
      // If this is set as default, unset other defaults
      if (paymentMethod.isDefault) {
        await _unsetDefaultPaymentMethods(userId);
      }

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('payment_methods')
          .doc(paymentMethod.id)
          .update(paymentMethod.toMap());
    } catch (e) {
      throw Exception('Failed to update payment method: $e');
    }
  }

  Future<void> deletePaymentMethod(
    String userId,
    String paymentMethodId,
  ) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('payment_methods')
          .doc(paymentMethodId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete payment method: $e');
    }
  }

  Future<void> _unsetDefaultPaymentMethods(String userId) async {
    final paymentMethods = await getUserPaymentMethods(userId);
    final batch = _firestore.batch();

    for (final method in paymentMethods.where((m) => m.isDefault)) {
      final ref = _firestore
          .collection('users')
          .doc(userId)
          .collection('payment_methods')
          .doc(method.id);
      batch.update(ref, {'isDefault': false});
    }

    await batch.commit();
  }

  // User Preferences Management
  Future<UserPreferences> getUserPreferences(String userId) async {
    try {
      final doc =
          await _firestore
              .collection('users')
              .doc(userId)
              .collection('preferences')
              .doc('settings')
              .get();

      if (doc.exists) {
        return UserPreferences.fromMap(doc.data()!);
      } else {
        // Create default preferences
        final defaultPrefs = UserPreferences(
          userId: userId,
          createdAt: DateTime.now(),
        );
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('preferences')
            .doc('settings')
            .set(defaultPrefs.toMap());
        return defaultPrefs;
      }
    } catch (e) {
      throw Exception('Failed to get user preferences: $e');
    }
  }

  Future<void> updateUserPreferences(UserPreferences preferences) async {
    try {
      await _firestore
          .collection('users')
          .doc(preferences.userId)
          .collection('preferences')
          .doc('settings')
          .update(preferences.copyWith(updatedAt: DateTime.now()).toMap());
    } catch (e) {
      throw Exception('Failed to update preferences: $e');
    }
  }

  // Account Security
  Future<void> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Re-authenticate user
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);

      // Update password
      await user.updatePassword(newPassword);
    } catch (e) {
      throw Exception('Failed to change password: $e');
    }
  }

  Future<void> updateEmail(String newEmail, String password) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Re-authenticate user
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );
      await user.reauthenticateWithCredential(credential);

      // Update email
      await user.verifyBeforeUpdateEmail(newEmail);

      // Update in Firestore
      await _firestore.collection('users').doc(user.uid).update({
        'email': newEmail,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update email: $e');
    }
  }

  // Account Deletion
  Future<void> deleteAccount(String password) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Re-authenticate user
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );
      await user.reauthenticateWithCredential(credential);

      // Delete user data from Firestore
      await _deleteUserData(user.uid);

      // Delete Firebase Auth account
      await user.delete();
    } catch (e) {
      throw Exception('Failed to delete account: $e');
    }
  }

  Future<void> _deleteUserData(String userId) async {
    final batch = _firestore.batch();

    // Delete user document
    batch.delete(_firestore.collection('users').doc(userId));

    // Delete subcollections (addresses, payment methods, preferences)
    final collections = ['addresses', 'payment_methods', 'preferences'];

    for (final collection in collections) {
      final snapshot =
          await _firestore
              .collection('users')
              .doc(userId)
              .collection(collection)
              .get();

      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
    }

    await batch.commit();
  }

  // Data Export (GDPR compliance)
  Future<Map<String, dynamic>> exportUserData(String userId) async {
    try {
      final userData = <String, dynamic>{};

      // Get user profile
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        userData['profile'] = userDoc.data();
      }

      // Get addresses
      final addressesSnapshot =
          await _firestore
              .collection('users')
              .doc(userId)
              .collection('addresses')
              .get();
      userData['addresses'] =
          addressesSnapshot.docs.map((doc) => doc.data()).toList();

      // Get payment methods (without sensitive data)
      final paymentSnapshot =
          await _firestore
              .collection('users')
              .doc(userId)
              .collection('payment_methods')
              .get();
      userData['payment_methods'] =
          paymentSnapshot.docs.map((doc) {
            final data = doc.data();
            // Remove sensitive payment data
            data.remove('cardNumber');
            data.remove('accountNumber');
            return data;
          }).toList();

      // Get preferences
      final prefsDoc =
          await _firestore
              .collection('users')
              .doc(userId)
              .collection('preferences')
              .doc('settings')
              .get();
      if (prefsDoc.exists) {
        userData['preferences'] = prefsDoc.data();
      }

      return userData;
    } catch (e) {
      throw Exception('Failed to export user data: $e');
    }
  }
}
