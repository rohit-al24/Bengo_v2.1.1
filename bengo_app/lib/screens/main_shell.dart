import 'package:flutter/material.dart';
import '../widgets/bottom_nav.dart';
import 'dashboard/dashboard_screen.dart';
import 'courses/courses_screen.dart';
import 'clan/clan_home_screen.dart';
import 'roleplay/roleplay_home_screen.dart';
import 'profile/profile_screen.dart';

/// Main shell managing the 5-tab bottom navigation:
/// Home (0) · Learn (1) · Clan (2, center) · RolePlay (3) · Profile (4)
class MainShell extends StatefulWidget {
  const MainShell({super.key, this.initialIndex = 0});
  final int initialIndex;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late int _currentIndex;

  // Clan button live state (would be driven by real-time data in production)
  bool _clanRushActive      = false;
  bool _clanRushEndingSoon  = false;
  bool _clanDuelAvailable   = false;
  bool _clanRushGoalReached = false;
  double _clanRushProgress  = 0.0;
  String? _clanRushCountdown;

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
          DashboardScreen(),    // 0 — Home
          CoursesScreen(),      // 1 — Learn
          ClanHomeScreen(),     // 2 — Clan (center)
          RolePlayHomeScreen(), // 3 — RolePlay
          ProfileScreen(),      // 4 — Profile
        ],
      ),
      bottomNavigationBar: BenGoBottomNav(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        isDark: false,
        clanRushActive: _clanRushActive,
        clanRushEndingSoon: _clanRushEndingSoon,
        clanDuelAvailable: _clanDuelAvailable,
        clanRushGoalReached: _clanRushGoalReached,
        clanRushProgress: _clanRushProgress,
        clanRushCountdown: _clanRushCountdown,
      ),
    );
  }
}
