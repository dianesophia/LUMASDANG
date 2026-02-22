import 'package:flutter/material.dart';

/// A reusable bottom tab bar with the Lumasdang green gradient.
///
/// Basic usage — drop-in replacement for [BottomNavigationBar]:
///
/// ```dart
/// Scaffold(
///   bottomNavigationBar: AppBottomNavBar(controller: _tabController),
///   body: ...,
/// );
/// ```
///
/// Custom tabs:
///
/// ```dart
/// AppBottomNavBar(
///   controller: _tabController,
///   tabs: const [
///     Tab(icon: Icon(Icons.home_outlined, size: 22), text: 'Home'),
///     Tab(icon: Icon(Icons.info_outline,  size: 22), text: 'About'),
///   ],
/// )
/// ```
class AppBottomNavBar extends StatelessWidget {
  final TabController controller;

  /// Override the default Home / Patients / Alerts tabs.
  final List<Tab>? tabs;

  const AppBottomNavBar({
    super.key,
    required this.controller,
    this.tabs,
  });

  static const List<Tab> _defaultTabs = [
    Tab(icon: Icon(Icons.home_outlined,          size: 22), text: 'Home'),
    Tab(icon: Icon(Icons.people_outline,         size: 22), text: 'Patients'),
    Tab(icon: Icon(Icons.notifications_outlined, size: 22), text: 'Alerts'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2E8B7B), Color(0xFF5CAA7F)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: TabBar(
          controller: controller,
          tabs: tabs ?? _defaultTabs,
          indicator: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          indicatorPadding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          dividerColor: Colors.transparent,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withOpacity(0.55),
          labelStyle:
              const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontSize: 12),
        ),
      ),
    );
  }
}