import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'dart:math';

class EnhancedAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  static const String _failedAttemptsKey = 'failed_login_attempts';
  static const String _lockoutTimeKey = 'lockout_time';
  static const String _rememberMeKey = 'remember_me';
  static const int _maxFailedAttempts = 5;
  static const int _lockoutDurationMinutes = 30;

  // Check if account is locked out
  Future<bool> isAccountLockedOut(String email) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '${_lockoutTimeKey}_${email.toLowerCase()}';
    final lockoutTime = prefs.getInt(key);

    if (lockoutTime != null) {
      final lockoutDateTime = DateTime.fromMillisecondsSinceEpoch(lockoutTime);
      final now = DateTime.now();

      if (now.isBefore(lockoutDateTime)) {
        return true;
      } else {
        // Lockout period has expired, clear it
        await prefs.remove(key);
        await prefs.remove('${_failedAttemptsKey}_${email.toLowerCase()}');
        return false;
      }
    }

    return false;
  }

  // Get remaining lockout time in minutes
  Future<int> getRemainingLockoutTime(String email) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '${_lockoutTimeKey}_${email.toLowerCase()}';
    final lockoutTime = prefs.getInt(key);

    if (lockoutTime != null) {
      final lockoutDateTime = DateTime.fromMillisecondsSinceEpoch(lockoutTime);
      final now = DateTime.now();

      if (now.isBefore(lockoutDateTime)) {
        return lockoutDateTime.difference(now).inMinutes + 1;
      }
    }

    return 0;
  }

  // Record failed login attempt
  Future<void> recordFailedAttempt(String email) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '${_failedAttemptsKey}_${email.toLowerCase()}';
    final attempts = prefs.getInt(key) ?? 0;
    final newAttempts = attempts + 1;

    await prefs.setInt(key, newAttempts);

    if (newAttempts >= _maxFailedAttempts) {
      // Lock the account
      final lockoutTime = DateTime.now().add(
        Duration(minutes: _lockoutDurationMinutes),
      );
      await prefs.setInt(
        '${_lockoutTimeKey}_${email.toLowerCase()}',
        lockoutTime.millisecondsSinceEpoch,
      );
    }
  }

  // Clear failed attempts on successful login
  Future<void> clearFailedAttempts(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('${_failedAttemptsKey}_${email.toLowerCase()}');
    await prefs.remove('${_lockoutTimeKey}_${email.toLowerCase()}');
  }

  // Enhanced sign in with lockout protection
  Future<UserCredential> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    // Check if account is locked out
    if (await isAccountLockedOut(email)) {
      final remainingTime = await getRemainingLockoutTime(email);
      throw FirebaseAuthException(
        code: 'account-locked',
        message:
            'Account is locked due to too many failed attempts. Try again in $remainingTime minutes.',
      );
    }

    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Clear failed attempts on successful login
      await clearFailedAttempts(email);

      return credential;
    } catch (e) {
      // Record failed attempt
      await recordFailedAttempt(email);
      rethrow;
    }
  }

  // Google Sign In
  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);

      // Create user document if it doesn't exist
      if (userCredential.additionalUserInfo?.isNewUser == true) {
        await _createUserDocument(userCredential.user!, {
          'name': googleUser.displayName ?? '',
          'email': googleUser.email,
          'role': 'customer',
          'authProvider': 'google',
          'emailVerified': true,
        });
      }

      return userCredential;
    } catch (e) {
      throw Exception('Google sign in failed: $e');
    }
  }

  // Send email verification
  Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    }
  }

  // Check if email is verified
  bool isEmailVerified() {
    return _auth.currentUser?.emailVerified ?? false;
  }

  // Generate and send 2FA code
  Future<String> generateAndSend2FACode(String email) async {
    final code = _generate6DigitCode();

    // Store code in Firestore with expiration
    await _firestore.collection('2fa_codes').doc(email.toLowerCase()).set({
      'code': _hashCode(code),
      'expiresAt': DateTime.now().add(Duration(minutes: 10)),
      'attempts': 0,
    });

    // In a real app, send this via SMS or email
    // For demo purposes, we'll just return it
    return code;
  }

  // Verify 2FA code
  Future<bool> verify2FACode(String email, String code) async {
    try {
      final doc =
          await _firestore
              .collection('2fa_codes')
              .doc(email.toLowerCase())
              .get();

      if (!doc.exists) return false;

      final data = doc.data()!;
      final storedCodeHash = data['code'] as String;
      final expiresAt = (data['expiresAt'] as Timestamp).toDate();
      final attempts = data['attempts'] as int;

      // Check if code has expired
      if (DateTime.now().isAfter(expiresAt)) {
        await doc.reference.delete();
        return false;
      }

      // Check if too many attempts
      if (attempts >= 3) {
        await doc.reference.delete();
        return false;
      }

      // Verify code
      if (_hashCode(code) == storedCodeHash) {
        await doc.reference.delete();
        return true;
      } else {
        // Increment attempts
        await doc.reference.update({'attempts': attempts + 1});
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  // Password strength validation
  Map<String, bool> validatePasswordStrength(String password) {
    return {
      'minLength': password.length >= 8,
      'hasUppercase': password.contains(RegExp(r'[A-Z]')),
      'hasLowercase': password.contains(RegExp(r'[a-z]')),
      'hasDigits': password.contains(RegExp(r'[0-9]')),
      'hasSpecialChar': password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]')),
    };
  }

  // Check if password meets requirements
  bool isPasswordStrong(String password) {
    final validation = validatePasswordStrength(password);
    return validation.values.every((requirement) => requirement);
  }

  // Remember me functionality
  Future<void> setRememberMe(bool remember, String email) async {
    final prefs = await SharedPreferences.getInstance();
    if (remember) {
      await prefs.setString(_rememberMeKey, email);
    } else {
      await prefs.remove(_rememberMeKey);
    }
  }

  // Get remembered email
  Future<String?> getRememberedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_rememberMeKey);
  }

  // Enhanced registration with email verification
  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
    required String phone,
    String role = 'customer',
  }) async {
    // Validate password strength
    if (!isPasswordStrong(password)) {
      throw FirebaseAuthException(
        code: 'weak-password',
        message: 'Password does not meet security requirements',
      );
    }

    final userCredential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    // Create user document
    await _createUserDocument(userCredential.user!, {
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
      'authProvider': 'email',
      'emailVerified': false,
    });

    // Send email verification
    await sendEmailVerification();

    return userCredential;
  }

  // Create user document in Firestore
  Future<void> _createUserDocument(
    User user,
    Map<String, dynamic> userData,
  ) async {
    await _firestore.collection('users').doc(user.uid).set({
      ...userData,
      'createdAt': FieldValue.serverTimestamp(),
      'lastLoginAt': FieldValue.serverTimestamp(),
    });
  }

  // Generate 6-digit code
  String _generate6DigitCode() {
    final random = Random();
    return (100000 + random.nextInt(900000)).toString();
  }

  // Hash code for secure storage
  String _hashCode(String code) {
    final bytes = utf8.encode(code);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Sign out from all providers
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  // Update last login time
  Future<void> updateLastLogin() async {
    final user = _auth.currentUser;
    if (user != null) {
      await _firestore.collection('users').doc(user.uid).update({
        'lastLoginAt': FieldValue.serverTimestamp(),
      });
    }
  }
}
