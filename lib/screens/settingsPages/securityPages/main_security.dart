// lib/screens/settingsPages/security/main_security.dart

import 'package:flutter/material.dart';

// Import your pages
import 'change_password.dart';


class MainSecurity extends StatelessWidget {
  const MainSecurity({super.key});

  final Color buttonColor = const Color.fromRGBO(255, 255, 255, 0.3);
  final Color textColor = Colors.black;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
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
            crossAxisAlignment: CrossAxisAlignment.start,
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
                              "Security",
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

                    /// Divider Line
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

              /// MENU ITEMS
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      _buildMenuItem(
                        context,
                        "Change Password",
                        Icons.lock_open, // ✅ padlock open icon
                      ),

                      const SizedBox(height: 10),

                      _buildMenuItem(
                        context,
                        "Face ID / Touch ID",
                        Icons.face,
                      ),

                      const SizedBox(height: 10),

                      _buildMenuItem(
                        context,
                        "Fingerprint Authentication",
                        Icons.fingerprint,
                      ),
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

  /// MENU ITEM BUILDER
  Widget _buildMenuItem(BuildContext context, String title, IconData icon) {
    return InkWell(
      onTap: () {
        Widget page;

        switch (title) {
          case "Change Password":
            page = const ChangePassword();
            break;

          /*case "Face ID / Touch ID":
            page = const FaceIDTouchID();
            break;

          case "Fingerprint Authentication":
            page = const FingerprintAuthentication();
            break;*/

          default:
            page = PlaceholderScreen(title: title);
        }

        Navigator.of(context).push(_slideFadeRoute(page));
      },

      borderRadius: BorderRadius.circular(8),

      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
        decoration: BoxDecoration(
          color: buttonColor,
          borderRadius: BorderRadius.circular(8),
        ),

        child: Row(
          children: [

            /// ICON
            Icon(icon, color: textColor),

            const SizedBox(width: 12),

            /// TITLE
            Text(
              title,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// SLIDE + FADE ANIMATION
  PageRouteBuilder _slideFadeRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (_, __, ___) => page,

      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.0, 1.0);
        const end = Offset.zero;

        final tween =
            Tween(begin: begin, end: end).chain(CurveTween(curve: Curves.ease));

        final fadeTween = Tween<double>(begin: 0.0, end: 1.0);

        return SlideTransition(
          position: animation.drive(tween),
          child: FadeTransition(
            opacity: animation.drive(fadeTween),
            child: child,
          ),
        );
      },
    );
  }
}

/// PLACEHOLDER SCREEN
class PlaceholderScreen extends StatelessWidget {
  final String title;

  const PlaceholderScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Text("This is the $title page"),
      ),
    );
  }
}
