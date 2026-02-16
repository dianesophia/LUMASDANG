import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lumasdang/screens/home.dart';
import 'package:intl/intl.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  // Updated controllers
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

  bool _isLoading = false;
  bool _checkingUsername = false;
  bool _usernameAvailable = true;
  String _usernameErrorMessage = '';
  bool _obscurePassword = true;

  // New fields
  String? selectedSex;
  DateTime? selectedBirthday;
  String? selectedBarangay;

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
    super.dispose();
  }

  // ---------- Capitalize Words ----------
  String capitalizeWords(String text) {
    return text
        .split(" ")
        .map((word) => word.isEmpty
            ? word
            : "${word[0].toUpperCase()}${word.substring(1).toLowerCase()}")
        .join(" ");
  }

  // ---------- Check username availability ----------
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

          if (doc.exists) {
            _usernameErrorMessage = 'Username is already taken';
          } else {
            _usernameErrorMessage = 'Username is available';
          }
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

  // ---------- Select Birthday ----------
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
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != selectedBirthday) {
      setState(() {
        selectedBirthday = picked;
      });
    }
  }

  // ---------- REGISTER ----------
  Future<void> _register() async {
    print('========================================');
    print('REGISTRATION STARTED');
    print('========================================');

    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final contact = _contactController.text.trim();
    final address = _addressController.text.trim();
    final password = _passwordController.text.trim();
    final confirm = _confirmController.text.trim();

    // Validation
    if (firstName.isEmpty) return _showSnack("Please enter your first name");
    if (firstName.length < 2) return _showSnack("First name must be at least 2 characters");
    
    if (lastName.isEmpty) return _showSnack("Please enter your last name");
    if (lastName.length < 2) return _showSnack("Last name must be at least 2 characters");

    if (username.isEmpty) return _showSnack("Please enter a username");
    if (username.length < 3) return _showSnack("Username must be at least 3 characters");
    if (!_usernameAvailable) return _showSnack("Username is already taken");

    if (email.isEmpty) return _showSnack("Please enter your email");
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      return _showSnack("Please enter a valid email address");
    }

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

      if (typed.length <= 9) {
        return _showSnack("Please type your barangay name");
      }

      final nameOnly = typed.substring(9).trim();

      if (nameOnly.isEmpty) {
        return _showSnack("Please type your barangay name");
      }

      finalBarangay = "Barangay ${capitalizeWords(nameOnly)}";
    } else {
      finalBarangay = selectedBarangay!;
    }

    setState(() => _isLoading = true);

    try {
      // Create Firebase Auth user
      print('Creating Firebase Auth user...');
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;
      print('Firebase Auth user created: ${user?.uid}');

      if (user != null) {
        final barangayId = finalBarangay.toLowerCase().replaceAll(" ", "_");
        final fullName = "$firstName $lastName";

        // Calculate age
        final age = DateTime.now().year - selectedBirthday!.year;

        print('Creating Firestore batch...');
        final batch = _firestore.batch();

        // Save user with all new fields
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

        // Username lookup
        batch.set(
          _firestore.collection('usernames').doc(username.toLowerCase()),
          {
            'email': email,
            'uid': user.uid,
            'createdAt': Timestamp.now(),
          },
        );

        // Add to barangay users
        batch.set(
          _firestore
              .collection('barangays')
              .doc(barangayId)
              .collection('users')
              .doc(user.uid),
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

        // Ensure barangay exists
        batch.set(
          _firestore.collection('barangays').doc(barangayId),
          {
            'name': finalBarangay,
            'barangayId': barangayId,
            'createdAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );

        print('Committing batch...');
        await batch.commit();
        print('Registration successful!');

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomePage()),
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      print('FirebaseAuthException: ${e.code}');

      String message = 'Registration failed';

      switch (e.code) {
        case 'weak-password':
          message = 'Password is too weak (minimum 6 characters)';
          break;
        case 'email-already-in-use':
          message = 'Email is already registered';
          break;
        case 'invalid-email':
          message = 'Invalid email address';
          break;
        default:
          message = e.message ?? 'Registration failed';
      }

      _showSnack(message);
    } catch (e) {
      print('Error: $e');
      _showSnack("Registration failed: ${e.toString()}");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ---------- UI ----------
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
                  const SizedBox(height: 40),

                  // First Name
                  _buildField(
                      controller: _firstNameController,
                      hint: 'First Name',
                      icon: Icons.person_outline),

                  const SizedBox(height: 20),

                  // Last Name
                  _buildField(
                      controller: _lastNameController,
                      hint: 'Last Name',
                      icon: Icons.person_outline),

                  const SizedBox(height: 20),

                  // Username with validation
                  _buildUsernameField(),

                  const SizedBox(height: 20),

                  // Email
                  _buildField(
                      controller: _emailController,
                      hint: 'Email',
                      icon: Icons.email_outlined),

                  const SizedBox(height: 20),

                  // Contact Number
                  _buildField(
                      controller: _contactController,
                      hint: 'Contact Number',
                      icon: Icons.phone_outlined),

                  const SizedBox(height: 20),

                  // Sex Dropdown
                  _buildSexDropdown(),

                  const SizedBox(height: 20),

                  // Birthday Picker
                  _buildBirthdayPicker(),

                  const SizedBox(height: 20),

                  // Address
                  _buildField(
                      controller: _addressController,
                      hint: 'Complete Address',
                      icon: Icons.home_outlined),

                  const SizedBox(height: 20),

                  // Barangay Dropdown
                  _buildBarangayDropdown(),

                  if (selectedBarangay == "Others (Please specify)") ...[
                    const SizedBox(height: 20),
                    _buildOtherBarangayField(),
                  ],

                  const SizedBox(height: 20),

                  // Password
                  _buildField(
                      controller: _passwordController,
                      hint: 'Password',
                      icon: Icons.lock_outline,
                      isPassword: true),

                  const SizedBox(height: 20),

                  // Confirm Password
                  _buildField(
                      controller: _confirmController,
                      hint: 'Confirm Password',
                      icon: Icons.lock_outline,
                      isPassword: true),

                  const SizedBox(height: 40),

                  // Register Button
                  SizedBox(
                    width: 200,
                    child: ElevatedButton(
                      onPressed: (_isLoading || !_usernameAvailable)
                          ? null
                          : _register,
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
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              "Register",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Already have an account? Log in',
                      style: TextStyle(color: Colors.white, fontSize: 14),
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

  // ---------- NORMAL TEXT FIELD ----------
 Widget _buildField({
  required TextEditingController controller,
  required String hint,
  required IconData icon,
  bool isPassword = false,
}) {
  return Container(
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: Colors.white70)),
    ),
    child: TextField(
      controller: controller,
      obscureText: isPassword ? _obscurePassword : false,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white70),
        border: InputBorder.none,
        prefixIcon: Icon(icon, color: Colors.white70),
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        // Eye icon for password fields
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  color: Colors.white70,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              )
            : null,
      ),
    ),
  );
}

  // ---------- USERNAME FIELD WITH VALIDATION ----------
  Widget _buildUsernameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.white70)),
          ),
          child: TextField(
            controller: _usernameController,
            style: const TextStyle(color: Colors.white),
            onChanged: (value) {
              Future.delayed(const Duration(milliseconds: 500), () {
                if (_usernameController.text == value) {
                  _checkUsernameAvailability(value.trim());
                }
              });
            },
            decoration: InputDecoration(
              hintText: 'Username',
              hintStyle: const TextStyle(color: Colors.white70),
              border: InputBorder.none,
              prefixIcon:
                  const Icon(Icons.alternate_email, color: Colors.white70),
              suffixIcon: _checkingUsername
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: Padding(
                        padding: EdgeInsets.all(12.0),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                    )
                  : (_usernameController.text.length >= 3
                      ? Icon(
                          _usernameAvailable
                              ? Icons.check_circle
                              : Icons.cancel,
                          color: _usernameAvailable
                              ? Colors.greenAccent
                              : Colors.redAccent,
                        )
                      : null),
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        if (_usernameErrorMessage.isNotEmpty &&
            _usernameController.text.length >= 3)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 40),
            child: Text(
              _usernameErrorMessage,
              style: TextStyle(
                color: _usernameAvailable
                    ? Colors.greenAccent
                    : Colors.redAccent,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }

  // ---------- SEX DROPDOWN ----------
  Widget _buildSexDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white70),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonFormField<String>(
        value: selectedSex,
        dropdownColor: const Color(0xFF2E8B7B),
        decoration: const InputDecoration(
          border: InputBorder.none,
          prefixIcon: Icon(Icons.wc_outlined, color: Colors.white70),
        ),
        hint: const Text(
          "Select Sex",
          style: TextStyle(color: Colors.white70),
        ),
        style: const TextStyle(color: Colors.white),
        items: sexOptions.map((sex) {
          return DropdownMenuItem(
            value: sex,
            child: Text(
              sex,
              style: const TextStyle(color: Colors.white),
            ),
          );
        }).toList(),
        onChanged: (val) {
          setState(() {
            selectedSex = val;
          });
        },
      ),
    );
  }

  // ---------- BIRTHDAY PICKER ----------
  Widget _buildBirthdayPicker() {
    return GestureDetector(
      onTap: _selectBirthday,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white70),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_outlined, color: Colors.white70),
            const SizedBox(width: 12),
            Text(
              selectedBirthday == null
                  ? "Select Birthday"
                  : DateFormat('MMMM dd, yyyy').format(selectedBirthday!),
              style: TextStyle(
                color: selectedBirthday == null
                    ? Colors.white70
                    : Colors.white,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------- BARANGAY DROPDOWN ----------
  Widget _buildBarangayDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white70),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonFormField<String>(
        value: selectedBarangay,
        dropdownColor: const Color(0xFF2E8B7B),
        decoration: const InputDecoration(
          border: InputBorder.none,
          prefixIcon:
              Icon(Icons.location_on_outlined, color: Colors.white70),
        ),
        hint: const Text(
          "Select Barangay",
          style: TextStyle(color: Colors.white70),
        ),
        style: const TextStyle(color: Colors.white),
        items: barangays.map((b) {
          return DropdownMenuItem(
            value: b,
            child: Text(
              b,
              style: const TextStyle(color: Colors.white),
            ),
          );
        }).toList(),
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
      ),
    );
  }

  // ---------- OTHER BARANGAY FIELD ----------
  Widget _buildOtherBarangayField() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white70)),
      ),
      child: TextField(
        controller: _otherBarangayController,
        style: const TextStyle(color: Colors.white),
        decoration: const InputDecoration(
          hintText: 'Type your barangay name',
          hintStyle: TextStyle(color: Colors.white70),
          border: InputBorder.none,
          prefixIcon:
              Icon(Icons.location_city_outlined, color: Colors.white70),
          contentPadding: EdgeInsets.symmetric(vertical: 12),
        ),
        onChanged: (value) {
          if (!value.startsWith("Barangay ")) {
            _otherBarangayController.text = "Barangay ";
            _otherBarangayController.selection = TextSelection.fromPosition(
              TextPosition(offset: _otherBarangayController.text.length),
            );
          }
        },
      ),
    );
  }
}