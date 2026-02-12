  import 'package:flutter/material.dart';
  import 'package:lumasdang/screens/authPages/login.dart';

  class LoadingScreen extends StatefulWidget {
    const LoadingScreen({super.key});

    @override
    State<LoadingScreen> createState() => _LoadingScreenState();
  }

  class _LoadingScreenState extends State<LoadingScreen>
      with SingleTickerProviderStateMixin {

    late AnimationController _controller;

    @override
    void initState() {
      super.initState();

      /// Dot animation
      _controller = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 900),
      )..repeat();

      /// Navigate after 5 seconds
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => const LoginPage(),
            ),
          );
        }
      });
    }

    @override
    void dispose() {
      _controller.dispose();
      super.dispose();
    }

    Widget _buildDot(int index) {
      return AnimatedBuilder(
        animation: _controller,
        builder: (_, child) {
          double value = (_controller.value + index * 0.2) % 1;

          return Opacity(
            opacity: 0.3 + (value * 0.7),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: const CircleAvatar(
                radius: 5,
                backgroundColor: Colors.white,
              ),
            ),
          );
        },
      );
    }

    Widget _buildFooterDots() {
      return Padding(
        padding: const EdgeInsets.only(bottom: 40),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildDot(0),
            _buildDot(1),
            _buildDot(2),
          ],
        ),
      );
    }

    @override
    Widget build(BuildContext context) {
      return Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
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

                /// Push content to vertical center
                const Spacer(),

                /// LOGO (CENTER)
                Image.asset(
                  'assets/logo/logo.png',
                  width: 150,
                  height: 150,
                ),

                const Spacer(),

                /// FOOTER LOADING DOTS
                _buildFooterDots(),
              ],
            ),
          ),
        ),
      );
    }
  }
