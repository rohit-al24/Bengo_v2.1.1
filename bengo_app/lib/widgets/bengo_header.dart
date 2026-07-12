import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';
import '../utils/app_decorations.dart';
import '../services/api_service.dart';
import '../screens/leaderboard/leaderboard_screen.dart';

class BenGoHeader extends StatefulWidget {
  final bool isSubPage;
  final VoidCallback? onBackTap;
  final Widget? rightActions;

  const BenGoHeader({
    super.key,
    this.isSubPage = false,
    this.onBackTap,
    this.rightActions,
  });

  @override
  State<BenGoHeader> createState() => _BenGoHeaderState();
}

class _BenGoHeaderState extends State<BenGoHeader> {
  @override
  void initState() {
    super.initState();
    if (ApiService.instance.currentUserNotifier.value == null) {
      ApiService.instance.getMe();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Map<String, dynamic>?>(
      valueListenable: ApiService.instance.currentUserNotifier,
      builder: (context, user, _) {
        final streak = user?['streak_days'] ?? 0;
        final xp = user?['xp'] ?? 0;
        final username = user?['username']?.toString() ?? '';
        final avatarLetter =
            username.isNotEmpty ? username[0].toUpperCase() : '';

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Container(
            decoration:
                AppDecorations.softPanel(color: AppColors.bgWhite, radius: 24),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  // Left portion: Avatar + Stats (or Back button + Stats)
                  if (widget.isSubPage) ...[
                    GestureDetector(
                      onTap: widget.onBackTap ?? () => Navigator.pop(context),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: AppDecorations.skeuomorphicCard(radius: 14),
                        child: const Icon(
                          Icons.arrow_back_rounded,
                          size: 22,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$streak DAYS',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(
                          '$xp XP',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: AppColors.primary.withAlpha(77),
                            width: 1.5),
                        color: AppColors.primary.withAlpha(23),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(20),
                            offset: const Offset(0, 10),
                            blurRadius: 18,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          avatarLetter.isNotEmpty ? avatarLetter : 'U',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$streak DAYS',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(
                          '$xp XP',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ],

                  const Spacer(),
                  // Center: Logo text
                  Text(
                    'BenGo',
                    style: AppTextStyles.brandNameSmall.copyWith(fontSize: 24),
                  ),
                  const Spacer(),

                  // Right portion: Pill Actions or custom actions
                  widget.rightActions ??
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GestureDetector(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                    builder: (_) => const LeaderboardScreen()),
                              );
                            },
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration:
                                  AppDecorations.skeuomorphicCard(radius: 14),
                              child: const Icon(
                                Icons.bar_chart_rounded,
                                color: AppColors.textSecondary,
                                size: 22,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            width: 40,
                            height: 40,
                            decoration:
                                AppDecorations.skeuomorphicCard(radius: 14),
                            child: const Icon(
                              Icons.notifications_outlined,
                              color: AppColors.textSecondary,
                              size: 22,
                            ),
                          ),
                        ],
                      ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
