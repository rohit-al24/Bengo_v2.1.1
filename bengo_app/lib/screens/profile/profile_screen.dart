import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../../utils/app_decorations.dart';
import '../../services/api_service.dart';
import '../../widgets/bengo_header.dart';
import '../friends/friends_screen.dart';
import '../leaderboard/leaderboard_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic> _user = {};
  Map<String, dynamic> _progress = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _loading = true);

    // Try to load cached user first for instant display
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString('user');
    if (cached != null && cached.isNotEmpty) {
      try {
        final parsed = Map<String, dynamic>.from(
          await _parseJson(cached),
        );
        if (mounted) setState(() => _user = parsed);
      } catch (_) {}
    }

    // Then fetch fresh data from API
    try {
      final me = await ApiService.instance.getMe();
      final progress = await ApiService.instance.getMyProgress();
      if (mounted) {
        setState(() {
          _user = me;
          _progress = progress;
        });
        // Update cache
        prefs.setString('user', jsonEncode(me));
      }
    } catch (_) {
      // Keep cached data
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<Map<String, dynamic>> _parseJson(String s) async {
    return jsonDecode(s) as Map<String, dynamic>;
  }

  String get _displayName {
    final u = _user;
    final name = (u['first_name'] ?? '').toString().trim();
    final last = (u['last_name'] ?? '').toString().trim();
    if (name.isNotEmpty || last.isNotEmpty) return '$name $last'.trim();
    return (u['username'] ?? 'User').toString();
  }

  String get _displayUsername => '@${_user['username'] ?? 'user'}';
  String get _displayEmail    => _user['email']?.toString() ?? '';
  int    get _xp              => (_user['xp']         ?? _progress['xp']         ?? 0) as int;
  int    get _streak          => (_user['streak_days'] ?? _progress['streak_days'] ?? 0) as int;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Map<String, dynamic>?>(
      valueListenable: ApiService.instance.currentUserNotifier,
      builder: (context, userNotifierMap, _) {
        final displayUser = userNotifierMap ?? _user;
        final xp = (displayUser['xp'] ?? _progress['xp'] ?? 0) as int;
        final streak = (displayUser['streak_days'] ?? _progress['streak_days'] ?? 0) as int;
        final displayName = () {
          final name = (displayUser['first_name'] ?? '').toString().trim();
          final last = (displayUser['last_name'] ?? '').toString().trim();
          if (name.isNotEmpty || last.isNotEmpty) return '$name $last'.trim();
          return (displayUser['username'] ?? 'User').toString();
        }();
        final displayUsername = '@${displayUser['username'] ?? 'user'}';
        final displayEmail = displayUser['email']?.toString() ?? '';

        return Scaffold(
          backgroundColor: AppColors.bgLight,
          body: SafeArea(
            child: RefreshIndicator(
              onRefresh: _loadProfile,
              color: AppColors.primary,
              child: CustomScrollView(
                slivers: [
                  const SliverToBoxAdapter(child: BenGoHeader()),
                  SliverToBoxAdapter(child: _buildProfileHeader(displayName, displayUsername)),
                  if (displayEmail.isNotEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                        child: _buildInfoRow(Icons.mail_outline_rounded, displayEmail),
                      ),
                    ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: _buildStatsCard(xp, streak),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: _buildProgressSection(),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: _buildMembershipCard(),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: _buildCertificationsSection(context),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                      child: _buildFriendsButton(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }




  Widget _buildProfileHeader(String name, String username) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          children: [
            Stack(
              alignment: Alignment.bottomCenter,
              children: [
                Container(
                  width: 90, height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFE8CFA0),
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 12)],
                  ),
                  child: _loading
                      ? const CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2)
                      : const Icon(Icons.person, size: 48, color: Color(0xFF8B4513)),
                ),
                Positioned(
                  bottom: -6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(color: AppColors.accentGreen, borderRadius: BorderRadius.circular(12)),
                    child: Text('LEARNER', style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 0.5)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(name, style: AppTextStyles.headlineMedium),
            const SizedBox(height: 2),
            Text(username, style: AppTextStyles.bodySmall),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.edit, size: 14, color: AppColors.primary),
              label: Text('EDIT PROFILE', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary, letterSpacing: 1)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: AppDecorations.skeuomorphicCard(radius: 12),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 18),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: AppTextStyles.bodyMedium)),
        ],
      ),
    );
  }

  Widget _buildStatsCard(int xp, int streak) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppDecorations.skeuomorphicCard(radius: 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.bolt_rounded, color: AppColors.primary, size: 24),
                const SizedBox(height: 6),
                Text(xp.toString(), style: AppTextStyles.statNumber),
                Text('TOTAL XP', style: AppTextStyles.captionUpper),
              ],
            ),
          ),
          Container(width: 1, height: 60, color: AppColors.borderLight),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 30),
                  Text(streak.toString(), style: AppTextStyles.statNumber),
                  Text('DAY STREAK', style: AppTextStyles.captionUpper),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSection() {
    final unlocked = (_progress['unlocked_exams'] as List? ?? []);
    final lessonProg = (_progress['lesson_progress'] as List? ?? []);
    final completed = lessonProg.where((l) => l['is_completed'] == true).length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppDecorations.skeuomorphicCard(radius: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Learning Progress', style: AppTextStyles.headlineMedium),
          const SizedBox(height: 14),
          Row(
            children: [
              _progressStat('${unlocked.length}', 'Exams Unlocked', Icons.lock_open_rounded),
              const SizedBox(width: 12),
              _progressStat('$completed', 'Lessons Done', Icons.check_circle_outline_rounded),
              const SizedBox(width: 12),
              _progressStat('${lessonProg.length}', 'In Progress', Icons.trending_up_rounded),
            ],
          ),
        ],
      ),
    );
  }

  Widget _progressStat(String value, String label, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: AppDecorations.skeuomorphicCard(color: AppColors.bgLight, radius: 12),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary, size: 20),
            const SizedBox(height: 6),
            Text(value, style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
            Text(label, style: AppTextStyles.captionUpper.copyWith(fontSize: 8), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildMembershipCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppDecorations.skeuomorphicCard(color: AppColors.primary, radius: 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('MEMBERSHIP STATUS', style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w600, color: Colors.white70, letterSpacing: 1)),
                const SizedBox(height: 4),
                Text('Active Member', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
            child: Text('MANAGE', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  Widget _buildCertificationsSection(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Certifications', style: AppTextStyles.headlineMedium),
            Text('View All', style: GoogleFonts.inter(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _certBadge('あa', 'JLPT N5\nMastery'),
            const SizedBox(width: 12),
            _certBadge('⌨', 'Logic\nGates'),
            const SizedBox(width: 12),
            _certBadge('🏆', 'Top 1%\nGlobal'),
          ],
        ),
      ],
    );
  }

  Widget _certBadge(String icon, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: AppDecorations.skeuomorphicCard(radius: 14),
        child: Column(
          children: [
            Text(icon, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 8),
            Text(label, textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 10, color: AppColors.textSecondary, height: 1.3)),
          ],
        ),
      ),
    );
  }

  Widget _buildFriendsButton(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FriendsScreen())),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: AppDecorations.skeuomorphicCard(radius: 14),
        child: Row(
          children: [
            const Icon(Icons.people_outline_rounded, color: AppColors.primary),
            const SizedBox(width: 12),
            Text('Friends & Network', style: AppTextStyles.headlineSmall),
            const Spacer(),
            const Icon(Icons.chevron_right, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}
