import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/api_service.dart';
import '../../widgets/bengo_header.dart';
import 'roleplay_room_create_screen.dart';
import 'roleplay_history_screen.dart';
import 'roleplay_models.dart';

const _kAccent = Color(0xFFC41230);
const _kInk    = Color(0xFF1B1B1D);
const _kMuted  = Color(0xFF8A8A8F);

class RolePlayHomeScreen extends StatefulWidget {
  const RolePlayHomeScreen({super.key});
  @override
  State<RolePlayHomeScreen> createState() => _RolePlayHomeScreenState();
}

class _RolePlayHomeScreenState extends State<RolePlayHomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  List<dynamic> _stories = [];
  List<dynamic> _publicRooms = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final stories = await ApiService.instance.getRolePlayStories();
      final rooms   = await ApiService.instance.getRolePlayRooms(visibility: 'public');
      if (!mounted) return;
      setState(() {
        _stories = stories;
        _publicRooms = rooms;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load RolePlay data.';
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FD),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          color: _kAccent,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
            slivers: [
              const SliverToBoxAdapter(child: BenGoHeader()),
              SliverToBoxAdapter(child: _buildHero()),
              SliverToBoxAdapter(child: _buildQuickActions()),

              if (_loading)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(48.0),
                    child: Center(child: CircularProgressIndicator(color: _kAccent)),
                  ),
                )
              else if (_error != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Center(
                      child: Text(_error!, style: GoogleFonts.inter(color: _kAccent, fontWeight: FontWeight.w600)),
                    ),
                  ),
                )
              else ...[
                // Featured Stories
                SliverToBoxAdapter(child: _buildSectionLabel('FEATURED STORIES')),
                SliverToBoxAdapter(child: _buildStoriesCarousel()),

                // Public Rooms
                SliverToBoxAdapter(child: _buildSectionLabel('PUBLIC ROOMS')),
                SliverToBoxAdapter(child: _buildPublicRooms()),

                // Friends / Active Users
                SliverToBoxAdapter(child: _buildSectionLabel('ONLINE PLAYERS')),
                SliverToBoxAdapter(child: _buildFriendsRow()),
              ],

              const SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHero() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1B1B1D), Color(0xFF8B0D21)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFC41230).withOpacity(0.35),
              blurRadius: 30,
              offset: const Offset(0, 12),
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
                    '🎭 RolePlay',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Practice Japanese by acting in\nreal conversations with real people.',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: Colors.white60,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  AnimatedBuilder(
                    animation: _pulseAnim,
                    builder: (_, child) => Transform.scale(
                      scale: _pulseAnim.value,
                      alignment: Alignment.centerLeft,
                      child: child,
                    ),
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const RolePlayRoomScreen()),
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          '🎬 Start Now',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: _kAccent,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            _FloatingMask(),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    final actions = [
      ('🎬', 'Start\nRoom', () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const RolePlayRoomScreen()))),
      ('📜', 'Session\nHistory', () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const RolePlayHistoryScreen()))),
      ('👥', 'Friends', () {}),
      ('🌐', 'Refresh', _loadData),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        children: actions.map((a) {
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: _QuickActionButton(emoji: a.$1, label: a.$2, onTap: a.$3),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: _kMuted,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildStoriesCarousel() {
    if (_stories.isEmpty) {
      return Container(
        height: 120,
        margin: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFEDE9F4)),
        ),
        child: Center(
          child: Text('No featured stories available yet.',
              style: GoogleFonts.inter(color: _kMuted, fontSize: 13)),
        ),
      );
    }
    return SizedBox(
      height: 180,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
        scrollDirection: Axis.horizontal,
        itemCount: _stories.length,
        itemBuilder: (_, i) => _StoryCard(story: _stories[i]),
      ),
    );
  }

  Widget _buildPublicRooms() {
    if (_publicRooms.isEmpty) {
      return Container(
        margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFEDE9F4)),
        ),
        child: Center(
          child: Text('No public lobbies waiting. Create one above! 🎮',
              style: GoogleFonts.inter(color: _kMuted, fontSize: 13)),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Column(
        children: _publicRooms.map((r) => _RoomCard(room: r, onRefresh: _loadData)).toList(),
      ),
    );
  }

  Widget _buildFriendsRow() {
    // Generate dummy active users just to populate the online row beautifully
    final dummyPlayers = [
      ('Yuki',  '🦊', const Color(0xFFFF6B6B)),
      ('Hiro',  '🐺', const Color(0xFF667eea)),
      ('Aiko',  '🐱', const Color(0xFF43e97b)),
      ('Kenji', '🐼', const Color(0xFFa18cd1)),
    ];
    return SizedBox(
      height: 140, // Increased to 140 to completely prevent vertical text/button overflows
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
        scrollDirection: Axis.horizontal,
        itemCount: dummyPlayers.length,
        itemBuilder: (_, i) {
          final p = dummyPlayers[i];
          return _FriendChip(name: p.$1, emoji: p.$2, color: p.$3);
        },
      ),
    );
  }
}

class _FloatingMask extends StatefulWidget {
  @override
  State<_FloatingMask> createState() => _FloatingMaskState();
}

