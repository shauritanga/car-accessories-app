import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<UserModel?> signIn(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      DocumentSnapshot doc =
          await _firestore.collection('users').doc(result.user!.uid).get();

      return UserModel.fromMap(
        doc.data() as Map<String, dynamic>,
        result.user!.uid,
      );
    } catch (e) {
      throw Exception('Login failed: $e');
    }
  }

  Future<UserModel?> register(
    String email,
    String password,
    String role,
    String name,
    String phone,
  ) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      UserModel user = UserModel(
        id: result.user!.uid,
        email: email,
        role: role,
        name: name,
        phone: phone,
      );
      await _firestore
          .collection('users')
          .doc(result.user!.uid)
          .set(user.toMap());
      return user;
    } catch (e) {
      throw Exception('Registration failed: $e');
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      throw Exception('Password reset failed: $e');
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  User? get currentUser => _auth.currentUser;
}
