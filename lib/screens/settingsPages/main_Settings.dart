// lib/screens/settings/mainSettings.dart
/*import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Auth
import 'package:lumasdang/screens/authPages/login.dart';

// Settings Pages
import 'package:lumasdang/screens/settingsPages/aboutPages/main_About_Lumasdang.dart';
import 'package:lumasdang/screens/settingsPages/change_user_name.dart';
import 'package:lumasdang/screens/settingsPages/clear_cache.dart';
import 'package:lumasdang/screens/settingsPages/edit_profile.dart';
import 'package:lumasdang/screens/settingsPages/customize_appearance.dart';
import 'package:lumasdang/screens/settingsPages/securityPages/main_security.dart';

// Services
import '../../services/local_db_service.dart';
import '../../services/firestore_service.dart';

/// ✅ ENUM FOR SETTINGS ROUTES
enum SettingsOption {
  changeUsername,
  editProfile,
  security,
  customizeAppearance,
  clearCache,
  about,
}

class MainSettings extends StatelessWidget {
  const MainSettings({super.key});

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
              /// HEADER
              Padding(
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
                              "Settings",
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 48),
                      ],
                    ),
                    Container(
                      height: 1.5,
                      width: double.infinity,
                      color: Colors.white.withOpacity(0.3),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              /// SETTINGS LIST
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _settingsTile(
                      icon: Icons.person_outline,
                      text: "Change User Name",
                      option: SettingsOption.changeUsername,
                      context: context,
                    ),

                    _settingsTile(
                      icon: Icons.edit,
                      text: "Edit Profile",
                      option: SettingsOption.editProfile,
                      context: context,
                    ),

                    _settingsTile(
                      icon: Icons.lock_outline,
                      text: "Security",
                      option: SettingsOption.security,
                      context: context,
                    ),

                    _settingsTile(
                      icon: Icons.brush_outlined,
                      text: "Customize Appearance",
                      option: SettingsOption.customizeAppearance,
                      context: context,
                    ),

                    _settingsTile(
                      icon: Icons.delete_outline,
                      text: "Clear Cache",
                      option: SettingsOption.clearCache,
                      context: context,
                    ),

                    _settingsTile(
                      icon: Icons.info_outline,
                      text: "About Lumasdang",
                      option: SettingsOption.about,
                      context: context,
                    ),

                    const SizedBox(height: 30),

                    /// LOG OUT
                    _bottomButton(
                      text: "Log Out",
                      onTap: () async {
                        await FirebaseAuth.instance.signOut();

                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginPage()),
                        );
                      },
                    ),

                    const SizedBox(height: 10),

                    /// DELETE ACCOUNT
                    _bottomButton(
                      text: "Delete Account",
                      onTap: () => _showDeleteConfirmation(context),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// ✅ SETTINGS TILE
  Widget _settingsTile({
    required IconData icon,
    required String text,
    required SettingsOption option,
    required BuildContext context,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      color: Colors.white.withOpacity(0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: Colors.black),
        title: Text(text,
            style: const TextStyle(
                color: Colors.black, fontWeight: FontWeight.w600)),
        onTap: () => _handleNavigation(context, option),
      ),
    );
  }

  /// ✅ SWITCH CASE NAVIGATION
  void _handleNavigation(BuildContext context, SettingsOption option) {
    switch (option) {
      case SettingsOption.changeUsername:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ChangeUserName()),
        );
        break;

      case SettingsOption.editProfile:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const EditProfile()),
        );
        break;

      case SettingsOption.security:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MainSecurity()),
        );
        break;

      case SettingsOption.customizeAppearance:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CustomizeAppearance()),
        );
        break;

      case SettingsOption.clearCache:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ClearCache()),
        );
        break;

      case SettingsOption.about:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MainAboutLumasdang()),
        );
        break;
    }
  }

  /// BOTTOM BUTTON
  Widget _bottomButton({
    required String text,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white70,
          borderRadius: BorderRadius.circular(25),
        ),
        alignment: Alignment.center,
        child: Text(text,
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 16)),
      ),
    );
  }

  /// DELETE CONFIRMATION
  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Account"),
        content: const Text(
            "Are you sure you want to delete your account?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent),
            onPressed: () async {
              Navigator.pop(ctx);
              await _deleteAccount(context);
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAccount(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await LocalDbService.instance.softDeleteByUserId(user.uid);
    await FirestoreService().softDeleteUser(user.uid);
    await FirebaseAuth.instance.signOut();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }
}*/

