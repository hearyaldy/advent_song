// lib/core/services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseDatabase _database = FirebaseDatabase.instance;

  // Current user
  static User? get currentUser => _auth.currentUser;

  // Check if user is logged in
  static bool get isLoggedIn => currentUser != null;

  // Check if current user is admin
  static Future<bool> get isAdmin async {
    if (!isLoggedIn) return false;

    try {
      final snapshot =
          await _database.ref().child('users').child(currentUser!.uid).get();
      final userData = snapshot.value as Map<dynamic, dynamic>?;
      return userData?['isAdmin'] ?? false;
    } catch (e) {
      return false;
    }
  }

  // Email/password login with specific error handling
  static Future<AuthResult> login(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return AuthResult.success();
    } on FirebaseAuthException catch (e) {
      String message = 'Login failed';
      switch (e.code) {
        case 'user-not-found':
          message = 'No user found with this email address';
          break;
        case 'wrong-password':
          message = 'Incorrect password';
          break;
        case 'invalid-email':
          message = 'Invalid email address';
          break;
        case 'user-disabled':
          message = 'This account has been disabled';
          break;
        case 'too-many-requests':
          message = 'Too many failed attempts. Please try again later';
          break;
        case 'network-request-failed':
          message = 'Network error. Please check your connection';
          break;
        default:
          message = 'Login failed: ${e.message ?? 'Unknown error'}';
      }
      return AuthResult.failure(message);
    } catch (e) {
      return AuthResult.failure('An unexpected error occurred');
    }
  }

  // Password reset
  static Future<AuthResult> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return AuthResult.success('Password reset email sent');
    } on FirebaseAuthException catch (e) {
      String message = 'Failed to send reset email';
      switch (e.code) {
        case 'user-not-found':
          message = 'No user found with this email address';
          break;
        case 'invalid-email':
          message = 'Invalid email address';
          break;
        default:
          message =
              'Failed to send reset email: ${e.message ?? 'Unknown error'}';
      }
      return AuthResult.failure(message);
    } catch (e) {
      return AuthResult.failure('An unexpected error occurred');
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

  // Create admin user (for initial setup only - remove in production)
  static Future<AuthResult> createAdminUser(
      String email, String password) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Set as admin in Realtime Database
      await _database.ref().child('users').child(credential.user!.uid).set({
        'email': email,
        'isAdmin': true,
        'createdAt': ServerValue.timestamp,
      });

      return AuthResult.success('Admin user created successfully');
    } on FirebaseAuthException catch (e) {
      String message = 'Failed to create admin user';
      switch (e.code) {
        case 'email-already-in-use':
          message = 'Email address is already in use';
          break;
        case 'invalid-email':
          message = 'Invalid email address';
          break;
        case 'weak-password':
          message = 'Password is too weak';
          break;
        default:
          message = 'Failed to create user: ${e.message ?? 'Unknown error'}';
      }
      return AuthResult.failure(message);
    } catch (e) {
      return AuthResult.failure('An unexpected error occurred');
    }
  }

  // Listen to auth state changes
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Check if email is verified
  static bool get isEmailVerified => currentUser?.emailVerified ?? false;

  // Send email verification
  static Future<AuthResult> sendEmailVerification() async {
    if (!isLoggedIn) return AuthResult.failure('No user logged in');

    try {
      await currentUser!.sendEmailVerification();
      return AuthResult.success('Verification email sent');
    } catch (e) {
      return AuthResult.failure('Failed to send verification email');
    }
  }
}

// Result class for better error handling
class AuthResult {
  final bool isSuccess;
  final String message;

  AuthResult._(this.isSuccess, this.message);

  factory AuthResult.success([String? message]) {
    return AuthResult._(true, message ?? 'Success');
  }

  factory AuthResult.failure(String message) {
    return AuthResult._(false, message);
  }
}
