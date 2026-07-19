import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/clan_service.dart';
import 'clan_theme.dart';
import 'clan_home_screen.dart';
import 'clan_creation_screen.dart';

class ClanJoinScreen extends StatefulWidget {
  const ClanJoinScreen({super.key});

  @override
  State<ClanJoinScreen> createState() => _ClanJoinScreenState();
}

class _ClanJoinScreenState extends State<ClanJoinScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  List<Map<String, dynamic>> _topClans = [];
  List<Map<String, dynamic>> _recommended = [];
  bool _loading = true;
  bool _joining = false;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final top  = await ClanService.instance.fetchLeaderboard('world');
      final rec  = await ClanService.instance.fetchLeaderboard('world');
      if (mounted) setState(() {
        _topClans   = top;
        _recommended = rec.where((c) => c['privacy'] != 'closed').take(10).toList();
        _loading    = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> get _filtered => _searchQuery.isEmpty
      ? _topClans
      : _topClans.where((c) =>
          (c['name'] as String? ?? '').toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (c['tag']  as String? ?? '').toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();

  Future<void> _join(Map<String, dynamic> clan) async {
    final privacy = clan['privacy'] as String? ?? 'open';
    final label   = privacy == 'open' ? 'Join' : 'Request to Join';
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: kClanSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(label, style: GoogleFonts.spaceGrotesk(fontSize: 18, fontWeight: FontWeight.w800, color: kClanInk)),
        content: RichText(
          text: TextSpan(
            style: GoogleFonts.inter(fontSize: 14, color: kClanMuted, height: 1.5),
            children: [
              const TextSpan(text: 'Would you like to '),
              TextSpan(text: label.toLowerCase(), style: const TextStyle(fontWeight: FontWeight.w700, color: kClanInk)),
              const TextSpan(text: ' '),
              TextSpan(text: clan['name'] as String? ?? '—', style: const TextStyle(fontWeight: FontWeight.w700, color: kClanInk)),
              const TextSpan(text: '?'),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: GoogleFonts.inter(color: kClanMuted, fontWeight: FontWeight.w700))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: kClanAccent, foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0),
            onPressed: () => Navigator.pop(context, true),
            child: Text(label, style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    setState(() => _joining = true);
    try {
      await ClanService.instance.joinClan(clan['id'] as int);
      if (!mounted) return;
      if (privacy == 'open') {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ClanHomeScreen()));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Join request sent!', style: GoogleFonts.inter(color: Colors.white)),
          backgroundColor: kClanInk,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString(), style: GoogleFonts.inter(color: Colors.white)),
        backgroundColor: kClanRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    } finally {
      if (mounted) setState(() => _joining = false);
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
        title: Text('Find a Clan',
          style: GoogleFonts.spaceGrotesk(fontSize: 18, fontWeight: FontWeight.w700, color: kClanInk)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ClanPillButton(
              label: 'Create',
              icon: Icons.add_rounded,
              isOutlined: true,
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ClanCreationScreen())),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(110),
          child: Column(
            children: [
              // Search bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: kClanSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: kClanBorder),
                    boxShadow: kRaisedShadow,
                  ),
                  child: TextField(
                    controller: _searchCtrl,
                    style: GoogleFonts.inter(fontSize: 14, color: kClanInk),
                    decoration: InputDecoration(
                      hintText: 'Search clans by name or tag…',
                      hintStyle: GoogleFonts.inter(color: kClanMuted, fontSize: 13),
                      border: InputBorder.none,
                      prefixIcon: const Icon(Icons.search_rounded, color: kClanMuted, size: 20),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                    ),
                    onChanged: (v) => setState(() => _searchQuery = v),
                  ),
                ),
              ),
              // Tab bar
              TabBar(
                controller: _tabCtrl,
                indicatorColor: kClanAccent,
                indicatorWeight: 2.5,
                labelColor: kClanAccent,
                unselectedLabelColor: kClanMuted,
                labelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700),
                unselectedLabelStyle: GoogleFonts.inter(fontSize: 13),
                tabs: const [Tab(text: 'All Clans'), Tab(text: 'Recommended')],
              ),
            ],
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: kClanAccent))
          : TabBarView(
              controller: _tabCtrl,
              children: [
                _ClanList(clans: _filtered, onJoin: _joining ? null : _join),
                _ClanList(clans: _recommended, onJoin: _joining ? null : _join),
              ],
            ),
    );
  }
}

