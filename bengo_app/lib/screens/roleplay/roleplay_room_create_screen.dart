import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/api_service.dart';
import 'roleplay_models.dart';
import 'roleplay_gameplay_screen.dart';

const _kAccent = Color(0xFFC41230);
const _kInk    = Color(0xFF1B1B1D);

// ══════════════════════════════════════════════════════════════════════════════
/// Entry point — covers Create + Join
// ══════════════════════════════════════════════════════════════════════════════
class RolePlayRoomScreen extends StatefulWidget {
  const RolePlayRoomScreen({super.key});
  @override
  State<RolePlayRoomScreen> createState() => _RolePlayRoomScreenState();
}

class _RolePlayRoomScreenState extends State<RolePlayRoomScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  final _codeCtrl = TextEditingController();
  String _visibility = 'public';
  int _maxPlayers = 4;
  bool _creating = false;
  bool _joining  = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _createRoom() async {
    setState(() { _creating = true; _error = null; });
    try {
      final room = RolePlayRoom.fromJson(
        await ApiService.instance.createRolePlayRoom(
          visibility: _visibility,
          maxPlayers: _maxPlayers,
        ),
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => RolePlayLobbyScreen(room: room, isCreator: true)),
      );
    } catch (e) {
      setState(() => _error = 'Could not create room. Try again.');
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  Future<void> _joinRoom() async {
    final code = _codeCtrl.text.trim().toUpperCase();
    if (code.length < 6) {
      setState(() => _error = 'Enter the 6-character room code.');
      return;
    }
    setState(() { _joining = true; _error = null; });
    try {
      final room = RolePlayRoom.fromJson(
        await ApiService.instance.joinRolePlayRoom(code),
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => RolePlayLobbyScreen(room: room, isCreator: false)),
      );
    } catch (e) {
      setState(() => _error = 'Room not found or already started.');
    } finally {
      if (mounted) setState(() => _joining = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _kInk, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('🎭 RolePlay',
            style: GoogleFonts.spaceGrotesk(
                fontSize: 18, fontWeight: FontWeight.w800, color: _kInk)),
        bottom: TabBar(
          controller: _tabs,
          labelColor: _kAccent,
          unselectedLabelColor: Colors.grey,
          indicatorColor: _kAccent,
          labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13),
          tabs: const [Tab(text: '＋ Create Room'), Tab(text: '🔑 Join Room')],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [_buildCreate(), _buildJoin()],
      ),
    );
  }

  Widget _buildCreate() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionLabel('VISIBILITY'),
          const SizedBox(height: 10),
          Row(
            children: [
              for (final v in ['public', 'friends', 'private'])
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _VisibilityChip(
                      label: v[0].toUpperCase() + v.substring(1),
                      icon: v == 'public' ? '🌍' : v == 'friends' ? '👫' : '🔒',
                      selected: _visibility == v,
                      onTap: () => setState(() => _visibility = v),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),
          _SectionLabel('MAX PLAYERS  ($_maxPlayers)'),
          Slider(
            value: _maxPlayers.toDouble(),
            min: 2, max: 8, divisions: 6,
            activeColor: _kAccent,
            inactiveColor: _kAccent.withOpacity(0.15),
            label: '$_maxPlayers',
            onChanged: (v) => setState(() => _maxPlayers = v.toInt()),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('2', style: GoogleFonts.inter(fontSize: 11, color: Colors.grey)),
              Text('8', style: GoogleFonts.inter(fontSize: 11, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF5F7),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _kAccent.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                const Text('🎰', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'The story is picked randomly after all players join — the spin wheel decides!',
                    style: GoogleFonts.inter(fontSize: 12, color: _kAccent, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          if (_error != null) ...[
            _ErrorBanner(_error!),
            const SizedBox(height: 14),
          ],
          _PrimaryButton(
            label: _creating ? 'Creating…' : '🚀 Create Room',
            loading: _creating,
            onTap: _creating ? null : _createRoom,
          ),
        ],
      ),
    );
  }

  Widget _buildJoin() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionLabel('ROOM CODE'),
          const SizedBox(height: 10),
          TextField(
            controller: _codeCtrl,
            textCapitalization: TextCapitalization.characters,
            style: GoogleFonts.spaceGrotesk(
                fontSize: 28, fontWeight: FontWeight.w800,
                letterSpacing: 8, color: _kInk),
            maxLength: 6,
            decoration: InputDecoration(
              hintText: 'ABC123',
              hintStyle: GoogleFonts.spaceGrotesk(
                  fontSize: 28, fontWeight: FontWeight.w800,
                  letterSpacing: 8, color: Colors.grey.shade300),
              counterText: '',
              filled: true,
              fillColor: const Color(0xFFF8F8F8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: _kAccent, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            ),
          ),
          const SizedBox(height: 28),
          if (_error != null) ...[
            _ErrorBanner(_error!),
            const SizedBox(height: 14),
          ],
          _PrimaryButton(
            label: _joining ? 'Joining…' : '🔑 Join Room',
            loading: _joining,
            onTap: _joining ? null : _joinRoom,
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
/// Lobby — shows members, room code, spin button for creator
// ══════════════════════════════════════════════════════════════════════════════
class RolePlayLobbyScreen extends StatefulWidget {
  final RolePlayRoom room;
  final bool isCreator;
  const RolePlayLobbyScreen({super.key, required this.room, required this.isCreator});
  @override
  State<RolePlayLobbyScreen> createState() => _RolePlayLobbyScreenState();
}

class _RolePlayLobbyScreenState extends State<RolePlayLobbyScreen> {
  late RolePlayRoom _room;
  Timer? _pollTimer;
  bool _spinning = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _room = widget.room;
    // Poll every 3 seconds to get updated member list
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) => _poll());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _poll() async {
    try {
      final updated = RolePlayRoom.fromJson(
        await ApiService.instance.getRolePlayRoom(_room.roomCode),
      );
      if (!mounted) return;
      setState(() => _room = updated);
      // If story was assigned (someone else triggered spin), move to spin reveal
      if (updated.status == 'active' && updated.storyTitle != null) {
        _pollTimer?.cancel();
        _goToSpinReveal(updated.storyTitle!, updated.storyEmoji ?? '🎭');
      }
    } catch (_) {}
  }

  Future<void> _spin() async {
    setState(() { _spinning = true; _error = null; });
    try {
      final data = await ApiService.instance.spinRolePlayRoom(_room.roomCode);
      if (!mounted) return;
      _pollTimer?.cancel();
      _goToSpinReveal(
        data['story_title'] as String? ?? 'Story',
        data['story_emoji']  as String? ?? '🎭',
      );
    } catch (e) {
      setState(() {
        _spinning = false;
        _error = 'Could not spin. Need at least 2 players.';
      });
    }
  }

  void _goToSpinReveal(String title, String emoji) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => RolePlaySpinRevealScreen(
          room: _room,
          storyTitle: title,
          storyEmoji: emoji,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final members = _room.members;
    final canSpin  = widget.isCreator && members.length >= 2 && !_spinning;

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F1A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white54),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Lobby', style: GoogleFonts.spaceGrotesk(
            color: Colors.white, fontWeight: FontWeight.w800)),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Room code card
            Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1B0A0E), Color(0xFF3D0A14)],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: _kAccent.withOpacity(0.4)),
              ),
              child: Column(
                children: [
                  Text('ROOM CODE', style: GoogleFonts.inter(
                      fontSize: 11, letterSpacing: 2,
                      color: Colors.white38, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: _room.roomCode));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Room code copied!')),
                      );
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(_room.roomCode,
                            style: GoogleFonts.spaceGrotesk(
                                fontSize: 40, fontWeight: FontWeight.w900,
                                letterSpacing: 10, color: Colors.white)),
                        const SizedBox(width: 8),
                        const Icon(Icons.copy_rounded, color: Colors.white38, size: 18),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text('Share this code with friends to join',
                      style: GoogleFonts.inter(fontSize: 12, color: Colors.white38)),
                ],
              ),
            ),

            // Members
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  Text('Players  (${members.length}/${_room.maxPlayers})',
                      style: GoogleFonts.inter(
                          fontSize: 13, fontWeight: FontWeight.w700,
                          color: Colors.white60)),
                  const SizedBox(height: 12),
                  for (final m in members)
                    Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A2E),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40, height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _kAccent.withOpacity(0.15),
                              border: Border.all(
                                  color: m.isCreator ? _kAccent : Colors.white12),
                            ),
                            child: Center(
                              child: Text(m.username.isNotEmpty
                                  ? m.username[0].toUpperCase()
                                  : '?',
                                  style: GoogleFonts.spaceGrotesk(
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(m.username,
                                style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white)),
                          ),
                          if (m.isCreator)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: _kAccent.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text('HOST',
                                  style: GoogleFonts.inter(
                                      fontSize: 10, fontWeight: FontWeight.w800,
                                      color: _kAccent)),
                            ),
                        ],
                      ),
                    ),
                  if (members.length < 2)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        '⏳ Waiting for at least 1 more player…',
                        style: GoogleFonts.inter(fontSize: 12, color: Colors.white38),
                      ),
                    ),
                ],
              ),
            ),

            // Spin / error / waiting
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  if (_error != null) ...[
                    _ErrorBanner(_error!),
                    const SizedBox(height: 12),
                  ],
                  if (widget.isCreator)
                    _PrimaryButton(
                      label: _spinning ? 'Spinning…' : '🎰 Spin to Reveal Story!',
                      loading: _spinning,
                      onTap: canSpin ? _spin : null,
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A2E),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: 16, height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2, color: _kAccent),
                          ),
                          const SizedBox(width: 12),
                          Text('Waiting for host to spin…',
                              style: GoogleFonts.inter(
                                  fontSize: 13, color: Colors.white60,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
/// Spin reveal — improved animation → character select
// ══════════════════════════════════════════════════════════════════════════════
class RolePlaySpinRevealScreen extends StatefulWidget {
  final RolePlayRoom room;
  final String storyTitle, storyEmoji;
  const RolePlaySpinRevealScreen({
    super.key, required this.room,
    required this.storyTitle, required this.storyEmoji,
  });
  @override
  State<RolePlaySpinRevealScreen> createState() => _RolePlaySpinRevealScreenState();
}

class _RolePlaySpinRevealScreenState extends State<RolePlaySpinRevealScreen>
    with TickerProviderStateMixin {

  late AnimationController _wheelCtrl;
  late AnimationController _revealCtrl;
  late AnimationController _particleCtrl;
  late Animation<double> _wheelSpin;
  late Animation<double> _revealScale;
  late Animation<double> _revealOpacity;

  bool _revealed = false;

  @override
  void initState() {
    super.initState();

    // Wheel spin — fast then ease to stop
    _wheelCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 4));
    _wheelSpin = Tween<double>(begin: 0, end: math.pi * 20).animate(
      CurvedAnimation(parent: _wheelCtrl, curve: Curves.easeOutExpo),
    );

    // Story reveal pop
    _revealCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _revealScale   = Tween<double>(begin: 0.4, end: 1.0).animate(
        CurvedAnimation(parent: _revealCtrl, curve: Curves.elasticOut));
    _revealOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _revealCtrl, curve: Curves.easeOut));

    // Particle burst
    _particleCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 2));

    _wheelCtrl.forward();
    _wheelCtrl.addStatusListener((s) {
      if (s == AnimationStatus.completed && mounted) {
        setState(() => _revealed = true);
        _revealCtrl.forward();
        _particleCtrl.forward();
        Future.delayed(const Duration(seconds: 3), _goToCharSelect);
      }
    });
  }

  @override
  void dispose() {
    _wheelCtrl.dispose();
    _revealCtrl.dispose();
    _particleCtrl.dispose();
    super.dispose();
  }

  void _goToCharSelect() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => RolePlayCharacterSelectInline(
          room: widget.room,
          storyTitle: widget.storyTitle,
          storyEmoji: widget.storyEmoji,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      body: Stack(
        children: [
          // Particle burst
          if (_revealed)
            AnimatedBuilder(
              animation: _particleCtrl,
              builder: (_, __) => CustomPaint(
                painter: _ParticlePainter(_particleCtrl.value),
                size: MediaQuery.of(context).size,
              ),
            ),

          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (!_revealed) ...[
                  Text('Spinning…',
                      style: GoogleFonts.spaceGrotesk(
                          fontSize: 20, fontWeight: FontWeight.w800,
                          color: Colors.white70)),
                  const SizedBox(height: 48),
                  _ImprovedWheel(animation: _wheelSpin),
                  const SizedBox(height: 48),
                  Text('Who will you be today? 🎭',
                      style: GoogleFonts.inter(
                          fontSize: 14, color: Colors.white38)),
                ] else ...[
                  AnimatedBuilder(
                    animation: _revealCtrl,
                    builder: (_, child) => Opacity(
                      opacity: _revealOpacity.value,
                      child: Transform.scale(
                          scale: _revealScale.value, child: child),
                    ),
                    child: Column(
                      children: [
                        Text(widget.storyEmoji,
                            style: const TextStyle(fontSize: 80)),
                        const SizedBox(height: 16),
                        Text(widget.storyTitle,
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 32, fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                                colors: [Color(0xFFEB4B6E), Color(0xFFBF1B2C)]),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text('Your Story!',
                              style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white)),
                        ),
                        const SizedBox(height: 24),
                        Text('Choosing characters in 3 seconds…',
                            style: GoogleFonts.inter(
                                fontSize: 13, color: Colors.white38)),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class RolePlayCharacterSelectInline extends StatefulWidget {
  final RolePlayRoom room;
  final String storyTitle, storyEmoji;
  const RolePlayCharacterSelectInline({
    super.key, required this.room,
    required this.storyTitle, required this.storyEmoji,
  });
  @override
  State<RolePlayCharacterSelectInline> createState() =>
      _RolePlayCharacterSelectInlineState();
}

class _RolePlayCharacterSelectInlineState
    extends State<RolePlayCharacterSelectInline> {
  List<RolePlayCharacter> _characters = [];
  int? _mySelection;
  bool _loading = true;
  bool _locking = false;
  bool _lockedIn = false;
  String? _error;
  int _countdown = 60; // 1-minute pick countdown
  Timer? _timer;
  Timer? _syncTimer;
  RolePlayRoom? _currentRoomState;

  @override
  void initState() {
    super.initState();
    _currentRoomState = widget.room;
    _loadCharacters();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _syncTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadCharacters() async {
    try {
      final story = await ApiService.instance.getRolePlayStory(
        widget.room.storyId!,
      );
      final chars = (story['characters'] as List<dynamic>? ?? [])
          .map((c) => RolePlayCharacter.fromJson(c as Map<String, dynamic>))
          .toList();
      if (!mounted) return;
      setState(() { _characters = chars; _loading = false; });
      _startCountdown();
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = 'Could not load characters.'; _loading = false; });
    }
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() {
        if (_countdown > 0) _countdown--;
      });
      if (_countdown <= 0) {
        t.cancel();
        if (!_lockedIn) {
          if (_mySelection == null && _characters.isNotEmpty) {
            // Find first unselected character
            for (int i = 0; i < _characters.length; i++) {
              if (!_isCharacterTakenByOthers(i)) {
                _mySelection = i;
                break;
              }
            }
            if (_mySelection == null) _mySelection = 0;
          }
          _lockIn();
        }
      }
    });
  }

  bool _isCharacterTakenByOthers(int index) {
    if (_currentRoomState == null) return false;
    final charId = _characters[index].id;
    return _currentRoomState!.members.any((m) => m.characterId == charId && !m.isCreator);
  }

  Future<void> _lockIn() async {
    if (_mySelection == null) return;
    setState(() { _locking = true; _error = null; });
    try {
      final myChar = _characters[_mySelection!];
      await ApiService.instance.selectRolePlayCharacter(
        widget.room.roomCode,
        myChar.id,
      );
      if (!mounted) return;
      setState(() {
        _locking = false;
        _lockedIn = true;
      });
      _startSyncPolling();
    } catch (e) {
      setState(() {
        _locking = false;
        _error = 'Character already taken — pick another.';
      });
    }
  }

  void _startSyncPolling() {
    _syncTimer = Timer.periodic(const Duration(seconds: 2), (t) async {
      if (!mounted) { t.cancel(); return; }
      try {
        final roomState = RolePlayRoom.fromJson(
          await ApiService.instance.getRolePlayRoom(widget.room.roomCode),
        );
        if (!mounted) return;
        setState(() => _currentRoomState = roomState);

        // Check if all players have selected their character
        final allSelected = roomState.members.every((m) => m.characterId != null);
        if (allSelected || _countdown <= 0) {
          t.cancel();
          _timer?.cancel();
          _proceedToReveal(roomState);
        }
      } catch (_) {}
    });
  }

  Future<void> _proceedToReveal(RolePlayRoom finalRoom) async {
    // Get full dialogues list
    final story = await ApiService.instance.getRolePlayStory(widget.room.storyId!);
    final dialogues = (story['dialogues'] as List<dynamic>? ?? [])
        .map((d) => RolePlayDialogue.fromJson(d as Map<String, dynamic>))
        .toList();

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => RolePlayCastRevealScreen(
          roomCode: widget.room.roomCode,
          storyTitle: widget.storyTitle,
          storyEmoji: widget.storyEmoji,
          myCharacter: _characters[_mySelection ?? 0],
          dialogues: dialogues,
          room: finalRoom,
          characters: _characters,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F0F1A),
        body: Center(child: CircularProgressIndicator(color: _kAccent)),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F1A),
        elevation: 0,
        title: Text(_lockedIn ? 'Waiting for Others…' : 'Choose Your Character',
            style: GoogleFonts.spaceGrotesk(
                color: Colors.white, fontWeight: FontWeight.w800)),
        actions: [
          if (!_lockedIn)
            Center(
              child: Container(
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _countdown <= 15 ? _kAccent : const Color(0xFF2A2A3E),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('$_countdown s',
                    style: GoogleFonts.spaceGrotesk(
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        fontSize: 14)),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Story banner
          Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1A0A0E), Color(0xFF3D0A14)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Text(widget.storyEmoji, style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 12),
                Text(widget.storyTitle,
                    style: GoogleFonts.spaceGrotesk(
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        fontSize: 16)),
              ],
            ),
          ),

          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.1,
              ),
              itemCount: _characters.length,
              itemBuilder: (_, i) {
                final c = _characters[i];
                final selected = _mySelection == i;
                
                // Check if taken by other users
                String? takenBy;
                if (_currentRoomState != null) {
                  final occupant = _currentRoomState!.members.firstWhere(
                    (m) => m.characterId == c.id,
                    orElse: () => const RolePlayMember(id: 0, userId: 0, username: '', avatarId: '', isCreator: false, score: 0.0),
                  );
                  if (occupant.userId != 0) {
                    takenBy = occupant.username;
                  }
                }

                final isTaken = takenBy != null && !_lockedIn;

                return GestureDetector(
                  onTap: (_lockedIn || isTaken) ? null : () => setState(() => _mySelection = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: selected
                          ? const Color(0xFF1A0A0E)
                          : isTaken
                              ? const Color(0xFF121220).withOpacity(0.5)
                              : const Color(0xFF16213E),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: selected ? _kAccent : Colors.white10,
                        width: selected ? 2 : 1,
                      ),
                      boxShadow: selected
                          ? [BoxShadow(
                              color: _kAccent.withOpacity(0.3),
                              blurRadius: 16, offset: const Offset(0, 4))]
                          : [],
                    ),
                    child: Stack(
                      children: [
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 52, height: 52,
                              decoration: BoxDecoration(
                                color: c.color.withOpacity(isTaken ? 0.05 : 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(c.emoji, style: const TextStyle(fontSize: 26)),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(c.name,
                                style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w700,
                                    color: isTaken ? Colors.white30 : Colors.white)),
                            if (takenBy != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 4, left: 8, right: 8),
                                child: Text(
                                  'Taken by $takenBy',
                                  style: GoogleFonts.inter(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.orange.shade300),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              )
                            else if (selected)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: _kAccent,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text('Selected',
                                      style: GoogleFonts.inter(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white)),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                if (_error != null) ...[
                  _ErrorBanner(_error!),
                  const SizedBox(height: 12),
                ],
                if (_lockedIn)
                  Container(
                    padding: const EdgeInsets.all(16),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E2035),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        const SizedBox(
                          width: 24, height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2.5, color: _kAccent),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Character Locked! Waiting for all players to pick…',
                          style: GoogleFonts.inter(
                              fontSize: 13, color: Colors.white70,
                              fontWeight: FontWeight.w700),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                else
                  _PrimaryButton(
                    label: _locking
                        ? 'Locking in…'
                        : _mySelection != null
                            ? '✅ Confirm — Play as ${_characters[_mySelection!].name}'
                            : '👆 Select a character',
                    loading: _locking,
                    onTap: (_mySelection != null && !_locking)
                        ? _lockIn
                        : null,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
/// Cast Reveal Transition Screen
// ══════════════════════════════════════════════════════════════════════════════
class RolePlayCastRevealScreen extends StatefulWidget {
  final String roomCode, storyTitle, storyEmoji;
  final RolePlayCharacter myCharacter;
  final List<RolePlayDialogue> dialogues;
  final RolePlayRoom room;
  final List<RolePlayCharacter> characters;

  const RolePlayCastRevealScreen({
    super.key,
    required this.roomCode,
    required this.storyTitle,
    required this.storyEmoji,
    required this.myCharacter,
    required this.dialogues,
    required this.room,
    required this.characters,
  });

  @override
  State<RolePlayCastRevealScreen> createState() => _RolePlayCastRevealScreenState();
}

class _RolePlayCastRevealScreenState extends State<RolePlayCastRevealScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _revealCtrl;

  @override
  void initState() {
    super.initState();
    _revealCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 4));
    _revealCtrl.forward();
    _revealCtrl.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => RolePlayGameplayScreen(
              storyTitle:  widget.storyTitle,
              storyEmoji:  widget.storyEmoji,
              roomCode:    widget.roomCode,
              myCharacter: widget.myCharacter,
              dialogues:   widget.dialogues,
            ),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _revealCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final membersWithCharacters = widget.room.members.where((m) => m.characterId != null).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('🎬 Cast Revealed!',
                  style: GoogleFonts.spaceGrotesk(
                      fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white)),
              const SizedBox(height: 8),
              Text('Preparing your conversation story...',
                  style: GoogleFonts.inter(fontSize: 13, color: Colors.white38)),
              const SizedBox(height: 36),

              for (int i = 0; i < membersWithCharacters.length; i++) ...[
                AnimatedBuilder(
                  animation: _revealCtrl,
                  builder: (_, child) {
                    final delay = i * 0.15;
                    final progress = (_revealCtrl.value - delay).clamp(0.0, 1.0);
                    final scale = Curves.elasticOut.transform(progress);
                    return Opacity(
                      opacity: progress.clamp(0.0, 1.0),
                      child: Transform.scale(scale: scale, child: child),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E2035),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Row(
                      children: [
                        // Player username first
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(membersWithCharacters[i].username,
                                  style: GoogleFonts.inter(
                                      fontSize: 14, fontWeight: FontWeight.w800,
                                      color: Colors.white)),
                              const SizedBox(height: 2),
                              Text('Player',
                                  style: GoogleFonts.inter(
                                      fontSize: 11, color: Colors.white30)),
                            ],
                          ),
                        ),

                        // Cast pointer
                        const Text('👉', style: TextStyle(fontSize: 18)),
                        const SizedBox(width: 14),

                        // Character Role
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2D0A12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _kAccent.withOpacity(0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(membersWithCharacters[i].characterEmoji ?? '👤',
                                  style: const TextStyle(fontSize: 18)),
                              const SizedBox(width: 8),
                              Text(
                                membersWithCharacters[i].characterName ?? 'Role',
                                style: GoogleFonts.spaceGrotesk(
                                    fontSize: 13, fontWeight: FontWeight.w800,
                                    color: _kAccent),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 48),
              const SizedBox(
                width: 32, height: 32,
                child: CircularProgressIndicator(color: _kAccent, strokeWidth: 3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


// ── Improved Wheel Widget ───────────────────────────────────────────────────────
class _ImprovedWheel extends StatelessWidget {
  final Animation<double> animation;
  const _ImprovedWheel({required this.animation});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (_, __) => Transform.rotate(
        angle: animation.value,
        child: CustomPaint(
          size: const Size(220, 220),
          painter: _WheelPainter(),
          child: const SizedBox(
            width: 220, height: 220,
            child: Center(
              child: _WheelCenter(),
            ),
          ),
        ),
      ),
    );
  }
}

class _WheelCenter extends StatelessWidget {
  const _WheelCenter();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 70, height: 70,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFF0F0F1A),
        boxShadow: [
          BoxShadow(color: Colors.black45, blurRadius: 12),
        ],
      ),
      child: const Center(
        child: Text('🎭', style: TextStyle(fontSize: 32)),
      ),
    );
  }
}

class _WheelPainter extends CustomPainter {
  static const _colors = [
    Color(0xFFEB4B6E), Color(0xFFFF8E53), Color(0xFFFFBE0B),
    Color(0xFF43e97b), Color(0xFF667eea), Color(0xFFa18cd1),
    Color(0xFFfa709a), Color(0xFF4ECDC4),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final sweep  = 2 * math.pi / _colors.length;

    for (int i = 0; i < _colors.length; i++) {
      final paint = Paint()..color = _colors[i]..style = PaintingStyle.fill;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        i * sweep - math.pi / 2,
        sweep,
        true,
        paint,
      );
    }

    // Divider lines
    final linePaint = Paint()
      ..color = Colors.white.withOpacity(0.25)
      ..strokeWidth = 2;
    for (int i = 0; i < _colors.length; i++) {
      final angle = i * sweep - math.pi / 2;
      canvas.drawLine(
        center,
        Offset(
          center.dx + radius * math.cos(angle),
          center.dy + radius * math.sin(angle),
        ),
        linePaint,
      );
    }

    // Outer ring
    final ringPaint = Paint()
      ..color = Colors.white.withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    canvas.drawCircle(center, radius - 2, ringPaint);

    // Glow shadow
    final glowPaint = Paint()
      ..color = const Color(0xFFEB4B6E).withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 20);
    canvas.drawCircle(center, radius - 2, glowPaint);
  }

  @override
  bool shouldRepaint(_) => false;
}

// ── Particle burst after reveal ────────────────────────────────────────────────
class _ParticlePainter extends CustomPainter {
  final double progress;
  _ParticlePainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(99);
    final colors = [
      const Color(0xFFEB4B6E), const Color(0xFFFFBE0B),
      const Color(0xFF43e97b), const Color(0xFF667eea), const Color(0xFFfa709a),
    ];
    for (int i = 0; i < 60; i++) {
      final startX = size.width / 2;
      final startY = size.height / 2;
      final angle  = rng.nextDouble() * math.pi * 2;
      final dist   = rng.nextDouble() * size.width * 0.5 * progress;
      final x      = startX + dist * math.cos(angle);
      final y      = startY + dist * math.sin(angle) - 80 * progress;
      final opacity = (1 - progress).clamp(0.0, 1.0);
      final paint  = Paint()
        ..color = colors[i % colors.length].withOpacity(opacity)
        ..style  = PaintingStyle.fill;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(x, y), width: 7, height: 10),
          const Radius.circular(2),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => old.progress != progress;
}

// ── Shared small widgets ───────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: GoogleFonts.inter(
            fontSize: 10, fontWeight: FontWeight.w700,
            color: Colors.grey, letterSpacing: 1.2));
  }
}

