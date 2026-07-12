import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../../utils/app_decorations.dart';
import '../../services/api_service.dart';
import '../../widgets/bengo_header.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic> _user = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final me = await ApiService.instance.getMe();
      if (mounted) {
        setState(() {
          _user = me;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Map<String, dynamic>?>(
      valueListenable: ApiService.instance.currentUserNotifier,
      builder: (context, userNotifierMap, _) {
        final displayUser = userNotifierMap ?? _user;
        final xp = (displayUser['xp'] ?? 0) as int;
        final streak = (displayUser['streak_days'] ?? 0) as int;

        return Scaffold(
          backgroundColor: AppColors.bgLight,
          body: SafeArea(
            child: CustomScrollView(
              slivers: [
                const SliverToBoxAdapter(child: BenGoHeader()),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    child: _buildWelcomeHeader(displayUser, streak, xp),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: _buildDailyRevisionCard(),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: _buildAnnouncementCard(),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    child: _buildNextLessonCard(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildWelcomeHeader(Map<String, dynamic> user, int streak, int xp) {
    final name = (user['first_name'] as String?)?.trim();
    final displayName = (name != null && name.isNotEmpty)
        ? name
        : ((user['username'] as String?)?.trim() ?? 'Samurai');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Good morning, $displayName',
          style: AppTextStyles.headlineLarge,
        ),
        const SizedBox(height: 6),
        Text(
          'Focus on today’s lesson and earn your next mastery level.',
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(child: _buildMiniInfoCard('$streak', 'DAY STREAK', Icons.local_fire_department_rounded, Colors.orange)),
            const SizedBox(width: 12),
            Expanded(child: _buildMiniInfoCard('$xp', 'TOTAL XP', Icons.bolt_rounded, AppColors.primary)),
          ],
        ),
      ],
    );
  }

  Widget _buildMiniInfoCard(String value, String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppDecorations.skeuomorphicCard(radius: 20),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withOpacity(0.16), color.withOpacity(0.05)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: AppTextStyles.displayMedium.copyWith(fontSize: 22, color: AppColors.textPrimary)),
                const SizedBox(height: 4),
                Text(label, style: AppTextStyles.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyRevisionCard() {
    return Container(
      decoration: AppDecorations.skeuomorphicCard(radius: 24),
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.repeat_rounded, color: AppColors.primary, size: 26),
          ),
          const SizedBox(height: 18),
          Text('Daily Revision', style: AppTextStyles.headlineMedium.copyWith(color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          Text(
            'Recall 15 items from Lesson 4 to maintain mastery.',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary, height: 1.5),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              ),
              child: Text(
                'STUDY NOW',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnnouncementCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppDecorations.skeuomorphicCard(radius: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('ANNOUNCEMENTS', style: AppTextStyles.captionUpper),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('LIMITED EVENT', style: AppTextStyles.labelSmall.copyWith(color: Colors.white)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text('Cherry Blossom Festival 2024', style: AppTextStyles.headlineSmall),
          const SizedBox(height: 8),
          Text(
            'Join the community challenge to earn exclusive badges and 500 bonus XP. Ends in 3 days.',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text('VIEW EVENT DETAILS', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNextLessonCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppDecorations.skeuomorphicCard(radius: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('NEXT LESSON', style: AppTextStyles.captionUpper),
          const SizedBox(height: 12),
          Text('Going to the Market', style: AppTextStyles.headlineMedium),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('CHAPTER 5 · 4/12', style: AppTextStyles.bodySmall),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.bgLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('CONTINUE', style: AppTextStyles.labelMedium.copyWith(color: AppColors.primary)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: LinearProgressIndicator(
              value: 4 / 12,
              minHeight: 8,
              backgroundColor: AppColors.borderLight,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accentGreen),
            ),
          ),
        ],
      ),
    );
  }

  Widget _avatar(int index, Color color) {
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        border: Border.all(color: Colors.white, width: 2),
      ),
    );
  }

  Widget _buildDailyGoalCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppDecorations.skeuomorphicCard(radius: 20),
      child: Row(
        children: [
          // Circular progress
          SizedBox(
            width: 72,
            height: 72,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: 0.65,
                  strokeWidth: 7,
                  backgroundColor: AppColors.borderLight,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
                Text(
                  '65\n%',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Daily Goal', style: AppTextStyles.headlineSmall),
                const SizedBox(height: 2),
                Text('45/60 min completed', style: AppTextStyles.bodySmall),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: 0.75,
                    backgroundColor: AppColors.borderLight,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accentGreen),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String value, String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppDecorations.skeuomorphicCard(radius: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentPathCard() {
    return Container(
      decoration: AppDecorations.skeuomorphicCard(radius: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image banner
          Container(
            height: 120,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              gradient: LinearGradient(
                colors: [Colors.brown.shade200, Colors.brown.shade100],
              ),
            ),
            child: Stack(
              children: [
                // Background placeholder
                Container(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    gradient: LinearGradient(
                      colors: [const Color(0xFFB8860B).withOpacity(0.7), const Color(0xFF8B4513).withOpacity(0.5)],
                    ),
                  ),
                  child: Center(
                    child: Icon(Icons.local_florist, color: Colors.white.withOpacity(0.4), size: 48),
                  ),
                ),
                // JLPT Badge
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Text('JLPT', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white)),
                        Text('N5', style: GoogleFonts.inter(fontSize: 10, color: Colors.white70)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CHAPTER 5',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Text('Going to the Market', style: AppTextStyles.headlineMedium),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('4 / 12', style: AppTextStyles.labelMedium),
                        Text('Lessons', style: AppTextStyles.bodySmall),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Learn common particles and shopping vocabulary used in daily Tokyo life.',
                  style: AppTextStyles.bodyMedium,
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.bgLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.bookmark_border_rounded, color: AppColors.textSecondary, size: 18),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDictionaryTile() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppDecorations.skeuomorphicCard(radius: 16),
      child: Column(
        children: [
          const Icon(Icons.g_translate_rounded, color: AppColors.primary, size: 28),
          const SizedBox(height: 8),
          Text(
            'DICTIONARY',
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}
