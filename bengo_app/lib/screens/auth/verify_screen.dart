import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../main_shell.dart';

// ── Design tokens ─────────────────────────────────────────────────────────────
const _kBg = Color(0xFFFAF8F5);
const _kAccent = Color(0xFFC41230);
const _kInk = Color(0xFF1B1B1D);
const _kMuted = Color(0xFF8A8A8F);
const _kSurface = Color(0xFFFFFFFF);

// ── Confetti colours ──────────────────────────────────────────────────────────
const _kConfettiColors = [
  Color(0xFFC41230),
  Color(0xFFFF6B6B),
  Color(0xFFFFD93D),
  Color(0xFF6BCB77),
  Color(0xFF4D96FF),
  Color(0xFFFF6DA7),
  Color(0xFFFFB347),
];

class AccountCreatedScreen extends StatefulWidget {
  const AccountCreatedScreen({super.key});

  @override
  State<AccountCreatedScreen> createState() => _AccountCreatedScreenState();
}

class _AccountCreatedScreenState extends State<AccountCreatedScreen>
    with TickerProviderStateMixin {
  // ── Tick draw animation ───────────────────────────────────────────────────
  late final AnimationController _circleCtrl;
  late final AnimationController _tickCtrl;
  late final AnimationController _pulseCtrl;

  // ── Text reveal ───────────────────────────────────────────────────────────
  late final AnimationController _textCtrl;
  late final Animation<double> _titleFade;
  late final Animation<Offset> _titleSlide;
  late final Animation<double> _subtitleFade;
  late final Animation<Offset> _subtitleSlide;
  late final Animation<double> _cardFade;
  late final Animation<Offset> _cardSlide;

  // ── Confetti ──────────────────────────────────────────────────────────────
  late final AnimationController _confettiCtrl;
  final List<_ConfettiParticle> _particles = [];

  @override
  void initState() {
    super.initState();
    _generateParticles();

    // 1. Circle scales in
    _circleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    // 2. Tick path draws
    _tickCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    // 3. Gentle pulse on the circle
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    // 4. Text reveal
    _textCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _titleFade = CurvedAnimation(
        parent: _textCtrl, curve: const Interval(0.0, 0.55, curve: Curves.easeOut));
    _titleSlide = Tween<Offset>(
            begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _textCtrl,
            curve: const Interval(0.0, 0.55, curve: Curves.easeOut)));
    _subtitleFade = CurvedAnimation(
        parent: _textCtrl, curve: const Interval(0.25, 0.75, curve: Curves.easeOut));
    _subtitleSlide = Tween<Offset>(
            begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _textCtrl,
            curve: const Interval(0.25, 0.75, curve: Curves.easeOut)));
    _cardFade = CurvedAnimation(
        parent: _textCtrl, curve: const Interval(0.5, 1.0, curve: Curves.easeOut));
    _cardSlide = Tween<Offset>(
            begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _textCtrl,
            curve: const Interval(0.5, 1.0, curve: Curves.easeOut)));

    // 5. Confetti
    _confettiCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    _runSequence();

    // Navigate to main shell after 3.5 s
    Timer(const Duration(milliseconds: 3800), () {
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainShell()),
        (route) => false,
      );
    });
  }

  void _generateParticles() {
    final rng = math.Random();
    for (int i = 0; i < 60; i++) {
      _particles.add(_ConfettiParticle(
        color: _kConfettiColors[rng.nextInt(_kConfettiColors.length)],
        x: rng.nextDouble(),
        size: 6 + rng.nextDouble() * 8,
        speed: 0.5 + rng.nextDouble() * 0.5,
        drift: (rng.nextDouble() - 0.5) * 0.4,
        rotation: rng.nextDouble() * math.pi * 2,
        rotationSpeed: (rng.nextDouble() - 0.5) * 8,
        isRect: rng.nextBool(),
        delay: rng.nextDouble() * 0.35,
      ));
    }
  }

  Future<void> _runSequence() async {
    await Future.delayed(const Duration(milliseconds: 120));

    // Circle pop in
    _circleCtrl.forward();

    // Haptic + sound at the circle pop moment
    await Future.delayed(const Duration(milliseconds: 300));
    _playTickSound();

    // Tick draws in
    await Future.delayed(const Duration(milliseconds: 50));
    _tickCtrl.forward();

    // Confetti bursts
    await Future.delayed(const Duration(milliseconds: 200));
    _confettiCtrl.forward();

    // Text reveals
    await Future.delayed(const Duration(milliseconds: 350));
    _textCtrl.forward();
  }

  void _playTickSound() {
    // Trigger success haptic
    HapticFeedback.mediumImpact();
    // Light follow-up vibration for the 'tick' feel
    Future.delayed(const Duration(milliseconds: 120),
        () => HapticFeedback.lightImpact());
  }

  @override
  void dispose() {
    _circleCtrl.dispose();
    _tickCtrl.dispose();
    _pulseCtrl.dispose();
    _textCtrl.dispose();
    _confettiCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: _kBg,
      body: Stack(
        children: [
          // ── Confetti layer ────────────────────────────────────────────────
          AnimatedBuilder(
            animation: _confettiCtrl,
            builder: (_, __) {
              return CustomPaint(
                size: Size(size.width, size.height),
                painter: _ConfettiPainter(
                  particles: _particles,
                  progress: _confettiCtrl.value,
                  screenHeight: size.height,
                ),
              );
            },
          ),

          // ── Main content ──────────────────────────────────────────────────
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // ── Animated tick circle ─────────────────────────────
                    AnimatedBuilder(
                      animation: Listenable.merge(
                          [_circleCtrl, _tickCtrl, _pulseCtrl]),
                      builder: (_, __) {
                        final circleScale = CurvedAnimation(
                          parent: _circleCtrl,
                          curve: Curves.elasticOut,
                        ).value;
                        final tickProgress = CurvedAnimation(
                          parent: _tickCtrl,
                          curve: Curves.easeInOut,
                        ).value;
                        final pulse = Tween<double>(begin: 1.0, end: 1.04)
                            .evaluate(CurvedAnimation(
                                parent: _pulseCtrl,
                                curve: Curves.easeInOut));

                        return Transform.scale(
                          scale: circleScale * pulse,
                          child: SizedBox(
                            width: 160,
                            height: 160,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Outer glow ring
                                Container(
                                  width: 160,
                                  height: 160,
                                  decoration: BoxDecoration(
                                    color: _kAccent
                                        .withOpacity(0.10 * circleScale),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                // Main circle
                                Container(
                                  width: 110,
                                  height: 110,
                                  decoration: const BoxDecoration(
                                    color: _kAccent,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Color(0x50C41230),
                                        blurRadius: 24,
                                        offset: Offset(0, 10),
                                      ),
                                      BoxShadow(
                                        color: Color(0x30C41230),
                                        blurRadius: 6,
                                        offset: Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: CustomPaint(
                                    painter: _TickPainter(
                                        progress: tickProgress),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 36),

                    // ── Title ─────────────────────────────────────────────
                    SlideTransition(
                      position: _titleSlide,
                      child: FadeTransition(
                        opacity: _titleFade,
                        child: Text(
                          'Account Created!',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            color: _kInk,
                            letterSpacing: -0.8,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // ── Subtitle ──────────────────────────────────────────
                    SlideTransition(
                      position: _subtitleSlide,
                      child: FadeTransition(
                        opacity: _subtitleFade,
                        child: Text(
                          'Your BenGo account is ready.\nYour journey to mastery starts now.',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: _kMuted,
                            height: 1.6,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // ── Loading card ──────────────────────────────────────
                    SlideTransition(
                      position: _cardSlide,
                      child: FadeTransition(
                        opacity: _cardFade,
                        child: _LoadingCard(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Custom tick painter ───────────────────────────────────────────────────────
class _TickPainter extends CustomPainter {
  final double progress; // 0→1

  const _TickPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final cx = size.width / 2;
    final cy = size.height / 2;

    // The tick path: two segments — short arm then long arm
    // Short: from (cx-18, cy) to (cx-6, cy+14)
    // Long:  from (cx-6, cy+14) to (cx+20, cy-16)
    const p1 = Offset(0, 0); // relative start of short arm
    final shortEnd = const Offset(12, 14);
    final longEnd = const Offset(38, -16);

    final origin = Offset(cx - 19, cy);

    // Total path length proxy: split 35% short, 65% long
    final shortFrac = 0.35;
    final longFrac = 0.65;

    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();

    if (progress <= shortFrac) {
      // Drawing the short arm
      final t = progress / shortFrac;
      final end = Offset.lerp(Offset.zero, shortEnd, t)!;
      path.moveTo(origin.dx, origin.dy);
      path.lineTo(origin.dx + end.dx, origin.dy + end.dy);
    } else {
      // Short arm complete + drawing the long arm
      final t = (progress - shortFrac) / longFrac;
      final end = Offset.lerp(shortEnd, longEnd, t)!;
      path.moveTo(origin.dx, origin.dy);
      path.lineTo(origin.dx + shortEnd.dx, origin.dy + shortEnd.dy);
      path.lineTo(origin.dx + end.dx, origin.dy + end.dy);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_TickPainter old) => old.progress != progress;
}

// ── Confetti particle data ────────────────────────────────────────────────────
class _ConfettiParticle {
  final Color color;
  final double x;         // normalised x start (0–1)
  final double size;
  final double speed;
  final double drift;     // horizontal drift per unit time
  final double rotation;
  final double rotationSpeed;
  final bool isRect;
  final double delay;     // animation start delay (0–1)

  const _ConfettiParticle({
    required this.color,
    required this.x,
    required this.size,
    required this.speed,
    required this.drift,
    required this.rotation,
    required this.rotationSpeed,
    required this.isRect,
    required this.delay,
  });
}

class _ConfettiPainter extends CustomPainter {
  final List<_ConfettiParticle> particles;
  final double progress;
  final double screenHeight;

  _ConfettiPainter({
    required this.particles,
    required this.progress,
    required this.screenHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final localT = ((progress - p.delay) / (1.0 - p.delay)).clamp(0.0, 1.0);
      if (localT <= 0) continue;

      // Start particles from the top-centre area (logo position)
      final startX = size.width / 2 + (p.x - 0.5) * 80;
      final startY = size.height * 0.0; // near top of screen

      final x = startX + p.drift * localT * size.width * 0.5;
      final y = startY + localT * screenHeight * p.speed * 1.2;
      final opacity = (1.0 - (localT * 0.85)).clamp(0.0, 1.0);
      final angle = p.rotation + p.rotationSpeed * localT;

      final paint = Paint()
        ..color = p.color.withOpacity(opacity)
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(angle);

      if (p.isRect) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
                center: Offset.zero,
                width: p.size,
                height: p.size * 0.45),
            const Radius.circular(2),
          ),
          paint,
        );
      } else {
        canvas.drawCircle(Offset.zero, p.size / 2.2, paint);
      }

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.progress != progress;
}

// ── Loading card ──────────────────────────────────────────────────────────────
class _LoadingCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEAE5E1)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: _kAccent,
            ),
          ),
          const SizedBox(width: 14),
          Text(
            'Preparing your dashboard…',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: _kMuted,
            ),
          ),
        ],
      ),
    );
  }
}
