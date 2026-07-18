import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/api_service.dart';
import '../../widgets/bengo_avatar.dart';
import 'verify_screen.dart';

// ── Design tokens (matches login_screen palette) ──────────────────────────────
const _kBg = Color(0xFFFAF8F5);
const _kSurface = Color(0xFFFFFFFF);
const _kAccent = Color(0xFFC41230);
const _kAccentShadow = Color(0x40C41230);
const _kInk = Color(0xFF1B1B1D);
const _kFieldTint = Color(0xFFFDF3F5);
const _kFieldBorder = Color(0xFFEDD5D8);
const _kFieldFocus = Color(0xFFC41230);
const _kMuted = Color(0xFF8A8A8F);
const _kDivider = Color(0xFFE5E0DC);
const _kBorderLight = Color(0xFFEAE5E1);

// ── Step metadata ─────────────────────────────────────────────────────────────
const _kStepTitles = [
  'Personal Details',
  'Learning Goals',
  'Your Avatar',
  'Verify Email',
  'Your Identity',
  'Select Institution',
];
const _kStepSubtitles = [
  'Tell us a little about yourself',
  'Personalise your study path',
  'Choose your BenGo companion',
  'Confirm your email address',
  'Choose a unique username',
  'Which institution are you from?',
];
const _kStepIcons = [
  Icons.person_outline_rounded,
  Icons.school_outlined,
  Icons.face_retouching_natural_outlined,
  Icons.mark_email_read_outlined,
  Icons.badge_outlined,
  Icons.business_outlined,
];