class _FloatingMaskState extends State<_FloatingMask>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        return Transform.translate(
          offset: Offset(0, (_ctrl.value - 0.5) * 10),
          child: Container(
            width: 82,
            height: 82,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Colors.white.withOpacity(0.15),
                  Colors.white.withOpacity(0.04),
                ],
              ),
              border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
            ),
            child: const Center(child: Text('🎭', style: TextStyle(fontSize: 44))),
          ),
        );
      },
    );
  }
}

class _QuickActionButton extends StatefulWidget {
  final String emoji, label;
  final VoidCallback onTap;
  const _QuickActionButton({required this.emoji, required this.label, required this.onTap});
  @override
  State<_QuickActionButton> createState() => _QuickActionButtonState();
}

class _QuickActionButtonState extends State<_QuickActionButton> {
  bool _pressed = false;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.93 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFEDE9F4), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(widget.emoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(height: 6),
              Text(
                widget.label,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: _kInk,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StoryCard extends StatefulWidget {
  final dynamic story;
  const _StoryCard({required this.story});
  @override
  State<_StoryCard> createState() => _StoryCardState();
}

class _StoryCardState extends State<_StoryCard> {
  bool _pressed = false;
  @override
  Widget build(BuildContext context) {
    final s = widget.story;
    final title      = s['title'] as String? ?? 'Untitled';
    final emoji      = s['cover_emoji'] as String? ?? '📖';
    final jlpt       = s['jlpt_level'] as String? ?? 'N5';
    final difficulty = s['difficulty'] as String? ?? 'easy';
    final chars      = s['character_count'] as int? ?? 2;

    // Derived consistent gradients
    final List<Color> gradient = [const Color(0xFFfa709a), const Color(0xFFfee140)];
    if (difficulty == 'easy') {
      gradient[0] = const Color(0xFFFF6B6B);
      gradient[1] = const Color(0xFFFF8E53);
    } else if (difficulty == 'medium') {
      gradient[0] = const Color(0xFF4ECDC4);
      gradient[1] = const Color(0xFF44A08D);
    }

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          width: 140,
          margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: gradient.first.withOpacity(0.35),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 30)),
              const Spacer(),
              Text(
                title,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.3,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  _MiniChip(jlpt),
                  const SizedBox(width: 4),
                  _MiniChip(difficulty[0].toUpperCase() + difficulty.substring(1)),
                ],
              ),
              const SizedBox(height: 4),
              Text('👤 $chars characters',
                  style: GoogleFonts.inter(fontSize: 10, color: Colors.white70)),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  final String label;
  const _MiniChip(this.label);
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.25),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
            fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white),
      ),
    );
  }
}

class _RoomCard extends StatefulWidget {
  final dynamic room;
  final VoidCallback onRefresh;
  const _RoomCard({required this.room, required this.onRefresh});
  @override
  State<_RoomCard> createState() => _RoomCardState();
}

class _RoomCardState extends State<_RoomCard> {
  bool _joining = false;

  Future<void> _join(BuildContext context, String code) async {
    setState(() => _joining = true);
    try {
      final res = await ApiService.instance.joinRolePlayRoom(code);
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => RolePlayLobbyScreen(
            room: RolePlayRoom.fromJson(res),
            isCreator: false,
          ),
        ),
      ).then((_) => widget.onRefresh());
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not join room.')),
      );
    } finally {
      if (mounted) setState(() => _joining = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.room;
    final code     = r['room_code'] as String? ?? '';
    final cur      = r['member_count'] as int? ?? 1;
    final max      = r['max_players'] as int? ?? 4;
    final title    = r['story_title'] as String? ?? 'Waiting for Story Spin';
    final isFull   = cur >= max;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEDE9F4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFFEB4B6E), Color(0xFFBF1B2C)]),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Center(child: Text('🎭', style: TextStyle(fontSize: 22))),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Room $code',
                  style: GoogleFonts.spaceGrotesk(fontSize: 14, fontWeight: FontWeight.w700, color: _kInk),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: GoogleFonts.inter(fontSize: 11, color: _kMuted),
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _RoomProgress(current: cur, max: max),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          if (_joining)
            const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5, color: _kAccent))
          else if (!isFull)
            GestureDetector(
              onTap: () => _join(context, code),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFFEB4B6E), Color(0xFFBF1B2C)]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('Join', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(12)),
              child: Text('Full', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: _kMuted)),
            ),
        ],
      ),
    );
  }
}

class _RoomProgress extends StatelessWidget {
  final int current, max;
  const _RoomProgress({required this.current, required this.max});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(max, (i) {
        return Container(
          width: 7, height: 7,
          margin: const EdgeInsets.only(right: 2.5),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: i < current ? _kAccent : const Color(0xFFE5E7EB),
          ),
        );
      }),
    );
  }
}

class _FriendChip extends StatelessWidget {
  final String name, emoji;
  final Color color;
  const _FriendChip({required this.name, required this.emoji, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 90,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEDE9F4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            children: [
              Container(
                width: 38, height: 38,
                decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle),
                child: Center(child: Text(emoji, style: const TextStyle(fontSize: 18))),
              ),
              Positioned(
                bottom: 0, right: 0,
                child: Container(
                  width: 9, height: 9,
                  decoration: const BoxDecoration(
                    color: Color(0xFF4CAF50),
                    shape: BoxShape.circle,
                    border: Border.fromBorderSide(BorderSide(color: Colors.white, width: 1.2)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(name, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: _kInk)),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(8)),
            child: Text('Online', style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w700, color: _kMuted)),
          ),
        ],
      ),
    );
  }
}
