import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_colors.dart';

/// Enhanced 5-tab bottom navigation bar with a center floating Clan button.
/// Tabs: Home (0) · Learn (1) · Clan (2) · RolePlay (3) · Profile (4)
class BenGoBottomNav extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final bool isDark;

  // Clan button state flags
  final bool clanRushActive;
  final bool clanRushEndingSoon;
  final bool clanDuelAvailable;
  final bool clanRushGoalReached;
  final double clanRushProgress; // 0.0 – 1.0
  final String? clanRushCountdown; // e.g. "18m"

  const BenGoBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.isDark = false,
    this.clanRushActive = false,
    this.clanRushEndingSoon = false,
    this.clanDuelAvailable = false,
    this.clanRushGoalReached = false,
    this.clanRushProgress = 0.0,
    this.clanRushCountdown,
  });

  @override
  State<BenGoBottomNav> createState() => _BenGoBottomNavState();
}

class _BenGoBottomNavState extends State<BenGoBottomNav>
    with TickerProviderStateMixin {
  late AnimationController _glowController;
  late AnimationController _pulseController;
  late AnimationController _glintController;
  late AnimationController _goldFlashController;

  late Animation<double> _glowAnim;
  late Animation<double> _pulseAnim;
  late Animation<double> _glintAnim;
  late Animation<double> _goldFlashAnim;

  @override
  void initState() {
    super.initState();

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _glintController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _goldFlashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _glowAnim = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _glintAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _glintController, curve: Curves.easeOut),
    );
    _goldFlashAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _goldFlashController, curve: Curves.easeOut),
    );
  }

  @override
  void didUpdateWidget(BenGoBottomNav old) {
    super.didUpdateWidget(old);
    if (widget.clanRushEndingSoon && !old.clanRushEndingSoon) {
      _pulseController.repeat(reverse: true);
    } else if (!widget.clanRushEndingSoon) {
      _pulseController.stop();
      _pulseController.reset();
    }
    if (widget.clanDuelAvailable && !old.clanDuelAvailable) {
      _glintController.repeat();
    } else if (!widget.clanDuelAvailable) {
      _glintController.stop();
      _glintController.reset();
    }
    if (widget.clanRushGoalReached && !old.clanRushGoalReached) {
      _goldFlashController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _glowController.dispose();
    _pulseController.dispose();
    _glintController.dispose();
    _goldFlashController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.isDark ? AppColors.navBgDark : AppColors.navBg;

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 72,
          child: Row(
            children: [
              _buildNavItem(0, Icons.home_rounded, 'Home'),
              _buildNavItem(1, Icons.menu_book_rounded, 'Learn'),
              // Center Clan button slot
              Expanded(child: _buildClanButton()),
              _buildNavItem(3, Icons.theater_comedy_rounded, 'RolePlay'),
              _buildNavItem(4, Icons.person_outline_rounded, 'Profile'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isActive = widget.currentIndex == index;
    final color = isActive ? AppColors.navActive : AppColors.navInactive;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          widget.onTap(index);
        },
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: isActive
                  ? const EdgeInsets.symmetric(horizontal: 12, vertical: 5)
                  : EdgeInsets.zero,
              decoration: isActive
                  ? BoxDecoration(
                      color: AppColors.navActive.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    )
                  : null,
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClanButton() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        widget.onTap(2);
      },
      onLongPress: () {
        HapticFeedback.heavyImpact();
        _showQuickMenu(context);
      },
      child: Center(
        child: AnimatedBuilder(
          animation: Listenable.merge([
            _glowAnim, _pulseAnim, _glintAnim, _goldFlashAnim,
          ]),
          builder: (_, __) {
            double scale = 1.0;
            if (widget.clanRushEndingSoon) scale = _pulseAnim.value;

            return Transform.scale(
              scale: scale,
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  // Outer glow ring
                  CustomPaint(
                    size: const Size(68, 68),
                    painter: _ClanButtonRingPainter(
                      rushActive: widget.clanRushActive,
                      rushProgress: widget.clanRushProgress,
                      rushEndingSoon: widget.clanRushEndingSoon,
                      goalReached: widget.clanRushGoalReached,
                      glowValue: _glowAnim.value,
                      goldFlash: _goldFlashAnim.value,
                    ),
                  ),
                  // Main circle button
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: widget.clanRushGoalReached
                          ? const LinearGradient(
                              colors: [Color(0xFFFFD700), Color(0xFFFF8C00)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : const LinearGradient(
                              colors: [Color(0xFFEB4B6E), Color(0xFFBF1B2C)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                      boxShadow: [
                        BoxShadow(
                          color: (widget.clanRushGoalReached
                                  ? const Color(0xFFFFD700)
                                  : AppColors.primary)
                              .withOpacity(0.5 * _glowAnim.value),
                          blurRadius: 16,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Center(
                      child: widget.clanDuelAvailable
                          ? _buildGlintIcon()
                          : const Text('⛩️', style: TextStyle(fontSize: 24)),
                    ),
                  ),
                  // Countdown badge
                  if (widget.clanRushActive && widget.clanRushCountdown != null)
                    Positioned(
                      top: -2,
                      right: 2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: widget.clanRushEndingSoon
                              ? const Color(0xFFF59E0B)
                              : AppColors.primary,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        child: Text(
                          widget.clanRushCountdown!,
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  // Goal reached checkmark
                  if (widget.clanRushGoalReached && _goldFlashAnim.value > 0.5)
                    Positioned(
                      top: -2,
                      right: 2,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: Color(0xFF22C55E),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check, color: Colors.white, size: 10),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildGlintIcon() {
    return AnimatedBuilder(
      animation: _glintAnim,
      builder: (_, __) {
        return Stack(
          alignment: Alignment.center,
          children: [
            const Text('⛩️', style: TextStyle(fontSize: 22)),
            if (_glintAnim.value > 0.3 && _glintAnim.value < 0.7)
              Positioned(
                right: 2,
                top: 2,
                child: Icon(
                  Icons.flash_on,
                  color: Colors.white.withOpacity(
                      (_glintAnim.value - 0.3) / 0.4),
                  size: 12,
                ),
              ),
          ],
        );
      },
    );
  }

  void _showQuickMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _ClanQuickMenu(
        onSelect: (idx) {
          Navigator.pop(context);
          widget.onTap(idx);
        },
        rushProgress: widget.clanRushProgress,
        rushActive: widget.clanRushActive,
      ),
    );
  }
}

// ── Ring painter ────────────────────────────────────────────────────────────

class _ClanButtonRingPainter extends CustomPainter {
  final bool rushActive;
  final double rushProgress;
  final bool rushEndingSoon;
  final bool goalReached;
  final double glowValue;
  final double goldFlash;

  _ClanButtonRingPainter({
    required this.rushActive,
    required this.rushProgress,
    required this.rushEndingSoon,
    required this.goalReached,
    required this.glowValue,
    required this.goldFlash,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 3;

    if (rushActive) {
      // Background ring
      final bgPaint = Paint()
        ..color = Colors.grey.withOpacity(0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round;
      canvas.drawCircle(center, radius, bgPaint);

      // Progress arc
      final arcColor = goalReached
          ? Color.lerp(const Color(0xFFFFD700), Colors.white, goldFlash)!
          : rushEndingSoon
              ? const Color(0xFFF59E0B)
              : const Color(0xFFEB4B6E);

      final arcPaint = Paint()
        ..color = arcColor.withOpacity(0.7 + 0.3 * glowValue)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -pi / 2,
        2 * pi * rushProgress,
        false,
        arcPaint,
      );
    } else {
      // Idle glow ring
      final glowPaint = Paint()
        ..color = const Color(0xFFBF1B2C).withOpacity(0.3 * glowValue)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5;
      canvas.drawCircle(center, radius, glowPaint);
    }
  }

  @override
  bool shouldRepaint(_ClanButtonRingPainter old) => true;
}

// ── Quick menu bottom sheet ─────────────────────────────────────────────────

class _ClanQuickMenu extends StatelessWidget {
  final ValueChanged<int> onSelect;
  final double rushProgress;
  final bool rushActive;

  const _ClanQuickMenu({
    required this.onSelect,
    required this.rushProgress,
    required this.rushActive,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Clan Quick Menu',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          _QuickMenuItem(icon: '⚔️', label: 'Battle', onTap: () => onSelect(2)),
          _QuickMenuItem(icon: '💬', label: 'Clan Chat', onTap: () => onSelect(2)),
          _QuickMenuItem(icon: '🏆', label: 'Leaderboard', onTap: () => onSelect(2)),
          _QuickMenuItem(icon: '🔥', label: 'War', onTap: () => onSelect(2)),
          // Clan Rush with inline progress
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: GestureDetector(
              onTap: () => onSelect(2),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: rushActive
                      ? AppColors.primary.withOpacity(0.15)
                      : Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(14),
                  border: rushActive
                      ? Border.all(color: AppColors.primary.withOpacity(0.4))
                      : null,
                ),
                child: Row(
                  children: [
                    const Text('⚡', style: TextStyle(fontSize: 20)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Clan Rush',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          if (rushActive) ...[
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: rushProgress,
                                backgroundColor: Colors.white12,
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                    Color(0xFFEB4B6E)),
                                minHeight: 5,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${(rushProgress * 100).toStringAsFixed(0)}% complete',
                              style: GoogleFonts.inter(
                                  fontSize: 10, color: Colors.white54),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: Colors.white38),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _QuickMenuItem extends StatelessWidget {
  final String icon;
  final String label;
  final VoidCallback onTap;

  const _QuickMenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        onTap: onTap,
        leading: Text(icon, style: const TextStyle(fontSize: 20)),
        title: Text(
          label,
          style: GoogleFonts.inter(
              fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
        ),
        trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white38),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        tileColor: Colors.white.withOpacity(0.04),
      ),
    );
  }
}
