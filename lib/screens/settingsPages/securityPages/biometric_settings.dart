import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../services/BiometricAuthService.dart';

class BiometricSettingsPage extends StatefulWidget {
  const BiometricSettingsPage({super.key});

  @override
  State<BiometricSettingsPage> createState() => _BiometricSettingsPageState();
}

class _BiometricSettingsPageState extends State<BiometricSettingsPage>
    with SingleTickerProviderStateMixin {
  final BiometricAuthService _biometricService = BiometricAuthService();

  bool _isLoading = true;
  bool _biometricEnabled = false;
  bool _isSupported = false;
  bool _isFaceAvailable = false;
  bool _isFingerprintAvailable = false;
  bool _isToggling = false;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _loadBiometricStatus();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadBiometricStatus() async {
    final supported = await _biometricService.isDeviceSupported();
    final canCheck = await _biometricService.canCheckBiometrics();
    final faceAvailable = await _biometricService.isFaceIdAvailable();
    final fingerprintAvailable = await _biometricService.isFingerprintAvailable();
    final enabled = await _biometricService.isBiometricLoginEnabled();

    if (mounted) {
      setState(() {
        _isSupported = supported && canCheck;
        _isFaceAvailable = faceAvailable;
        _isFingerprintAvailable = fingerprintAvailable;
        _biometricEnabled = enabled;
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleBiometric(bool value) async {
    if (_isToggling) return;
    setState(() => _isToggling = true);

    if (value) {
      await _enableBiometric();
    } else {
      await _disableBiometric();
    }

    setState(() => _isToggling = false);
  }

  Future<void> _enableBiometric() async {
    // First verify with biometrics that user is the device owner
    final result = await _biometricService.authenticate(
      reason: 'Verify your identity to enable biometric login',
    );

    if (result != BiometricResult.success) {
      _showResultSnackbar(_resultMessage(result), isError: true);
      return;
    }

    // Get current user's credentials from Firestore to store
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showResultSnackbar('No active session found.', isError: true);
      return;
    }

    // Show password confirmation dialog to save credentials securely
    final password = await _showPasswordConfirmDialog();
    if (password == null || password.isEmpty) return;

    try {
      // Re-authenticate to confirm password is correct
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );
      await user.reauthenticateWithCredential(credential);

      // Save credentials & enable flag
      await _biometricService.saveCredentials(user.email!, password);
      await _biometricService.setBiometricLoginEnabled(true);

      if (mounted) {
        setState(() => _biometricEnabled = true);
        _showResultSnackbar('Biometric login enabled!', isError: false);
      }
    } on FirebaseAuthException catch (e) {
      String msg = 'Could not verify password.';
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        msg = 'Incorrect password. Please try again.';
      }
      _showResultSnackbar(msg, isError: true);
    } catch (_) {
      _showResultSnackbar('An error occurred. Please try again.', isError: true);
    }
  }

  Future<void> _disableBiometric() async {
    final confirmed = await _showDisableConfirmDialog();
    if (!confirmed) return;

    await _biometricService.clearSavedCredentials();
    if (mounted) {
      setState(() => _biometricEnabled = false);
      _showResultSnackbar('Biometric login disabled.', isError: false);
    }
  }

  Future<String?> _showPasswordConfirmDialog() async {
    final passwordController = TextEditingController();
    bool obscure = true;
    String? result;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Dialog(
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
                      child: const Icon(Icons.lock_outline_rounded,
                          color: Color(0xFF2E8B7B), size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Confirm Password',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A3D35),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Enter your password to link it with biometric login.',
                  style: TextStyle(
                      fontSize: 13, color: Colors.grey.shade600, height: 1.5),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: passwordController,
                  obscureText: obscure,
                  style: const TextStyle(color: Color(0xFF1A3D35)),
                  decoration: InputDecoration(
                    hintText: 'Your password',
                    hintStyle: TextStyle(color: Colors.grey.shade400),
                    prefixIcon: const Icon(Icons.lock_outline_rounded,
                        color: Color(0xFF2E8B7B), size: 20),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscure
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: Colors.grey.shade400,
                        size: 20,
                      ),
                      onPressed: () => setS(() => obscure = !obscure),
                    ),
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
                    focusedBorder: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(14)),
                      borderSide:
                          BorderSide(color: Color(0xFF2E8B7B), width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text('Cancel',
                            style: TextStyle(color: Colors.grey.shade500)),
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
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          result = passwordController.text.trim();
                          Navigator.pop(ctx);
                        },
                        child: const Text('Confirm',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    passwordController.dispose();
    return result;
  }

  Future<bool> _showDisableConfirmDialog() async {
    bool confirmed = false;
    await showDialog(
      context: context,
      builder: (ctx) => Dialog(
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
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.no_encryption_gmailerrorred_rounded,
                        color: Colors.redAccent, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Disable Biometrics',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A3D35),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'This will remove your saved credentials and disable biometric login. You can re-enable it anytime.',
                style: TextStyle(
                    fontSize: 13, color: Colors.grey.shade600, height: 1.5),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text('Cancel',
                          style: TextStyle(color: Colors.grey.shade500)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        confirmed = true;
                        Navigator.pop(ctx);
                      },
                      child: const Text('Disable',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    return confirmed;
  }

  String _resultMessage(BiometricResult result) {
    switch (result) {
      case BiometricResult.notSupported:
        return 'Biometrics not supported on this device.';
      case BiometricResult.notEnrolled:
        return 'No biometrics enrolled. Please set up in device settings.';
      case BiometricResult.lockedOut:
        return 'Too many attempts. Try again later.';
      case BiometricResult.failed:
        return 'Authentication failed. Please try again.';
      case BiometricResult.error:
        return 'An error occurred. Please try again.';
      default:
        return 'Unexpected error.';
    }
  }

  void _showResultSnackbar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor:
            isError ? const Color(0xFFB85C5C) : const Color(0xFF3A8C6E),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
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
          child: Column(
            children: [
              // ── HEADER ──────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 12, 8, 0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => Navigator.pop(context),
                            borderRadius: BorderRadius.circular(50),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.35),
                                  width: 1.2,
                                ),
                              ),
                              child: const Icon(
                                Icons.arrow_back_ios_new_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                        const Expanded(
                          child: Center(
                            child: Text(
                              'Biometric Login',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 44),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      height: 1,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            Colors.white.withOpacity(0.35),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── BODY ────────────────────────────────────────────────────
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 28),
                        child: Column(
                          children: [
                            // Biometric icon hero
                            _buildHeroIcon(),

                            const SizedBox(height: 32),

                            // Not supported banner
                            if (!_isSupported) _buildNotSupportedBanner(),

                            // Main toggle card
                            if (_isSupported) ...[
                              _buildToggleCard(),
                              const SizedBox(height: 20),
                              _buildAvailableBiometricsCard(),
                              const SizedBox(height: 20),
                              _buildHowItWorksCard(),
                            ],
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroIcon() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (_, __) => Transform.scale(
        scale: _biometricEnabled ? _pulseAnimation.value : 1.0,
        child: Container(
          width: 110,
          height: 110,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(_biometricEnabled ? 0.25 : 0.12),
            border: Border.all(
              color: Colors.white
                  .withOpacity(_biometricEnabled ? 0.5 : 0.2),
              width: 2,
            ),
          ),
          child: Icon(
            _isFaceAvailable
                ? Icons.face_unlock_outlined
                : Icons.fingerprint_rounded,
            color: Colors.white,
            size: 56,
          ),
        ),
      ),
    );
  }

  Widget _buildNotSupportedBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.orange.withOpacity(0.4), width: 1),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: Colors.orangeAccent, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Biometric authentication is not available or not set up on this device. Please configure it in your device settings.',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 13,
                  height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: Colors.white.withOpacity(0.28), width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.security_rounded,
                color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Enable Biometric Login',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _biometricEnabled
                      ? 'Tap to disable biometric login'
                      : 'Sign in without typing your password',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.65), fontSize: 12),
                ),
              ],
            ),
          ),
          _isToggling
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2.5),
                )
              : Switch.adaptive(
                  value: _biometricEnabled,
                  onChanged: _toggleBiometric,
                  activeColor: Colors.white,
                  activeTrackColor: const Color(0xFF1A5F4A),
                  inactiveThumbColor: Colors.white.withOpacity(0.7),
                  inactiveTrackColor: Colors.white.withOpacity(0.2),
                ),
        ],
      ),
    );
  }

  Widget _buildAvailableBiometricsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: Colors.white.withOpacity(0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'AVAILABLE ON THIS DEVICE',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.white.withOpacity(0.65),
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 14),
          if (_isFaceAvailable)
            _biometricChip(Icons.face_unlock_outlined, 'Face ID'),
          if (_isFingerprintAvailable) ...[
            if (_isFaceAvailable) const SizedBox(height: 10),
            _biometricChip(Icons.fingerprint_rounded, 'Fingerprint / Touch ID'),
          ],
          if (!_isFaceAvailable && !_isFingerprintAvailable)
            Text(
              'No specific biometrics detected. Device PIN or pattern may be used as fallback.',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.75),
                  fontSize: 13,
                  height: 1.5),
            ),
        ],
      ),
    );
  }

  Widget _biometricChip(IconData icon, String label) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF1A5F4A).withOpacity(0.6),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            'Available',
            style: TextStyle(color: Colors.white, fontSize: 11),
          ),
        ),
      ],
    );
  }

  Widget _buildHowItWorksCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: Colors.white.withOpacity(0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline_rounded,
                  color: Colors.white.withOpacity(0.8), size: 16),
              const SizedBox(width: 6),
              Text(
                'How it works',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _infoItem('Enable the toggle and confirm your password once.'),
          _infoItem('On your next login, tap the biometric button on the login screen.'),
          _infoItem('Authenticate with Face ID or Fingerprint — no password needed.'),
          _infoItem('Your credentials are stored securely on this device only.'),
        ],
      ),
    );
  }

  Widget _infoItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 5),
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.6),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.75),
                  fontSize: 13,
                  height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}