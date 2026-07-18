import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import '../../services/api_service.dart';
import 'roleplay_models.dart';
import 'roleplay_result_screen.dart';

const _kAccent = Color(0xFFC41230);

double _similarity(String a, String b) {
  final s1 = a.trim().toLowerCase();
  final s2 = b.trim().toLowerCase();
  if (s1.isEmpty || s2.isEmpty) return 0.0;
  if (s1 == s2) return 1.0;

  final rows = s1.length + 1;
  final cols = s2.length + 1;
  final dp   = List.generate(rows, (_) => List<int>.filled(cols, 0));

  for (int i = 0; i < rows; i++) dp[i][0] = i;
  for (int j = 0; j < cols; j++) dp[0][j] = j;

  for (int i = 1; i < rows; i++) {
    for (int j = 1; j < cols; j++) {
      if (s1[i - 1] == s2[j - 1]) {
        dp[i][j] = dp[i - 1][j - 1];
      } else {
        dp[i][j] = 1 + [dp[i-1][j], dp[i][j-1], dp[i-1][j-1]].reduce(math.min);
      }
    }
  }
  final dist = dp[s1.length][s2.length];
  final maxLen = math.max(s1.length, s2.length);
  return 1.0 - dist / maxLen;
}

class RolePlayGameplayScreen extends StatefulWidget {
  final String storyTitle, storyEmoji, roomCode;
  final RolePlayCharacter myCharacter;
  final List<RolePlayDialogue> dialogues;

  const RolePlayGameplayScreen({
    super.key,
    required this.storyTitle,
    required this.storyEmoji,
    required this.roomCode,
    required this.myCharacter,
    required this.dialogues,
  });

  @override
  State<RolePlayGameplayScreen> createState() => _RolePlayGameplayScreenState();
}

