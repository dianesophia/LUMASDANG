// lib/screens/login.dart
/*import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lumasdang/screens/home.dart';
import 'register.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Login function with soft-delete check
  Future<void> _login() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final user = userCredential.user;
      if (user != null) {
        // Check if account is soft-deleted in Firestore
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (doc.exists && doc.data()?['isDeleted'] == true) {
          // Sign out immediately if deleted
          await _auth.signOut();

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "This account has been deleted. Please register a new account.",
              ),
            ),
          );
          return; // Stop login
        }

        // Login successful → go to HomePage
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomePage()),
        );
      }
    } on FirebaseAuthException catch (e) {
      String message = 'Login failed. Please try again.';
      if (e.code == 'user-not-found') {
        message = 'No user found for that email.';
      } else if (e.code == 'wrong-password') {
        message = 'Incorrect password.';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Forgot password dialog
  Future<void> _showForgotPasswordDialog() async {
    final emailController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
          contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
          actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          title: Row(
            children: const [
              Icon(Icons.lock_reset, color: Color(0xFF2E8B7B)),
              SizedBox(width: 10),
              Text(
                "Reset Password",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Enter your registered email address and we will send you a password reset link.",
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.email_outlined),
                  hintText: "Enter your email",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFF2E8B7B),
                      width: 2,
                    ),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                "Cancel",
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E8B7B),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              onPressed: () async {
                final email = emailController.text.trim();
                if (email.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Please enter your email")),
                  );
                  return;
                }

                try {
                  await _auth.sendPasswordResetEmail(email: email);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        "Password reset email sent. Please check your inbox or spam folder.",
                      ),
                    ),
                  );
                } on FirebaseAuthException catch (e) {
                  String message = "Something went wrong.";
                  if (e.code == 'user-not-found') {
                    message = "No account found with that email.";
                  } else if (e.code == 'invalid-email') {
                    message = "Invalid email format.";
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(message)),
                  );
                }
              },
              child: const Text("Send Reset Link"),
            ),
          ],
        );
      },
    );

    emailController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF2E8B7B),
              Color(0xFF5CAA7F),
              Color(0xFF8BC88A),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Lumasdang',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontStyle: FontStyle.italic,
                      shadows: [
                        Shadow(
                          color: Colors.black26,
                          offset: Offset(2, 2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 60),
                  _buildLoginField(
                    controller: _emailController,
                    hint: 'Email',
                    icon: Icons.person_outline,
                  ),
                  const SizedBox(height: 20),
                  _buildLoginField(
                    controller: _passwordController,
                    hint: 'Password',
                    icon: Icons.lock_outline,
                    isPassword: true,
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: 200,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF5A962),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        elevation: 3,
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(
                              color: Colors.white,
                            )
                          : const Text(
                              'Log in',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextButton(
                    onPressed: _showForgotPasswordDialog,
                    child: const Text(
                      'Forgot your password or username?',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const RegisterPage()),
                      );
                    },
                    child: const Text(
                      "Don't have an account? Sign Up",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
  }) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.white70, width: 1),
        ),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        style: const TextStyle(color: Colors.white, fontSize: 16),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white70),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }
}
*/

