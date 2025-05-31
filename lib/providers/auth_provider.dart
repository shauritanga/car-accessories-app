import 'package:car_accessories/models/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Auth state class
class AuthState {
  final UserModel? user;
  final bool isLoading;
  final String? error;

  AuthState({this.user, this.isLoading = false, this.error});

  AuthState copyWith({UserModel? user, bool? isLoading, String? error}) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

// Auth notifier
class AuthNotifier extends StateNotifier<AuthState> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  AuthNotifier() : super(AuthState()) {
    _init();
  }

  void _init() {
    _auth.authStateChanges().listen((User? user) async {
      if (user == null) {
        state = AuthState();
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
            );
            state = AuthState(user: userModel);
          } else {
            state = AuthState();
          }
        } catch (e) {
          state = AuthState(error: e.toString());
        }
      }
    });
  }

  Future<void> signIn(String email, String password) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      await _auth.signInWithEmailAndPassword(email: email, password: password);
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
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'email': email,
        'name': name,
        'phone': phone,
        'role': role,
        'createdAt': FieldValue.serverTimestamp(),
      });
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
      await _auth.signOut();
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
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
