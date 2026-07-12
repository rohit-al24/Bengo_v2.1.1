import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../../widgets/bengo_app_bar.dart';
import '../../services/api_service.dart';
import '../../widgets/bottom_nav.dart';
import '../vocabulary/vocabulary_path_screen.dart';

/// Screen shown after tapping a JLPT exam card.
/// When examId is provided, loads real categories from API.
class CourseCategoriesScreen extends StatefulWidget {
  final String level; // e.g. "N5"
  final int? examId; // null = static demo mode

  const CourseCategoriesScreen({
    super.key,
    required this.level,
    this.examId,
  });

  @override
  State<CourseCategoriesScreen> createState() => _CourseCategoriesScreenState();
}

class _CourseCategoriesScreenState extends State<CourseCategoriesScreen> {
  List<dynamic> _categories = [];
  bool _loading = false;
  String _examTitle = '';
  Map<String, dynamic>? _currentRank;

  // Static fallback icons mapped by category title
  static final _iconMap = <String, Map<String, dynamic>>{
    'Vocabulary': {
      'icon': Icons.g_translate_rounded,
      'color': const Color(0xFFE8F5E9),
      'iconColor': const Color(0xFF2E7D32)
    },
    'Grammar': {
      'icon': Icons.edit_note_rounded,
      'color': const Color(0xFFE3F2FD),
      'iconColor': const Color(0xFF1565C0)
    },
    'Kanji': {
      'icon': Icons.brush_rounded,
      'color': const Color(0xFFFFF3E0),
      'iconColor': const Color(0xFFE65100)
    },
    'Listening': {
      'icon': Icons.hearing_rounded,
      'color': const Color(0xFFF3E5F5),
      'iconColor': const Color(0xFF6A1B9A)
    },
    'Speaking': {
      'icon': Icons.record_voice_over_rounded,
      'color': const Color(0xFFFFEBEE),
      'iconColor': const Color(0xFFB71C1C)
    },
  };
  static const _defaultMeta = {
    'icon': Icons.menu_book_rounded,
    'color': Color(0xFFECEFF1),
    'iconColor': Color(0xFF455A64)
  };

  // Static demo categories (used when no examId)
  static const _staticCategories = [
    {
      'id': null,
      'title': 'Vocabulary',
      'description': 'Learn essential words & meanings',
      'lessons_count': 10
    },
    {
      'id': null,
      'title': 'Grammar',
      'description': 'Master sentence patterns & particles',
      'lessons_count': 8
    },
    {
      'id': null,
      'title': 'Kanji',
      'description': 'Read & write essential characters',
      'lessons_count': 6
    },
    {
      'id': null,
      'title': 'Listening',
      'description': 'Train your ear with real audio',
      'lessons_count': 5
    },
    {
      'id': null,
      'title': 'Speaking',
      'description': 'Practice pronunciation & speech',
      'lessons_count': 4
    },
  ];

  @override
  void initState() {
    super.initState();
    if (widget.examId != null) {
      _loadFromApi();
    } else {
      _categories = List<dynamic>.from(_staticCategories);
    }
  }

  Future<void> _loadFromApi() async {
    setState(() => _loading = true);
    try {
      final exam = await ApiService.instance.getExam(widget.examId!);
      final progressData = await ApiService.instance.getMyRankProgress();
      final ranks = await ApiService.instance.getRanksForExam(widget.examId!);
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

      setState(() {
        _examTitle = exam['title'] ?? '';
        _categories = List<dynamic>.from(exam['categories'] ?? []);
        _currentRank = matchedRank;
      });
    } catch (_) {
      // Fall back to static
      setState(() {
        _categories = List<dynamic>.from(_staticCategories);
        _currentRank = null;
      });
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      bottomNavigationBar: BenGoBottomNav(
        currentIndex: 1,
        onTap: (i) {
          if (i != 1) Navigator.of(context).popUntil((r) => r.isFirst);
        },
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildAppBar(context)),
            SliverToBoxAdapter(child: _buildHeader()),
            SliverToBoxAdapter(child: _buildProgressCard()),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text('Study Categories',
                    style: AppTextStyles.headlineLarge),
              ),
            ),
            if (_loading)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                      child:
                          CircularProgressIndicator(color: AppColors.primary)),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) => Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: _buildCategoryCard(context, _categories[i]),
                  ),
                  childCount: _categories.length,
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return BenGoAppBar(
      showBack: true,
      actions: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'JLPT ${widget.level}',
            style: GoogleFonts.inter(
                fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    final title =
        _examTitle.isNotEmpty ? _examTitle : 'JLPT ${widget.level} Proficiency';
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.displayMedium),
          const SizedBox(height: 6),
          Text('Choose a category to begin your learning path.',
              style: AppTextStyles.bodyMedium),
          const SizedBox(height: 12),
          _buildRankBadge(_currentRank),
        ],
      ),
    );
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

  Widget _buildProgressCard() {
    final total = _categories.fold<int>(0, (sum, c) {
      final count = c['lessons_count'] ?? c['lessons']?.length ?? 0;
      return sum + (count as int);
    });

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primary, AppColors.primaryDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('OVERALL PROGRESS',
                      style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.white70,
                          letterSpacing: 1)),
                  const SizedBox(height: 4),
                  Text('${_categories.length} Categories',
                      style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white)),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: 0.0,
                      backgroundColor: Colors.white.withOpacity(0.2),
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(Colors.white),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Icon(Icons.emoji_events_rounded,
                    color: Colors.amber, size: 32),
                const SizedBox(height: 4),
                Text('$total',
                    style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
                Text('total lessons',
                    style:
                        GoogleFonts.inter(fontSize: 10, color: Colors.white70)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard(BuildContext context, dynamic cat) {
    final title = (cat['title'] ?? cat['label'] ?? 'Category') as String;
    final desc = (cat['description'] ?? 'Study materials') as String;
    final lessonsCount =
        cat['lessons_count'] ?? (cat['lessons'] as List?)?.length ?? 0;
    final catId = cat['id'] as int?;
    final lessons = cat['lessons'] as List? ?? [];
    final meta = _iconMap[title] ?? _defaultMeta;

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => VocabularyPathScreen(
              level: widget.level,
              category: title,
              examId: widget.examId,
              catId: catId,
              apiLessons: lessons.isNotEmpty ? lessons : null,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.bgWhite,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12)
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: meta['color'] as Color,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(meta['icon'] as IconData,
                  color: meta['iconColor'] as Color, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.headlineMedium),
                  const SizedBox(height: 2),
                  Text(desc, style: AppTextStyles.bodySmall),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        width: 80,
                        height: 4,
                        decoration: BoxDecoration(
                            color: AppColors.borderLight,
                            borderRadius: BorderRadius.circular(2)),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: 0.0,
                          child: Container(
                            decoration: BoxDecoration(
                                color: AppColors.accentGreen,
                                borderRadius: BorderRadius.circular(2)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('0/$lessonsCount', style: AppTextStyles.bodySmall),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                  color: AppColors.bgLight, shape: BoxShape.circle),
              child: const Icon(Icons.chevron_right_rounded,
                  color: AppColors.textMuted, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}
