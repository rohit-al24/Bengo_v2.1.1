import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'roleplay_models.dart';

const _kAccent = Color(0xFFC41230);
const _kInk    = Color(0xFF1B1B1D);
const _kMuted  = Color(0xFF8A8A8F);

class RolePlayResultScreen extends StatefulWidget {
  final RolePlayResult result;
  const RolePlayResultScreen({super.key, required this.result});

  @override
  State<RolePlayResultScreen> createState() => _RolePlayResultScreenState();
}

class _RolePlayResultScreenState extends State<RolePlayResultScreen>
    with TickerProviderStateMixin {
  late AnimationController _entryCtrl;
  late AnimationController _ringCtrl;
  late AnimationController _confettiCtrl;
  late Animation<double> _entryScale;
  late Animation<double> _entryOpacity;

  @override
  void initState() {
    super.initState();

    _entryCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _entryScale = Tween<double>(begin: 0.6, end: 1.0).animate(
        CurvedAnimation(parent: _entryCtrl, curve: Curves.elasticOut));
    _entryOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut));

    _ringCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));

    _confettiCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 3));

    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        _entryCtrl.forward();
        _ringCtrl.forward();
        _confettiCtrl.forward();
      }
    });
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _ringCtrl.dispose();
    _confettiCtrl.dispose();
    super.dispose();
  }

  double get _accuracy {
    if (widget.result.lines.isEmpty) return 0;
    final correct = widget.result.lines.where((l) => l.correct).length;
    return correct / widget.result.lines.length;
  }

  int get _correctCount => widget.result.lines.where((l) => l.correct).length;
  int get _skippedCount => widget.result.lines.where((l) => !l.correct).length;

  double get _avgScore {
    if (widget.result.lines.isEmpty) return 0;
    return widget.result.lines.map((l) => l.score).reduce((a, b) => a + b) /
        widget.result.lines.length;
  }

  String _formatElapsed(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '${m}m ${s}s';
  }

  int get _xpEarned => (_correctCount * 15 + _accuracy * 50).toInt();
  int get _coinsEarned => (_correctCount * 5 + _accuracy * 20).toInt();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FD),
      body: SafeArea(
        child: Stack(
          children: [
            _ConfettiLayer(controller: _confettiCtrl),
            SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
              child: AnimatedBuilder(
                animation: _entryCtrl,
                builder: (_, child) => Opacity(
                  opacity: _entryOpacity.value,
                  child: Transform.scale(scale: _entryScale.value, child: child),
                ),
                child: Column(
                  children: [
                    _buildTrophyHeader(),
                    const SizedBox(height: 24),
                    _buildAccuracyRing(),
                    const SizedBox(height: 24),
                    _buildStatsGrid(),
                    const SizedBox(height: 20),
                    _buildRewards(),
                    const SizedBox(height: 20),
                    _buildAchievements(),
                    const SizedBox(height: 28),
                    _buildActions(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrophyHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1B1B1D), Color(0xFF8B0D21)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: _kAccent.withOpacity(0.35),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            _accuracy >= 0.8 ? '🏆' : _accuracy >= 0.6 ? '🥈' : '🥉',
            style: const TextStyle(fontSize: 52),
          ),
          const SizedBox(height: 8),
          Text(
            _accuracy >= 0.8
                ? 'Excellent!'
                : _accuracy >= 0.6
                    ? 'Good Job!'
                    : 'Keep Practicing!',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${widget.result.storyEmoji}  ${widget.result.storyTitle}',
            style: GoogleFonts.inter(fontSize: 14, color: Colors.white60),
          ),
        ],
      ),
    );
  }

  Widget _buildAccuracyRing() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: _ringCtrl,
            builder: (_, __) {
              final animated = _ringCtrl.value * _accuracy;
              return SizedBox(
                width: 100,
                height: 100,
                child: CustomPaint(
                  painter: _RingPainter(value: animated),
                  child: Center(
                    child: Text(
                      '${(_ringCtrl.value * _accuracy * 100).toInt()}%',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: _kAccent,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Conversation Accuracy',
                    style: GoogleFonts.inter(
                        fontSize: 13, fontWeight: FontWeight.w700, color: _kInk)),
                const SizedBox(height: 12),
                _AccuracyRow('✅ Correct',
                    '$_correctCount sentences', const Color(0xFF4CAF50)),
                const SizedBox(height: 6),
                _AccuracyRow('⏭ Skipped',
                    '$_skippedCount sentences', Colors.orange),
                const SizedBox(height: 6),
                _AccuracyRow('⏱ Duration',
                    _formatElapsed(widget.result.elapsed), const Color(0xFF667eea)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    final stats = [
      ('📊', 'Avg Score',  '${(_avgScore * 100).toInt()}%'),
      ('🎯', 'Accuracy',   '${(_accuracy * 100).toInt()}%'),
      ('✅', 'Correct',    '$_correctCount'),
      ('⏭', 'Skipped',    '$_skippedCount'),
    ];
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 2.0,
      children: stats.map((s) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Text(s.$1, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(s.$3,
                      style: GoogleFonts.spaceGrotesk(
                          fontSize: 18, fontWeight: FontWeight.w800, color: _kAccent)),
                  Text(s.$2,
                      style: GoogleFonts.inter(fontSize: 10, color: _kMuted)),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRewards() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [Color(0xFFFFF8E1), Color(0xFFFFF3CD)]),
        borderRadius: BorderRadius.circular(22),
        border:
            Border.all(color: const Color(0xFFFFD700).withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _RewardPill('⚡', '$_xpEarned XP'),
          Container(
              width: 1,
              height: 40,
              color: const Color(0xFFFFD700).withOpacity(0.3)),
          _RewardPill('🪙', '$_coinsEarned Coins'),
        ],
      ),
    );
  }

  Widget _buildAchievements() {
    final achievements = [
      if (_accuracy >= 0.9) ('🌟', 'Perfect Score'),
      if (_skippedCount == 0) ('🔥', 'No Skips'),
      if (widget.result.elapsed.inMinutes < 5) ('⚡', 'Speed Run'),
      ('🎭', 'Role Player'),
    ];
    if (achievements.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('🏅 Achievements',
            style: GoogleFonts.inter(
                fontSize: 13, fontWeight: FontWeight.w700, color: _kInk)),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: achievements.map((a) {
              return Container(
                margin: const EdgeInsets.only(right: 10),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF5F7),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _kAccent.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Text(a.$1, style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: 6),
                    Text(a.$2,
                        style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: _kAccent)),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildActions() {
    return Column(
      children: [
        GestureDetector(
          onTap: () => Navigator.of(context).popUntil((r) => r.isFirst),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Color(0xFFEB4B6E), Color(0xFFBF1B2C)]),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: _kAccent.withOpacity(0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Center(
              child: Text('🏠 Back to RolePlay',
                  style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white)),
            ),
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFEDE9F4)),
            ),
            child: Center(
              child: Text('🔁 Replay Conversation',
                  style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: _kInk)),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Helpers ────────────────────────────────────────────────────────────────────
class _AccuracyRow extends StatelessWidget {
  final String label, value;
  final Color color;
  const _AccuracyRow(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: GoogleFonts.inter(fontSize: 12, color: _kMuted)),
        Text(value,
            style: GoogleFonts.inter(
                fontSize: 12, fontWeight: FontWeight.w700, color: color)),
      ],
    );
  }
}

class _RewardPill extends StatelessWidget {
  final String emoji, label;
  const _RewardPill(this.emoji, this.label);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 28)),
        const SizedBox(height: 4),
        Text(label,
            style: GoogleFonts.spaceGrotesk(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF92400E))),
      ],
    );
  }
}

