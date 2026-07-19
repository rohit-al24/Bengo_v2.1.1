import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/clan_service.dart';
import '../../services/api_service.dart';
import 'clan_theme.dart';
import 'clan_battle_screen.dart';
import 'clan_rush_screen.dart';
import 'clan_leaderboard_screen.dart';
import 'clan_chat_screen.dart';
import 'clan_settings_screen.dart';
import 'clan_join_screen.dart';
import 'clan_creation_screen.dart';

class ClanHomeScreen extends StatefulWidget {
  const ClanHomeScreen({super.key});
  @override
  State<ClanHomeScreen> createState() => _ClanHomeScreenState();
}

class _ClanHomeScreenState extends State<ClanHomeScreen> with SingleTickerProviderStateMixin {
  Map<String, dynamic>? _clan;
  Map<String, dynamic>? _rush;
  List<Map<String, dynamic>> _members = [];
  bool _loading = true;
  String? _error;

  late final AnimationController _shimmerCtrl;

  @override
  void initState() {
    super.initState();
    _shimmerCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat();
    _load();
  }

  @override
  void dispose() {
    _shimmerCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final clan = await ClanService.instance.fetchMyClan();
      if (clan == null) {
        if (mounted) setState(() { _clan = null; _loading = false; });
        return;
      }
      final rush = await ClanService.instance.fetchActiveRush(clan['id'] as int);
      final members = await ClanService.instance.fetchClanMembers(clan['id'] as int);
      if (mounted) setState(() {
        _clan = clan;
        _rush = rush;
        _members = members;
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kClanBg,
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: kClanAccent))
            : _error != null
                ? _ErrorView(error: _error!, onRetry: _load)
                : _clan == null
                    ? _NoClanView()
                    : _ClanHomeBody(
                        clan: _clan!,
                        rush: _rush,
                        members: _members,
                        onRefresh: _load,
                      ),
      ),
    );
  }
}

// ── No clan view ──────────────────────────────────────────────────────────────

class _NoClanView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ClanCard(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                const Icon(Icons.shield_outlined, size: 64, color: kClanMuted),
                const SizedBox(height: 16),
                Text('No Clan Yet',
                  style: GoogleFonts.spaceGrotesk(fontSize: 22, fontWeight: FontWeight.w700, color: kClanInk)),
                const SizedBox(height: 8),
                Text('Join an existing clan or create your own to start competing.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(fontSize: 14, color: kClanMuted, height: 1.5)),
                const SizedBox(height: 24),
                ClanPillButton(
                  label: 'Browse & Join',
                  icon: Icons.search_rounded,
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ClanJoinScreen())),
                ),
                const SizedBox(height: 12),
                ClanPillButton(
                  label: 'Create a Clan',
                  icon: Icons.add_rounded,
                  isOutlined: true,
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ClanCreationScreen())),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Error view ────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ClanCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off_rounded, size: 48, color: kClanMuted),
              const SizedBox(height: 12),
              Text('Could not load clan data', style: GoogleFonts.spaceGrotesk(fontSize: 16, fontWeight: FontWeight.w700, color: kClanInk)),
              const SizedBox(height: 8),
              Text(error, textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 12, color: kClanMuted)),
              const SizedBox(height: 16),
              ClanPillButton(label: 'Retry', icon: Icons.refresh_rounded, onPressed: onRetry),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Main body ─────────────────────────────────────────────────────────────────

class _ClanHomeBody extends StatelessWidget {
  final Map<String, dynamic> clan;
  final Map<String, dynamic>? rush;
  final List<Map<String, dynamic>> members;
  final VoidCallback onRefresh;

