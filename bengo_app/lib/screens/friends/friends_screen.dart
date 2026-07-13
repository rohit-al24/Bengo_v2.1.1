import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/app_colors.dart';
import '../../widgets/bengo_app_bar.dart';
import '../../widgets/bengo_avatar.dart';
import '../../services/api_service.dart';
import '../../widgets/bottom_nav.dart';

// ── Design tokens ──────────────────────────────────────────────────────────────
const _kBg     = Color(0xFFFAF8F5);
const _kSurface = Color(0xFFFFFFFF);
const _kAccent  = Color(0xFFC41230);
const _kInk     = Color(0xFF1B1B1D);
const _kMuted   = Color(0xFF8A8A8F);
const _kBorder  = Color(0xFFEAE5E1);
const _kFieldTint  = Color(0xFFFDF3F5);
const _kFieldBorder = Color(0xFFEDD5D8);

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  final _searchCtrl = TextEditingController();

  List<dynamic> _friends  = [];
  List<dynamic> _incoming = [];
  List<dynamic> _suggested = [];
  List<dynamic> _searchResults = [];

  bool _loading   = true;
  bool _searching = false;
  String _error   = '';

  @override
  void initState() {
    super.initState();
    _loadAll();
    _searchCtrl.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchCtrl.removeListener(_onSearchChanged);
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() { _loading = true; _error = ''; });
    try {
      final futs = await Future.wait([
        ApiService.instance.getFriends(),
        ApiService.instance.getIncomingRequests(),
        ApiService.instance.searchUsers(''),
      ]);
      setState(() {
        _friends  = futs[0];
        _incoming = futs[1];
        _suggested = futs[2].take(6).toList();
      });
    } catch (_) {
      setState(() => _error = 'Could not load friends.');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _onSearchChanged() async {
    final q = _searchCtrl.text.trim();
    if (q.isEmpty) {
      setState(() { _searchResults = []; _searching = false; });
      return;
    }
    setState(() => _searching = true);
    try {
      final res = await ApiService.instance.searchUsers(q);
      if (mounted) setState(() { _searchResults = res; _searching = false; });
    } catch (_) {
      if (mounted) setState(() => _searching = false);
    }
  }

  Future<void> _acceptRequest(int id) async {
    try { await ApiService.instance.acceptFriendRequest(id); _loadAll(); } catch (_) {}
  }

  Future<void> _rejectRequest(int id) async {
    try { await ApiService.instance.rejectFriendRequest(id); _loadAll(); } catch (_) {}
  }

  Future<void> _sendRequest(int toUserId) async {
    try {
      await ApiService.instance.sendFriendRequest(toUserId);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Row(children: [
          const Icon(Icons.check_circle_rounded, color: Colors.white, size: 16),
          const SizedBox(width: 8),
          const Text('Friend request sent!'),
        ]),
        backgroundColor: _kAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    } catch (_) {}
  }

  void _showProfileSheet(Map<String, dynamic> user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (_) => _UserProfileSheet(user: user),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      bottomNavigationBar: BenGoBottomNav(
        currentIndex: 3,
        onTap: (i) {
          if (i != 3) Navigator.of(context).popUntil((r) => r.isFirst);
        },
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadAll,
          color: _kAccent,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: _buildAppBar(context)),
              SliverToBoxAdapter(child: _buildSearchBar()),

              if (_error.isNotEmpty)
                SliverToBoxAdapter(child: _buildErrorBanner()),

              // Search results
              if (_searchCtrl.text.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                    child: Text('Search Results', style: GoogleFonts.spaceGrotesk(
                      fontSize: 18, fontWeight: FontWeight.w700, color: _kInk)),
                  ),
                ),
                if (_searching)
                  const SliverToBoxAdapter(child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: CircularProgressIndicator(color: _kAccent, strokeWidth: 2.5)),
                  ))
                else if (_searchResults.isEmpty)
                  SliverToBoxAdapter(child: _buildEmptyState(
                    icon: Icons.search_off_rounded,
                    label: 'No users found',
                    sub: 'Try a different username',
                  ))
                else
                  SliverList(delegate: SliverChildBuilderDelegate(
                    (_, i) => _buildSearchTile(_searchResults[i]),
                    childCount: _searchResults.length,
                  )),
              ]

              // Normal content
              else if (_loading)
                const SliverToBoxAdapter(child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 60),
                  child: Center(child: CircularProgressIndicator(color: _kAccent, strokeWidth: 2.5)),
                ))
              else ...[
                // ── Incoming requests ──────────────────────────────────────
                if (_incoming.isNotEmpty) ...[
                  SliverToBoxAdapter(child: _buildSectionHeader('Friend Requests', badge: _incoming.length)),
                  SliverList(delegate: SliverChildBuilderDelegate(
                    (_, i) => _buildRequestCard(_incoming[i]),
                    childCount: _incoming.length,
                  )),
                  SliverToBoxAdapter(child: const SizedBox(height: 8)),
                ],

                // ── Friends ────────────────────────────────────────────────
                SliverToBoxAdapter(child: _buildSectionHeader('My Friends', badge: _friends.length, secondary: true)),
                if (_friends.isEmpty)
                  SliverToBoxAdapter(child: _buildEmptyState(
                    icon: Icons.group_add_rounded,
                    label: 'No friends yet',
                    sub: 'Search for users and start connecting!',
                  ))
                else
                  SliverList(delegate: SliverChildBuilderDelegate(
                    (_, i) => _buildFriendTile(_friends[i]),
                    childCount: _friends.length,
                  )),

                // ── Suggested ──────────────────────────────────────────────
                if (_suggested.isNotEmpty) ...[
                  SliverToBoxAdapter(child: _buildSectionHeader('People You May Know')),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                      child: _buildSuggestedGrid(),
                    ),
                  ),
                ],
              ],

              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ),
        ),
      ),
    );
  }

  // ── App bar ──────────────────────────────────────────────────────────────────
  Widget _buildAppBar(BuildContext context) {
    return BenGoAppBar(
      showBack: true,
      actions: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: _kSurface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _kBorder),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))],
              ),
              child: const Icon(Icons.people_outline_rounded, color: _kMuted, size: 22),
            ),
            if (_incoming.isNotEmpty)
              Positioned(
                top: -4, right: -4,
                child: Container(
                  width: 18, height: 18,
                  decoration: BoxDecoration(
                    color: _kAccent,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Center(
                    child: Text('${_incoming.length}',
                      style: GoogleFonts.inter(fontSize: 9, color: Colors.white, fontWeight: FontWeight.w800)),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  // ── Search bar ───────────────────────────────────────────────────────────────
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Container(
        decoration: BoxDecoration(
          color: _kSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _kBorder),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 3))],
        ),
        child: TextField(
          controller: _searchCtrl,
          style: GoogleFonts.inter(fontSize: 14, color: _kInk),
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search_rounded, color: _kMuted, size: 20),
            hintText: 'Search by username…',
            hintStyle: GoogleFonts.inter(fontSize: 14, color: _kMuted),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            suffixIcon: _searchCtrl.text.isNotEmpty
                ? GestureDetector(
                    onTap: () { _searchCtrl.clear(); setState(() => _searchResults = []); },
                    child: const Icon(Icons.close_rounded, color: _kMuted, size: 18))
                : null,
          ),
        ),
      ),
    );
  }

  // ── Section header ───────────────────────────────────────────────────────────
  Widget _buildSectionHeader(String title, {int? badge, bool secondary = false}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
      child: Row(
        children: [
          Expanded(
            child: Text(title, style: GoogleFonts.spaceGrotesk(
              fontSize: 18, fontWeight: FontWeight.w700,
              color: secondary ? _kMuted : _kInk, letterSpacing: -0.3)),
          ),
          if (badge != null && badge > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: secondary ? _kBorder : _kAccent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('$badge', style: GoogleFonts.inter(
                fontSize: 11, fontWeight: FontWeight.w700,
                color: secondary ? _kMuted : Colors.white)),
            ),
        ],
      ),
    );
  }

  // ── Incoming request card ────────────────────────────────────────────────────
  Widget _buildRequestCard(dynamic req) {
    final fromUser = req['from_user'] as Map<String, dynamic>? ?? {};
    final username  = fromUser['username']?.toString() ?? 'Unknown';
    final firstName = fromUser['first_name']?.toString() ?? '';
    final lastName  = fromUser['last_name']?.toString() ?? '';
    final displayName = (firstName.isNotEmpty || lastName.isNotEmpty)
        ? '$firstName $lastName'.trim()
        : username;
    final avatarId  = fromUser['avatar_id']?.toString();
    final xp        = fromUser['xp'] as int? ?? 0;
    final reqId     = req['id'] as int? ?? 0;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kFieldTint,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _kFieldBorder, width: 1.5),
        boxShadow: [BoxShadow(color: _kAccent.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          // Avatar
          Stack(
            clipBehavior: Clip.none,
            children: [
              BenGoAvatar(avatarId: avatarId, size: 52),
              Positioned(
                top: -4, right: -4,
                child: Container(
                  width: 18, height: 18,
                  decoration: BoxDecoration(
                    color: _kAccent, shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2)),
                  child: const Icon(Icons.person_add_rounded, color: Colors.white, size: 10),
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),

          // Name + username + xp
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(displayName, style: GoogleFonts.inter(
                  fontSize: 14, fontWeight: FontWeight.w700, color: _kInk),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text('@$username', style: GoogleFonts.inter(
                  fontSize: 12, color: _kMuted, fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Row(children: [
                  const Icon(Icons.bolt_rounded, size: 12, color: _kAccent),
                  const SizedBox(width: 2),
                  Text('$xp XP', style: GoogleFonts.inter(
                    fontSize: 11, color: _kAccent, fontWeight: FontWeight.w700)),
                ]),
              ],
            ),
          ),

          // Accept / Reject buttons
          Column(
            children: [
              _ActionButton(
                label: 'Accept',
                filled: true,
                onTap: () => _acceptRequest(reqId),
              ),
              const SizedBox(height: 6),
              _ActionButton(
                label: 'Decline',
                filled: false,
                onTap: () => _rejectRequest(reqId),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Friend tile ──────────────────────────────────────────────────────────────
  Widget _buildFriendTile(dynamic friendship) {
    final friend   = friendship['friend'] as Map<String, dynamic>? ?? {};
    final username  = friend['username']?.toString() ?? 'Unknown';
    final firstName = friend['first_name']?.toString() ?? '';
    final lastName  = friend['last_name']?.toString() ?? '';
    final displayName = (firstName.isNotEmpty || lastName.isNotEmpty)
        ? '$firstName $lastName'.trim()
        : username;
    final avatarId  = friend['avatar_id']?.toString();
    final isOnline  = friendship['is_online'] as bool? ?? false;
    final xp        = friend['xp'] as int? ?? 0;

    return GestureDetector(
      onTap: () => _showProfileSheet(friend),
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _kSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _kBorder),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 3))],
        ),
        child: Row(
          children: [
            // Avatar + online dot
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                BenGoAvatar(avatarId: avatarId, size: 46),
                Container(
                  width: 12, height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isOnline ? AppColors.online : AppColors.offline,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 14),

            // Name + status
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(displayName, style: GoogleFonts.inter(
                    fontSize: 14, fontWeight: FontWeight.w700, color: _kInk),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text('@$username', style: GoogleFonts.inter(
                    fontSize: 11, color: _kMuted, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 3),
                  Row(children: [
                    Icon(Icons.circle, size: 7,
                      color: isOnline ? AppColors.online : AppColors.offline),
                    const SizedBox(width: 5),
                    Text(isOnline ? 'Online' : 'Offline',
                      style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500,
                        color: isOnline ? AppColors.online : _kMuted)),
                  ]),
                ],
              ),
            ),

            // XP + View Profile
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _kFieldTint,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _kFieldBorder),
                  ),
                  child: Row(children: [
                    const Icon(Icons.bolt_rounded, size: 13, color: _kAccent),
                    const SizedBox(width: 3),
                    Text('$xp XP', style: GoogleFonts.inter(
                      fontSize: 11, color: _kAccent, fontWeight: FontWeight.w700)),
                  ]),
                ),
                const SizedBox(height: 8),
                Row(children: [
                  Text('View Profile', style: GoogleFonts.inter(
                    fontSize: 11, fontWeight: FontWeight.w600, color: _kAccent)),
                  const SizedBox(width: 3),
                  const Icon(Icons.chevron_right_rounded, color: _kAccent, size: 16),
                ]),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Search result tile ───────────────────────────────────────────────────────
  Widget _buildSearchTile(dynamic user) {
    final username  = user['username']?.toString() ?? '';
    final firstName = user['first_name']?.toString() ?? '';
    final lastName  = user['last_name']?.toString() ?? '';
    final displayName = (firstName.isNotEmpty || lastName.isNotEmpty)
        ? '$firstName $lastName'.trim()
        : username;
    final avatarId  = user['avatar_id']?.toString();
    final xp        = user['xp'] as int? ?? 0;
    final id        = user['id'] as int? ?? 0;

    return GestureDetector(
      onTap: () => _showProfileSheet(user),
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _kSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _kBorder),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
        ),
        child: Row(
          children: [
            BenGoAvatar(avatarId: avatarId, size: 44),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(displayName, style: GoogleFonts.inter(
                    fontSize: 14, fontWeight: FontWeight.w700, color: _kInk),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text('@$username', style: GoogleFonts.inter(
                    fontSize: 11, color: _kMuted)),
                  if (xp > 0) ...[
                    const SizedBox(height: 3),
                    Row(children: [
                      const Icon(Icons.bolt_rounded, size: 12, color: _kAccent),
                      Text(' $xp XP', style: GoogleFonts.inter(
                        fontSize: 11, color: _kAccent, fontWeight: FontWeight.w600)),
                    ]),
                  ],
                ],
              ),
            ),
            _ActionButton(label: 'Add', filled: true, onTap: () => _sendRequest(id)),
          ],
        ),
      ),
    );
  }

  // ── Suggested grid ───────────────────────────────────────────────────────────
  Widget _buildSuggestedGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.72,
      ),
      itemCount: _suggested.length,
      itemBuilder: (context, i) {
        final s = _suggested[i] as Map<String, dynamic>;
        final name = s['username']?.toString() ?? 'User';
        final firstName = s['first_name']?.toString() ?? '';
        final avatarId = s['avatar_id']?.toString();
        final id = s['id'] as int?;

        return GestureDetector(
          onTap: () => _showProfileSheet(s),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _kSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _kBorder),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8)],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                BenGoAvatar(avatarId: avatarId, size: 52),
                const SizedBox(height: 8),
                Text(firstName.isNotEmpty ? firstName : name,
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: _kInk),
                  maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
                const SizedBox(height: 2),
                Text('@$name',
                  style: GoogleFonts.inter(fontSize: 10, color: _kMuted),
                  maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: id != null ? () => _sendRequest(id) : null,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: _kAccent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(child: Text('Add',
                      style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white))),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Error banner ─────────────────────────────────────────────────────────────
  Widget _buildErrorBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Row(children: [
        const Icon(Icons.wifi_off_rounded, color: Colors.orange, size: 18),
        const SizedBox(width: 8),
        Expanded(child: Text(_error, style: GoogleFonts.inter(fontSize: 12, color: Colors.orange.shade800))),
      ]),
    );
  }

  // ── Empty state ──────────────────────────────────────────────────────────────
  Widget _buildEmptyState({required IconData icon, required String label, required String sub}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Column(children: [
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(color: _kFieldTint, borderRadius: BorderRadius.circular(20)),
            child: Icon(icon, size: 30, color: _kMuted),
          ),
          const SizedBox(height: 12),
          Text(label, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: _kInk)),
          const SizedBox(height: 4),
          Text(sub, style: GoogleFonts.inter(fontSize: 12, color: _kMuted)),
        ]),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Small reusable action button
