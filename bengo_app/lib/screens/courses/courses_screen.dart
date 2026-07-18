import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/api_service.dart';
import '../../widgets/bengo_header.dart';
import 'course_categories_screen.dart';

// ── Design tokens ─────────────────────────────────────────────────────────────
const _kBg = Color(0xFFFAF8F5);
const _kSurface = Color(0xFFFFFFFF);
const _kAccent = Color(0xFFC41230);
const _kAccentShadow = Color(0x35C41230);
const _kInk = Color(0xFF1B1B1D);
const _kMuted = Color(0xFF8A8A8F);
const _kBorderLight = Color(0xFFEAE5E1);
const _kFieldTint = Color(0xFFFDF3F5);
const _kFieldBorder = Color(0xFFEDD5D8);
const _kGreenTint = Color(0xFFF0FDF4);
const _kGreenBorder = Color(0xFFBBF7D0);
const _kGreenText = Color(0xFF16A34A);

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
  Map<String, dynamic> _userData = {}; // real user xp/streak

  @override
  void initState() {
    super.initState();
    _loadExams();
    _loadUserStats();
  }

  Future<void> _loadUserStats() async {
    try {
      final cached = ApiService.instance.currentUserNotifier.value;
      if (cached != null) {
        if (mounted) setState(() => _userData = cached);
        return;
      }
      final me = await ApiService.instance.getMe();
      if (mounted) setState(() => _userData = me);
    } catch (_) {}
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

        if (matchedRank != null) rankByExamId[examId] = matchedRank;

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
          'canUpgrade':
              matchedRank?['is_completed'] == true && nextRank != null,
          'nextRank': nextRank,
        };
      }

      setState(() {
        _exams = List<dynamic>.from(examsData);
        _rankByExamId
          ..clear()
          ..addAll(rankByExamId);
        _upgradeMetaByExamId
          ..clear()
          ..addAll(upgradeMetaByExamId);
      });
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = '');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadExams,
          color: _kAccent,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              const SliverToBoxAdapter(child: BenGoHeader()),
              if (_error.isNotEmpty) SliverToBoxAdapter(child: _buildError()),
              // Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
                  child: _buildHeader(),
                ),
              ),
              if (_loading)
                const SliverToBoxAdapter(child: _LoadingWidget())
              else ...[
                if (_exams.any((e) => e['is_unlocked'] == true)) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                      child: Text(
                        'Your Exams',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: _kInk,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                  ),
                  ..._exams.where((e) => e['is_unlocked'] == true).map(
                        (e) => SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                            child: _buildExamCard(e, unlocked: true),
                          ),
                        ),
                      ),
                ],
                if (_exams.any((e) => e['is_unlocked'] != true)) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                      child: Text(
                        'Unlock for more progress',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: _kInk,
                          letterSpacing: -0.4,
                        ),
                      ),
                    ),
                  ),
                  ..._exams.where((e) => e['is_unlocked'] != true).map(
                        (e) => SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                            child: _buildLockedExamCard(e),
                          ),
                        ),
                      ),
                ],
                if (_exams.isEmpty) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      child: _buildStaticN5Card(),
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Available Exams',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: _kInk,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Choose your JLPT path and start studying.',
          style: GoogleFonts.inter(fontSize: 12, color: _kMuted),
        ),
      ],
    );
  }

  Widget _buildError() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFED7AA)),
      ),
      child: Row(
        children: [
          const Icon(Icons.wifi_off_rounded,
              color: Color(0xFFEA580C), size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text('Offline mode — showing cached data',
                style: GoogleFonts.inter(fontSize: 12, color: _kMuted)),
          ),
        ],
      ),
    );
  }

  Widget _buildExamCard(Map<String, dynamic> exam, {required bool unlocked}) {
    final examId = exam['id'] as int?;
    final currentRank = examId == null ? null : _rankByExamId[examId];
    final rankName = (currentRank?['rank_name'] ?? '').toString();
    final rankIcon = (currentRank?['rank_icon'] ?? '🏆').toString();
    final title = (exam['title'] ?? '').toString();
    final description = (exam['description'] ?? '').toString();
    final level = (exam['level'] ?? '').toString();

    return _TappableCard(
      onTap: () async {
        if (!unlocked) {
          try {
            await ApiService.instance.unlockExam(exam['id'] as int);
            if (!mounted) return;
            await _loadExams();
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${exam['title']} unlocked!')),
            );
          } catch (_) {}
          return;
        }
        await _showRankJourneySheet(exam);
      },
      child: Container(
        decoration: BoxDecoration(
          color: _kSurface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: _kBorderLight),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0F000000),
              blurRadius: 20,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: _kFieldTint,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      level.isNotEmpty ? level : 'JLPT',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _kAccent,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: unlocked ? const Color(0xFFEAEAF8) : _kFieldTint,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      unlocked ? 'Ready' : 'Locked',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: unlocked ? const Color(0xFF3B49DF) : _kMuted,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                title,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: _kInk,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: _kMuted,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEDF7F0),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Row(
                      children: [
                        Text(rankIcon, style: const TextStyle(fontSize: 14)),
                        const SizedBox(width: 8),
                        Text(
                          rankName.isNotEmpty
                              ? 'Rank • $rankName'
                              : 'Rank • New',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: _kAccent,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 11),
                    decoration: BoxDecoration(
                      color: unlocked ? const Color(0xFF1B1B1D) : _kFieldTint,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      unlocked ? 'OPEN' : 'UNLOCK',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: unlocked ? Colors.white : _kAccent,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Locked exam row ────────────────────────────────────────────────────────
  Widget _buildLockedExamCard(Map<String, dynamic> exam) {
    final title = (exam['title'] ?? '').toString();
    final level = (exam['level'] ?? '').toString();

    return _TappableCard(
      onTap: () async {
        try {
          await ApiService.instance.unlockExam(exam['id'] as int);
          if (!mounted) return;
          await _loadExams();
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$title unlocked!')),
          );
        } catch (_) {}
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF8F5FF),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFE9DFFB)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.lock_outline_rounded,
                    color: _kAccent, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: _kInk,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Level $level · Tap to unlock and start',
                      style: GoogleFonts.inter(fontSize: 12, color: _kMuted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: _kAccent,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  'UNLOCK',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Static fallback N5 card ────────────────────────────────────────────────
  Widget _buildStaticN5Card() {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
            builder: (_) => const CourseCategoriesScreen(level: 'N5')),
      ),
      child: Container(
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _kGreenTint,
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(color: _kGreenBorder),
                  ),
                  child: Text('Level: N5',
                      style: GoogleFonts.inter(
                          fontSize: 11,
                          color: _kGreenText,
                          fontWeight: FontWeight.w700)),
                ),
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: _kFieldTint,
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(color: _kFieldBorder),
                  ),
                  child: const Icon(Icons.menu_book_rounded,
                      color: _kAccent, size: 22),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text('JLPT N5\nProficiency',
                style: GoogleFonts.spaceGrotesk(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: _kInk,
                    height: 1.2,
                    letterSpacing: -0.4)),
            const SizedBox(height: 6),
            Text('Foundation level Japanese for daily communication basics.',
                style: GoogleFonts.inter(
                    fontSize: 13, color: _kMuted, height: 1.5)),
            const SizedBox(height: 16),
            Divider(color: _kBorderLight, height: 1),
            const SizedBox(height: 14),
            Row(
              children: [
                _SubjectChip(
                    icon: Icons.g_translate_rounded, label: 'Vocabulary'),
                const SizedBox(width: 10),
                _SubjectChip(icon: Icons.edit_note_rounded, label: 'Grammar'),
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
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorderLight),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.lock_outline_rounded,
                color: Color(0xFFB0B0B0), size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: _kInk)),
                Text(subtitle,
                    style: GoogleFonts.inter(fontSize: 12, color: _kMuted)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(100),
              border: Border.all(color: _kBorderLight),
            ),
            child: Text('LOCKED',
                style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: _kMuted,
                    letterSpacing: 0.5)),
          ),
        ],
      ),
    );
  }

  // ── Rank badge ─────────────────────────────────────────────────────────────
  Widget _buildRankBadge(Map<String, dynamic>? rankProgress) {
    final rankName = (rankProgress?['rank_name'] ?? '').toString();
    final icon = (rankProgress?['rank_icon'] ?? '').toString().trim();
    final displayIcon = icon.isNotEmpty ? icon : '🏆';
    final label = rankName.isNotEmpty
        ? 'Current rank: $rankName'
        : 'Rank: Start learning';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: _kFieldTint,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: _kFieldBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(displayIcon, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.inter(
                fontSize: 12, fontWeight: FontWeight.w700, color: _kAccent),
          ),
        ],
      ),
    );
  }

  // ── Upgrade button ─────────────────────────────────────────────────────────
  Widget _buildUpgradeButton(
      Map<String, dynamic> exam, Map<String, dynamic> nextRank) {
    final nextRankName = (nextRank['name'] ?? 'Next rank').toString();
    return GestureDetector(
      onTap: () => _showUpgradeDialog(exam, nextRank),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: _kAccent,
          borderRadius: BorderRadius.circular(100),
          boxShadow: const [
            BoxShadow(
                color: _kAccentShadow, blurRadius: 0, offset: Offset(0, 3)),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.rocket_launch_rounded,
                color: Colors.white, size: 14),
            const SizedBox(width: 8),
            Text(
              'Upgrade to $nextRankName',
              style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  // ── Rank Journey bottom sheet ──────────────────────────────────────────────
  Future<void> _showRankJourneySheet(Map<String, dynamic> exam) async {
    final examId = exam['id'] as int?;
    if (examId == null) return;

    try {
      final ranks = await ApiService.instance.getRanksForExam(examId);
      final progressData = await ApiService.instance.getMyRankProgress();
      final rankProgresses = progressData
          .whereType<Map<String, dynamic>>()
          .where((p) => (p['exam_id'] as int?) == examId)
          .toList();
      final progressByRankId = <int, Map<String, dynamic>>{};
      for (final p in rankProgresses) {
        final rankId = p['rank'] as int?;
        if (rankId != null)
          progressByRankId[rankId] = Map<String, dynamic>.from(p);
      }

      if (!mounted) return;
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (sheetContext) {
          return DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.8,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            builder: (scrollContext, controller) {
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                          color: _kBorderLight,
                          borderRadius: BorderRadius.circular(100)),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  exam['title'] ?? 'Exam',
                                  style: GoogleFonts.spaceGrotesk(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                      color: _kInk,
                                      letterSpacing: -0.3),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Choose a rank path to continue, review, or replay.',
                                  style: GoogleFonts.inter(
                                      fontSize: 12, color: _kMuted),
                                ),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.pop(sheetContext),
                            child: Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: _kBg,
                                shape: BoxShape.circle,
                                border: Border.all(color: _kBorderLight),
                              ),
                              child: const Icon(Icons.close_rounded,
                                  size: 16, color: _kMuted),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Expanded(
                      child: ListView.builder(
                        controller: controller,
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                        itemCount: ranks.length,
                        itemBuilder: (context, index) {
                          final rank = ranks[index] as Map<String, dynamic>;
                          final progress = progressByRankId[rank['id'] as int];
                          final isCompleted = progress?['is_completed'] == true;
                          final isCurrent = progress?['is_current'] == true;
                          final firstRankId = ranks.isNotEmpty
                              ? ranks.first['id'] as int?
                              : null;
                          final isFirstRank =
                              firstRankId != null && rank['id'] == firstRankId;
                          final hasProgress = progress != null;
                          final canOpen = hasProgress || isFirstRank;
                          final progressLabel = isCompleted
                              ? 'Completed'
                              : canOpen
                                  ? 'Current rank'
                                  : 'Locked';
                          final icon = (rank['icon'] ?? '🏆').toString();
                          final percent =
                              ((progress?['progress_pct'] as num?) ?? 0)
                                  .toDouble();

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isCompleted ? _kGreenTint : _kBg,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                  color: isCompleted
                                      ? _kGreenBorder
                                      : _kBorderLight),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(icon,
                                        style: const TextStyle(fontSize: 20)),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(rank['name'] ?? 'Rank',
                                          style: GoogleFonts.inter(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                              color: _kInk)),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: isCompleted
                                            ? _kGreenText
                                            : _kAccent,
                                        borderRadius:
                                            BorderRadius.circular(100),
                                      ),
                                      child: Text(progressLabel,
                                          style: GoogleFonts.inter(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.white)),
                                    ),
                                  ],
                                ),
                                if (progress != null) ...[
                                  const SizedBox(height: 10),
                                  Text(
                                    '${progress['completed_lessons'] ?? 0}/${progress['total_lessons'] ?? 0} lessons · ${percent.toStringAsFixed(0)}%',
                                    style: GoogleFonts.inter(
                                        fontSize: 11, color: _kMuted),
                                  ),
                                  const SizedBox(height: 6),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(100),
                                    child: LinearProgressIndicator(
                                      value: percent / 100,
                                      minHeight: 6,
                                      backgroundColor: _kBorderLight,
                                      valueColor:
                                          const AlwaysStoppedAnimation<Color>(
                                              _kAccent),
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 14),
                                SizedBox(
                                  width: double.infinity,
                                  height: 46,
                                  child: ElevatedButton(
                                    onPressed: canOpen
                                        ? () async {
                                            if (progress != null) {
                                              await ApiService.instance
                                                  .activateRank(
                                                      progress['id'] as int);
                                            }
                                            if (!mounted) return;
                                            Navigator.pop(sheetContext);
                                            Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    CourseCategoriesScreen(
                                                  level: exam['level'] ?? 'N5',
                                                  examId: examId,
                                                ),
                                              ),
                                            );
                                          }
                                        : null,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          canOpen ? _kAccent : _kBorderLight,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(100)),
                                      elevation: 0,
                                    ),
                                    child: Text(
                                      isCompleted
                                          ? 'Review this rank'
                                          : (canOpen
                                              ? 'Open this rank'
                                              : 'Locked'),
                                      style: GoogleFonts.inter(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13),
                                    ),
                                  ),
                                ),
                                if (isCompleted) ...[
                                  const SizedBox(height: 8),
                                  TextButton.icon(
                                    onPressed: () async {
                                      if (progress == null) return;
                                      final logs = await ApiService.instance
                                          .getRankLogs(progress['id'] as int);
                                      if (!mounted) return;
                                      showModalBottomSheet(
                                        context: context,
                                        isScrollControlled: true,
                                        backgroundColor: Colors.transparent,
                                        builder: (detailContext) =>
                                            DraggableScrollableSheet(
                                          expand: false,
                                          initialChildSize: 0.7,
                                          minChildSize: 0.5,
                                          maxChildSize: 0.95,
                                          builder: (detailScrollContext,
                                                  detailController) =>
                                              Container(
                                            decoration: const BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.vertical(
                                                      top: Radius.circular(28)),
                                            ),
                                            child: Column(
                                              children: [
                                                const SizedBox(height: 12),
                                                Container(
                                                  width: 40,
                                                  height: 4,
                                                  decoration: BoxDecoration(
                                                      color: _kBorderLight,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              100)),
                                                ),
                                                const SizedBox(height: 14),
                                                Padding(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 20),
                                                  child: Row(
                                                    children: [
                                                      Expanded(
                                                        child: Text(
                                                          'Rank history',
                                                          style: GoogleFonts
                                                              .spaceGrotesk(
                                                            fontSize: 20,
                                                            fontWeight:
                                                                FontWeight.w700,
                                                            color: _kInk,
                                                          ),
                                                        ),
                                                      ),
                                                      GestureDetector(
                                                        onTap: () =>
                                                            Navigator.pop(
                                                                detailContext),
                                                        child: Container(
                                                          width: 34,
                                                          height: 34,
                                                          decoration:
                                                              BoxDecoration(
                                                            color: _kBg,
                                                            shape:
                                                                BoxShape.circle,
                                                            border: Border.all(
                                                                color:
                                                                    _kBorderLight),
                                                          ),
                                                          child: const Icon(
                                                              Icons
                                                                  .close_rounded,
                                                              size: 16,
                                                              color: _kMuted),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                const SizedBox(height: 10),
                                                Expanded(
                                                  child: ListView.builder(
                                                    controller:
                                                        detailController,
                                                    padding: const EdgeInsets
                                                        .fromLTRB(
                                                        20, 8, 20, 24),
                                                    itemCount: logs.length,
                                                    itemBuilder:
                                                        (logContext, logIndex) {
                                                      final log = logs[logIndex]
                                                          as Map<String,
                                                              dynamic>;
                                                      return Container(
                                                        margin: const EdgeInsets
                                                            .only(bottom: 10),
                                                        padding:
                                                            const EdgeInsets
                                                                .all(14),
                                                        decoration:
                                                            BoxDecoration(
                                                          color: _kBg,
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(14),
                                                          border: Border.all(
                                                              color:
                                                                  _kBorderLight),
                                                        ),
                                                        child: Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            Text(
                                                              log['lesson_name']
                                                                      ?.toString() ??
                                                                  'Lesson',
                                                              style: GoogleFonts.inter(
                                                                  fontSize: 13,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                  color: _kInk),
                                                            ),
                                                            const SizedBox(
                                                                height: 3),
                                                            Text(
                                                              '${(log['score_pct'] as num?)?.toStringAsFixed(0) ?? '0'}% · ${log['correct'] ?? 0}/${log['wrong'] ?? 0} correct/wrong',
                                                              style: GoogleFonts
                                                                  .inter(
                                                                      fontSize:
                                                                          11,
                                                                      color:
                                                                          _kMuted),
                                                            ),
                                                          ],
                                                        ),
                                                      );
                                                    },
                                                  ),
                                                ),
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.fromLTRB(
                                                          20, 0, 20, 20),
                                                  child: SizedBox(
                                                    width: double.infinity,
                                                    height: 48,
                                                    child: ElevatedButton(
                                                      onPressed: () async {
                                                        final certificates =
                                                            await ApiService
                                                                .instance
                                                                .getMyCertificates();
                                                        final cert = certificates
                                                            .whereType<
                                                                Map<String,
                                                                    dynamic>>()
                                                            .firstWhere(
                                                              (item) =>
                                                                  (item['certificate'] as Map<
                                                                          String,
                                                                          dynamic>?)?[
                                                                      'rank'] ==
                                                                  rank['id'],
                                                              orElse: () =>
                                                                  <String,
                                                                      dynamic>{},
                                                            );
                                                        final url = ((cert['certificate']
                                                                        as Map<
                                                                            String,
                                                                            dynamic>?)?[
                                                                    'template_url'] ??
                                                                '')
                                                            .toString();
                                                        if (url.isNotEmpty) {
                                                          await launchUrl(
                                                              Uri.parse(url),
                                                              mode: LaunchMode
                                                                  .externalApplication);
                                                        }
                                                      },
                                                      style: ElevatedButton
                                                          .styleFrom(
                                                        backgroundColor:
                                                            _kAccent,
                                                        foregroundColor:
                                                            Colors.white,
                                                        shape: RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        100)),
                                                        elevation: 0,
                                                      ),
                                                      child: Text(
                                                          'Open certificate',
                                                          style:
                                                              GoogleFonts.inter(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w700)),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.history_rounded,
                                        size: 16),
                                    label: Text('View logs',
                                        style: GoogleFonts.inter(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600)),
                                    style: TextButton.styleFrom(
                                        foregroundColor: _kAccent),
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      );
    } catch (_) {}
  }

  Future<void> _showUpgradeDialog(
      Map<String, dynamic> exam, Map<String, dynamic> nextRank) async {
    final nextRankName = (nextRank['name'] ?? 'Next rank').toString();
    final nextRankIcon = (nextRank['icon'] ?? '🏆').toString();
    final passPct = nextRank['pass_percentage'] as int? ?? 70;
    final timer = nextRank['question_timer_seconds'] as int? ?? 30;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: _kSurface,
        title: Text('Upgrade to $nextRankName',
            style: GoogleFonts.spaceGrotesk(
                fontWeight: FontWeight.w700, color: _kInk)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${exam['title'] ?? 'Exam'} — ${exam['level'] ?? ''}',
                style: GoogleFonts.inter(fontSize: 12, color: _kMuted)),
            const SizedBox(height: 10),
            Row(
              children: [
                Text(nextRankIcon, style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 8),
                Expanded(
                    child: Text(nextRankName,
                        style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: _kInk))),
              ],
            ),
            const SizedBox(height: 12),
            Text('Pass percentage: $passPct%',
                style: GoogleFonts.inter(fontSize: 13, color: _kInk)),
            const SizedBox(height: 4),
            Text('Question timer: ${timer}s',
                style: GoogleFonts.inter(fontSize: 13, color: _kInk)),
            const SizedBox(height: 4),
            Text(
                'Your next lessons will start fresh with this rank\'s settings.',
                style: GoogleFonts.inter(fontSize: 12, color: _kMuted)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: GoogleFonts.inter(color: _kMuted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _kAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(100)),
              elevation: 0,
            ),
            child: Text('Upgrade',
                style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
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
}

// ═══════════════════════════════════════════════════════════════════════════════
// LOCAL COMPONENTS
// ═══════════════════════════════════════════════════════════════════════════════

class _LoadingWidget extends StatelessWidget {
  const _LoadingWidget();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 48),
      child: Center(
          child: CircularProgressIndicator(color: _kAccent, strokeWidth: 2.5)),
    );
  }
}

class _SubjectChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _SubjectChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _kBg,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: _kBorderLight),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: _kMuted),
          const SizedBox(width: 5),
          Text(label,
              style: GoogleFonts.inter(
                  fontSize: 10, color: _kMuted, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

// ── Tappable card wrapper ──────────────────────────────────────────────────────
class _TappableCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  const _TappableCard({required this.child, this.onTap});

  @override
  State<_TappableCard> createState() => _TappableCardState();
}

class _TappableCardState extends State<_TappableCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap?.call();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.975 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          decoration: BoxDecoration(
            color: _kSurface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: _pressed ? _kAccent.withOpacity(0.35) : _kBorderLight,
            ),
            boxShadow: _pressed
                ? const [
                    BoxShadow(
                      color: Color(0x18C41230),
                      blurRadius: 20,
                      offset: Offset(0, 6),
                    ),
                  ]
                : const [
                    BoxShadow(
                      color: Color(0x08000000),
                      blurRadius: 16,
                      offset: Offset(0, 5),
                    ),
                  ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
