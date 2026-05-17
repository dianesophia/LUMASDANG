import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
import '../../services/firestore_service.dart';
import '../../services/local_db_service.dart';
import '../authPages/login.dart';

class EditProfile extends StatefulWidget {
  const EditProfile({super.key});

  @override
  State<EditProfile> createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  final _firestoreService = FirestoreService();
  final _localDbService = LocalDbService.instance;
  // final _imagePicker = ImagePicker();

  final TextEditingController _displayNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _loading = false;
  bool _loadingProfile = true;
  bool _emailChanged = false;
  bool _obscurePassword = true;
  // String? _profilePicturePath;
  String? _originalEmail;
  int _emailLength = 0;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();

    _displayNameController.addListener(() {
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
            // _profilePicturePath = profile['profilePicture'];
            _emailLength = _emailController.text.length;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading user profile: $e');
    } finally {
      setState(() => _loadingProfile = false);
    }
  }

  // Future<void> _takePhoto() async {
  //   try {
  //     final XFile? photo = await _imagePicker.pickImage(
  //       source: ImageSource.camera,
  //       maxWidth: 800,
  //       maxHeight: 800,
  //       imageQuality: 85,
  //     );
  //     if (photo != null) await _uploadProfilePicture(photo.path);
  //   } catch (e) {
  //     _showErrorSnackBar('Error taking photo: $e');
  //   }
  // }

  // Future<void> _uploadPhoto() async {
  //   try {
  //     final XFile? image = await _imagePicker.pickImage(
  //       source: ImageSource.gallery,
  //       maxWidth: 800,
  //       maxHeight: 800,
  //       imageQuality: 85,
  //     );
  //     if (image != null) await _uploadProfilePicture(image.path);
  //   } catch (e) {
  //     _showErrorSnackBar('Error uploading photo: $e');
  //   }
  // }

  // Future<void> _uploadProfilePicture(String imagePath) async {
  //   setState(() => _loading = true);
  //   try {
  //     final user = _firestoreService.auth.currentUser;
  //     if (user == null) return;
  //
  //     final uploadedPath = await _firestoreService.updateProfilePicture(user.uid, imagePath);
  //     if (uploadedPath != null) {
  //       setState(() => _profilePicturePath = uploadedPath);
  //       await _localDbService.updateProfilePictureForUser(user.uid, uploadedPath);
  //     }
  //   } finally {
  //     setState(() => _loading = false);
  //   }
  // }



