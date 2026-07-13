import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/api_service.dart';
import '../../widgets/bengo_avatar.dart';
import '../../widgets/bengo_header.dart';
import '../daily_revision/daily_revision_screen.dart';

// ── Tokens ────────────────────────────────────────────────────────────────────
const _kAccent = Color(0xFFC41230);
const _kAccentShadow = Color(0x35C41230);
const _kInk = Color(0xFF1B1B1D);
const _kMuted = Color(0xFF8A8A8F);
const _kBorderLight = Color(0xFFEAE5E1);
const _kFieldTint = Color(0xFFFDF3F5);

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic> _user = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final me = await ApiService.instance.getMe();
      if (mounted) setState(() { _user = me; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  String get _greeting {
    final h = TimeOfDay.now().hour;
    if (h < 5)  return 'Good night';
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String get _greetingEmoji {
    final h = TimeOfDay.now().hour;
    if (h < 5)  return '🌙';
    if (h < 12) return '☀️';
    if (h < 17) return '🌤';
    return '🌅';
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Map<String, dynamic>?>(
      valueListenable: ApiService.instance.currentUserNotifier,
      builder: (context, userNotifierMap, _) {
        final u = userNotifierMap ?? _user;
        final xp = (u['xp'] ?? 0) as int;
        final streak = (u['streak_days'] ?? 0) as int;
        final firstName = (u['first_name'] ?? '').toString().trim();
        final username = (u['username'] ?? '').toString().trim();
        final displayName = firstName.isNotEmpty ? firstName : (username.isNotEmpty ? username : 'Samurai');
        final avatarId = u['avatar_id']?.toString() ?? 'a1';

        return Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFFFAF8F5),
                  Color(0xFFF8F5FF),
                  Color(0xFFFFF5F7),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0.0, 0.55, 1.0],
              ),
            ),
            child: SafeArea(
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // App bar
                  const SliverToBoxAdapter(child: BenGoHeader()),

                  // Hero banner — full-bleed card with avatar
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                      child: _HeroBanner(
                        displayName: displayName,
                        greeting: _greeting,
                        greetingEmoji: _greetingEmoji,
                        xp: xp,
                        streak: streak,
                        avatarId: avatarId,
                      ),
                    ),
                  ),

                  // Section: Quick actions
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
                      child: _SectionLabel(label: 'QUICK ACTIONS'),
                    ),
                  ),

                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                      child: _buildDailyRevisionCard(),
                    ),
                  ),

                  // Section: Events
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
                      child: _SectionLabel(label: 'EVENTS'),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                      child: _buildAnnouncementCard(),
                    ),
                  ),

                  // Section: Your path
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
                      child: _SectionLabel(label: 'YOUR PATH'),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
                      child: _buildNextLessonCard(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ── Daily Revision ──────────────────────────────────────────────────────────
  Widget _buildDailyRevisionCard() {
    return _Card3D(
      accentColor: _kAccent,
      child: Row(
        children: [
          // Icon block
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFDF3F5), Color(0xFFFAEAEE)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFEDD5D8)),
            ),
            child:
                const Icon(Icons.repeat_rounded, color: _kAccent, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Daily Revision',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: _kInk,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Recall 15 items · Lesson 4',
                  style: GoogleFonts.inter(fontSize: 12, color: _kMuted),
                ),
              ],
            ),
          ),
          _PillCTA(
            label: 'GO',
            compact: true,
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const DailyRevisionScreen()),
            ),
          ),
        ],
      ),
    );
  }

  // ── Announcement ────────────────────────────────────────────────────────────
  Widget _buildAnnouncementCard() {
    return _Card3D(
      accentColor: const Color(0xFFFF6B35),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFFECB3)),
            ),
            child: const Center(
              child: Text('🌸', style: TextStyle(fontSize: 24)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'LIVE EVENT',
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: _kAccent,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3EC),
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(color: const Color(0xFFFFCBA4)),
                      ),
                      child: Text(
                        '3 days left',
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFE65100),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Cherry Blossom Festival',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _kInk,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Earn exclusive badges & 500 bonus XP.',
                  style: GoogleFonts.inter(fontSize: 12, color: _kMuted),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () {},
                  child: Text(
                    'View details →',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _kAccent,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Next Lesson ─────────────────────────────────────────────────────────────
  Widget _buildNextLessonCard() {
    return _Card3D(
      accentColor: const Color(0xFF6366F1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  'CHAPTER 5',
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF6366F1),
                    letterSpacing: 1,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '33%',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _kAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Going to the Market',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: _kInk,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '4 of 12 lessons completed',
            style: GoogleFonts.inter(fontSize: 12, color: _kMuted),
          ),
          const SizedBox(height: 14),
          _SegmentedProgress(value: 4, total: 12),
          const SizedBox(height: 16),
          _PillCTA(label: 'CONTINUE', onPressed: () {}),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// HERO BANNER — user avatar + greeting + stat pills
// ═══════════════════════════════════════════════════════════════════════════════

class _HeroBanner extends StatelessWidget {
  final String displayName;
  final String greeting;
  final String greetingEmoji;
  final int xp;
  final int streak;
  final String avatarId;

  const _HeroBanner({
    required this.displayName,
    required this.greeting,
    required this.greetingEmoji,
    required this.xp,
    required this.streak,
    required this.avatarId,
  });

  @override
  Widget build(BuildContext context) {
    final def = avatarById(avatarId);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        // Deep gradient hero bg
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1B1B1D),
            def.shadow.withOpacity(0.72),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: def.shadow.withOpacity(0.30),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          // Left: text + stats
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$greetingEmoji  $greeting',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.white60,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  displayName,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.6,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _StatChip(emoji: '🔥', value: '$streak', label: 'streak'),
                    const SizedBox(width: 8),
                    _StatChip(emoji: '⚡', value: '$xp', label: 'XP'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Right: floating 3D avatar
          _FloatingAvatar(avatarId: avatarId),
        ],
      ),
    );
  }
}

