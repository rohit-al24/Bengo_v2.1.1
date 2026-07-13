import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/app_colors.dart';
import '../../services/api_service.dart';
import '../../widgets/bengo_header.dart';
import '../../widgets/bottom_nav.dart';
import '../main_shell.dart';

// ── Design tokens ─────────────────────────────────────────────────────────────
const _kBg = Color(0xFFFAF8F5);
const _kSurface = Color(0xFFFFFFFF);
const _kAccent = Color(0xFFC41230);
const _kInk = Color(0xFF1B1B1D);
const _kMuted = Color(0xFF8A8A8F);
const _kBorderLight = Color(0xFFEAE5E1);
const _kFieldTint = Color(0xFFFDF3F5);
const _kFieldBorder = Color(0xFFEDD5D8);

// Medal colours
const _kGold = Color(0xFFFFD700);
const _kSilver = Color(0xFFC0C0C0);
const _kBronze = Color(0xFFCD7F32);

// Current user highlight
const _kUserTint = Color(0xFFFDF3F5);
const _kUserBorder = Color(0xFFEDD5D8);

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  Map<String, dynamic> _me = {};
  List<dynamic> _users = [];
  bool _loading = true;
  String _activeTab = 'friends';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final me = await ApiService.instance.getMe();
      _me = me;
      final hasInstitution = me['institution'] != null &&
          me['institution'].toString().trim().isNotEmpty;
      _activeTab = hasInstitution ? 'institution' : 'friends';
      final list = await ApiService.instance.getLeaderboard(_activeTab);
      setState(() {
        _users = list;
      });
    } catch (_) {
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _switchTab(String tab) async {
    if (_activeTab == tab) return;
    setState(() {
      _activeTab = tab;
      _loading = true;
    });
    try {
      final list = await ApiService.instance.getLeaderboard(tab);
      setState(() {
        _users = list;
      });
    } catch (_) {
    } finally {
      setState(() => _loading = false);
    }
  }

  int? get _userRank {
    final myUsername = _me['username'] as String?;
    if (myUsername == null) return null;
    for (int i = 0; i < _users.length; i++) {
      if (_users[i]['username'] == myUsername) return i + 1;
    }
    return null;
  }

  int get _userXP => (_me['xp'] ?? 0) as int;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Column(
          children: [
            const BenGoHeader(isSubPage: true),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: _kAccent, strokeWidth: 2.5))
                  : RefreshIndicator(
                      onRefresh: () async {
                        final list = await ApiService.instance
                            .getLeaderboard(_activeTab);
                        setState(() => _users = list);
                      },
                      color: _kAccent,
                      child: CustomScrollView(
                        physics: const BouncingScrollPhysics(),
                        slivers: [
                          // ── Header ───────────────────────────────────────
                          SliverToBoxAdapter(
                            child: Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(20, 8, 20, 14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Leaderboard',
                                    style: GoogleFonts.spaceGrotesk(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w700,
                                      color: _kInk,
                                      letterSpacing: -0.6,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Climb the ranks and master Japanese.',
                                    style: GoogleFonts.inter(
                                        fontSize: 13, color: _kMuted),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // ── Tab selector ─────────────────────────────────
                          SliverToBoxAdapter(
                            child: Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(20, 0, 20, 18),
                              child: _buildTabSelector(),
                            ),
                          ),
                          // ── Podium ───────────────────────────────────────
                          if (_users.isNotEmpty)
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                    20, 0, 20, 24),
                                child: _buildPodium(),
                              ),
                            ),
                          // ── Rank list (4+) ────────────────────────────────
                          if (_users.length > 3)
                            SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  final listIndex = index + 3;
                                  if (listIndex >= _users.length) return null;
                                  final u = _users[listIndex];
                                  final isUser =
                                      u['username'] == _me['username'];
                                  return _buildRankRow(
                                    listIndex + 1,
                                    u['username'] ?? 'User',
                                    '${u['xp'] ?? 0}',
                                    'LEVEL ${((u['xp'] ?? 0) / 100).ceil()} • ${u['institution'] ?? 'NO INSTITUTION'}',
                                    isUser,
                                  );
                                },
                                childCount: _users.length - 3,
                              ),
                            )
                          else if (_users.isEmpty)
                            SliverFillRemaining(
                              hasScrollBody: false,
                              child: Center(
                                child: Text(
                                  'No ranks recorded yet.',
                                  style: GoogleFonts.inter(
                                      color: _kMuted, fontSize: 13),
                                ),
                              ),
                            ),
                          const SliverToBoxAdapter(
                              child: SizedBox(height: 24)),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!_loading && _userRank != null)
            _buildCurrentUserCard(_userRank!, _userXP),
          BenGoBottomNav(
            currentIndex: 2,
            onTap: (i) {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => MainShell(initialIndex: i)),
                (route) => false,
              );
            },
          ),
        ],
      ),
    );
  }

  // ── Tab selector ─────────────────────────────────────────────────────────
  Widget _buildTabSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: _kBorderLight),
        boxShadow: const [
          BoxShadow(
              color: Color(0x07000000), blurRadius: 8, offset: Offset(0, 3))
        ],
      ),
      child: Row(
        children: [
          _TabButton(
            label: 'FRIENDS',
            isActive: _activeTab == 'friends',
            onTap: () => _switchTab('friends'),
          ),
          _TabButton(
            label: 'INSTITUTION',
            isActive: _activeTab == 'institution',
            onTap: () => _switchTab('institution'),
          ),
        ],
      ),
    );
  }

  // ── Podium ────────────────────────────────────────────────────────────────
  Widget _buildPodium() {
    final first = _users.isNotEmpty ? _users[0] : null;
    final second = _users.length > 1 ? _users[1] : null;
    final third = _users.length > 2 ? _users[2] : null;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kBorderLight),
        boxShadow: const [
          BoxShadow(
              color: Color(0x08000000), blurRadius: 12, offset: Offset(0, 4))
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (second != null)
            _PodiumItem(
              name: second['username'] ?? 'User',
              xp: '${second['xp'] ?? 0}',
              rank: 2,
              medalColor: _kSilver,
              avatarSize: 68,
            )
          else
            const SizedBox(width: 68),
          if (first != null)
            _PodiumItem(
              name: first['username'] ?? 'User',
              xp: '${first['xp'] ?? 0}',
              rank: 1,
              medalColor: _kGold,
              avatarSize: 90,
              showCrown: true,
            )
          else
            const SizedBox(width: 90),
          if (third != null)
            _PodiumItem(
              name: third['username'] ?? 'User',
              xp: '${third['xp'] ?? 0}',
              rank: 3,
              medalColor: _kBronze,
              avatarSize: 58,
            )
          else
            const SizedBox(width: 58),
        ],
      ),
    );
  }

  // ── Rank row (4+) ─────────────────────────────────────────────────────────
  Widget _buildRankRow(
      int rank, String name, String xp, String subtitle, bool isUser) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isUser ? _kUserTint : _kSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUser ? _kFieldBorder : _kBorderLight,
          width: isUser ? 1.5 : 1,
        ),
        boxShadow: const [
          BoxShadow(
              color: Color(0x06000000), blurRadius: 6, offset: Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          // Rank number
          SizedBox(
            width: 28,
            child: Text(
              '#$rank',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isUser ? _kAccent : _kMuted,
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Avatar
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isUser
                  ? _kAccent.withOpacity(0.12)
                  : const Color(0xFFF0F0F0),
            ),
            child: Center(
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : 'U',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isUser ? _kAccent : _kMuted,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _kInk,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isUser) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _kAccent,
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(
                          'YOU',
                          style: GoogleFonts.inter(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: Colors.white),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(fontSize: 10, color: _kMuted),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                xp,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isUser ? _kAccent : _kInk,
                ),
              ),
              Text(
                'XP',
                style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: _kMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Pinned current user card ──────────────────────────────────────────────
  Widget _buildCurrentUserCard(int rank, int xp) {
    final name = _me['username'] ?? 'You';
    final institution =
        (_me['institution'] ?? 'NO INSTITUTION').toString().toUpperCase();
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 6, 20, 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _kUserTint,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kFieldBorder, width: 1.5),
        boxShadow: const [
          BoxShadow(
              color: Color(0x10C41230), blurRadius: 8, offset: Offset(0, -2))
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              '#$rank',
              style: GoogleFonts.spaceGrotesk(
                  fontSize: 13, fontWeight: FontWeight.w700, color: _kAccent),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _kAccent.withOpacity(0.12),
            ),
            child: Center(
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : 'U',
                style: GoogleFonts.spaceGrotesk(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _kAccent),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _kInk),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _kAccent,
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(
                        'YOU',
                        style: GoogleFonts.inter(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: Colors.white),
                      ),
                    ),
                  ],
                ),
                Text(institution,
                    style: GoogleFonts.inter(fontSize: 10, color: _kMuted)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$xp',
                style: GoogleFonts.spaceGrotesk(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _kAccent),
              ),
              Text('XP',
                  style: GoogleFonts.inter(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: _kMuted)),
            ],
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// LOCAL COMPONENTS
// ═══════════════════════════════════════════════════════════════════════════════