/*import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lumasdang/screens/home.dart';
import 'register.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _usernameOrEmailController = TextEditingController();
  final _passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isLoading = false;

  @override
  void dispose() {
    _usernameOrEmailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    String input = _usernameOrEmailController.text.trim();
    String password = _passwordController.text.trim();

    if (input.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter username or email')),
      );
      return;
    }

    if (password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter password')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      String emailToUse = input;

      print('Login attempt with input: $input');

      // Check if input looks like an email (contains @)
      if (!input.contains('@')) {
        print('Input appears to be a username, looking up email...');
        
        // Treat as username - look up email
        try {
          final usernameDoc = await FirebaseFirestore.instance
              .collection('usernames')
              .doc(input.toLowerCase())
              .get();

          if (usernameDoc.exists) {
            emailToUse = usernameDoc.data()?['email'] ?? input;
            print('Found email for username: $emailToUse');
          } else {
            print('Username not found in database');
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Username not found')),
            );
            setState(() => _isLoading = false);
            return;
          }
        } catch (e) {
          print('Error looking up username: $e');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error looking up username: $e')),
          );
          setState(() => _isLoading = false);
          return;
        }
      } else {
        print('Input appears to be an email');
      }

      print('Attempting to sign in with email: $emailToUse');

      // Sign in with email
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: emailToUse,
        password: password,
      );

      final user = userCredential.user;
      print('Sign in successful, user UID: ${user?.uid}');

      if (user != null) {
        // Check if account is soft-deleted
        try {
          final doc = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();

          print('User document exists: ${doc.exists}');
          if (doc.exists) {
            print('User data: ${doc.data()}');
          }

          if (doc.exists && doc.data()?['isDeleted'] == true) {
            print('Account is soft-deleted');
            await _auth.signOut();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  "This account has been deleted. Please register a new account.",
                ),
              ),
            );
            setState(() => _isLoading = false);
            return;
          }
        } catch (e) {
          print('Error checking user document: $e');
          // Continue with login even if we can't check the document
        }

        print('Login successful, navigating to home...');

        // Login successful
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomePage()),
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      print('FirebaseAuthException: ${e.code} - ${e.message}');
      String message = 'Login failed. Please try again.';
      
      if (e.code == 'user-not-found') {
        message = 'No account found with this email.';
      } else if (e.code == 'wrong-password') {
        message = 'Incorrect password.';
      } else if (e.code == 'invalid-email') {
        message = 'Invalid email format.';
      } else if (e.code == 'user-disabled') {
        message = 'This account has been disabled.';
      } else if (e.code == 'too-many-requests') {
        message = 'Too many failed attempts. Try again later.';
      } else if (e.code == 'invalid-credential') {
        message = 'Invalid credentials. Please check your email and password.';
      }
      
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      print('General error: $e');
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showForgotPasswordDialog() async {
    final emailController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Reset Password'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Enter your email address to receive a password reset link.',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: 'Enter your email',
                  prefixIcon: const Icon(Icons.email_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E8B7B),
              ),
              onPressed: () async {
                final email = emailController.text.trim();
                if (email.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter your email')),
                  );
                  return;
                }

                try {
                  await _auth.sendPasswordResetEmail(email: email);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Password reset email sent. Check your inbox.'),
                    ),
                  );
                } on FirebaseAuthException catch (e) {
                  String msg = 'Error occurred';
                  if (e.code == 'user-not-found') msg = 'No account found with this email';
                  if (e.code == 'invalid-email') msg = 'Invalid email format';
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text(msg)));
                }
              },
              child: const Text('Send'),
            ),
          ],
        );
      },
    );

    emailController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF2E8B7B), Color(0xFF5CAA7F), Color(0xFF8BC88A)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Lumasdang',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontStyle: FontStyle.italic,
                      shadows: [
                        Shadow(
                            color: Colors.black26,
                            offset: Offset(2, 2),
                            blurRadius: 4)
                      ],
                    ),
                  ),
                  const SizedBox(height: 60),
                  _buildField(
                    controller: _usernameOrEmailController,
                    hint: 'Username or Email',
                    icon: Icons.person_outline,
                  ),
                  const SizedBox(height: 20),
                  _buildField(
                    controller: _passwordController,
                    hint: 'Password',
                    icon: Icons.lock_outline,
                    isPassword: true,
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: 200,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF5A962),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'Log in',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.w600),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: _showForgotPasswordDialog,
                    child: const Text(
                      'Forgot your password?',
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const RegisterPage()),
                    ),
                    child: const Text(
                      "Don't have an account? Sign Up",
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
  }) {
    return Container(
      decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.white70, width: 1))),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        style: const TextStyle(color: Colors.white, fontSize: 16),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white70),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          prefixIcon: Icon(icon, color: Colors.white70),
        ),
      ),
    );
  }
}*/


