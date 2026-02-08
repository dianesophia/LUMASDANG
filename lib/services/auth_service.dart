import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ---------------- REGISTER ----------------
  Future<User?> register(String email, String password) async {
    try {
      UserCredential user = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return user.user;
    } catch (e) {
      print(e);
      return null;
    }
  }

  // ---------------- LOGIN ----------------
  Future<User?> login(String email, String password) async {
    try {
      UserCredential user = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return user.user;
    } catch (e) {
      print(e);
      return null;
    }
  }

  // ---------------- LOGOUT ----------------
  Future<void> logout() async {
    await _auth.signOut();
  }

  // ---------------- PASSWORD VALIDATION ----------------
  /// Returns null if valid, otherwise error message
  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return "Please enter a password";
    }
    if (value.length < 6) {
      return "Password must be at least 6 characters";
    }
    // Optional: Add more rules (uppercase, number, symbol)
    // Example:
    // if (!RegExp(r'[A-Z]').hasMatch(value)) return "Password must contain an uppercase letter";
    return null; // valid
  }
}