class _VisibilityChip extends StatelessWidget {
  final String label, icon;
  final bool selected;
  final VoidCallback onTap;
  const _VisibilityChip({
    required this.label, required this.icon,
    required this.selected, required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFFF0F2) : const Color(0xFFF8F8F8),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? _kAccent : Colors.grey.shade200,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Text(icon, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 4),
            Text(label,
                style: GoogleFonts.inter(
                    fontSize: 11, fontWeight: FontWeight.w700,
                    color: selected ? _kAccent : _kInk)),
          ],
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback? onTap;
  const _PrimaryButton({required this.label, this.loading = false, this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: onTap != null
              ? const LinearGradient(
                  colors: [Color(0xFFEB4B6E), Color(0xFFBF1B2C)])
              : null,
          color: onTap == null ? Colors.grey.shade200 : null,
          borderRadius: BorderRadius.circular(18),
          boxShadow: onTap != null
              ? [BoxShadow(
                  color: _kAccent.withOpacity(0.3),
                  blurRadius: 16, offset: const Offset(0, 6))]
              : [],
        ),
        child: Center(
          child: loading
              ? const SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.5, color: Colors.white))
              : Text(label,
                  style: GoogleFonts.inter(
                      fontSize: 15, fontWeight: FontWeight.w700,
                      color: onTap != null ? Colors.white : Colors.grey)),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner(this.message);
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFCA5A5)),
      ),
      child: Row(
        children: [
          const Text('⚠️'),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message,
                style: GoogleFonts.inter(
                    fontSize: 12, fontWeight: FontWeight.w600,
                    color: const Color(0xFF991B1B))),
          ),
        ],
      ),
    );
  }
}
