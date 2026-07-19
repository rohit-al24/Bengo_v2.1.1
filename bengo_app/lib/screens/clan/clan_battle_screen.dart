import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'clan_theme.dart';
import 'adrenaline_duel_screen.dart';

class ClanBattleScreen extends StatelessWidget {
  const ClanBattleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kClanBg,
      appBar: AppBar(
        backgroundColor: kClanBg,
        elevation: 0,
        leading: const BackButton(color: kClanInk),
        title: Text('Battle Arena',
          style: GoogleFonts.spaceGrotesk(fontSize: 18, fontWeight: FontWeight.w700, color: kClanInk)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            // ── Rush Battle highlight ─────────────────────────────────────────
            _BattleTypeCard(
              icon: Icons.bolt_rounded,
              iconColor: kClanGold,
              title: 'Rush Battle',
              subtitle: 'Active clan event · Earn 2× Rush points',
              badge: '2× Rush',
              badgeColor: kClanGold,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdrenalineDuelScreen())),
            ),
            const SizedBox(height: 12),

            // ── Standard modes ────────────────────────────────────────────────
            const ClanSectionHeader(title: 'BATTLE MODES'),
            const SizedBox(height: 10),
            _BattleTypeCard(
              icon: Icons.sports_martial_arts_rounded,
              iconColor: kClanAccent,
              title: 'Adrenaline Duel',
              subtitle: 'Tug-of-war BP bar · Real questions · Combos & Shields',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdrenalineDuelScreen())),
            ),
            const SizedBox(height: 10),
            _BattleTypeCard(
              icon: Icons.group_rounded,
              iconColor: const Color(0xFF1565C0),
              title: 'Clan War',
              subtitle: 'Coordinated clan-vs-clan campaign',
              comingSoon: true,
              onTap: () {},
            ),
            const SizedBox(height: 10),
            _BattleTypeCard(
              icon: Icons.flash_on_rounded,
              iconColor: const Color(0xFF2E7D32),
              title: 'Speed Round',
              subtitle: 'Race against the clock — most right answers wins',
              comingSoon: true,
              onTap: () {},
            ),
            const SizedBox(height: 10),
            _BattleTypeCard(
              icon: Icons.casino_rounded,
              iconColor: const Color(0xFF6A1B9A),
              title: 'Sudden Death',
              subtitle: 'One wrong answer ends it all',
              comingSoon: true,
              onTap: () {},
            ),
            const SizedBox(height: 24),

            // ── Recent battles ────────────────────────────────────────────────
            const ClanSectionHeader(title: 'BATTLE RULES'),
            const SizedBox(height: 10),
            ClanCard(
              child: Column(
                children: const [
                  _RuleRow(icon: Icons.timer_rounded, text: 'Admin-set global timer — when it ends, higher BP wins'),
                  Divider(color: kClanBorder, height: 1),
                  _RuleRow(icon: Icons.local_fire_department_rounded, text: 'Build combos by answering correctly in a row'),
                  Divider(color: kClanBorder, height: 1),
                  _RuleRow(icon: Icons.shield_rounded, text: 'Combo ×3+ lets you block attacks with a Shield'),
                  Divider(color: kClanBorder, height: 1),
                  _RuleRow(icon: Icons.bolt_rounded, text: 'High combos trigger automatic steals from the opponent'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BattleTypeCard extends StatefulWidget {
  final IconData icon;
  final Color iconColor;
  final String title, subtitle;
  final String? badge;
  final Color? badgeColor;
  final bool comingSoon;
  final VoidCallback onTap;

  const _BattleTypeCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.badge,
    this.badgeColor,
    this.comingSoon = false,
    required this.onTap,
  });

  @override
  State<_BattleTypeCard> createState() => _BattleTypeCardState();
}

class _BattleTypeCardState extends State<_BattleTypeCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) { setState(() => _pressed = false); if (!widget.comingSoon) widget.onTap(); },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: kClanSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kClanBorder, width: 1),
          boxShadow: _pressed ? [] : kRaisedShadow,
        ),
        child: Row(
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: widget.iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(13),
                border: Border.all(color: widget.iconColor.withOpacity(0.2)),
              ),
              child: Icon(widget.icon, color: widget.iconColor, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(widget.title,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 15, fontWeight: FontWeight.w700, color: kClanInk)),
                      if (widget.badge != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: (widget.badgeColor ?? kClanAccent).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(widget.badge!,
                            style: GoogleFonts.inter(
                              fontSize: 10, fontWeight: FontWeight.w800,
                              color: widget.badgeColor ?? kClanAccent)),
                        ),
                      ],
                      if (widget.comingSoon) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: kClanBorder,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text('Soon',
                            style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: kClanMuted)),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(widget.subtitle,
                    style: GoogleFonts.inter(fontSize: 12, color: kClanMuted, height: 1.4)),
                ],
              ),
            ),
            if (!widget.comingSoon)
              Icon(Icons.chevron_right_rounded, color: kClanMuted, size: 22),
          ],
        ),
      ),
    );
  }
}

class _RuleRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _RuleRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 16, color: kClanAccent),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: GoogleFonts.inter(fontSize: 13, color: kClanInk, height: 1.4))),
        ],
      ),
    );
  }
}
