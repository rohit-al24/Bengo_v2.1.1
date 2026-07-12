import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/api_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_decorations.dart';
import '../../widgets/bengo_app_bar.dart';
import 'team_result_screen.dart';

class TeamGameScreen extends StatefulWidget {
  const TeamGameScreen({super.key, required this.teamId});
  final int teamId;

  @override
  State<TeamGameScreen> createState() => _TeamGameScreenState();
}

class _TeamGameScreenState extends State<TeamGameScreen> {
  bool _loading = true;
  Map<String, dynamic>? _team;
  late List<Map<String, dynamic>> _questions;
  int _currentIndex = 0;
  int _timeLeft = 15;
  Timer? _timer;
  bool _showReveal = false;
  int? _selectedAnswer;
  int _score = 0;
  int _streak = 0;
  int _knives = 0;
  int _shields = 1;
  int _eliminates = 0;
  int _shieldCost = 2;
  int _megaShieldCost = 4;
  List<String> _events = [];
  bool _isPaused = false;

  @override
  void initState() {
    super.initState();
    _questions = _buildQuestions();
    _loadTeam();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadTeam() async {
    try {
      final team = await ApiService.instance.getTeam(widget.teamId);
      setState(() {
        _team = team;
        final settings = (team['settings'] as Map?)?.cast<String, dynamic>();
        _timeLeft = settings?['question_timer']?.toInt() ?? 15;
      });
      _startTimer();
    } catch (_) {
      setState(() {
        _events.add('Failed to load game state.');
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  List<Map<String, dynamic>> _buildQuestions() {
    return [
      {
        'id': 1,
        'prompt': 'What does "にほん" mean?',
        'options': ['Water', 'Japan', 'Book', 'Home'],
        'correct': 1,
      },
      {
        'id': 2,
        'prompt': 'Choose the word for "water".',
        'options': ['みず', 'いえ', 'ほん', 'にわ'],
        'correct': 0,
      },
      {
        'id': 3,
        'prompt': 'Select the meaning of "いえ".',
        'options': ['Book', 'House', 'Friend', 'Teacher'],
        'correct': 1,
      },
    ];
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isPaused) return;
      if (_timeLeft <= 0) {
        timer.cancel();
        _revealAnswer();
        return;
      }
      setState(() {
        _timeLeft -= 1;
      });
    });
  }

  void _revealAnswer() {
    setState(() {
      _showReveal = true;
      _selectedAnswer ??= -1;
    });
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      _advanceQuestion();
    });
  }

  void _advanceQuestion() {
    setState(() {
      _showReveal = false;
      _selectedAnswer = null;
      _currentIndex += 1;
      _timeLeft = (_team?['settings']?['question_timer']?.toInt() ?? 15);
    });
    if (_currentIndex >= _questions.length) {
      _finishGame();
      return;
    }
    _startTimer();
  }

