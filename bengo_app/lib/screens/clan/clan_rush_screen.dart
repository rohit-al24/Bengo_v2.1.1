import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/clan_service.dart';
import 'clan_theme.dart';

class ClanRushScreen extends StatefulWidget {
  final Map<String, dynamic>? rush;
  const ClanRushScreen({super.key, this.rush});

  @override
  State<ClanRushScreen> createState() => _ClanRushScreenState();
}

class _ClanRushScreenState extends State<ClanRushScreen> {
  Map<String, dynamic>? _rush;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    if (widget.rush != null) {
      _rush = widget.rush;
      _loading = false;
    } else {
      _load();
    }
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      // Try to find any active rush (requires a clanId from navigation args or shared state)
      final rush = await ClanService.instance.fetchActiveRush(0); // 0 = search all
      if (mounted) setState(() {
        _rush = rush;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kClanBg,
      appBar: AppBar(
        backgroundColor: kClanBg,
        elevation: 0,
        leading: const BackButton(color: kClanInk),
        title: Text('Clan Rush', style: GoogleFonts.spaceGrotesk(fontSize: 18, fontWeight: FontWeight.w700, color: kClanInk)),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: kClanAccent))
            : _rush == null
                ? _NoRush()
                : _RushBody(rush: _rush!),
      ),
    );
  }
}

class _NoRush extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: ClanCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.bolt_outlined, size: 56, color: kClanMuted),
              const SizedBox(height: 16),
              Text('No Active Rush', style: GoogleFonts.spaceGrotesk(fontSize: 20, fontWeight: FontWeight.w700, color: kClanInk)),
              const SizedBox(height: 8),
              Text('Your clan leader or an admin can start a Rush at any time.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 13, color: kClanMuted, height: 1.5)),
            ],
          ),
        ),
      ),
    );
  }
}

class _RushBody extends StatelessWidget {
  final Map<String, dynamic> rush;
  const _RushBody({required this.rush});

  @override
  Widget build(BuildContext context) {
    final goal    = (rush['goal_points'] as num?)?.toDouble() ?? 1.0;
    final current = (rush['current_points'] as num?)?.toDouble() ?? 0.0;
    final pct     = goal > 0 ? (current / goal).clamp(0.0, 1.2) : 0.0;
    final status  = rush['status'] as String? ?? 'active';

    // Reward tiers
    final tiers = [
      _RushTier('Bronze', 0.50, kClanMuted,    Icons.military_tech_rounded),
      _RushTier('Silver', 0.75, const Color(0xFF9E9E9E), Icons.military_tech_rounded),
      _RushTier('Gold',   1.00, kClanGold,     Icons.emoji_events_rounded),
      _RushTier('Perfect',1.10, const Color(0xFF6A1B9A), Icons.auto_awesome_rounded),
    ];

    return RefreshIndicator(
      color: kClanAccent,
      backgroundColor: kClanSurface,
      onRefresh: () async {},
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          // ── Rush status card ──────────────────────────────────────────────
          ClanCard(
            color: const Color(0xFFFFF8F0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: kClanGold.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.bolt_rounded, color: kClanGold, size: 26),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(rush['name'] as String? ?? 'Clan Rush',
                          style: GoogleFonts.spaceGrotesk(fontSize: 16, fontWeight: FontWeight.w800, color: kClanInk)),
                        Text(status == 'active' ? 'In Progress' : status,
                          style: GoogleFonts.inter(fontSize: 12, color: kClanMuted)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: status == 'active' ? kClanGreen.withOpacity(0.1) : kClanBorder,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: status == 'active' ? kClanGreen.withOpacity(0.4) : kClanBorder),
                    ),
                    child: Text(status == 'active' ? 'LIVE' : status.toUpperCase(),
                      style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w800,
                        color: status == 'active' ? kClanGreen : kClanMuted)),
                  ),
                ]),
                const SizedBox(height: 20),
                // Big arc-style progress
                _CircularProgress(pct: pct, current: current.round(), goal: goal.round()),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Reward tiers ──────────────────────────────────────────────────
          const ClanSectionHeader(title: 'REWARD TIERS'),
          const SizedBox(height: 10),
          ...tiers.map((t) => _TierRow(tier: t, pct: pct)),
          const SizedBox(height: 16),

          // ── Contributors ──────────────────────────────────────────────────
          if ((rush['contributions'] as List?)?.isNotEmpty == true) ...[
            const ClanSectionHeader(title: 'TOP CONTRIBUTORS'),
            const SizedBox(height: 10),
            ...((rush['contributions'] as List).take(5).map((c) {
              final m = Map<String, dynamic>.from(c as Map);
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ClanCard(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Row(
                    children: [
                      CircleAvatar(radius: 16, backgroundColor: kClanAccentL,
                        child: Text((m['username'] as String? ?? '?')[0].toUpperCase(),
                          style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700, color: kClanAccent))),
                      const SizedBox(width: 10),
                      Expanded(child: Text(m['username'] as String? ?? '—',
                        style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: kClanInk))),
                      Text('${m['points_contributed'] ?? 0} pts',
                        style: GoogleFonts.spaceGrotesk(fontSize: 13, fontWeight: FontWeight.w700, color: kClanAccent)),
                    ],
                  ),
                ),
              );
            })),
          ],
        ],
      ),
    );
  }
}

class _RushTier {
  final String name;
  final double threshold; // as fraction of goal (0.5 = 50%)
  final Color color;
  final IconData icon;
  const _RushTier(this.name, this.threshold, this.color, this.icon);
}

class _TierRow extends StatelessWidget {
  final _RushTier tier;
  final double pct;
  const _TierRow({required this.tier, required this.pct});

  @override
  Widget build(BuildContext context) {
    final reached = pct >= tier.threshold;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ClanCard(
        color: reached ? tier.color.withOpacity(0.06) : kClanSurface,
        child: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: tier.color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(tier.icon, color: tier.color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tier.name,
                    style: GoogleFonts.spaceGrotesk(fontSize: 14, fontWeight: FontWeight.w700,
                      color: reached ? tier.color : kClanInk)),
                  Text('${(tier.threshold * 100).round()}% of goal',
                    style: GoogleFonts.inter(fontSize: 11, color: kClanMuted)),
                ],
              ),
            ),
            Icon(
              reached ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
              color: reached ? tier.color : kClanBorder,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

class _CircularProgress extends StatelessWidget {
  final double pct;
  final int current, goal;
  const _CircularProgress({required this.pct, required this.current, required this.goal});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 140, height: 140,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 140, height: 140,
                child: CircularProgressIndicator(
                  value: pct.clamp(0.0, 1.0),
                  backgroundColor: kClanBorder,
                  color: kClanGold,
                  strokeWidth: 12,
                  strokeCap: StrokeCap.round,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('${(pct * 100).toStringAsFixed(0)}%',
                    style: GoogleFonts.spaceGrotesk(fontSize: 28, fontWeight: FontWeight.w900, color: kClanInk)),
                  Text('$current / $goal',
                    style: GoogleFonts.inter(fontSize: 12, color: kClanMuted)),
                  Text('pts', style: GoogleFonts.inter(fontSize: 11, color: kClanMuted)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
