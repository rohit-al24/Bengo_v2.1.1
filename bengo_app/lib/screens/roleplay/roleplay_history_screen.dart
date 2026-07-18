import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/api_service.dart';
import '../../widgets/roleplay_shell.dart';
import 'roleplay_room_create_screen.dart';

const _kAccent = Color(0xFFC41230);
const _kInk = Color(0xFF1B1B1D);
const _kMuted = Color(0xFF8A8A8F);

class RolePlayHistoryScreen extends StatefulWidget {
  const RolePlayHistoryScreen({super.key});

  @override
  State<RolePlayHistoryScreen> createState() => _RolePlayHistoryScreenState();
}

class _RolePlayHistoryScreenState extends State<RolePlayHistoryScreen> {
  List<dynamic> _history = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.instance.getRolePlayHistory();
      if (!mounted) return;
      setState(() {
        _history = res;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load history.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return RolePlayShell(
      title: 'History',
      subtitle: 'Your past roleplay sessions',
      showBack: true,
      onBackTap: () => Navigator.pop(context),
      selectedTab: RolePlayNavTab.history,
      onNavTap: _handleRolePlayNavTap,
      body: _buildHistoryBody(),
    );
  }

  Widget _buildHistoryBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: _kAccent));
    }
    if (_error != null) {
      return Center(
        child: Text(_error!,
            style: GoogleFonts.inter(
                color: _kAccent, fontWeight: FontWeight.w600)),
      );
    }

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '📜 History',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  'Your past roleplay sessions.',
                  style: GoogleFonts.inter(fontSize: 14, color: Colors.white70),
                ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(child: _buildSummaryStats()),
        if (_history.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(48.0),
              child: Center(
                child: Text(
                  'No past sessions found. Start a room to play! 🎭',
                  style: GoogleFonts.inter(color: _kMuted, fontSize: 13),
                ),
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) => _HistoryCard(item: _history[i]),
                childCount: _history.length,
              ),
            ),
          ),
      ],
    );
  }

  void _handleRolePlayNavTap(RolePlayNavTab tab) {
    if (tab == RolePlayNavTab.history) return;
    if (tab == RolePlayNavTab.home) {
      Navigator.of(context).popUntil((route) => route.isFirst);
      return;
    }
    if (tab == RolePlayNavTab.create) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const RolePlayRoomScreen()),
      );
    }
  }

  Widget _buildSummaryStats() {
    if (_history.isEmpty) return const SizedBox.shrink();

    final totalXP = _history.fold<double>(0.0, (sum, h) {
      final score = (h['score'] as num?)?.toDouble() ?? 0.0;
      return sum + score;
    }).toInt();

    final avgAccuracy = _history.map((h) {
          return (h['accuracy'] as num?)?.toDouble() ?? 0.0;
        }).reduce((a, b) => a + b) /
        _history.length;

    final stats = [
      ('⚡', '$totalXP pts', 'Total Score'),
      ('🎯', '${(avgAccuracy * 100).toInt()}%', 'Avg Accuracy'),
      ('🎬', '${_history.length}', 'Sessions'),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Row(
        children: stats.map((s) {
          return Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4))
                ],
              ),
              child: Column(
                children: [
                  Text(s.$1, style: const TextStyle(fontSize: 20)),
                  const SizedBox(height: 6),
                  Text(s.$2,
                      style: GoogleFonts.spaceGrotesk(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: _kAccent)),
                  Text(s.$3,
                      style: GoogleFonts.inter(fontSize: 10, color: _kMuted)),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final dynamic item;
  const _HistoryCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final title = item['story_title'] as String? ?? 'Story';
    final emoji = item['story_emoji'] as String? ?? '🎭';
    final accuracy = (item['accuracy'] as num?)?.toDouble() ?? 0.0;
    final score = ((item['score'] as num?)?.toDouble() ?? 0.0).toInt();
    final correct = item['correct_count'] as int? ?? 0;
    final code = item['room_code'] as String? ?? '';
    final dateStr = item['created_at'] as String? ?? '';

    String displayDate = '';
    if (dateStr.isNotEmpty) {
      try {
        final date = DateTime.parse(dateStr);
        displayDate =
            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      } catch (_) {}
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEDE9F4)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 32)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.spaceGrotesk(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _kInk)),
                const SizedBox(height: 2),
                Text('Room $code • $displayDate',
                    style: GoogleFonts.inter(fontSize: 11, color: _kMuted)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${(accuracy * 100).toInt()}%',
                  style: GoogleFonts.spaceGrotesk(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: _kAccent)),
              Text('$correct correct • $score pts',
                  style: GoogleFonts.inter(fontSize: 10, color: _kMuted)),
            ],
          ),
        ],
      ),
    );
  }
}