class CreateAccountScreen extends StatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen>
    with TickerProviderStateMixin {
  final _pageCtrl = PageController();
  int _currentPage = 0;
  static const _totalPages = 6;

  // Stage 1
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscurePw = true;
  bool _obscureConfirm = true;

  // Stage 2
  String? _selectedLevel;
  String? _selectedGoal;

  // Stage 3 — Avatar
  String _selectedAvatarId = 'a1';

  // Stage 4 — OTP / Email verify
  final _otpCtrl = TextEditingController();
  final _otpFocus = FocusNode();
  bool _otpSent = false;
  bool _isSendingOtp = false;
  bool _isVerifyingOtp = false;
  String _errorMsg = '';

  // Stage 5
  final _usernameCtrl = TextEditingController();
  bool _isRegistering = false;

  // Email validation
  final _emailFocus = FocusNode();
  bool _isCheckingEmail = false;
  bool? _emailAvailable;
  bool _isEmailFormatValid = false;
  String _emailStatusMessage = '';
  
  // Username validation
  bool _isCheckingUsername = false;
  bool? _usernameAvailable; // null = not checked, true = available, false = taken
  Timer? _usernameCheckTimer;

  // Stage 6 — Institution Selection
  List<dynamic> _institutions = [];
  dynamic _selectedInstitution;
  final _institutionSearchCtrl = TextEditingController();
  List<dynamic> _filteredInstitutions = [];
  bool _showInstitutionDropdown = false;
  bool _isSearchingInstitutions = false;
  final _regNumberCtrl = TextEditingController();
  bool _isLoadingInstitutions = false;
  Timer? _institutionSearchDebounce;

  // Page transition animation controller
  late final AnimationController _pageAnimCtrl;

  @override
  void initState() {
    super.initState();
    _pageAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _usernameCtrl.addListener(() => setState(() {}));
    _emailFocus.addListener(() {
      if (!_emailFocus.hasFocus) {
        _checkEmailAvailability(_emailCtrl.text.trim());
      }
    });
    _emailCtrl.addListener(() {
      final email = _emailCtrl.text.trim();
      if (email.isEmpty) {
        setState(() {
          _isEmailFormatValid = false;
          _emailAvailable = null;
          _emailStatusMessage = '';
          _isCheckingEmail = false;
        });
        return;
      }

      setState(() {
        _isEmailFormatValid = _isValidEmail(email);
        if (!_isEmailFormatValid) {
          _emailAvailable = null;
          _emailStatusMessage = 'Please enter a valid email address.';
        }
      });
    });
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _pageAnimCtrl.dispose();
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    _otpCtrl.dispose();
    _otpFocus.dispose();
    _emailFocus.dispose();
    _usernameCtrl.dispose();
    _institutionSearchCtrl.dispose();
    _regNumberCtrl.dispose();
    _usernameCheckTimer?.cancel();
    _institutionSearchDebounce?.cancel();
    super.dispose();
  }

  void _animateIn() {
    _pageAnimCtrl.reset();
    _pageAnimCtrl.forward();
  }

  Future<void> _nextPage() async {
    if (_currentPage == 0 && !_validateStage1()) return;
    if (_currentPage == 1) {
      if (!_validateStage2()) return;
      // Don't send OTP yet — avatar step is next
    }
    if (_currentPage == 2) {
      // Avatar chosen — now send OTP and move to email verify
      await _sendVerificationCode();
      if (!mounted) return;
    }
    if (_currentPage == 3) {
      await _verifyOtp();
      return;
    }
    if (_currentPage == 4) {
      if (!_validateStage4()) return;
      // Load institutions before moving to institution stage
      await _loadInstitutions();
      if (!mounted) return;
    }
    if (_currentPage == 5) {
      // Complete registration with institution selection
      await _completeRegistration();
      return;
    }
    if (_currentPage < _totalPages - 1) {
      _pageCtrl.nextPage(
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageCtrl.previousPage(
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: Column(
        children: [
          _StepHeader(
            currentStep: _currentPage,
            totalSteps: _totalPages,
            onBack: _previousPage,
          ),
          Expanded(
            child: PageView(
              controller: _pageCtrl,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (i) {
                setState(() => _currentPage = i);
                _animateIn();
              },
              children: [
                _buildStage1(),
                _buildStage2(),
                _buildStageAvatar(),
                _buildStage3(),
                _buildStage4(),
                _buildStageInstitution(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Stage 1: Personal Details ──────────────────────────────────────────────
  Widget _buildStage1() {
    return _StageShell(
      animCtrl: _pageAnimCtrl,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StageHeading(
            icon: _kStepIcons[0],
            title: _kStepTitles[0],
            subtitle: _kStepSubtitles[0],
          ),
          const SizedBox(height: 24),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _FilledField(
                      label: 'First name',
                      controller: _firstNameCtrl,
                      hint: 'Kenji',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _FilledField(
                      label: 'Last name',
                      controller: _lastNameCtrl,
                      hint: 'Tanaka',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _FilledField(
                label: 'Email address',
                controller: _emailCtrl,
                hint: 'student@bengo.edu',
                prefixIcon: Icons.alternate_email_rounded,
                keyboardType: TextInputType.emailAddress,
                focusNode: _emailFocus,
                onChanged: (_) => setState(() {}),
              ),
              if (_isCheckingEmail) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(_kAccent),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Checking email availability…',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: _kMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ] else if (_emailStatusMessage.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      _emailAvailable == true
                          ? Icons.check_circle_rounded
                          : Icons.error_outline_rounded,
                      size: 16,
                      color: _emailAvailable == true
                          ? const Color(0xFF2E7D32)
                          : const Color(0xFFD32F2F),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _emailStatusMessage,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: _emailAvailable == true
                            ? const Color(0xFF2E7D32)
                            : const Color(0xFFD32F2F),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 14),
              _FilledField(
                label: 'Password',
                controller: _passwordCtrl,
                hint: '••••••••',
                prefixIcon: Icons.lock_outline_rounded,
                isPassword: true,
                obscureText: _obscurePw,
                onToggleObscure: () => setState(() => _obscurePw = !_obscurePw),
              ),
              const SizedBox(height: 14),
              _FilledField(
                label: 'Confirm password',
                controller: _confirmCtrl,
                hint: '••••••••',
                prefixIcon: Icons.shield_outlined,
                isPassword: true,
                obscureText: _obscureConfirm,
                onToggleObscure: () =>
                    setState(() => _obscureConfirm = !_obscureConfirm),
              ),
              if (_errorMsg.isNotEmpty) ...[
                const SizedBox(height: 12),
                _ErrorBanner(message: _errorMsg),
              ],
            ],
          ),
          const SizedBox(height: 28),
          _PillCTA(
            label: 'Continue',
            onPressed: _canAdvanceFromStage1() ? _nextPage : null,
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ── Stage 2: Learning Goals ────────────────────────────────────────────────
  Widget _buildStage2() {
    final levels = [
      ('N5 — Beginner', 'First steps into Japanese', '⭐'),
      ('N4 — Elementary', 'Everyday basic phrases', '⭐⭐'),
      ('N3 — Intermediate', 'Navigate most situations', '⭐⭐⭐'),
    ];
    final goals = [
      ('Daily Conversation', Icons.chat_bubble_outline_rounded),
      ('JLPT Certification', Icons.workspace_premium_outlined),
      ('Anime / Manga', Icons.auto_stories_outlined),
      ('Business Japanese', Icons.business_center_outlined),
    ];

    return _StageShell(
      animCtrl: _pageAnimCtrl,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StageHeading(
            icon: _kStepIcons[1],
            title: _kStepTitles[1],
            subtitle: _kStepSubtitles[1],
          ),
          const SizedBox(height: 24),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionLabel(label: 'JLPT Level'),
              const SizedBox(height: 10),
              ...levels.map((l) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _LevelTile(
                      title: l.$1,
                      subtitle: l.$2,
                      stars: l.$3,
                      isSelected: _selectedLevel == l.$1,
                      onTap: () => setState(() => _selectedLevel = l.$1),
                    ),
                  )),
              const SizedBox(height: 20),
              _SectionLabel(label: 'Learning Goal'),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: goals
                    .map((g) => _GoalChip(
                          label: g.$1,
                          icon: g.$2,
                          isSelected: _selectedGoal == g.$1,
                          onTap: () => setState(() => _selectedGoal = g.$1),
                        ))
                    .toList(),
              ),
              if (_errorMsg.isNotEmpty) ...[
                const SizedBox(height: 12),
                _ErrorBanner(message: _errorMsg),
              ],
            ],
          ),
          const SizedBox(height: 28),
          _PillCTA(
            label: _isSendingOtp ? 'Sending code…' : 'Continue',
            isLoading: _isSendingOtp,
            onPressed: _isSendingOtp ? null : _nextPage,
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ── Stage Avatar: Pick Your Companion ──────────────────────────────────────
  Widget _buildStageAvatar() {
    final def = avatarById(_selectedAvatarId);
    final fade = CurvedAnimation(parent: _pageAnimCtrl, curve: Curves.easeOut);
    final slide = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _pageAnimCtrl, curve: Curves.easeOut));

    return FadeTransition(
      opacity: fade,
      child: SlideTransition(
        position: slide,
        child: Column(
          children: [
            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _StageHeading(
                      icon: _kStepIcons[2],
                      title: _kStepTitles[2],
                      subtitle: _kStepSubtitles[2],
                    ),
                    const SizedBox(height: 20),
                    Column(
                      children: [
                        // 3D-tilt animated preview of selected avatar
                        Center(
                          child: _Avatar3DPreview(
                            key: ValueKey(_selectedAvatarId),
                            avatarId: _selectedAvatarId,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Center(
                          child: Text(
                            def.label,
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1B1B1D),
                              letterSpacing: -0.3,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Accent pill using shadow colour
                        Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: def.shadow.withOpacity(0.10),
                              borderRadius: BorderRadius.circular(100),
                              border: Border.all(color: def.shadow.withOpacity(0.28)),
                            ),
                            child: Text(
                              'Your Companion',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: def.shadow,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Avatar picker grid
                        BenGoAvatarPicker(
                          selectedId: _selectedAvatarId,
                          onSelect: (id) => setState(() => _selectedAvatarId = id),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
            // Pinned button at bottom
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
              child: _PillCTA(
                label: 'Continue',
                onPressed: _nextPage,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Stage 3: Verify Email ─────────────────────────────────────────────────
  Widget _buildStage3() {
    return _StageShell(
      animCtrl: _pageAnimCtrl,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StageHeading(
            icon: _kStepIcons[3],
            title: _kStepTitles[3],
            subtitle: _kStepSubtitles[3],
            centred: true,
          ),
          const SizedBox(height: 8),
          Column(
            children: [
              // Email badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: _kFieldTint,
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(color: _kFieldBorder),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.alternate_email_rounded,
                        size: 14, color: _kAccent),
                    const SizedBox(width: 6),
                    Text(
                      _emailCtrl.text.trim().isEmpty
                          ? 'your@email.com'
                          : _emailCtrl.text.trim(),
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _kAccent,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _otpSent
                    ? 'Code sent — check your inbox.'
                    : 'Tap Continue to receive your code.',
                style: GoogleFonts.inter(fontSize: 12, color: _kMuted),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              // OTP boxes
              _OtpInputRow(
                controller: _otpCtrl,
                focusNode: _otpFocus,
                onChanged: () => setState(() {}),
              ),
              const SizedBox(height: 20),
              // Resend
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Didn't receive the code? ",
                      style: GoogleFonts.inter(fontSize: 12, color: _kMuted)),
                  GestureDetector(
                    onTap: _isSendingOtp ? null : _sendVerificationCode,
                    child: Text(
                      _isSendingOtp ? 'Sending…' : 'Resend',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _kAccent,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              // Envelope illustration
              _EnvelopeIllustration(hasMail: _otpSent),
              const SizedBox(height: 28),
              if (_errorMsg.isNotEmpty) ...[
                _ErrorBanner(message: _errorMsg),
                const SizedBox(height: 14),
              ],
            ],
          ),
          _PillCTA(
            label: _isVerifyingOtp ? 'Verifying…' : 'Verify & Continue',
            isLoading: _isVerifyingOtp,
            onPressed: _isVerifyingOtp ? null : _nextPage,
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ── Stage 4: Username / Identity ──────────────────────────────────────────
  Widget _buildStage4() {
    return _StageShell(
      animCtrl: _pageAnimCtrl,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StageHeading(
            icon: _kStepIcons[4],
            title: _kStepTitles[4],
            subtitle: _kStepSubtitles[4],
          ),
          const SizedBox(height: 24),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionLabel(label: 'Username'),
              const SizedBox(height: 10),
              // Username field
              _UsernameField(
                controller: _usernameCtrl,
                isChecking: _isCheckingUsername,
                isAvailable: _usernameAvailable,
                onChanged: _checkUsernameAvailability,
              ),
              const SizedBox(height: 16),
              // Preview card
              _UsernamePreview(
                username: _usernameCtrl.text.trim(),
                firstName: _firstNameCtrl.text.trim(),
                lastName: _lastNameCtrl.text.trim(),
              ),
              const SizedBox(height: 8),
              Text(
                'Others will find you by this name on the leaderboard.',
                style: GoogleFonts.inter(fontSize: 12, color: _kMuted),
              ),
              if (_errorMsg.isNotEmpty) ...[
                const SizedBox(height: 12),
                _ErrorBanner(message: _errorMsg),
              ],
            ],
          ),
          const SizedBox(height: 28),
          _PillCTA(
            label: 'Continue',
            onPressed: _nextPage,
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ── Stage 6: Institution Selection ─────────────────────────────────────────
  Widget _buildStageInstitution() {
    final hasSelection = _selectedInstitution != null;

    return _StageShell(
      animCtrl: _pageAnimCtrl,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StageHeading(
            icon: _kStepIcons[5],
            title: _kStepTitles[5],
            subtitle: _kStepSubtitles[5],
          ),
          const SizedBox(height: 24),
          _SectionLabel(label: 'Institution'),
          const SizedBox(height: 10),
          _FilledField(
            label: 'Search institution',
            controller: _institutionSearchCtrl,
            hint: 'Type to search...',
            prefixIcon: Icons.search_outlined,
            onChanged: _filterInstitutions,
          ),
          if (_showInstitutionDropdown && _filteredInstitutions.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: _kSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _kFieldBorder),
              ),
              constraints: const BoxConstraints(maxHeight: 200),
              child: ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _filteredInstitutions.length,
                itemBuilder: (ctx, idx) {
                  final inst = _filteredInstitutions[idx];
                  return InkWell(
                    onTap: () => _selectInstitution(inst),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            inst['name'] ?? 'Unknown',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _kInk,
                            ),
                          ),
                          if (inst['code'] != null)
                            Text(
                              inst['code'] ?? '',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: _kMuted,
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ] else if (_isSearchingInstitutions) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(_kAccent)),
                  ),
                  const SizedBox(width: 8),
                  Text('Searching institutions…', style: GoogleFonts.inter(fontSize: 12, color: _kMuted)),
                ],
              ),
            ),
          ],
          if (hasSelection) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _kFieldTint,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _kAccent, width: 1.5),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: _kAccent, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _selectedInstitution['name'] ?? 'Unknown',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _kAccent,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setState(() {
                      _selectedInstitution = null;
                      _institutionSearchCtrl.clear();
                      _regNumberCtrl.clear();
                      _filteredInstitutions = [];
                      _showInstitutionDropdown = false;
                      _isSearchingInstitutions = false;
                    }),
                    child: Icon(Icons.close, color: _kAccent, size: 18),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 280),
              child: hasSelection
                  ? Container(
                      key: const ValueKey('reg-number'),
                      child: AnimatedOpacity(
                        opacity: 1.0,
                        duration: const Duration(milliseconds: 300),
                        child: _FilledField(
                          label: 'Institutional Registration Number',
                          controller: _regNumberCtrl,
                          hint: 'e.g., STU-2024-001',
                          enabled: true,
                        ),
                      ),
                    )
                  : const SizedBox.shrink(key: ValueKey('empty')),
            ),
          ],
          if (_errorMsg.isNotEmpty) ...[
            const SizedBox(height: 12),
            _ErrorBanner(message: _errorMsg),
          ],
          const SizedBox(height: 24),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextButton(
                onPressed: _isRegistering ? null : _skipInstitutionStage,
                child: Text(
                  'Skip for now',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _kAccent,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: _PillCTA(
                  label: _isRegistering ? 'Creating account…' : 'Continue',
                  isLoading: _isRegistering,
                  onPressed: _isRegistering || !_canContinueFromInstitutionStage() ? null : _nextPage,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ── Logic ──────────────────────────────────────────────────────────────────
  bool _canAdvanceFromStage1() {
    final email = _emailCtrl.text.trim();
    return email.isNotEmpty &&
        _isValidEmail(email) &&
        !_isCheckingEmail &&
        _emailAvailable == true;
  }

  bool _isValidEmail(String value) {
    final regex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    return regex.hasMatch(value.trim());
  }

  bool _validateStage1() {
    if (_firstNameCtrl.text.trim().isEmpty ||
        _lastNameCtrl.text.trim().isEmpty) {
      _setError('Enter your first and last name.');
      return false;
    }
    final email = _emailCtrl.text.trim();
    if (email.isEmpty || !_isValidEmail(email)) {
      _setError('Enter a valid email address.');
      return false;
    }
    if (_isCheckingEmail) {
      _setError('Please wait while we verify your email.');
      return false;
    }
    if (_emailAvailable != true) {
      _setError('Please choose an email address that is available.');
      return false;
    }
    if (_passwordCtrl.text.length < 6) {
      _setError('Password must be at least 6 characters.');
      return false;
    }
    if (_passwordCtrl.text != _confirmCtrl.text) {
      _setError('Passwords do not match.');
      return false;
    }
    _setError('');
    return true;
  }

  Future<void> _checkEmailAvailability(String email) async {
    final trimmedEmail = email.trim();
    if (trimmedEmail.isEmpty) {
      if (mounted) {
        setState(() {
          _isCheckingEmail = false;
          _emailAvailable = null;
          _emailStatusMessage = '';
          _isEmailFormatValid = false;
        });
      }
      return;
    }

    if (!_isValidEmail(trimmedEmail)) {
      if (mounted) {
        setState(() {
          _isCheckingEmail = false;
          _emailAvailable = null;
          _emailStatusMessage = 'Please enter a valid email address.';
          _isEmailFormatValid = false;
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        _isCheckingEmail = true;
        _emailStatusMessage = 'Checking email availability…';
        _isEmailFormatValid = true;
      });
    }

    try {
      final available = await ApiService.instance.checkEmailAvailability(trimmedEmail);
      if (!mounted) return;
      setState(() {
        _emailAvailable = available;
        _isCheckingEmail = false;
        _emailStatusMessage = available
            ? 'Email is available.'
            : 'This email is already registered.';
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _isCheckingEmail = false;
          _emailAvailable = null;
          _emailStatusMessage = 'Could not verify email right now.';
        });
      }
    }
  }

  bool _validateStage2() {
    if (_selectedLevel == null || _selectedGoal == null) {
      _setError('Please select a JLPT level and a learning goal.');
      return false;
    }
    _setError('');
    return true;
  }

  bool _validateStage4() {
    final username = _usernameCtrl.text.trim();
    if (username.isEmpty || username.length < 3) {
      _setError('Choose a username with at least 3 characters.');
      return false;
    }
    if (_usernameAvailable != true) {
      _setError('Username is not available or still checking. Please wait.');
      return false;
    }
    _setError('');
    return true;
  }

  void _setError(String msg) => setState(() => _errorMsg = msg);

  Future<void> _checkUsernameAvailability(String username) async {
    // Cancel previous timer if any
    _usernameCheckTimer?.cancel();
    
    if (username.length < 3) {
      setState(() => _usernameAvailable = null);
      return;
    }

    // Set checking state
    setState(() => _isCheckingUsername = true);

    // Debounce: wait 600ms before checking
    _usernameCheckTimer = Timer(const Duration(milliseconds: 600), () async {
      try {
        final available = await ApiService.instance.checkUsernameAvailability(username);
        if (mounted) {
          setState(() {
            _usernameAvailable = available;
            _isCheckingUsername = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _usernameAvailable = null;
            _isCheckingUsername = false;
          });
        }
      }
    });
  }

  Future<void> _loadInstitutions() async {
    setState(() => _isLoadingInstitutions = true);
    try {
      final institutions = await ApiService.instance.fetchInstitutions();
      if (mounted) {
        setState(() {
          _institutions = institutions;
          _filteredInstitutions = institutions;
          _isLoadingInstitutions = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingInstitutions = false);
      }
    }
  }

  void _filterInstitutions(String query) {
    _institutionSearchDebounce?.cancel();

    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) {
      setState(() {
        _filteredInstitutions = [];
        _showInstitutionDropdown = false;
        _isSearchingInstitutions = false;
      });
      return;
    }

    setState(() {
      _showInstitutionDropdown = true;
      _isSearchingInstitutions = true;
    });

    _institutionSearchDebounce = Timer(const Duration(milliseconds: 350), () async {
      try {
        final institutions = await ApiService.instance.fetchInstitutions(search: trimmedQuery);
        if (!mounted) return;
        setState(() {
          _filteredInstitutions = List<dynamic>.from(institutions);
          _showInstitutionDropdown = _filteredInstitutions.isNotEmpty;
          _isSearchingInstitutions = false;
        });
      } catch (_) {
        if (!mounted) return;
        setState(() {
          _filteredInstitutions = [];
          _showInstitutionDropdown = false;
          _isSearchingInstitutions = false;
        });
      }
    });
  }

  void _selectInstitution(dynamic institution) {
    setState(() {
      _selectedInstitution = institution;
      _institutionSearchCtrl.text = institution['name'] ?? '';
      _showInstitutionDropdown = false;
      _filteredInstitutions = [];
      _isSearchingInstitutions = false;
    });
  }

  bool _canContinueFromInstitutionStage() {
    return _selectedInstitution != null && _regNumberCtrl.text.trim().isNotEmpty;
  }

  Future<void> _skipInstitutionStage() async {
    setState(() {
      _selectedInstitution = null;
      _institutionSearchCtrl.clear();
      _regNumberCtrl.clear();
      _showInstitutionDropdown = false;
      _filteredInstitutions = [];
      _isSearchingInstitutions = false;
    });
    await _nextPage();
  }

  Future<void> _sendVerificationCode() async {
    setState(() {
      _isSendingOtp = true;
      _errorMsg = '';
    });
    try {
      await ApiService.instance
          .sendVerificationCode(email: _emailCtrl.text.trim());
      if (!mounted) return;
      setState(() => _otpSent = true);
      _otpFocus.requestFocus();
      // Advance page if not already on stage 3
      if (_currentPage == 1) {
        _pageCtrl.nextPage(
          duration: const Duration(milliseconds: 380),
          curve: Curves.easeInOut,
        );
      }
    } on Exception catch (e) {
      _setError(e.toString());
    } finally {
      if (mounted) setState(() => _isSendingOtp = false);
    }
  }

  Future<void> _verifyOtp() async {
    if (_otpCtrl.text.trim().length != 6) {
      _setError('Enter the 6-digit code sent to your email.');
      return;
    }
    setState(() {
      _isVerifyingOtp = true;
      _errorMsg = '';
    });
    try {
      await ApiService.instance.verifyEmailCode(
        email: _emailCtrl.text.trim(),
        code: _otpCtrl.text.trim(),
      );
      if (!mounted) return;
      setState(() => _otpSent = true);
      _pageCtrl.nextPage(
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeInOut,
      );
    } on Exception catch (e) {
      _setError(e.toString());
    } finally {
      if (mounted) setState(() => _isVerifyingOtp = false);
    }
  }

  Future<void> _completeRegistration() async {
    final username = _usernameCtrl.text.trim();
    if (username.isEmpty || username.length < 3) {
      _setError('Choose a username with at least 3 characters.');
      return;
    }
    setState(() {
      _isRegistering = true;
      _errorMsg = '';
    });
    try {
      final available =
          await ApiService.instance.checkUsernameAvailability(username);
      if (!available) {
        _setError('That username is already taken.');
        return;
      }
      await ApiService.instance.register(
        username: username,
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
        password2: _confirmCtrl.text,
        firstName: _firstNameCtrl.text.trim(),
        lastName: _lastNameCtrl.text.trim(),
        preferredLevel: _selectedLevel ?? '',
        learningGoal: _selectedGoal ?? '',
        avatarId: _selectedAvatarId,
        institutionId: _selectedInstitution != null
            ? int.tryParse(_selectedInstitution['id'].toString())
            : null,
        institutionalRegistrationNumber: _regNumberCtrl.text.trim().isEmpty
            ? null
            : _regNumberCtrl.text.trim(),
      );
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AccountCreatedScreen()),
        (route) => false,
      );
    } on Exception catch (e) {
      _setError(e.toString());
    } finally {
      if (mounted) setState(() => _isRegistering = false);
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// AVATAR 3D PREVIEW
// ═══════════════════════════════════════════════════════════════════════════════

class _Avatar3DPreview extends StatefulWidget {
  final String avatarId;
  const _Avatar3DPreview({super.key, required this.avatarId});

  @override
  State<_Avatar3DPreview> createState() => _Avatar3DPreviewState();
}

class _Avatar3DPreviewState extends State<_Avatar3DPreview>
    with TickerProviderStateMixin {
  late AnimationController _tiltX;
  late AnimationController _tiltY;
  late AnimationController _float;

  @override
  void initState() {
    super.initState();
    _tiltX = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
    _tiltY = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _float = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _tiltX.dispose();
    _tiltY.dispose();
    _float.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final def = avatarById(widget.avatarId);
    return AnimatedBuilder(
      animation: Listenable.merge([_tiltX, _tiltY, _float]),
      builder: (_, child) {
        final rx = (_tiltX.value - 0.5) * 0.18; // radians
        final ry = (_tiltY.value - 0.5) * 0.18;
        final dy = (_float.value - 0.5) * 8.0;   // px vertical drift

        return Transform.translate(
          offset: Offset(0, dy),
          child: Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001) // perspective
              ..rotateX(rx)
              ..rotateY(ry),
            child: child,
          ),
        );
      },
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(34), // squircle
          boxShadow: [
            BoxShadow(
              color: def.shadow.withOpacity(0.45),
              blurRadius: 28,
              offset: const Offset(0, 10),
              spreadRadius: 2,
            ),
            BoxShadow(
              color: def.shadow.withOpacity(0.20),
              blurRadius: 50,
              spreadRadius: 8,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: Image.asset(
            def.asset,
            fit: BoxFit.cover,
            width: 120,
            height: 120,
            errorBuilder: (_, __, ___) => Container(
              color: def.shadow.withOpacity(0.15),
              child: Icon(Icons.person, size: 56, color: def.shadow),
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SHARED COMPONENTS
// ═══════════════════════════════════════════════════════════════════════════════

/// The neat header: back button, step dots, step counter
class _StepHeader extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final VoidCallback onBack;

  const _StepHeader({
    required this.currentStep,
    required this.totalSteps,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return Container(
      color: _kBg,
      padding: EdgeInsets.fromLTRB(16, top + 10, 16, 12),
      child: Column(
        children: [
          Row(
            children: [
              // Back / close button
              _BackCircle(onTap: onBack),
              const SizedBox(width: 12),

              // Step dots — animated
              Expanded(
                child: Row(
                  children: List.generate(totalSteps * 2 - 1, (i) {
                    if (i.isOdd) {
                      // Connector line
                      return Expanded(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 350),
                          height: 2,
                          decoration: BoxDecoration(
                            color: (i ~/ 2) < currentStep
                                ? _kAccent
                                : _kBorderLight,
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                      );
                    }
                    // Dot
                    final stepIdx = i ~/ 2;
                    final isDone = stepIdx < currentStep;
                    final isActive = stepIdx == currentStep;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 350),
                      width: isActive ? 28 : 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: isDone || isActive ? _kAccent : _kBorderLight,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: isActive
                          ? null
                          : isDone
                              ? Center(
                                  child: Container(
                                    width: 4,
                                    height: 4,
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                )
                              : null,
                    );
                  }),
                ),
              ),
              const SizedBox(width: 12),

              // Step counter badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _kFieldTint,
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(color: _kFieldBorder),
                ),
                child: Text(
                  '${currentStep + 1} / $totalSteps',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _kAccent,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BackCircle extends StatefulWidget {
  final VoidCallback onTap;
  const _BackCircle({required this.onTap});

  @override
  State<_BackCircle> createState() => _BackCircleState();
}

class _BackCircleState extends State<_BackCircle> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.92 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: _pressed ? _kFieldTint : _kSurface,
            shape: BoxShape.circle,
            border: Border.all(color: _kBorderLight, width: 1.5),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A000000),
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 16,
            color: _kInk,
          ),
        ),
      ),
    );
  }
}

/// Scrollable shell with fade-up entry animation
class _StageShell extends StatelessWidget {
  final AnimationController animCtrl;
  final Widget child;

  const _StageShell({required this.animCtrl, required this.child});

  @override
  Widget build(BuildContext context) {
    final fade = CurvedAnimation(parent: animCtrl, curve: Curves.easeOut);
    final slide = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: animCtrl, curve: Curves.easeOut));

    return FadeTransition(
      opacity: fade,
      child: SlideTransition(
        position: slide,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: child,
        ),
      ),
    );
  }
}

/// Icon + title + subtitle heading block
class _StageHeading extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool centred;

  const _StageHeading({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.centred = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 4),
      child: Column(
        crossAxisAlignment:
            centred ? CrossAxisAlignment.center : CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _kFieldTint,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _kFieldBorder),
            ),
            child: Icon(icon, color: _kAccent, size: 24),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: _kInk,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: GoogleFonts.inter(fontSize: 13, color: _kMuted),
          ),
        ],
      ),
    );
  }
}

/// Uppercase section label
class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: GoogleFonts.inter(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.6,
        color: _kMuted,
      ),
    );
  }
}

/// M3-style filled text field
class _FilledField extends StatefulWidget {
  final String label;
  final TextEditingController controller;
  final String hint;
  final IconData? prefixIcon;
  final bool isPassword;
  final bool obscureText;
  final VoidCallback? onToggleObscure;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final bool enabled;
  final FocusNode? focusNode;

  const _FilledField({
    required this.label,
    required this.controller,
    required this.hint,
    this.prefixIcon,
    this.isPassword = false,
    this.obscureText = false,
    this.onToggleObscure,
    this.keyboardType,
    this.onChanged,
    this.enabled = true,
    this.focusNode,
  });

  @override
  State<_FilledField> createState() => _FilledFieldState();
}

class _FilledFieldState extends State<_FilledField> {
  final _focus = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    (widget.focusNode ?? _focus).addListener(() => setState(() => _focused = (widget.focusNode ?? _focus).hasFocus));
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focus.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: _kInk.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 6),
        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            color: _focused ? const Color(0xFFFFF0F2) : _kFieldTint,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
              bottomLeft: Radius.circular(4),
              bottomRight: Radius.circular(4),
            ),
            border: Border(
              bottom: BorderSide(
                color: _focused ? _kFieldFocus : _kFieldBorder,
                width: _focused ? 2 : 1,
              ),
            ),
          ),
          child: TextField(
            controller: widget.controller,
            focusNode: widget.focusNode ?? _focus,
            enabled: widget.enabled,
            obscureText: widget.isPassword && widget.obscureText,
            keyboardType: widget.keyboardType,
            onChanged: widget.onChanged,
            style: GoogleFonts.inter(
                fontSize: 15, color: _kInk, fontWeight: FontWeight.w500),
            cursorColor: _kAccent,
            decoration: InputDecoration(
              prefixIcon: widget.prefixIcon != null
                  ? Padding(
                      padding: const EdgeInsets.only(left: 12, right: 8),
                      child: Icon(widget.prefixIcon,
                          color: _focused ? _kAccent : _kMuted, size: 20),
                    )
                  : null,
              prefixIconConstraints:
                  const BoxConstraints(minWidth: 44, minHeight: 48),
              suffixIcon: widget.isPassword
                  ? IconButton(
                      icon: Icon(
                        widget.obscureText
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: _kMuted,
                        size: 18,
                      ),
                      onPressed: widget.onToggleObscure,
                    )
                  : null,
              hintText: widget.hint,
              hintStyle: GoogleFonts.inter(
                  color: _kMuted.withOpacity(0.6), fontSize: 14),
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            ),
          ),
        ),
      ],
    );
  }
}

/// Pill CTA button
class _PillCTA extends StatefulWidget {
  final String label;
  final bool isLoading;
  final VoidCallback? onPressed;

  const _PillCTA({
    required this.label,
    this.isLoading = false,
    this.onPressed,
  });

  @override
  State<_PillCTA> createState() => _PillCTAState();
}

class _PillCTAState extends State<_PillCTA> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    return GestureDetector(
      onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
      onTapUp: enabled
          ? (_) {
              setState(() => _pressed = false);
              widget.onPressed!();
            }
          : null,
      onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 110),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 54,
          decoration: BoxDecoration(
            color: enabled ? _kAccent : _kAccent.withOpacity(0.45),
            borderRadius: BorderRadius.circular(100),
            boxShadow: enabled
                ? const [
                    BoxShadow(
                      color: _kAccentShadow,
                      blurRadius: 0,
                      offset: Offset(0, 4),
                    ),
                    BoxShadow(
                      color: Color(0x20C41230),
                      blurRadius: 12,
                      offset: Offset(0, 8),
                    ),
                  ]
                : [],
          ),
          child: Center(
            child: widget.isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2.2),
                  )
                : Text(
                    widget.label,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.3,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

/// Red error banner
class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFCDD2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: _kAccent, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: _kAccent,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// JLPT Level selection tile
class _LevelTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final String stars;
  final bool isSelected;
  final VoidCallback onTap;

  const _LevelTile({
    required this.title,
    required this.subtitle,
    required this.stars,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFF0F2) : _kSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? _kAccent : _kBorderLight,
            width: isSelected ? 1.8 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isSelected ? 0.0 : 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Radio circle
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? _kAccent : Colors.transparent,
                border: Border.all(
                  color: isSelected ? _kAccent : _kMuted,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check_rounded,
                      size: 13, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _kInk,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: _kMuted,
                    ),
                  ),
                ],
              ),
            ),
            Text(stars, style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}

/// Learning goal chip
class _GoalChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _GoalChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? _kAccent : _kSurface,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: isSelected ? _kAccent : _kBorderLight,
            width: isSelected ? 0 : 1,
          ),
          boxShadow: isSelected
              ? const [
                  BoxShadow(
                      color: _kAccentShadow,
                      blurRadius: 0,
                      offset: Offset(0, 3))
                ]
              : [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 4,
                      offset: const Offset(0, 2))
                ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 16,
                color: isSelected ? Colors.white : _kMuted),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : _kInk,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// OTP input row — 6 boxes with a transparent text field overlay
class _OtpInputRow extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onChanged;

  const _OtpInputRow({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
  });

  @override
  State<_OtpInputRow> createState() => _OtpInputRowState();
}

