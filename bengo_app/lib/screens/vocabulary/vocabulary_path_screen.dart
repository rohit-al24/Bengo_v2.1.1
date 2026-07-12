import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../../widgets/bengo_app_bar.dart';
import '../../widgets/bottom_nav.dart';
import '../../services/api_service.dart';
import 'topic_wise_study_screen.dart';
import 'vocabulary_learning_screen.dart';
import 'vocabulary_test_screen.dart';

class VocabularyPathScreen extends StatefulWidget {
  final String level;
  final String category;
  final int? examId;
  final int? catId;
  final List<dynamic>? apiLessons; // real lessons from API

  const VocabularyPathScreen({
    super.key,
    this.level = 'N5',
    this.category = 'Vocabulary',
    this.examId,
    this.catId,
    this.apiLessons,
  });

  @override
  State<VocabularyPathScreen> createState() => _VocabularyPathScreenState();
}

class _VocabularyPathScreenState extends State<VocabularyPathScreen> {
  List<dynamic> _currentLessons = [];

  @override
  void initState() {
    super.initState();
    _currentLessons = widget.apiLessons ?? [];
  }

  Future<void> _refreshLessons() async {
    if (widget.examId == null || widget.catId == null) return;
    try {
      final exam = await ApiService.instance.getExam(widget.examId!);
      final cats = exam['categories'] as List? ?? [];
      final myCat = cats.firstWhere(
        (c) => c['id'] == widget.catId,
        orElse: () => null,
      );
      if (myCat != null && mounted) {
        setState(() {
          _currentLessons = (myCat['lessons'] ?? []).where((lesson) {
            final visible = lesson['is_visible_for_user'];
            return visible == null || visible == true;
          }).toList();
        });
      }
    } catch (e) {
      debugPrint('Error refreshing lessons: $e');
    }
  }

  static final _staticLessons = List.generate(10, (i) {
    return {
      'id': null,
      'number': i + 1,
      'title': 'Lesson ${i + 1}',
      'subtitle': _lessonSubtitles[i],
      'isCompleted': i < 1,
      'isActive': i == 1,
      'isLocked': i > 1,
      'lesson_type': 'study',
    };
  });

  static const _lessonSubtitles = [
    'Greetings & Basics',
    'Numbers & Counting',
    'Colors & Shapes',
    'Daily Routines',
    'Food & Drinks',
    'Family Members',
    'Time & Dates',
    'Places & Directions',
    'Shopping & Money',
    'Weather & Seasons',
  ];