// ── Clan list ─────────────────────────────────────────────────────────────────

class _ClanList extends StatelessWidget {
  final List<Map<String, dynamic>> clans;
  final void Function(Map<String, dynamic>)? onJoin;
  const _ClanList({required this.clans, required this.onJoin});

  @override
  Widget build(BuildContext context) {
    if (clans.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off_rounded, size: 48, color: kClanMuted),
            const SizedBox(height: 12),
            Text('No clans found', style: GoogleFonts.spaceGrotesk(fontSize: 16, color: kClanMuted, fontWeight: FontWeight.w600)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      itemCount: clans.length,
      itemBuilder: (_, i) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: _ClanCard(clan: clans[i], onJoin: onJoin),
      ),
    );
  }
}

class _ClanCard extends StatelessWidget {
  final Map<String, dynamic> clan;
  final void Function(Map<String, dynamic>)? onJoin;
  const _ClanCard({super.key, required this.clan, required this.onJoin});

  @override
  Widget build(BuildContext context) {
    final name      = clan['name'] as String? ?? '—';
    final tag       = clan['tag'] as String? ?? '';
    final trophies  = clan['trophies'] ?? 0;
    final members   = clan['member_count'] ?? 0;
    final slots     = clan['slots_unlocked'] ?? 10;
    final privacy   = clan['privacy'] as String? ?? 'open';
    final minTrophy = clan['min_join_trophies'] ?? 0;
    final isFull    = members >= slots;
    final isClosed  = privacy == 'closed';
    final canJoin   = !isFull && !isClosed && onJoin != null;

    return ClanCard(
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: kClanAccentL,
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: kClanBorder),
              boxShadow: kRaisedShadow,
            ),
            child: const Icon(Icons.shield_rounded, color: kClanAccent, size: 26),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(child: Text(name,
                      style: GoogleFonts.spaceGrotesk(fontSize: 14, fontWeight: FontWeight.w700, color: kClanInk),
                      overflow: TextOverflow.ellipsis)),
                    const SizedBox(width: 6),
                    Text('#$tag', style: GoogleFonts.inter(fontSize: 11, color: kClanMuted)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.emoji_events_rounded, size: 12, color: kClanGold),
                    const SizedBox(width: 3),
                    Text('$trophies', style: GoogleFonts.inter(fontSize: 12, color: kClanMuted)),
                    const SizedBox(width: 10),
                    Icon(_privacyIcon(privacy), size: 12, color: kClanMuted),
                    const SizedBox(width: 3),
                    Text(privacy, style: GoogleFonts.inter(fontSize: 12, color: kClanMuted)),
                    const SizedBox(width: 10),
                    const Icon(Icons.people_rounded, size: 12, color: kClanMuted),
                    const SizedBox(width: 3),
                    Text('$members/$slots', style: GoogleFonts.inter(fontSize: 12, color: kClanMuted)),
                  ],
                ),
                if (minTrophy > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text('Min: $minTrophy trophies', style: GoogleFonts.inter(fontSize: 11, color: kClanMuted)),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (isFull)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: kClanBorder, borderRadius: BorderRadius.circular(10)),
              child: Text('Full', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: kClanMuted)),
            )
          else if (isClosed)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: kClanBorder, borderRadius: BorderRadius.circular(10)),
              child: Text('Closed', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: kClanMuted)),
            )
          else
            GestureDetector(
              onTap: canJoin ? () => onJoin!(clan) : null,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: kClanAccent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(color: kClanAccent.withOpacity(0.3), blurRadius: 6, offset: const Offset(0, 2)),
                  ],
                ),
                child: Text(
                  privacy == 'invite_only' ? 'Request' : 'Join',
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
                ),
              ),
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