  String? _validateInputs() {
    final displayName = _displayNameController.text.trim();
    final email = _emailController.text.trim();
    if (displayName.isEmpty) return 'Display name cannot be empty';
    if (displayName.length < 3) return 'Display name must be at least 3 characters';
    if (email.isEmpty) return 'Email cannot be empty';
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      return 'Please enter a valid email address';
    }
    if (_emailChanged && _passwordController.text.trim().isEmpty) {
      return 'Password is required to change email';
    }
    return null;
  }

  Future<void> _updateProfile() async {
    final validationError = _validateInputs();
    if (validationError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(validationError),
          backgroundColor: Colors.orange.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
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

      displayNameSuccess = await _firestoreService.updateDisplayName(
        displayName: displayName,
        context: context,
      );

      if (displayNameSuccess) {
        final user = _firestoreService.auth.currentUser;
        if (user != null) {
          await _localDbService.updateDisplayNameForUser(user.uid, displayName);
        }
      }

      if (_emailChanged) {
        emailSuccess = await _firestoreService.changeEmail(
          currentPassword: _passwordController.text.trim(),
          newEmail: newEmail,
          context: context,
        );

        if (emailSuccess) {
          final user = _firestoreService.auth.currentUser;
          if (user != null) {
            await _localDbService.updateEmailForUser(user.uid, newEmail);
          }
        }
      }

      if (mounted) {
        if (_emailChanged && emailSuccess) {
          _showResultDialog(
            title: "Profile Updated",
            message: "Your profile has been updated successfully.",
            subtitle: "A verification email has been sent to your new address. Check spam folder and please verify and log in again.",
            onConfirm: () async {
              await _firestoreService.auth.signOut();
              if (mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                  (route) => false,
                );
              }
            },
          );
        } else if (displayNameSuccess) {
          _showResultDialog(
            title: "Profile Updated",
            message: "Your profile has been updated successfully.",
            onConfirm: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
          );
        }
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  void _showResultDialog({
    required String title,
    required String message,
    String? subtitle,
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Color(0xFF2E8B7B), size: 28),
            const SizedBox(width: 10),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message, style: const TextStyle(fontSize: 15)),
            if (subtitle != null) ...[
              const SizedBox(height: 12),
              Text(subtitle, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
            ],
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: onConfirm,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E8B7B),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: const Text("Done", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // void _showPhotoOptions() {
  //   showModalBottomSheet(
  //     context: context,
  //     backgroundColor: Colors.transparent,
  //     builder: (context) => Container(
  //       margin: const EdgeInsets.all(16),
  //       decoration: BoxDecoration(
  //         color: Colors.white,
  //         borderRadius: BorderRadius.circular(20),
  //       ),
  //       child: Column(
  //         mainAxisSize: MainAxisSize.min,
  //         children: [
  //           const SizedBox(height: 8),
  //           Container(
  //             width: 40,
  //             height: 4,
  //             decoration: BoxDecoration(
  //               color: Colors.grey.shade300,
  //               borderRadius: BorderRadius.circular(2),
  //             ),
  //           ),
  //           const SizedBox(height: 16),
  //           const Text(
  //             "Update Photo",
  //             style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
  //           ),
  //           const SizedBox(height: 8),
  //           _bottomSheetOption(
  //             icon: Icons.camera_alt_rounded,
  //             label: "Take Photo",
  //             onTap: () {
  //               Navigator.pop(context);
  //               _takePhoto();
  //             },
  //           ),
  //           _bottomSheetOption(
  //             icon: Icons.photo_library_rounded,
  //             label: "Choose from Gallery",
  //             onTap: () {
  //               Navigator.pop(context);
  //               _uploadPhoto();
  //             },
  //           ),
  //           const SizedBox(height: 16),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  // Widget _bottomSheetOption({
  //   required IconData icon,
  //   required String label,
  //   required VoidCallback onTap,
  // }) {
  //   return ListTile(
  //     leading: Container(
  //       width: 40,
  //       height: 40,
  //       decoration: BoxDecoration(
  //         color: const Color(0xFF2E8B7B).withOpacity(0.1),
  //         borderRadius: BorderRadius.circular(10),
  //       ),
  //       child: Icon(icon, color: const Color(0xFF2E8B7B), size: 22),
  //     ),
  //     title: Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
  //     onTap: onTap,
  //   );
  // }

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
              ? const Center(child: CircularProgressIndicator(color: Colors.white))
              : Column(
                  children: [
                    /// ── HEADER ───────────────────────────────────────────
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
                                    //"Edit Profile",
                                    "Change Email",
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

                    const SizedBox(height: 28),

                    /// ── CONTENT ──────────────────────────────────────────
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [

                            /// ── Profile Photo (commented out) ────────────
                            // Center(
                            //   child: Stack(
                            //     children: [
                            //       // Avatar ring
                            //       Container(
                            //         width: 108,
                            //         height: 108,
                            //         decoration: BoxDecoration(
                            //           shape: BoxShape.circle,
                            //           border: Border.all(
                            //             color: Colors.white.withOpacity(0.6),
                            //             width: 3,
                            //           ),
                            //         ),
                            //         child: ClipOval(
                            //           child: _profilePicturePath != null &&
                            //                   _profilePicturePath!.isNotEmpty
                            //               ? Builder(builder: (context) {
                            //                   try {
                            //                     return Image.memory(
                            //                       base64Decode(_profilePicturePath!),
                            //                       fit: BoxFit.cover,
                            //                     );
                            //                   } catch (_) {
                            //                     return _defaultAvatar();
                            //                   }
                            //                 })
                            //               : _defaultAvatar(),
                            //         ),
                            //       ),
                            //       // Loading overlay
                            //       if (_loading)
                            //         Positioned.fill(
                            //           child: Container(
                            //             decoration: BoxDecoration(
                            //               shape: BoxShape.circle,
                            //               color: Colors.black.withOpacity(0.45),
                            //             ),
                            //             child: const Center(
                            //               child: CircularProgressIndicator(
                            //                 color: Colors.white,
                            //                 strokeWidth: 2,
                            //               ),
                            //             ),
                            //           ),
                            //         ),
                            //       // Edit badge
                            //       Positioned(
                            //         bottom: 2,
                            //         right: 2,
                            //         child: GestureDetector(
                            //           onTap: _loading ? null : _showPhotoOptions,
                            //           child: Container(
                            //             width: 32,
                            //             height: 32,
                            //             decoration: BoxDecoration(
                            //               color: Colors.white,
                            //               shape: BoxShape.circle,
                            //               border: Border.all(
                            //                 color: const Color(0xFF2E8B7B),
                            //                 width: 2,
                            //               ),
                            //             ),
                            //             child: const Icon(
                            //               Icons.camera_alt_rounded,
                            //               color: Color(0xFF2E8B7B),
                            //               size: 16,
                            //             ),
                            //           ),
                            //         ),
                            //       ),
                            //     ],
                            //   ),
                            // ),
                            //
                            // const SizedBox(height: 8),
                            //
                            // Center(
                            //   child: TextButton(
                            //     onPressed: _loading ? null : _showPhotoOptions,
                            //     child: Text(
                            //       "Change Photo",
                            //       style: TextStyle(
                            //         color: Colors.white.withOpacity(0.85),
                            //         fontSize: 13,
                            //         fontWeight: FontWeight.w600,
                            //         decoration: TextDecoration.underline,
                            //         decorationColor: Colors.white.withOpacity(0.6),
                            //       ),
                            //     ),
                            //   ),
                            // ),
                            //
                            // const SizedBox(height: 28),

                            /// ── Display Name ─────────────────────────────
                           /* _sectionLabel("Display Name"),
                            const SizedBox(height: 8),
                            _inputField(
                              controller: _displayNameController,
                              hint: "Enter display name",
                              icon: Icons.badge_outlined,
                              maxLength: 20,
                              counter: '$_displayNameLength/20',
                            ),
*/


                            const SizedBox(height: 20),

                            /// ── Email ─────────────────────────────────────
                            _sectionLabel("Email"),
                            const SizedBox(height: 8),
                            _inputField(
                              controller: _emailController,
                              hint: "Enter email address",
                              icon: Icons.mail_outline_rounded,
                              maxLength: 256,
                              counter: '$_emailLength/256',
                              keyboardType: TextInputType.emailAddress,
                            ),

                            /// ── Password (conditional) ────────────────────
                            if (_emailChanged) ...[
                              const SizedBox(height: 20),
                              _sectionLabel("Current Password"),
                              const SizedBox(height: 8),
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.95),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.6),
                                    width: 1.2,
                                  ),
                                ),
                                child: TextField(
                                  controller: _passwordController,
                                  enabled: !_loading,
                                  obscureText: _obscurePassword,
                                  style: const TextStyle(
                                    color: Colors.black87,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 15,
                                  ),
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 16),
                                    prefixIcon: const Icon(
                                      Icons.lock_outline_rounded,
                                      color: Color(0xFF2E8B7B),
                                      size: 20,
                                    ),
                                    hintText: "Required to change email",
                                    hintStyle: TextStyle(
                                      color: Colors.grey.shade400,
                                      fontSize: 14,
                                    ),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_off_outlined
                                            : Icons.visibility_outlined,
                                        color: Colors.grey.shade500,
                                        size: 20,
                                      ),
                                      onPressed: () {
                                        setState(() => _obscurePassword = !_obscurePassword);
                                      },
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 12),

                              // Info banner
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.2),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.info_outline_rounded,
                                      color: Colors.white.withOpacity(0.8),
                                      size: 16,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        "You'll need to log in again after changing your email.",
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.8),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],

                            const SizedBox(height: 36),

                            /// ── Save Button ───────────────────────────────
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _loading ? null : _updateProfile,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: const Color(0xFF2E8B7B),
                                  disabledBackgroundColor: Colors.white.withOpacity(0.5),
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 0,
                                ),
                                child: _loading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          valueColor: AlwaysStoppedAnimation<Color>(
                                            Color(0xFF2E8B7B),
                                          ),
                                        ),
                                      )
                                    : const Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.check_rounded, size: 20),
                                          SizedBox(width: 8),
                                          Text(
                                            "Save Changes",
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w700,
                                              letterSpacing: 0.3,
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ),

                            const SizedBox(height: 32),
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

  // Widget _defaultAvatar() {
  //   return Container(
  //     color: Colors.white.withOpacity(0.25),
  //     child: const Icon(Icons.person_rounded, size: 56, color: Colors.white),
  //   );
  // }

  Widget _sectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Colors.white.withOpacity(0.65),
          letterSpacing: 1.4,
        ),
      ),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    int? maxLength,
    String? counter,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.95),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Colors.white.withOpacity(0.6),
              width: 1.2,
            ),
          ),
          child: TextField(
            controller: controller,
            enabled: !_loading,
            maxLength: maxLength,
            keyboardType: keyboardType,
            style: const TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.w500,
              fontSize: 15,
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              counterText: '',
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              prefixIcon: Icon(icon, color: const Color(0xFF2E8B7B), size: 20),
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
            ),
          ),
        ),
        if (counter != null)
          Padding(
            padding: const EdgeInsets.only(top: 4, right: 4),
            child: Text(
              counter,
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 11,
              ),
            ),
          ),
      ],
    );
  }
}