  /// Returns the effective lesson list — API data if available, else static.
  List<Map<String, dynamic>> get _lessons {
    if (_currentLessons.isNotEmpty) {
      final visibleLessons = _currentLessons.where((lesson) {
        final visible = lesson['is_visible_for_user'];
        return visible == null || visible == true;
      }).toList();
      return visibleLessons.asMap().entries.map((e) {
        final l = e.value as Map<String, dynamic>;
        return {
          'id': l['id'],
          'number': e.key + 1,
          'title': l['name'] ?? 'Lesson ${e.key + 1}',
          'subtitle':
              l['lesson_type'] == 'exam' ? 'Exam Only' : 'Study & Practice',
          'isCompleted': l['is_completed'] == true,
          'isActive': l['is_unlocked'] == true && l['is_completed'] != true,
          'isLocked': l['is_unlocked'] != true,
          'lesson_type': l['lesson_type'] ?? 'study',
          'test_source': l['test_source'] ?? 'from_study',
          'category_show_type': l['category_show_type'] ?? 'full_row',
          'has_active_bank': l['has_active_bank'] ?? false,
          'rank_id': l['rank_id'],
          'question_timer_seconds': l['question_timer_seconds'],
          'has_overall_timer': l['has_overall_timer'] ?? false,
          'overall_timer_seconds': l['overall_timer_seconds'],
          'pass_percentage': l['pass_percentage'],
        };
      }).toList();
    }
    return _staticLessons;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F9FF),
      bottomNavigationBar: BenGoBottomNav(
        currentIndex: 1,
        onTap: (i) {
          if (i != 1) Navigator.of(context).popUntil((r) => r.isFirst);
        },
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(context),
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 40),
                  child: _buildZigzagPath(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return const BenGoAppBar(showBack: true);
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      child: Column(
        children: [
          // Level badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Text(
              widget.level,
              style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '${widget.level} ${widget.category} Path',
            style: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF171C21)),
          ),
          const SizedBox(height: 12),
          // Stats row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _statPill('PROGRESS', '1/10'),
              Container(
                width: 1,
                height: 28,
                margin: const EdgeInsets.symmetric(horizontal: 20),
                color: const Color(0xFFDEE3EA),
              ),
              _statPill('MASTERY', '80%'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statPill(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF5C3F3F),
              letterSpacing: 1),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.primary),
        ),
      ],
    );
  }

  Widget _buildZigzagPath(BuildContext context) {
    // Each node alternates: even index → left-center, odd → right-center
    // We use a fixed-width canvas-style layout
    const double nodeSize = 64.0;
    const double leftX = 60.0;
    const double rightX = 220.0;
    const double nodeSpacing = 120.0;
    const double totalWidth = 300.0;

    return SizedBox(
      width: double.infinity,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Draw connecting curves in the background
          CustomPaint(
            size: Size(totalWidth, nodeSpacing * _lessons.length + 40),
            painter: _PathPainter(
              leftX: leftX + nodeSize / 2,
              rightX: rightX + nodeSize / 2,
              nodeSize: nodeSize,
              nodeSpacing: nodeSpacing,
              count: _lessons.length,
            ),
          ),
          // Lesson nodes on top
          SizedBox(
            height: nodeSpacing * _lessons.length + 40,
            child: Stack(
              children: List.generate(_lessons.length, (i) {
                final lesson = _lessons[i];
                final isLeft = i % 2 == 0;
                final xPos = isLeft ? leftX : rightX;
                final yPos = i * nodeSpacing + 20.0;

                final isCompleted = lesson['isCompleted'] as bool;
                final isActive = lesson['isActive'] as bool;
                final isLocked = lesson['isLocked'] as bool;

                return Positioned(
                  left: xPos,
                  top: yPos,
                  child: _LessonNode(
                    lesson: lesson,
                    nodeSize: nodeSize,
                    isCompleted: isCompleted,
                    isActive: isActive,
                    isLocked: isLocked,
                    isLeft: isLeft,
                    onTap: isLocked
                        ? null
                        : () => _showLessonSheet(context, lesson),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  void _showLessonSheet(BuildContext context, Map<String, dynamic> lesson) {
    final lessonId = lesson['id'] as int?;
    final lessonType = lesson['lesson_type']?.toString() ?? 'study';
    final showType = lesson['category_show_type']?.toString() ?? 'full_row';
    final hasBank = lesson['has_active_bank'] as bool? ?? false;
    final testSrc = lesson['test_source']?.toString() ?? 'from_study';

    // exam lesson → go directly to test
    if (lessonType == 'exam') {
      Navigator.of(context)
          .push(MaterialPageRoute(
            builder: (_) => VocabularyTestScreen(
              lessonId: lessonId,
              category: widget.category,
              level: widget.level,
              lessonNumber: lesson['number'] as int,
              rankId: lesson['rank_id'] as int?,
              questionTimerSeconds:
                  lesson['question_timer_seconds'] as int? ?? 30,
              hasOverallTimer: lesson['has_overall_timer'] as bool? ?? false,
              overallTimerSeconds: lesson['overall_timer_seconds'] as int?,
              passPct: lesson['pass_percentage'] as int? ?? 70,
            ),
          ))
          .then((_) => _refreshLessons());
      return;
    }

    // study lesson — show sheet
    final canTest = hasBank || testSrc == 'from_study';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _LessonBottomSheet(
        lesson: lesson,
        canTest: canTest,
        onStudy: () async {
          Navigator.pop(ctx);
          // Topic-wise → TopicWiseStudyScreen
          if (showType == 'topic_wise' && lessonId != null) {
            await Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => TopicWiseStudyScreen(
                lessonId: lessonId,
                rankId: lesson['rank_id'] as int?,
                category: widget.category,
                level: widget.level,
                lessonName: lesson['title']?.toString() ?? '',
              ),
            ));
          } else {
            // Full row → VocabularyLearningScreen
            await Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => VocabularyLearningScreen(
                lessonNumber: lesson['number'] as int,
                category: widget.category,
                level: widget.level,
                lessonId: lessonId,
                rankId: lesson['rank_id'] as int?,
              ),
            ));
          }
          _refreshLessons();
        },
        onTest: canTest
            ? () async {
                Navigator.pop(ctx);
                await Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => VocabularyTestScreen(
                    lessonId: lessonId,
                    category: widget.category,
                    level: widget.level,
                    lessonNumber: lesson['number'] as int,
                    rankId: lesson['rank_id'] as int?,
                    questionTimerSeconds:
                        lesson['question_timer_seconds'] as int? ?? 30,
                    hasOverallTimer:
                        lesson['has_overall_timer'] as bool? ?? false,
                    overallTimerSeconds:
                        lesson['overall_timer_seconds'] as int?,
                    passPct: lesson['pass_percentage'] as int? ?? 70,
                  ),
                ));
                _refreshLessons();
              }
            : null,
      ),
    );
  }
}