class _OtpInputRowState extends State<_OtpInputRow> {
  @override
  Widget build(BuildContext context) {
    final code = widget.controller.text.padRight(6);
    return Stack(
      alignment: Alignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(6, (i) {
            final filled = i < widget.controller.text.length;
            final active = i == widget.controller.text.length &&
                widget.focusNode.hasFocus;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 44,
              height: 54,
              decoration: BoxDecoration(
                color: filled
                    ? const Color(0xFFFFF0F2)
                    : active
                        ? _kFieldTint
                        : _kSurface,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(10),
                  topRight: Radius.circular(10),
                  bottomLeft: Radius.circular(4),
                  bottomRight: Radius.circular(4),
                ),
                border: Border(
                  bottom: BorderSide(
                    color: active
                        ? _kAccent
                        : filled
                            ? _kFieldFocus.withOpacity(0.5)
                            : _kBorderLight,
                    width: active ? 2.5 : 1.5,
                  ),
                ),
              ),
              child: Center(
                child: Text(
                  code[i].trim().isEmpty ? '' : code[i],
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: _kInk,
                  ),
                ),
              ),
            );
          }),
        ),
        Positioned.fill(
          child: TextField(
            controller: widget.controller,
            focusNode: widget.focusNode,
            keyboardType: TextInputType.number,
            maxLength: 6,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: const TextStyle(color: Colors.transparent, fontSize: 1),
            cursorColor: Colors.transparent,
            decoration: const InputDecoration(
              border: InputBorder.none,
              counterText: '',
            ),
            onChanged: (_) {
              setState(() {});
              widget.onChanged();
            },
          ),
        ),
      ],
    );
  }
}

