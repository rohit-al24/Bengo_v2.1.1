import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ── Avatar catalogue — 15 real image assets ────────────────────────────────
class BenGoAvatarDef {
  final String id;       // 'av1' … 'av15'
  final String label;    // display name
  final String asset;    // path inside assets/avatars/
  // Accent / shadow colour derived from filename index
  final Color shadow;

  const BenGoAvatarDef({
    required this.id,
    required this.label,
    required this.asset,
    required this.shadow,
  });
}

const kAllAvatars = <BenGoAvatarDef>[
  BenGoAvatarDef(id: 'av1',  label: 'Avatar 1',  asset: 'assets/avatars/av1.png',  shadow: Color(0xFFC41230)),
  BenGoAvatarDef(id: 'av2',  label: 'Avatar 2',  asset: 'assets/avatars/av2.png',  shadow: Color(0xFF7C3AED)),
  BenGoAvatarDef(id: 'av3',  label: 'Avatar 3',  asset: 'assets/avatars/av3.png',  shadow: Color(0xFF0EA5E9)),
  BenGoAvatarDef(id: 'av4',  label: 'Avatar 4',  asset: 'assets/avatars/av4.png',  shadow: Color(0xFF16A34A)),
  BenGoAvatarDef(id: 'av5',  label: 'Avatar 5',  asset: 'assets/avatars/av5.png',  shadow: Color(0xFFEA580C)),
  BenGoAvatarDef(id: 'av6',  label: 'Avatar 6',  asset: 'assets/avatars/av6.png',  shadow: Color(0xFFDB2777)),
  BenGoAvatarDef(id: 'av7',  label: 'Avatar 7',  asset: 'assets/avatars/av7.png',  shadow: Color(0xFF0D9488)),
  BenGoAvatarDef(id: 'av8',  label: 'Avatar 8',  asset: 'assets/avatars/av8.png',  shadow: Color(0xFF9333EA)),
  BenGoAvatarDef(id: 'av9',  label: 'Avatar 9',  asset: 'assets/avatars/av9.png',  shadow: Color(0xFFC41230)),
  BenGoAvatarDef(id: 'av10', label: 'Avatar 10', asset: 'assets/avatars/av10.png', shadow: Color(0xFF2563EB)),
  BenGoAvatarDef(id: 'av11', label: 'Avatar 11', asset: 'assets/avatars/av11.png', shadow: Color(0xFF65A30D)),
  BenGoAvatarDef(id: 'av12', label: 'Avatar 12', asset: 'assets/avatars/av12.png', shadow: Color(0xFFD97706)),
  BenGoAvatarDef(id: 'av13', label: 'Avatar 13', asset: 'assets/avatars/av13.png', shadow: Color(0xFFE11D48)),
  BenGoAvatarDef(id: 'av14', label: 'Avatar 14', asset: 'assets/avatars/av14.png', shadow: Color(0xFF0891B2)),
  BenGoAvatarDef(id: 'av15', label: 'Avatar 15', asset: 'assets/avatars/av15.png', shadow: Color(0xFF7C3AED)),
];

BenGoAvatarDef avatarById(String? id) {
  return kAllAvatars.firstWhere(
    (a) => a.id == id,
    orElse: () => kAllAvatars.first,
  );
}

// ── Legacy alias so other files still compile ──────────────────────────────
// (dashboard & profile used kAvatarCategories — no longer needed)

// ═══════════════════════════════════════════════════════════════════════════════
// BenGoAvatar — square squircle card (used in header, dashboard, profile)
// ═══════════════════════════════════════════════════════════════════════════════

class BenGoAvatar extends StatelessWidget {
  final String? avatarId;
  final double size;
  final bool showRing;
  final bool selected;

  const BenGoAvatar({
    super.key,
    this.avatarId,
    this.size = 48,
    this.showRing = false,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    final def = avatarById(avatarId);
    final radius = size * 0.26; // squircle curve ratio

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          // 3D elevation shadow
          BoxShadow(
            color: def.shadow.withOpacity(selected ? 0.52 : 0.28),
            blurRadius: selected ? 22 : 12,
            offset: Offset(0, selected ? 8 : 5),
            spreadRadius: selected ? 1 : 0,
          ),
          // Ambient under-glow
          if (selected)
            BoxShadow(
              color: def.shadow.withOpacity(0.18),
              blurRadius: 40,
              spreadRadius: 4,
            ),
        ],
        border: selected
            ? Border.all(color: Colors.white, width: 2.5)
            : (showRing
                ? Border.all(
                    color: def.shadow.withOpacity(0.5), width: 2)
                : null),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Image.asset(
          def.asset,
          fit: BoxFit.cover,
          width: size,
          height: size,
          errorBuilder: (_, __, ___) => Container(
            color: def.shadow.withOpacity(0.15),
            child: Icon(Icons.person, size: size * 0.5, color: def.shadow),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// BenGoAvatarPicker — 3-column image grid, no categories
// ═══════════════════════════════════════════════════════════════════════════════

class BenGoAvatarPicker extends StatelessWidget {
  final String? selectedId;
  final ValueChanged<String> onSelect;

  const BenGoAvatarPicker({
    super.key,
    this.selectedId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 1.0,
      ),
      itemCount: kAllAvatars.length,
      itemBuilder: (_, i) {
        final av = kAllAvatars[i];
        final isSelected = av.id == selectedId;
        return GestureDetector(
          onTap: () => onSelect(av.id),
          child: _AvatarCard(def: av, isSelected: isSelected),
        );
      },
    );
  }
}

// ── Individual card in the picker grid ────────────────────────────────────────
class _AvatarCard extends StatefulWidget {
  final BenGoAvatarDef def;
  final bool isSelected;
  const _AvatarCard({required this.def, required this.isSelected});

  @override
  State<_AvatarCard> createState() => _AvatarCardState();
}

class _AvatarCardState extends State<_AvatarCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _scale = Tween<double>(begin: 1.0, end: 1.06)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack));
  }

  @override
  void didUpdateWidget(_AvatarCard old) {
    super.didUpdateWidget(old);
    if (widget.isSelected && !old.isSelected) {
      _ctrl.forward().then((_) => _ctrl.reverse());
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final def = widget.def;
    final sel = widget.isSelected;

    return AnimatedBuilder(
      animation: _scale,
      builder: (_, child) =>
          Transform.scale(scale: _scale.value, child: child),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          // 3D lift: stronger shadow when selected
          boxShadow: [
            BoxShadow(
              color: def.shadow.withOpacity(sel ? 0.48 : 0.18),
              blurRadius: sel ? 20 : 10,
              offset: Offset(0, sel ? 8 : 4),
              spreadRadius: sel ? 1 : 0,
            ),
            if (sel)
              BoxShadow(
                color: def.shadow.withOpacity(0.14),
                blurRadius: 36,
                spreadRadius: 4,
              ),
          ],
          // Selection outline — white inner ring
          border: sel
              ? Border.all(color: def.shadow, width: 2.5)
              : Border.all(color: Colors.transparent, width: 2.5),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              // Avatar image — fills the square
              Positioned.fill(
                child: Image.asset(
                  def.asset,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: def.shadow.withOpacity(0.12),
                    child: Icon(Icons.person,
                        size: 36, color: def.shadow.withOpacity(0.5)),
                  ),
                ),
              ),

              // Top-left shimmer highlight (3D top-face light)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 36,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withOpacity(0.18),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              // Selected check badge
              if (sel)
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: def.shadow,
                      shape: BoxShape.circle,
                      border:
                          Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: def.shadow.withOpacity(0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      size: 13,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