// ═══════════════════════════════════════════════════════════════════════════════
class _ActionButton extends StatelessWidget {
  final String label;
  final bool filled;
  final VoidCallback onTap;
  const _ActionButton({required this.label, required this.filled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: filled ? _kAccent : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: filled ? null : Border.all(color: _kBorder, width: 1.5),
        ),
        child: Text(label, style: GoogleFonts.inter(
          fontSize: 12, fontWeight: FontWeight.w700,
          color: filled ? Colors.white : _kMuted)),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// User Profile Bottom Sheet — slides up with full profile details
// ═══════════════════════════════════════════════════════════════════════════════
class _UserProfileSheet extends StatefulWidget {
  final Map<String, dynamic> user;
  const _UserProfileSheet({required this.user});

  @override
  State<_UserProfileSheet> createState() => _UserProfileSheetState();
}

class _UserProfileSheetState extends State<_UserProfileSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<Offset> _slideAnim;
  late Animation<double>  _fadeAnim;

  int _friendCount = 0;
  int _examCount   = 0;
  bool _loading    = true;
  bool _isFriend   = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 380));
    _slideAnim = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _fadeAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _ctrl.forward();
    _loadExtras();
  }

  Future<void> _loadExtras() async {
    try {
      final friends = await ApiService.instance.getFriends();
      final exams   = await ApiService.instance.getExams();
      final targetId = widget.user['id'] as int? ?? 0;
      bool isFriend = false;
      for (var f in friends) {
        final friendUser = f['friend'] as Map<String, dynamic>? ?? {};
        if (friendUser['id'] == targetId) {
          isFriend = true;
          break;
        }
      }
      if (mounted) setState(() {
        _friendCount = friends.length;
        _examCount   = exams.length;
        _isFriend    = isFriend;
        _loading     = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _confirmAndRemoveFriend() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text('Remove Friend', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold, color: _kInk)),
        content: Text('Are you sure you want to remove @${widget.user['username']} from your friends?', style: GoogleFonts.inter(color: _kInk)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: GoogleFonts.inter(color: _kMuted, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _kAccent,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Remove', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _loading = true);
      try {
        final targetId = widget.user['id'] as int? ?? 0;
        await ApiService.instance.removeFriend(targetId);
        _close();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Removed @${widget.user['username']} from friends'),
            backgroundColor: _kAccent,
          ),
        );
      } catch (e) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to remove friend. Please try again.')),
        );
      }
    }
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  void _close() => _ctrl.reverse().then((_) => Navigator.pop(context));

  @override
  Widget build(BuildContext context) {
    final u           = widget.user;
    final username    = u['username']?.toString() ?? 'user';
    final firstName   = u['first_name']?.toString() ?? '';
    final lastName    = u['last_name']?.toString() ?? '';
    final displayName = (firstName.isNotEmpty || lastName.isNotEmpty)
        ? '$firstName $lastName'.trim()
        : username;
    final avatarId    = u['avatar_id']?.toString();
    final xp          = u['xp'] as int? ?? 0;
    final streak      = u['streak_days'] as int? ?? 0;
    final institution = u['institution']?.toString() ?? '';
    final def         = avatarById(avatarId);

    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: Container(
          decoration: const BoxDecoration(
            color: _kSurface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              const SizedBox(height: 12),
              Center(child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: _kBorder, borderRadius: BorderRadius.circular(2)),
              )),
              const SizedBox(height: 8),

              // Close row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    GestureDetector(
                      onTap: _close,
                      child: Container(
                        width: 34, height: 34,
                        decoration: BoxDecoration(
                          color: _kFieldTint, shape: BoxShape.circle,
                          border: Border.all(color: _kFieldBorder)),
                        child: const Icon(Icons.close_rounded, size: 16, color: _kMuted),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // Avatar + gradient backdrop
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [def.shadow.withOpacity(0.08), Colors.transparent],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Column(
                  children: [
                    // Avatar with glow
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(color: def.shadow.withOpacity(0.35), blurRadius: 24, spreadRadius: 2),
                        ],
                      ),
                      child: BenGoAvatar(avatarId: avatarId, size: 88),
                    ),
                    const SizedBox(height: 14),

                    // Name
                    Text(displayName, style: GoogleFonts.spaceGrotesk(
                      fontSize: 22, fontWeight: FontWeight.w700, color: _kInk, letterSpacing: -0.5)),
                    const SizedBox(height: 4),
                    Text('@$username', style: GoogleFonts.inter(
                      fontSize: 14, color: _kMuted, fontWeight: FontWeight.w500)),

                    if (institution.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _kFieldTint, borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: _kFieldBorder)),
                        child: Text(institution, style: GoogleFonts.inter(
                          fontSize: 11, color: _kAccent, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ],
                ),
              ),

              // Stats row
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                child: Row(
                  children: [
                    _StatCard(value: '$xp', label: 'XP', icon: Icons.bolt_rounded, color: _kAccent),
                    const SizedBox(width: 10),
                    _StatCard(value: '$streak', label: 'Streak', icon: Icons.local_fire_department_rounded, color: const Color(0xFFEA580C)),
                    const SizedBox(width: 10),
                    _StatCard(
                      value: _loading ? '—' : '$_friendCount',
                      label: 'Friends',
                      icon: Icons.people_rounded,
                      color: const Color(0xFF0EA5E9),
                    ),
                    const SizedBox(width: 10),
                    _StatCard(
                      value: _loading ? '—' : '$_examCount',
                      label: 'Exams',
                      icon: Icons.school_rounded,
                      color: const Color(0xFF16A34A),
                    ),
                  ],
                ),
              ),

              if (_isFriend) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: _loading ? null : _confirmAndRemoveFriend,
                      icon: const Icon(Icons.person_remove_rounded, color: _kAccent, size: 18),
                      label: Text(
                        'Remove Friend',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          color: _kAccent,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFEDD5D8), width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        backgroundColor: const Color(0xFFFDF3F5),
                      ),
                    ),
                  ),
                ),
              ],

              // Bottom safe area
              SizedBox(height: MediaQuery.of(context).viewInsets.bottom + 8),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Stat card used inside profile sheet ────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;
  const _StatCard({required this.value, required this.label, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.07),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.18)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 6),
            Text(value, style: GoogleFonts.spaceGrotesk(
              fontSize: 16, fontWeight: FontWeight.w800, color: color)),
            const SizedBox(height: 2),
            Text(label, style: GoogleFonts.inter(
              fontSize: 10, color: _kMuted, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
