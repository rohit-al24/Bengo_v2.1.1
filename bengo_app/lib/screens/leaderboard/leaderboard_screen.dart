import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/app_colors.dart';
import '../../services/api_service.dart';
import '../../widgets/bengo_avatar.dart';
import '../../widgets/bengo_header.dart';
import '../../widgets/bottom_nav.dart';
import '../main_shell.dart';

// ── Design tokens ──────────────────────────────────────────────────────────────
const _kBg          = Color(0xFFFAF8F5);
const _kSurface     = Color(0xFFFFFFFF);
const _kAccent      = Color(0xFFC41230);
const _kInk         = Color(0xFF1B1B1D);
const _kMuted       = Color(0xFF8A8A8F);
const _kBorder      = Color(0xFFEAE5E1);
const _kFieldTint   = Color(0xFFFDF3F5);
const _kFieldBorder = Color(0xFFEDD5D8);

// Medal colours
const _kGold   = Color(0xFFFFD700);
const _kSilver = Color(0xFFC0C0C0);
const _kBronze = Color(0xFFCD7F32);

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic> _me = {};
  List<dynamic> _users = [];
  bool _loading   = true;
  String _activeTab = 'friends';
  late AnimationController _shimmerCtrl;

  @override
  void initState() {
    super.initState();
    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
    _loadData();
  }

  @override
  void dispose() {
    _shimmerCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final me = await ApiService.instance.getMe();
      _me = me;
      final hasInstitution =
          me['institution'] != null && me['institution'].toString().trim().isNotEmpty;
      _activeTab = hasInstitution ? 'institution' : 'friends';
      final list = await ApiService.instance.getLeaderboard(_activeTab);
      setState(() => _users = list);
    } catch (_) {
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _switchTab(String tab) async {
    if (_activeTab == tab) return;
    setState(() { _activeTab = tab; _loading = true; });
    try {
      final list = await ApiService.instance.getLeaderboard(tab);
      setState(() => _users = list);
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
                  ? _buildLoadingState()
                  : RefreshIndicator(
                      onRefresh: () async {
                        final list =
                            await ApiService.instance.getLeaderboard(_activeTab);
                        setState(() => _users = list);
                      },
                      color: _kAccent,
                      child: CustomScrollView(
                        physics: const BouncingScrollPhysics(),
                        slivers: [
                          // ── Page title ─────────────────────────────────────
                          SliverToBoxAdapter(child: _buildPageTitle()),
                          // ── Tab selector ───────────────────────────────────
                          SliverToBoxAdapter(child: _buildTabSelector()),
                          // ── Podium top-3 ───────────────────────────────────
                          if (_users.isNotEmpty)
                            SliverToBoxAdapter(child: _buildPodium()),
                          // ── Rank rows 4+ ───────────────────────────────────
                          if (_users.length > 3)
                            SliverPadding(
                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                              sliver: SliverList(
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) {
                                    final listIndex = index + 3;
                                    if (listIndex >= _users.length) return null;
                                    final u = _users[listIndex];
                                    final isUser = u['username'] == _me['username'];
                                    return _buildRankRow(
                                      listIndex + 1, u, isUser,
                                    );
                                  },
                                  childCount: _users.length - 3,
                                ),
                              ),
                            )
                          else if (_users.isEmpty)
                            SliverFillRemaining(
                              hasScrollBody: false,
                              child: _buildEmptyState(),
                            ),
                          const SliverToBoxAdapter(child: SizedBox(height: 24)),
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

  // ── Page title ────────────────────────────────────────────────────────────
  Widget _buildPageTitle() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Leaderboard',
                    style: GoogleFonts.spaceGrotesk(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: _kInk,
                        letterSpacing: -0.8)),
                const SizedBox(height: 2),
                Text('Climb the ranks · Master Japanese.',
                    style: GoogleFonts.inter(fontSize: 13, color: _kMuted)),
              ],
            ),
          ),
          // Current user rank badge
          if (_userRank != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: _kFieldTint,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _kFieldBorder, width: 1.5),
              ),
              child: Column(
                children: [
                  Text('YOUR RANK',
                      style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: _kMuted,
                          letterSpacing: 0.8)),
                  const SizedBox(height: 2),
                  Text('#${_userRank!}',
                      style: GoogleFonts.spaceGrotesk(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: _kAccent)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ── Tab selector ──────────────────────────────────────────────────────────
  Widget _buildTabSelector() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: _kSurface,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: _kBorder),
          boxShadow: const [
            BoxShadow(color: Color(0x07000000), blurRadius: 8, offset: Offset(0, 3))
          ],
        ),
        child: Row(
          children: [
            _TabButton(
              label: 'FRIENDS',
              icon: Icons.people_rounded,
              isActive: _activeTab == 'friends',
              onTap: () => _switchTab('friends'),
            ),
            _TabButton(
              label: 'INSTITUTION',
              icon: Icons.school_rounded,
              isActive: _activeTab == 'institution',
              onTap: () => _switchTab('institution'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Podium ────────────────────────────────────────────────────────────────
  Widget _buildPodium() {
    final first  = _users.isNotEmpty ? _users[0] : null;
    final second = _users.length > 1 ? _users[1] : null;
    final third  = _users.length > 2 ? _users[2] : null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              _kAccent.withOpacity(0.04),
              _kSurface,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _kBorder),
          boxShadow: const [
            BoxShadow(color: Color(0x0A000000), blurRadius: 16, offset: Offset(0, 6)),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (second != null)
              _PodiumItem(user: second, rank: 2, medalColor: _kSilver, avatarSize: 64, isCurrentUser: second['username'] == _me['username'])
            else
              const SizedBox(width: 80),

            if (first != null)
              _PodiumItem(user: first, rank: 1, medalColor: _kGold, avatarSize: 88, showCrown: true, isCurrentUser: first['username'] == _me['username'])
            else
              const SizedBox(width: 88),

            if (third != null)
              _PodiumItem(user: third, rank: 3, medalColor: _kBronze, avatarSize: 52, isCurrentUser: third['username'] == _me['username'])
            else
              const SizedBox(width: 64),
          ],
        ),
      ),
    );
  }

  // ── Rank row (4+) ─────────────────────────────────────────────────────────
  Widget _buildRankRow(int rank, dynamic u, bool isUser) {
    final name     = u['username']?.toString() ?? 'User';
    final firstName = u['first_name']?.toString() ?? '';
    final lastName  = u['last_name']?.toString() ?? '';
    final displayName = (firstName.isNotEmpty || lastName.isNotEmpty)
        ? '$firstName $lastName'.trim() : name;
    final xp       = u['xp'] as int? ?? 0;
    final streak   = u['streak_days'] as int? ?? 0;
    final avatarId = u['avatar_id']?.toString();
    final inst     = u['institution']?.toString() ?? '';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isUser ? _kFieldTint : _kSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUser ? _kFieldBorder : _kBorder,
          width: isUser ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isUser ? _kAccent.withOpacity(0.08) : Colors.black.withOpacity(0.04),
            blurRadius: 8, offset: const Offset(0, 3)),
        ],
      ),
      child: Row(
        children: [
          // Rank number
          SizedBox(
            width: 30,
            child: Text('#$rank',
                style: GoogleFonts.spaceGrotesk(
                    fontSize: 13, fontWeight: FontWeight.w700,
                    color: isUser ? _kAccent : _kMuted)),
          ),
          const SizedBox(width: 8),

          // Avatar
          BenGoAvatar(avatarId: avatarId, size: 40),
          const SizedBox(width: 12),

          // Name + institution
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(displayName,
                          style: GoogleFonts.inter(
                              fontSize: 14, fontWeight: FontWeight.w600, color: _kInk),
                          overflow: TextOverflow.ellipsis),
                    ),
                    if (isUser) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _kAccent, borderRadius: BorderRadius.circular(20)),
                        child: Text('YOU',
                            style: GoogleFonts.inter(
                                fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    if (inst.isNotEmpty) ...[
                      Icon(Icons.school_rounded, size: 10, color: _kMuted),
                      const SizedBox(width: 3),
                      Flexible(child: Text(inst,
                          style: GoogleFonts.inter(fontSize: 10, color: _kMuted),
                          overflow: TextOverflow.ellipsis)),
                      const SizedBox(width: 8),
                    ],
                    if (streak > 0) ...[
                      const Icon(Icons.local_fire_department_rounded, size: 10, color: Color(0xFFEA580C)),
                      const SizedBox(width: 2),
                      Text('$streak', style: GoogleFonts.inter(
                          fontSize: 10, color: const Color(0xFFEA580C), fontWeight: FontWeight.w600)),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // XP
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('$xp',
                  style: GoogleFonts.spaceGrotesk(
                      fontSize: 17, fontWeight: FontWeight.w800,
                      color: isUser ? _kAccent : _kInk)),
              Text('XP',
                  style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w600, color: _kMuted)),
            ],
          ),
        ],
      ),
    );
  }

  // ── Sticky current-user card ──────────────────────────────────────────────
  Widget _buildCurrentUserCard(int rank, int xp) {
    final name     = _me['username']?.toString() ?? 'You';
    final firstName = _me['first_name']?.toString() ?? '';
    final lastName  = _me['last_name']?.toString() ?? '';
    final displayName = (firstName.isNotEmpty || lastName.isNotEmpty)
        ? '$firstName $lastName'.trim() : name;
    final avatarId = _me['avatar_id']?.toString();
    final streak   = _me['streak_days'] as int? ?? 0;
    final inst     = (_me['institution'] ?? '').toString().toUpperCase();

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _kFieldTint,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _kFieldBorder, width: 1.5),
        boxShadow: [
          BoxShadow(
              color: _kAccent.withOpacity(0.12),
              blurRadius: 12, offset: const Offset(0, -4)),
        ],
      ),
      child: Row(
        children: [
          // Rank
          SizedBox(
            width: 30,
            child: Text('#$rank',
                style: GoogleFonts.spaceGrotesk(
                    fontSize: 13, fontWeight: FontWeight.w700, color: _kAccent)),
          ),
          const SizedBox(width: 8),

          BenGoAvatar(avatarId: avatarId, size: 40),
          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Flexible(child: Text(displayName,
                      style: GoogleFonts.inter(
                          fontSize: 14, fontWeight: FontWeight.w700, color: _kInk),
                      overflow: TextOverflow.ellipsis)),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _kAccent, borderRadius: BorderRadius.circular(20)),
                    child: Text('YOU', style: GoogleFonts.inter(
                        fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white)),
                  ),
                ]),
                const SizedBox(height: 2),
                Row(children: [
                  if (inst.isNotEmpty) ...[
                    Icon(Icons.school_rounded, size: 10, color: _kMuted),
                    const SizedBox(width: 3),
                    Flexible(child: Text(inst,
                        style: GoogleFonts.inter(fontSize: 10, color: _kMuted),
                        overflow: TextOverflow.ellipsis)),
                    const SizedBox(width: 8),
                  ],
                  if (streak > 0) ...[
                    const Icon(Icons.local_fire_department_rounded, size: 10, color: Color(0xFFEA580C)),
                    const SizedBox(width: 2),
                    Text('$streak day streak', style: GoogleFonts.inter(
                        fontSize: 10, color: const Color(0xFFEA580C), fontWeight: FontWeight.w600)),
                  ],
                ]),
              ],
            ),
          ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('$xp',
                  style: GoogleFonts.spaceGrotesk(
                      fontSize: 18, fontWeight: FontWeight.w800, color: _kAccent)),
              Text('XP',
                  style: GoogleFonts.inter(
                      fontSize: 9, fontWeight: FontWeight.w600, color: _kMuted)),
            ],
          ),
        ],
      ),
    );
  }

  // ── Loading shimmer ───────────────────────────────────────────────────────
  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(color: _kAccent, strokeWidth: 2.5),
    );
  }

  // ── Empty state ───────────────────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              color: _kFieldTint,
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Icon(Icons.emoji_events_rounded, size: 34, color: _kMuted),
          ),
          const SizedBox(height: 16),
          Text('No rankings yet',
              style: GoogleFonts.spaceGrotesk(
                  fontSize: 18, fontWeight: FontWeight.w700, color: _kInk)),
          const SizedBox(height: 6),
          Text('Complete lessons to appear here!',
              style: GoogleFonts.inter(fontSize: 13, color: _kMuted)),
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
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: isActive ? _kAccent : Colors.transparent,
            borderRadius: BorderRadius.circular(100),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: isActive ? Colors.white : _kMuted),
              const SizedBox(width: 6),
              Text(label,
                  style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isActive ? Colors.white : _kMuted,
                      letterSpacing: 0.6)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Podium item ─────────────────────────────────────────────────────────────