  void _selectAnswer(int index) {
    if (_showReveal) return;
    setState(() {
      _selectedAnswer = index;
      _showReveal = true;
    });
    _timer?.cancel();
    final current = _questions[_currentIndex];
    final correct = current['correct'] as int;
    if (index == correct) {
      _score += 10;
      _streak += 1;
      _events.insert(0, 'Correct answer +10 points.');
      if (_streak >= (_team?['settings']?['knife_threshold']?.toInt() ?? 3)) {
        _knives += 1;
        _events.insert(0, 'Knife earned from streak.');
      }
      if (_streak >= (_team?['settings']?['eliminate_threshold']?.toInt() ?? 5)) {
        _eliminates += 1;
        _events.insert(0, 'Eliminate charge ready.');
      }
    } else {
      _score = (_score - 3).clamp(0, 9999);
      _streak = 0;
      _events.insert(0, 'Wrong answer -3 points.');
    }
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      _advanceQuestion();
    });
  }

  Future<void> _finishGame() async {
    _timer?.cancel();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (_) => TeamResultScreen(
        teamId: widget.teamId,
        score: _score,
        streak: _streak,
        events: _events,
      ),
    ));
  }

  void _togglePause() {
    setState(() {
      _isPaused = !_isPaused;
    });
  }

  void _startKnifeAttack() {
    if (_knives <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No knives available.')));
      return;
    }
    showDialog(
      context: context,
      builder: (context) {
        final members = (_team?['members'] as List<dynamic>? ?? []).where((member) => member['user'] != _getCurrentUserId()).toList();
        return AlertDialog(
          backgroundColor: const Color(0xFF0F1628),
          title: Text('Knife Attack', style: GoogleFonts.inter(color: Colors.white)),
          content: members.isEmpty
              ? Text('No available targets.', style: GoogleFonts.inter(color: Colors.grey.shade400))
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: members.map((member) {
                    final username = member['user'].toString();
                    return ListTile(
                      title: Text(username, style: GoogleFonts.inter(color: Colors.white)),
                      trailing: const Icon(Icons.chevron_right, color: Colors.white70),
                      onTap: () {
                        Navigator.of(context).pop();
                        _executeKnife(member['user'] as int);
                      },
                    );
                  }).toList(),
                ),
        );
      },
    );
  }

  void _executeKnife(int targetId) {
    _confirmAttack(
      attackName: 'Knife',
      targetId: targetId,
      damage: (_score * (_team?['settings']?['knife_points_percentage']?.toInt() ?? 25) / 100).round(),
    );
  }

  void _startEliminateAttack() {
    if (_eliminates <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No eliminate charges available.')));
      return;
    }
    showDialog(
      context: context,
      builder: (context) {
        final members = (_team?['members'] as List<dynamic>? ?? [])
            .where((member) => member['user'] != _getCurrentUserId())
            .toList();
        return AlertDialog(
          backgroundColor: const Color(0xFF0F1628),
          title: Text('Eliminate Attack', style: GoogleFonts.inter(color: Colors.white)),
          content: members.isEmpty
              ? Text('No available targets.', style: GoogleFonts.inter(color: Colors.grey.shade400))
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: members.map((member) {
                    final username = member['user'].toString();
                    return ListTile(
                      title: Text(username, style: GoogleFonts.inter(color: Colors.white)),
                      trailing: const Icon(Icons.chevron_right, color: Colors.white70),
                      onTap: () {
                        Navigator.of(context).pop();
                        _applyAttack(
                          attackName: 'Eliminate',
                          targetName: username,
                          damage: 100,
                          isEliminate: true,
                          shieldUsed: false,
                        );
                      },
                    );
                  }).toList(),
                ),
        );
      },
    );
  }

  void _confirmAttack({
    required String attackName,
    required int targetId,
    required int damage,
    bool isEliminate = false,
  }) {
    final members = (_team?['members'] as List<dynamic>? ?? [])
        .where((member) => member['user'] != _getCurrentUserId())
        .toList();
    final target = members.firstWhere((member) => member['user'] == targetId, orElse: () => null);
    final targetName = target != null ? target['user'].toString() : 'Rival';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF0F1628),
          title: Text('$attackName Attack', style: GoogleFonts.inter(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Target: $targetName', style: GoogleFonts.inter(color: Colors.grey.shade300)),
              const SizedBox(height: 12),
              Text('Potential damage: $damage points.', style: GoogleFonts.inter(color: Colors.grey.shade400)),
              if (_shields > 0) ...[
                const SizedBox(height: 10),
                Text('Target may defend with a shield.', style: GoogleFonts.inter(color: Colors.grey.shade400)),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel', style: GoogleFonts.inter(color: AppColors.primary)),
            ),
            if (_shields > 0)
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _resolveShield(attackName: attackName, targetName: targetName, damage: damage, isEliminate: isEliminate);
                },
                child: Text('Shield defense', style: GoogleFonts.inter(color: AppColors.accentCyan)),
              ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _applyAttack(attackName: attackName, targetName: targetName, damage: damage, isEliminate: isEliminate, shieldUsed: false);
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: Text('Strike', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
            ),
          ],
        );
      },
    );
  }

  void _resolveShield({
    required String attackName,
    required String targetName,
    required int damage,
    bool isEliminate = false,
  }) {
    setState(() {
      _shields -= 1;
      _streak = (_streak - _shieldCost).clamp(0, 9999);
      _events.insert(0, '$targetName used a shield and blocked the $attackName. Streak -$_shieldCost.');
    });
  }

  void _applyAttack({
    required String attackName,
    required String targetName,
    required int damage,
    bool isEliminate = false,
    required bool shieldUsed,
  }) {
    setState(() {
      if (isEliminate) {
        _eliminates = (_eliminates - 1).clamp(0, 9999);
        _events.insert(0, '$attackName succeeded! $targetName eliminated for $damage points.');
      } else {
        _knives = (_knives - 1).clamp(0, 9999);
        _events.insert(0, 'Knife hit! $targetName lost $damage points.');
      }
      _score = (_score - damage).clamp(0, 9999);
    });
  }

  int _getCurrentUserId() {
    return ApiService.instance.currentUserNotifier.value?['id'] as int? ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildAppBar()),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                child: _loading ? const Center(child: CircularProgressIndicator()) : _buildGameContent(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return BenGoAppBar(
      showBack: true,
      title: 'Team Battle',
      actions: [
        IconButton(
          icon: Icon(_isPaused ? Icons.play_arrow : Icons.pause, color: Colors.white),
          onPressed: _togglePause,
        ),
      ],
    );
  }

  Widget _buildGameContent() {
    if (_currentIndex >= _questions.length) {
      return Center(child: Text('Finishing game...', style: GoogleFonts.inter(color: Colors.white)));
    }

    final question = _questions[_currentIndex];
    final correctIndex = question['correct'] as int;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Round ${_currentIndex + 1}/${_questions.length}', style: GoogleFonts.sourceCodePro(color: AppColors.accentCyan, letterSpacing: 2, fontSize: 11)),
        const SizedBox(height: 12),
        Text(question['prompt'] as String, style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w700, color: Colors.white)),
        const SizedBox(height: 20),
        _buildProgressBar(),
        const SizedBox(height: 8),
        Text('Time left: $_timeLeft sec', style: GoogleFonts.inter(color: AppColors.textLight)),
        const SizedBox(height: 24),
        ...List.generate((question['options'] as List<String>).length, (index) {
          final label = (question['options'] as List<String>)[index];
          final selected = _selectedAnswer == index;
          final isCorrect = _showReveal && index == correctIndex;
          final isWrong = _showReveal && selected && index != correctIndex;
          return _buildOptionCard(label, selected, isCorrect, isWrong, () {
            if (_showReveal) return;
            setState(() => _selectedAnswer = index);
            _selectAnswer(index);
          });
        }),
        const SizedBox(height: 22),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildStatTile('Score', '$_score'),
            _buildStatTile('Streak', '$_streak'),
            _buildStatTile('Knives', '$_knives'),
            _buildStatTile('Shields', '$_shields'),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: _knives > 0 ? _startKnifeAttack : null,
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                child: Text('Use Knife', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _eliminates > 0 ? _startEliminateAttack : null,
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentGold, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                child: Text('Eliminate', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text('Eliminate ready when streak reaches ${_team?['settings']?['eliminate_threshold']?.toInt() ?? 5}.', style: GoogleFonts.inter(color: AppColors.textLight, fontSize: 12)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _finishGame,
                style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.primary), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                child: Text('Finish', style: GoogleFonts.inter(color: AppColors.primary, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),
        _buildEventLog(),
      ],
    );
  }

  Widget _buildProgressBar() {
    final total = _team?['settings']?['question_timer']?.toInt() ?? 15;
    final value = total > 0 ? (_timeLeft / total) : 0.0;
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: LinearProgressIndicator(
        value: value,
        backgroundColor: Colors.white12,
        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
        minHeight: 12,
      ),
    );
  }

  Widget _buildOptionCard(String label, bool selected, bool isCorrect, bool isWrong, VoidCallback onTap) {
    final color = isCorrect
        ? Colors.greenAccent.shade700
        : isWrong
            ? Colors.redAccent.shade400
            : selected
                ? AppColors.primary
                : const Color(0xFF121A2E);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(16)),
        child: Text(label, style: GoogleFonts.inter(color: Colors.white, fontSize: 15)),
      ),
    );
  }

  Widget _buildStatTile(String title, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(color: const Color(0xFF101726), borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          Text(title, style: GoogleFonts.inter(color: AppColors.textLight, fontSize: 12)),
          const SizedBox(height: 8),
          Text(value, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18)),
        ],
      ),
    );
  }

  Widget _buildEventLog() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Battle log', style: GoogleFonts.sourceCodePro(color: AppColors.accentCyan, letterSpacing: 2, fontSize: 11)),
        const SizedBox(height: 10),
        ..._events.take(4).map((event) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text('• $event', style: GoogleFonts.inter(color: AppColors.textLight, fontSize: 13)),
            )),
      ],
    );
  }
}
