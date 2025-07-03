import 'package:car_accessories/models/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/enhanced_auth_service.dart';

// Auth state class
class AuthState {
  final UserModel? user;
  final bool isLoading;
  final String? error;
  final bool isEmailVerified;
  final bool requiresTwoFactor;
  final bool isAccountLocked;
  final int lockoutTimeRemaining;
  final String? rememberedEmail;

  AuthState({
    this.user,
    this.isLoading = false,
    this.error,
    this.isEmailVerified = false,
    this.requiresTwoFactor = false,
    this.isAccountLocked = false,
    this.lockoutTimeRemaining = 0,
    this.rememberedEmail,
  });

  AuthState copyWith({
    UserModel? user,
    bool? isLoading,
    String? error,
    bool? isEmailVerified,
    bool? requiresTwoFactor,
    bool? isAccountLocked,
    int? lockoutTimeRemaining,
    String? rememberedEmail,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      requiresTwoFactor: requiresTwoFactor ?? this.requiresTwoFactor,
      isAccountLocked: isAccountLocked ?? this.isAccountLocked,
      lockoutTimeRemaining: lockoutTimeRemaining ?? this.lockoutTimeRemaining,
      rememberedEmail: rememberedEmail ?? this.rememberedEmail,
    );
  }
}

// Auth notifier
class AuthNotifier extends StateNotifier<AuthState> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final EnhancedAuthService _enhancedAuth = EnhancedAuthService();

  AuthNotifier() : super(AuthState()) {
    _init();
  }

  void _init() async {
    // Load remembered email
    final rememberedEmail = await _enhancedAuth.getRememberedEmail();
    state = state.copyWith(rememberedEmail: rememberedEmail);

    _auth.authStateChanges().listen((User? user) async {
      if (user == null) {
        final rememberedEmail = await _enhancedAuth.getRememberedEmail();
        state = AuthState(rememberedEmail: rememberedEmail);
      } else {
        try {
          state = state.copyWith(isLoading: true);
          final userDoc =
              await _firestore.collection('users').doc(user.uid).get();

          if (userDoc.exists) {
            final userData = userDoc.data() as Map<String, dynamic>;
            final userModel = UserModel(
              id: user.uid,
              email: user.email,
              name: userData['name'],
              phone: userData['phone'],
              role: userData['role'] ?? 'customer',
              status: userData['status'] ?? 'active',
            );

            // Update last login
            await _enhancedAuth.updateLastLogin();

            state = AuthState(
              user: userModel,
              isEmailVerified: user.emailVerified,
            );
          } else {
            state = AuthState();
          }
        } catch (e) {
          state = AuthState(error: e.toString());
        }
      }
    });
  }

  Future<void> signIn(
    String email,
    String password, {
    bool rememberMe = false,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      // Check if account is locked
      if (await _enhancedAuth.isAccountLockedOut(email)) {
        final remainingTime = await _enhancedAuth.getRemainingLockoutTime(
          email,
        );
        state = state.copyWith(
          isLoading: false,
          isAccountLocked: true,
          lockoutTimeRemaining: remainingTime,
          error: 'Account locked for $remainingTime minutes',
        );
        return;
      }

      await _enhancedAuth.signInWithEmailAndPassword(email, password);

      // Set remember me preference
      await _enhancedAuth.setRememberMe(rememberMe, email);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> register(
    String email,
    String password,
    String role,
    String name,
    String phone,
  ) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      // Create Firebase Auth user
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user == null) {
        throw Exception('Failed to create user account');
      }

      final userId = userCredential.user!.uid;

      // Create user document in Firestore
      final userData = {
        'email': email,
        'name': name,
        'phone': phone,
        'role': role,
        'status': role == 'seller' ? 'pending' : 'active',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'isActive': true,
      };

      await _firestore.collection('users').doc(userId).set(userData);

      // Verify the document was created
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) {
        throw Exception('Failed to create user document in Firestore');
      }

      // Update loading state
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      await _auth.sendPasswordResetEmail(email: email);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _enhancedAuth.signOut();
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  // Google Sign In
  Future<void> signInWithGoogle() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      await _enhancedAuth.signInWithGoogle();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  // Send email verification
  Future<void> sendEmailVerification() async {
    try {
      await _enhancedAuth.sendEmailVerification();
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  // Check password strength
  Map<String, bool> validatePasswordStrength(String password) {
    return _enhancedAuth.validatePasswordStrength(password);
  }

  // Generate 2FA code
  Future<String> generate2FACode(String email) async {
    try {
      return await _enhancedAuth.generateAndSend2FACode(email);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  // Verify 2FA code
  Future<bool> verify2FACode(String email, String code) async {
    try {
      return await _enhancedAuth.verify2FACode(email, code);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  // Clear authentication errors
  void clearError() {
    state = state.copyWith(error: null);
  }

  // Clear account lockout status
  void clearLockout() {
    state = state.copyWith(isAccountLocked: false, lockoutTimeRemaining: 0);
  }
}

// Providers
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

final currentUserProvider = Provider<UserModel?>((ref) {
  return ref.watch(authProvider).user;
});

final userRoleProvider = Provider<String>((ref) {
  return ref.watch(authProvider).user?.role ?? 'customer';
});
