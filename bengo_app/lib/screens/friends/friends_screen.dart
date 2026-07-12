import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_decorations.dart';
import '../../utils/app_text_styles.dart';
import '../../widgets/bengo_app_bar.dart';
import '../../services/api_service.dart';
import '../../widgets/bottom_nav.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  final _searchCtrl = TextEditingController();

  List<dynamic> _friends = [];
  List<dynamic> _incoming = [];
  List<dynamic> _suggested = [];
  List<dynamic> _searchResults = [];

  bool _loading = true;
  bool _searching = false;
  String _error = '';

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
    setState(() {
      _loading = true;
      _error = '';
    });
    try {
      final futs = await Future.wait([
        ApiService.instance.getFriends(),
        ApiService.instance.getIncomingRequests(),
        ApiService.instance.searchUsers(''), // empty = suggested
      ]);
      setState(() {
        _friends = futs[0];
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
      setState(() {
        _searchResults = [];
        _searching = false;
      });
      return;
    }
    setState(() => _searching = true);
    try {
      final res = await ApiService.instance.searchUsers(q);
      if (mounted)
        setState(() {
          _searchResults = res;
          _searching = false;
        });
    } catch (_) {
      if (mounted) setState(() => _searching = false);
    }
  }

  Future<void> _acceptRequest(int id) async {
    try {
      await ApiService.instance.acceptFriendRequest(id);
      _loadAll();
    } catch (_) {}
  }

  Future<void> _rejectRequest(int id) async {
    try {
      await ApiService.instance.rejectFriendRequest(id);
      _loadAll();
    } catch (_) {}
  }

  Future<void> _sendRequest(int toUserId) async {
    try {
      await ApiService.instance.sendFriendRequest(toUserId);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Friend request sent!'),
          backgroundColor: AppColors.primary));
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      bottomNavigationBar: BenGoBottomNav(
        currentIndex: 3, // Profile tab (friends is sub-page of profile)
        onTap: (i) {
          if (i != 3) Navigator.of(context).popUntil((r) => r.isFirst);
        },
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadAll,
          color: AppColors.primary,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _buildAppBar(context)),
              SliverToBoxAdapter(child: _buildSearchBar()),

              // Error banner
              if (_error.isNotEmpty)
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.orange.withOpacity(0.3)),
                    ),
                    child: Text(_error, style: AppTextStyles.bodySmall),
                  ),
                ),

              // Search results
              if (_searchCtrl.text.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
                    child: Text('Search Results',
                        style: AppTextStyles.headlineLarge),
                  ),
                ),
                if (_searching)
                  const SliverToBoxAdapter(
                    child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(
                            child: CircularProgressIndicator(
                                color: AppColors.primary))),
                  )
                else if (_searchResults.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Text('No users found.',
                          style: AppTextStyles.bodyMedium),
                    ),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => _buildSearchTile(_searchResults[i]),
                      childCount: _searchResults.length,
                    ),
                  ),
              ]

              // Normal content
              else if (_loading)
                const SliverToBoxAdapter(
                  child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                          child: CircularProgressIndicator(
                              color: AppColors.primary))),
                )
              else ...[
                // Incoming requests card
                if (_incoming.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: _buildIncomingHeader(),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: _buildFeaturedRequest(_incoming.first),
                    ),
                  ),
                ],

                // Friends list
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                    child: Text('Friends', style: AppTextStyles.headlineLarge),
                  ),
                ),
                if (_friends.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Text('No friends yet — search and add some!',
                          style: AppTextStyles.bodyMedium),
                    ),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => _buildFriendTile(_friends[i]),
                      childCount: _friends.length,
                    ),
                  ),

                // Suggested
                if (_suggested.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                      child:
                          Text('Suggested', style: AppTextStyles.headlineLarge),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                      child: _buildSuggestedRow(),
                    ),
                  ),
                ],
              ],

              const SliverToBoxAdapter(child: SizedBox(height: 20)),
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
              width: 40,
              height: 40,
              decoration: AppDecorations.skeuomorphicCard(radius: 14),
              child: const Icon(Icons.people_outline_rounded,
                  color: AppColors.textSecondary, size: 22),
            ),
            if (_incoming.isNotEmpty)
              Positioned(
                top: -4,
                right: -4,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.red.shade400,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  child: Center(
                    child: Text(
                      '${_incoming.length}',
                      style: GoogleFonts.inter(
                        fontSize: 8,
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
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
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.bgWhite,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)
          ],
        ),
        child: TextField(
          controller: _searchCtrl,
          style: AppTextStyles.bodyMedium,
          decoration: InputDecoration(
            prefixIcon:
                const Icon(Icons.search, color: AppColors.textMuted, size: 20),
            hintText: 'Find usernames...',
            hintStyle: AppTextStyles.bodyMedium,
            border: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            suffixIcon: _searchCtrl.text.isNotEmpty
                ? GestureDetector(
                    onTap: () {
                      _searchCtrl.clear();
                      setState(() => _searchResults = []);
                    },
                    child: const Icon(Icons.close,
                        color: AppColors.textMuted, size: 18))
                : null,
          ),
        ),
      ),
    );
  }

  // ── Incoming requests header ─────────────────────────────────────────────────
  Widget _buildIncomingHeader() {
    return Row(
      children: [
        Expanded(
            child:
                Text('Incoming Requests', style: AppTextStyles.headlineLarge)),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
              color: Colors.pink.shade400,
              borderRadius: BorderRadius.circular(20)),
          child: Text('${_incoming.length} NEW',
              style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 0.5)),
        ),
      ],
    );
  }

  // ── Featured incoming request card ───────────────────────────────────────────
  Widget _buildFeaturedRequest(dynamic req) {
    final fromUser = req['from_user'] as Map<String, dynamic>? ?? {};
    final username = fromUser['username']?.toString() ?? 'Unknown';
    final reqId = req['id'] as int? ?? 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFC8E6C9), Color(0xFFA5D6A7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.topRight,
            children: [
              CircleAvatar(
                radius: 36,
                backgroundColor: Colors.white.withOpacity(0.6),
                child: const Icon(Icons.person,
                    size: 38, color: Color(0xFF388E3C)),
              ),
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                    color: Colors.red.shade400,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2)),
                child:
                    const Icon(Icons.person_add, color: Colors.white, size: 12),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text('New Study Request',
              style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1B5E20))),
          const SizedBox(height: 4),
          Text('@$username wants to join your network',
              style: GoogleFonts.inter(
                  fontSize: 12, color: const Color(0xFF2E7D32)),
              textAlign: TextAlign.center),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _acceptRequest(reqId),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF388E3C),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                        child: Text('Accept',
                            style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Colors.white))),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: () => _rejectRequest(reqId),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                        child: Text('Reject',
                            style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF388E3C)))),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Real friend tile ─────────────────────────────────────────────────────────
  Widget _buildFriendTile(dynamic friendship) {
    final friend = friendship['friend'] as Map<String, dynamic>? ?? {};
    final name = friend['username']?.toString() ?? 'Unknown';
    final isOnline = friendship['is_online'] as bool? ?? false;
    final xp = friend['xp'] as int? ?? 0;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgWhite,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)
        ],
      ),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.primary.withOpacity(0.1),
                child: const Icon(Icons.person,
                    color: AppColors.primary, size: 24),
              ),
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isOnline ? AppColors.online : AppColors.offline,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: AppTextStyles.headlineSmall,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1),
                const SizedBox(height: 2),
                Text(isOnline ? '● Online' : 'Offline',
                    style: GoogleFonts.inter(
                        fontSize: 11,
                        color:
                            isOnline ? AppColors.online : AppColors.textMuted,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('$xp XP',
                  style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Row(children: [
                Text('View Profile',
                    style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary)),
                const SizedBox(width: 3),
                const Icon(Icons.arrow_forward,
                    color: AppColors.primary, size: 13),
              ]),
            ],
          ),
        ],
      ),
    );
  }

  // ── Search result tile ───────────────────────────────────────────────────────
  Widget _buildSearchTile(dynamic user) {
    final name = user['username']?.toString() ?? '';
    final id = user['id'] as int? ?? 0;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgWhite,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.primary.withOpacity(0.1),
            child: const Icon(Icons.person, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
              child: Text('@$name',
                  style: AppTextStyles.headlineSmall,
                  overflow: TextOverflow.ellipsis)),
          GestureDetector(
            onTap: () => _sendRequest(id),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text('Add',
                  style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Suggested horizontal row ──────────────────────────────────────────────────
  Widget _buildSuggestedRow() {
    final items = _suggested.isEmpty
        ? [
            {'username': 'Ren_02', 'sub': 'In Your\nNetwork'},
            {'username': 'Aoi_Study', 'sub': 'Mutual Friend'},
            {'username': 'Nami_K', 'sub': 'JLPT N5'},
          ]
        : _suggested;

    return SizedBox(
      height: 140,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          final s = items[i] as Map<String, dynamic>;
          final name =
              s['username']?.toString() ?? s['name']?.toString() ?? 'User';
          final sub = s['sub']?.toString() ?? 'Suggested';
          final id = s['id'] as int?;

          return Container(
            width: 115,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.bgWhite,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                    radius: 22,
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    child: const Icon(Icons.person,
                        color: AppColors.primary, size: 22)),
                const SizedBox(height: 6),
                Text(name,
                    style: AppTextStyles.labelMedium
                        .copyWith(color: AppColors.textPrimary),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    textAlign: TextAlign.center),
                Text(sub,
                    style: AppTextStyles.bodySmall,
                    textAlign: TextAlign.center,
                    maxLines: 2),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: id != null ? () => _sendRequest(id) : null,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.primary),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('Add',
                        style: GoogleFonts.inter(
                            fontSize: 11,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
