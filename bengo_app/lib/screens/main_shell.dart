import 'package:flutter/material.dart';
import '../widgets/bottom_nav.dart';
import 'dashboard/dashboard_screen.dart';
import 'courses/courses_screen.dart';
import 'teams/teams_screen.dart';
import 'profile/profile_screen.dart';

/// Main shell that manages the 4 bottom navigation tabs.
/// Keeps the bottom nav consistent across all pages using IndexedStack
/// so pages preserve their state when switching.
class MainShell extends StatefulWidget {
  const MainShell({super.key, this.initialIndex = 0});
  final int initialIndex;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late int _currentIndex;

  // Whether the current tab uses a dark bottom nav
  final List<bool> _darkNavPages = [false, false, true, false];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void _onTabTapped(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          DashboardScreen(),
          CoursesScreen(),
          TeamsScreen(),
          ProfileScreen(),
        ],
      ),
      bottomNavigationBar: BenGoBottomNav(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        isDark: _darkNavPages[_currentIndex],
      ),
    );
  }
}