// lib/screens/login.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lumasdang/screens/home.dart';
import 'register.dart';
import 'dart:async';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _usernameOrEmailController = TextEditingController();
  final _passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isLoading = false;

  @override
  void dispose() {
    _usernameOrEmailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    String input = _usernameOrEmailController.text.trim();
    String password = _passwordController.text.trim();

    if (input.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter username or email')),
      );
      return;
    }

    if (password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter password')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      String emailToUse = input;

      print('Login attempt with input: $input');

      // Check if input looks like an email (contains @)
      if (!input.contains('@')) {
        print('Input appears to be a username, looking up email...');
        
        // Treat as username - look up email
        try {
          final usernameDoc = await FirebaseFirestore.instance
              .collection('usernames')
              .doc(input.toLowerCase())
              .get();

          if (usernameDoc.exists) {
            emailToUse = usernameDoc.data()?['email'] ?? input;
            print('Found email for username: $emailToUse');
          } else {
            print('Username not found in database');
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Username not found')),
            );
            setState(() => _isLoading = false);
            return;
          }
        } catch (e) {
          print('Error looking up username: $e');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error looking up username: $e')),
          );
          setState(() => _isLoading = false);
          return;
        }
      } else {
        print('Input appears to be an email');
      }

      print('Attempting to sign in with email: $emailToUse');

      // Sign in with email
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: emailToUse,
        password: password,
      );

      final user = userCredential.user;
      print('Sign in successful, user UID: ${user?.uid}');

      if (user != null) {
        // Check if account is soft-deleted
        try {
          final doc = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();

          print('User document exists: ${doc.exists}');
          if (doc.exists) {
            print('User data: ${doc.data()}');
          }

          if (doc.exists && doc.data()?['isDeleted'] == true) {
            print('Account is soft-deleted');
            await _auth.signOut();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  "This account has been deleted. Please register a new account.",
                ),
              ),
            );
            setState(() => _isLoading = false);
            return;
          }
        } catch (e) {
          print('Error checking user document: $e');
          // Continue with login even if we can't check the document
        }

        print('Login successful, navigating to home...');

        // ✅ AUTO-FIX: Ensure user has barangayId before navigating
        await _ensureUserHasBarangayId(user.uid);

        // Login successful
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomePage()),
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      print('FirebaseAuthException: ${e.code} - ${e.message}');
      String message = 'Login failed. Please try again.';
      
      if (e.code == 'user-not-found') {
        message = 'No account found with this email.';
      } else if (e.code == 'wrong-password') {
        message = 'Incorrect password.';
      } else if (e.code == 'invalid-email') {
        message = 'Invalid email format.';
      } else if (e.code == 'user-disabled') {
        message = 'This account has been disabled.';
      } else if (e.code == 'too-many-requests') {
        message = 'Too many failed attempts. Try again later.';
      } else if (e.code == 'invalid-credential') {
        message = 'Invalid credentials. Please check your email and password.';
      }
      
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      print('General error: $e');
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
// Replace the _ensureUserHasBarangayId method in your login.dart with this version:

