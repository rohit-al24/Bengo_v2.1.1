import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';
import '../../widgets/bengo_avatar.dart';
import '../../widgets/bengo_header.dart';
import '../friends/friends_screen.dart';
import '../auth/login_screen.dart';

// ── Tokens ────────────────────────────────────────────────────────────────────
const _kAccent = Color(0xFFC41230);
const _kAccentShadow = Color(0x35C41230);
const _kInk = Color(0xFF1B1B1D);
const _kMuted = Color(0xFF8A8A8F);
const _kBorderLight = Color(0xFFEAE5E1);
const _kSurface = Color(0xFFFFFFFF);
const _kFieldTint = Color(0xFFFDF3F5);
const _kFieldBorder = Color(0xFFEDD5D8);

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic> _user = {};
  Map<String, dynamic> _progress = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _loading = true);
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString('user');
    if (cached != null && cached.isNotEmpty) {
      try {
        final parsed = jsonDecode(cached) as Map<String, dynamic>;
        if (mounted) setState(() => _user = parsed);
      } catch (_) {}
    }
    try {
      final me = await ApiService.instance.getMe();
      final progress = await ApiService.instance.getMyProgress();
      if (mounted) {
        setState(() {
          _user = me;
          _progress = progress;
        });
        prefs.setString('user', jsonEncode(me));
      }
    } catch (_) {
      // keep cached
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Map<String, dynamic>?>(
      valueListenable: ApiService.instance.currentUserNotifier,
      builder: (context, userNotifierMap, _) {
        final u = userNotifierMap ?? _user;
        final firstName = (u['first_name'] ?? '').toString().trim();
        final lastName = (u['last_name'] ?? '').toString().trim();
        final displayName = (firstName.isNotEmpty || lastName.isNotEmpty)
            ? '$firstName $lastName'.trim()
            : (u['username'] ?? 'User').toString();
        final username = '@${u['username'] ?? 'user'}';
        final email = u['email']?.toString() ?? '';
        final xp = (u['xp'] ?? _progress['xp'] ?? 0) as int;
        final streak = (u['streak_days'] ?? _progress['streak_days'] ?? 0) as int;
        final avatarId = u['avatar_id']?.toString() ?? 'a1';
        final def = avatarById(avatarId);

        return Scaffold(
          backgroundColor: const Color(0xFFFAF8F5),
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFFAF8F5), Color(0xFFF8F5FF), Color(0xFFFFF5F7)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0.0, 0.5, 1.0],
              ),
            ),
            child: SafeArea(
              child: RefreshIndicator(
                onRefresh: _loadProfile,
                color: _kAccent,
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    // ── App header ────────────────────────────────────────────
                    const SliverToBoxAdapter(child: BenGoHeader()),
                    // ── Hero banner ──────────────────────────────────────────
                    SliverToBoxAdapter(
                      child: _ProfileHero(
                        def: def,
                        avatarId: avatarId,
                        displayName: displayName,
                        username: username,
                        xp: xp,
                        streak: streak,
                        loading: _loading,
                        onEdit: () => _showEditSheet(context, u),
                      ),
                    ),

                    // ── Progress card ────────────────────────────────────────
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                        child: _buildProgressCard(),
                      ),
                    ),

                    // ── Email row ────────────────────────────────────────────
                    if (email.isNotEmpty)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                          child: _InfoCard(
                            icon: Icons.alternate_email_rounded,
                            label: 'EMAIL',
                            value: email,
                          ),
                        ),
                      ),

                    // ── Institution + Mentor row ──────────────────────────
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                        child: Builder(builder: (_) {
                          final instName = (u['institution_name'] ?? '')?.toString() ?? '';

                          // mentor may be provided as mentor_name, a map, or scalar
                          String mentorName = '';
                          if (u['mentor_name'] != null) {
                            mentorName = u['mentor_name'].toString();
                          } else {
                            final mentor = u['mentor'];
                            if (mentor is Map) {
                              mentorName = (mentor['username'] ?? mentor['name'] ?? '').toString();
                            } else if (mentor is String) {
                              mentorName = mentor;
                            }
                          }

                          final instSettings = u['institution_settings'] as Map<String, dynamic>?;
                          final mentorAssignEnabled = instSettings?['mentor_assign_enabled'] == true;
                          final mentorChangeEnabled = instSettings?['mentor_change_enabled'] == true;
                          final canChangeMentor = mentorAssignEnabled || (mentorChangeEnabled && mentorName.isNotEmpty);

                          if (instName.isEmpty) return const SizedBox.shrink();
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.85),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: const Color(0xFFEDE8F8)),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextButton(
                                    onPressed: () {},
                                    style: TextButton.styleFrom(padding: EdgeInsets.zero),
                                    child: Text(
                                      instName,
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                      style: GoogleFonts.inter(fontSize: 14, color: _kInk, fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        mentorName.isNotEmpty ? mentorName : 'No mentor assigned',
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                        style: GoogleFonts.inter(
                                          fontSize: 13,
                                          color: mentorName.isNotEmpty ? _kMuted : const Color(0xFF8A8A8A),
                                          fontStyle: mentorName.isNotEmpty ? FontStyle.normal : FontStyle.italic,
                                        ),
                                      ),
                                      if (canChangeMentor)
                                        TextButton(
                                          onPressed: () => _showMentorPicker(context, u),
                                          style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 0)),
                                          child: Text('Change mentor', style: GoogleFonts.inter(fontSize: 12, color: _kAccent)),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ),
                    ),

                    // ── Membership card ──────────────────────────────────────
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                        child: _buildMembershipCard(),
                      ),
                    ),

                    // ── Certifications ───────────────────────────────────────
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                        child: _buildCertsSection(),
                      ),
                    ),

                    // ── Friends button ───────────────────────────────────────
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                        child: _FriendsButton(
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => const FriendsScreen()),
                          ),
                        ),
                      ),
                    ),

                    // ── Logout button ────────────────────────────────────────
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 14, 20, 40),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              await ApiService.instance.clearTokens();
                              if (mounted) {
                                Navigator.of(context).pushAndRemoveUntil(
                                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                                  (_) => false,
                                );
                              }
                            },
                            icon: const Icon(Icons.logout_rounded),
                            label: const Text('Logout'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFDC2626),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ── Edit profile bottom sheet ─────────────────────────────────────────────
  void _showEditSheet(BuildContext context, Map<String, dynamic> user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditProfileSheet(
        user: user,
        onSaved: () {
          _loadProfile();
        },
      ),
    );
  }

  Future<void> _showMentorPicker(BuildContext context, Map<String, dynamic> user) async {
    final institutionValue = user['institution'];
    final institutionId = institutionValue is Map
        ? institutionValue['id']
        : institutionValue;
    if (institutionId == null) return;

    late final List<dynamic> mentors;
    try {
      mentors = await ApiService.instance.fetchInstitutionMentors(int.parse(institutionId.toString()));
    } catch (_) {
      return;
    }

    int? selectedMentorId;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Choose mentor', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  if (mentors.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text('No mentors are available for your institution.', style: GoogleFonts.inter(color: _kMuted)),
                    )
                  else
                    ...mentors.map((mentor) {
                      final mentorId = mentor['id'] as int?;
                      final mentorLabel = mentor['username'] ?? mentor['email'] ?? 'Mentor';
                      return ListTile(
                        title: Text(mentorLabel.toString()),
                        trailing: selectedMentorId == mentorId ? const Icon(Icons.check_circle, color: _kAccent) : null,
                        onTap: () {
                          setState(() {
                            selectedMentorId = mentorId;
                          });
                        },
                      );
                    }).toList(),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: selectedMentorId == null
                              ? null
                              : () async {
                                  try {
                                    await ApiService.instance.assignMentor(
                                      institutionId: int.parse(institutionId.toString()),
                                      studentId: user['id'] as int,
                                      mentorId: selectedMentorId!,
                                    );
                                    Navigator.of(context).pop();
                                    _loadProfile();
                                  } catch (_) {
                                    Navigator.of(context).pop();
                                  }
                                },
                          style: ElevatedButton.styleFrom(backgroundColor: _kAccent),
                          child: Text('Save mentor', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ── Progress card ─────────────────────────────────────────────────────────
  Widget _buildProgressCard() {
    final unlocked = (_progress['unlocked_exams'] as List? ?? []);
    final lessonProg = (_progress['lesson_progress'] as List? ?? []);
    final completed = lessonProg.where((l) => l['is_completed'] == true).length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _kSurface.withOpacity(0.85),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFEDE8F8)),
        boxShadow: const [
          BoxShadow(
              color: Color(0x09000000), blurRadius: 20, offset: Offset(0, 6))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'LEARNING PROGRESS',
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: _kMuted,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _ProgStat(
                  icon: Icons.lock_open_rounded,
                  value: '${unlocked.length}',
                  label: 'Unlocked'),
              const SizedBox(width: 10),
              _ProgStat(
                  icon: Icons.check_circle_outline_rounded,
                  value: '$completed',
                  label: 'Lessons Done'),
              const SizedBox(width: 10),
              _ProgStat(
                  icon: Icons.trending_up_rounded,
                  value: '${lessonProg.length}',
                  label: 'In Progress'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMembershipCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFC41230), Color(0xFF8B0D21)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
              color: _kAccentShadow, blurRadius: 20, offset: Offset(0, 8))
        ],
      ),
      child: Row(
        children: [
          const Text('🏅', style: TextStyle(fontSize: 28)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'MEMBERSHIP',
                  style: GoogleFonts.inter(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: Colors.white60,
                      letterSpacing: 1.2),
                ),
                const SizedBox(height: 2),
                Text(
                  'Active Member',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(100),
            ),
            child: Text(
              'MANAGE',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: _kAccent,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCertsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Certifications',
              style: GoogleFonts.spaceGrotesk(
                  fontSize: 18, fontWeight: FontWeight.w700, color: _kInk),
            ),
            Text(
              'View All',
              style: GoogleFonts.inter(
                  fontSize: 12, color: _kAccent, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            _CertBadge(icon: 'あ', label: 'JLPT N5\nMastery'),
            const SizedBox(width: 10),
            _CertBadge(icon: '⌨', label: 'Logic\nGates'),
            const SizedBox(width: 10),
            _CertBadge(icon: '🏆', label: 'Top 1%\nGlobal'),
          ],
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// HERO BANNER
// ═══════════════════════════════════════════════════════════════════════════════

class _ProfileHero extends StatelessWidget {
  final BenGoAvatarDef def;
  final String avatarId;
  final String displayName;
  final String username;
  final int xp;
  final int streak;
  final bool loading;
  final VoidCallback onEdit;

  const _ProfileHero({
    required this.def,
    required this.avatarId,
    required this.displayName,
    required this.username,
    required this.xp,
    required this.streak,
    required this.loading,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFEDE8F8)),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0A000000), blurRadius: 24, offset: Offset(0, 8))
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Avatar with glow
              Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: def.shadow.withOpacity(0.38),
                          blurRadius: 22,
                          spreadRadius: 3,
                        )
                      ],
                    ),
                    child: BenGoAvatar(avatarId: avatarId, size: 80, showRing: true),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: _kInk,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      username,
                      style: GoogleFonts.inter(
                          fontSize: 13, color: _kMuted),
                    ),
                    const SizedBox(height: 10),
                    // Stat pills
                    Row(
                      children: [
                        _MiniPill(emoji: '🔥', value: '$streak', label: 'days'),
                        const SizedBox(width: 8),
                        _MiniPill(emoji: '⚡', value: '$xp', label: 'XP'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          // Edit button
          GestureDetector(
            onTap: onEdit,
            child: Container(
              height: 46,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFEDE8F8), width: 1.5),
                borderRadius: BorderRadius.circular(100),
                color: const Color(0xFFFBF8FF),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.edit_rounded, size: 16, color: _kAccent),
                  const SizedBox(width: 8),
                  Text(
                    'Edit Profile',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _kAccent,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// EDIT PROFILE SHEET
// ═══════════════════════════════════════════════════════════════════════════════

class _EditProfileSheet extends StatefulWidget {
  final Map<String, dynamic> user;
  final VoidCallback onSaved;

  const _EditProfileSheet({required this.user, required this.onSaved});

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  late final TextEditingController _firstCtrl;
  late final TextEditingController _lastCtrl;
  late String _avatarId;
  bool _saving = false;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _firstCtrl = TextEditingController(
        text: widget.user['first_name']?.toString() ?? '');
    _lastCtrl = TextEditingController(
        text: widget.user['last_name']?.toString() ?? '');
    _avatarId = widget.user['avatar_id']?.toString() ?? 'a1';
  }

  @override
  void dispose() {
    _firstCtrl.dispose();
    _lastCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() { _saving = true; _error = ''; });
    try {
      await ApiService.instance.updateProfile({
        'first_name': _firstCtrl.text.trim(),
        'last_name': _lastCtrl.text.trim(),
        'avatar_id': _avatarId,
      });
      if (mounted) {
        Navigator.pop(context);
        widget.onSaved();
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final screenH = MediaQuery.of(context).size.height;

    return Container(
      height: screenH * 0.92,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // ── Drag handle + title ──────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                        color: _kBorderLight,
                        borderRadius: BorderRadius.circular(100)),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Edit Profile',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 22, fontWeight: FontWeight.w700, color: _kInk),
                ),
                const SizedBox(height: 6),
                Text(
                  'Pick your avatar below, then confirm your name.',
                  style: GoogleFonts.inter(fontSize: 12, color: _kMuted),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // ── Scrollable: avatar section ──────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section label
                  Text(
                    'CHOOSE AVATAR',
                    style: GoogleFonts.inter(
                      fontSize: 10, fontWeight: FontWeight.w800,
                      color: _kMuted, letterSpacing: 1.5),
                  ),
                  const SizedBox(height: 10),
                  // Preview row
                  Row(
                    children: [
                      BenGoAvatar(avatarId: _avatarId, size: 56, showRing: true),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          avatarById(_avatarId).label,
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 16, fontWeight: FontWeight.w700, color: _kInk),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // Avatar grid
                  BenGoAvatarPicker(
                    selectedId: _avatarId,
                    onSelect: (id) => setState(() => _avatarId = id),
                  ),
                ],
              ),
            ),
          ),

          // ── Pinned: name fields + save button ──────────────────────────
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: _kBorderLight)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0A000000),
                  blurRadius: 20,
                  offset: Offset(0, -6),
                ),
              ],
            ),
            padding: EdgeInsets.fromLTRB(24, 16, 24, 16 + bottom),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'YOUR NAME',
                  style: GoogleFonts.inter(
                    fontSize: 10, fontWeight: FontWeight.w800,
                    color: _kMuted, letterSpacing: 1.5),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: _EditField(label: 'First name', ctrl: _firstCtrl)),
                    const SizedBox(width: 10),
                    Expanded(child: _EditField(label: 'Last name', ctrl: _lastCtrl)),
                  ],
                ),
                if (_error.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _kFieldTint,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _kFieldBorder),
                    ),
                    child: Text(_error,
                        style: GoogleFonts.inter(fontSize: 12, color: _kAccent)),
                  ),
                ],
                const SizedBox(height: 14),
                // Save button
                GestureDetector(
                  onTap: _saving ? null : _save,
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFC41230), Color(0xFFE0183A)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(100),
                      boxShadow: const [
                        BoxShadow(color: _kAccentShadow, blurRadius: 0, offset: Offset(0, 4)),
                        BoxShadow(color: Color(0x18C41230), blurRadius: 12, offset: Offset(0, 8)),
                      ],
                    ),
                    child: Center(
                      child: _saving
                          ? const SizedBox(
                              width: 20, height: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : Text(
                              'Save Changes',
                              style: GoogleFonts.inter(
                                fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white),
                            ),
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
}

// ═══════════════════════════════════════════════════════════════════════════════
// COMPONENTS
// ═══════════════════════════════════════════════════════════════════════════════

class _MiniPill extends StatelessWidget {
  final String emoji;
  final String value;
  final String label;
  const _MiniPill({required this.emoji, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F2FA),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: const Color(0xFFEDE9F4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          Text(
            value,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 13, fontWeight: FontWeight.w700, color: _kInk),
          ),
          const SizedBox(width: 3),
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 11, color: _kMuted),
          ),
        ],
      ),
    );
  }
}