// lib/screens/settings/mainSettings.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Auth
import 'package:lumasdang/screens/authPages/login.dart';

// Settings Pages
import 'package:lumasdang/screens/settingsPages/aboutPages/main_About_Lumasdang.dart';
import 'package:lumasdang/screens/settingsPages/change_user_name.dart';
import 'package:lumasdang/screens/settingsPages/clear_cache.dart';
import 'package:lumasdang/screens/settingsPages/edit_profile.dart';
import 'package:lumasdang/screens/settingsPages/customize_appearance.dart';
import 'package:lumasdang/screens/settingsPages/securityPages/main_security.dart';

// Services
import '../../services/local_db_service.dart';
import '../../services/firestore_service.dart';

/// ✅ ENUM FOR SETTINGS ROUTES
enum SettingsOption {
  changeUsername,
  editProfile,
  security,
  customizeAppearance,
  clearCache,
  about,
}

class MainSettings extends StatelessWidget {
  const MainSettings({super.key});

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
              /// HEADER
              Padding(
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
                              "Settings",
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 48),
                      ],
                    ),
                    Container(
                      height: 1.5,
                      width: double.infinity,
                      color: Colors.white.withOpacity(0.3),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              /// SETTINGS LIST
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    // 🔍 DEBUG BUTTON - TEMPORARY - Remove after fixing
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red, width: 2),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.bug_report, color: Colors.red.shade700),
                              const SizedBox(width: 8),
                              Text(
                                'Debug Tools',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red.shade700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'If you\'re seeing permission errors, click below to check your account setup',
                            style: TextStyle(fontSize: 12),
                          ),
                          const SizedBox(height: 12),
                          const Center(child: DebugUserButton()),
                        ],
                      ),
                    ),
                    
                    _settingsTile(
                      icon: Icons.person_outline,
                      text: "Change User Name",
                      option: SettingsOption.changeUsername,
                      context: context,
                    ),

                    _settingsTile(
                      icon: Icons.edit,
                      text: "Edit Profile",
                      option: SettingsOption.editProfile,
                      context: context,
                    ),

                    _settingsTile(
                      icon: Icons.lock_outline,
                      text: "Security",
                      option: SettingsOption.security,
                      context: context,
                    ),

                    _settingsTile(
                      icon: Icons.brush_outlined,
                      text: "Customize Appearance",
                      option: SettingsOption.customizeAppearance,
                      context: context,
                    ),

                    _settingsTile(
                      icon: Icons.delete_outline,
                      text: "Clear Cache",
                      option: SettingsOption.clearCache,
                      context: context,
                    ),

                    _settingsTile(
                      icon: Icons.info_outline,
                      text: "About Lumasdang",
                      option: SettingsOption.about,
                      context: context,
                    ),

                    const SizedBox(height: 30),

                    /// LOG OUT
                    _bottomButton(
                      text: "Log Out",
                      onTap: () async {
                        await FirebaseAuth.instance.signOut();

                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginPage()),
                        );
                      },
                    ),

                    const SizedBox(height: 10),

                    /// DELETE ACCOUNT
                    _bottomButton(
                      text: "Delete Account",
                      onTap: () => _showDeleteConfirmation(context),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// ✅ SETTINGS TILE
  Widget _settingsTile({
    required IconData icon,
    required String text,
    required SettingsOption option,
    required BuildContext context,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      color: Colors.white.withOpacity(0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: Colors.black),
        title: Text(text,
            style: const TextStyle(
                color: Colors.black, fontWeight: FontWeight.w600)),
        onTap: () => _handleNavigation(context, option),
      ),
    );
  }

  /// ✅ SWITCH CASE NAVIGATION
  void _handleNavigation(BuildContext context, SettingsOption option) {
    switch (option) {
      case SettingsOption.changeUsername:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ChangeUserName()),
        );
        break;

      case SettingsOption.editProfile:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const EditProfile()),
        );
        break;

      case SettingsOption.security:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MainSecurity()),
        );
        break;

      case SettingsOption.customizeAppearance:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CustomizeAppearance()),
        );
        break;

      case SettingsOption.clearCache:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ClearCache()),
        );
        break;

      case SettingsOption.about:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MainAboutLumasdang()),
        );
        break;
    }
  }

  /// BOTTOM BUTTON
  Widget _bottomButton({
    required String text,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white70,
          borderRadius: BorderRadius.circular(25),
        ),
        alignment: Alignment.center,
        child: Text(text,
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 16)),
      ),
    );
  }

  /// DELETE CONFIRMATION
  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Account"),
        content: const Text(
            "Are you sure you want to delete your account?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent),
            onPressed: () async {
              Navigator.pop(ctx);
              await _deleteAccount(context);
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAccount(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await LocalDbService.instance.softDeleteByUserId(user.uid);
    await FirestoreService().softDeleteUser(user.uid);
    await FirebaseAuth.instance.signOut();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }
}

// ============================================================================
// 🔍 DEBUG USER BUTTON - Add this at the bottom of the file
// ============================================================================

class DebugUserButton extends StatelessWidget {
  const DebugUserButton({super.key});

  Future<void> _debugUser(BuildContext context) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      
      if (user == null) {
        _showDialog(context, '❌ ERROR', 'No user logged in');
        return;
      }

      print('\n═══════════════════════════════════════');
      print('🔍 DEBUG USER INFO');
      print('═══════════════════════════════════════');
      print('User UID: ${user.uid}');
      print('User Email: ${user.email}');
      
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) {
        _showDialog(context, '❌ ERROR', 'User document does not exist!\n\nUID: ${user.uid}');
        return;
      }

      final userData = userDoc.data()!;
      print('\n📄 User Document Fields:');
      userData.forEach((key, value) {
        print('  $key: $value');
      });

      final hasBarangayId = userData.containsKey('barangayId');
      final barangayId = userData['barangayId'];
      
      print('\n🔍 Critical Checks:');
      print('  Has barangayId field: $hasBarangayId');
      print('  barangayId value: $barangayId');
      print('  barangayId is null: ${barangayId == null}');
      print('  barangayId is empty: ${barangayId == ""}');

      String status = '';
      String message = '';

      if (!hasBarangayId) {
        status = '❌ PROBLEM FOUND';
        message = 'User document is MISSING the "barangayId" field!\n\n'
                  'Fix: Go to Firebase Console → Firestore → users → ${user.uid}\n'
                  'Add field: barangayId = "barangay_talisay"';
      } else if (barangayId == null || barangayId == '') {
        status = '❌ PROBLEM FOUND';
        message = 'barangayId field is NULL or EMPTY!\n\n'
                  'Current value: ${barangayId == null ? "null" : "empty string"}\n\n'
                  'Fix: Update in Firebase Console';
      } else {
        status = '✅ User Document OK';
        message = 'User has valid barangayId: $barangayId\n\n';
        
        print('\n🔍 Checking barangay document...');
        final barangayDoc = await FirebaseFirestore.instance
            .collection('barangays')
            .doc(barangayId)
            .get();

        if (!barangayDoc.exists) {
          status = '⚠️ BARANGAY MISSING';
          message += 'BUT: Barangay document does NOT exist!\n\n'
                     'barangays/$barangayId\n\n'
                     'Fix: Create in Firebase Console';
        } else {
          message += 'Barangay document exists: ✅\n\n';
          
          print('\n🔍 Testing patient access...');
          try {
            final patientsSnapshot = await FirebaseFirestore.instance
                .collection('barangays')
                .doc(barangayId)
                .collection('patients')
                .limit(1)
                .get();

            status = '✅ ALL CHECKS PASSED';
            message += 'Can read patients: ✅\n'
                       'Found ${patientsSnapshot.docs.length} patients\n\n'
                       'Everything looks good!';
          } catch (e) {
            status = '❌ PERMISSION DENIED';
            message += 'CANNOT read patients!\n\n'
                       'Error: $e\n\n'
                       'Fix: Update Firestore rules';
          }
        }
      }

      print('\n═══════════════════════════════════════');
      print('Result: $status');
      print('═══════════════════════════════════════\n');

      _showDialog(context, status, message);

    } catch (e) {
      print('❌ Debug error: $e');
      _showDialog(context, '❌ ERROR', 'Debug failed:\n\n$e');
    }
  }

  void _showDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Text(message),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () => _debugUser(context),
      icon: const Icon(Icons.bug_report),
      label: const Text('🔍 Debug My Account'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
    );
  }
}