  const _ClanHomeBody({
    required this.clan,
    required this.rush,
    required this.members,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final clanName    = clan['name'] as String? ?? '—';
    final clanTag     = clan['tag'] as String? ?? '';
    final trophies    = clan['trophies'] ?? 0;
    final memberCount = clan['member_count'] ?? 0;
    final slotsTotal  = clan['slots_unlocked'] ?? 10;
    final privacy     = clan['privacy'] as String? ?? 'open';

    return RefreshIndicator(
      color: kClanAccent,
      backgroundColor: kClanSurface,
      onRefresh: () async => onRefresh(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          // ── Header ──────────────────────────────────────────────────────
          _ClanHeader(
            name: clanName,
            tag: clanTag,
            trophies: trophies.toString(),
            memberCount: memberCount,
            slotsTotal: slotsTotal,
            privacy: privacy,
            onSettings: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => ClanSettingsScreen(clan: clan, members: members))),
          ),
          const SizedBox(height: 16),

          // ── Active Rush banner ───────────────────────────────────────────
          if (rush != null) ...[
            _RushBanner(rush: rush!,
              onTap: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => ClanRushScreen(rush: rush!)))),
            const SizedBox(height: 16),
          ],

          // ── Quick actions grid ───────────────────────────────────────────
          const ClanSectionHeader(title: 'QUICK ACTIONS'),
          const SizedBox(height: 10),
          _QuickActionsGrid(clan: clan),
          const SizedBox(height: 20),

          // ── Members ──────────────────────────────────────────────────────
          ClanSectionHeader(
            title: 'MEMBERS  ·  $memberCount / $slotsTotal',
            trailing: TextButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => ClanLeaderboardScreen(clanId: clan['id'] as int))),
              child: Text('See All', style: GoogleFonts.inter(fontSize: 12, color: kClanAccent, fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(height: 10),
          ...members.take(5).map((m) => _MemberRow(member: m)),
        ],
      ),
    );
  }
}

// ── Clan header card ──────────────────────────────────────────────────────────

class _ClanHeader extends StatelessWidget {
  final String name, tag, trophies, privacy;
  final int memberCount, slotsTotal;
  final VoidCallback onSettings;

  const _ClanHeader({
    required this.name, required this.tag, required this.trophies,
    required this.memberCount, required this.slotsTotal,
    required this.privacy, required this.onSettings,
  });

  @override
  Widget build(BuildContext context) {
    return ClanCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              // Clan crest
              Container(
                width: 56, height: 56,
                decoration: BoxDecoration(
                  color: kClanAccentL,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: kClanBorder, width: 1.5),
                  boxShadow: kRaisedShadow,
                ),
                child: const Center(child: Icon(Icons.shield_rounded, color: kClanAccent, size: 30)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(name, style: GoogleFonts.spaceGrotesk(fontSize: 18, fontWeight: FontWeight.w800, color: kClanInk)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: kClanBorder,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text('#$tag', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: kClanMuted)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.emoji_events_rounded, size: 14, color: kClanGold),
                        const SizedBox(width: 3),
                        Text('$trophies trophies', style: GoogleFonts.inter(fontSize: 12, color: kClanMuted)),
                        const SizedBox(width: 10),
                        Icon(_privacyIcon(privacy), size: 13, color: kClanMuted),
                        const SizedBox(width: 3),
                        Text(privacy, style: GoogleFonts.inter(fontSize: 12, color: kClanMuted)),
                      ],
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: onSettings,
                child: Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: kClanBorder.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: kClanBorder),
                  ),
                  child: const Icon(Icons.settings_rounded, size: 18, color: kClanMuted),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClanProgressBar(
            value: memberCount / slotsTotal,
            fillColor: kClanAccent,
            label: 'Member slots  $memberCount / $slotsTotal',
          ),
        ],
      ),
    );
  }

  IconData _privacyIcon(String p) {
    switch (p) {
      case 'open': return Icons.lock_open_rounded;
      case 'invite_only': return Icons.mail_outlined;
      default: return Icons.lock_rounded;
    }
  }
}

// ── Rush banner ───────────────────────────────────────────────────────────────