class _ProgStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  const _ProgStat({required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFAF8F5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _kBorderLight),
        ),
        child: Column(
          children: [
            Icon(icon, color: _kAccent, size: 20),
            const SizedBox(height: 6),
            Text(
              value,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 20, fontWeight: FontWeight.w700, color: _kInk),
            ),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 9, color: _kMuted, letterSpacing: 0.5),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoCard({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEDE8F8)),
        boxShadow: const [
          BoxShadow(color: Color(0x07000000), blurRadius: 12, offset: Offset(0, 4))
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFFDF3F5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFEDD5D8)),
            ),
            child: Icon(icon, color: _kAccent, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 9, fontWeight: FontWeight.w700,
                    color: _kMuted, letterSpacing: 1.2),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.inter(fontSize: 13, color: _kInk),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CertBadge extends StatelessWidget {
  final String icon;
  final String label;
  const _CertBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.85),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFEDE8F8)),
          boxShadow: const [
            BoxShadow(color: Color(0x07000000), blurRadius: 10, offset: Offset(0, 4))
          ],
        ),
        child: Column(
          children: [
            Text(icon, style: const TextStyle(fontSize: 26)),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 10, color: _kMuted, height: 1.3),
            ),
          ],
        ),
      ),
    );
  }
}

class _FriendsButton extends StatelessWidget {
  final VoidCallback onTap;
  const _FriendsButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.85),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFEDE8F8)),
          boxShadow: const [
            BoxShadow(
                color: Color(0x07000000), blurRadius: 12, offset: Offset(0, 4))
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFFFDF3F5),
                borderRadius: BorderRadius.circular(13),
                border: Border.all(color: const Color(0xFFEDD5D8)),
              ),
              child: const Icon(Icons.people_alt_rounded, color: _kAccent, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                'Friends & Network',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 16, fontWeight: FontWeight.w700, color: _kInk),
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: _kMuted),
          ],
        ),
      ),
    );
  }
}

class _EditField extends StatelessWidget {
  final String label;
  final TextEditingController ctrl;
  const _EditField({required this.label, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11, fontWeight: FontWeight.w600, color: _kMuted),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          style: GoogleFonts.inter(fontSize: 14, color: _kInk),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFFAF8F5),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: _kBorderLight),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: _kBorderLight),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: _kAccent, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
