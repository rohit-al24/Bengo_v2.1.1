import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/api_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_decorations.dart';
import '../../widgets/bengo_app_bar.dart';
import 'team_game_screen.dart';

class TeamLobbyScreen extends StatefulWidget {
  const TeamLobbyScreen({super.key, required this.teamId});
  final int teamId;

  @override
  State<TeamLobbyScreen> createState() => _TeamLobbyScreenState();
}

class _TeamLobbyScreenState extends State<TeamLobbyScreen> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _team;
  List<dynamic> _friends = [];
  List<dynamic> _searchResults = [];
  String _query = '';
  bool _inviteLoading = false;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await ApiService.instance.getTeam(widget.teamId);
      final friends = await ApiService.instance.getFriends();
      setState(() {
        _team = result;
        _friends = friends;
        _searchResults = friends;
      });
    } catch (e) {
      setState(() {
        _error = 'Unable to load team lobby.';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _searchMembers(String value) async {
    setState(() {
      _query = value;
    });
    if (value.trim().isEmpty) {
      setState(() {
        _searchResults = _friends;
      });
      return;
    }
    try {
      final results = await ApiService.instance.searchUsers(value);
      setState(() {
        _searchResults = results;
      });
    } catch (_) {
      setState(() {
        _searchResults = _friends;
      });
    }
  }

  Future<void> _sendInvite(int userId) async {
    setState(() {
      _inviteLoading = true;
    });
    try {
      await ApiService.instance.sendTeamInvite(widget.teamId, userId);
      await _refresh();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Invite failed.')));
    } finally {
      setState(() {
        _inviteLoading = false;
      });
    }
  }

  Future<void> _startGame() async {
    if (_team == null) return;
    try {
      await ApiService.instance.startTeam(widget.teamId);
      if (!mounted) return;
      await Navigator.of(context).push(MaterialPageRoute(builder: (_) => TeamGameScreen(teamId: widget.teamId)));
      await _refresh();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Unable to start game.')));
    }
  }

  Future<void> _endGame() async {
    try {
      await ApiService.instance.endTeam(widget.teamId);
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Unable to end game.')));
    }
  }

  bool _isInvited(int userId) {
    final invites = _team?['invites'] as List<dynamic>? ?? [];
    return invites.any((invite) => invite['to_user'] == userId && invite['status'] == 'pending');
  }

  bool _isJoined(int userId) {
    final members = _team?['members'] as List<dynamic>? ?? [];
    return members.any((member) => member['user'] == userId);
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
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                        ? Text(_error!, style: GoogleFonts.inter(color: Colors.redAccent))
                        : _buildLobbyContent(),
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
      title: 'Team Lobby',
      actions: [
        if (_team != null && !(_team!['finished'] as bool))
          IconButton(
            icon: const Icon(Icons.close, color: AppColors.textSecondary),
            onPressed: _endGame,
          ),
      ],
    );
  }

  Widget _buildLobbyContent() {
    final team = _team!;
    final members = team['members'] as List<dynamic>? ?? [];
    final settings = (team['settings'] as Map?)?.cast<String, dynamic>() ?? {};
    final started = team['started'] as bool? ?? false;
    final finished = team['finished'] as bool? ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(team['name'] as String? ?? 'Team Room', style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white)),
        const SizedBox(height: 8),
        Text('${members.length} / ${team['max_members']}', style: GoogleFonts.inter(color: AppColors.textLight)),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          decoration: AppDecorations.skeuomorphicCard(color: const Color(0xFF12182E), radius: 22),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Team Settings', style: GoogleFonts.sourceCodePro(fontSize: 11, letterSpacing: 2, color: AppColors.accentCyan)),
              const SizedBox(height: 14),
              _buildSettingRow('Exam', settings['exam_level']?.toString() ?? 'n/a'),
              _buildSettingRow('Cooldown', '${settings['cooldown_seconds'] ?? 4}s'),
              _buildSettingRow('Timer', '${settings['question_timer'] ?? 15}s'),
              _buildSettingRow('Knife %', '${settings['knife_points_percentage'] ?? 25}%'),
              _buildSettingRow('Duration', '${(settings['duration_seconds'] ?? 300) ~/ 60} min'),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _buildSectionTitle('Members'),
        Wrap(
          spacing: 10,
          runSpacing: 8,
          children: members.map((member) {
            final username = member['user'].toString();
            return _chip(username, true);
          }).toList(),
        ),
        const SizedBox(height: 20),
        _buildSectionTitle('Invite Friends'),
        _buildSearchInput(),
        const SizedBox(height: 12),
        _buildInviteList(),
        const SizedBox(height: 20),
        if (!finished)
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: started ? () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => TeamGameScreen(teamId: widget.teamId))) : _startGame,
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                  child: Text(started ? 'Resume Game' : 'Start Game', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildSettingRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.inter(color: AppColors.textLight)),
          Text(value, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String text) {
    return Text(text, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white));
  }

  Widget _buildSearchInput() {
    return TextField(
      style: GoogleFonts.inter(color: Colors.white),
      decoration: InputDecoration(
        hintText: 'Search players by name',
        hintStyle: GoogleFonts.inter(color: Colors.grey.shade500),
        filled: true,
        fillColor: const Color(0xFF101626),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        suffixIcon: const Icon(Icons.search, color: Colors.white70),
      ),
      onChanged: _searchMembers,
    );
  }

  Widget _buildInviteList() {
    final members = _team?['members'] as List<dynamic>? ?? [];
    return Column(
      children: _searchResults.map((user) {
        final userId = user['id'] as int;
        final username = user['username']?.toString() ?? userId.toString();
        final alreadyJoined = _isJoined(userId);
        final alreadyInvited = _isInvited(userId);
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(color: const Color(0xFF101826), borderRadius: BorderRadius.circular(16)),
          child: Row(
            children: [
              CircleAvatar(backgroundColor: AppColors.primary.withOpacity(0.18), child: Text(username.isNotEmpty ? username[0].toUpperCase() : '?', style: GoogleFonts.inter(color: Colors.white))),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(username, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(alreadyJoined ? 'Already joined' : alreadyInvited ? 'Invite sent' : 'Tap to invite', style: GoogleFonts.inter(color: AppColors.textLight, fontSize: 12)),
                  ],
                ),
              ),
              if (!alreadyJoined)
                ElevatedButton(
                  onPressed: alreadyInvited || _inviteLoading ? null : () => _sendInvite(userId),
                  style: ElevatedButton.styleFrom(backgroundColor: alreadyInvited ? Colors.grey : AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                  child: Text(alreadyInvited ? 'Pending' : 'Invite', style: GoogleFonts.inter(fontSize: 12, color: Colors.white)),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _chip(String label, bool active) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: active ? AppColors.primary : const Color(0xFF1B2437), borderRadius: BorderRadius.circular(14)),
      child: Text(label, style: GoogleFonts.inter(color: Colors.white, fontSize: 13)),
    );
  }
}
