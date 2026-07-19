import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'clan_theme.dart';
import '../../services/api_service.dart';

class ClanCreationScreen extends StatefulWidget {
  const ClanCreationScreen({super.key});

  @override
  State<ClanCreationScreen> createState() => _ClanCreationScreenState();
}

class _ClanCreationScreenState extends State<ClanCreationScreen>
    with SingleTickerProviderStateMixin {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  String _selectedBadge = '⚔️';
  String _selectedBanner = 'red_wave';
  String _privacy = 'open';
  int _minJoinTrophies = 0;

  // Real requirements
  int get _userXP {
    final user = ApiService.instance.currentUserNotifier.value;
    if (user != null && user.containsKey('xp')) {
      return (user['xp'] as num).toInt();
    }
    return 0;
  }
  final int _requiredXP = 20000;
  final int _initialSlots = 3;

  bool _creating = false;
  bool _created = false;

  late AnimationController _celebController;
  late Animation<double> _celebAnim;

  final _badges = ['⚔️', '🐉', '🦅', '🌸', '⛩️', '🔥', '💎', '🌙', '☀️', '🏯'];
  final _banners = [
    ('red_wave', '🔴 Red Wave'),
    ('blue_mist', '🔵 Blue Mist'),
    ('gold_sun', '🟡 Gold Sun'),
    ('dark_moon', '⚫ Dark Moon'),
    ('sakura', '🌸 Sakura'),
  ];

  @override
  void initState() {
    super.initState();
    _celebController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));
    _celebAnim = CurvedAnimation(parent: _celebController, curve: Curves.elasticOut);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _celebController.dispose();
    super.dispose();
  }

  bool get _canCreate =>
      _userXP >= _requiredXP &&
      _nameCtrl.text.trim().length >= 3;

  Future<void> _create() async {
    if (!_canCreate) return;
    setState(() => _creating = true);
    await Future.delayed(const Duration(milliseconds: 800));
    setState(() {
      _creating = false;
      _created = true;
    });
    _celebController.forward();
  }

  @override
  Widget build(BuildContext context) {
    if (_created) return _buildConfirmation();

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Create a Clan',
            style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Requirements checklist
            _buildRequirementsCard(),
            const SizedBox(height: 20),
            // Form
            _buildFormCard(),
            const SizedBox(height: 20),
            // Badge picker
            _buildBadgePicker(),
            const SizedBox(height: 20),
            // Banner picker
            _buildBannerPicker(),
            const SizedBox(height: 20),
            // Privacy selector
            _buildPrivacySelector(),
            const SizedBox(height: 20),
            // Min trophies
            _buildMinTrophiesSlider(),
            const SizedBox(height: 28),
            // Create button
            AnimatedOpacity(
              opacity: _canCreate ? 1.0 : 0.5,
              duration: const Duration(milliseconds: 300),
              child: GestureDetector(
                onTap: _create,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  decoration: BoxDecoration(
                    gradient: _canCreate
                        ? const LinearGradient(
                            colors: [Color(0xFFEB4B6E), Color(0xFFBF1B2C)])
                        : null,
                    color: _canCreate ? null : Colors.white12,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: _canCreate
                        ? [
                            BoxShadow(
                              color: const Color(0xFFBF1B2C).withOpacity(0.4),
                              blurRadius: 20,
                              offset: const Offset(0, 6),
                            )
                          ]
                        : null,
                  ),
                  child: Center(
                    child: _creating
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : Text(
                            '⚔️  Found the Clan',
                            style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Colors.white),
                          ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildRequirementsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kClanBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Requirements',
              style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white70)),
          const SizedBox(height: 12),
          _RequirementRow(
            label: 'XP',
            current: _userXP,
            required: _requiredXP,
            met: _userXP >= _requiredXP,
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kClanBorder),
      ),
      child: Column(
        children: [
          _DarkTextField(
            controller: _nameCtrl,
            label: 'Clan Name',
            hint: 'Samurai Rising',
            maxLength: 24,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 14),
          _DarkTextField(
            controller: _descCtrl,
            label: 'Description',
            hint: 'We fight with honor...',
            maxLength: 200,
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildBadgePicker() {
    return _SectionCard(
      title: 'Clan Badge',
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _badges.map((b) {
          final selected = b == _selectedBadge;
          return GestureDetector(
            onTap: () => setState(() => _selectedBadge = b),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: selected
                    ? kClanAccent.withOpacity(0.2)
                    : Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: selected ? kClanAccent : kClanBorder,
                  width: selected ? 2 : 1,
                ),
              ),
              child: Center(child: Text(b, style: const TextStyle(fontSize: 24))),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBannerPicker() {
    return _SectionCard(
      title: 'Clan Banner',
      child: Column(
        children: _banners.map((b) {
          final selected = b.$1 == _selectedBanner;
          return GestureDetector(
            onTap: () => setState(() => _selectedBanner = b.$1),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: selected
                    ? kClanAccent.withOpacity(0.12)
                    : Colors.white.withOpacity(0.04),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: selected ? kClanAccent : kClanBorder),
              ),
              child: Row(
                children: [
                  Text(b.$2, style: GoogleFonts.inter(fontSize: 14, color: Colors.white)),
                  const Spacer(),
                  if (selected)
                    const Icon(Icons.check_circle, color: kClanAccent, size: 18),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPrivacySelector() {
    return _SectionCard(
      title: 'Privacy',
      child: Column(
        children: [
          _PrivacyOption(
            value: 'open',
            selected: _privacy == 'open',
            label: 'Open',
            desc: 'Anyone meeting trophy requirements can join instantly',
            icon: '🌐',
            onTap: () => setState(() => _privacy = 'open'),
          ),
          const SizedBox(height: 8),
          _PrivacyOption(
            value: 'invite_only',
            selected: _privacy == 'invite_only',
            label: 'Invite Only',
            desc: 'Players can request to join; leaders approve',
            icon: '🔔',
            onTap: () => setState(() => _privacy = 'invite_only'),
          ),
          const SizedBox(height: 8),
          _PrivacyOption(
            value: 'closed',
            selected: _privacy == 'closed',
            label: 'Closed',
            desc: 'Invite-out only; no join requests accepted',
            icon: '🔒',
            onTap: () => setState(() => _privacy = 'closed'),
          ),
        ],
      ),
    );
  }

  Widget _buildMinTrophiesSlider() {
    return _SectionCard(
      title: 'Minimum Trophies to Join',
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('🏆 $_minJoinTrophies trophies',
                  style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white)),
            ],
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: kClanAccent,
              inactiveTrackColor: Colors.white12,
              thumbColor: Colors.white,
              overlayColor: kClanAccent.withOpacity(0.2),
            ),
            child: Slider(
              value: _minJoinTrophies.toDouble(),
              min: 0,
              max: 2000,
              divisions: 40,
              onChanged: (v) => setState(() => _minJoinTrophies = v.round()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmation() {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      body: SafeArea(
        child: ScaleTransition(
          scale: _celebAnim,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('🎉', style: TextStyle(fontSize: 80)),
                  const SizedBox(height: 24),
                  Text(
                    'Clan Founded!',
                    style: GoogleFonts.inter(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '"${_nameCtrl.text}" is live.\nYour clan starts with $_initialSlots member slots.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                        fontSize: 15, color: Colors.white54, height: 1.6),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: kClanBorder),
                    ),
                    child: Text(
                      '🏰 Grow your clan trophies together to unlock more slots, up to 10.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                          fontSize: 13, color: Colors.white60, height: 1.5),
                    ),
                  ),
                  const SizedBox(height: 32),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 40, vertical: 16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            colors: [Color(0xFFEB4B6E), Color(0xFFBF1B2C)]),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text('Enter Your Kingdom',
                          style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Sub-widgets ──────────────────────────────────────────────────────────────

class _RequirementRow extends StatelessWidget {
  final String label;
  final int current;
  final int required;
  final bool met;
  final bool isCoins;

  const _RequirementRow({
    required this.label,
    required this.current,
    required this.required,
    required this.met,
    this.isCoins = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${isCoins ? '🪙' : '✨'} $label: ${_fmt(current)} / ${_fmt(required)}',
              style: GoogleFonts.inter(
                  fontSize: 12,
                  color: met ? Colors.white70 : Colors.orange),
            ),
            Icon(
              met ? Icons.check_circle : Icons.cancel,
              color: met ? const Color(0xFF4CAF50) : Colors.orange,
              size: 16,
            ),
          ],
        ),
        if (!met) ...[
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (current / required).clamp(0.0, 1.0),
              backgroundColor: kClanBorder,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Colors.orange),
              minHeight: 5,
            ),
          ),
        ],
      ],
    );
  }

  String _fmt(int n) =>
      n >= 1000 ? '${(n / 1000).toStringAsFixed(1)}K' : n.toString();
}

class _LevelRequirementRow extends StatelessWidget {
  final int current;
  final int required;
  final bool met;

  const _LevelRequirementRow(
      {required this.current, required this.required, required this.met});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          met
              ? '🔓 Level $current — Requirement met'
              : '🔒 Level required: $required (you are $current)',
          style: GoogleFonts.inter(
              fontSize: 12, color: met ? Colors.white70 : Colors.orange),
        ),
        Icon(
          met ? Icons.check_circle : Icons.lock,
          color: met ? const Color(0xFF4CAF50) : Colors.orange,
          size: 16,
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kClanBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white60)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _PrivacyOption extends StatelessWidget {
  final String value;
  final bool selected;
  final String label;
  final String desc;
  final String icon;
  final VoidCallback onTap;

  const _PrivacyOption({
    required this.value,
    required this.selected,
    required this.label,
    required this.desc,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected
              ? kClanAccent.withOpacity(0.12)
              : Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: selected ? kClanAccent : kClanBorder),
        ),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white)),
                  Text(desc,
                      style: GoogleFonts.inter(
                          fontSize: 11, color: Colors.white38)),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle, color: kClanAccent, size: 18),
          ],
        ),
      ),
    );
  }
}

class _DarkTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final int maxLength;
  final int maxLines;
  final ValueChanged<String>? onChanged;

  const _DarkTextField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.maxLength,
    this.maxLines = 1,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.white54)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLength: maxLength,
          maxLines: maxLines,
          onChanged: onChanged,
          style: GoogleFonts.inter(fontSize: 14, color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(fontSize: 14, color: Colors.white24),
            counterStyle: GoogleFonts.inter(fontSize: 10, color: Colors.white24),
            filled: true,
            fillColor: Colors.white.withOpacity(0.06),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: kClanAccent),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white12),
            ),
          ),
        ),
      ],
    );
  }
}
