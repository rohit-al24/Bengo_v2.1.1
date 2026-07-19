import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'clan_theme.dart';

class MatchResultScreen extends StatefulWidget {
  final bool didWin;
  final int myCorrect;
  final int myWrong;
  final int myCombo;
  final int myBP;
  final int opponentBP;

  const MatchResultScreen({
    super.key,
    required this.didWin,
    required this.myCorrect,
    required this.myWrong,
    required this.myCombo,
    required this.myBP,
    required this.opponentBP,
  });

  @override
  State<MatchResultScreen> createState() => _MatchResultScreenState();
}

class _MatchResultScreenState extends State<MatchResultScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))
      ..forward();
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    _fade  = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accuracy = (widget.myCorrect + widget.myWrong) > 0
        ? (widget.myCorrect / (widget.myCorrect + widget.myWrong) * 100).round()
        : 0;

    return Scaffold(
      backgroundColor: kClanBg,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fade,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
            child: Column(
              children: [
                // ── Result badge ─────────────────────────────────────────────
                ScaleTransition(
                  scale: _scale,
                  child: _ResultBadge(didWin: widget.didWin),
                ),
                const SizedBox(height: 24),

                // ── BP comparison ─────────────────────────────────────────────
                ClanCard(
                  child: Column(
                    children: [
                      Text('Match Score',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 13, fontWeight: FontWeight.w700,
                          color: kClanMuted, letterSpacing: 0.8)),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _BPScore(label: 'You', bp: widget.myBP, isHighlighted: widget.didWin),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Text('vs',
                              style: GoogleFonts.inter(fontSize: 16, color: kClanMuted, fontWeight: FontWeight.w600)),
                          ),
                          _BPScore(label: 'Opponent', bp: widget.opponentBP, isHighlighted: !widget.didWin),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ── Performance stats ─────────────────────────────────────────
                ClanCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const ClanSectionHeader(title: 'PERFORMANCE'),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(child: _StatItem(
                            icon: Icons.check_circle_outline_rounded,
                            color: kClanGreen,
                            label: 'Correct',
                            value: widget.myCorrect.toString(),
                          )),
                          Expanded(child: _StatItem(
                            icon: Icons.cancel_outlined,
                            color: kClanRed,
                            label: 'Wrong',
                            value: widget.myWrong.toString(),
                          )),
                          Expanded(child: _StatItem(
                            icon: Icons.local_fire_department_rounded,
                            color: kClanGold,
                            label: 'Best Combo',
                            value: '×${widget.myCombo}',
                          )),
                          Expanded(child: _StatItem(
                            icon: Icons.percent_rounded,
                            color: const Color(0xFF1565C0),
                            label: 'Accuracy',
                            value: '$accuracy%',
                          )),
                        ],
                      ),
                      const SizedBox(height: 14),
                      ClanProgressBar(
                        value: accuracy / 100,
                        fillColor: accuracy >= 80 ? kClanGreen : accuracy >= 50 ? kClanGold : kClanRed,
                        label: 'Accuracy rate',
                      ),
                    ],
                  ),
                ),
                const Spacer(),

                // ── Actions ───────────────────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: ClanPillButton(
                    label: 'Back to Clan',
                    icon: Icons.home_rounded,
                    onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ClanPillButton(
                    label: 'Duel Again',
                    icon: Icons.sports_martial_arts_rounded,
                    isOutlined: true,
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ResultBadge extends StatelessWidget {
  final bool didWin;
  const _ResultBadge({required this.didWin});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 96, height: 96,
          decoration: BoxDecoration(
            color: didWin ? const Color(0xFFE8F5E9) : kClanAccentL,
            shape: BoxShape.circle,
            border: Border.all(
              color: didWin ? kClanGreen : kClanRed,
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: (didWin ? kClanGreen : kClanRed).withOpacity(0.25),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Icon(
            didWin ? Icons.emoji_events_rounded : Icons.sports_martial_arts_rounded,
            color: didWin ? kClanGreen : kClanRed,
            size: 48,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          didWin ? 'Victory!' : 'Defeated',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 32, fontWeight: FontWeight.w900,
            color: didWin ? kClanGreen : kClanRed,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          didWin ? 'You dominated the duel!' : 'Keep practicing — you\'ll get them next time.',
          style: GoogleFonts.inter(fontSize: 13, color: kClanMuted),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _BPScore extends StatelessWidget {
  final String label;
  final int bp;
  final bool isHighlighted;
  const _BPScore({required this.label, required this.bp, required this.isHighlighted});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(bp.toString(),
          style: GoogleFonts.spaceGrotesk(
            fontSize: 40, fontWeight: FontWeight.w900,
            color: isHighlighted ? kClanAccent : kClanMuted,
          )),
        Text('BP', style: GoogleFonts.inter(fontSize: 11, color: kClanMuted, fontWeight: FontWeight.w600)),
        const SizedBox(height: 2),
        Text(label, style: GoogleFonts.inter(fontSize: 13, color: kClanInk, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label, value;
  const _StatItem({required this.icon, required this.color, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 4),
        Text(value, style: GoogleFonts.spaceGrotesk(fontSize: 18, fontWeight: FontWeight.w800, color: kClanInk)),
        Text(label, style: GoogleFonts.inter(fontSize: 10, color: kClanMuted), textAlign: TextAlign.center),
      ],
    );
  }
}
