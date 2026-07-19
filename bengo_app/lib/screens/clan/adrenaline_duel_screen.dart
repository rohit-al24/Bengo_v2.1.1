import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/clan_service.dart';
import 'clan_theme.dart';
import 'match_result_screen.dart';

class AdrenalineDuelScreen extends StatefulWidget {
  const AdrenalineDuelScreen({super.key});

  @override
  State<AdrenalineDuelScreen> createState() => _AdrenalineDuelScreenState();
}

class _AdrenalineDuelScreenState extends State<AdrenalineDuelScreen>
    with TickerProviderStateMixin {

  // ── Config from API ────────────────────────────────────────────────────────
  int _matchTimer = 120;
  int _shieldThreshold = 3;
  List<DuelQuestion> _questions = [];

  // ── Game state ─────────────────────────────────────────────────────────────
  bool _loading = true;
  bool _gameStarted = false;
  bool _gameOver = false;

  int _timeRemaining = 120;
  Timer? _countdownTimer;

  int _qIndex = 0;
  String? _selectedAnswer;
  bool _answerLocked = false;

  // Player state
  double _myBP = 0.0;    // 0–100
  int _myCombo = 0;
  int _myCorrect = 0;
  int _myWrong = 0;

  // Opponent state (simulated for now; replace with WebSocket later)
  double _opponentBP = 0.0;
  int _opponentCombo = 0;

  // Shield
  bool _shieldOffered = false;
  bool _shieldUsed = false;

  // Animation controllers
  late final AnimationController _barCtrl;
  late final Animation<double> _myBarAnim;
  late final Animation<double> _oppBarAnim;

  @override
  void initState() {
    super.initState();
    _barCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _myBarAnim  = Tween<double>(begin: 0, end: 0).animate(_barCtrl);
    _oppBarAnim = Tween<double>(begin: 0, end: 0).animate(_barCtrl);
    _loadConfig();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _barCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadConfig() async {
    try {
      final cfg = await ClanService.instance.fetchDuelConfig();
      final count = cfg['questions_per_duel'] as int? ?? 20;
      final timer = cfg['duel_timer_seconds'] as int? ?? 120;
      final threshold = cfg['shield_combo_threshold'] as int? ?? 3;
      final questions = await ClanService.instance.fetchDuelQuestions(count);
      if (mounted) setState(() {
        _matchTimer     = timer;
        _timeRemaining  = timer;
        _shieldThreshold = threshold;
        _questions      = questions;
        _loading        = false;
      });
    } catch (e) {
      // Fallback: use defaults with dummy questions
      if (mounted) setState(() {
        _questions = _fallbackQuestions();
        _loading = false;
      });
    }
  }

  List<DuelQuestion> _fallbackQuestions() => [
    const DuelQuestion(id: 0, target: 'ありがとう', correctAnswer: 'Thank you', options: ['Thank you', 'Hello', 'Goodbye', 'Sorry']),
    const DuelQuestion(id: 1, target: 'おはよう', correctAnswer: 'Good morning', options: ['Good morning', 'Good evening', 'Good night', 'Goodbye']),
    const DuelQuestion(id: 2, target: '猫', correctAnswer: 'Cat', options: ['Cat', 'Dog', 'Bird', 'Fish']),
  ];

  void _startGame() {
    setState(() { _gameStarted = true; });
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() {
        _timeRemaining--;
        // Simulate opponent — increases by random small amount
        _opponentBP = (_opponentBP + 3.0 + (DateTime.now().millisecond % 5)).clamp(0.0, 100.0);
      });
      if (_timeRemaining <= 0) {
        t.cancel();
        _endGame();
      }
    });
  }

  void _onAnswer(String answer) {
    if (_answerLocked || _gameOver) return;
    setState(() {
      _selectedAnswer = answer;
      _answerLocked = true;
    });

    final current = _questions[_qIndex];
    final correct = answer == current.correctAnswer;

    if (correct) {
      final gain = 10.0 + (_myCombo * 2.0);
      _myBP = (_myBP + gain).clamp(0.0, 100.0);
      _myCombo++;
      _myCorrect++;

      // Check if opponent should be offered shield (simulated incoming attack)
      // In a real multiplayer flow this is server-driven; here it's local demo
    } else {
      _myBP = (_myBP - 5.0).clamp(0.0, 100.0);
      _myCombo = 0;
      _myWrong++;

      // Simulate attack arriving from opponent — offer shield to "player" if combo threshold met
      // For demo: if opponent combo is simulated high, we show shield prompt
      if (_opponentCombo >= _shieldThreshold && !_shieldUsed) {
        _offerShield();
      }
    }

    // Animate bar
    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      setState(() {
        _answerLocked = false;
        _selectedAnswer = null;
        if (_qIndex < _questions.length - 1) {
          _qIndex++;
        } else {
          _endGame();
        }
      });
    });
  }

  void _offerShield() {
    setState(() => _shieldOffered = true);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ShieldDialog(
        onShield: () {
          Navigator.pop(context);
          setState(() {
            _shieldUsed = true;
            _shieldOffered = false;
            // Reflect damage
            _opponentBP = (_opponentBP - 5.0).clamp(0.0, 100.0);
          });
        },
        onDecline: () {
          Navigator.pop(context);
          setState(() => _shieldOffered = false);
        },
      ),
    );
  }

  void _endGame() {
    _countdownTimer?.cancel();
    setState(() => _gameOver = true);
    final iWin = _myBP >= _opponentBP;
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(
        builder: (_) => MatchResultScreen(
          didWin: iWin,
          myCorrect: _myCorrect,
          myWrong: _myWrong,
          myCombo: _myCombo,
          myBP: _myBP.round(),
          opponentBP: _opponentBP.round(),
        ),
      ));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kClanBg,
      appBar: AppBar(
        backgroundColor: kClanBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: kClanInk),
          onPressed: () => _confirmQuit(context),
        ),
        title: Text('Adrenaline Duel',
          style: GoogleFonts.spaceGrotesk(fontSize: 18, fontWeight: FontWeight.w700, color: kClanInk)),
        actions: [
          if (_gameStarted && !_gameOver) Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: _TimerBadge(seconds: _timeRemaining),
          ),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: kClanAccent))
            : !_gameStarted
                ? _StartOverlay(questions: _questions, onStart: _startGame)
                : _GameBody(
                    question: _questions.isEmpty ? null : _questions[_qIndex],
                    questionIndex: _qIndex,
                    questionCount: _questions.length,
                    myBP: _myBP,
                    opponentBP: _opponentBP,
                    myCombo: _myCombo,
                    selectedAnswer: _selectedAnswer,
                    answerLocked: _answerLocked,
                    onAnswer: _onAnswer,
                    myCorrect: _myCorrect,
                    myWrong: _myWrong,
                  ),
      ),
    );
  }

  void _confirmQuit(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: kClanSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Quit Duel?', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700, color: kClanInk)),
        content: Text('You will forfeit this match.', style: GoogleFonts.inter(color: kClanMuted)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Stay', style: GoogleFonts.inter(color: kClanAccent, fontWeight: FontWeight.w700))),
          TextButton(onPressed: () { Navigator.pop(context); Navigator.pop(context); },
            child: Text('Quit', style: GoogleFonts.inter(color: kClanRed, fontWeight: FontWeight.w700))),
        ],
      ),
    );
  }
}

