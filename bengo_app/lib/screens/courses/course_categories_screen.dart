import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/app_colors.dart';
import '../../widgets/bengo_app_bar.dart';
import '../../services/api_service.dart';
import '../../widgets/bottom_nav.dart';
import '../vocabulary/vocabulary_path_screen.dart';

// ── Design tokens ─────────────────────────────────────────────────────────────
const _kBg = Color(0xFFFAF8F5);
const _kSurface = Color(0xFFFFFFFF);
const _kAccent = Color(0xFFC41230);
const _kInk = Color(0xFF1B1B1D);
const _kMuted = Color(0xFF8A8A8F);
const _kBorderLight = Color(0xFFEAE5E1);
const _kFieldTint = Color(0xFFFDF3F5);
const _kFieldBorder = Color(0xFFEDD5D8);

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
      'bg': const Color(0xFFE8F5E9),
      'iconColor': const Color(0xFF2E7D32)
    },
    'Grammar': {
      'icon': Icons.edit_note_rounded,
      'bg': const Color(0xFFE3F2FD),
      'iconColor': const Color(0xFF1565C0)
    },
    'Kanji': {
      'icon': Icons.brush_rounded,
      'bg': const Color(0xFFFFF3E0),
      'iconColor': const Color(0xFFE65100)
    },
    'Listening': {
      'icon': Icons.hearing_rounded,
      'bg': const Color(0xFFF3E5F5),
      'iconColor': const Color(0xFF6A1B9A)
    },
    'Speaking': {
      'icon': Icons.record_voice_over_rounded,
      'bg': const Color(0xFFFFEBEE),
      'iconColor': const Color(0xFFB71C1C)
    },
  };
  static const _defaultMeta = {
    'icon': Icons.menu_book_rounded,
    'bg': Color(0xFFECEFF1),
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
      backgroundColor: _kBg,
      bottomNavigationBar: BenGoBottomNav(
        currentIndex: 1,
        onTap: (i) {
          if (i != 1) Navigator.of(context).popUntil((r) => r.isFirst);
        },
      ),
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // App bar
            SliverToBoxAdapter(child: _buildAppBar(context)),

            // Page heading
            SliverToBoxAdapter(child: _buildHeader()),

            // Overall progress card
            SliverToBoxAdapter(child: _buildProgressCard()),

            // Section label
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Text(
                  'STUDY CATEGORIES',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: _kMuted,
                    letterSpacing: 1.6,
                  ),
                ),
              ),
            ),

            if (_loading)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 48),
                  child: Center(
                    child: CircularProgressIndicator(
                        color: _kAccent, strokeWidth: 2.5),
                  ),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) => Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                    child: _buildCategoryCard(context, _categories[i]),
                  ),
                  childCount: _categories.length,
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }

  // ── App bar ─────────────────────────────────────────────────────────────────
  Widget _buildAppBar(BuildContext context) {
    return BenGoAppBar(
      showBack: true,
      actions: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: _kAccent,
            borderRadius: BorderRadius.circular(100),
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

  // ── Page heading ────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    final title =
        _examTitle.isNotEmpty ? _examTitle : 'JLPT ${widget.level} Proficiency';
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: _kInk,
              letterSpacing: -0.5,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Choose a category to begin your learning path.',
            style: GoogleFonts.inter(fontSize: 13, color: _kMuted, height: 1.5),
          ),
          const SizedBox(height: 14),
          _buildRankBadge(_currentRank),
        ],
      ),
    );
  }

  // ── Rank badge pill ─────────────────────────────────────────────────────────
  Widget _buildRankBadge(Map<String, dynamic>? rankProgress) {
    final rankName = (rankProgress?['rank_name'] ?? '').toString();
    final icon = (rankProgress?['rank_icon'] ?? '').toString().trim();
    final displayIcon = icon.isNotEmpty ? icon : '🏆';
    final label =
        rankName.isNotEmpty ? 'Current rank: $rankName' : 'Rank: Start learning';

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

  // ── Overall progress card (red gradient) ────────────────────────────────────
  Widget _buildProgressCard() {
    final total = _categories.fold<int>(0, (sum, c) {
      final count = c['lessons_count'] ?? (c['lessons'] as List?)?.length ?? 0;
      return sum + (count as int);
    });
    final completed = _categories.fold<int>(0, (sum, c) {
      final lessons = c['lessons'] as List?;
      if (lessons == null) return sum;
      return sum +
          lessons.where((lesson) => lesson['is_completed'] == true).length;
    });
    final progress =
        total > 0 ? (completed / total).clamp(0.0, 1.0) : 0.0;
    final rankName =
        (_currentRank?['rank_name'] ?? 'Current rank').toString();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFC41230), Color(0xFF8B0D21)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Color(0x40C41230),
              blurRadius: 0,
              offset: Offset(0, 4),
            ),
            BoxShadow(
              color: Color(0x20C41230),
              blurRadius: 14,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'OVERALL PROGRESS',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.white60,
                      letterSpacing: 1.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    rankName,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(100),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 7,
                      backgroundColor: Colors.white.withOpacity(0.25),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          Colors.white),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${(progress * 100).toStringAsFixed(0)}%  ·  $completed / $total lessons',
                    style: GoogleFonts.inter(
                        fontSize: 11,
                        color: Colors.white70,
                        fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Icon(Icons.emoji_events_rounded,
                    color: Colors.amber, size: 34),
                const SizedBox(height: 6),
                Text(
                  '$total',
                  style: GoogleFonts.spaceGrotesk(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white),
                ),
                Text(
                  'lessons',
                  style: GoogleFonts.inter(fontSize: 10, color: Colors.white60),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Category card ───────────────────────────────────────────────────────────
  Widget _buildCategoryCard(BuildContext context, dynamic cat) {
    final title = (cat['title'] ?? cat['label'] ?? 'Category') as String;
    final desc = (cat['description'] ?? 'Study materials') as String;
    final lessonsCount =
        cat['lessons_count'] ?? (cat['lessons'] as List?)?.length ?? 0;
    final catId = cat['id'] as int?;
    final lessons = cat['lessons'] as List? ?? [];
    final meta = _iconMap[title] ?? _defaultMeta;

    // Completion from lessons list
    final completedCount = lessons
        .where((l) => l['is_completed'] == true)
        .length;
    final total = lessons.isNotEmpty ? lessons.length : (lessonsCount as int);
    final progress = total > 0 ? completedCount / total : 0.0;

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
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: _kSurface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _kBorderLight),
          boxShadow: const [
            BoxShadow(
                color: Color(0x07000000), blurRadius: 10, offset: Offset(0, 3))
          ],
        ),
        child: Row(
          children: [
            // Icon squircle
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: meta['bg'] as Color,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                meta['icon'] as IconData,
                color: meta['iconColor'] as Color,
                size: 28,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: _kInk,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    desc,
                    style: GoogleFonts.inter(fontSize: 12, color: _kMuted),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(100),
                          child: LinearProgressIndicator(
                            value: progress.toDouble(),
                            minHeight: 5,
                            backgroundColor: _kBorderLight,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                                _kAccent),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$completedCount/$total',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _kMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            // Arrow
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: _kFieldTint,
                shape: BoxShape.circle,
                border: Border.all(color: _kFieldBorder),
              ),
              child: const Icon(Icons.chevron_right_rounded,
                  color: _kAccent, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}
