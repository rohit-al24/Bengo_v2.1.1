import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/roleplay_shell.dart';
import 'roleplay_models.dart';
import 'roleplay_gameplay_screen.dart';
import 'roleplay_history_screen.dart';
import 'roleplay_room_create_screen.dart';

const _kAccent = Color(0xFFC41230);
const _kInk = Color(0xFF1B1B1D);
const _kMuted = Color(0xFF8A8A8F);

const kDefaultCharacters = <RolePlayCharacter>[
  RolePlayCharacter(
      id: 1, name: 'Mina', emoji: '🧑‍🎓', displayOrder: 1, role: 'Student'),
  RolePlayCharacter(
      id: 2, name: 'Kai', emoji: '🕵️', displayOrder: 2, role: 'Detective'),
  RolePlayCharacter(
      id: 3, name: 'Rin', emoji: '🚀', displayOrder: 3, role: 'Explorer'),
  RolePlayCharacter(
      id: 4, name: 'Sora', emoji: '🎭', displayOrder: 4, role: 'Storyteller'),
];

const kRolePlayCharacters = <String, List<RolePlayCharacter>>{
  'Detective Mystery': [
    RolePlayCharacter(
        id: 1, name: 'Mina', emoji: '🧑‍🎓', displayOrder: 1, role: 'Student'),
    RolePlayCharacter(
        id: 2, name: 'Kai', emoji: '🕵️', displayOrder: 2, role: 'Detective'),
    RolePlayCharacter(
        id: 3, name: 'Rin', emoji: '🚀', displayOrder: 3, role: 'Explorer'),
  ],
  'Time Travel': [
    RolePlayCharacter(
        id: 1, name: 'Lina', emoji: '⏳', displayOrder: 1, role: 'Traveler'),
    RolePlayCharacter(
        id: 2, name: 'Jules', emoji: '🧠', displayOrder: 2, role: 'Historian'),
    RolePlayCharacter(
        id: 3, name: 'Miko', emoji: '🌌', displayOrder: 3, role: 'Pilot'),
  ],
};

// ── Screen ─────────────────────────────────────────────────────────────────────
class RolePlayCharacterSelectScreen extends StatefulWidget {
  final String storyTitle, storyEmoji, characterMode;
  final int characterCount;

  const RolePlayCharacterSelectScreen({
    super.key,
    required this.storyTitle,
    required this.storyEmoji,
    required this.characterCount,
    required this.characterMode,
  });

  @override
  State<RolePlayCharacterSelectScreen> createState() =>
      _RolePlayCharacterSelectScreenState();
}