// ── Timer badge ───────────────────────────────────────────────────────────────

class _TimerBadge extends StatelessWidget {
  final int seconds;
  const _TimerBadge({required this.seconds});

  @override
  Widget build(BuildContext context) {
    final isUrgent = seconds <= 30;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isUrgent ? kClanAccentL : kClanSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isUrgent ? kClanAccent : kClanBorder, width: 1.5),
        boxShadow: kRaisedShadow,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer_rounded, size: 14, color: isUrgent ? kClanAccent : kClanMuted),
          const SizedBox(width: 4),
          Text(_fmt(seconds),
            style: GoogleFonts.spaceGrotesk(
              fontSize: 14, fontWeight: FontWeight.w800,
              color: isUrgent ? kClanAccent : kClanInk,
            )),
        ],
      ),
    );
  }

  String _fmt(int s) => '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';
}

// ── Start overlay ─────────────────────────────────────────────────────────────

class _StartOverlay extends StatelessWidget {
  final List<DuelQuestion> questions;
  final VoidCallback onStart;
  const _StartOverlay({required this.questions, required this.onStart});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ClanCard(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  color: kClanAccentL,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: kRaisedShadow,
                ),
                child: const Icon(Icons.sports_martial_arts_rounded, color: kClanAccent, size: 40),
              ),
              const SizedBox(height: 20),
              Text('Ready to Duel?',
                style: GoogleFonts.spaceGrotesk(fontSize: 24, fontWeight: FontWeight.w800, color: kClanInk)),
              const SizedBox(height: 8),
              Text('${questions.length} questions · Answer fast · Build combos to attack',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 14, color: kClanMuted, height: 1.5)),
              const SizedBox(height: 8),
              _RuleChip(icon: Icons.timer_rounded, label: 'Global countdown timer'),
              _RuleChip(icon: Icons.local_fire_department_rounded, label: 'Combos boost your BP'),
              _RuleChip(icon: Icons.shield_rounded, label: 'Shield available at Combo ×3+'),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ClanPillButton(label: 'Start Duel', icon: Icons.play_arrow_rounded, onPressed: onStart),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RuleChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _RuleChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: kClanAccent),
          const SizedBox(width: 6),
          Text(label, style: GoogleFonts.inter(fontSize: 12, color: kClanMuted)),
        ],
      ),
    );
  }
}