// ── Ring chart ─────────────────────────────────────────────────────────────────
class _RingPainter extends CustomPainter {
  final double value;
  const _RingPainter({required this.value});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 8;
    const strokeWidth = 8.0;

    final bgPaint = Paint()
      ..color = const Color(0xFFF3F4F6)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fgPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFEB4B6E), Color(0xFFBF1B2C)],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * value,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.value != value;
}

// ── Confetti ───────────────────────────────────────────────────────────────────
class _ConfettiLayer extends StatelessWidget {
  final AnimationController controller;
  const _ConfettiLayer({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        if (controller.value > 0.8) return const SizedBox.shrink();
        return IgnorePointer(
          child: CustomPaint(
            painter: _ConfettiPainter(progress: controller.value, seed: 42),
            size: MediaQuery.of(context).size,
          ),
        );
      },
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  final double progress;
  final int seed;
  const _ConfettiPainter({required this.progress, required this.seed});

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(seed);
    final colors = [
      const Color(0xFFEB4B6E), const Color(0xFFFFBE0B),
      const Color(0xFF4ECDC4), const Color(0xFF667eea), const Color(0xFF43e97b),
    ];
    for (int i = 0; i < 50; i++) {
      final x = rng.nextDouble() * size.width;
      final y = -20.0 + (size.height * 1.2) * progress;
      final offset = math.sin(progress * math.pi * 2 + i) * 30;
      final paint = Paint()
        ..color = colors[i % colors.length].withOpacity(1 - progress)
        ..style = PaintingStyle.fill;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(x + offset, y), width: 8, height: 10),
          const Radius.circular(2),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.progress != progress;
}
