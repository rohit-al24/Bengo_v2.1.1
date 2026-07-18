import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const _kRolePlayBackground = Color(0xFF0F0F1A);
const _kRolePlaySurface = Color(0xFF151523);
const _kRolePlayAccent = Color(0xFFC41230);
const _kRolePlayMuted = Color(0xFF8D94A6);

enum RolePlayNavTab {
  home,
  create,
  history,
}

class RolePlayShell extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget body;
  final bool showBack;
  final VoidCallback? onBackTap;
  final RolePlayNavTab? selectedTab;
  final ValueChanged<RolePlayNavTab>? onNavTap;
  final bool showFooter;
  final Widget? rightAction;

  const RolePlayShell({
    super.key,
    required this.title,
    required this.body,
    this.subtitle,
    this.showBack = false,
    this.onBackTap,
    this.selectedTab,
    this.onNavTap,
    this.showFooter = true,
    this.rightAction,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kRolePlayBackground,
      body: SafeArea(
        child: Column(
          children: [
            _RolePlayHeader(
              title: title,
              subtitle: subtitle,
              showBack: showBack,
              onBackTap: onBackTap,
              rightAction: rightAction,
            ),
            Expanded(child: body),
          ],
        ),
      ),
      bottomNavigationBar: showFooter
          ? RolePlayFooterNav(
              selectedTab: selectedTab,
              onNavTap: onNavTap,
            )
          : null,
    );
  }
}

class _RolePlayHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool showBack;
  final VoidCallback? onBackTap;
  final Widget? rightAction;

  const _RolePlayHeader({
    required this.title,
    this.subtitle,
    this.showBack = false,
    this.onBackTap,
    this.rightAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1B1B1D), Color(0xFF8B0D21)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 20),
      child: Column(
        children: [
          Row(
            children: [
              if (showBack)
                InkWell(
                  onTap: onBackTap ?? () => Navigator.maybePop(context),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.arrow_back_rounded,
                        color: Colors.white, size: 22),
                  ),
                )
              else
                const SizedBox(width: 44),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        )),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(subtitle!,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.white70,
                          )),
                    ],
                  ],
                ),
              ),
              if (rightAction != null) ...[
                const SizedBox(width: 12),
                rightAction!,
              ] else
                const SizedBox(width: 44),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text('RolePlay',
                    style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white70,
                        letterSpacing: 1.2)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class RolePlayFooterNav extends StatelessWidget {
  final RolePlayNavTab? selectedTab;
  final ValueChanged<RolePlayNavTab>? onNavTap;

  const RolePlayFooterNav({
    super.key,
    this.selectedTab,
    this.onNavTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: _kRolePlaySurface,
        border: Border(top: BorderSide(color: Color(0xFF292A3B), width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 72,
          child: Row(
            children: [
              _RolePlayNavItem(
                icon: Icons.home_rounded,
                label: 'Home',
                selected: selectedTab == RolePlayNavTab.home,
                onTap: () => onNavTap?.call(RolePlayNavTab.home),
              ),
              _RolePlayNavItem(
                icon: Icons.meeting_room_rounded,
                label: 'Create',
                selected: selectedTab == RolePlayNavTab.create,
                onTap: () => onNavTap?.call(RolePlayNavTab.create),
              ),
              _RolePlayNavItem(
                icon: Icons.history_rounded,
                label: 'History',
                selected: selectedTab == RolePlayNavTab.history,
                onTap: () => onNavTap?.call(RolePlayNavTab.history),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RolePlayNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _RolePlayNavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon,
                  size: 22, color: selected ? Colors.white : Colors.white54),
              const SizedBox(height: 4),
              Text(label,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: selected ? Colors.white : Colors.white54,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                  )),
            ],
          ),
        ),
      ),
    );
  }
}