class _RushBanner extends StatelessWidget {
  final Map<String, dynamic> rush;
  final VoidCallback onTap;
  const _RushBanner({required this.rush, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final goal     = (rush['goal_points'] as num?)?.toDouble() ?? 1.0;
    final current  = (rush['current_points'] as num?)?.toDouble() ?? 0.0;
    final pct      = goal > 0 ? (current / goal) : 0.0;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFF8F0), Color(0xFFFFF3E0)],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kClanGold.withOpacity(0.4), width: 1.5),
          boxShadow: kRaisedShadow,
        ),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: kClanGold.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(child: Icon(Icons.bolt_rounded, color: kClanGold, size: 26)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('CLAN RUSH ACTIVE', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.8, color: kClanGold)),
                      const Spacer(),
                      const Icon(Icons.chevron_right_rounded, color: kClanGold, size: 18),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClanProgressBar(value: pct, fillColor: kClanGold, height: 8),
                  const SizedBox(height: 4),
                  Text('${(pct * 100).toStringAsFixed(0)}% to goal',
                    style: GoogleFonts.inter(fontSize: 11, color: kClanMuted)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Quick actions grid ────────────────────────────────────────────────────────

class _QuickActionsGrid extends StatelessWidget {
  final Map<String, dynamic> clan;
  const _QuickActionsGrid({required this.clan});

  @override
  Widget build(BuildContext context) {
    final actions = [
      _QuickAction('Battle', Icons.sports_martial_arts_rounded, kClanAccent,
        () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ClanBattleScreen()))),
      _QuickAction('Leaderboard', Icons.leaderboard_rounded, const Color(0xFF1565C0),
        () => Navigator.push(context, MaterialPageRoute(builder: (_) => ClanLeaderboardScreen(clanId: clan['id'] as int)))),
      _QuickAction('Chat', Icons.chat_bubble_outline_rounded, kClanGreen,
        () => Navigator.push(context, MaterialPageRoute(builder: (_) => ClanChatScreen(clanId: clan['id'] as int)))),
      _QuickAction('Rush', Icons.bolt_rounded, kClanGold, () {}),
    ];
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      children: actions.map((a) => _QuickActionTile(action: a)).toList(),
    );
  }
}

class _QuickAction {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _QuickAction(this.label, this.icon, this.color, this.onTap);
}

class _QuickActionTile extends StatelessWidget {
  final _QuickAction action;
  const _QuickActionTile({super.key, required this.action});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: action.onTap,
      child: ClanCard(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                color: action.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(action.icon, color: action.color, size: 20),
            ),
            const SizedBox(height: 6),
            Text(action.label, textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: kClanInk),
              maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}

// ── Member row ────────────────────────────────────────────────────────────────

class _MemberRow extends StatelessWidget {
  final Map<String, dynamic> member;
  const _MemberRow({super.key, required this.member});

  @override
  Widget build(BuildContext context) {
    final username = member['username'] as String? ?? '—';
    final role     = member['role'] as String? ?? 'member';
    final trophies = member['trophies'] ?? 0;
    final isLeader = role == 'leader';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ClanCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: kClanAccentL,
              child: Text(username.isNotEmpty ? username[0].toUpperCase() : '?',
                style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700, color: kClanAccent)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(username, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: kClanInk)),
                      if (isLeader) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: kClanGold.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: kClanGold.withOpacity(0.4)),
                          ),
                          child: Text('Leader', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: kClanGold)),
                        ),
                      ],
                    ],
                  ),
                  Text(_roleLabel(role), style: GoogleFonts.inter(fontSize: 11, color: kClanMuted)),
                ],
              ),
            ),
            Row(
              children: [
                const Icon(Icons.emoji_events_rounded, size: 14, color: kClanGold),
                const SizedBox(width: 3),
                Text(trophies.toString(), style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: kClanInk)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _roleLabel(String r) {
    switch (r) {
      case 'leader': return 'Clan Leader';
      case 'co_leader': return 'Co-Leader';
      case 'elder': return 'Elder';
      default: return 'Member';
    }
  }
}