class _FloatingAvatar extends StatefulWidget {
  final String avatarId;
  const _FloatingAvatar({required this.avatarId});

  @override
  State<_FloatingAvatar> createState() => _FloatingAvatarState();
}

class _FloatingAvatarState extends State<_FloatingAvatar>
    with TickerProviderStateMixin {
  late AnimationController _float;
  late AnimationController _tilt;

  @override
  void initState() {
    super.initState();
    _float = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _tilt = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _float.dispose();
    _tilt.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_float, _tilt]),
      builder: (_, child) {
        final dy = (_float.value - 0.5) * 8;
        final ry = (_tilt.value - 0.5) * 0.15;
        return Transform.translate(
          offset: Offset(0, dy),
          child: Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(ry),
            child: child,
          ),
        );
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Glow aura behind the squircle avatar
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(26),
              boxShadow: [
                BoxShadow(
                  color: avatarById(widget.avatarId).shadow.withOpacity(0.35),
                  blurRadius: 28,
                  spreadRadius: 4,
                ),
              ],
            ),
          ),
          BenGoAvatar(
            avatarId: widget.avatarId,
            size: 80,
            showRing: true,
            selected: true,
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String emoji;
  final String value;
  final String label;
  const _StatChip({required this.emoji, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: Colors.white.withOpacity(0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 5),
          Text(
            value,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 3),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              color: Colors.white60,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// 3D ELEVATED CARD
// ═══════════════════════════════════════════════════════════════════════════════

class _Card3D extends StatefulWidget {
  final Widget child;
  final Color accentColor;
  const _Card3D({required this.child, required this.accentColor});

  @override
  State<_Card3D> createState() => _Card3DState();
}

class _Card3DState extends State<_Card3D> {
  Offset _tilt = Offset.zero;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: (d) {
        final size = context.size ?? const Size(300, 150);
        setState(() {
          _tilt = Offset(
            (d.localPosition.dx / size.width - 0.5) * 0.08,
            (d.localPosition.dy / size.height - 0.5) * 0.08,
          );
        });
      },
      onPanEnd: (_) => setState(() => _tilt = Offset.zero),
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() { _pressed = false; _tilt = Offset.zero; }),
      onTapCancel: () => setState(() { _pressed = false; _tilt = Offset.zero; }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        child: Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateX(-_tilt.dy)
            ..rotateY(_tilt.dx)
            ..scale(_pressed ? 0.98 : 1.0),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.88),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFEDE8F8)),
              boxShadow: [
                BoxShadow(
                  color: widget.accentColor.withOpacity(0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
                const BoxShadow(
                  color: Color(0x06000000),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// COMPONENTS
// ═══════════════════════════════════════════════════════════════════════════════

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: GoogleFonts.inter(
        fontSize: 10,
        fontWeight: FontWeight.w800,
        color: _kMuted,
        letterSpacing: 1.6,
      ),
    );
  }
}

class _SegmentedProgress extends StatelessWidget {
  final int value;
  final int total;
  const _SegmentedProgress({required this.value, required this.total});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(total, (i) {
        final filled = i < value;
        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 1.5),
            height: 5,
            decoration: BoxDecoration(
              color: filled ? _kAccent : _kBorderLight,
              borderRadius: BorderRadius.circular(100),
            ),
          ),
        );
      }),
    );
  }
}

class _PillCTA extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool compact;
  const _PillCTA({required this.label, this.onPressed, this.compact = false});

  @override
  State<_PillCTA> createState() => _PillCTAState();
}

class _PillCTAState extends State<_PillCTA> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onPressed?.call();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          height: widget.compact ? 40 : 50,
          padding: widget.compact
              ? const EdgeInsets.symmetric(horizontal: 18)
              : null,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFC41230), Color(0xFFE0183A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(100),
            boxShadow: const [
              BoxShadow(
                  color: _kAccentShadow, blurRadius: 0, offset: Offset(0, 4)),
              BoxShadow(
                  color: Color(0x18C41230),
                  blurRadius: 14,
                  offset: Offset(0, 8)),
            ],
          ),
          child: Center(
            child: Text(
              widget.label,
              style: GoogleFonts.inter(
                fontSize: widget.compact ? 12 : 13,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 0.8,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