class _RolePlayCharacterSelectScreenState
    extends State<RolePlayCharacterSelectScreen> with TickerProviderStateMixin {
  // Phases
  bool _isSpinning = true;
  bool _storyRevealed = false;

  // Selection
  int? _mySelection;
  final Set<int> _lockedByOthers = {};
  int _countdown = 30;
  Timer? _countdownTimer;

  // Animations
  late AnimationController _wheelCtrl;
  late AnimationController _revealCtrl;
  late AnimationController _countdownCtrl;
  late Animation<double> _revealScale;
  late Animation<double> _revealOpacity;

  late List<RolePlayCharacter> _characters;

  @override
  void initState() {
    super.initState();

    final storyChars =
        kRolePlayCharacters[widget.storyTitle] ?? kDefaultCharacters;
    _characters = storyChars.take(widget.characterCount).toList();

    // Wheel spin controller
    _wheelCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    );

    // Story reveal animation
    _revealCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _revealScale = Tween<double>(begin: 0.5, end: 1.0).animate(
        CurvedAnimation(parent: _revealCtrl, curve: Curves.elasticOut));
    _revealOpacity = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _revealCtrl, curve: Curves.easeOut));

    // Countdown progress bar
    _countdownCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    );

    // Start the spin sequence
    _wheelCtrl.forward();
    _wheelCtrl.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() {
          _isSpinning = false;
          _storyRevealed = true;
        });
        _revealCtrl.forward();
        Future.delayed(const Duration(milliseconds: 800), _startSelectionPhase);
      }
    });
  }

  void _startSelectionPhase() {
    if (!mounted) return;
    _countdownCtrl.forward();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() => _countdown--);
      // Simulate another player locking a character at t=20
      if (_countdown == 20 && _characters.length > 1) {
        setState(() => _lockedByOthers.add(1));
      }
      if (_countdown <= 0) {
        t.cancel();
        _autoAssignAndProceed();
      }
    });
  }

  void _selectCharacter(int index) {
    if (_lockedByOthers.contains(index)) return;
    setState(() => _mySelection = index);
  }

  void _confirmAndStart() {
    _countdownTimer?.cancel();
    final selected =
        _mySelection != null ? _characters[_mySelection!] : _characters[0];
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => RolePlayGameplayScreen(
          storyTitle: widget.storyTitle,
          storyEmoji: widget.storyEmoji,
          roomCode: 'BENGO',
          myCharacter: selected,
          dialogues: _buildFallbackDialogues(selected),
        ),
      ),
    );
  }

  List<RolePlayDialogue> _buildFallbackDialogues(RolePlayCharacter character) {
    return [
      RolePlayDialogue(
        id: 1,
        characterId: character.id,
        displayOrder: 1,
        speakerName: character.name,
        speakerEmoji: character.emoji,
        japanese: 'こんにちは',
        romaji: 'Konnichiwa',
        english: 'Hello! Let us begin our story.',
        emotion: 'friendly',
        pauseMs: 1200,
      ),
    ];
  }

  void _autoAssignAndProceed() {
    if (_mySelection == null) {
      for (int i = 0; i < _characters.length; i++) {
        if (!_lockedByOthers.contains(i)) {
          _mySelection = i;
          break;
        }
      }
    }
    Future.delayed(const Duration(milliseconds: 500), _confirmAndStart);
  }

  @override
  void dispose() {
    _wheelCtrl.dispose();
    _revealCtrl.dispose();
    _countdownCtrl.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RolePlayShell(
      title: 'Pick Your Role',
      subtitle: widget.storyTitle,
      showBack: true,
      onBackTap: () => Navigator.pop(context),
      selectedTab: null,
      onNavTap: _handleRolePlayNavTap,
      body: SafeArea(
        child: _isSpinning ? _buildSpinPhase() : _buildSelectionPhase(),
      ),
    );
  }

  void _handleRolePlayNavTap(RolePlayNavTab tab) {
    if (tab == RolePlayNavTab.home) {
      Navigator.of(context).popUntil((route) => route.isFirst);
      return;
    }
    if (tab == RolePlayNavTab.create) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const RolePlayRoomScreen()),
      );
      return;
    }
    if (tab == RolePlayNavTab.history) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const RolePlayHistoryScreen()),
      );
    }
  }

  // ── Spin phase ───────────────────────────────────────────────────────────────
  Widget _buildSpinPhase() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Drawing Your Story…',
          style: GoogleFonts.spaceGrotesk(
              fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white),
        ),
        const SizedBox(height: 48),
        _CasinoWheel(controller: _wheelCtrl),
        const SizedBox(height: 48),
        Text('🎰 Spinning the wheel of fate',
            style: GoogleFonts.inter(fontSize: 13, color: Colors.white54)),
      ],
    );
  }

  // ── Selection phase ──────────────────────────────────────────────────────────
  Widget _buildSelectionPhase() {
    return Column(
      children: [
        // Story revealed banner
        AnimatedBuilder(
          animation: _revealCtrl,
          builder: (_, child) => Opacity(
            opacity: _revealOpacity.value,
            child: Transform.scale(scale: _revealScale.value, child: child),
          ),
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFEB4B6E), Color(0xFFBF1B2C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: _kAccent.withOpacity(0.4),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Text(widget.storyEmoji, style: const TextStyle(fontSize: 44)),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Your Story',
                        style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white60,
                            letterSpacing: 1.2)),
                    Text(widget.storyTitle,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.3,
                        )),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Countdown bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Choose your character',
                      style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white70)),
                  Text('$_countdown s',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: _countdown > 10 ? Colors.white : _kAccent,
                      )),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: AnimatedBuilder(
                  animation: _countdownCtrl,
                  builder: (_, __) => LinearProgressIndicator(
                    value: 1 - _countdownCtrl.value,
                    backgroundColor: Colors.white12,
                    valueColor: AlwaysStoppedAnimation<Color>(
                        _countdown > 10 ? _kAccent : Colors.orange),
                    minHeight: 6,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Character grid
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.1,
            ),
            itemCount: _characters.length,
            itemBuilder: (_, i) => _CharacterCard(
              character: _characters[i],
              isSelected: _mySelection == i,
              isLocked: _lockedByOthers.contains(i),
              onTap: () => _selectCharacter(i),
            ),
          ),
        ),

        // Confirm button
        Padding(
          padding: const EdgeInsets.all(20),
          child: GestureDetector(
            onTap: _mySelection != null ? _confirmAndStart : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                gradient: _mySelection != null
                    ? const LinearGradient(
                        colors: [Color(0xFFEB4B6E), Color(0xFFBF1B2C)])
                    : null,
                color: _mySelection == null ? const Color(0xFF2A2A3E) : null,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Center(
                child: Text(
                  _mySelection != null
                      ? '✅ Lock In — ${_characters[_mySelection!].name}'
                      : '👆 Select a Character',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _mySelection != null ? Colors.white : Colors.white38,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Casino Wheel ───────────────────────────────────────────────────────────────
class _CasinoWheel extends StatelessWidget {
  final AnimationController controller;
  const _CasinoWheel({required this.controller});

  @override
  Widget build(BuildContext context) {
    final rotation = Tween<double>(begin: 0, end: math.pi * 14).animate(
      CurvedAnimation(parent: controller, curve: Curves.easeInOutCubic),
    );
    return AnimatedBuilder(
      animation: rotation,
      builder: (_, __) => Transform.rotate(
        angle: rotation.value,
        child: Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const SweepGradient(colors: [
              Color(0xFFEB4B6E),
              Color(0xFFFF8E53),
              Color(0xFFFFBE0B),
              Color(0xFF43e97b),
              Color(0xFF667eea),
              Color(0xFFa18cd1),
              Color(0xFFEB4B6E),
            ]),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFEB4B6E).withOpacity(0.5),
                blurRadius: 40,
                spreadRadius: 10,
              ),
            ],
          ),
          child: Center(
            child: Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                  shape: BoxShape.circle, color: Color(0xFF0F0F1A)),
              child: const Center(
                  child: Text('🎭', style: TextStyle(fontSize: 36))),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Character Card ─────────────────────────────────────────────────────────────
class _CharacterCard extends StatefulWidget {
  final RolePlayCharacter character;
  final bool isSelected, isLocked;
  final VoidCallback onTap;
  const _CharacterCard({
    required this.character,
    required this.isSelected,
    required this.isLocked,
    required this.onTap,
  });

  @override
  State<_CharacterCard> createState() => _CharacterCardState();
}

class _CharacterCardState extends State<_CharacterCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _lockCtrl;
  late Animation<double> _lockScale;

  @override
  void initState() {
    super.initState();
    _lockCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _lockScale = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _lockCtrl, curve: Curves.elasticOut));
  }

  @override
  void didUpdateWidget(_CharacterCard old) {
    super.didUpdateWidget(old);
    if (widget.isLocked && !old.isLocked) _lockCtrl.forward(from: 0);
  }

  @override
  void dispose() {
    _lockCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.character;
    return GestureDetector(
      onTap: widget.isLocked ? null : widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: widget.isLocked
              ? const Color(0xFF1A1A2E)
              : widget.isSelected
                  ? const Color(0xFF1A0A0E)
                  : const Color(0xFF16213E),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: widget.isSelected
                ? _kAccent
                : widget.isLocked
                    ? Colors.white12
                    : Colors.white10,
            width: widget.isSelected ? 2 : 1,
          ),
          boxShadow: widget.isSelected
              ? [
                  BoxShadow(
                    color: _kAccent.withOpacity(0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  )
                ]
              : [],
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: c.color.withOpacity(widget.isLocked ? 0.08 : 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                        child: Text(c.emoji,
                            style: const TextStyle(fontSize: 24))),
                  ),
                  const SizedBox(height: 8),
                  Text(c.name,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: widget.isLocked ? Colors.white24 : Colors.white,
                      )),
                  const SizedBox(height: 2),
                  Text(c.role,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color:
                            widget.isLocked ? Colors.white12 : Colors.white54,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            // Locked overlay
            if (widget.isLocked)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    color: Colors.black54,
                  ),
                  child: AnimatedBuilder(
                    animation: _lockScale,
                    builder: (_, __) => Transform.scale(
                      scale: _lockScale.value,
                      child: const Center(
                          child: Text('🔒', style: TextStyle(fontSize: 28))),
                    ),
                  ),
                ),
              ),
            // Selected checkmark
            if (widget.isSelected && !widget.isLocked)
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: const BoxDecoration(
                      color: _kAccent, shape: BoxShape.circle),
                  child: const Icon(Icons.check, color: Colors.white, size: 14),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
