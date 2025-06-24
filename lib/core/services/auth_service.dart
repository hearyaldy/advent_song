// lib/core/services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Current user
  static User? get currentUser => _auth.currentUser;

  // Check if user is logged in
  static bool get isLoggedIn => currentUser != null;

  // Check if current user is admin
  static Future<bool> get isAdmin async {
    if (!isLoggedIn) return false;

    try {
      final doc =
          await _firestore.collection('users').doc(currentUser!.uid).get();

      return doc.data()?['isAdmin'] ?? false;
    } catch (e) {
      return false;
    }
  }

  // Simple email/password login
  static Future<bool> login(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  // Logout
  static Future<void> logout() async {
    await _auth.signOut();
  }

  // Get user display name
  static String get userName {
    if (!isLoggedIn) return '';
    return currentUser?.email?.split('@')[0] ?? 'User';
  }

  // Create admin user (for setup)
  static Future<bool> createAdminUser(String email, String password) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Set as admin in Firestore
      await _firestore.collection('users').doc(credential.user!.uid).set({
        'email': email,
        'isAdmin': true,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      return false;
    }
  }
}
