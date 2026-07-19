import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/clan_service.dart';
import '../../services/api_service.dart';
import 'clan_theme.dart';
import 'clan_join_screen.dart';

class ClanSettingsScreen extends StatefulWidget {
  final Map<String, dynamic> clan;
  final List<Map<String, dynamic>> members;

  const ClanSettingsScreen({
    super.key,
    required this.clan,
    required this.members,
  });

  @override
  State<ClanSettingsScreen> createState() => _ClanSettingsScreenState();
}

class _ClanSettingsScreenState extends State<ClanSettingsScreen> {
  bool _leaving = false;

  // ── Leave Clan ────────────────────────────────────────────────────────────

  void _promptLeave() {
    final clanName = widget.clan['name'] as String? ?? 'this clan';
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: kClanSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Leave Clan?',
          style: GoogleFonts.spaceGrotesk(fontSize: 18, fontWeight: FontWeight.w800, color: kClanInk)),
        content: RichText(
          text: TextSpan(
            style: GoogleFonts.inter(fontSize: 14, color: kClanMuted, height: 1.5),
            children: [
              const TextSpan(text: 'Are you sure you want to leave '),
              TextSpan(text: clanName, style: const TextStyle(fontWeight: FontWeight.w700, color: kClanInk)),
              const TextSpan(text: '? You will lose your clan rank and contributions.'),
            ],
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actionsAlignment: MainAxisAlignment.spaceBetween,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
              style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: kClanMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: kClanRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            onPressed: () {
              Navigator.pop(context);
              _doLeave();
            },
            child: Text('Leave', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Future<void> _doLeave() async {
    setState(() => _leaving = true);
    try {
      final clanId = widget.clan['id'] as int;
      await ClanService.instance.leaveClan(clanId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('You have left the clan.', style: GoogleFonts.inter(color: Colors.white)),
          backgroundColor: kClanInk,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      // Navigate back to the join/browse screen
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const ClanJoinScreen()),
        (route) => route.isFirst,
      );
    } on ApiException catch (e) {
      setState(() => _leaving = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message, style: GoogleFonts.inter(color: Colors.white)),
          backgroundColor: kClanRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final clanName    = widget.clan['name'] as String? ?? '—';
    final privacy     = widget.clan['privacy'] as String? ?? 'open';
    final trophies    = widget.clan['trophies'] ?? 0;
    final description = widget.clan['description'] as String? ?? '';
    final memberCount = widget.clan['member_count'] ?? 0;
    final slotsTotal  = widget.clan['slots_unlocked'] ?? 10;
    final isLeader    = (widget.clan['my_role'] as String?) == 'leader';

    return Scaffold(
      backgroundColor: kClanBg,
      appBar: AppBar(
        backgroundColor: kClanBg,
        elevation: 0,
        leading: const BackButton(color: kClanInk),
        title: Text('Clan Settings',
          style: GoogleFonts.spaceGrotesk(fontSize: 18, fontWeight: FontWeight.w700, color: kClanInk)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [

            // ── Clan identity card ───────────────────────────────────────────
            const ClanSectionHeader(title: 'CLAN IDENTITY'),
            const SizedBox(height: 10),
            ClanCard(
              child: Column(
                children: [
                  _SettingsRow(
                    icon: Icons.shield_rounded,
                    label: 'Clan Name',
                    value: clanName,
                    editable: isLeader,
                    onEdit: isLeader ? () {} : null,
                  ),
                  const Divider(color: kClanBorder, height: 1),
                  _SettingsRow(
                    icon: Icons.tag_rounded,
                    label: 'Clan Tag',
                    value: '#${widget.clan['tag'] ?? ''}',
                    editable: false,
                  ),
                  const Divider(color: kClanBorder, height: 1),
                  _SettingsRow(
                    icon: Icons.lock_outline_rounded,
                    label: 'Privacy',
                    value: _privacyLabel(privacy),
                    editable: isLeader,
                    onEdit: isLeader ? () {} : null,
                  ),
                  if (description.isNotEmpty) ...[
                    const Divider(color: kClanBorder, height: 1),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Description', style: GoogleFonts.inter(fontSize: 11, color: kClanMuted, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          Text(description, style: GoogleFonts.inter(fontSize: 13, color: kClanInk, height: 1.5)),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Stats ────────────────────────────────────────────────────────
            const ClanSectionHeader(title: 'STATS'),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: ClanCard(
                child: ClanStatChip(icon: Icons.emoji_events_rounded, value: trophies.toString(), label: 'Trophies'),
              )),
              const SizedBox(width: 8),
              Expanded(child: ClanCard(
                child: ClanStatChip(icon: Icons.people_rounded, value: '$memberCount/$slotsTotal', label: 'Members'),
              )),
            ]),
            const SizedBox(height: 20),

            // ── Members list ──────────────────────────────────────────────────
            const ClanSectionHeader(title: 'MEMBERS'),
            const SizedBox(height: 10),
            ...widget.members.map((m) => _MemberSettingsRow(
              member: m,
              isLeader: isLeader,
            )),
            const SizedBox(height: 32),

            // ── Danger zone: Leave Clan ──────────────────────────────────────
            const ClanSectionHeader(title: 'DANGER ZONE'),
            const SizedBox(height: 10),
            ClanCard(
              color: const Color(0xFFFFF8F8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const Icon(Icons.warning_amber_rounded, color: kClanRed, size: 18),
                    const SizedBox(width: 8),
                    Text('Leave Clan',
                      style: GoogleFonts.spaceGrotesk(fontSize: 15, fontWeight: FontWeight.w700, color: kClanRed)),
                  ]),
                  const SizedBox(height: 6),
                  Text(
                    isLeader
                      ? 'As clan leader, leaving will transfer leadership to the next senior member or dissolve the clan if you are the only member.'
                      : 'You will lose your position and contributions. This action cannot be undone.',
                    style: GoogleFonts.inter(fontSize: 12, color: kClanMuted, height: 1.5),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: _leaving
                      ? const Center(child: CircularProgressIndicator(color: kClanRed, strokeWidth: 2))
                      : ClanPillButton(
                          label: 'Leave Clan',
                          icon: Icons.exit_to_app_rounded,
                          isDanger: true,
                          isOutlined: true,
                          onPressed: _promptLeave,
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

  String _privacyLabel(String p) {
    switch (p) {
      case 'open': return 'Open — Anyone can join';
      case 'invite_only': return 'Invite Only';
      case 'closed': return 'Closed';
      default: return p;
    }
  }
}

// ── Settings row ──────────────────────────────────────────────────────────────

class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final bool editable;
  final VoidCallback? onEdit;

  const _SettingsRow({
    required this.icon,
    required this.label,
    required this.value,
    this.editable = false,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: kClanMuted),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: GoogleFonts.inter(fontSize: 11, color: kClanMuted, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(value, style: GoogleFonts.inter(fontSize: 14, color: kClanInk, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          if (editable && onEdit != null)
            GestureDetector(
              onTap: onEdit,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: kClanBorder.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.edit_outlined, size: 14, color: kClanMuted),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Member row in settings ────────────────────────────────────────────────────

class _MemberSettingsRow extends StatelessWidget {
  final Map<String, dynamic> member;
  final bool isLeader;

  const _MemberSettingsRow({super.key, required this.member, required this.isLeader});

  @override
  Widget build(BuildContext context) {
    final username = member['username'] as String? ?? '—';
    final role     = member['role'] as String? ?? 'member';
    final trophies = member['trophies'] ?? 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ClanCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: kClanAccentL,
              child: Text(username.isNotEmpty ? username[0].toUpperCase() : '?',
                style: GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.w700, color: kClanAccent)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(username, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: kClanInk)),
                  Text(_roleLabel(role), style: GoogleFonts.inter(fontSize: 11, color: kClanMuted)),
                ],
              ),
            ),
            Row(
              children: [
                const Icon(Icons.emoji_events_rounded, size: 13, color: kClanGold),
                const SizedBox(width: 3),
                Text(trophies.toString(), style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: kClanInk)),
              ],
            ),
            if (isLeader && role != 'leader') ...[
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {},
                child: const Icon(Icons.more_vert_rounded, size: 18, color: kClanMuted),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _roleLabel(String r) {
    switch (r) {
      case 'leader': return 'Leader';
      case 'co_leader': return 'Co-Leader';
      case 'elder': return 'Elder';
      default: return 'Member';
    }
  }
}