// ─── Custom Painter for the winding path ──────────────────────────────────────

class _PathPainter extends CustomPainter {
  final double leftX;
  final double rightX;
  final double nodeSize;
  final double nodeSpacing;
  final int count;

  _PathPainter({
    required this.leftX,
    required this.rightX,
    required this.nodeSize,
    required this.nodeSpacing,
    required this.count,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final completedPaint = Paint()
      ..color = AppColors.primary.withOpacity(0.35)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final lockedPaint = Paint()
      ..color = const Color(0xFFDEE3EA)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    for (int i = 0; i < count - 1; i++) {
      final isLeft = i % 2 == 0;
      final startX = isLeft ? leftX : rightX;
      final endX = isLeft ? rightX : leftX;

      final startY = i * nodeSpacing + 20 + nodeSize / 2;
      final endY = (i + 1) * nodeSpacing + 20 + nodeSize / 2;

      final path = Path();
      path.moveTo(startX, startY);

      // Cubic bezier curve for smooth S-shape
      final cp1x = startX + (endX - startX) * 0.2;
      final cp1y = startY + (endY - startY) * 0.5;
      final cp2x = endX - (endX - startX) * 0.2;
      final cp2y = endY - (endY - startY) * 0.4;

      path.cubicTo(cp1x, cp1y, cp2x, cp2y, endX, endY);

      // Paint completed path segment differently
      final paint = (i < 1) ? completedPaint : lockedPaint;
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_PathPainter old) => false;
}

// ─── Lesson Node Widget ───────────────────────────────────────────────────────

class _LessonNode extends StatelessWidget {
  final Map<String, dynamic> lesson;
  final double nodeSize;
  final bool isCompleted;
  final bool isActive;
  final bool isLocked;
  final bool isLeft;
  final VoidCallback? onTap;

  const _LessonNode({
    required this.lesson,
    required this.nodeSize,
    required this.isCompleted,
    required this.isActive,
    required this.isLocked,
    required this.isLeft,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color borderColor;
    Color iconColor;
    IconData icon;
    List<BoxShadow> shadows = [];

    if (isCompleted) {
      bgColor = AppColors.primary;
      borderColor = AppColors.primary;
      iconColor = Colors.white;
      icon = Icons.check_rounded;
    } else if (isActive) {
      bgColor = Colors.white;
      borderColor = AppColors.primary;
      iconColor = AppColors.primary;
      icon = Icons.menu_book_rounded;
      shadows = [
        BoxShadow(
            color: AppColors.primary.withOpacity(0.25),
            blurRadius: 20,
            spreadRadius: 3),
        BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10),
      ];
    } else {
      bgColor = const Color(0xFFEFF4FB);
      borderColor = const Color(0xFFDEE3EA);
      iconColor = const Color(0xFFDEE3EA);
      icon = Icons.lock_outline_rounded;
    }

    final label = lesson['title'] as String;
    final subtitle = lesson['subtitle'] as String;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment:
            isLeft ? CrossAxisAlignment.start : CrossAxisAlignment.end,
        children: [
          // Node circle
          Container(
            width: nodeSize,
            height: nodeSize,
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
              border: Border.all(color: borderColor, width: isActive ? 2.5 : 2),
              boxShadow: shadows,
            ),
            child: Icon(icon, color: iconColor, size: isActive ? 28 : 22),
          ),
          const SizedBox(height: 6),
          // Label
          SizedBox(
            width: 90,
            child: Column(
              crossAxisAlignment:
                  isLeft ? CrossAxisAlignment.start : CrossAxisAlignment.end,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    color: isLocked
                        ? const Color(0xFFDEE3EA)
                        : const Color(0xFF171C21),
                  ),
                ),
                if (!isLocked)
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      color: isActive
                          ? AppColors.primary
                          : const Color(0xFF5C3F3F),
                    ),
                    maxLines: 2,
                    textAlign: isLeft ? TextAlign.left : TextAlign.right,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Lesson Bottom Sheet ──────────────────────────────────────────────────────

class _LessonBottomSheet extends StatelessWidget {
  final Map<String, dynamic> lesson;
  final VoidCallback onStudy;
  final VoidCallback? onTest;
  final bool canTest;

  const _LessonBottomSheet({
    required this.lesson,
    required this.onStudy,
    this.onTest,
    this.canTest = true,
  });

  @override
  Widget build(BuildContext context) {
    final lessonNum = lesson['number'] as int;
    final title = lesson['title'] as String;
    final subtitle = lesson['subtitle'] as String;
    final showType = lesson['category_show_type']?.toString() ?? 'full_row';

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: const Color(0xFFDEE3EA),
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),

          // Lesson badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.primary.withOpacity(0.2)),
            ),
            child: Text('LESSON $lessonNum',
                style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                    letterSpacing: 1)),
          ),
          const SizedBox(height: 12),

