import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/firestore_service.dart';
import '../../services/local_db_service.dart';
import '../authPages/login.dart';
import 'dart:convert';


class EditProfile extends StatefulWidget {
  const EditProfile({super.key});

  @override
  State<EditProfile> createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  final _firestoreService = FirestoreService();
  final _localDbService = LocalDbService.instance;
  final _imagePicker = ImagePicker();
  
  final TextEditingController _displayNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _loading = false;
  bool _loadingProfile = true;
  bool _emailChanged = false;
  bool _obscurePassword = true;
  String? _profilePicturePath;
  String? _originalEmail;
  int _displayNameLength = 0;
  int _emailLength = 0;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    
    _displayNameController.addListener(() {
      setState(() {
        _displayNameLength = _displayNameController.text.length;
      });
    });
    
    _emailController.addListener(() {
      setState(() {
        _emailLength = _emailController.text.length;
        _emailChanged = _emailController.text.trim() != _originalEmail;
      });
    });
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Load user profile data from Firestore
  Future<void> _loadUserProfile() async {
    setState(() => _loadingProfile = true);
    
    try {
      final user = _firestoreService.auth.currentUser;
      
      if (user != null) {
        final profile = await _firestoreService.getUserProfile();
        
        if (mounted && profile != null) {
          setState(() {
            _displayNameController.text = profile['displayName'] ?? user.displayName ?? '';
            _emailController.text = profile['email'] ?? user.email ?? '';
            _originalEmail = user.email;
            _profilePicturePath = profile['profilePicture'];
            _displayNameLength = _displayNameController.text.length;
            _emailLength = _emailController.text.length;
          });
        }
      }
    } catch (e) {
      print('Error loading user profile: $e');
    } finally {
      setState(() => _loadingProfile = false);
    }
  }

