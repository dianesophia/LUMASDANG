// lib/screens/settings/mainSettings.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lumasdang/screens/login.dart';// ✅ IMPORT ADDED
import 'package:lumasdang/screens/settingsPages/aboutPages/mainAboutLumasdang.dart';
import '../../services/local_db_service.dart';
import '../../services/firestore_service.dart';

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
              // AppBar replacement
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16),
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
              ),

              const SizedBox(height: 20),

              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _settingsTile(icon: Icons.person_outline, text: "Change User Name", onTap: () {}),
                    _settingsTile(icon: Icons.edit, text: "Edit Profile", onTap: () {}),
                    _settingsTile(icon: Icons.lock_outline, text: "Security", onTap: () {}),
                    _settingsTile(icon: Icons.brush_outlined, text: "Customize Appearance", onTap: () {}),
                    _settingsTile(icon: Icons.delete_outline, text: "Clear Cache", onTap: () {}),

                    // ✅ ABOUT LUMASDANG NAVIGATION
                    _settingsTile(
                      icon: Icons.info_outline,
                      text: "About Lumasdang",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const MainAboutLumasdang(),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 30),

                    // Log Out Button
                    _bottomButton(
                      text: "Log Out",
                      color: Colors.white70,
                      textColor: Colors.black,
                      onTap: () async {
                        try {
                          await FirebaseAuth.instance.signOut();
                          Navigator.pushReplacement(
                              context, MaterialPageRoute(builder: (_) => const LoginPage()));
                        } catch (e) {
                          ScaffoldMessenger.of(context)
                              .showSnackBar(SnackBar(content: Text("Failed to log out: $e")));
                        }
                      },
                    ),

                    const SizedBox(height: 10),

                    // Delete Account Button
                    _bottomButton(
                      text: "Delete Account",
                      color: Colors.white70,
                      textColor: Colors.black,
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

  Widget _settingsTile({required IconData icon, required String text, required VoidCallback onTap}) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      color: Colors.white.withOpacity(0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: Colors.black),
        title: Text(text,
            style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w600)),
        onTap: onTap,
      ),
    );
  }

  Widget _bottomButton({
    required String text,
    required Color color,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(25)),
        alignment: Alignment.center,
        child: Text(text,
            style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16)),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Account"),
        content: const Text(
            "Are you sure you want to delete your account? This action will mark your account as deleted."),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await _deleteAccount(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAccount(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await LocalDbService.instance.softDeleteByUserId(user.uid);
      await FirestoreService().softDeleteUser(user.uid);
      await FirebaseAuth.instance.signOut();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Your account has been deleted.")),
      );

      Future.delayed(const Duration(seconds: 1), () {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginPage()));
      });
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Failed to delete account: $e")));
    }
  }
}