// ── Game body ─────────────────────────────────────────────────────────────────

class _GameBody extends StatelessWidget {
  final DuelQuestion? question;
  final int questionIndex, questionCount;
  final double myBP, opponentBP;
  final int myCombo, myCorrect, myWrong;
  final String? selectedAnswer;
  final bool answerLocked;
  final void Function(String) onAnswer;

  const _GameBody({
    required this.question,
    required this.questionIndex,
    required this.questionCount,
    required this.myBP,
    required this.opponentBP,
    required this.myCombo,
    required this.myCorrect,
    required this.myWrong,
    required this.selectedAnswer,
    required this.answerLocked,
    required this.onAnswer,
  });

  @override
  Widget build(BuildContext context) {
    if (question == null) return const SizedBox();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        children: [
          // ── Battle bars ──────────────────────────────────────────────────
          _BattleBarsRow(myBP: myBP, opponentBP: opponentBP, myCombo: myCombo),
          const SizedBox(height: 16),

          // ── Stats row ─────────────────────────────────────────────────────
          _StatsRow(correct: myCorrect, wrong: myWrong, combo: myCombo),
          const SizedBox(height: 16),

          // ── Question card ─────────────────────────────────────────────────
          Expanded(
            child: ClanCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Progress
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${questionIndex + 1} / $questionCount',
                        style: GoogleFonts.inter(fontSize: 12, color: kClanMuted, fontWeight: FontWeight.w600)),
                      ComboBadge(combo: myCombo),
                    ],
                  ),
                  ClanProgressBar(value: questionCount > 0 ? questionIndex / questionCount : 0, fillColor: kClanAccent, height: 6),
                  const SizedBox(height: 20),

