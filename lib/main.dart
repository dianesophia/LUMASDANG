import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

// Screens
import 'screens/login.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}




class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lumasdang',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2E8B7B)),
        useMaterial3: true,
      ),
      home: const LoginPage(),
    );
  }
}

// ==================== SPLASH/LOADING SCREEN ====================
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _dotsController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Dots animation controller
    _dotsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    // Fade animation controller
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );

    _fadeController.forward();

    // Navigate to login screen after delay
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const LoginPage(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 500),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _dotsController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF4A9B8C),
              Color(0xFF3D998A),
              Color(0xFF4DAF8B),
              Color(0xFF5CB88D),
            ],
          ),
        ),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(flex: 2),
                  // Logo Container
                  Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF8E1),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Background gradient for logo
                          Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color(0xFFFFFDE7),
                                  Color(0xFFFFF8E1),
                                ],
                              ),
                            ),
                          ),
                          // Logo content - silhouettes with arrow
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      // Adult silhouette (left)
                                      Positioned(
                                        left: 20,
                                        child: Icon(
                                          Icons.person,
                                          size: 70,
                                          color: const Color(0xFF6B8EAE),
                                        ),
                                      ),
                                      // Child silhouette (right)
                                      Positioned(
                                        right: 20,
                                        bottom: 10,
                                        child: Icon(
                                          Icons.child_care,
                                          size: 50,
                                          color: const Color(0xFFE57373),
                                        ),
                                      ),
                                      // Growth arrow
                                      Positioned(
                                        top: 10,
                                        child: Transform.rotate(
                                          angle: -0.5,
                                          child: Icon(
                                            Icons.trending_up,
                                            size: 40,
                                            color: const Color(0xFF4CAF50),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Logo text
                                const Text(
                                  'LUMASDANG',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF8B7355),
                                    letterSpacing: 2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 60),
                  // Loading dots animation
                  AnimatedBuilder(
                    animation: _dotsController,
                    builder: (context, child) {
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(4, (index) {
                          final delay = index * 0.2;
                          final animValue =
                              ((_dotsController.value + delay) % 1.0);
                          final scale = animValue < 0.5
                              ? 1.0 + (animValue * 0.6)
                              : 1.0 + ((1.0 - animValue) * 0.6);
                          final opacity = animValue < 0.5
                              ? 0.4 + (animValue * 1.2)
                              : 0.4 + ((1.0 - animValue) * 1.2);

                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 6),
                            child: Transform.scale(
                              scale: scale,
                              child: Container(
                                width: 14,
                                height: 14,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color.fromRGBO(
                                    45,
                                    55,
                                    60,
                                    opacity.clamp(0.0, 1.0),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      );
                    },
                  ),
                  const Spacer(flex: 2),
                  // Loading text
                  const Text(
                    'Loading',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Login screen moved to: lib/screens/login.dart
// Home screen moved to: lib/screens/home.dart
