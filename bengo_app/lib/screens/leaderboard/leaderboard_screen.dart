import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../../utils/app_decorations.dart';
import '../../services/api_service.dart';
import '../../widgets/bengo_header.dart';
import '../../widgets/bottom_nav.dart';
import '../main_shell.dart';

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
      
      // Determine default tab based on whether they have an institution
      final hasInstitution = me['institution'] != null && me['institution'].toString().trim().isNotEmpty;
      _activeTab = hasInstitution ? 'institution' : 'friends';
      
      final list = await ApiService.instance.getLeaderboard(_activeTab);
      setState(() {
        _users = list;
      });
    } catch (_) {
      // Offline / error fallback
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
      if (_users[i]['username'] == myUsername) {
        return i + 1;
      }
    }
    return null;
  }

  int get _userXP => (_me['xp'] ?? 0) as int;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: SafeArea(
        child: Column(
          children: [
            // App Bar
            const BenGoHeader(isSubPage: true),
            // Main content
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : RefreshIndicator(
                      onRefresh: () async {
                        final list = await ApiService.instance.getLeaderboard(_activeTab);
                        setState(() {
                          _users = list;
                        });
                      },
                      color: AppColors.primary,
                      child: CustomScrollView(
                        slivers: [
                          // Leaderboard Title
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Leaderboard',
                                    style: GoogleFonts.inter(
                                      fontSize: 26,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Climb the ranks and master Japanese.',
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // Tab selector
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              child: _buildTabSelector(),
                            ),
                          ),
                          // Top 3 Podium (Only if we have users)
                          if (_users.isNotEmpty)
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                                child: _buildPodium(),
                              ),
                            ),
                          // List items (Rank 4+)
                          if (_users.length > 3)
                            SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  final listIndex = index + 3;
                                  if (listIndex >= _users.length) return null;
                                  final u = _users[listIndex];
                                  final isUser = u['username'] == _me['username'];
                                  return _buildLeaderItem(
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
                                  style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 13),
                                ),
                              ),
                            ),
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
          // Pin current user card right above navigation bar
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



  Widget _buildTabSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: AppDecorations.skeuomorphicCard(radius: 20),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => _switchTab('friends'),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _activeTab == 'friends' ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    'FRIENDS',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: _activeTab == 'friends' ? Colors.white : AppColors.textSecondary,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => _switchTab('institution'),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _activeTab == 'institution' ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    'INSTITUTION',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: _activeTab == 'institution' ? Colors.white : AppColors.textSecondary,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPodium() {
    final first = _users.isNotEmpty ? _users[0] : null;
    final second = _users.length > 1 ? _users[1] : null;
    final third = _users.length > 2 ? _users[2] : null;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // 2nd place
        if (second != null)
          _podiumItem(second['username'] ?? 'User', '${second['xp'] ?? 0}', 2, const Color(0xFFC0C0C0), 72)
        else
          const SizedBox(width: 72),

        // 1st place
        if (first != null)
          _podiumItem(first['username'] ?? 'User', '${first['xp'] ?? 0}', 1, const Color(0xFFFFD700), 96)
        else
          const SizedBox(width: 96),

        // 3rd place
        if (third != null)
          _podiumItem(third['username'] ?? 'User', '${third['xp'] ?? 0}', 3, const Color(0xFFCD7F32), 60)
        else
          const SizedBox(width: 60),
      ],
    );
  }

  Widget _podiumItem(String name, String xp, int rank, Color ringColor, double avatarSize) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              width: avatarSize, height: avatarSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: ringColor, width: 3.5),
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: ringColor.withOpacity(0.2),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : 'U',
                  style: GoogleFonts.inter(
                    fontSize: avatarSize * 0.45,
                    fontWeight: FontWeight.w800,
                    color: ringColor,
                  ),
                ),
              ),
            ),
            Container(
              width: 22, height: 22,
              decoration: BoxDecoration(
                color: ringColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Center(
                child: Text(
                  '$rank',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          name,
          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          '$xp XP',
          style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary),
        ),
      ],
    );
  }

  Widget _buildLeaderItem(int rank, String name, String xp, String subtitle, bool isUser) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      padding: const EdgeInsets.all(14),
      decoration: AppDecorations.skeuomorphicCard(
        color: isUser ? const Color(0xFFE2F4D9) : Colors.white,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            child: Text(
              '$rank',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: isUser ? const Color(0xFF33691E) : AppColors.textMuted,
              ),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            radius: 18,
            backgroundColor: isUser ? const Color(0xFF33691E).withOpacity(0.12) : AppColors.primary.withOpacity(0.1),
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : 'U',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: isUser ? const Color(0xFF33691E) : AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isUser ? const Color(0xFF1B5E20) : AppColors.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    color: isUser ? const Color(0xFF558B2F) : AppColors.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                xp,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: isUser ? const Color(0xFF1B5E20) : AppColors.primary,
                ),
              ),
              Text(
                'XP',
                style: GoogleFonts.inter(
                  fontSize: 9,
                  color: isUser ? const Color(0xFF558B2F) : AppColors.textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentUserCard(int rank, int xp) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFE2F4D9), // Minty green
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF9CCC65), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            offset: const Offset(0, -2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            child: Text(
              '$rank',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF33691E),
              ),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            radius: 18,
            backgroundColor: const Color(0xFF33691E).withOpacity(0.15),
            child: Text(
              _me['username'] != null && _me['username'].isNotEmpty ? _me['username'][0].toUpperCase() : 'U',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF33691E),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_me['username'] ?? 'You'} (You)',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1B5E20),
                  ),
                ),
                Text(
                  (_me['institution'] ?? 'NO INSTITUTION').toString().toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    color: const Color(0xFF558B2F),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$xp',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1B5E20),
                ),
              ),
              Text(
                'XP',
                style: GoogleFonts.inter(
                  fontSize: 9,
                  color: const Color(0xFF558B2F),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