  /// Take photo using camera
  Future<void> _takePhoto() async {
    try {
      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (photo != null) {
        await _uploadProfilePicture(photo.path);
      }
    } catch (e) {
      print('Error taking photo: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error taking photo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Upload photo from gallery
  Future<void> _uploadPhoto() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null) {
        await _uploadProfilePicture(image.path);
      }
    } catch (e) {
      print('Error uploading photo: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading photo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Upload profile picture to Firestore and update local DB
  Future<void> _uploadProfilePicture(String imagePath) async {
    setState(() => _loading = true);

    try {
      final user = _firestoreService.auth.currentUser;

if (user == null) return;

final uploadedPath =
    await _firestoreService.updateProfilePicture(
      user.uid,
      imagePath,
    );


      if (uploadedPath != null) {
        setState(() {
          _profilePicturePath = uploadedPath;
        });

        // Update local DB
        final user = _firestoreService.auth.currentUser;
        if (user != null) {
          await _localDbService.updateProfilePictureForUser(
            user.uid,
            uploadedPath,
          );
        }
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  /// Validate inputs
  String? _validateInputs() {
    final displayName = _displayNameController.text.trim();
    final email = _emailController.text.trim();
    
    if (displayName.isEmpty) {
      return 'Display name cannot be empty';
    }
    
    if (displayName.length < 3) {
      return 'Display name must be at least 3 characters';
    }
    
    if (email.isEmpty) {
      return 'Email cannot be empty';
    }
    
    // Email format validation
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      return 'Please enter a valid email address';
    }
    
    // If email changed, password is required
    if (_emailChanged && _passwordController.text.trim().isEmpty) {
      return 'Password is required to change email';
    }
    
    return null;
  }

  /// Update profile
  Future<void> _updateProfile() async {
    // Validate inputs
    final validationError = _validateInputs();
    if (validationError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(validationError),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final displayName = _displayNameController.text.trim();
      final newEmail = _emailController.text.trim();
      
      bool displayNameSuccess = false;
      bool emailSuccess = false;

      // Update display name
      displayNameSuccess = await _firestoreService.updateDisplayName(
        displayName: displayName,
        context: context,
      );

      if (displayNameSuccess) {
        // Update local DB
        final user = _firestoreService.auth.currentUser;
        if (user != null) {
          await _localDbService.updateDisplayNameForUser(
            user.uid,
            displayName,
          );
        }
      }

      // Update email if changed
      if (_emailChanged) {
        emailSuccess = await _firestoreService.changeEmail(
          currentPassword: _passwordController.text.trim(),
          newEmail: newEmail,
          context: context,
        );

        if (emailSuccess) {
          // Update local DB
          final user = _firestoreService.auth.currentUser;
          if (user != null) {
            await _localDbService.updateEmailForUser(user.uid, newEmail);
          }
        }
      }

      if (mounted) {
        if (_emailChanged && emailSuccess) {
          // Email was changed - show verification dialog and sign out
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 28),
                  SizedBox(width: 10),
                  Text("Profile Updated"),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Your profile has been updated successfully.",
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "A verification email has been sent to your new email address. Please verify and log in again.",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () async {
                    // Sign out user
                    await _firestoreService.auth.signOut();
                    
                    if (mounted) {
                      Navigator.pop(context); // close dialog
                      // Navigate to login screen
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginPage()),
                        (route) => false,
                      );
                    }
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFF2E8B7B),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    "OK",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          );
        } else if (displayNameSuccess) {
          // Only display name was changed - show success and go back
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 28),
                  SizedBox(width: 10),
                  Text("Success"),
                ],
              ),
              content: const Text(
                "Your profile has been updated successfully.",
                style: TextStyle(fontSize: 16),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context); // close dialog
                    Navigator.pop(context); // go back
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFF2E8B7B),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    "OK",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          );
        }
      }
    } finally {
      setState(() => _loading = false);
    }
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
          child: _loadingProfile
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                )
              : Column(
                  children: [
                    // Custom AppBar
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back, color: Colors.white),
                            onPressed: () => Navigator.pop(context),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Edit Profile',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),

                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            const SizedBox(height: 20),

                            // Profile Picture
                            Stack(
                              children: [
                                Container(
                                  width: 120,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white,
                                    border: Border.all(color: Colors.white, width: 3),
                                  ),
                                  child: ClipOval(
                                   child: _profilePicturePath != null &&
                                              _profilePicturePath!.isNotEmpty
                                          ? Builder(
                                              builder: (context) {
                                                try {
                                                  return Image.memory(
                                                    base64Decode(_profilePicturePath!),
                                                    fit: BoxFit.cover,
                                                  );
                                                } catch (e) {
                                                  return const Icon(Icons.person, size: 60, color: Colors.grey);
                                                }
                                              },
                                            )
                                          : const Icon(Icons.person, size: 60, color: Colors.grey),


                                  ),
                                ),
                                if (_loading)
                                  Positioned.fill(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.black.withOpacity(0.5),
                                      ),
                                      child: const Center(
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),

                            const SizedBox(height: 20),

                            // Buttons Row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Take Photo Button
                                Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF4A4A4A),
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(25),
                                      onTap: _loading ? null : _takePhoto,
                                      child: const Padding(
                                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                        child: Row(
                                          children: [
                                            Icon(Icons.camera_alt, color: Colors.white, size: 20),
                                            SizedBox(width: 8),
                                            Text(
                                              'Take Photo',
                                              style: TextStyle(color: Colors.white, fontSize: 14),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(width: 12),

                                // Upload Photo Button
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(25),
                                      onTap: _loading ? null : _uploadPhoto,
                                      child: const Padding(
                                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                        child: Row(
                                          children: [
                                            Icon(Icons.upload, color: Color(0xFF4A4A4A), size: 20),
                                            SizedBox(width: 8),
                                            Text(
                                              'Upload Photo',
                                              style: TextStyle(color: Color(0xFF4A4A4A), fontSize: 14),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 40),

                            // Display Name Field
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Display Name',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF7EBAA3),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: TextField(
                                      controller: _displayNameController,
                                      enabled: !_loading,
                                      style: const TextStyle(color: Colors.white),
                                      maxLength: 20,
                                      decoration: InputDecoration(
                                        border: InputBorder.none,
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                        counterText: '$_displayNameLength/20',
                                        counterStyle: const TextStyle(color: Colors.white70, fontSize: 12),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Email Field
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Email',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF7EBAA3),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: TextField(
                                      controller: _emailController,
                                      enabled: !_loading,
                                      style: const TextStyle(color: Colors.white),
                                      maxLength: 256,
                                      keyboardType: TextInputType.emailAddress,
                                      decoration: InputDecoration(
                                        border: InputBorder.none,
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                        counterText: '$_emailLength/256',
                                        counterStyle: const TextStyle(color: Colors.white70, fontSize: 12),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Password field (only shown if email changed)
                            if (_emailChanged) ...[
                              const SizedBox(height: 24),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Current Password',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF7EBAA3),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: TextField(
                                        controller: _passwordController,
                                        enabled: !_loading,
                                        obscureText: _obscurePassword,
                                        style: const TextStyle(color: Colors.white),
                                        decoration: InputDecoration(
                                          border: InputBorder.none,
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                          suffixIcon: IconButton(
                                            icon: Icon(
                                              _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                              color: Colors.white70,
                                            ),
                                            onPressed: () {
                                              setState(() {
                                                _obscurePassword = !_obscurePassword;
                                              });
                                            },
                                          ),
                                          hintText: 'Required to change email',
                                          hintStyle: const TextStyle(color: Colors.white60, fontSize: 12),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(Icons.info_outline, color: Colors.white, size: 16),
                                      SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'You\'ll need to log in again after changing your email.',
                                          style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],

                            const SizedBox(height: 40),

                            // Update Button
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24.0),
                              child: SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _loading ? null : _updateProfile,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: const Color(0xFF2E8B7B),
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    elevation: 2,
                                  ),
                                  child: _loading
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Color(0xFF2E8B7B),
                                          ),
                                        )
                                      : const Text(
                                          'Update My Profile',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                ),
                              ),
                            ),
                            
                            const SizedBox(height: 24),
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
}