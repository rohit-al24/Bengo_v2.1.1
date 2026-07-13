import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'login_screen.dart';

// ── Tokens ────────────────────────────────────────────────────────────────────
const _kAccent = Color(0xFFC41230);
const _kInk = Color(0xFF1B1B1D);
const _kMuted = Color(0xFF8A8A8F);

// Background: same tri-stop gradient as dashboard
const _kGradTop = Color(0xFFFAF8F5);
const _kGradMid = Color(0xFFF8F5FF);
const _kGradBot = Color(0xFFFFF5F7);

// Timing
const _kPhase1Ms = 2400; // orbs float
const _kPhase2Ms = 1800; // logo + text settle
const _kTotalMs  = _kPhase1Ms + _kPhase2Ms; // 4200 ms total

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {

  // ── Orb float — slow continuous drift ─────────────────────────────────────
  late final AnimationController _orbCtrl;

  // ── Logo scale-in ──────────────────────────────────────────────────────────
  late final AnimationController _logoCtrl;
  late final Animation<double>   _logoScale;
  late final Animation<double>   _logoFade;

  // ── Content stagger ────────────────────────────────────────────────────────
  late final AnimationController _contentCtrl;
  late final Animation<double>   _line1Fade;
  late final Animation<Offset>   _line1Slide;
  late final Animation<double>   _line2Fade;
  late final Animation<Offset>   _line2Slide;
  late final Animation<double>   _line3Fade;
  late final Animation<Offset>   _line3Slide;

  // ── Loading bar ────────────────────────────────────────────────────────────
  late final AnimationController _barCtrl;
  late final Animation<double>   _barWidth;

  Timer? _timer;

  @override
  void initState() {
    super.initState();

    // Orb drift — repeating slow float
    _orbCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();

    // Logo scale-in at t=0
    _logoCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _logoScale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _logoCtrl, curve: Curves.elasticOut),
    );
    _logoFade = CurvedAnimation(parent: _logoCtrl, curve: const Interval(0.0, 0.5));
    _logoCtrl.forward();

    // Content stagger — starts at phase 2
    _contentCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _line1Fade  = _intervalFade(_contentCtrl, 0.00, 0.50);
    _line1Slide = _intervalSlide(_contentCtrl, 0.00, 0.50);
    _line2Fade  = _intervalFade(_contentCtrl, 0.25, 0.70);
    _line2Slide = _intervalSlide(_contentCtrl, 0.25, 0.70);
    _line3Fade  = _intervalFade(_contentCtrl, 0.55, 1.00);
    _line3Slide = _intervalSlide(_contentCtrl, 0.55, 1.00);

    // Loading bar — sweeps from 0→1 over total duration
    _barCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: _kTotalMs),
    )..forward();
    _barWidth = CurvedAnimation(parent: _barCtrl, curve: Curves.easeInOut);

    // Phase transition
    _timer = Timer(const Duration(milliseconds: _kPhase1Ms), _startPhase2);
    Timer(const Duration(milliseconds: _kTotalMs), _goToLogin);
  }

  Animation<double> _intervalFade(AnimationController ctrl, double b, double e) {
    return CurvedAnimation(
      parent: ctrl,
      curve: Interval(b, e, curve: Curves.easeOut),
    );
  }

  Animation<Offset> _intervalSlide(AnimationController ctrl, double b, double e) {
    return Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: ctrl,
      curve: Interval(b, e, curve: Curves.easeOut),
    ));
  }

  void _startPhase2() {
    if (!mounted) return;
    _contentCtrl.forward();
  }

  void _goToLogin() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, a, __) => const LoginScreen(),
        transitionsBuilder: (_, anim, __, child) {
          return FadeTransition(opacity: anim, child: child);
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _orbCtrl.dispose();
    _logoCtrl.dispose();
    _contentCtrl.dispose();
    _barCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        // Same gradient as dashboard
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [_kGradTop, _kGradMid, _kGradBot],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [

              // ── Floating orbs (decorative, blurred) ──────────────────────
              AnimatedBuilder(
                animation: _orbCtrl,
                builder: (_, __) => _OrbLayer(
                  progress: _orbCtrl.value,
                  size: size,
                ),
              ),

              // ── Main content ──────────────────────────────────────────────
              Positioned.fill(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [

                    // ── Logo card ───────────────────────────────────────────
                    AnimatedBuilder(
                      animation: _logoCtrl,
                      builder: (_, child) => Opacity(
                        opacity: _logoFade.value.clamp(0.0, 1.0),
                        child: Transform.scale(
                          scale: _logoScale.value,
                          child: child,
                        ),
                      ),
                      child: const _LogoCard(),
                    ),
                    const SizedBox(height: 40),

                    // ── Wordmark ────────────────────────────────────────────
                    SlideTransition(
                      position: _line1Slide,
                      child: FadeTransition(
                        opacity: _line1Fade,
                        child: ShaderMask(
                          blendMode: BlendMode.srcIn,
                          shaderCallback: (bounds) =>
                              const LinearGradient(
                            colors: [Color(0xFF1B1B1D), Color(0xFF3A1820)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ).createShader(bounds),
                          child: Text(
                            'BenGo',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 52,
                              fontWeight: FontWeight.w700,
                              color: _kInk,
                              letterSpacing: -2,
                              height: 1,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // ── Tagline ─────────────────────────────────────────────
                    SlideTransition(
                      position: _line2Slide,
                      child: FadeTransition(
                        opacity: _line2Fade,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: _kAccent.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(100),
                            border: Border.all(
                                color: _kAccent.withOpacity(0.18)),
                          ),
                          child: Text(
                            'MASTERY THROUGH FOCUS',
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 3.5,
                              color: _kAccent,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // ── Subtitle ────────────────────────────────────────────
                    SlideTransition(
                      position: _line3Slide,
                      child: FadeTransition(
                        opacity: _line3Fade,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 48),
                          child: Text(
                            'Smart daily revisions build stronger recall and keep every lesson sharp.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: _kMuted,
                              height: 1.65,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Loading bar at bottom ─────────────────────────────────────
              Positioned(
                bottom: 40,
                left: 40,
                right: 40,
                child: Column(
                  children: [
                    // Track
                    Container(
                      height: 3,
                      decoration: BoxDecoration(
                        color: _kAccent.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: AnimatedBuilder(
                        animation: _barWidth,
                        builder: (_, __) => FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: _barWidth.value,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFC41230), Color(0xFFFF6B6B)],
                              ),
                              borderRadius: BorderRadius.circular(100),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Preparing your path…',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: _kMuted,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Logo card — clean squircle with gradient ring ─────────────────────────────
class _LogoCard extends StatelessWidget {
  const _LogoCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 108,
      height: 108,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFFEDE9F4), width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x16000000),
            blurRadius: 32,
            offset: Offset(0, 14),
            spreadRadius: -4,
          ),
          BoxShadow(
            color: Color(0x30C41230),
            blurRadius: 20,
            offset: Offset(0, 6),
            spreadRadius: -6,
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ShaderMask(
              blendMode: BlendMode.srcIn,
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Color(0xFF1B1B1D), Color(0xFF3A1820)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ).createShader(bounds),
              child: Text(
                'Bg',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 40,
                  fontWeight: FontWeight.w700,
                  color: _kInk,
                  letterSpacing: -2.5,
                  height: 1,
                ),
              ),
            ),
            const SizedBox(height: 5),
            Container(
              width: 28,
              height: 3,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFC41230), Color(0xFFFF6B6B)],
                ),
                borderRadius: BorderRadius.circular(100),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Floating orb layer ────────────────────────────────────────────────────────
class _OrbLayer extends StatelessWidget {
  final double progress; // 0→1 repeating
  final Size size;
  const _OrbLayer({required this.progress, required this.size});

  @override
  Widget build(BuildContext context) {
    // Each orb drifts in a slow figure-8 using sin/cos offsets
    return Stack(
      children: [
        _Orb(
          progress: progress,
          baseX: size.width * 0.15,
          baseY: size.height * 0.18,
          driftAmp: 22,
          driftFreq: 1.0,
          diameter: 180,
          color: const Color(0xFFC41230),
          opacity: 0.07,
        ),
        _Orb(
          progress: progress,
          baseX: size.width * 0.82,
          baseY: size.height * 0.28,
          driftAmp: 18,
          driftFreq: 0.8,
          diameter: 140,
          color: const Color(0xFF7C3AED),
          opacity: 0.06,
        ),
        _Orb(
          progress: progress,
          baseX: size.width * 0.6,
          baseY: size.height * 0.72,
          driftAmp: 28,
          driftFreq: 1.2,
          diameter: 200,
          color: const Color(0xFFC41230),
          opacity: 0.05,
        ),
        _Orb(
          progress: progress,
          baseX: size.width * 0.25,
          baseY: size.height * 0.78,
          driftAmp: 14,
          driftFreq: 0.6,
          diameter: 120,
          color: const Color(0xFF6366F1),
          opacity: 0.05,
        ),
      ],
    );
  }
}

class _Orb extends StatelessWidget {
  final double progress;
  final double baseX;
  final double baseY;
  final double driftAmp;
  final double driftFreq;
  final double diameter;
  final Color color;
  final double opacity;

  const _Orb({
    required this.progress,
    required this.baseX,
    required this.baseY,
    required this.driftAmp,
    required this.driftFreq,
    required this.diameter,
    required this.color,
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    final t = progress * 2 * math.pi * driftFreq;
    final dx = driftAmp * math.sin(t);
    final dy = driftAmp * math.cos(t * 0.7);

    return Positioned(
      left: baseX - diameter / 2 + dx,
      top: baseY - diameter / 2 + dy,
      child: Container(
        width: diameter,
        height: diameter,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withOpacity(opacity),
        ),
        // Blur is expensive but small orbs at low opacity look fine without it
      ),
    );
  }
}
