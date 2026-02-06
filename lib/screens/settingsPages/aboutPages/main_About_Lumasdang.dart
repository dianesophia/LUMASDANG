// lib/screens/settingsPages/aboutPages/main_about_lumasdang.dart
import 'package:flutter/material.dart';
import 'package:lumasdang/screens/settingsPages/aboutPages/code_of_conduct.dart';
import 'package:lumasdang/screens/settingsPages/aboutPages/privacy_policy.dart';
import 'package:lumasdang/screens/settingsPages/aboutPages/terms_of_use.dart';
import 'about_lumasdang.dart';

class MainAboutLumasdang extends StatelessWidget {
  const MainAboutLumasdang({super.key});

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
              // Header: Back Button + Title

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
                              "About Lumasdang",
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

              // Menu cards
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      _buildMenuItem(context, "About Lumasdang"),
                      const SizedBox(height: 10),
                      _buildMenuItem(context, "Terms of Use"),
                      const SizedBox(height: 10),
                      _buildMenuItem(context, "Code of Conduct"),
                      const SizedBox(height: 10),
                      _buildMenuItem(context, "Privacy Policy"),
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

  Widget _buildMenuItem(BuildContext context, String title) {
    return InkWell(
      onTap: () {
        Widget page;
        switch (title) {
          case "About Lumasdang":
            page = const AboutLumasdang();
            break;
          case "Terms of Use":
            page = const TermsOfUse();
            break;
          case "Code of Conduct":
            page = const CodeOfConduct();
            break;
          case "Privacy Policy":
            page = const PrivacyPolicy(); 
            break;
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
        child: Text(
          title,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  // Helper function for slide + fade transition
  PageRouteBuilder _slideFadeRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.0, 1.0);
        const end = Offset.zero;
        const curve = Curves.ease;

        final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
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

// Placeholder screen for other menu items
class PlaceholderScreen extends StatelessWidget {
  final String title;
  const PlaceholderScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text("This is the $title page")),
    );
  }
}