class _PodiumItem extends StatelessWidget {
  final Map<String, dynamic> user;
  final int rank;
  final Color medalColor;
  final double avatarSize;
  final bool showCrown;
  final bool isCurrentUser;

  const _PodiumItem({
    required this.user,
    required this.rank,
    required this.medalColor,
    required this.avatarSize,
    this.showCrown = false,
    this.isCurrentUser = false,
  });

  @override
  Widget build(BuildContext context) {
    final name     = user['username']?.toString() ?? 'User';
    final firstName = user['first_name']?.toString() ?? '';
    final displayName = firstName.isNotEmpty ? firstName : name;
    final xp       = user['xp'] as int? ?? 0;
    final avatarId = user['avatar_id']?.toString();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Crown emoji for #1
        if (showCrown)
          Text('👑', style: TextStyle(fontSize: avatarSize * 0.33))
        else
          SizedBox(height: avatarSize * 0.33),
        const SizedBox(height: 6),

        // Avatar with medal ring + glow
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(avatarSize * 0.26),
                border: Border.all(color: medalColor, width: showCrown ? 3 : 2.5),
                boxShadow: [
                  BoxShadow(
                    color: medalColor.withOpacity(showCrown ? 0.40 : 0.22),
                    blurRadius: showCrown ? 20 : 12,
                    spreadRadius: showCrown ? 4 : 1,
                  ),
                  if (isCurrentUser)
                    BoxShadow(
                      color: _kAccent.withOpacity(0.25),
                      blurRadius: 16, spreadRadius: 2,
                    ),
                ],
              ),
              child: BenGoAvatar(avatarId: avatarId, size: avatarSize),
            ),
            // Rank badge
            Container(
              width: 22, height: 22,
              decoration: BoxDecoration(
                color: medalColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Center(
                child: Text('$rank',
                    style: GoogleFonts.inter(
                        fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white)),
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        // Name
        SizedBox(
          width: avatarSize + 16,
          child: Text(
            displayName,
            style: GoogleFonts.inter(
              fontSize: showCrown ? 13 : 11,
              fontWeight: FontWeight.w700,
              color: _kInk,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ),

        const SizedBox(height: 3),

        // XP chip
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: medalColor.withOpacity(0.35), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: medalColor.withOpacity(0.12),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.bolt_rounded, size: 11, color: medalColor),
              const SizedBox(width: 2),
              Text('$xp XP',
                  style: GoogleFonts.inter(
                      fontSize: 10, fontWeight: FontWeight.w800, color: medalColor)),
            ],
          ),
        ),

        // Podium bar (visual height indicator)
        const SizedBox(height: 10),
        Container(
          width: avatarSize * 0.75,
          height: showCrown ? 48 : rank == 2 ? 32 : 20,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [medalColor.withOpacity(0.6), medalColor.withOpacity(0.2)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
          ),
        ),
      ],
    );
  }
}
