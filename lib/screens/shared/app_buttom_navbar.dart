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

  /// Main app tabs — matches [HomePage] bottom navigation.
  static const List<Tab> mainTabs = [
    Tab(icon: Icon(Icons.dashboard_rounded, size: 22), text: 'Dashboard'),
    Tab(icon: Icon(Icons.assignment_rounded, size: 22), text: 'Assessment'),
    Tab(icon: Icon(Icons.people_rounded, size: 22), text: 'Patients'),
    Tab(
      icon: Icon(Icons.notifications_rounded, size: 22),
      text: 'Alerts',
    ),
  ];

  static const List<Tab> _defaultTabs = mainTabs;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1F6B5F), Color(0xFF2E8B7B)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: TabBar(
          controller: controller,
          tabs: tabs ?? _defaultTabs,
          indicator: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(14),
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          indicatorPadding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
          dividerColor: Colors.transparent,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withValues(alpha: 0.45),
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 11,
            letterSpacing: 0.2,
          ),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        ),
      ),
    );
  }
}