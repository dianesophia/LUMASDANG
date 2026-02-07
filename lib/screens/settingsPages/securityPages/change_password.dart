import 'package:flutter/material.dart';
import '../../../services/firestore_service.dart';
import '../../../services/auth_service.dart';

class ChangePassword extends StatefulWidget {
  const ChangePassword({super.key});

  @override
  State<ChangePassword> createState() => _ChangePasswordState();
}

class _ChangePasswordState extends State<ChangePassword> {
  final _formKey = GlobalKey<FormState>();
  final _firestoreService = FirestoreService();
  final _authService = AuthService();

  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _loading = false;
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _updatePassword() async {
    debugPrint('Starting password update...');
    if (!_formKey.currentState!.validate()) {
      debugPrint('Form validation failed');
      return;
    }

    setState(() => _loading = true);
    debugPrint('Loading state set to true');

    try {
      debugPrint('Calling firestoreService.changePassword...');
      await _firestoreService.changePassword(
        currentPassword: _currentPasswordController.text.trim(),
        newPassword: _newPasswordController.text.trim(),
        context: context,
      );
      debugPrint('Password change completed successfully');

      // Clear form on success
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();

      // Show success dialog and navigate back
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text("Success"),
            content: const Text("Your password has been updated successfully."),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // close dialog
                  Navigator.pop(context); // go back
                },
                child: const Text(
                  "OK",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      debugPrint('Password update failed: $e');
      // Error handling is done in FirestoreService
    } finally {
      debugPrint('Finally block - setting loading to false');
      if (mounted) {
        setState(() => _loading = false);
        debugPrint('Loading state set to false');
      }
    }
  }

  String? _validateCurrentPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your current password';
    }
    return null;
  }

  String? _validateNewPassword(String? value) {
    return _authService.validatePassword(value);
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your new password';
    }
    if (value != _newPasswordController.text) {
      return 'Passwords do not match';
    }
    return null;
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
              // ================= HEADER =================
              _buildHeader(),
              const SizedBox(height: 20),
              // ================= FORM =================
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _passwordField(
                          controller: _currentPasswordController,
                          label: "Current Password",
                          obscureText: _obscureCurrent,
                          toggleObscure: () {
                            setState(() => _obscureCurrent = !_obscureCurrent);
                          },
                          validator: _validateCurrentPassword,
                        ),
                        const SizedBox(height: 16),
                        _passwordField(
                          controller: _newPasswordController,
                          label: "New Password",
                          obscureText: _obscureNew,
                          toggleObscure: () {
                            setState(() => _obscureNew = !_obscureNew);
                          },
                          validator: _validateNewPassword,
                        ),
                        const SizedBox(height: 16),
                        _passwordField(
                          controller: _confirmPasswordController,
                          label: "Confirm New Password",
                          obscureText: _obscureConfirm,
                          toggleObscure: () {
                            setState(() => _obscureConfirm = !_obscureConfirm);
                          },
                          validator: _validateConfirmPassword,
                        ),
                        const SizedBox(height: 30),
                        _buildUpdateButton(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () => Navigator.pop(context),
              ),
              const Expanded(
                child: Center(
                  child: Text(
                    "Change Password",
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
          Container(
            margin: const EdgeInsets.only(top: 4),
            height: 1.5,
            width: double.infinity,
            color: Colors.white.withOpacity(0.3),
          ),
        ],
      ),
    );
  }

  Widget _buildUpdateButton() {
    return GestureDetector(
      onTap: _loading ? null : _updatePassword,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: _loading 
              ? Colors.grey.withOpacity(0.5)
              : Colors.white70,
          borderRadius: BorderRadius.circular(25),
        ),
        alignment: Alignment.center,
        child: _loading
            ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    "Updating...",
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              )
            : const Text(
                "Update Password",
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
      ),
    );
  }

  Widget _passwordField({
    required TextEditingController controller,
    required String label,
    required bool obscureText,
    required VoidCallback toggleObscure,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      validator: validator,
      enabled: !_loading,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: _loading 
            ? Colors.grey.withOpacity(0.3)
            : Colors.white.withOpacity(0.6),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        suffixIcon: IconButton(
          icon: Icon(
            obscureText ? Icons.visibility_off : Icons.visibility,
            color: Colors.black54,
          ),
          onPressed: _loading ? null : toggleObscure,
        ),
        labelStyle: const TextStyle(color: Colors.black87),
      ),
      style: const TextStyle(color: Colors.black87),
    );
  }
}
