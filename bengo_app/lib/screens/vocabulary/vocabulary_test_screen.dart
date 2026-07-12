import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/app_colors.dart';
import '../../services/api_service.dart';
import '../../widgets/bengo_header.dart';
import '../../widgets/bottom_nav.dart';

// ── Question result type ─────────────────────────────────────────────────────
enum QuestionResult { correct, wrong, timeout, skipped }

class _QuestionStat {
  final String target;
  final String correctAnswer;
  final String? chosen;
  final QuestionResult result;
  const _QuestionStat({
    required this.target, required this.correctAnswer,
    this.chosen, required this.result,
  });
}

// ────────────────────────────────────────────────────────────────────────────
class VocabularyTestScreen extends StatefulWidget {
  final int? lessonId;
  final int? rankId;
  final int? questionTimerSeconds;   // per-question (0 = no limit)
  final bool hasOverallTimer;
  final int? overallTimerSeconds;
  final int? passPct;
  final String category;
  final String level;
  final int lessonNumber;
  final String rankName;

  const VocabularyTestScreen({
    super.key,
    this.lessonId,
    this.rankId,
    this.questionTimerSeconds = 30,
    this.hasOverallTimer = false,
    this.overallTimerSeconds,
    this.passPct = 70,
    this.category = 'Vocabulary',
    this.level = 'N5',
    this.lessonNumber = 1,
    this.rankName = '',
  });

  @override
  State<VocabularyTestScreen> createState() => _VocabularyTestScreenState();
}