/// Animated envelope illustration for stage 3
class _EnvelopeIllustration extends StatelessWidget {
  final bool hasMail;
  const _EnvelopeIllustration({required this.hasMail});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      width: double.infinity,
      height: 140,
      decoration: BoxDecoration(
        color: hasMail ? const Color(0xFFFFF0F2) : const Color(0xFFF5F3F0),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: hasMail ? _kFieldBorder : _kBorderLight,
          width: 1.5,
        ),
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        child: hasMail
            ? Column(
                key: const ValueKey('sent'),
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.mark_email_read_outlined,
                      color: _kAccent, size: 48),
                  const SizedBox(height: 8),
                  Text(
                    'Code delivered!',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _kAccent,
                    ),
                  ),
                ],
              )
            : Column(
                key: const ValueKey('waiting'),
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.email_outlined, color: _kMuted, size: 48),
                  const SizedBox(height: 8),
                  Text(
                    'Awaiting code…',
                    style: GoogleFonts.inter(
                        fontSize: 13, color: _kMuted),
                  ),
                ],
              ),
      ),
    );
  }
}

/// Username field with @ prefix
class _UsernameField extends StatefulWidget {
  final TextEditingController controller;
  final bool isChecking;
  final bool? isAvailable;
  final Function(String) onChanged;
  
