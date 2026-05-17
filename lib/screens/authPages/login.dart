import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lumasdang/screens/home/home_page.dart';
import 'register.dart';
import 'dart:async';
import '../../services/connectivity_service.dart';
import '../../services/local_db_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../services/BiometricAuthService.dart';
import 'package:flutter/foundation.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with TickerProviderStateMixin {

  final _usernameOrEmailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  // Secure storage for offline credential cache (encrypted by OS)
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  
  // Biometric authentication service
  final BiometricAuthService _biometricService = BiometricAuthService();

  bool _isLoading = false;
  bool _obscurePassword = true;
  
  // Biometric login state
  bool _isBiometricAvailable = false;
  bool _isBiometricEnabled = false;
  bool _isBiometricLoading = false;

  late AnimationController _backgroundController;
  late AnimationController _contentController;
  late AnimationController _leafController;

  late Animation<double> _contentFade;
  late Animation<Offset> _contentSlide;
  late Animation<double> _leafRotation;

  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();

    _backgroundController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat(reverse: true);

    _contentController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _leafController = AnimationController(
      duration: const Duration(seconds: 6),
      vsync: this,
    )..repeat(reverse: true);

    _contentFade = CurvedAnimation(
      parent: _contentController,
      curve: Curves.easeOut,
    );

    _contentSlide = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _contentController,
      curve: Curves.easeOutCubic,
    ));

    _leafRotation = Tween<double>(begin: -0.05, end: 0.05).animate(
      CurvedAnimation(parent: _leafController, curve: Curves.easeInOut),
    );

    Future.delayed(const Duration(milliseconds: 200), () {
      _contentController.forward();
    });
    
    // Initialize biometric status
    _checkBiometricAvailability();
  }

  Future<void> _checkBiometricAvailability() async {
    try {
      final isSupported = await _biometricService.isDeviceSupported();
      final canCheck = await _biometricService.canCheckBiometrics();
      final isEnabled = await _biometricService.isBiometricLoginEnabled();
      final credentials = await _biometricService.getSavedCredentials();
      
      if (mounted) {
        setState(() {
          _isBiometricAvailable = isSupported && canCheck && credentials != null;
          _isBiometricEnabled = isEnabled;
        });
      }
      
      // Auto-prompt biometric login if available and enabled
      if (_isBiometricAvailable && _isBiometricEnabled && credentials != null) {
        // Small delay to ensure UI is fully rendered
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            _promptBiometricLogin();
          }
        });
      }
    } catch (e) {
      // Silently fail - biometric login is optional
      debugPrint('Biometric availability check failed: $e');
    }
  }

  @override
  void dispose() {
    _usernameOrEmailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _backgroundController.dispose();
    _contentController.dispose();
    _leafController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    String input = _usernameOrEmailController.text.trim();
    String password = _passwordController.text.trim();

    setState(() => _isLoading = true);

    // Attempt offline login if no network available.
    //final online = await ConnectivityService.instance.checkOnline();
    final online = kIsWeb ? true : await ConnectivityService.instance.checkOnline();
    if (!online) {
      // Resolve input to an email if user typed username previously saved locally
      String emailToUse = input;
      if (!input.contains('@')) {
        final storedEmail = await _secureStorage.read(key: 'cached_email_for_username:${input.toLowerCase()}');
        if (storedEmail != null && storedEmail.isNotEmpty) {
          emailToUse = storedEmail;
        }
      }

      // Check cached password for this email
      final cachedPassword = await _secureStorage.read(key: 'cached_password_for_email:${emailToUse.toLowerCase()}');
      if (cachedPassword != null && cachedPassword == password) {
        // Allow offline access — mark session as offline‑authenticated and navigate to HomePage
        LocalDbService.instance.setOfflineAuthenticated(true);
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomePage()),
          );
        }
        setState(() => _isLoading = false);
        return;
      }

      _showErrorSnackbar('No internet connection. Cannot sign in offline with these credentials.');
      setState(() => _isLoading = false);
      return;
    }

    try {
      String emailToUse = input;

      if (!input.contains('@')) {
        final usernameDoc = await FirebaseFirestore.instance
            .collection('usernames')
            .doc(input.toLowerCase())
            .get();

        if (usernameDoc.exists) {
          emailToUse = usernameDoc.data()?['email'] ?? input;
        } else {
          _showErrorSnackbar('Username not found');
          setState(() => _isLoading = false);
          return;
        }
      }

      final userCredential = await _auth.signInWithEmailAndPassword(
        email: emailToUse,
        password: password,
      );

      final user = userCredential.user;

      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (doc.exists && doc.data()?['isDeleted'] == true) {
          await _auth.signOut();
          _showErrorSnackbar("This account has been deleted.");
          setState(() => _isLoading = false);
          return;
        }

        await _ensureUserHasBarangayId(user.uid);

        // Cache credentials for offline login (secure storage)
        try {
          final emailLower = emailToUse.toLowerCase();
          await _secureStorage.write(key: 'cached_password_for_email:$emailLower', value: password);
          // If user logged in using username (input without @), keep a mapping
          if (!input.contains('@')) {
            await _secureStorage.write(key: 'cached_email_for_username:${input.toLowerCase()}', value: emailToUse);
          }
        } catch (e) {
          // ignore storage errors
        }

        // Mark session as online‑authenticated (not offline cached mode)
        LocalDbService.instance.setOfflineAuthenticated(false);

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomePage()),
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      String message = 'Login failed. Please try again.';
      if (e.code == 'user-not-found') message = 'No account found with this email.';
      else if (e.code == 'wrong-password') message = 'Incorrect password.';
      else if (e.code == 'invalid-email') message = 'Invalid email format.';
      else if (e.code == 'user-disabled') message = 'This account has been disabled.';
      else if (e.code == 'too-many-requests') message = 'Too many failed attempts. Try again later.';
      else if (e.code == 'invalid-credential') message = 'Invalid credentials. Please check your email and password.';
      _showErrorSnackbar(message);
    } catch (e) {
      _showErrorSnackbar('Error: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(child: Text(message, style: const TextStyle(fontFamily: 'Georgia'))),
          ],
        ),
        backgroundColor: const Color(0xFFB85C5C),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _promptBiometricLogin() async {
    if (_isBiometricLoading) return;
    
    setState(() => _isBiometricLoading = true);
    
    final result = await _biometricService.authenticate(
      reason: 'Sign in to Lumasdang with biometrics',
    );
    
    if (!mounted) return;
    
    if (result == BiometricResult.success) {
      await _loginWithBiometric();
    } else if (result != BiometricResult.failed) {
      // Only show error for actual failures, not user cancellation
      String errorMsg = _getBiometricErrorMessage(result);
      if (errorMsg.isNotEmpty) {
        _showErrorSnackbar(errorMsg);
      }
      setState(() => _isBiometricLoading = false);
    } else {
      setState(() => _isBiometricLoading = false);
    }
  }

  Future<void> _loginWithBiometric() async {
    try {
      // Get saved credentials from secure storage
      final credentials = await _biometricService.getSavedCredentials();
      if (credentials == null) {
        _showErrorSnackbar('No saved credentials found. Please log in with your password first.');
        setState(() => _isBiometricLoading = false);
        return;
      }

      final email = credentials['email']!;
      final password = credentials['password']!;

      setState(() => _isLoading = true);

      // Check if online
      final online = await ConnectivityService.instance.checkOnline();
      if (!online) {
        // Offline biometric login not supported - must verify with server
        _showErrorSnackbar('Internet connection required for biometric login.');
        setState(() => _isLoading = false);
        return;
      }

      // Try to sign in with saved credentials
      try {
        final userCredential = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );

        final user = userCredential.user;
        if (user != null) {
          // Check if account is deleted
          final doc = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();

          if (doc.exists && doc.data()?['isDeleted'] == true) {
            await _auth.signOut();
            _showErrorSnackbar("This account has been deleted.");
            setState(() => _isLoading = false);
            return;
          }

          await _ensureUserHasBarangayId(user.uid);

          // Mark session as online‑authenticated
          LocalDbService.instance.setOfflineAuthenticated(false);

          if (mounted) {
            // Show success message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
                    const SizedBox(width: 10),
                    const Expanded(child: Text('Signed in with biometrics!')),
                  ],
                ),
                backgroundColor: const Color(0xFF3A8C6E),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                margin: const EdgeInsets.all(16),
              ),
            );

            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const HomePage()),
            );
          }
        }
      } on FirebaseAuthException catch (e) {
        String message = 'Biometric login failed. Please try again.';
        if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
          message = 'Saved credentials are invalid. Please log in with your password.';
          // Clear corrupted credentials
          await _biometricService.clearSavedCredentials();
        } else if (e.code == 'user-not-found') {
          message = 'Account not found.';
          await _biometricService.clearSavedCredentials();
        }
        _showErrorSnackbar(message);
        setState(() => _isLoading = false);
      }
    } catch (e) {
      _showErrorSnackbar('Biometric login error: ${e.toString()}');
      setState(() => _isLoading = false);
    }
  }

  String _getBiometricErrorMessage(BiometricResult result) {
    switch (result) {
      case BiometricResult.notSupported:
        return 'Biometric authentication is not supported on this device.';
      case BiometricResult.notEnrolled:
        return 'No biometrics enrolled. Please set up in device settings.';
      case BiometricResult.lockedOut:
        return 'Too many failed attempts. Try again later.';
      case BiometricResult.error:
        return 'An authentication error occurred. Please try again.';
      default:
        return '';
    }
  }

  Future<void> _ensureUserHasBarangayId(String uid) async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get()
          .timeout(const Duration(seconds: 3));

      if (!userDoc.exists) return;

      final data = userDoc.data();
      final barangayId = data?['barangayId'];

      if (barangayId == null || barangayId == '') {
        String barangayToUse = 'barangay_talisay';
        final existingBarangay = data?['barangay'] as String?;
        if (existingBarangay != null && existingBarangay.isNotEmpty) {
          barangayToUse = existingBarangay.toLowerCase().replaceAll(' ', '_');
        }
        await FirebaseFirestore.instance.collection('users').doc(uid).update({
          'barangayId': barangayToUse,
          'updatedAt': FieldValue.serverTimestamp(),
        }).timeout(const Duration(seconds: 3));
      }
    } catch (_) {}
  }

  Future<void> _showForgotPasswordDialog() async {
    final emailController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          backgroundColor: const Color(0xFFF5F2EC),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2E8B7B).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.lock_reset_rounded, color: Color(0xFF2E8B7B), size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Reset Password',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A3D35),
                        fontFamily: 'Georgia',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Enter your email and we\'ll send a reset link to your inbox.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: Color(0xFF1A3D35)),
                  decoration: InputDecoration(
                    hintText: 'your@email.com',
                    hintStyle: TextStyle(color: Colors.grey.shade400),
                    prefixIcon: const Icon(Icons.mail_outline_rounded, color: Color(0xFF2E8B7B), size: 20),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFF2E8B7B), width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          'Cancel',
                          style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E8B7B),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () async {
                          final email = emailController.text.trim();
                          if (email.isEmpty) {
                            _showErrorSnackbar('Please enter your email');
                            return;
                          }
                          try {
                            await _auth.sendPasswordResetEmail(email: email);
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Reset link sent! Check your inbox and spam folder.'),
                                backgroundColor: const Color(0xFF3A8C6E),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                margin: const EdgeInsets.all(16),
                              ),
                            );
                          } on FirebaseAuthException catch (e) {
                            String msg = 'Error occurred';
                            if (e.code == 'user-not-found') msg = 'No account found with this email';
                            if (e.code == 'invalid-email') msg = 'Invalid email format';
                            _showErrorSnackbar(msg);
                          }
                        },
                        child: const Text('Send Link', style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
    emailController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Animated gradient background
          AnimatedBuilder(
            animation: _backgroundController,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: const [
                      Color(0xFF2E8B7B),
                      Color(0xFF5CAA7F),
                      Color(0xFF8BC88A),
                    ],
                    stops: [
                      0.0,
                      0.4 + _backgroundController.value * 0.1,
                      1.0,
                    ],
                  ),
                ),
              );
            },
          ),

          // Decorative circles
          Positioned(
            top: -80,
            right: -60,
            child: AnimatedBuilder(
              animation: _leafController,
              builder: (_, __) => Transform.rotate(
                angle: _leafRotation.value,
                child: Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.04),
                    border: Border.all(color: Colors.white.withOpacity(0.06), width: 1),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            left: -80,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.03),
                border: Border.all(color: Colors.white.withOpacity(0.05), width: 1),
              ),
            ),
          ),

          // Leaf decoration top-left
          Positioned(
            top: 40,
            left: 24,
            child: AnimatedBuilder(
              animation: _leafController,
              builder: (_, __) => Transform.rotate(
                angle: _leafRotation.value * 2,
                child: Opacity(
                  opacity: 0.15,
                  child: Icon(
                    Icons.eco_rounded,
                    color: Colors.white,
                    size: 80,
                  ),
                ),
              ),
            ),
          ),

          // Main content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
                child: Form(
                  key: _formKey,
                  child: SlideTransition(
                    position: _contentSlide,
                    child: FadeTransition(
                      opacity: _contentFade,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Brand mark
                          Center(
                            child: Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.2),
                                      width: 1,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.eco_rounded,
                                    color: Colors.white,
                                    size: 36,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                const Text(
                                  'Lµmasdαng',
                                  style: TextStyle(
                                    fontSize: 40,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    fontFamily: 'Georgia',
                                    letterSpacing: 1.5,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black26,
                                        offset: Offset(0, 3),
                                        blurRadius: 12,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Welcome back',
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: Colors.white.withOpacity(0.65),
                                    letterSpacing: 0.5,
                                    fontWeight: FontWeight.w300,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 48),

                          // Card
                          Container(
                            padding: const EdgeInsets.all(28),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8F5EF),
                              borderRadius: BorderRadius.circular(28),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.25),
                                  blurRadius: 40,
                                  offset: const Offset(0, 20),
                                  spreadRadius: -5,
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Sign In',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF1A5F4A),
                                    fontFamily: 'Georgia',
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Enter your credentials to continue',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                                const SizedBox(height: 28),

                                // Email/Username
                                _buildField(
                                  controller: _usernameOrEmailController,
                                  label: 'Username or Email',
                                  icon: Icons.person_outline_rounded,
                                  focusNode: _emailFocusNode,
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Please enter your username or email';
                                    }
                                    return null;
                                  },
                                  onEditingComplete: () => _passwordFocusNode.requestFocus(),
                                ),

                                const SizedBox(height: 16),

                                // Password
                                _buildField(
                                  controller: _passwordController,
                                  label: 'Password',
                                  icon: Icons.lock_outline_rounded,
                                  focusNode: _passwordFocusNode,
                                  isPassword: true,
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Please enter your password';
                                    }
                                    return null;
                                  },
                                  onEditingComplete: () {
                                    if (!_isLoading) _login();
                                  },
                                ),

                                // Forgot password
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: _showForgotPasswordDialog,
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: const Text(
                                      'Forgot password?',
                                      style: TextStyle(
                                        color: Color(0xFF2E8B7B),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 8),

                                // Biometric login button (only show if available and enabled)
                                if (_isBiometricAvailable && _isBiometricEnabled)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: SizedBox(
                                      width: double.infinity,
                                      height: 48,
                                      child: OutlinedButton.icon(
                                        onPressed: _isBiometricLoading ? null : _promptBiometricLogin,
                                        style: OutlinedButton.styleFrom(
                                          side: const BorderSide(
                                            color: Color(0xFF2E8B7B),
                                            width: 1.5,
                                          ),
                                          foregroundColor: const Color(0xFF2E8B7B),
                                          disabledForegroundColor: Colors.grey.shade300,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(14),
                                          ),
                                        ),
                                        icon: _isBiometricLoading
                                            ? const SizedBox(
                                                width: 20,
                                                height: 20,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  valueColor: AlwaysStoppedAnimation<Color>(
                                                    Color(0xFF2E8B7B),
                                                  ),
                                                ),
                                              )
                                            : const Icon(Icons.fingerprint_rounded, size: 20),
                                        label: Text(
                                          _isBiometricLoading
                                              ? 'Authenticating...'
                                              : 'Sign in with Biometrics',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: 0.3,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),

                                const SizedBox(height: 8),

                                // Login button
                                SizedBox(
                                  width: double.infinity,
                                  height: 54,
                                  child: ElevatedButton(
                                    onPressed: _isLoading ? null : _login,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF1A5F4A),
                                      disabledBackgroundColor: Colors.grey.shade200,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                    child: _isLoading
                                        ? const SizedBox(
                                            width: 22,
                                            height: 22,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2.5,
                                            ),
                                          )
                                        : const Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                'Sign In',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w700,
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                              SizedBox(width: 8),
                                              Icon(Icons.arrow_forward_rounded, size: 18),
                                            ],
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 28),

                          // Sign up link
                          Center(
                            child: GestureDetector(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const RegisterPage()),
                              ),
                              child: RichText(
                                text: TextSpan(
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white.withOpacity(0.7),
                                  ),
                                  children: const [
                                    TextSpan(text: "Don't have an account? "),
                                    TextSpan(
                                      text: 'Sign Up',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        decoration: TextDecoration.underline,
                                        decorationColor: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required FocusNode focusNode,
    String? Function(String?)? validator,
    VoidCallback? onEditingComplete,
    bool isPassword = false,
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      obscureText: isPassword ? _obscurePassword : false,
      validator: validator,
      onEditingComplete: onEditingComplete,
      style: const TextStyle(
        fontSize: 15,
        color: Color(0xFF1A5F4A),
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: Colors.grey.shade500,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        prefixIcon: Icon(icon, color: const Color(0xFF2E8B7B), size: 20),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: Colors.grey.shade400,
                  size: 20,
                ),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              )
            : null,
        filled: true,
        fillColor: const Color(0xFFF0EDE6),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE2DDD5), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF2E8B7B), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFB85C5C), width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFB85C5C), width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}