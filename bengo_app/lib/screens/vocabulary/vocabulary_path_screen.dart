import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/app_colors.dart';
import '../../widgets/bengo_app_bar.dart';
import '../../widgets/bottom_nav.dart';
import '../../services/api_service.dart';
import 'topic_wise_study_screen.dart';
import 'vocabulary_learning_screen.dart';
import 'vocabulary_test_screen.dart';

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

class VocabularyPathScreen extends StatefulWidget {
  final String level;
  final String category;
  final int? examId;
  final int? catId;
  final List<dynamic>? apiLessons;

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
      backgroundColor: _kBg,
      bottomNavigationBar: BenGoBottomNav(
        currentIndex: 1,
        onTap: (i) {
          if (i != 1) Navigator.of(context).popUntil((r) => r.isFirst);
        },
      ),
      body: SafeArea(
        child: Column(
          children: [
            const BenGoAppBar(showBack: true),
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

  // ── Path header ─────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    final lessons = _lessons;
    final totalLessons = lessons.length;
    final completedLessons =
        lessons.where((l) => l['isCompleted'] == true).length;
    final progressLabel = '$completedLessons/$totalLessons';
    final mastery = totalLessons > 0
        ? ((completedLessons / totalLessons) * 100).toStringAsFixed(0)
        : '0';

    return Container(
      color: _kBg,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Column(
        children: [
          // Level + category badge
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 7),
            decoration: BoxDecoration(
              color: _kAccent,
              borderRadius: BorderRadius.circular(100),
              boxShadow: const [
                BoxShadow(
                    color: _kAccentShadow,
                    blurRadius: 0,
                    offset: Offset(0, 3)),
              ],
            ),
            child: Text(
              '${widget.level}  ·  ${widget.category}',
              style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 0.3),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '${widget.level} ${widget.category} Path',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: _kInk,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 14),
          // Stats row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: _kSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _kBorderLight),
              boxShadow: const [
                BoxShadow(
                    color: Color(0x07000000),
                    blurRadius: 8,
                    offset: Offset(0, 3))
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _StatPill(label: 'PROGRESS', value: progressLabel),
                Container(
                  width: 1,
                  height: 30,
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  color: _kBorderLight,
                ),
                _StatPill(label: 'MASTERY', value: '$mastery%'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Zigzag path (logic identical, styling improved) ─────────────────────────
  Widget _buildZigzagPath(BuildContext context) {
    const double nodeSize = 68.0;
    const double leftX = 52.0;
    const double rightX = 214.0;
    const double nodeSpacing = 128.0;

    return SizedBox(
      width: double.infinity,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          CustomPaint(
            size: Size(300, nodeSpacing * _lessons.length + 40),
            painter: _PathPainter(
              leftX: leftX + nodeSize / 2,
              rightX: rightX + nodeSize / 2,
              nodeSize: nodeSize,
              nodeSpacing: nodeSpacing,
              lessonCompletion: _lessons
                  .map<bool>((l) => l['isCompleted'] == true)
                  .toList(),
            ),
          ),
          SizedBox(
            height: nodeSpacing * _lessons.length + 40,
            child: Stack(
              children: List.generate(_lessons.length, (i) {
                final lesson = _lessons[i];
                final isLeft = i % 2 == 0;
                final xPos = isLeft ? leftX : rightX;
                final yPos = i * nodeSpacing + 20.0;

                return Positioned(
                  left: xPos,
                  top: yPos,
                  child: _LessonNode(
                    lesson: lesson,
                    nodeSize: nodeSize,
                    isCompleted: lesson['isCompleted'] as bool,
                    isActive: lesson['isActive'] as bool,
                    isLocked: lesson['isLocked'] as bool,
                    isLeft: isLeft,
                    onTap: (lesson['isLocked'] as bool)
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

// ═══════════════════════════════════════════════════════════════════════════════
// PATH PAINTER (logic identical, stroke upgraded)
// ═══════════════════════════════════════════════════════════════════════════════

class _PathPainter extends CustomPainter {
  final double leftX;
  final double rightX;
  final double nodeSize;
  final double nodeSpacing;
  final List<bool> lessonCompletion;

  _PathPainter({
    required this.leftX,
    required this.rightX,
    required this.nodeSize,
    required this.nodeSpacing,
    required this.lessonCompletion,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final completedPaint = Paint()
      ..color = _kAccent.withOpacity(0.4)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final lockedPaint = Paint()
      ..color = const Color(0xFFE0DBD7)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    for (int i = 0; i < lessonCompletion.length - 1; i++) {
      final isLeft = i % 2 == 0;
      final startX = isLeft ? leftX : rightX;
      final endX = isLeft ? rightX : leftX;
      final startY = i * nodeSpacing + 20 + nodeSize / 2;
      final endY = (i + 1) * nodeSpacing + 20 + nodeSize / 2;

      final path = Path();
      path.moveTo(startX, startY);
      final cp1x = startX + (endX - startX) * 0.2;
      final cp1y = startY + (endY - startY) * 0.5;
      final cp2x = endX - (endX - startX) * 0.2;
      final cp2y = endY - (endY - startY) * 0.4;
      path.cubicTo(cp1x, cp1y, cp2x, cp2y, endX, endY);

      canvas.drawPath(path, lessonCompletion[i] ? completedPaint : lockedPaint);
    }
  }

  @override
  bool shouldRepaint(_PathPainter old) => false;
}

// ═══════════════════════════════════════════════════════════════════════════════
// LESSON NODE (enhanced styling)
// ═══════════════════════════════════════════════════════════════════════════════

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
    // State-based styling
    final Color bgColor;
    final Color borderColor;
    final Color iconColor;
    final IconData icon;
    final List<BoxShadow> shadows;

    if (isCompleted) {
      bgColor = _kAccent;
      borderColor = _kAccent;
      iconColor = Colors.white;
      icon = Icons.check_rounded;
      shadows = const [
        BoxShadow(color: Color(0x30C41230), blurRadius: 10, offset: Offset(0, 4)),
      ];
    } else if (isActive) {
      bgColor = _kSurface;
      borderColor = _kAccent;
      iconColor = _kAccent;
      icon = Icons.menu_book_rounded;
      shadows = const [
        BoxShadow(color: Color(0x40C41230), blurRadius: 20, spreadRadius: 2),
        BoxShadow(color: Color(0x10000000), blurRadius: 10),
      ];
    } else {
      bgColor = const Color(0xFFF0EDE9);
      borderColor = _kBorderLight;
      iconColor = const Color(0xFFCCC7C2);
      icon = Icons.lock_outline_rounded;
      shadows = const [];
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
          // Node
          Container(
            width: nodeSize,
            height: nodeSize,
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
              border: Border.all(
                  color: borderColor, width: isActive ? 2.5 : 2),
              boxShadow: shadows,
            ),
            child: Icon(icon, color: iconColor, size: isActive ? 30 : 24),
          ),
          const SizedBox(height: 7),
          // Label
          SizedBox(
            width: 94,
            child: Column(
              crossAxisAlignment:
                  isLeft ? CrossAxisAlignment.start : CrossAxisAlignment.end,
              children: [
                Text(
                  label,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 12,
                    fontWeight:
                        isActive ? FontWeight.w700 : FontWeight.w600,
                    color: isLocked ? _kBorderLight : _kInk,
                  ),
                ),
                if (!isLocked)
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: isActive ? _kAccent : _kMuted,
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

// ═══════════════════════════════════════════════════════════════════════════════
// LESSON BOTTOM SHEET (enhanced)
// ═══════════════════════════════════════════════════════════════════════════════

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
    final isTopicWise = showType == 'topic_wise';

    return Container(
      decoration: const BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
                color: _kBorderLight,
                borderRadius: BorderRadius.circular(100)),
          ),
          const SizedBox(height: 22),

          // Lesson number badge
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: _kFieldTint,
              borderRadius: BorderRadius.circular(100),
              border: Border.all(color: _kFieldBorder),
            ),
            child: Text(
              'LESSON $lessonNum',
              style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: _kAccent,
                  letterSpacing: 1),
            ),
          ),
          const SizedBox(height: 12),

          Text(
            title,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: _kInk,
              letterSpacing: -0.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: GoogleFonts.inter(fontSize: 13, color: _kMuted),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),

          // Mode badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: isTopicWise
                  ? const Color(0xFFEEF2FF)
                  : const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Text(
              isTopicWise ? '📚  Topic-Wise Mode' : '📋  Full List Mode',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isTopicWise
                    ? const Color(0xFF6366F1)
                    : const Color(0xFF16A34A),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Study button
          _SheetButton(
            label: 'Study',
            icon: Icons.menu_book_rounded,
            onPressed: onStudy,
            filled: true,
          ),
          const SizedBox(height: 12),

          // Test button
          if (canTest)
            _SheetButton(
              label: 'Take Test',
              icon: Icons.quiz_rounded,
              onPressed: onTest ?? () {},
              filled: false,
            )
          else
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '✅  Study-only lesson — no test required',
                style: GoogleFonts.inter(
                    fontSize: 12, color: _kMuted),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }
}

class _SheetButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool filled;

  const _SheetButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    required this.filled,
  });

  @override
  State<_SheetButton> createState() => _SheetButtonState();
}

class _SheetButtonState extends State<_SheetButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onPressed();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: double.infinity,
          height: 54,
          decoration: BoxDecoration(
            color: widget.filled ? _kAccent : _kSurface,
            borderRadius: BorderRadius.circular(100),
            border: Border.all(
              color: widget.filled ? _kAccent : _kFieldBorder,
              width: widget.filled ? 0 : 1.5,
            ),
            boxShadow: widget.filled
                ? const [
                    BoxShadow(
                        color: _kAccentShadow,
                        blurRadius: 0,
                        offset: Offset(0, 4)),
                    BoxShadow(
                        color: Color(0x18C41230),
                        blurRadius: 12,
                        offset: Offset(0, 8)),
                  ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                widget.icon,
                size: 18,
                color: widget.filled ? Colors.white : _kAccent,
              ),
              const SizedBox(width: 8),
              Text(
                widget.label,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: widget.filled ? Colors.white : _kAccent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Stat pill (header) ────────────────────────────────────────────────────────
class _StatPill extends StatelessWidget {
  final String label;
  final String value;
  const _StatPill({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: _kMuted,
            letterSpacing: 1.4,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: _kAccent,
          ),
        ),
      ],
    );
  }
}
