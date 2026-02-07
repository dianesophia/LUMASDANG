import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Register
  Future<User?> register(String email, String password) async {
    try {
      UserCredential user = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return user.user;
    } on FirebaseAuthException catch (e) {
      debugPrint('Registration error: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('Unexpected registration error: $e');
      rethrow;
    }
  }

  // Login
  Future<User?> login(String email, String password) async {
    try {
      UserCredential user = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return user.user;
    } on FirebaseAuthException catch (e) {
      debugPrint('Login error: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('Unexpected login error: $e');
      rethrow;
    }
  }

  // Logout
  Future<void> logout() async {
    try {
      await _auth.signOut();
    } catch (e) {
      debugPrint('Logout error: $e');
      rethrow;
    }
  }

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Check if user is logged in
  bool get isLoggedIn => currentUser != null;

  // Re-authenticate user (required for sensitive operations)
  Future<void> reauthenticate(String password) async {
    debugPrint('AuthService.reauthenticate started');
    final user = currentUser;
    if (user == null || user.email == null) {
      debugPrint('No current user or email found');
      throw FirebaseAuthException(
        code: 'no-current-user',
        message: 'No authenticated user found',
      );
    }

    try {
      debugPrint('Creating email credential for: ${user.email}');
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password.trim(),
      );
      debugPrint('Calling reauthenticateWithCredential...');
      await user.reauthenticateWithCredential(credential);
      debugPrint('Re-authentication successful');
    } on FirebaseAuthException catch (e) {
      debugPrint('Re-authentication error: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('Unexpected re-authentication error: $e');
      rethrow;
    }
  }

  // Change password
  Future<void> changePassword(String newPassword) async {
    debugPrint('AuthService.changePassword started');
    final user = currentUser;
    if (user == null) {
      debugPrint('No current user found');
      throw FirebaseAuthException(
        code: 'no-current-user',
        message: 'No authenticated user found',
      );
    }

    try {
      debugPrint('Calling updatePassword...');
      await user.updatePassword(newPassword.trim());
      debugPrint('Password updated successfully');
    } on FirebaseAuthException catch (e) {
      debugPrint('Password change error: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('Unexpected password change error: $e');
      rethrow;
    }
  }

  // Update user profile
  Future<void> updateProfile({String? displayName, String? photoURL}) async {
    final user = currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'no-current-user',
        message: 'No authenticated user found',
      );
    }

    try {
      await user.updateDisplayName(displayName);
      await user.updatePhotoURL(photoURL);
    } on FirebaseAuthException catch (e) {
      debugPrint('Profile update error: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('Unexpected profile update error: $e');
      rethrow;
    }
  }

  // Validate password strength
  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    if (value.length > 128) {
      return 'Password must be less than 128 characters';
    }
    // Add more validation rules if needed
    return null;
  }

  // Validate email format
  String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    return null;
  }
}
