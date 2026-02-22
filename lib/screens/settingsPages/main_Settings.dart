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
              /// ── HEADER ──────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 12, 8, 0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        // Back button with frosted pill
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
                              "Settings",
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                        ),
                        // Placeholder to balance header
                        const SizedBox(width: 44),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Subtle divider
                    Container(
                      height: 1,
                      width: double.infinity,
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

              const SizedBox(height: 24),

              /// ── SETTINGS LIST ────────────────────────────────────────────
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    // ── Section: Account ──────────────────────────────────
                    _sectionLabel("Account"),
                    const SizedBox(height: 8),

                    _settingsGroup(
                      context: context,
                      tiles: [
                        _TileData(
                          icon: Icons.person_outline_rounded,
                          text: "Change Username",
                          option: SettingsOption.changeUsername,
                        ),
                        _TileData(
                          icon: Icons.edit_outlined,
                          text: "Edit Profile",
                          option: SettingsOption.editProfile,
                        ),
                        _TileData(
                          icon: Icons.lock_outline_rounded,
                          text: "Security",
                          option: SettingsOption.security,
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // ── Section: Preferences ─────────────────────────────
                    _sectionLabel("Preferences"),
                    const SizedBox(height: 8),

                    _settingsGroup(
                      context: context,
                      tiles: [
                        _TileData(
                          icon: Icons.palette_outlined,
                          text: "Customize Appearance",
                          option: SettingsOption.customizeAppearance,
                        ),
                        _TileData(
                          icon: Icons.delete_sweep_outlined,
                          text: "Clear Cache",
                          option: SettingsOption.clearCache,
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // ── Section: Info ────────────────────────────────────
                    _sectionLabel("Info"),
                    const SizedBox(height: 8),

                    _settingsGroup(
                      context: context,
                      tiles: [
                        _TileData(
                          icon: Icons.info_outline_rounded,
                          text: "About Lµmasdαng",
                          option: SettingsOption.about,
                        ),
                      ],
                    ),

                    const SizedBox(height: 36),

                    /// ── LOG OUT BUTTON ───────────────────────────────────
                    _actionButton(
                      text: "Log Out",
                      icon: Icons.logout_rounded,
                      color: Colors.white,
                      textColor: const Color(0xFF2E8B7B),
                      onTap: () async {
                        await FirebaseAuth.instance.signOut();
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginPage()),
                        );
                      },
                    ),

                    const SizedBox(height: 12),

                    /// ── DELETE ACCOUNT BUTTON ────────────────────────────
                    _actionButton(
                      text: "Delete Account",
                      icon: Icons.delete_forever_rounded,
                      color: Colors.white.withOpacity(0.15),
                      textColor: Colors.white,
                      borderColor: Colors.white.withOpacity(0.4),
                      onTap: () => _showDeleteConfirmation(context),
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── SECTION LABEL ──────────────────────────────────────────────────────────
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

  // ── GROUPED TILES CARD ─────────────────────────────────────────────────────
  Widget _settingsGroup({
    required BuildContext context,
    required List<_TileData> tiles,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.28),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: List.generate(tiles.length, (index) {
            final tile = tiles[index];
            final isLast = index == tiles.length - 1;
            return Column(
              children: [
                _settingsTile(
                  icon: tile.icon,
                  text: tile.text,
                  option: tile.option,
                  context: context,
                ),
                if (!isLast)
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: Colors.white.withOpacity(0.15),
                    indent: 56,
                    endIndent: 0,
                  ),
              ],
            );
          }),
        ),
      ),
    );
  }

  // ── SINGLE SETTINGS TILE ───────────────────────────────────────────────────
  Widget _settingsTile({
    required IconData icon,
    required String text,
    required SettingsOption option,
    required BuildContext context,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _handleNavigation(context, option),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              // Icon container
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 14),
              // Label
              Expanded(
                child: Text(
                  text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              // Chevron
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.white.withOpacity(0.55),
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── NAVIGATION ─────────────────────────────────────────────────────────────
  void _handleNavigation(BuildContext context, SettingsOption option) {
    switch (option) {
      case SettingsOption.changeUsername:
        Navigator.push(context, MaterialPageRoute(builder: (_) => const ChangeUserName()));
        break;
      case SettingsOption.editProfile:
        Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfile()));
        break;
      case SettingsOption.security:
        Navigator.push(context, MaterialPageRoute(builder: (_) => const MainSecurity()));
        break;
      case SettingsOption.customizeAppearance:
        Navigator.push(context, MaterialPageRoute(builder: (_) => const CustomizeAppearance()));
        break;
      case SettingsOption.clearCache:
        Navigator.push(context, MaterialPageRoute(builder: (_) => const ClearCache()));
        break;
      case SettingsOption.about:
        Navigator.push(context, MaterialPageRoute(builder: (_) => const MainAboutLumasdang()));
        break;
    }
  }

  // ── ACTION BUTTON (Log Out / Delete) ───────────────────────────────────────
  Widget _actionButton({
    required String text,
    required IconData icon,
    required Color color,
    required Color textColor,
    Color? borderColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          border: borderColor != null
              ? Border.all(color: borderColor, width: 1)
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: textColor, size: 20),
            const SizedBox(width: 8),
            Text(
              text,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── DELETE CONFIRMATION DIALOG ─────────────────────────────────────────────
  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "Delete Account",
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: const Text(
          "This action is permanent and cannot be undone. Are you sure you want to delete your account?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
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

// ── HELPER DATA CLASS ──────────────────────────────────────────────────────
class _TileData {
  final IconData icon;
  final String text;
  final SettingsOption option;
  const _TileData({
    required this.icon,
    required this.text,
    required this.option,
  });
}

// ============================================================================
// 🔍 DEBUG USER BUTTON
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

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) {
        _showDialog(context, '❌ ERROR', 'User document does not exist!\n\nUID: ${user.uid}');
        return;
      }

      final userData = userDoc.data()!;
      final hasBarangayId = userData.containsKey('barangayId');
      final barangayId = userData['barangayId'];

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

        final barangayDoc = await FirebaseFirestore.instance
            .collection('barangays')
            .doc(barangayId)
            .get();

        if (!barangayDoc.exists) {
          status = '⚠️ BARANGAY MISSING';
          message += 'BUT: Barangay document does NOT exist!\n\nbarangays/$barangayId\n\nFix: Create in Firebase Console';
        } else {
          message += 'Barangay document exists: ✅\n\n';
          try {
            final patientsSnapshot = await FirebaseFirestore.instance
                .collection('barangays')
                .doc(barangayId)
                .collection('patients')
                .limit(1)
                .get();

            status = '✅ ALL CHECKS PASSED';
            message += 'Can read patients: ✅\nFound ${patientsSnapshot.docs.length} patients\n\nEverything looks good!';
          } catch (e) {
            status = '❌ PERMISSION DENIED';
            message += 'CANNOT read patients!\n\nError: $e\n\nFix: Update Firestore rules';
          }
        }
      }

      _showDialog(context, status, message);
    } catch (e) {
      _showDialog(context, '❌ ERROR', 'Debug failed:\n\n$e');
    }
  }

  void _showDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title),
        content: SingleChildScrollView(child: Text(message)),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}