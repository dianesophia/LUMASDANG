import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import '../../../services/firestore_service.dart';
import '../../../services/auth_service.dart';
import '../../../services/local_db_service.dart';

class EditProfile extends StatefulWidget {
  const EditProfile({super.key});

  @override
  State<EditProfile> createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  final _formKey = GlobalKey<FormState>();
  final _firestoreService = FirestoreService();
  final _authService = AuthService();
  final _imagePicker = ImagePicker();

  final TextEditingController _displayNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  File? _selectedImage;
  String? _currentProfileImageUrl;
  bool _loading = false;
  bool _imageUploading = false;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    setState(() => _loading = true);

    try {
      // Initialize LocalDbService if not already initialized
      await LocalDbService.instance.init();

      // Load from Firebase Auth
      final user = _authService.currentUser;
      if (user != null) {
        _displayNameController.text = user.displayName ?? '';
        _emailController.text = user.email ?? '';
        _currentProfileImageUrl = user.photoURL;
      }

      // Load from local cache as fallback
      final cachedDisplayName = LocalDbService.instance.getUserInfo('displayName');
      final cachedEmail = LocalDbService.instance.getUserInfo('email');
      final cachedPhotoURL = LocalDbService.instance.getUserInfo('photoURL');

      if (cachedDisplayName != null && _displayNameController.text.isEmpty) {
        _displayNameController.text = cachedDisplayName.toString();
      }
      if (cachedEmail != null && _emailController.text.isEmpty) {
        _emailController.text = cachedEmail.toString();
      }
      if (cachedPhotoURL != null && _currentProfileImageUrl == null) {
        _currentProfileImageUrl = cachedPhotoURL.toString();
      }
    } catch (e) {
      debugPrint('Error loading user profile: $e');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      // Check permissions
      if (source == ImageSource.camera) {
        final cameraPermission = await Permission.camera.request();
        if (!cameraPermission.isGranted) {
          _showErrorSnackBar('Camera permission is required to take photos');
          return;
        }
      } else {
        final storagePermission = await Permission.photos.request();
        if (!storagePermission.isGranted) {
          _showErrorSnackBar('Storage permission is required to select photos');
          return;
        }
      }

      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      _showErrorSnackBar('Failed to pick image: $e');
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      String? newImageUrl = _currentProfileImageUrl;

      // Upload new image if selected
      if (_selectedImage != null) {
        setState(() => _imageUploading = true);
        
        // Delete old image if exists
        if (_currentProfileImageUrl != null) {
          await _firestoreService.deleteOldProfileImage(_currentProfileImageUrl);
        }

        // Upload new image
        newImageUrl = await _firestoreService.uploadProfileImage(_selectedImage!);
        setState(() => _imageUploading = false);
      }

      // Update profile
      await _firestoreService.updateUserProfile(
        displayName: _displayNameController.text.trim().isEmpty 
            ? null 
            : _displayNameController.text.trim(),
        email: _emailController.text.trim().isEmpty 
            ? null 
            : _emailController.text.trim(),
        photoURL: newImageUrl,
        context: context,
      );

      // Update current image URL
      _currentProfileImageUrl = newImageUrl;
      _selectedImage = null;

      // Show success dialog
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text("Success"),
            content: const Text("Your profile has been updated successfully."),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
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
      debugPrint('Profile update failed: $e');
      setState(() => _imageUploading = false);
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String? _validateDisplayName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Display name is required';
    }
    if (value.trim().length < 2) {
      return 'Display name must be at least 2 characters';
    }
    if (value.trim().length > 50) {
      return 'Display name must be less than 50 characters';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    return _authService.validateEmail(value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
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
              // 🔙 Header
              _buildHeader(),
              const SizedBox(height: 24),
              // 🧑 Profile Image Section
              _buildProfileImageSection(),
              const SizedBox(height: 32),
              // ✏️ Form Fields
              Expanded(
                child: _buildFormSection(),
              ),
              // ✅ Update Button
              _buildUpdateButton(),
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
                    "Edit Profile",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 48), // keeps alignment
            ],
          ),
          Container(
            height: 1.5,
            width: double.infinity,
            color: Colors.white.withOpacity(0.3),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileImageSection() {
    return Column(
      children: [
        // Profile Image
        Stack(
          children: [
            CircleAvatar(
              radius: 55,
              backgroundColor: Colors.white,
              child: CircleAvatar(
                radius: 50,
                backgroundImage: _selectedImage != null
                    ? FileImage(_selectedImage!) as ImageProvider
                    : (_currentProfileImageUrl != null
                        ? NetworkImage(_currentProfileImageUrl!)
                        : const AssetImage('assets/profile.png')) as ImageProvider,
              ),
            ),
            if (_imageUploading)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        // 📸 Buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _actionButton(
              icon: Icons.camera_alt,
              label: 'Take Photo',
              isPrimary: false,
              onPressed: () => _pickImage(ImageSource.camera),
            ),
            const SizedBox(width: 12),
            _actionButton(
              icon: Icons.upload,
              label: 'Upload Photo',
              isPrimary: true,
              onPressed: () => _pickImage(ImageSource.gallery),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFormSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _labelWithCounter('Display Name', '${_displayNameController.text.length}/50'),
            _textField(
              controller: _displayNameController,
              validator: _validateDisplayName,
              hintText: 'Enter your display name',
            ),
            const SizedBox(height: 20),
            _labelWithCounter('Email', '${_emailController.text.length}/256'),
            _textField(
              controller: _emailController,
              validator: _validateEmail,
              hintText: 'Enter your email',
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpdateButton() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 32),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: _loading ? Colors.grey.withOpacity(0.5) : Colors.white70,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(
            horizontal: 48,
            vertical: 14,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        onPressed: _loading ? null : _updateProfile,
        child: _loading
            ? const Row(
                mainAxisSize: MainAxisSize.min,
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
                  Text('Updating...'),
                ],
              )
            : const Text(
                'Update My Profile',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
      ),
    );
  }

  // 🔘 Reusable action button
  Widget _actionButton({
    required IconData icon,
    required String label,
    required bool isPrimary,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: isPrimary ? Colors.white : Colors.white.withOpacity(0.6),
        foregroundColor: Colors.black,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      onPressed: _loading || _imageUploading ? null : onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
    );
  }

  // 🏷 Label + counter
  Widget _labelWithCounter(String label, String counter) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        Text(
          counter,
          style: const TextStyle(fontSize: 12, color: Colors.black54),
        ),
      ],
    );
  }

  // 📝 Text field style
  Widget _textField({
    required TextEditingController controller,
    String? Function(String?)? validator,
    String? hintText,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      enabled: !_loading,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hintText,
        filled: true,
        fillColor: _loading 
            ? Colors.grey.withOpacity(0.3)
            : Colors.white.withOpacity(0.4),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        hintStyle: const TextStyle(color: Colors.black54),
      ),
      style: const TextStyle(color: Colors.black87),
      onChanged: (value) {
        // Update counter when text changes
        setState(() {});
      },
    );
  }
}