          Text(title,
              style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF171C21))),
          const SizedBox(height: 4),
          Text(subtitle,
              style: GoogleFonts.inter(
                  fontSize: 13, color: const Color(0xFF5C3F3F))),

          // Show type badge
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: showType == 'topic_wise'
                  ? const Color(0xFFEEF2FF)
                  : const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
                showType == 'topic_wise'
                    ? '📚 Topic-Wise Mode'
                    : '📋 Full List Mode',
                style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: showType == 'topic_wise'
                        ? const Color(0xFF6366F1)
                        : const Color(0xFF16A34A))),
          ),
          const SizedBox(height: 20),

          // Study button
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              onPressed: onStudy,
              icon: const Icon(Icons.menu_book_rounded, size: 20),
              label: Text('Study',
                  style: GoogleFonts.inter(
                      fontSize: 16, fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Take Test button (only if canTest)
          if (canTest)
            SizedBox(
              width: double.infinity,
              height: 54,
              child: OutlinedButton.icon(
                onPressed: onTest,
                icon: const Icon(Icons.quiz_rounded, size: 20),
                label: Text('Take Test',
                    style: GoogleFonts.inter(
                        fontSize: 16, fontWeight: FontWeight.w700)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary, width: 1.5),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text('✅ Study-only lesson — no test required',
                  style: GoogleFonts.inter(
                      fontSize: 12, color: const Color(0xFF6B7280)),
                  textAlign: TextAlign.center),
            ),
        ],
      ),
    );
  }

  Widget _statBox(IconData icon, String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F9FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDEE3EA)),
      ),
      child: Column(children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(height: 4),
        Text(value,
            style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF171C21))),
        Text(label,
            style: GoogleFonts.inter(
                fontSize: 10, color: const Color(0xFF5C3F3F))),
      ]),
    );
  }
}