class _RolePlayGameplayScreenState extends State<RolePlayGameplayScreen>
    with TickerProviderStateMixin {

  final SpeechToText _speech = SpeechToText();
  bool _speechAvailable = false;
  String _liveTranscript = '';
  double _soundLevel = 0.0;

  int _currentLine = 0;
  bool _isListening = false;
  int _attempts = 0;
  static const _maxAttempts = 3;
  static const _passThreshold = 0.55;
  final List<RolePlayCompletedLine> _completedLines = [];
  DateTime? _startTime;

  // Poll sync timer
  Timer? _syncTimer;
  RolePlayRoom? _roomState;
  bool _evaluating = false;

  late AnimationController _bubbleCtrl;
  late Animation<double> _bubbleSlide;
  late Animation<double> _bubbleOpacity;
  late AnimationController _yourTurnCtrl;
  late Animation<double> _yourTurnPulse;
  late AnimationController _resultCtrl;
  late Animation<double> _resultScale;
  _LineResult? _lastResult;

  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
    _initSpeech();

    _bubbleCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _bubbleSlide = Tween<double>(begin: 20, end: 0).animate(
        CurvedAnimation(parent: _bubbleCtrl, curve: Curves.easeOutCubic));
    _bubbleOpacity = Tween<double>(begin: 0, end: 1).animate(_bubbleCtrl);

    _yourTurnCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _yourTurnPulse = Tween<double>(begin: 1.0, end: 1.08).animate(
        CurvedAnimation(parent: _yourTurnCtrl, curve: Curves.easeInOut));

    _resultCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _resultScale = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _resultCtrl, curve: Curves.elasticOut));

    _bubbleCtrl.forward(from: 0);

    // Start sync polling
    _syncTimer = Timer.periodic(const Duration(seconds: 2), (_) => _pollRoomState());
    _pollRoomState();
  }

  Future<void> _initSpeech() async {
    final available = await _speech.initialize(
      onStatus: _onSpeechStatus,
      onError:  (e) => debugPrint('STT error: $e'),
    );
    if (mounted) setState(() => _speechAvailable = available);
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    _speech.stop();
    _bubbleCtrl.dispose();
    _yourTurnCtrl.dispose();
    _resultCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _pollRoomState() async {
    if (_evaluating || !mounted) return;
    try {
      final room = RolePlayRoom.fromJson(
        await ApiService.instance.getRolePlayRoom(widget.roomCode),
      );
      if (!mounted) return;
      setState(() => _roomState = room);

      if (room.status == 'finished') {
        _syncTimer?.cancel();
        _showResults();
        return;
      }

      final serverIdx = room.current_dialogue_index;
      if (serverIdx > _currentLine && serverIdx <= widget.dialogues.length) {
        // Sync catch up
        for (int i = _currentLine; i < serverIdx; i++) {
          final d = widget.dialogues[i];
          _completedLines.add(RolePlayCompletedLine(d, true, 1.0, ''));
        }
        setState(() {
          _currentLine = serverIdx;
          _attempts = 0;
          _isListening = false;
        });
        _bubbleCtrl.forward(from: 0);
        _scrollToBottom();
      }

      // Check if current dialogue is NPC (not mapped to any player in this room)
      _checkAndProcessNPCLine(serverIdx);
    } catch (_) {}
  }

  void _checkAndProcessNPCLine(int currentIdx) {
    if (_roomState == null || currentIdx >= widget.dialogues.length) return;
    final d = widget.dialogues[currentIdx];

    // Find if any player in the room is playing this dialogue's character
    final isPlayerMapped = _roomState!.members.any((m) => m.characterId == d.characterId);
    
    // If not mapped (NPC/AI), the room host (creator) device auto-submits correct dialogue after 3 seconds
    if (!isPlayerMapped) {
      final myUserId = ApiService.instance.currentUserNotifier.value?['id'] as int? ?? 0;
      final isCreator = _roomState!.creatorId == myUserId;

      if (isCreator) {
        _evaluating = true;
        Future.delayed(const Duration(seconds: 3), () async {
          try {
            await ApiService.instance.submitRolePlayLine(
              widget.roomCode,
              dialogueId: d.id,
              correct: true,
              score: 1.0,
              passed: true,
            );
            _evaluating = false;
            _pollRoomState();
          } catch (_) {
            _evaluating = false;
          }
        });
      }
    }
  }

  RolePlayDialogue? get _currentDialogue =>
      _currentLine < widget.dialogues.length
          ? widget.dialogues[_currentLine]
          : null;

  bool get _isMyTurn =>
      _currentDialogue?.characterId == widget.myCharacter.id;

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 200), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent + 200,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _startListening() async {
    if (!mounted) return;
    if (!_speechAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Voice recognition not initialized.')),
      );
      return;
    }

    setState(() {
      _isListening = true;
      _liveTranscript = '';
      _soundLevel = 0;
    });

    await _speech.listen(
      localeId: 'ja_JP',
      onResult: _onSpeechResult,
      onSoundLevelChange: (level) {
        if (mounted) setState(() => _soundLevel = level.clamp(0.0, 10.0));
      },
      listenFor: const Duration(seconds: 15),
      pauseFor:  const Duration(seconds: 5),
      partialResults: true,
    );
  }

  void _onSpeechStatus(String status) {
    if ((status == 'done' || status == 'notListening') && _isListening) {
      _processResult(_liveTranscript);
    }
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    if (!mounted) return;
    setState(() => _liveTranscript = result.recognizedWords);
    if (result.finalResult) {
      _processResult(result.recognizedWords);
    }
  }

  Future<void> _processResult(String recognized) async {
    if (!mounted || _currentDialogue == null || _evaluating) return;
    _speech.stop();

    setState(() => _evaluating = true);

    final expected = _currentDialogue!.japanese;
    final score    = _similarity(recognized, expected);
    final correct  = score >= _passThreshold;
    final passed   = correct || _attempts >= _maxAttempts - 1;

    setState(() {
      _isListening = false;
      _soundLevel  = 0;
      _attempts++;
      _lastResult  = _LineResult(correct: correct, score: score, recognized: recognized);
    });
    _resultCtrl.forward(from: 0);

    try {
      await ApiService.instance.submitRolePlayLine(
        widget.roomCode,
        dialogueId: _currentDialogue!.id,
        correct: correct,
        score: score,
        passed: passed,
      );
      _evaluating = false;
      
      if (passed) {
        _completedLines.add(RolePlayCompletedLine(
            _currentDialogue!, correct, score, recognized));
        setState(() {
          _currentLine++;
          _attempts = 0;
        });
        _bubbleCtrl.forward(from: 0);
        _scrollToBottom();
      }
      
      _pollRoomState();
    } catch (_) {
      setState(() => _evaluating = false);
    }
  }

  void _showResults() {
    final elapsed = DateTime.now().difference(_startTime!);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => RolePlayResultScreen(
          result: RolePlayResult(
            storyTitle: widget.storyTitle,
            storyEmoji: widget.storyEmoji,
            roomCode:   widget.roomCode,
            lines:      List.unmodifiable(_completedLines),
            elapsed:    elapsed,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final d = _currentDialogue;

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: Stack(
                children: [
                  _buildSceneBg(),
                  _buildChatList(),
                  if (d != null)
                    _isMyTurn
                        ? _buildYourTurnPanel(d)
                        : _buildWaitingTurnPanel(d),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    final progress = _currentLine / math.max(widget.dialogues.length, 1);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      child: Column(
        children: [
          Row(
            children: [
              Text(widget.storyEmoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(widget.storyTitle,
                    style: GoogleFonts.spaceGrotesk(
                        fontSize: 14, fontWeight: FontWeight.w700,
                        color: Colors.white)),
              ),
              Text('${_currentLine}/${widget.dialogues.length}',
                  style: GoogleFonts.inter(
                      fontSize: 12, color: Colors.white38,
                      fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white10,
              valueColor: const AlwaysStoppedAnimation<Color>(_kAccent),
              minHeight: 3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSceneBg() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0F0F1A), Color(0xFF1A0A12)],
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
        ),
      ),
      child: Center(
        child: Opacity(
          opacity: 0.04,
          child: Text(widget.storyEmoji, style: const TextStyle(fontSize: 200)),
        ),
      ),
    );
  }

  Widget _buildChatList() {
    return Positioned.fill(
      bottom: 200,
      child: ListView.builder(
        controller: _scrollCtrl,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        itemCount: _completedLines.length,
        itemBuilder: (_, i) => _buildCompletedBubble(_completedLines[i]),
      ),
    );
  }

  Widget _buildCompletedBubble(RolePlayCompletedLine line) {
    final isMe = line.dialogue.characterId == widget.myCharacter.id;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            Container(
              width: 32, height: 32,
              decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF2A2A3E)),
              child: Center(
                child: Text(line.dialogue.speakerEmoji, style: const TextStyle(fontSize: 16)),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isMe ? const Color(0xFF2D0A12) : const Color(0xFF1E2035),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMe ? 16 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 16),
                ),
                border: Border.all(
                  color: isMe
                      ? _kAccent.withOpacity(line.correct ? 0.45 : 0.2)
                      : Colors.white10,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(line.dialogue.japanese,
                      style: GoogleFonts.notoSans(
                          fontSize: 15, fontWeight: FontWeight.w700,
                          color: Colors.white, height: 1.4)),
                  const SizedBox(height: 3),
                  Text(line.dialogue.english,
                      style: GoogleFonts.inter(fontSize: 11, color: Colors.white54)),
                ],
              ),
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: 8),
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.myCharacter.color.withOpacity(0.3),
                border: Border.all(color: widget.myCharacter.color),
              ),
              child: Center(
                child: Text(widget.myCharacter.emoji, style: const TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildYourTurnPanel(RolePlayDialogue line) {
    return Positioned(
      bottom: 0, left: 0, right: 0,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_lastResult != null)
            AnimatedBuilder(
              animation: _resultScale,
              builder: (_, child) => Transform.scale(scale: _resultScale.value, child: child),
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: _lastResult!.correct ? const Color(0xFF064E3B) : const Color(0xFF7C2D12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_lastResult!.correct ? '✅' : '🔄'),
                    const SizedBox(width: 8),
                    Text(
                      _lastResult!.correct
                          ? '${(_lastResult!.score * 100).toInt()}% match!'
                          : 'Try again (${_attempts}/$_maxAttempts)',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: Colors.white, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),

          Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFF1A0A0E),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: _kAccent.withOpacity(_isListening ? 0.7 : 0.35), width: _isListening ? 2 : 1.5),
              boxShadow: [
                BoxShadow(color: _kAccent.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 4)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedBuilder(
                  animation: _yourTurnPulse,
                  builder: (_, child) => Transform.scale(
                    scale: _yourTurnPulse.value,
                    alignment: Alignment.centerLeft,
                    child: child,
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFFEB4B6E), Color(0xFFBF1B2C)]),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('YOUR TURN',
                        style: GoogleFonts.inter(
                            fontSize: 10, fontWeight: FontWeight.w800,
                            color: Colors.white, letterSpacing: 1.5)),
                  ),
                ),
                const SizedBox(height: 10),

                Text(line.japanese,
                    style: GoogleFonts.notoSans(
                        fontSize: 22, fontWeight: FontWeight.w700,
                        color: Colors.white, height: 1.4)),
                if (line.romaji.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(line.romaji, style: GoogleFonts.inter(fontSize: 12, color: Colors.white38)),
                ],
                const SizedBox(height: 14),

                if (_isListening) ...[
                  _WaveformBars(level: _soundLevel),
                  const SizedBox(height: 8),
                  if (_liveTranscript.isNotEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(_liveTranscript, style: GoogleFonts.notoSans(fontSize: 15, color: Colors.white70)),
                    ),
                ] else
                  GestureDetector(
                    onTap: _startListening,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: _kAccent.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _kAccent.withOpacity(0.4)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.mic_rounded, color: _kAccent, size: 20),
                          const SizedBox(width: 8),
                          Text('Tap to speak',
                              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: _kAccent)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaitingTurnPanel(RolePlayDialogue line) {
    return Positioned(
      bottom: 0, left: 0, right: 0,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFF161622),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                "WAITING FOR ${line.speakerName.toUpperCase()}",
                style: GoogleFonts.inter(
                    fontSize: 9, fontWeight: FontWeight.w800,
                    color: Colors.white60, letterSpacing: 1.2),
              ),
            ),
            const SizedBox(height: 12),
            Text(line.japanese,
                style: GoogleFonts.notoSans(
                    fontSize: 20, fontWeight: FontWeight.w700,
                    color: Colors.white54, height: 1.4)),
            const SizedBox(height: 4),
            Text(line.english,
                style: GoogleFonts.inter(fontSize: 12, color: Colors.white30)),
          ],
        ),
      ),
    );
  }
}

class _WaveformBars extends StatelessWidget {
  final double level;
  const _WaveformBars({required this.level});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(22, (i) {
          final phase = i * 0.45;
          final base  = 6.0;
          final amp   = (level / 10) * 28;
          final h     = base + amp * math.pow(
              math.sin(DateTime.now().millisecondsSinceEpoch / 200.0 + phase).abs(), 0.4);
          return Container(
            width: 3,
            height: h.toDouble(),
            margin: const EdgeInsets.symmetric(horizontal: 1.5),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFEB4B6E), Color(0xFFBF1B2C)],
                begin: Alignment.topCenter, end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          );
        }),
      ),
    );
  }
}

class _LineResult {
  final bool correct;
  final double score;
  final String recognized;
  const _LineResult({
    required this.correct,
    required this.score,
    required this.recognized,
  });
}
