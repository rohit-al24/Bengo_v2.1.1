import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/clan_service.dart';
import 'clan_theme.dart';

class ClanChatScreen extends StatefulWidget {
  final int clanId;
  const ClanChatScreen({super.key, required this.clanId});

  @override
  State<ClanChatScreen> createState() => _ClanChatScreenState();
}

class _ClanChatScreenState extends State<ClanChatScreen> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  List<Map<String, dynamic>> _events = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final events = await ClanService.instance.fetchClanChat(widget.clanId);
      if (mounted) {
        setState(() {
          // Show newest-first for reverse ListView
          _events = events.reversed.toList();
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    // Local optimistic insert (WebSocket integration pending)
    setState(() {
      _events.insert(0, {
        'event_type': 'chat',
        'description': text,
        'actor_username': 'You',
        'created_at': DateTime.now().toIso8601String(),
        'is_me': true,
      });
    });
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kClanBg,
      appBar: AppBar(
        backgroundColor: kClanSurface,
        elevation: 0,
        leading: const BackButton(color: kClanInk),
        title: Row(
          children: [
            Container(
              width: 34, height: 34,
              decoration: BoxDecoration(
                color: kClanAccentL,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: kClanBorder),
              ),
              child: const Icon(Icons.shield_rounded, color: kClanAccent, size: 18),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Clan Chat',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 15, fontWeight: FontWeight.w700, color: kClanInk)),
                Text('Activity & messages',
                  style: GoogleFonts.inter(fontSize: 11, color: kClanMuted)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: kClanMuted, size: 20),
            onPressed: _load,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: kClanBorder),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: kClanAccent))
                : _events.isEmpty
                    ? _EmptyChat()
                    : ListView.builder(
                        controller: _scroll,
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                        reverse: true,
                        itemCount: _events.length,
                        itemBuilder: (_, i) => _EventBubble(event: _events[i]),
                      ),
          ),

          // ── Input bar ──────────────────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: kClanSurface,
              border: Border(top: BorderSide(color: kClanBorder)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            padding: EdgeInsets.fromLTRB(
              12, 10, 12,
              MediaQuery.of(context).viewInsets.bottom + 10,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: kClanBg,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: kClanBorder),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.04),
                          blurRadius: 4, offset: const Offset(0, 1)),
                      ],
                    ),
                    child: TextField(
                      controller: _controller,
                      style: GoogleFonts.inter(fontSize: 14, color: kClanInk),
                      decoration: InputDecoration(
                        hintText: 'Message your clan…',
                        hintStyle: GoogleFonts.inter(color: kClanMuted, fontSize: 14),
                        border: InputBorder.none,
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                      textInputAction: TextInputAction.send,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _sendMessage,
                  child: Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: kClanAccent,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: kClanAccent.withOpacity(0.35),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyChat extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.chat_bubble_outline_rounded, size: 52, color: kClanMuted),
          const SizedBox(height: 14),
          Text('No activity yet',
            style: GoogleFonts.spaceGrotesk(fontSize: 17, fontWeight: FontWeight.w700, color: kClanMuted)),
          const SizedBox(height: 6),
          Text('Be the first to send a message!',
            style: GoogleFonts.inter(fontSize: 13, color: kClanMuted)),
        ],
      ),
    );
  }
}

// ── Message bubble ────────────────────────────────────────────────────────────

class _EventBubble extends StatelessWidget {
  final Map<String, dynamic> event;
  const _EventBubble({required this.event});

  @override
  Widget build(BuildContext context) {
    final isMe        = event['is_me'] == true;
    final isSystem    = event['event_type'] != 'chat';
    final actor       = event['actor_username'] as String?
                        ?? (event['actor'] as Map?)?['username'] as String?
                        ?? 'System';
    final description = event['description'] as String? ?? '';
    final time        = _formatTime(event['created_at'] as String?);

    // ── System event pill ─────────────────────────────────────────────────────
    if (isSystem) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: kClanBorder.withOpacity(0.5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: kClanBorder),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_eventIcon(event['event_type'] as String? ?? ''),
                  size: 12, color: kClanMuted),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(description,
                    style: GoogleFonts.inter(fontSize: 12, color: kClanMuted),
                    textAlign: TextAlign.center),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // ── Chat bubble ───────────────────────────────────────────────────────────
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Avatar for others
          if (!isMe) ...[
            CircleAvatar(
              radius: 14,
              backgroundColor: kClanAccentL,
              child: Text(
                actor.isNotEmpty ? actor[0].toUpperCase() : '?',
                style: GoogleFonts.inter(
                  fontSize: 11, fontWeight: FontWeight.w700, color: kClanAccent),
              ),
            ),
            const SizedBox(width: 8),
          ],

          Column(
            crossAxisAlignment:
                isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              if (!isMe)
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 2),
                  child: Text(actor,
                    style: GoogleFonts.inter(
                      fontSize: 11, color: kClanMuted, fontWeight: FontWeight.w600)),
                ),
              Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.65),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isMe ? kClanAccent : kClanSurface,
                  borderRadius: BorderRadius.only(
                    topLeft:     const Radius.circular(16),
                    topRight:    const Radius.circular(16),
                    bottomLeft:  Radius.circular(isMe ? 16 : 4),
                    bottomRight: Radius.circular(isMe ? 4 : 16),
                  ),
                  boxShadow: kRaisedShadow,
                  border: isMe ? null : Border.all(color: kClanBorder),
                ),
                child: Text(description,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: isMe ? Colors.white : kClanInk,
                    height: 1.4,
                  )),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 3, left: 4, right: 4),
                child: Text(time,
                  style: GoogleFonts.inter(fontSize: 10, color: kClanMuted)),
              ),
            ],
          ),

          if (isMe) const SizedBox(width: 4),
        ],
      ),
    );
  }

  IconData _eventIcon(String type) {
    switch (type) {
      case 'member_joined': return Icons.person_add_rounded;
      case 'member_left':   return Icons.exit_to_app_rounded;
      case 'member_kicked': return Icons.person_remove_rounded;
      case 'battle_win':    return Icons.emoji_events_rounded;
      case 'rush_started':  return Icons.bolt_rounded;
      case 'role_changed':  return Icons.manage_accounts_rounded;
      default:              return Icons.info_outline_rounded;
    }
  }

  String _formatTime(String? iso) {
    if (iso == null) return '';
    try {
      final dt = DateTime.parse(iso).toLocal();
      final h  = dt.hour.toString().padLeft(2, '0');
      final m  = dt.minute.toString().padLeft(2, '0');
      return '$h:$m';
    } catch (_) {
      return '';
    }
  }
}
