import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../../utils/app_decorations.dart';
import '../../services/api_service.dart';
import '../../widgets/bengo_header.dart';
import 'course_categories_screen.dart';

class CoursesScreen extends StatefulWidget {
  const CoursesScreen({super.key});

  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> {
  List<dynamic> _exams = [];
  bool _loading = true;
  String _error = '';
  final Map<int, Map<String, dynamic>> _rankByExamId = {};
  final Map<int, Map<String, dynamic>> _upgradeMetaByExamId = {};

  @override
  void initState() {
    super.initState();
    _loadExams();
  }

  Future<void> _loadExams() async {
    setState(() {
      _loading = true;
      _error = '';
    });
    try {
      final examsData = await ApiService.instance.getExams();
      final progressData = await ApiService.instance.getMyRankProgress();
      final rankByExamId = <int, Map<String, dynamic>>{};
      final upgradeMetaByExamId = <int, Map<String, dynamic>>{};

      for (final exam in examsData.whereType<Map<String, dynamic>>()) {
        final examId = exam['id'] as int?;
        if (examId == null) continue;

        final ranks = await ApiService.instance.getRanksForExam(examId);
        final rankList = ranks.whereType<Map<String, dynamic>>().toList();
        Map<String, dynamic>? matchedRank;

        for (final progress in progressData.whereType<Map<String, dynamic>>()) {
          final rankId = progress['rank'];
          if (ranks.any((rank) => rank['id'] == rankId)) {
            matchedRank = Map<String, dynamic>.from(progress);
            if (progress['is_current'] == true ||
                progress['is_completed'] == true) {
              break;
            }
          }
        }

        if (matchedRank == null && rankList.isNotEmpty) {
          final firstRank = rankList.first;
          matchedRank = {
            'rank': firstRank['id'],
            'rank_name': firstRank['name'],
            'rank_icon': firstRank['icon'],
            'rank_color': firstRank['color'],
            'is_current': true,
          };
        }

        if (matchedRank != null) {
          rankByExamId[examId] = matchedRank;
        }

        final currentRankId = matchedRank?['rank'] as int?;
        Map<String, dynamic>? nextRank;
        if (currentRankId != null) {
          final currentRank = rankList.firstWhere(
            (rank) => rank['id'] == currentRankId,
            orElse: () => <String, dynamic>{},
          );
          if (currentRank.isNotEmpty) {
            final currentOrder = currentRank['order'] as int? ?? 0;
            nextRank = rankList.where((rank) {
              final order = rank['order'] as int? ?? 0;
              return order > currentOrder;
            }).fold<Map<String, dynamic>?>(null, (prev, rank) => prev ?? rank);
          }
        }

        upgradeMetaByExamId[examId] = {
          'canUpgrade': matchedRank?['is_completed'] == true && nextRank != null,
          'nextRank': nextRank,
        };
      }

      setState(() {
        _exams = List<dynamic>.from(examsData);
        _rankByExamId.clear();
        _rankByExamId.addAll(rankByExamId);
        _upgradeMetaByExamId.clear();
        _upgradeMetaByExamId.addAll(upgradeMetaByExamId);
      });
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      // Fall back to static data if backend not available
      setState(() => _error = '');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadExams,
          color: AppColors.primary,
          child: CustomScrollView(
            slivers: [
              const SliverToBoxAdapter(child: BenGoHeader()),
              if (_error.isNotEmpty) SliverToBoxAdapter(child: _buildError()),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: _buildAvailableExamsHeader(),
                ),
              ),
              if (_loading)
                SliverToBoxAdapter(child: _buildLoading())
              else ...[
                // ── Unlocked / Available Exams ──────────────────────────────
                ..._exams.where((e) => e['is_unlocked'] == true).map(
                      (e) => SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: _buildExamCard(e, unlocked: true),
                        ),
                      ),
                    ),
                // ── Locked Exams ────────────────────────────────────────────
                if (_exams.any((e) => e['is_unlocked'] != true)) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: Text('Unlock Exams',
                          style: AppTextStyles.headlineLarge),
                    ),
                  ),
                  ..._exams.where((e) => e['is_unlocked'] != true).map(
                        (e) => SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                            child: _buildLockedExamCard(e),
                          ),
                        ),
                      ),
                ],
                // ── Fallback static data if no exams from backend ──────────
                if (_exams.isEmpty) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      child: _buildStaticN5Card(),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: Text('Unlock Exams',
                          style: AppTextStyles.headlineLarge),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child:
                          _buildStaticLocked('JLPT N4', 'Limited Proficiency'),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: _buildStaticLocked('JLPT N3', 'Intermediate'),
                    ),
                  ),
                ],
              ],
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  child: _buildBoostCard(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 40),
      child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
    );
  }

  Widget _buildError() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.wifi_off_rounded, color: Colors.orange, size: 18),
          const SizedBox(width: 8),
          Expanded(
              child: Text('Offline mode — showing cached data',
                  style: AppTextStyles.bodySmall)),
        ],
      ),
    );
  }

  // ── API exam card ──────────────────────────────────────────────────────────
  Widget _buildExamCard(Map<String, dynamic> exam, {required bool unlocked}) {
    final examId = exam['id'] as int?;
    final currentRank = examId == null ? null : _rankByExamId[examId];
    final upgradeMeta = examId == null ? null : _upgradeMetaByExamId[examId];
    final canUpgrade = upgradeMeta?['canUpgrade'] == true;
    final nextRank = (upgradeMeta?['nextRank'] as Map<String, dynamic>?) ?? const <String, dynamic>{};

    return GestureDetector(
      onTap: () async {
        if (!unlocked) {
          // Unlock the exam
          try {
            await ApiService.instance.unlockExam(exam['id'] as int);
            _loadExams();
          } catch (_) {}
          return;
        }
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => CourseCategoriesScreen(
              level: exam['level'] ?? 'N5',
              examId: exam['id'] as int,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: AppDecorations.skeuomorphicCard(radius: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.accentGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: AppColors.accentGreen.withOpacity(0.3)),
                  ),
                  child: Text(
                    'Level: ${exam['level']}',
                    style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.accentGreen,
                        fontWeight: FontWeight.w600),
                  ),
                ),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                      color: AppColors.bgLight,
                      borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.menu_book_rounded,
                      color: AppColors.primary, size: 22),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(exam['title'] ?? '',
                style: AppTextStyles.displayMedium.copyWith(height: 1.2)),
            const SizedBox(height: 8),
            Text(exam['description'] ?? '', style: AppTextStyles.bodyMedium),
            const SizedBox(height: 10),
            _buildRankBadge(currentRank),
            if (canUpgrade) ...[
              const SizedBox(height: 10),
              _buildUpgradeButton(exam, nextRank),
            ],
            const SizedBox(height: 12),
            Divider(color: AppColors.borderLight),
            const SizedBox(height: 12),
            Row(
              children: [
                _subjectChip(Icons.g_translate_rounded, 'Vocabulary'),
                const SizedBox(width: 12),
                _subjectChip(Icons.edit_note_rounded, 'Grammar'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLockedExamCard(Map<String, dynamic> exam) {
    return GestureDetector(
      onTap: () async {
        try {
          await ApiService.instance.unlockExam(exam['id'] as int);
          _loadExams();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${exam['title']} unlocked!')),
          );
        } catch (_) {}
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: AppDecorations.skeuomorphicCard(radius: 14),
        child: Row(
          children: [
            const Icon(Icons.lock_outlined,
                color: AppColors.textMuted, size: 20),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(exam['title'] ?? '', style: AppTextStyles.headlineSmall),
                  Text('${exam['level']} · Tap to unlock',
                      style: AppTextStyles.bodySmall),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.bgLight,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Text('UNLOCK',
                  style: GoogleFonts.inter(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                      letterSpacing: 0.5)),
            ),
          ],
        ),
      ),
    );
  }

  // ── Static fallback widgets (when backend is offline) ─────────────────────
  Widget _buildStaticN5Card() {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
            builder: (_) => const CourseCategoriesScreen(level: 'N5')),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: AppDecorations.skeuomorphicCard(radius: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.accentGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: AppColors.accentGreen.withOpacity(0.3)),
                  ),
                  child: Text('Level: N5',
                      style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppColors.accentGreen,
                          fontWeight: FontWeight.w600)),
                ),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                      color: AppColors.bgLight,
                      borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.menu_book_rounded,
                      color: AppColors.primary, size: 22),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text('JLPT N5\nProficiency',
                style: AppTextStyles.displayMedium.copyWith(height: 1.2)),
            const SizedBox(height: 8),
            Text('Foundation level Japanese for daily communication basics.',
                style: AppTextStyles.bodyMedium),
            const SizedBox(height: 16),
            Divider(color: AppColors.borderLight),
            const SizedBox(height: 12),
            Row(
              children: [
                _subjectChip(Icons.g_translate_rounded, 'Vocabulary'),
                const SizedBox(width: 12),
                _subjectChip(Icons.edit_note_rounded, 'Grammar'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStaticLocked(String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration:
          AppDecorations.skeuomorphicCard(color: AppColors.bgLight, radius: 14),
      child: Row(
        children: [
          const Icon(Icons.lock_outlined, color: AppColors.textMuted, size: 20),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.headlineSmall),
                Text(subtitle, style: AppTextStyles.bodySmall),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.bgLight,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Text('LOCKED',
                style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMuted,
                    letterSpacing: 0.5)),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailableExamsHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('Available Exams', style: AppTextStyles.headlineLarge),
        GestureDetector(
          onTap: _loadExams,
          child: Text('REFRESH',
              style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                  letterSpacing: 1)),
        ),
      ],
    );
  }

  Widget _buildUpgradeButton(Map<String, dynamic> exam, Map<String, dynamic> nextRank) {
    final nextRankName = (nextRank['name'] ?? 'Next rank').toString();
    return GestureDetector(
      onTap: () => _showUpgradeDialog(exam, nextRank),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primary, AppColors.primaryDark],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.rocket_launch_rounded, color: Colors.white, size: 14),
            const SizedBox(width: 8),
            Text(
              'Upgrade to $nextRankName',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showUpgradeDialog(Map<String, dynamic> exam, Map<String, dynamic> nextRank) async {
    final nextRankName = (nextRank['name'] ?? 'Next rank').toString();
    final nextRankIcon = (nextRank['icon'] ?? '🏆').toString();
    final passPct = nextRank['pass_percentage'] as int? ?? 70;
    final timer = nextRank['question_timer_seconds'] as int? ?? 30;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('Upgrade to $nextRankName'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${exam['title'] ?? 'Exam'} — ${exam['level'] ?? ''}'),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(nextRankIcon, style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 8),
                Expanded(child: Text(nextRankName, style: AppTextStyles.headlineSmall)),
              ],
            ),
            const SizedBox(height: 12),
            Text('Pass percentage: $passPct%'),
            const SizedBox(height: 4),
            Text('Question timer: ${timer}s'),
            const SizedBox(height: 4),
            Text('Your next lessons will start fresh with this rank’s settings.'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Upgrade'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ApiService.instance.upgradeRank(nextRank['id'] as int);
        await _loadExams();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upgraded to $nextRankName')),
        );
      } catch (_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Upgrade failed. Please try again.')),
        );
      }
    }
  }

  Widget _buildRankBadge(Map<String, dynamic>? rankProgress) {
    final rankName = (rankProgress?['rank_name'] ?? '').toString();
    final icon = (rankProgress?['rank_icon'] ?? '').toString().trim();
    final displayIcon = icon.isNotEmpty ? icon : '🏆';
    final label = rankName.isNotEmpty
        ? 'Current rank: $rankName'
        : 'Rank: Start learning';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primary.withAlpha(12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.primary.withAlpha(40)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(displayIcon, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _subjectChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.bgLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Text(label,
              style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildBoostCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppDecorations.skeuomorphicCard(radius: 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('EXP Boost',
                    style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                        letterSpacing: 1)),
                const SizedBox(height: 8),
                Text('1.5x',
                    style: AppTextStyles.statNumber.copyWith(fontSize: 32)),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: 0.6,
                    backgroundColor: AppColors.borderLight,
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(AppColors.primary),
                    minHeight: 5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          Column(
            children: [
              const Icon(Icons.military_tech_rounded,
                  color: AppColors.accentGreen, size: 36),
              const SizedBox(height: 8),
              Text('24 Day', style: AppTextStyles.headlineSmall),
              Text('Streak', style: AppTextStyles.bodySmall),
            ],
          ),
        ],
      ),
    );
  }
}
