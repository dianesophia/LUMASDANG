import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:lumasdang/screens/home/home_page.dart';
import '../../services/connectivity_service.dart';
import '../../services/local_db_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> with TickerProviderStateMixin {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _contactController = TextEditingController();
  final _addressController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _otherBarangayController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  bool _isLoading = false;
  bool _checkingUsername = false;
  bool _usernameAvailable = true;
  String _usernameErrorMessage = '';
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  String? selectedSex;
  DateTime? selectedBirthday;
  String? selectedBarangay;

  late AnimationController _contentController;
  late Animation<double> _contentFade;
  late Animation<Offset> _contentSlide;

  final List<String> barangays = [
    "Barangay Alapang",
    "Barangay Alno",
    "Barangay Ambiong",
    "Barangay Bahong",
    "Barangay Balili",
    "Barangay Beckel",
    "Barangay Betag",
    "Barangay Bineng",
    "Barangay Cruz",
    "Barangay Lubas",
    "Barangay Pico",
    "Barangay Poblacion",
    "Barangay Puguis",
    "Barangay Shilan",
    "Barangay Tawang",
    "Barangay Wangal",
    "Others (Please specify)",
  ];

  final List<String> sexOptions = ["Male", "Female"];

  // Steps for multi-step form
  int _currentStep = 0;
  final int _totalSteps = 3;

  @override
  void initState() {
    super.initState();
    _contentController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );
    _contentFade = CurvedAnimation(parent: _contentController, curve: Curves.easeOut);
    _contentSlide = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _contentController, curve: Curves.easeOutCubic));

    _contentController.forward();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _contactController.dispose();
    _addressController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _otherBarangayController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  String capitalizeWords(String text) {
    return text
        .split(" ")
        .map((word) => word.isEmpty
            ? word
            : "${word[0].toUpperCase()}${word.substring(1).toLowerCase()}")
        .join(" ");
  }

  Future<void> _checkUsernameAvailability(String username) async {
    if (username.isEmpty || username.length < 3) {
      setState(() {
        _usernameAvailable = false;
        _usernameErrorMessage = '';
      });
      return;
    }

    setState(() {
      _checkingUsername = true;
      _usernameErrorMessage = '';
    });

    try {
      final doc = await _firestore
          .collection('usernames')
          .doc(username.toLowerCase())
          .get();

      if (mounted) {
        setState(() {
          _usernameAvailable = !doc.exists;
          _checkingUsername = false;
          _usernameErrorMessage = doc.exists ? 'Username is already taken' : 'Username is available';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _checkingUsername = false;
          _usernameErrorMessage = 'Error checking username';
        });
      }
    }
  }

  Future<void> _selectBirthday() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000, 1, 1),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF2E8B7B),
              onPrimary: Colors.white,
              surface: Color(0xFFF8F5EF),
              onSurface: Color(0xFF0F3D33),
            ),
            dialogBackgroundColor: const Color(0xFFF8F5EF),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != selectedBirthday) {
      setState(() => selectedBirthday = picked);
    }
  }

  Future<void> _register() async {
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final contact = _contactController.text.trim();
    final address = _addressController.text.trim();
    final password = _passwordController.text.trim();
    final confirm = _confirmController.text.trim();

    if (firstName.isEmpty) return _showSnack("Please enter your first name");
    if (firstName.length < 2) return _showSnack("First name must be at least 2 characters");
    if (lastName.isEmpty) return _showSnack("Please enter your last name");
    if (lastName.length < 2) return _showSnack("Last name must be at least 2 characters");
    if (username.isEmpty) return _showSnack("Please enter a username");
    if (username.length < 3) return _showSnack("Username must be at least 3 characters");
    if (!_usernameAvailable) return _showSnack("Username is already taken");
    if (email.isEmpty) return _showSnack("Please enter your email");
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) return _showSnack("Please enter a valid email");
    if (contact.isEmpty) return _showSnack("Please enter your contact number");
    if (contact.length < 10) return _showSnack("Please enter a valid contact number");
    if (selectedSex == null) return _showSnack("Please select your sex");
    if (selectedBirthday == null) return _showSnack("Please select your birthday");
    if (address.isEmpty) return _showSnack("Please enter your address");
    if (selectedBarangay == null) return _showSnack("Please select your barangay");
    if (password.isEmpty) return _showSnack("Please enter a password");
    if (password.length < 6) return _showSnack("Password must be at least 6 characters");
    if (password != confirm) return _showSnack("Passwords do not match");

    String finalBarangay;
    if (selectedBarangay == "Others (Please specify)") {
      final typed = _otherBarangayController.text.trim();
      if (typed.length <= 9) return _showSnack("Please type your barangay name");
      final nameOnly = typed.substring(9).trim();
      if (nameOnly.isEmpty) return _showSnack("Please type your barangay name");
      finalBarangay = "Barangay ${capitalizeWords(nameOnly)}";
    } else {
      finalBarangay = selectedBarangay!;
    }

    setState(() => _isLoading = true);

    // Registration requires an internet connection (Firebase account + Firestore docs).
    //final online = await ConnectivityService.instance.checkOnline();
    final online = kIsWeb ? true : await ConnectivityService.instance.checkOnline();
    if (!online) {
      _showSnack('Internet connection is required to create a new account. You can log in offline only after a successful online sign-in.');
      setState(() => _isLoading = false);
      return;
    }

    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;

      if (user != null) {
        final barangayId = finalBarangay.toLowerCase().replaceAll(" ", "_");
        final fullName = "$firstName $lastName";
        final age = DateTime.now().year - selectedBirthday!.year;
        final batch = _firestore.batch();

        batch.set(_firestore.collection('users').doc(user.uid), {
          'uid': user.uid,
          'firstName': firstName,
          'lastName': lastName,
          'fullName': fullName,
          'username': username,
          'email': email,
          'contactNumber': contact,
          'sex': selectedSex,
          'birthday': Timestamp.fromDate(selectedBirthday!),
          'age': age,
          'address': address,
          'barangay': finalBarangay,
          'barangayId': barangayId,
          'createdAt': Timestamp.now(),
          'isDeleted': false,
        });

        batch.set(
          _firestore.collection('usernames').doc(username.toLowerCase()),
          {'email': email, 'uid': user.uid, 'createdAt': Timestamp.now()},
        );

        batch.set(
          _firestore.collection('barangays').doc(barangayId).collection('users').doc(user.uid),
          {
            'uid': user.uid,
            'fullName': fullName,
            'username': username,
            'email': email,
            'sex': selectedSex,
            'age': age,
            'createdAt': Timestamp.now(),
          },
        );

        batch.set(
          _firestore.collection('barangays').doc(barangayId),
          {'name': finalBarangay, 'barangayId': barangayId, 'createdAt': FieldValue.serverTimestamp()},
          SetOptions(merge: true),
        );

        await batch.commit();

        // Cache credentials so this account can log in offline later.
        try {
          final emailLower = email.toLowerCase();
          await _secureStorage.write(
              key: 'cached_password_for_email:$emailLower', value: password);
          await _secureStorage.write(
              key: 'cached_email_for_username:${username.toLowerCase()}',
              value: email);
        } catch (_) {
          // ignore storage errors
        }

        // Mark session as online‑authenticated
        LocalDbService.instance.setOfflineAuthenticated(false);

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomePage()),
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      String message = 'Registration failed';
      switch (e.code) {
        case 'weak-password': message = 'Password is too weak (minimum 6 characters)'; break;
        case 'email-already-in-use': message = 'Email is already registered'; break;
        case 'invalid-email': message = 'Invalid email address'; break;
        default: message = e.message ?? 'Registration failed';
      }
      _showSnack(message);
    } catch (e) {
      _showSnack("Registration failed: ${e.toString()}");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(child: Text(msg)),
          ],
        ),
        backgroundColor: const Color(0xFFB85C5C),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background
          Container(
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
          ),

          // Decorative elements
          Positioned(
            top: -60,
            right: -40,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.04),
                border: Border.all(color: Colors.white.withOpacity(0.06)),
              ),
            ),
          ),
          Positioned(
            bottom: -80,
            left: -60,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.03),
                border: Border.all(color: Colors.white.withOpacity(0.04)),
              ),
            ),
          ),

          // Content
          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.arrow_back_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Create Account',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                fontFamily: 'Georgia',
                              ),
                            ),
                            Text(
                              'Join the Lµmasdαng community',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white60,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Leaf icon
                      Opacity(
                        opacity: 0.4,
                        child: const Icon(Icons.eco_rounded, color: Colors.white, size: 32),
                      ),
                    ],
                  ),
                ),

                // Progress indicator
                Padding(
                  padding: const EdgeInsets.fromLTRB(28, 20, 28, 0),
                  child: _buildProgressBar(),
                ),

                const SizedBox(height: 20),

                // Form card
                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFFF8F5EF),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(32),
                        topRight: Radius.circular(32),
                      ),
                    ),
                    child: FadeTransition(
                      opacity: _contentFade,
                      child: SlideTransition(
                        position: _contentSlide,
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(28, 32, 28, 32),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildStepTitle(),
                              const SizedBox(height: 24),
                              _buildCurrentStepFields(),
                              const SizedBox(height: 32),
                              _buildNavigationButtons(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Row(
      children: List.generate(_totalSteps, (index) {
        final isActive = index <= _currentStep;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: index < _totalSteps - 1 ? 8 : 0),
            height: 4,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              color: isActive
                  ? Colors.white
                  : Colors.white.withOpacity(0.25),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildStepTitle() {
    final titles = [
      ('Personal Info', 'Tell us about yourself'),
      ('Location Details', 'Where are you located?'),
      ('Account Security', 'Set up your login credentials'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF2E8B7B).withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Step ${_currentStep + 1} of $_totalSteps',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF2E8B7B),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          titles[_currentStep].$1,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A5F4A),
            fontFamily: 'Georgia',
          ),
        ),
        const SizedBox(height: 4),
        Text(
          titles[_currentStep].$2,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade500,
          ),
        ),
      ],
    );
  }

  Widget _buildCurrentStepFields() {
    switch (_currentStep) {
      case 0:
        return _buildStep1();
      case 1:
        return _buildStep2();
      case 2:
        return _buildStep3();
      default:
        return const SizedBox();
    }
  }

  Widget _buildStep1() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: _firstNameController,
                label: 'First Name',
                icon: Icons.badge_outlined,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTextField(
                controller: _lastNameController,
                label: 'Last Name',
                icon: Icons.badge_outlined,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildUsernameField(),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _emailController,
          label: 'Email Address',
          icon: Icons.mail_outline_rounded,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _contactController,
          label: 'Contact Number',
          icon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 16),
        _buildSexDropdown(),
        const SizedBox(height: 16),
        _buildBirthdayPicker(),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      children: [
        _buildTextField(
          controller: _addressController,
          label: 'Complete Address',
          icon: Icons.home_outlined,
          maxLines: 2,
        ),
        const SizedBox(height: 16),
        _buildBarangayDropdown(),
        if (selectedBarangay == "Others (Please specify)") ...[
          const SizedBox(height: 16),
          _buildOtherBarangayField(),
        ],
      ],
    );
  }

  Widget _buildStep3() {
    return Column(
      children: [
        _buildTextField(
          controller: _passwordController,
          label: 'Password',
          icon: Icons.lock_outline_rounded,
          isPassword: true,
          isObscure: _obscurePassword,
          onToggleObscure: () => setState(() => _obscurePassword = !_obscurePassword),
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _confirmController,
          label: 'Confirm Password',
          icon: Icons.lock_outline_rounded,
          isPassword: true,
          isObscure: _obscureConfirm,
          onToggleObscure: () => setState(() => _obscureConfirm = !_obscureConfirm),
        ),
        const SizedBox(height: 24),
        // Password requirements
        _buildPasswordHints(),
      ],
    );
  }

  Widget _buildPasswordHints() {
    final password = _passwordController.text;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2E8B7B).withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2E8B7B).withOpacity(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Password requirements',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2E8B7B),
            ),
          ),
          const SizedBox(height: 8),
          _buildHint('At least 6 characters', password.length >= 6),
          _buildHint('Passwords match', password.isNotEmpty && password == _confirmController.text),
        ],
      ),
    );
  }

  Widget _buildHint(String text, bool met) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(
            met ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
            size: 14,
            color: met ? const Color(0xFF2E8B7B) : Colors.grey.shade400,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: met ? const Color(0xFF2E8B7B) : Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Row(
      children: [
        if (_currentStep > 0)
          Expanded(
            child: OutlinedButton(
              onPressed: () {
                setState(() => _currentStep--);
                _contentController.reset();
                _contentController.forward();
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF2E8B7B), width: 1.5),
                foregroundColor: const Color(0xFF2E8B7B),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.arrow_back_rounded, size: 16),
                  SizedBox(width: 6),
                  Text('Back', style: TextStyle(fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        if (_currentStep > 0) const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: _isLoading
                ? null
                : () {
                    if (_currentStep < _totalSteps - 1) {
                      setState(() => _currentStep++);
                      _contentController.reset();
                      _contentController.forward();
                    } else {
                      _register();
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A5F4A),
              disabledBackgroundColor: Colors.grey.shade200,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _currentStep < _totalSteps - 1 ? 'Continue' : 'Create Account',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        _currentStep < _totalSteps - 1
                            ? Icons.arrow_forward_rounded
                            : Icons.check_rounded,
                        size: 18,
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  // ---------- FIELD WIDGETS ----------

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    bool isObscure = false,
    VoidCallback? onToggleObscure,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword ? isObscure : false,
      keyboardType: keyboardType,
      maxLines: isPassword ? 1 : maxLines,
      style: const TextStyle(
        color: Color(0xFF1A5F4A),
        fontSize: 15,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
        prefixIcon: Icon(icon, color: const Color(0xFF2E8B7B), size: 20),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  isObscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: Colors.grey.shade400,
                  size: 20,
                ),
                onPressed: onToggleObscure,
              )
            : null,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE2DDD5)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE2DDD5), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF2E8B7B), width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  Widget _buildUsernameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _usernameController,
          style: const TextStyle(
            color: Color(0xFF1A5F4A),
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
          onChanged: (value) {
            Future.delayed(const Duration(milliseconds: 500), () {
              if (_usernameController.text == value) {
                _checkUsernameAvailability(value.trim());
              }
            });
          },
          decoration: InputDecoration(
            labelText: 'Username',
            labelStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
            prefixIcon: const Icon(Icons.alternate_email_rounded, color: Color(0xFF2E8B7B), size: 20),
            suffixIcon: _checkingUsername
                ? const Padding(
                    padding: EdgeInsets.all(14),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF2E8B7B)),
                    ),
                  )
                : (_usernameController.text.length >= 3
                    ? Icon(
                        _usernameAvailable ? Icons.check_circle_rounded : Icons.cancel_rounded,
                        color: _usernameAvailable ? const Color(0xFF2E8B7B) : const Color(0xFFB85C5C),
                        size: 20,
                      )
                    : null),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFE2DDD5)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFE2DDD5)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFF2E8B7B), width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
        if (_usernameErrorMessage.isNotEmpty && _usernameController.text.length >= 3)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 16),
            child: Row(
              children: [
                Icon(
                  _usernameAvailable ? Icons.check_circle_rounded : Icons.cancel_rounded,
                  size: 12,
                  color: _usernameAvailable ? const Color(0xFF2E8B7B) : const Color(0xFFB85C5C),
                ),
                const SizedBox(width: 4),
                Text(
                  _usernameErrorMessage,
                  style: TextStyle(
                    fontSize: 12,
                    color: _usernameAvailable ? const Color(0xFF2E8B7B) : const Color(0xFFB85C5C),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildSexDropdown() {
    return DropdownButtonFormField<String>(
      value: selectedSex,
      dropdownColor: const Color(0xFFF8F5EF),
      decoration: InputDecoration(
        labelText: 'Sex',
        labelStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
        prefixIcon: const Icon(Icons.wc_outlined, color: Color(0xFF2E8B7B), size: 20),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE2DDD5)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE2DDD5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF2E8B7B), width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      style: const TextStyle(color: Color(0xFF1A5F4A), fontSize: 15),
      items: sexOptions
          .map((sex) => DropdownMenuItem(
                value: sex,
                child: Text(sex, style: const TextStyle(color: Color(0xFF1A5F4A))),
              ))
          .toList(),
      onChanged: (val) => setState(() => selectedSex = val),
    );
  }

  Widget _buildBirthdayPicker() {
    return GestureDetector(
      onTap: _selectBirthday,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2DDD5)),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_month_outlined, color: Color(0xFF2E8B7B), size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Birthday',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    selectedBirthday == null
                        ? 'Select your birthday'
                        : DateFormat('MMMM dd, yyyy').format(selectedBirthday!),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: selectedBirthday == null ? Colors.grey.shade400 : const Color(0xFF1A5F4A),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  Widget _buildBarangayDropdown() {
    return DropdownButtonFormField<String>(
      value: selectedBarangay,
      dropdownColor: const Color(0xFFF8F5EF),
      isExpanded: true,
      menuMaxHeight: 300,
      decoration: InputDecoration(
        labelText: 'Barangay',
        labelStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
        prefixIcon: const Icon(Icons.location_on_outlined, color: Color(0xFF2E8B7B), size: 20),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE2DDD5)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE2DDD5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF2E8B7B), width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      style: const TextStyle(color: Color(0xFF1A5F4A), fontSize: 15),
      items: barangays
          .map((b) => DropdownMenuItem(
                value: b,
                child: Text(
                  b,
                  style: const TextStyle(color: Color(0xFF1A5F4A)),
                  overflow: TextOverflow.ellipsis,
                ),
              ))
          .toList(),
      onChanged: (val) {
        setState(() {
          selectedBarangay = val;
          if (val == "Others (Please specify)") {
            _otherBarangayController.text = "Barangay ";
          } else {
            _otherBarangayController.clear();
          }
        });
      },
    );
  }

  Widget _buildOtherBarangayField() {
    return TextField(
      controller: _otherBarangayController,
      style: const TextStyle(color: Color(0xFF1A5F4A), fontSize: 15),
      decoration: InputDecoration(
        labelText: 'Type your barangay',
        labelStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
        prefixIcon: const Icon(Icons.location_city_outlined, color: Color(0xFF2E8B7B), size: 20),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE2DDD5)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE2DDD5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF2E8B7B), width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      onChanged: (value) {
        if (!value.startsWith("Barangay ")) {
          _otherBarangayController.text = "Barangay ";
          _otherBarangayController.selection = TextSelection.fromPosition(
            TextPosition(offset: _otherBarangayController.text.length),
          );
        }
      },
    );
  }
}