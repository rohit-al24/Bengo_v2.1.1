import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../../services/api_service.dart';
import 'verify_screen.dart';

class CreateAccountScreen extends StatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final int _totalPages = 4;

  // Stage 1 controllers
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();

  // Stage 2
  String? _selectedLevel;
  String? _selectedGoal;

  // Stage 3 - verification
  final _otpCtrl = TextEditingController();
  final _otpFocusNode = FocusNode();
  bool _otpSent = false;
  bool _isSendingOtp = false;
  bool _isVerifyingOtp = false;
  String _errorMessage = '';

  // Stage 4
  final _usernameCtrl = TextEditingController();
  bool _isRegistering = false;

  @override
  void dispose() {
    _pageController.dispose();
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    _usernameCtrl.dispose();
    super.dispose();
  }

  Future<void> _nextPage() async {
    if (_currentPage == 0) {
      if (!_validateStage1()) return;
    }

    if (_currentPage == 1) {
      if (!_validateStage2()) return;
      await _sendVerificationCode();
      if (!mounted) return;
    }

    if (_currentPage == 2) {
      await _verifyOtp();
      return;
    }

    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: Column(
        children: [
          // Progress header
          _buildProgressHeader(),
          // Pages
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (i) => setState(() => _currentPage = i),
              children: [
                _buildStage1(),
                _buildStage2(),
                _buildStage3(),
                _buildStage4(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressHeader() {
    final stages = ['1 OF 4', '2 OF 4', '3 OF 4', '4 OF 4'];
    final rightLabels = [
      'Personal Details',
      'Learning Goals',
      'Verify Email',
      'Identity'
    ];

    return Container(
      color: AppColors.bgLight,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 20,
        right: 20,
        bottom: 8,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'STAGE ${stages[_currentPage]}',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                rightLabels[_currentPage],
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (_currentPage + 1) / _totalPages,
              backgroundColor: AppColors.borderLight,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.primary),
              minHeight: 5,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Stage 1: Personal Details ────────────────────────────────────────────
  Widget _buildStage1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Center(
            child: Text('BenGo', style: AppTextStyles.brandName.copyWith(fontSize: 32)),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              "Let's start with the basics.",
              style: AppTextStyles.bodyMedium,
            ),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: _buildLabeledField(
                  label: 'First Name',
                  controller: _firstNameCtrl,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildLabeledField(
                  label: 'Last Name',
                  controller: _lastNameCtrl,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildLabeledField(
            label: 'Email ID',
            controller: _emailCtrl,
            prefixIcon: Icons.mail_outline_rounded,
          ),
          const SizedBox(height: 16),
          _buildLabeledField(
            label: 'Password',
            controller: _passwordCtrl,
            prefixIcon: Icons.lock_outline_rounded,
            isPassword: true,
          ),
          const SizedBox(height: 16),
          _buildLabeledField(
            label: 'Confirm Password',
            controller: _confirmPasswordCtrl,
            prefixIcon: Icons.shield_outlined,
            isPassword: true,
          ),
          const SizedBox(height: 48),
          _NextButton(onTap: _nextPage),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ─── Stage 2: Learning Level ──────────────────────────────────────────────
  Widget _buildStage2() {
    final levels = ['N5 - Beginner', 'N4 - Elementary', 'N3 - Intermediate'];
    final goals = ['Daily Conversation', 'JLPT Certification', 'Anime/Manga', 'Business'];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Text('Choose your\nstarting level', style: AppTextStyles.displayMedium),
          const SizedBox(height: 8),
          Text('We\'ll personalize your path.', style: AppTextStyles.bodyMedium),
          const SizedBox(height: 32),
          Text('JLPT LEVEL', style: AppTextStyles.captionUpper),
          const SizedBox(height: 12),
          ...levels.map((l) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _SelectionTile(
                  title: l,
                  isSelected: _selectedLevel == l,
                  onTap: () => setState(() => _selectedLevel = l),
                ),
              )),
          const SizedBox(height: 24),
          Text('LEARNING GOAL', style: AppTextStyles.captionUpper),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: goals
                .map((g) => _ChipOption(
                      label: g,
                      isSelected: _selectedGoal == g,
                      onTap: () => setState(() => _selectedGoal = g),
                    ))
                .toList(),
          ),
          const SizedBox(height: 48),
          _NextButton(onTap: _nextPage),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ─── Stage 3: Verify Identity ─────────────────────────────────────────────
  Widget _buildStage3() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 24),
          Text('Verify Identity', style: AppTextStyles.headlineLarge),
          const SizedBox(height: 8),
          Text(
            'We\'ve sent a 6-digit code to',
            style: AppTextStyles.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            _emailCtrl.text.trim().isEmpty ? 'your email address' : _emailCtrl.text.trim(),
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 24),
          if (_otpSent)
            Text(
              'Code sent — check your inbox.',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary),
            )
          else
            Text(
              'Tap next to receive your verification code.',
              style: AppTextStyles.bodySmall,
            ),
          const SizedBox(height: 24),
          Stack(
            alignment: Alignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(
                  6,
                  (i) => _OtpBox(digit: _otpCtrl.text.padRight(6)[i]),
                ),
              ),
              Positioned.fill(
                child: TextField(
                  controller: _otpCtrl,
                  focusNode: _otpFocusNode,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: const TextStyle(color: Colors.transparent),
                  cursorColor: AppColors.primary,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    counterText: '',
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text('Didn\'t receive the code?', style: AppTextStyles.bodySmall),
          const SizedBox(height: 4),
          GestureDetector(
            onTap: _sendVerificationCode,
            child: Text(
              _isSendingOtp ? 'Sending code...' : 'Resend Code',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 32),
          Container(
            height: 160,
            decoration: BoxDecoration(
              color: AppColors.borderLight,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Icon(Icons.email_outlined, size: 48, color: AppColors.textMuted),
            ),
          ),
          const SizedBox(height: 32),
          if (_errorMessage.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                _errorMessage,
                style: AppTextStyles.bodySmall.copyWith(color: Colors.redAccent),
              ),
            ),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _nextPage,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: _isVerifyingOtp
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Verify & Continue',
                          style: GoogleFonts.inter(
                              fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward_rounded, size: 20),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'BENGO STUDIO © 2024',
            style: AppTextStyles.captionUpper.copyWith(fontSize: 9),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ─── Stage 4: Username / Identity ─────────────────────────────────────────
  Widget _buildStage4() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.bgWhite,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Claim your identity', style: AppTextStyles.headlineLarge),
                const SizedBox(height: 8),
                Text(
                  'Choose a unique username that others will use to find you on the BenGo leaderboard.',
                  style: AppTextStyles.bodyMedium,
                ),
                const SizedBox(height: 24),
                Text('USERNAME', style: AppTextStyles.captionUpper),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.bgLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: TextField(
                    controller: _usernameCtrl,
                    style: AppTextStyles.bodyLarge,
                    decoration: InputDecoration(
                      prefixText: '@ ',
                      prefixStyle: GoogleFonts.inter(
                          color: AppColors.textMuted, fontSize: 15),
                      hintText: 'yourname',
                      hintStyle: AppTextStyles.bodyMedium,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Preview card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.bgLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: AppColors.primary.withOpacity(0.1),
                        child: const Icon(Icons.pets,
                            color: AppColors.primary, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('PREVIEW', style: AppTextStyles.captionUpper),
                          Text(
                            '@${_usernameCtrl.text.trim().isEmpty ? 'username' : _usernameCtrl.text.trim()}',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _completeRegistration,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: _isRegistering
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Finish Setup',
                          style: GoogleFonts.inter(
                              fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward_rounded, size: 20),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  void _showError(String message) {
    setState(() {
      _errorMessage = message;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  bool _validateStage1() {
    if (_firstNameCtrl.text.trim().isEmpty || _lastNameCtrl.text.trim().isEmpty) {
      _showError('Enter your first and last name.');
      return false;
    }
    if (_emailCtrl.text.trim().isEmpty || !_emailCtrl.text.contains('@')) {
      _showError('Enter a valid email address.');
      return false;
    }
    if (_passwordCtrl.text.length < 6) {
      _showError('Password must be at least 6 characters.');
      return false;
    }
    if (_passwordCtrl.text != _confirmPasswordCtrl.text) {
      _showError('Passwords do not match.');
      return false;
    }
    return true;
  }

  bool _validateStage2() {
    if (_selectedLevel == null || _selectedGoal == null) {
      _showError('Select a JLPT level and learning goal.');
      return false;
    }
    return true;
  }

  Future<void> _sendVerificationCode() async {
    setState(() {
      _isSendingOtp = true;
      _errorMessage = '';
    });
    try {
      await ApiService.instance.sendVerificationCode(
        email: _emailCtrl.text.trim(),
      );
      if (!mounted) return;
      setState(() {
        _otpSent = true;
      });
      _otpFocusNode.requestFocus();
    } on Exception catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) {
        setState(() {
          _isSendingOtp = false;
        });
      }
    }
  }

  Future<void> _verifyOtp() async {
    if (_otpCtrl.text.trim().length != 6) {
      _showError('Enter the 6-digit code sent to your email.');
      return;
    }
    setState(() {
      _isVerifyingOtp = true;
      _errorMessage = '';
    });
    try {
      await ApiService.instance.verifyEmailCode(
        email: _emailCtrl.text.trim(),
        code: _otpCtrl.text.trim(),
      );
      if (!mounted) return;
      setState(() {
        _otpSent = true;
      });
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } on Exception catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) {
        setState(() {
          _isVerifyingOtp = false;
        });
      }
    }
  }

  Future<void> _completeRegistration() async {
    final username = _usernameCtrl.text.trim();
    if (username.isEmpty || username.length < 3) {
      _showError('Choose a username with at least 3 characters.');
      return;
    }
    setState(() {
      _isRegistering = true;
      _errorMessage = '';
    });
    try {
      final available = await ApiService.instance.checkUsernameAvailability(username);
      if (!available) {
        _showError('That username is already taken.');
        return;
      }
      await ApiService.instance.register(
        username: username,
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
        password2: _confirmPasswordCtrl.text,
        firstName: _firstNameCtrl.text.trim(),
        lastName: _lastNameCtrl.text.trim(),
        preferredLevel: _selectedLevel ?? '',
        learningGoal: _selectedGoal ?? '',
      );
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AccountCreatedScreen()),
        (route) => false,
      );
    } on Exception catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) {
        setState(() {
          _isRegistering = false;
        });
      }
    }
  }

  Widget _buildLabeledField({
    required String label,
    required TextEditingController controller,
    IconData? prefixIcon,
    bool isPassword = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.labelMedium),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: AppColors.bgWhite,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: TextField(
            controller: controller,
            obscureText: isPassword,
            style: AppTextStyles.bodyLarge,
            decoration: InputDecoration(
              prefixIcon: prefixIcon != null
                  ? Icon(prefixIcon, color: AppColors.primary, size: 18)
                  : null,
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

class _SelectionTile extends StatelessWidget {
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const _SelectionTile({
    required this.title,
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
          color: isSelected ? AppColors.primary.withOpacity(0.08) : AppColors.bgWhite,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.borderLight,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? AppColors.primary : Colors.transparent,
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.textMuted,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 12, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
            Text(title, style: AppTextStyles.bodyLarge),
          ],
        ),
      ),
    );
  }
}

class _ChipOption extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ChipOption({
    required this.label,
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
          color: isSelected ? AppColors.primary : AppColors.bgWhite,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.borderLight,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _OtpBox extends StatelessWidget {
  final String digit;
  const _OtpBox({required this.digit});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 52,
      decoration: BoxDecoration(
        color: AppColors.bgWhite,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderLight, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
          ),
        ],
      ),
      child: Center(
        child: Text(
          digit.trim().isEmpty ? '' : digit,
          style: const TextStyle(fontSize: 20, letterSpacing: 2),
        ),
      ),
    );
  }
}

class _NextButton extends StatelessWidget {
  final VoidCallback onTap;
  const _NextButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Next',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.arrow_forward_rounded,
              color: AppColors.primary, size: 22),
        ],
      ),
    );
  }
}