  const _UsernameField({
    required this.controller,
    required this.isChecking,
    required this.isAvailable,
    required this.onChanged,
  });

  @override
  State<_UsernameField> createState() => _UsernameFieldState();
}

class _UsernameFieldState extends State<_UsernameField> {
  final _focus = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() => _focused = _focus.hasFocus));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        color: _focused ? const Color(0xFFFFF0F2) : _kFieldTint,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
          bottomLeft: Radius.circular(4),
          bottomRight: Radius.circular(4),
        ),
        border: Border(
          bottom: BorderSide(
            color: _focused 
              ? (widget.isAvailable == false ? const Color(0xFFD32F2F) : _kFieldFocus)
              : (widget.isAvailable == false ? const Color(0xFFD32F2F) : _kFieldBorder),
            width: _focused ? 2 : 1,
          ),
        ),
      ),
      child: TextField(
        controller: widget.controller,
        focusNode: _focus,
        onChanged: widget.onChanged,
        style: GoogleFonts.inter(
            fontSize: 15, color: _kInk, fontWeight: FontWeight.w500),
        cursorColor: _kAccent,
        decoration: InputDecoration(
          prefixText: '@  ',
          prefixStyle: GoogleFonts.inter(
            color: _focused ? _kAccent : _kMuted,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
          hintText: 'yourhandle',
          hintStyle: GoogleFonts.inter(
              color: _kMuted.withOpacity(0.6), fontSize: 14),
          suffixIcon: widget.isChecking
            ? Padding(
                padding: const EdgeInsets.all(12),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(_kAccent),
                  ),
                ),
              )
            : widget.isAvailable == true
              ? Padding(
                  padding: const EdgeInsets.all(12),
                  child: Icon(
                    Icons.check_circle,
                    color: const Color(0xFF4CAF50),
                    size: 20,
                  ),
                )
              : widget.isAvailable == false
                ? Padding(
                    padding: const EdgeInsets.all(12),
                    child: Icon(
                      Icons.cancel,
                      color: const Color(0xFFD32F2F),
                      size: 20,
                    ),
                  )
                : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 14, vertical: 14),
        ),
      ),
    );
  }
}

/// Profile preview card for stage 4
class _UsernamePreview extends StatelessWidget {
  final String username;
  final String firstName;
  final String lastName;

  const _UsernamePreview({
    required this.username,
    required this.firstName,
    required this.lastName,
  });

  @override
  Widget build(BuildContext context) {
    final displayName = username.isEmpty ? 'username' : username;
    final initials = [
      firstName.isNotEmpty ? firstName[0] : '',
      lastName.isNotEmpty ? lastName[0] : '',
    ].join().toUpperCase();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorderLight),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _kAccent.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                initials.isEmpty ? '???' : initials,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: _kAccent,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$firstName ${lastName.isEmpty ? '' : lastName}'.trim().isEmpty
                    ? 'Your Name'
                    : '$firstName $lastName'.trim(),
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: _kInk,
                ),
              ),
              Text(
                '@$displayName',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: _kAccent,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Text(
              'Preview',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF2E7D32),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