                  // Target word
                  Expanded(
                    child: Center(
                      child: Text(
                        question!.target,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.notoSans(
                          fontSize: 42, fontWeight: FontWeight.w900, color: kClanInk,
                          height: 1.2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text('What does this mean?',
                    style: GoogleFonts.inter(fontSize: 13, color: kClanMuted)),
                  const SizedBox(height: 16),

                  // Answer options
                  ...question!.options.map((opt) => _AnswerButton(
                    text: opt,
                    isSelected: selectedAnswer == opt,
                    isCorrect: answerLocked && opt == question!.correctAnswer,
                    isWrong: answerLocked && selectedAnswer == opt && opt != question!.correctAnswer,
                    onTap: answerLocked ? null : () => onAnswer(opt),
                  )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Battle bars row ───────────────────────────────────────────────────────────

class _BattleBarsRow extends StatelessWidget {
  final double myBP, opponentBP;
  final int myCombo;
  const _BattleBarsRow({required this.myBP, required this.opponentBP, required this.myCombo});

  @override
  Widget build(BuildContext context) {
    return ClanCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        children: [
          Row(
            children: [
              Text('You', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: kClanAccent)),
              const Spacer(),
              Text('${myBP.round()} BP', style: GoogleFonts.spaceGrotesk(fontSize: 13, fontWeight: FontWeight.w700, color: kClanAccent)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Row(
              children: [
                // My bar (left)
                Expanded(
                  child: Container(
                    height: 20,
                    decoration: BoxDecoration(
                      color: kClanBorder,
                      borderRadius: const BorderRadius.only(topLeft: Radius.circular(8), bottomLeft: Radius.circular(8)),
                    ),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: FractionallySizedBox(
                        widthFactor: (myBP / 100).clamp(0.0, 1.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: kClanAccent,
                            borderRadius: const BorderRadius.only(topLeft: Radius.circular(8), bottomLeft: Radius.circular(8)),
                            boxShadow: [BoxShadow(color: kClanAccent.withOpacity(0.4), blurRadius: 4, offset: const Offset(0, 2))],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // Divider
                Container(width: 3, height: 20, color: kClanInk),
                // Opponent bar (right)
                Expanded(
                  child: Container(
                    height: 20,
                    decoration: BoxDecoration(
                      color: kClanBorder,
                      borderRadius: const BorderRadius.only(topRight: Radius.circular(8), bottomRight: Radius.circular(8)),
                    ),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor: (opponentBP / 100).clamp(0.0, 1.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF1565C0),
                            borderRadius: const BorderRadius.only(topRight: Radius.circular(8), bottomRight: Radius.circular(8)),
                            boxShadow: [const BoxShadow(color: Color(0x441565C0), blurRadius: 4, offset: Offset(0, 2))],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text('${opponentBP.round()} BP', style: GoogleFonts.spaceGrotesk(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF1565C0))),
              const Spacer(),
              Text('Opponent', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF1565C0))),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Stats row ─────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  final int correct, wrong, combo;
  const _StatsRow({required this.correct, required this.wrong, required this.combo});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: ClanCard(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: ClanStatChip(icon: Icons.check_circle_outline_rounded, value: correct.toString(), label: 'Correct'),
        )),
        const SizedBox(width: 8),
        Expanded(child: ClanCard(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: ClanStatChip(icon: Icons.cancel_outlined, value: wrong.toString(), label: 'Wrong'),
        )),
        const SizedBox(width: 8),
        Expanded(child: ClanCard(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: ClanStatChip(icon: Icons.local_fire_department_rounded, value: '×$combo', label: 'Combo'),
        )),
      ],
    );
  }
}

// ── Answer button ─────────────────────────────────────────────────────────────

class _AnswerButton extends StatelessWidget {
  final String text;
  final bool isSelected, isCorrect, isWrong;
  final VoidCallback? onTap;
  const _AnswerButton({required this.text, required this.isSelected, required this.isCorrect, required this.isWrong, this.onTap});

  @override
  Widget build(BuildContext context) {
    Color bgColor = kClanSurface;
    Color borderColor = kClanBorder;
    Color textColor = kClanInk;
    IconData? trailingIcon;

    if (isCorrect) {
      bgColor = const Color(0xFFE8F5E9);
      borderColor = kClanGreen;
      textColor = kClanGreen;
      trailingIcon = Icons.check_circle_rounded;
    } else if (isWrong) {
      bgColor = kClanAccentL;
      borderColor = kClanRed;
      textColor = kClanRed;
      trailingIcon = Icons.cancel_rounded;
    } else if (isSelected) {
      borderColor = kClanAccent;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: 1.5),
            boxShadow: kRaisedShadow,
          ),
          child: Row(
            children: [
              Expanded(child: Text(text, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: textColor))),
              if (trailingIcon != null) Icon(trailingIcon, color: textColor, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Shield dialog ─────────────────────────────────────────────────────────────

class _ShieldDialog extends StatelessWidget {
  final VoidCallback onShield;
  final VoidCallback onDecline;
  const _ShieldDialog({required this.onShield, required this.onDecline});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: kClanSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFFE3F2FD),
                borderRadius: BorderRadius.circular(16),
                boxShadow: kRaisedShadow,
              ),
              child: const Icon(Icons.shield_rounded, color: Color(0xFF1565C0), size: 36),
            ),
            const SizedBox(height: 16),
            Text('Incoming Attack!', style: GoogleFonts.spaceGrotesk(fontSize: 18, fontWeight: FontWeight.w800, color: kClanInk)),
            const SizedBox(height: 8),
            Text('Your opponent is attacking. Deploy your Shield to block and reflect 5% damage back!',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 13, color: kClanMuted, height: 1.5)),
            const SizedBox(height: 20),
            SizedBox(width: double.infinity,
              child: ClanPillButton(
                label: 'Deploy Shield',
                icon: Icons.shield_rounded,
                onPressed: onShield,
              )),
            const SizedBox(height: 10),
            SizedBox(width: double.infinity,
              child: ClanPillButton(
                label: 'Take the Hit',
                isOutlined: true,
                onPressed: onDecline,
              )),
          ],
        ),
      ),
    );
  }
}