class _VocabularyTestScreenState extends State<VocabularyTestScreen>
    with TickerProviderStateMixin {

  // ── Data ─────────────────────────────────────────────────────────────────────
  List<Map<String, dynamic>> _questions = [];
  bool _loading = true;

  // ── Quiz state ────────────────────────────────────────────────────────────────
  int _currentQ         = 0;
  int? _selectedAnswer;
  bool _answerLocked    = false;
  bool _finished        = false;
  bool _endedByTimer    = false;
  final List<_QuestionStat> _stats = [];

  // ── Timers ────────────────────────────────────────────────────────────────────
  // Per-question countdown
  int _qSecondsLeft = 0;
  Timer? _qTimer;
  // Overall countdown
  int _overallSecondsLeft = 0;
  Timer? _overallTimer;
  // Time tracking
  final Stopwatch _stopwatch = Stopwatch();

  // ── Animation ─────────────────────────────────────────────────────────────────
  late AnimationController _optionAnim;
  late Animation<double> _optionFade;

  @override
  void initState() {
    super.initState();
    _optionAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _optionFade = CurvedAnimation(parent: _optionAnim, curve: Curves.easeOut);
    _loadQuestions();
  }

  @override
  void dispose() {
    _qTimer?.cancel();
    _overallTimer?.cancel();
    _stopwatch.stop();
    _optionAnim.dispose();
    super.dispose();
  }

  // ── Load questions ────────────────────────────────────────────────────────────
  Future<void> _loadQuestions() async {
    if (widget.lessonId == null) { _useFallback(); return; }
    setState(() { _loading = true; });
    try {
      final data = await ApiService.instance.getLessonTest(widget.lessonId!);
      final qs = data['questions'] as List? ?? data['items'] as List? ?? [];
      if (qs.isEmpty) { _useFallback(); return; }
      setState(() {
        _questions = qs.map<Map<String, dynamic>>((q) {
          final target  = q['target']?.toString() ?? q['question']?.toString() ?? '';
          final correct = q['correct_answer']?.toString() ?? '';
          final opts    = <String>[];
          if (q['options'] != null) {
            opts.addAll((q['options'] as List).map((o) => o.toString()));
          } else {
            opts.add(correct);
            for (var k in ['wrong_1', 'wrong_2', 'wrong_3']) {
              final v = q[k]?.toString();
              if (v != null && v.isNotEmpty) opts.add(v);
            }
          }
          if (opts.length > 4) {
            opts.removeWhere((o) => o == correct);
            opts.shuffle();
            opts.insertAll(0, [correct]);
            final onlyFour = [correct, ...opts.where((o) => o != correct).take(3)];
            opts
              ..clear()
              ..addAll(onlyFour);
          }
          opts.shuffle();
          final ci = opts.indexOf(correct);
          return {'target': target, 'options': opts, 'correct': ci < 0 ? 0 : ci};
        }).toList();
      });
    } catch (_) {
      _useFallback();
    } finally {
      setState(() => _loading = false);
      _startQuiz();
    }
  }

  void _useFallback() {
    _questions = [
      {'target': 'こんにちは', 'options': ['Hello','Thank you','Goodbye','Sorry'],    'correct': 0},
      {'target': 'ありがとう', 'options': ['Good morning','Thank you','Please','Excuse me'], 'correct': 1},
      {'target': 'さようなら', 'options': ['Good night','Hello','Goodbye','Thank you'], 'correct': 2},
    ];
    setState(() => _loading = false);
    _startQuiz();
  }

  // ── Start quiz + timers ───────────────────────────────────────────────────────
  void _startQuiz() {
    _stopwatch.start();
    if (widget.hasOverallTimer && (widget.overallTimerSeconds ?? 0) > 0) {
      _overallSecondsLeft = widget.overallTimerSeconds!;
      _overallTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() => _overallSecondsLeft--);
        if (_overallSecondsLeft <= 0) _overallTimerExpired();
      });
    }
    _startQuestionTimer();
    _optionAnim.forward(from: 0);
  }

  void _startQuestionTimer() {
    _qTimer?.cancel();
    final secs = widget.questionTimerSeconds ?? 0;
    if (secs <= 0) return;
    _qSecondsLeft = secs;
    _qTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _qSecondsLeft--);
      if (_qSecondsLeft <= 0) _questionTimedOut();
    });
  }

  void _questionTimedOut() {
    _qTimer?.cancel();
    if (_answerLocked || _finished) return;
    final q = _questions[_currentQ];
    _stats.add(_QuestionStat(
      target: q['target'] as String,
      correctAnswer: (q['options'] as List)[q['correct'] as int].toString(),
      chosen: null,
      result: QuestionResult.timeout,
    ));
    setState(() => _answerLocked = true);
    Future.delayed(const Duration(milliseconds: 700), _advance);
  }

  void _overallTimerExpired() {
    _overallTimer?.cancel();
    _qTimer?.cancel();
    if (_finished) return;
    // Record remaining questions as skipped
    for (int i = _currentQ + (_answerLocked ? 1 : 0); i < _questions.length; i++) {
      final q = _questions[i];
      _stats.add(_QuestionStat(
        target: q['target'] as String,
        correctAnswer: (q['options'] as List)[q['correct'] as int].toString(),
        result: QuestionResult.skipped,
      ));
    }
    setState(() => _endedByTimer = true);
    _finishQuiz();
  }

  // ── Answer selection ──────────────────────────────────────────────────────────
  void _selectAnswer(int i) {
    if (_answerLocked || _finished) return;
    _qTimer?.cancel();
    final isCorrect = i == (_questions[_currentQ]['correct'] as int);
    final q = _questions[_currentQ];
    _stats.add(_QuestionStat(
      target: q['target'] as String,
      correctAnswer: (q['options'] as List)[q['correct'] as int].toString(),
      chosen: (q['options'] as List)[i].toString(),
      result: isCorrect ? QuestionResult.correct : QuestionResult.wrong,
    ));
    setState(() { _selectedAnswer = i; _answerLocked = true; });
    Future.delayed(const Duration(milliseconds: 900), _advance);
  }

  void _advance() {
    if (_currentQ < _questions.length - 1) {
      setState(() { _currentQ++; _selectedAnswer = null; _answerLocked = false; });
      _startQuestionTimer();
      _optionAnim.forward(from: 0);
    } else {
      _finishQuiz();
    }
  }

  // ── Finish quiz ───────────────────────────────────────────────────────────────
  Future<void> _finishQuiz() async {
    _qTimer?.cancel();
    _overallTimer?.cancel();
    _stopwatch.stop();
    setState(() => _finished = true);

    final correct   = _stats.where((s) => s.result == QuestionResult.correct).length;
    final wrong     = _stats.where((s) => s.result == QuestionResult.wrong).length;
    final timedOut  = _stats.where((s) => s.result == QuestionResult.timeout).length;
    final total     = _questions.length;

    // Submit to API
    if (widget.lessonId != null) {
      try {
        await ApiService.instance.submitTestLog(
          lessonId:           widget.lessonId!,
          rankId:             widget.rankId,
          total:              total,
          correct:            correct,
          wrong:              wrong,
          timedOut:           timedOut,
          timeTakenSeconds:   _stopwatch.elapsed.inSeconds,
          endedByTimer:       _endedByTimer,
          questionDetail:     _stats.map((s) => {
            'target':          s.target,
            'correct_answer':  s.correctAnswer,
            'chosen':          s.chosen ?? '',
            'result':          s.result.name,
          }).toList(),
        );
      } catch (_) {}
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────────
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
        child: Padding(
          // leave room for the persistent bottom navigation bar so controls aren't covered
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 84),
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : _finished
                  ? _buildResultScreen(context)
                  : _buildQuizScreen(context),
        ),
      ),
    );
  }

  // ── Quiz Screen ───────────────────────────────────────────────────────────────
  Widget _buildQuizScreen(BuildContext context) {
    final q        = _questions[_currentQ];
    final progress = _currentQ / _questions.length;
    final qSecs    = widget.questionTimerSeconds ?? 0;
    final pctLeft  = qSecs > 0 ? _qSecondsLeft / qSecs : 1.0;
    final timerColor = pctLeft > 0.5
        ? AppColors.accentGreen
        : pctLeft > 0.25
            ? Colors.orange
            : Colors.red.shade500;

    final questionFontSize = MediaQuery.of(context).size.width < 360 ? 26.0 : 32.0;

    return Column(
      children: [
        // ── App bar ──────────────────────────────────────────────────────────
        const BenGoHeader(isSubPage: true),

        // ── Top bar: Progress + Timers ───────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Text('${_currentQ + 1}/${_questions.length}',
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textMuted)),
              const SizedBox(width: 12),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: AppColors.borderLight,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accentGreen),
                    minHeight: 6,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Timer pills
              if (qSecs > 0)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: timerColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(children: [
                    Icon(Icons.timer_outlined, size: 12, color: timerColor),
                    const SizedBox(width: 3),
                    Text('${_qSecondsLeft}s',
                        style: GoogleFonts.inter(fontSize: 11,
                            fontWeight: FontWeight.w600, color: timerColor)),
                  ]),
                ),
              if (widget.hasOverallTimer) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.indigo.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(children: [
                    const Icon(Icons.hourglass_bottom_rounded, size: 12, color: Colors.indigo),
                    const SizedBox(width: 3),
                    Text(_formatTime(_overallSecondsLeft),
                        style: GoogleFonts.inter(fontSize: 11,
                            fontWeight: FontWeight.w600, color: Colors.indigo)),
                  ]),
                ),
              ],
            ],
          ),
        ),

        // ── Main content ──────────────────────────────────────────────────────
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              children: [
                // ── Question text ─────────────────────────────────────────────
                const SizedBox(height: 12),
                Text(q['target'] as String,
                    style: GoogleFonts.notoSerif(fontSize: questionFontSize,
                        fontWeight: FontWeight.w700, color: AppColors.primary),
                    textAlign: TextAlign.center,
                    softWrap: true,
                    overflow: TextOverflow.visible,
                    maxLines: 5),
                const SizedBox(height: 8),
                Text('${widget.category} · ${widget.level}',
                    style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted, letterSpacing: 0.5),
                    textAlign: TextAlign.center),
                const SizedBox(height: 40),

                // ── Answer options ────────────────────────────────────────────
                FadeTransition(
                  opacity: _optionFade,
                  child: Column(
                    children: (q['options'] as List).asMap().entries.map((e) {
                      final i   = e.key;
                      final opt = e.value.toString();
                      final isCorrect  = i == (q['correct'] as int);
                      final isSelected = _selectedAnswer == i;

                      Color bg     = AppColors.bgLight;
                      Color border = Colors.transparent;
                      Color text   = AppColors.textPrimary;

                      if (_answerLocked) {
                        if (isCorrect) {
                          bg = AppColors.accentGreen.withOpacity(0.12);
                          border = AppColors.accentGreen;
                          text   = AppColors.accentGreen;
                        } else if (isSelected) {
                          bg = Colors.red.withOpacity(0.1);
                          border = Colors.red.shade300;
                          text   = Colors.red.shade600;
                        } else {
                          bg = AppColors.bgLight;
                          border = Colors.transparent;
                          text   = AppColors.textMuted;
                        }
                      } else {
                        border = AppColors.borderLight;
                      }

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: GestureDetector(
                          onTap: _answerLocked ? null : () => _selectAnswer(i),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            decoration: BoxDecoration(
                              color: bg,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: border, width: 1.2),
                            ),
                            child: Row(
                              children: [
                                Text(String.fromCharCode(65 + i),
                                    style: GoogleFonts.inter(fontSize: 14,
                                        fontWeight: FontWeight.w700, color: text.withOpacity(0.5))),
                                const SizedBox(width: 14),
                                Expanded(child: Text(opt,
                                    style: GoogleFonts.inter(fontSize: 14,
                                        fontWeight: FontWeight.w500, color: text),
                                    softWrap: true,
                                    overflow: TextOverflow.visible,
                                    maxLines: 3)),
                                if (_answerLocked && isCorrect)
                                  const Icon(Icons.check_circle_rounded,
                                      color: AppColors.accentGreen, size: 20),
                                if (_answerLocked && isSelected && !isCorrect)
                                  Icon(Icons.cancel_rounded, color: Colors.red.shade400, size: 20),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),

        // ── Bottom bar: Exit ───────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.logout_rounded, color: AppColors.primary, size: 16),
                  const SizedBox(width: 6),
                  Text('EXIT', style: GoogleFonts.inter(fontSize: 11,
                      fontWeight: FontWeight.w700, color: AppColors.primary, letterSpacing: 0.5)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Result Screen ─────────────────────────────────────────────────────────────
  Widget _buildResultScreen(BuildContext context) {
    final correct   = _stats.where((s) => s.result == QuestionResult.correct).length;
    final wrong     = _stats.where((s) => s.result == QuestionResult.wrong).length;
    final timedOut  = _stats.where((s) => s.result == QuestionResult.timeout).length;
    final total     = _questions.length;
    final pct       = total > 0 ? (correct / total * 100).round() : 0;
    final passPct   = widget.passPct ?? 70;
    final passed    = pct >= passPct && !_endedByTimer;

    return Column(
      children: [
        // ── App bar ──────────────────────────────────────────────────────────
        const BenGoHeader(isSubPage: true),

        // ── Results ────────────────────────────────────────────────────────────
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              children: [
                // ── Status icon ────────────────────────────────────────────────
                Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _endedByTimer
                        ? Colors.orange.withOpacity(0.1)
                        : passed
                            ? AppColors.accentGreen.withOpacity(0.1)
                            : AppColors.primary.withOpacity(0.08),
                  ),
                  child: Icon(
                    _endedByTimer
                        ? Icons.timer_off_rounded
                        : passed
                            ? Icons.emoji_events_rounded
                            : Icons.refresh_rounded,
                    size: 40,
                    color: _endedByTimer
                        ? Colors.orange
                        : passed ? AppColors.accentGreen : AppColors.primary,
                  ),
                ),
                const SizedBox(height: 16),

                // ── Heading ────────────────────────────────────────────────────
                Text(
                  _endedByTimer
                      ? 'Time\'s Up! ⏰'
                      : passed
                          ? 'Lesson Passed! 🎉'
                          : 'Keep Practicing!',
                  style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // ── Score ──────────────────────────────────────────────────────
                Column(
                  children: [
                    Text('$pct%', style: GoogleFonts.inter(fontSize: 56,
                        fontWeight: FontWeight.w900, color: AppColors.primary)),
                    Text('Score · ${passed ? 'Passed' : 'Need $passPct%'}',
                        style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted)),
                  ],
                ),
                const SizedBox(height: 16),

                // ── Progress bar ───────────────────────────────────────────────
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: total > 0 ? correct / total : 0,
                    backgroundColor: AppColors.borderLight,
                    valueColor: AlwaysStoppedAnimation<Color>(
                        passed ? AppColors.accentGreen : AppColors.primary),
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 24),

                // ── Stats grid ────────────────────────────────────────────────
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 2.2,
                  children: [
                    _statCard('✅ Correct', '$correct', AppColors.accentGreen),
                    _statCard('❌ Wrong', '$wrong', Colors.red.shade400),
                    _statCard('⏱ Timeout', '$timedOut', Colors.orange),
                    _statCard('📝 Total', '$total', AppColors.textSecondary),
                  ],
                ),
                const SizedBox(height: 20),

                // ── Time ───────────────────────────────────────────────────────
                Row(
                  children: [
                    const Icon(Icons.hourglass_top_rounded, size: 14, color: Colors.indigo),
                    const SizedBox(width: 8),
                    Text('Time Taken', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted)),
                    const Spacer(),
                    Text(_formatTime(_stopwatch.elapsed.inSeconds),
                        style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.indigo)),
                  ],
                ),
                const SizedBox(height: 24),

                // ── Question log ───────────────────────────────────────────────
                if (_stats.isNotEmpty) ...[
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text('QUESTION LOG',
                        style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700,
                            color: AppColors.textMuted, letterSpacing: 0.5)),
                  ),
                  const SizedBox(height: 12),
                  ..._stats.map((s) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _logRow(s),
                  )),
                  const SizedBox(height: 12),
                ],
              ],
            ),
          ),
        ),

        // ── Action buttons ─────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              SizedBox(
                width: double.infinity, height: 48,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: Text(passed ? 'CONTINUE' : 'BACK TO LESSONS',
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700,
                          letterSpacing: 0.8, color: Colors.white)),
                ),
              ),
              if (!passed && !_endedByTimer) ...[
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _currentQ = 0; _selectedAnswer = null; _answerLocked = false;
                      _finished = false; _endedByTimer = false; _stats.clear();
                    });
                    _loadQuestions();
                  },
                  child: Text('Retry Quiz',
                      style: GoogleFonts.inter(fontSize: 12,
                          color: AppColors.primary, fontWeight: FontWeight.w600)),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _statCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(value, style: GoogleFonts.inter(fontSize: 20,
              fontWeight: FontWeight.w800, color: color)),
          const SizedBox(height: 2),
          Text(label, style: GoogleFonts.inter(fontSize: 9,
              color: color.withOpacity(0.7), fontWeight: FontWeight.w600),
              textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _logRow(_QuestionStat s) {
    IconData icon;
    Color    color;
    switch (s.result) {
      case QuestionResult.correct:  icon = Icons.check_circle_rounded;  color = AppColors.accentGreen; break;
      case QuestionResult.wrong:    icon = Icons.cancel_rounded;        color = Colors.red.shade400;   break;
      case QuestionResult.timeout:  icon = Icons.timer_off_rounded;     color = Colors.orange;         break;
      case QuestionResult.skipped:  icon = Icons.skip_next_rounded;     color = AppColors.textMuted;   break;
    }
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 10),
        Expanded(
          child: Text(s.target, style: GoogleFonts.notoSerif(fontSize: 13,
              fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        ),
        if (s.chosen != null)
          Text('→ ${s.chosen}',
              style: GoogleFonts.inter(fontSize: 10, color: AppColors.textMuted)),
        const SizedBox(width: 8),
        Text('(${s.correctAnswer})',
            style: GoogleFonts.inter(fontSize: 10,
                color: AppColors.accentGreen, fontWeight: FontWeight.w600)),
      ],
    );
  }



  String _formatTime(int s) {
    final m = s ~/ 60;
    final sec = s % 60;
    return '${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }
}
