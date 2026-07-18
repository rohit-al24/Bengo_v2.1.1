import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import '../widgets/bengo_avatar.dart';
import '../screens/friends/friends_screen.dart';
import '../screens/leaderboard/leaderboard_screen.dart';
import '../screens/profile/profile_screen.dart';

// ── Tokens ────────────────────────────────────────────────────────────────────
const _kAccent = Color(0xFFC41230);
const _kInk = Color(0xFF1B1B1D);
const _kMuted = Color(0xFF8A8A8F);

class BenGoHeader extends StatefulWidget {
  final bool isSubPage;
  final VoidCallback? onBackTap;
  final Widget? rightActions;

  const BenGoHeader({
    super.key,
    this.isSubPage = false,
    this.onBackTap,
    this.rightActions,
  });

  @override
  State<BenGoHeader> createState() => _BenGoHeaderState();
}

class _BenGoHeaderState extends State<BenGoHeader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimmerCtrl;

  @override
  void initState() {
    super.initState();
    if (ApiService.instance.currentUserNotifier.value == null) {
      ApiService.instance.getMe();
    }
    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Map<String, dynamic>?>(
      valueListenable: ApiService.instance.currentUserNotifier,
      builder: (context, user, _) {
        final streak = user?['streak_days'] ?? 0;
        final xp = user?['xp'] ?? 0;
        final avatarId = user?['avatar_id']?.toString() ?? 'a1';

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Container(
            decoration: BoxDecoration(
              // Subtle warm-to-cool gradient surface
              gradient: const LinearGradient(
                colors: [
                  Color(0xFFFFFFFF),
                  Color(0xFFFBF8FF),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: const Color(0xFFEDE9F4),
                width: 1,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x08000000),
                  blurRadius: 20,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              child: Row(
                children: [
                  // ── Left side ───────────────────────────────────────────
                  if (widget.isSubPage) ...[
                    _IconBtn(
                      icon: Icons.arrow_back_rounded,
                      onTap: widget.onBackTap ?? () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 12),
                    _HeaderStats(streak: streak, xp: xp),
                  ] else ...[
                    GestureDetector(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const ProfileScreen()),
                      ),
                      child: BenGoAvatar(
                        avatarId: avatarId,
                        size: 42,
                        showRing: true,
                      ),
                    ),
                    const SizedBox(width: 12),
                    _HeaderStats(streak: streak, xp: xp),
                  ],

                  const Spacer(),

                  // ── Logo ────────────────────────────────────────────────
                  _AnimatedLogoText(ctrl: _shimmerCtrl),

                  const Spacer(),

                  // ── Right actions ────────────────────────────────────────
                  widget.rightActions ??
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _IconBtn(
                            icon: Icons.bar_chart_rounded,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (_) => const LeaderboardScreen()),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const _FriendsIconBtn(),
                        ],
                      ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ── Avatar circle ─────────────────────────────────────────────────────────────
class _Avatar extends StatelessWidget {
  final String letter;
  const _Avatar({required this.letter});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [Color(0xFFC41230), Color(0xFF8B0D21)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x30C41230),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Text(
          letter,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

// ── Streak / XP stats ─────────────────────────────────────────────────────────
class _HeaderStats extends StatelessWidget {
  final dynamic streak;
  final dynamic xp;
  const _HeaderStats({required this.streak, required this.xp});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🔥', style: TextStyle(fontSize: 11)),
            const SizedBox(width: 3),
            Text(
              '$streak days',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: _kInk,
              ),
            ),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('⚡', style: TextStyle(fontSize: 10)),
            const SizedBox(width: 3),
            Text(
              '$xp XP',
              style: GoogleFonts.inter(
                fontSize: 11,
                color: _kMuted,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Icon button ───────────────────────────────────────────────────────────────
class _IconBtn extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _IconBtn({required this.icon, required this.onTap});

  @override
  State<_IconBtn> createState() => _IconBtnState();
}

class _IconBtnState extends State<_IconBtn> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.92 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: const Color(0xFFF5F2FA),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFEDE9F4)),
          ),
          child: Icon(widget.icon, size: 18, color: _kMuted),
        ),
      ),
    );
  }
}

// ── Animated shimmer logo text ────────────────────────────────────────────────
class _AnimatedLogoText extends StatelessWidget {
  final AnimationController ctrl;
  const _AnimatedLogoText({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ctrl,
      builder: (_, __) {
        final t = ctrl.value; // 0→1 repeating
        // shimmer offset — sweeps left to right
        final shimmerX = -1.5 + t * 3.5;
        return ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) => LinearGradient(
            begin: Alignment(shimmerX - 0.6, 0),
            end: Alignment(shimmerX + 0.6, 0),
            colors: const [
              Color(0xFF1B1B1D),
              Color(0xFFC41230),
              Color(0xFF1B1B1D),
            ],
            stops: const [0.0, 0.5, 1.0],
          ).createShader(bounds),
          child: Text(
            'BenGo',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: _kInk,
              letterSpacing: -0.6,
            ),
          ),
        );
      },
    );
  }
}

class _FriendsIconBtn extends StatefulWidget {
  const _FriendsIconBtn();

  @override
  State<_FriendsIconBtn> createState() => _FriendsIconBtnState();
}

class _FriendsIconBtnState extends State<_FriendsIconBtn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animCtrl;
  late final Animation<double> _translateY;
  late final Animation<double> _opacity;
  late final Animation<double> _scale;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _translateY = Tween<double>(begin: 0.0, end: -35.0).animate(
      CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic),
    );

    _opacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 1.0), weight: 20),
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 1.0), weight: 50),
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 0.0), weight: 30),
    ]).animate(_animCtrl);

    _scale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 1.3), weight: 30),
      TweenSequenceItem(tween: Tween<double>(begin: 1.3, end: 1.0), weight: 70),
    ]).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutBack));

    NotificationService.instance.newRequestAnimationTrigger
        .addListener(_onNewRequest);
  }

  void _onNewRequest() {
    if (mounted) {
      _animCtrl.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    NotificationService.instance.newRequestAnimationTrigger
        .removeListener(_onNewRequest);
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: NotificationService.instance.pendingRequestsNotifier,
      builder: (context, pendingCount, _) {
        return Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            GestureDetector(
              onTapDown: (_) => setState(() => _pressed = true),
              onTapUp: (_) {
                setState(() => _pressed = false);
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const FriendsScreen()),
                );
              },
              onTapCancel: () => setState(() => _pressed = false),
              child: AnimatedScale(
                scale: _pressed ? 0.92 : 1.0,
                duration: const Duration(milliseconds: 100),
                child: AnimatedBuilder(
                  animation: _animCtrl,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _scale.value,
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F2FA),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFEDE9F4)),
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            const Icon(Icons.people_alt_rounded,
                                size: 18, color: _kMuted),
                            if (pendingCount > 0)
                              Positioned(
                                top: 6,
                                right: 6,
                                child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: _kAccent,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            // Floating "+1" animated text
            AnimatedBuilder(
              animation: _animCtrl,
              builder: (context, child) {
                if (_animCtrl.isDismissed) return const SizedBox.shrink();
                return Positioned(
                  top: _translateY.value,
                  child: Opacity(
                    opacity: _opacity.value,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _kAccent,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: _kAccent.withOpacity(0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        '+1',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}