class _TabButton extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: isActive ? _kAccent : Colors.transparent,
            borderRadius: BorderRadius.circular(100),
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isActive ? Colors.white : _kMuted,
                letterSpacing: 0.8,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PodiumItem extends StatelessWidget {
  final String name;
  final String xp;
  final int rank;
  final Color medalColor;
  final double avatarSize;
  final bool showCrown;

  const _PodiumItem({
    required this.name,
    required this.xp,
    required this.rank,
    required this.medalColor,
    required this.avatarSize,
    this.showCrown = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showCrown)
          Text('👑', style: TextStyle(fontSize: avatarSize * 0.35)),
        if (!showCrown) SizedBox(height: avatarSize * 0.35),
        const SizedBox(height: 4),
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              width: avatarSize,
              height: avatarSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                border: Border.all(color: medalColor, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: medalColor.withOpacity(0.25),
                    blurRadius: 14,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : 'U',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: avatarSize * 0.4,
                    fontWeight: FontWeight.w700,
                    color: medalColor,
                  ),
                ),
              ),
            ),
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: medalColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Center(
                child: Text(
                  '$rank',
                  style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Colors.white),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: avatarSize + 12,
          child: Text(
            name,
            style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: _kInk),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ),
        Text(
          '$xp XP',
          style: GoogleFonts.inter(
              fontSize: 11, fontWeight: FontWeight.w600, color: _kAccent),
        ),
      ],
    );
  }
}