// ✅ UPDATED METHOD: Auto-fix missing barangayId BUT DON'T BLOCK LOGIN IF IT FAILS
Future<void> _ensureUserHasBarangayId(String uid) async {
  try {
    print('🔍 Checking if user has barangayId...');
    
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get()
        .timeout(const Duration(seconds: 3)); // Add timeout
    
    if (!userDoc.exists) {
      print('⚠️ User document does not exist');
      return; // Don't block login
    }
    
    final data = userDoc.data();
    final barangayId = data?['barangayId'];
    
    // Check if barangayId is missing or empty
    if (barangayId == null || barangayId == '') {
      print('⚠️ User missing barangayId, adding it now...');
      
      // Get existing barangay from user data if available
      String barangayToUse = 'barangay_talisay';
      final existingBarangay = data?['barangay'] as String?;
      
      if (existingBarangay != null && existingBarangay.isNotEmpty) {
        // Convert existing barangay name to ID format
        barangayToUse = existingBarangay.toLowerCase().replaceAll(' ', '_');
      }
      
      // Try to add barangayId - but don't block if it fails
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .update({
          'barangayId': barangayToUse,
          'updatedAt': FieldValue.serverTimestamp(),
        }).timeout(const Duration(seconds: 3));
        
        print('✅ Added barangayId: $barangayToUse to user document');
        
        // Try to ensure barangay document exists
        final barangayDoc = await FirebaseFirestore.instance
            .collection('barangays')
            .doc(barangayToUse)
            .get()
            .timeout(const Duration(seconds: 3));
        
        if (!barangayDoc.exists) {
          await FirebaseFirestore.instance
              .collection('barangays')
              .doc(barangayToUse)
              .set({
            'name': existingBarangay ?? 'Barangay Talisay',
            'barangayId': barangayToUse,
            'createdAt': FieldValue.serverTimestamp(),
          }).timeout(const Duration(seconds: 3));
          print('✅ Created barangay document: $barangayToUse');
        }
      } catch (updateError) {
        print('⚠️ Could not update barangayId (permission issue): $updateError');
        print('   User can still login - will try again later');
        // Continue with login anyway
      }
    } else {
      print('✅ User already has barangayId: $barangayId');
    }
  } on TimeoutException catch (e) {
    print('⏱️ Timeout checking barangayId: $e');
    print('   User can still login - will try again later');
    // Continue with login anyway
  } catch (e) {
    print('❌ Error checking/adding barangayId: $e');
    print('   User can still login - will try again later');
    // DON'T block login if this fails - user can still access app
  }
}


// ============================================================================
// IMPORTANT: This version won't block your login even if Firestore rules
// are blocking the barangayId update. You'll still be able to login,
// but you need to fix the Firestore rules separately!
// ============================================================================

  Future<void> _showForgotPasswordDialog() async {
    final emailController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Reset Password'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Enter your email address to receive a password reset link.',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: 'Enter your email',
                  prefixIcon: const Icon(Icons.email_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E8B7B),
              ),
              onPressed: () async {
                final email = emailController.text.trim();
                if (email.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter your email')),
                  );
                  return;
                }

                try {
                  await _auth.sendPasswordResetEmail(email: email);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Password reset email sent. Check your inbox.'),
                    ),
                  );
                } on FirebaseAuthException catch (e) {
                  String msg = 'Error occurred';
                  if (e.code == 'user-not-found') msg = 'No account found with this email';
                  if (e.code == 'invalid-email') msg = 'Invalid email format';
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text(msg)));
                }
              },
              child: const Text('Send'),
            ),
          ],
        );
      },
    );

    emailController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF2E8B7B), Color(0xFF5CAA7F), Color(0xFF8BC88A)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Lumasdang',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontStyle: FontStyle.italic,
                      shadows: [
                        Shadow(
                            color: Colors.black26,
                            offset: Offset(2, 2),
                            blurRadius: 4)
                      ],
                    ),
                  ),
                  const SizedBox(height: 60),
                  _buildField(
                    controller: _usernameOrEmailController,
                    hint: 'Username or Email',
                    icon: Icons.person_outline,
                  ),
                  const SizedBox(height: 20),
                  _buildField(
                    controller: _passwordController,
                    hint: 'Password',
                    icon: Icons.lock_outline,
                    isPassword: true,
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: 200,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF5A962),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'Log in',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.w600),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: _showForgotPasswordDialog,
                    child: const Text(
                      'Forgot your password?',
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const RegisterPage()),
                    ),
                    child: const Text(
                      "Don't have an account? Sign Up",
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  
  

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
  }) {
    return Container(
      decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.white70, width: 1))),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        style: const TextStyle(color: Colors.white, fontSize: 16),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white70),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          prefixIcon: Icon(icon, color: Colors.white70),
        ),
      ),
      
    );
    
    
  }
  
}