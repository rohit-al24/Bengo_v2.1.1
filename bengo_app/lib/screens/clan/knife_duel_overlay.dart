import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'clan_theme.dart';

/// 8-phase Attack Sequence Cinematic
/// Phase 0: Forge & Target (pre-open)
/// Phase 1: Global Pause + held-breath
/// Phase 2: Blurred popup overlay zoom in
/// Phase 3: Avatar face-off medallions with dolly-zoom
/// Phase 4: Knife streak across screen
/// Phase 5: Defender decision window (countdown ring + Shield/Accept)
/// Phase 6A: Shield barrier bloom or glass-shatter
/// Phase 6B: Frame-crack hit resolution
/// Phase 7: Ink-stamp result
/// Phase 8: Resume countdown + unfade
class KnifeDuelOverlay extends StatefulWidget {
  final String attackerName;
  final String defenderName;
  final void Function(bool blocked) onComplete;

  const KnifeDuelOverlay({
    super.key,
    required this.attackerName,
    required this.defenderName,
    required this.onComplete,
  });

  @override
  State<KnifeDuelOverlay> createState() => _KnifeDuelOverlayState();
}

class _KnifeDuelOverlayState extends State<KnifeDuelOverlay>
    with TickerProviderStateMixin {
  int _phase = 1;
  bool _blocked = false;

  // Phase controllers
  late AnimationController _popupCtrl;    // phase 2: popup zoom
  late AnimationController _knifeCtrl;    // phase 4: knife streak
  late AnimationController _decisionCtrl; // phase 5: countdown ring
  late AnimationController _resultCtrl;   // phase 7: stamp
  late AnimationController _resumeCtrl;   // phase 8: fade out
  late AnimationController _breathCtrl;   // idle medallion breathing
  late AnimationController _barrierCtrl;  // phase 6A: barrier bloom

  late Animation<double> _popupScale;
  late Animation<double> _knifeX;
  late Animation<double> _stampScale;
  late Animation<double> _breath;
  late Animation<double> _barrierRadius;
  late Animation<double> _decisionRing;

  @override
  void initState() {
    super.initState();

    _popupCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _popupScale = Tween<double>(begin: 0.6, end: 1.0).animate(
        CurvedAnimation(parent: _popupCtrl, curve: Curves.easeOutBack));

    _knifeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _knifeX = Tween<double>(begin: -1.0, end: 1.5).animate(
        CurvedAnimation(parent: _knifeCtrl, curve: Curves.easeIn));

    _decisionCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 10));
    _decisionRing = Tween<double>(begin: 1.0, end: 0.0).animate(_decisionCtrl);

    _resultCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _stampScale = Tween<double>(begin: 2.0, end: 1.0).animate(
        CurvedAnimation(parent: _resultCtrl, curve: Curves.easeOut));

    _resumeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));

    _breathCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
    _breath = Tween<double>(begin: 1.0, end: 1.03).animate(
        CurvedAnimation(parent: _breathCtrl, curve: Curves.easeInOut));

    _barrierCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _barrierRadius = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _barrierCtrl, curve: Curves.easeOut));

    _startSequence();
  }

  void _startSequence() async {
    // Phase 1: pause already felt by opening overlay
    await Future.delayed(const Duration(milliseconds: 300));
    // Phase 2: popup zoom in
    setState(() => _phase = 2);
    _popupCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 500));
    // Phase 3: face-off (avatars already shown in phase 2+)
    setState(() => _phase = 3);
    await Future.delayed(const Duration(milliseconds: 800));
    // Phase 4: knife streak
    setState(() => _phase = 4);
    _knifeCtrl.forward();
    HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 700));
    // Phase 5: defender decision
    setState(() => _phase = 5);
    _decisionCtrl.forward();
    // Auto-timeout at 10 seconds
    _decisionCtrl.addStatusListener((s) {
      if (s == AnimationStatus.completed && _phase == 5) {
        _onDefend(false); // auto-accept on timeout
      }
    });
  }

  void _onDefend(bool shielded) async {
    if (_phase != 5) return;
    _decisionCtrl.stop();
    HapticFeedback.mediumImpact();

    setState(() {
      _blocked = shielded;
      _phase = shielded ? 6 : 7;
    });

    if (shielded) {
      _barrierCtrl.forward();
      await Future.delayed(const Duration(milliseconds: 500));
    }

    // Phase 7: stamp
    setState(() => _phase = 7);
    _resultCtrl.forward();
    HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 1200));

    // Phase 8: resume
    setState(() => _phase = 8);
    _resumeCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) {
      Navigator.pop(context);
      widget.onComplete(_blocked);
    }
  }

  @override
  void dispose() {
    _popupCtrl.dispose();
    _knifeCtrl.dispose();
    _decisionCtrl.dispose();
    _resultCtrl.dispose();
    _resumeCtrl.dispose();
    _breathCtrl.dispose();
    _barrierCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return AnimatedBuilder(
      animation: Listenable.merge([_popupCtrl, _knifeCtrl, _resultCtrl, _resumeCtrl]),
      builder: (_, __) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.zero,
          child: Stack(
            children: [
              // Background blur / dim
              GestureDetector(
                onTap: () {}, // prevent dismiss
                child: Container(
                  width: size.width,
                  height: size.height,
                  color: Colors.black.withOpacity(0.85),
                ),
              ),
              // Main popup card
              Center(
                child: ScaleTransition(
                  scale: _popupScale,
                  child: Container(
                    width: size.width * 0.9,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1A0A0A), Color(0xFF0D0D1A)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: _blocked
                            ? const Color(0xFF3B82F6).withOpacity(0.5)
                            : const Color(0xFFEB4B6E).withOpacity(0.5),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (_blocked
                                  ? const Color(0xFF3B82F6)
                                  : const Color(0xFFEB4B6E))
                              .withOpacity(0.2),
                          blurRadius: 40,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Phase label
                        _buildPhaseLabel(),
                        const SizedBox(height: 20),
                        // Avatars face-off
                        _buildFaceOff(),
                        const SizedBox(height: 20),
                        // Knife streak (phase 4)
                        if (_phase >= 4 && _phase <= 5) _buildKnifeStreak(size),
                        // Barrier (phase 6A)
                        if (_phase == 6) _buildBarrierBloom(),
                        // Hit crack (phase 7 unblocked)
                        if (_phase == 7 && !_blocked) _buildHitCrack(),
                        // Decision buttons (phase 5)
                        if (_phase == 5) _buildDecisionButtons(),
                        // Result stamp (phase 7+)
                        if (_phase >= 7) _buildResultStamp(),
                        // Resume (phase 8)
                        if (_phase == 8) _buildResumeIndicator(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPhaseLabel() {
    final labels = {
      1: '⏸️ Battle Paused',
      2: '⚔️ Knife Attack!',
      3: '⚔️ Knife Attack!',
      4: '🗡️ Strike Incoming!',
      5: '🛡️ Defend Yourself!',
      6: '🛡️ Shield Activated!',
      7: _blocked ? '✅ BLOCKED!' : '💥 STRUCK!',
      8: '▶️ Resuming...',
    };
    return Text(
      labels[_phase] ?? '',
      style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: Colors.white54,
          letterSpacing: 1),
    );
  }

  Widget _buildFaceOff() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildMedallion(widget.attackerName, const Color(0xFFEB4B6E), '⚔️', isAttacker: true),
        // VS divider
        Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white12),
              ),
              child: Text('VS',
                  style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: Colors.white38)),
            ),
            Container(
                width: 1, height: 40, color: Colors.white12),
          ],
        ),
        _buildMedallion(widget.defenderName, const Color(0xFF3B82F6), '🛡️', isAttacker: false),
      ],
    );
  }

  Widget _buildMedallion(String name, Color color, String icon, {required bool isAttacker}) {
    return AnimatedBuilder(
      animation: _breath,
      builder: (_, __) {
        final isDamaged = _phase >= 7 && !_blocked && !isAttacker;
        return Transform.scale(
          scale: _breath.value,
          child: Column(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [color.withOpacity(0.3), color.withOpacity(0.1)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(
                    color: isDamaged ? Colors.red : color,
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (isDamaged ? Colors.red : color).withOpacity(0.4),
                      blurRadius: 16,
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Text(icon, style: const TextStyle(fontSize: 32)),
                    if (isDamaged)
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.red.withOpacity(0.3),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(name,
                  style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white70)),
              if (isDamaged)
                Text('-150 BP',
                    style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.red)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildKnifeStreak(Size size) {
    return AnimatedBuilder(
      animation: _knifeX,
      builder: (_, __) {
        return SizedBox(
          height: 40,
          child: Stack(
            children: [
              Positioned(
                left: (_knifeX.value + 1) / 2.5 * (size.width * 0.9),
                top: 10,
                child: Transform.rotate(
                  angle: 0.3,
                  child: Row(
                    children: [
                      // Motion trail
                      Container(
                        width: 40,
                        height: 3,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              const Color(0xFFEB4B6E).withOpacity(0.5),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const Text('🗡️', style: TextStyle(fontSize: 22)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBarrierBloom() {
    return AnimatedBuilder(
      animation: _barrierRadius,
      builder: (_, __) {
        return SizedBox(
          height: 60,
          child: Center(
            child: Container(
              width: 80 * _barrierRadius.value,
              height: 80 * _barrierRadius.value,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.blue.withOpacity(0.3 * (1 - _barrierRadius.value)),
                border: Border.all(
                  color: Colors.blue.withOpacity(0.8 * (1 - _barrierRadius.value)),
                  width: 2,
                ),
              ),
              child: _barrierRadius.value > 0.5
                  ? Center(
                      child: Text('🛡️',
                          style: TextStyle(
                              fontSize: 28 * _barrierRadius.value)))
                  : null,
            ),
          ),
        );
      },
    );
  }

  Widget _buildHitCrack() {
    return Container(
      height: 40,
      child: Center(
        child: Text(
          '💥',
          style: TextStyle(
              fontSize: 36 * _resultCtrl.value.clamp(0.3, 1.0)),
        ),
      ),
    );
  }

  Widget _buildDecisionButtons() {
    return Column(
      children: [
        // Countdown ring
        AnimatedBuilder(
          animation: _decisionRing,
          builder: (_, __) {
            return SizedBox(
              width: 60,
              height: 60,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: _decisionRing.value,
                    backgroundColor: Colors.white10,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFF3B82F6)),
                    strokeWidth: 5,
                  ),
                  Text(
                    '${(_decisionRing.value * 10).ceil()}',
                    style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => _onDefend(true),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: const Color(0xFF3B82F6).withOpacity(0.5)),
                  ),
                  child: Center(
                    child: Text('🛡️  Shield',
                        style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF3B82F6))),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: GestureDetector(
                onTap: () => _onDefend(false),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Center(
                    child: Text('Accept Hit',
                        style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white38)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildResultStamp() {
    return ScaleTransition(
      scale: _stampScale,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(
            color: _blocked ? const Color(0xFF3B82F6) : Colors.red,
            width: 3,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          _blocked ? 'BLOCKED' : 'STRUCK',
          style: GoogleFonts.inter(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: _blocked ? const Color(0xFF3B82F6) : Colors.red,
            letterSpacing: 4,
          ),
        ),
      ),
    );
  }

  Widget _buildResumeIndicator() {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Text(
        'Resuming battle...',
        style: GoogleFonts.inter(fontSize: 12, color: Colors.white38),
      ),
    );
  }
}
