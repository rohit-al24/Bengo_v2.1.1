/// Shared design tokens and components for all Clan screens.
/// Light-mode skeuomorphic design system.
library clan_theme;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ── Colour tokens ─────────────────────────────────────────────────────────────
const kClanBg      = Color(0xFFF5F0E8); // warm cream parchment
const kClanSurface = Color(0xFFFDFAF5); // paper white
const kClanAccent  = Color(0xFFC41230); // BenGo red
const kClanAccentL = Color(0xFFFFECEF); // light red tint
const kClanBorder  = Color(0xFFE2D8C8); // warm tan border
const kClanInk     = Color(0xFF1C1410); // dark warm ink
const kClanMuted   = Color(0xFF7C6A5A); // secondary text
const kClanGold    = Color(0xFFB8860B); // trophy/gold
const kClanGreen   = Color(0xFF2E7D32); // success
const kClanRed     = Color(0xFFC62828); // danger

// ── Shadow helpers ────────────────────────────────────────────────────────────

/// Standard raised card shadow (skeuomorphic lifted look)
List<BoxShadow> get kRaisedShadow => [
  const BoxShadow(color: Color(0x1A000000), blurRadius: 12, offset: Offset(0, 4)),
  const BoxShadow(color: Color(0x66FFFFFF), blurRadius: 2, offset: Offset(0, -1), spreadRadius: -1),
];

/// Subtle inner/inset shadow for engraved tracks
List<BoxShadow> get kInnerShadow => [
  const BoxShadow(color: Color(0x22000000), blurRadius: 4, offset: Offset(0, 2), spreadRadius: -1),
];

// ── Raised card ───────────────────────────────────────────────────────────────

class ClanCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? color;

  const ClanCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 16,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? kClanSurface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: kClanBorder, width: 1),
        boxShadow: kRaisedShadow,
      ),
      child: child,
    );
  }
}

// ── Skeuomorphic pill button ──────────────────────────────────────────────────

class ClanPillButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isDanger;
  final bool isOutlined;
  final IconData? icon;

  const ClanPillButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.isDanger = false,
    this.isOutlined = false,
    this.icon,
  });

  @override
  State<ClanPillButton> createState() => _ClanPillButtonState();
}

class _ClanPillButtonState extends State<ClanPillButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final base = widget.isDanger ? kClanRed : kClanAccent;
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) { setState(() => _pressed = false); widget.onPressed?.call(); },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        height: 48,
        decoration: BoxDecoration(
          color: widget.isOutlined ? Colors.transparent : (widget.onPressed == null ? base.withOpacity(0.4) : base),
          borderRadius: BorderRadius.circular(100),
          border: widget.isOutlined ? Border.all(color: base, width: 1.5) : null,
          boxShadow: widget.isOutlined || widget.onPressed == null ? [] : [
            BoxShadow(color: base.withOpacity(0.30), blurRadius: _pressed ? 2 : 8, offset: Offset(0, _pressed ? 1 : 4)),
          ],
        ),
        child: Center(
          child: widget.isLoading
              ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: widget.isOutlined ? base : Colors.white, strokeWidth: 2))
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.icon != null) ...[
                      Icon(widget.icon, color: widget.isOutlined ? base : Colors.white, size: 18),
                      const SizedBox(width: 6),
                    ],
                    Text(widget.label,
                      style: GoogleFonts.inter(
                        fontSize: 14, fontWeight: FontWeight.w700,
                        color: widget.isOutlined ? base : Colors.white,
                      )),
                  ],
                ),
        ),
      ),
    );
  }
}

// ── Section header ────────────────────────────────────────────────────────────

class ClanSectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;
  const ClanSectionHeader({super.key, required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(title,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 13, fontWeight: FontWeight.w700,
              color: kClanMuted, letterSpacing: 0.8,
            ),
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

// ── Engraved progress bar ─────────────────────────────────────────────────────

class ClanProgressBar extends StatelessWidget {
  final double value; // 0.0 – 1.0
  final Color? fillColor;
  final double height;
  final String? label;

  const ClanProgressBar({
    super.key,
    required this.value,
    this.fillColor,
    this.height = 12,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(label!, style: GoogleFonts.inter(fontSize: 11, color: kClanMuted)),
          const SizedBox(height: 4),
        ],
        Container(
          height: height,
          decoration: BoxDecoration(
            color: kClanBorder,
            borderRadius: BorderRadius.circular(height),
            boxShadow: [
              const BoxShadow(color: Color(0x22000000), blurRadius: 3, offset: Offset(0, 1), spreadRadius: -1),
            ],
          ),
          child: FractionallySizedBox(
            widthFactor: value.clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  (fillColor ?? kClanAccent).withOpacity(0.9),
                  fillColor ?? kClanAccent,
                ]),
                borderRadius: BorderRadius.circular(height),
                boxShadow: [
                  BoxShadow(color: (fillColor ?? kClanAccent).withOpacity(0.4), blurRadius: 4, offset: const Offset(0, 2)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Stat chip ─────────────────────────────────────────────────────────────────

class ClanStatChip extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const ClanStatChip({super.key, required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: kClanAccent, size: 20),
        const SizedBox(height: 2),
        Text(value, style: GoogleFonts.spaceGrotesk(fontSize: 16, fontWeight: FontWeight.w700, color: kClanInk)),
        Text(label, style: GoogleFonts.inter(fontSize: 10, color: kClanMuted)),
      ],
    );
  }
}

// ── Combo badge ───────────────────────────────────────────────────────────────

class ComboBadge extends StatelessWidget {
  final int combo;
  const ComboBadge({super.key, required this.combo});

  @override
  Widget build(BuildContext context) {
    if (combo < 2) return const SizedBox.shrink();
    final Color col = combo >= 7 ? kClanGold : combo >= 4 ? const Color(0xFFE65100) : kClanAccent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: col.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: col.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.local_fire_department_rounded, color: col, size: 14),
          const SizedBox(width: 3),
          Text('×$combo', style: GoogleFonts.spaceGrotesk(fontSize: 13, fontWeight: FontWeight.w800, color: col)),
        ],
      ),
    );
  }
}
