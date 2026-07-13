import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import '../screens/friends/friends_screen.dart';
import '../screens/daily_revision/daily_revision_screen.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  // Navigation key to access overlay and context anywhere
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  // Notifiers for widgets to listen to
  final ValueNotifier<int> pendingRequestsNotifier = ValueNotifier(0);
  final ValueNotifier<int> newRequestAnimationTrigger = ValueNotifier(0);

  // Cache to track seen friend request IDs to prevent duplicate alerts
  final Set<int> _seenRequestIds = {};
  bool _isInitialLoad = true;

  // Cache to track seen friend IDs to prevent duplicate accepted request alerts
  final Set<int> _seenFriendIds = {};
  bool _isFriendsInitialLoad = true;

  Timer? _pollingTimer;

  // Initialize service, start periodic polls
  void init() {
    _pollingTimer?.cancel();
    _isInitialLoad = true;
    _isFriendsInitialLoad = true;
    _seenRequestIds.clear();
    _seenFriendIds.clear();

    // Start polling every 15 seconds
    _pollingTimer = Timer.periodic(const Duration(seconds: 15), (_) => performChecks());
    // Initial check
    Timer(const Duration(seconds: 3), () => performChecks());
  }

  void dispose() {
    _pollingTimer?.cancel();
  }

  // Periodic checks for friend requests & daily revision
  Future<void> performChecks() async {
    await checkFriendRequests();
    await checkAcceptedFriendRequests();
    await checkDailyRevision();
  }

  // Poll friend requests and show notifications + trigger animations
  Future<void> checkFriendRequests() async {
    try {
      final incoming = await ApiService.instance.getIncomingRequests();
      pendingRequestsNotifier.value = incoming.length;

      bool foundNew = false;
      String newSenderUsername = 'Someone';

      for (var req in incoming) {
        final id = req['id'] as int? ?? 0;
        if (!_seenRequestIds.contains(id)) {
          _seenRequestIds.add(id);
          foundNew = true;
          final fromUser = req['from_user'] as Map<String, dynamic>? ?? {};
          newSenderUsername = fromUser['username']?.toString() ?? 'Someone';
        }
      }

      if (foundNew) {
        if (!_isInitialLoad) {
          // Trigger +1 animation in header
          newRequestAnimationTrigger.value++;
          
          // Show overlay notification
          showNotification(
            title: 'New Friend Request',
            message: '@$newSenderUsername sent you a study request!',
            icon: Icons.person_add_rounded,
            onTap: () {
              navigatorKey.currentState?.push(
                MaterialPageRoute(builder: (_) => const FriendsScreen()),
              );
            },
          );
        }
      }
      _isInitialLoad = false;
    } catch (_) {}
  }

  // Poll accepted friend requests
  Future<void> checkAcceptedFriendRequests() async {
    try {
      final friends = await ApiService.instance.getFriends();
      bool foundNew = false;
      String newFriendUsername = 'Someone';

      for (var f in friends) {
        final friendUser = f['friend'] as Map<String, dynamic>? ?? {};
        final friendId = friendUser['id'] as int? ?? 0;
        if (friendId != 0 && !_seenFriendIds.contains(friendId)) {
          _seenFriendIds.add(friendId);
          foundNew = true;
          newFriendUsername = friendUser['username']?.toString() ?? 'Someone';
        }
      }

      if (foundNew) {
        if (!_isFriendsInitialLoad) {
          // Show overlay notification
          showNotification(
            title: 'Friend Request Accepted',
            message: '@$newFriendUsername accepted your friend request!',
            icon: Icons.people_rounded,
            onTap: () {
              navigatorKey.currentState?.push(
                MaterialPageRoute(builder: (_) => const FriendsScreen()),
              );
            },
          );
        }
      }
      _isFriendsInitialLoad = false;
    } catch (_) {}
  }

  // Check if daily revision is available and prompt user
  Future<void> checkDailyRevision() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final todayStr = DateTime.now().toIso8601String().substring(0, 10); // "YYYY-MM-DD"
      final lastNotifiedDate = prefs.getString('last_revision_notif_date');

      // If we already notified today, skip
      if (lastNotifiedDate == todayStr) return;

      // Check revision availability
      final session = await ApiService.instance.getDailyRevisionSession();
      final questions = session['questions'] as List? ?? [];
      final attemptsToday = session['attempts_today'] as int? ?? 0;
      final attemptLimit = session['attempt_limit'] as int? ?? 1;

      if (questions.isNotEmpty && attemptsToday < attemptLimit) {
        // Formulate hourly greeting
        final hour = DateTime.now().hour;
        String greeting;
        if (hour >= 5 && hour < 12) {
          greeting = 'Good Morning';
        } else if (hour >= 12 && hour < 18) {
          greeting = 'Good Afternoon';
        } else {
          greeting = 'Good Evening';
        }

        // Fetch user profile username if cached
        String name = '';
        final me = ApiService.instance.currentUserNotifier.value;
        if (me != null) {
          name = me['first_name']?.toString() ?? me['username']?.toString() ?? '';
        }
        final displayName = name.isNotEmpty ? ', $name' : '';

        // Save last notified date so we only notify once per day
        await prefs.setString('last_revision_notif_date', todayStr);

        showNotification(
          title: '$greeting$displayName!',
          message: 'Your Daily Revision is ready. Tap to boost your recall!',
          icon: Icons.repeat_rounded,
          onTap: () {
            navigatorKey.currentState?.push(
              MaterialPageRoute(builder: (_) => const DailyRevisionScreen()),
            );
          },
        );
      }
    } catch (_) {}
  }

  // Show a beautifully animated in-app notification overlay
  void showNotification({
    required String title,
    required String message,
    required IconData icon,
    VoidCallback? onTap,
  }) {
    final overlayState = navigatorKey.currentState?.overlay;
    if (overlayState == null) return;

    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => _NotificationOverlay(
        title: title,
        message: message,
        icon: icon,
        onTap: () {
          overlayEntry.remove();
          onTap?.call();
        },
        onDismiss: () => overlayEntry.remove(),
      ),
    );

    overlayState.insert(overlayEntry);
  }
}

class _NotificationOverlay extends StatefulWidget {
  final String title;
  final String message;
  final IconData icon;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const _NotificationOverlay({
    required this.title,
    required this.message,
    required this.icon,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  State<_NotificationOverlay> createState() => _NotificationOverlayState();
}

class _NotificationOverlayState extends State<_NotificationOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<Offset> _slideAnim;
  Timer? _dismissTimer;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _slideAnim = Tween<Offset>(
      begin: const Offset(0, -1.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack));

    _ctrl.forward();

    // Auto dismiss after 4.5 seconds
    _dismissTimer = Timer(const Duration(milliseconds: 4500), _hide);
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  void _hide() {
    if (mounted) {
      _ctrl.reverse().then((_) {
        widget.onDismiss();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWeb = MediaQuery.of(context).size.width > 600;
    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: SlideTransition(
          position: _slideAnim,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: isWeb ? 450 : double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFEDE9F4), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: InkWell(
                    onTap: widget.onTap,
                    borderRadius: BorderRadius.circular(18),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFDF3F5),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFEDD5D8)),
                            ),
                            child: Icon(widget.icon, color: const Color(0xFFC41230), size: 22),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.title,
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF1B1B1D),
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  widget.message,
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: const Color(0xFF8A8A8F),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, size: 18, color: Color(0xFF8A8A8F)),
                            onPressed: _hide,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
