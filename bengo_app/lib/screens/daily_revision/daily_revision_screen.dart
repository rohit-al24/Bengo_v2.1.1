import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/api_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';

class DailyRevisionScreen extends StatefulWidget {
  const DailyRevisionScreen({super.key});

  @override
  State<DailyRevisionScreen> createState() => _DailyRevisionScreenState();
}

class _DailyRevisionScreenState extends State<DailyRevisionScreen> {
  bool _loading = true;
  bool _submitting = false;
  bool _finished = false;
  int _currentIndex = 0;
  int _secondsLeft = 0;
  int? _selectedAnswerIndex;
  bool _answerLocked = false;
  Timer? _timer;

  Map<String, dynamic> _config = {};
  List<Map<String, dynamic>> _questions = [];
  final List<Map<String, dynamic>> _results = [];
  Map<String, dynamic>? _submission;

  int _attemptsToday = 0;
  int _attemptLimit = 1;
  int _remainingAttempts = 1;
  int _streakTimeRemainingSeconds = 0;

  @override
  void initState() {
    super.initState();
    _loadSession();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadSession() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final session = await ApiService.instance.getDailyRevisionSession();
      final questions = (session['questions'] as List?)
              ?.map<Map<String, dynamic>>(
                  (q) => Map<String, dynamic>.from(q as Map))
              .toList() ??
          <Map<String, dynamic>>[];
      final config = Map<String, dynamic>.from(session['config'] as Map? ?? {});
      if (!mounted) return;
      final attemptsToday = session['attempts_today'] as int? ?? 0;
      final attemptLimit = session['attempt_limit'] as int? ??
          (config['daily_limit'] as int? ?? 1);
      final remainingAttempts = session['remaining_attempts'] as int? ??
          (attemptLimit - attemptsToday);
      final streakTimeRemaining = session['streak_time_remaining_seconds'] as int? ?? 0;
      setState(() {
        _config = config;
        _questions = questions;
        _secondsLeft = (config['timer_minutes'] as int? ?? 10) * 60;
        _attemptsToday = attemptsToday;
        _attemptLimit = attemptLimit;
        _remainingAttempts = remainingAttempts < 0 ? 0 : remainingAttempts;
        _streakTimeRemainingSeconds = streakTimeRemaining;
        _loading = false;
      });
      _startTimer();
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  void _startTimer() {
    _timer?.cancel();
    if (_secondsLeft <= 0) return;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() => _secondsLeft--);
      if (_secondsLeft <= 0) {
        timer.cancel();
        _finishSession(force: true);
      }
    });
  }

  void _answerQuestion(int index) {
    if (_answerLocked || _finished || _currentIndex >= _questions.length)
      return;
    final question = _questions[_currentIndex];
    final correctIndex = question['correct_index'] as int? ?? 0;
    final selected = index;
    final isCorrect = selected == correctIndex;
    _results.add({
      'target': question['target'],
      'chosen': question['options']?[selected],
      'correct_answer': question['correct_answer'],
      'correct': isCorrect,
      'xp': isCorrect ? (_config['per_question_xp'] as int? ?? 5) : 0,
    });
    setState(() {
      _selectedAnswerIndex = index;
      _answerLocked = true;
    });
    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      if (_currentIndex < _questions.length - 1) {
        setState(() {
          _currentIndex++;
          _selectedAnswerIndex = null;
          _answerLocked = false;
        });
      } else {
        _finishSession();
      }
    });
  }

  Future<void> _finishSession({bool force = false}) async {
    if (_finished) return;
    _timer?.cancel();
    if (!force && _currentIndex < _questions.length) {
      final question = _questions[_currentIndex];
      _results.add({
        'target': question['target'],
        'chosen': null,
        'correct_answer': question['correct_answer'],
        'correct': false,
        'xp': 0,
      });
    }
    if (!mounted) return;
    setState(() => _finished = true);
    if (_submitting) return;
    setState(() => _submitting = true);
    try {
      final total = _results.length;
      final correct = _results.where((r) => r['correct'] == true).length;
      final wrong = total - correct;
      final submission = await ApiService.instance.submitDailyRevision(
        total: total,
        correct: correct,
        wrong: wrong,
        timedOut: force ? 0 : 0,
      );
      if (!mounted) return;
      setState(() {
        _submission = submission;
        _submitting = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _submitting = false);
    }
  }

  Widget _buildQuestionCard() {
    if (_questions.isEmpty) {
      final message = _remainingAttempts <= 0
          ? 'Daily revision limit reached. Come back tomorrow.'
          : 'No revision questions are available yet. Complete some take-tests first so this revision pool can be built from your unlocked exams.';
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.auto_awesome,
                  size: 52, color: AppColors.primary),
              const SizedBox(height: 16),
              Text(
                _remainingAttempts <= 0
                    ? 'Come back tomorrow'
                    : 'No revision questions are available yet.',
                style: AppTextStyles.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              if (_remainingAttempts > 0)
                Text(
                    'Attempts: $_attemptsToday / $_attemptLimit • Available: $_remainingAttempts',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.textSecondary),
                    textAlign: TextAlign.center),
            ],
          ),
        ),
      );
    }

    final question = _questions[_currentIndex];
    final options =
        (question['options'] as List?)?.map((o) => o.toString()).toList() ??
            <String>[];
    final attemptsLabel = 'Attempts: $_attemptsToday / $_attemptLimit';
    final availableLabel = _remainingAttempts > 0
        ? 'Available attempts: $_remainingAttempts'
        : 'Daily limit reached — come back tomorrow';
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Daily Revision', style: AppTextStyles.headlineMedium),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14)),
                child: Text('${_currentIndex + 1}/${_questions.length}',
                    style: AppTextStyles.labelMedium
                        .copyWith(color: AppColors.primary)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                  child: Text(attemptsLabel,
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.textSecondary))),
              Expanded(
                  child: Text(availableLabel,
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.textSecondary),
                      textAlign: TextAlign.end)),
            ],
          ),
          const SizedBox(height: 10),
          Text('Time left: ${_formatSeconds(_secondsLeft)}',
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 6),
          Text(
            'Streak window: ${_formatSeconds(_streakTimeRemainingSeconds)} left to complete today’s revision',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.borderLight)),
            child: Text(question['target']?.toString() ?? '',
                style: AppTextStyles.headlineSmall.copyWith(fontSize: 20)),
          ),
          const SizedBox(height: 16),
          ...List.generate(options.length, (index) {
            final selected = _selectedAnswerIndex == index;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: InkWell(
                onTap: _answerLocked ? null : () => _answerQuestion(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.primary.withValues(alpha: 0.14)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: selected
                            ? AppColors.primary
                            : AppColors.borderLight),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: selected
                                ? AppColors.primary
                                : AppColors.bgLight),
                        alignment: Alignment.center,
                        child: Text(String.fromCharCode(65 + index),
                            style: GoogleFonts.inter(
                                fontSize: 12,
                                color: selected
                                    ? Colors.white
                                    : AppColors.textSecondary)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                          child: Text(options[index],
                              style: AppTextStyles.bodyMedium)),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSummaryScreen() {
    final percent =
        _submission != null && (_submission!['score_pct'] as num?) != null
            ? (_submission!['score_pct'] as num).toDouble()
            : 0.0;
    final xp =
        _submission != null ? (_submission!['xp_gained'] as int? ?? 0) : 0;
    final streak =
        _submission != null ? (_submission!['streak_gained'] as int? ?? 0) : 0;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ListView(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.borderLight)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Daily Revision Complete',
                    style: AppTextStyles.headlineMedium),
                const SizedBox(height: 8),
                Text(
                    'Your results are ready. You earned a fresh boost for today’s recall session.',
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: AppColors.textSecondary)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                        child: _miniSummaryCard(
                            '${percent.toStringAsFixed(0)}%',
                            'Accuracy',
                            Icons.percent_rounded,
                            AppColors.primary)),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _miniSummaryCard('$xp XP', 'Reward',
                            Icons.bolt_rounded, Colors.orange)),
                  ],
                ),
                const SizedBox(height: 10),
                _miniSummaryCard('$streak streak', 'Streak',
                    Icons.local_fire_department_rounded, Colors.redAccent),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text('Detailed Summary', style: AppTextStyles.headlineSmall),
          const SizedBox(height: 8),
          ..._results.map((result) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderLight)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                            result['correct'] == true
                                ? Icons.check_circle_rounded
                                : Icons.cancel_rounded,
                            color: result['correct'] == true
                                ? Colors.green
                                : Colors.redAccent),
                        const SizedBox(width: 8),
                        Expanded(
                            child: Text(result['target'].toString(),
                                style: AppTextStyles.labelMedium)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('Your answer: ${result['chosen'] ?? 'No answer'}',
                        style: AppTextStyles.bodyMedium
                            .copyWith(color: AppColors.textSecondary)),
                    Text('Correct answer: ${result['correct_answer']}',
                        style: AppTextStyles.bodyMedium
                            .copyWith(color: AppColors.textSecondary)),
                    if (result['correct'] == true)
                      Text('+${result['xp']} XP earned',
                          style: AppTextStyles.bodyMedium
                              .copyWith(color: AppColors.primary)),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _miniSummaryCard(
      String value, String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: AppTextStyles.labelMedium
                        .copyWith(color: AppColors.textPrimary)),
                Text(label,
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        title: const Text('Daily Revision'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _finished
              ? _submitting
                  ? const Center(child: CircularProgressIndicator())
                  : _buildSummaryScreen()
              : (_remainingAttempts <= 0
                  ? _buildLimitReachedScreen()
                  : _buildQuestionCard()),
    );
  }

  Widget _buildLimitReachedScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.hourglass_disabled_outlined,
                size: 60, color: AppColors.primary),
            const SizedBox(height: 20),
            Text('Daily limit reached',
                style: AppTextStyles.headlineSmall
                    .copyWith(color: AppColors.textPrimary)),
            const SizedBox(height: 12),
            Text(
              'You have used all your daily revision attempts. Please come back tomorrow for more practice.',
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Text(
              'Attempts today: $_attemptsToday / $_attemptLimit',
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textPrimary),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatSeconds(int seconds) {
  final mins = seconds ~/ 60;
  final secs = seconds % 60;
  return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
}
