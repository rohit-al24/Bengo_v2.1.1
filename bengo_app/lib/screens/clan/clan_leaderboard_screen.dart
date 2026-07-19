import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/clan_service.dart';
import 'clan_theme.dart';

class ClanLeaderboardScreen extends StatefulWidget {
  final int clanId;
  const ClanLeaderboardScreen({super.key, required this.clanId});

  @override
  State<ClanLeaderboardScreen> createState() => _ClanLeaderboardScreenState();
}

class _ClanLeaderboardScreenState extends State<ClanLeaderboardScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;
  final List<String> _scopes = ['world', 'country', 'friends'];
  final List<String> _scopeLabels = ['World', 'Country', 'Friends'];

  Map<String, List<Map<String, dynamic>>> _data = {'world': [], 'country': [], 'friends': []};
  Map<String, bool> _loaded = {'world': false, 'country': false, 'friends': false};
  Map<String, bool> _loading = {'world': false, 'country': false, 'friends': false};

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this)
      ..addListener(() {
        if (!_tabCtrl.indexIsChanging) _loadTab(_scopes[_tabCtrl.index]);
      });
    _loadTab('world');
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadTab(String scope) async {
    if (_loaded[scope] == true || _loading[scope] == true) return;
    setState(() => _loading[scope] = true);
    try {
      final rows = await ClanService.instance.fetchLeaderboard(scope);
      if (mounted) setState(() {
        _data[scope] = rows;
        _loaded[scope] = true;
        _loading[scope] = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading[scope] = false);
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
        title: Text('Clan Rankings',
          style: GoogleFonts.spaceGrotesk(fontSize: 18, fontWeight: FontWeight.w700, color: kClanInk)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(46),
          child: _ScopeTabBar(controller: _tabCtrl, labels: _scopeLabels),
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: _scopes.map((scope) {
          final isLoading = _loading[scope] == true;
          final rows = _data[scope] ?? [];
          if (isLoading) return const Center(child: CircularProgressIndicator(color: kClanAccent));
          if (rows.isEmpty) return _EmptyLeaderboard();
          return _LeaderboardList(rows: rows, clanId: widget.clanId);
        }).toList(),
      ),
    );
  }
}

class _ScopeTabBar extends StatelessWidget {
  final TabController controller;
  final List<String> labels;
  const _ScopeTabBar({required this.controller, required this.labels});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Container(
        height: 36,
        decoration: BoxDecoration(
          color: kClanBorder.withOpacity(0.4),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: kClanBorder),
        ),
        child: TabBar(
          controller: controller,
          indicator: BoxDecoration(
            color: kClanSurface,
            borderRadius: BorderRadius.circular(8),
            boxShadow: kRaisedShadow,
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          labelColor: kClanAccent,
          unselectedLabelColor: kClanMuted,
          labelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700),
          unselectedLabelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
          dividerColor: Colors.transparent,
          tabs: labels.map((l) => Tab(text: l, height: 34)).toList(),
        ),
      ),
    );
  }
}

class _EmptyLeaderboard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.leaderboard_outlined, size: 48, color: kClanMuted),
          const SizedBox(height: 12),
          Text('No clans yet', style: GoogleFonts.spaceGrotesk(fontSize: 16, color: kClanMuted, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _LeaderboardList extends StatelessWidget {
  final List<Map<String, dynamic>> rows;
  final int clanId;
  const _LeaderboardList({required this.rows, required this.clanId});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      itemCount: rows.length,
      itemBuilder: (_, i) {
        final clan = rows[i];
        final isMe = clan['id'] == clanId;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isMe ? kClanAccentL : kClanSurface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isMe ? kClanAccent.withOpacity(0.4) : kClanBorder,
                width: isMe ? 1.5 : 1,
              ),
              boxShadow: kRaisedShadow,
            ),
            child: Row(
              children: [
                // Rank
                SizedBox(
                  width: 36,
                  child: _RankWidget(rank: i + 1),
                ),
                const SizedBox(width: 12),
                // Crest placeholder
                Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(
                    color: isMe ? kClanAccentL : kClanBorder.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: isMe ? kClanAccent.withOpacity(0.3) : kClanBorder),
                  ),
                  child: Icon(Icons.shield_rounded, size: 20,
                    color: isMe ? kClanAccent : kClanMuted),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(clan['name'] as String? ?? '—',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 14, fontWeight: FontWeight.w700,
                              color: isMe ? kClanAccent : kClanInk)),
                          if (isMe) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: kClanAccent, borderRadius: BorderRadius.circular(6)),
                              child: Text('You', style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white)),
                            ),
                          ],
                        ],
                      ),
                      Text('${clan['member_count'] ?? 0} members',
                        style: GoogleFonts.inter(fontSize: 11, color: kClanMuted)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.emoji_events_rounded, size: 14, color: kClanGold),
                        const SizedBox(width: 3),
                        Text((clan['trophies'] ?? 0).toString(),
                          style: GoogleFonts.spaceGrotesk(fontSize: 15, fontWeight: FontWeight.w800, color: kClanInk)),
                      ],
                    ),
                    Text('trophies', style: GoogleFonts.inter(fontSize: 10, color: kClanMuted)),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _RankWidget extends StatelessWidget {
  final int rank;
  const _RankWidget({required this.rank});

  @override
  Widget build(BuildContext context) {
    if (rank <= 3) {
      final colors = [kClanGold, const Color(0xFF9E9E9E), const Color(0xFF8D6E63)];
      return Container(
        width: 32, height: 32,
        decoration: BoxDecoration(
          color: colors[rank - 1].withOpacity(0.15),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(['🥇', '🥈', '🥉'][rank - 1], style: const TextStyle(fontSize: 16)),
        ),
      );
    }
    return Text('#$rank',
      style: GoogleFonts.spaceGrotesk(fontSize: 13, fontWeight: FontWeight.w700, color: kClanMuted),
      textAlign: TextAlign.center);
  }
}
