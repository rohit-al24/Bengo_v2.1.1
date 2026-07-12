import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_colors.dart';
import '../utils/app_decorations.dart';

/// The persistent bottom navigation bar used across all main app screens.
/// Takes the current index and a callback when a tab is tapped.
class BenGoBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final bool isDark;

  const BenGoBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isDark ? AppColors.navBgDark : AppColors.navBg;
    final inactiveColor =
        isDark ? const Color(0xFF666699) : AppColors.navInactive;
    final activeColor = AppColors.navActive;

    return Container(
      decoration: AppDecorations.softPanel(color: bgColor, radius: 26),
      child: SafeArea(
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              _NavItem(
                icon: Icons.grid_view_rounded,
                label: 'Dashboard',
                isActive: currentIndex == 0,
                activeColor: activeColor,
                inactiveColor: inactiveColor,
                isDark: isDark,
                onTap: () => onTap(0),
              ),
              _NavItem(
                icon: Icons.menu_book_rounded,
                label: 'Courses',
                isActive: currentIndex == 1,
                activeColor: activeColor,
                inactiveColor: inactiveColor,
                isDark: isDark,
                onTap: () => onTap(1),
              ),
              _NavItem(
                icon: Icons.groups_rounded,
                label: 'Teams',
                isActive: currentIndex == 2,
                activeColor: activeColor,
                inactiveColor: inactiveColor,
                isDark: isDark,
                isHighlighted: true,
                onTap: () => onTap(2),
              ),
              _NavItem(
                icon: Icons.person_outline_rounded,
                label: 'Profile',
                isActive: currentIndex == 3,
                activeColor: activeColor,
                inactiveColor: inactiveColor,
                isDark: isDark,
                onTap: () => onTap(3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final Color activeColor;
  final Color inactiveColor;
  final bool isDark;
  final bool isHighlighted;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.activeColor,
    required this.inactiveColor,
    required this.isDark,
    required this.onTap,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive ? activeColor : inactiveColor;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        splashColor: activeColor.withAlpha(25),
        highlightColor: activeColor.withAlpha(13),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isActive && isHighlighted)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: activeColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(icon, color: Colors.white, size: 22),
              )
            else
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                child: Icon(icon, color: color, size: 22),
              ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
