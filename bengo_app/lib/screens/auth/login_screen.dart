import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/api_service.dart';
import '../main_shell.dart';
import 'create_account_screen.dart';

// ── Design tokens ────────────────────────────────────────────────────────────
const _kBg = Color(0xFFFAF8F5);
const _kSurface = Color(0xFFFFFFFF);
const _kAccent = Color(0xFFC41230);
const _kAccentShadow = Color(0x40C41230);
const _kInk = Color(0xFF1B1B1D);
const _kFieldTint = Color(0xFFFDF3F5); // light red tint fill
const _kFieldBorder = Color(0xFFEDD5D8);
const _kFieldBorderFocus = Color(0xFFC41230);
const _kMuted = Color(0xFF8A8A8F);
const _kDivider = Color(0xFFE5E0DC);

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  bool _obscurePassword = true;
  bool _isLoading = false;
  String _errorMsg = '';

  late final AnimationController _enterCtrl;
  late final Animation<double> _fadeIn;
  late final Animation<Offset> _slideUp;

  @override
  void initState() {
    super.initState();
    _enterCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeIn = CurvedAnimation(parent: _enterCtrl, curve: Curves.easeOut);
    _slideUp = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _enterCtrl, curve: Curves.easeOut));
    _enterCtrl.forward();
  }

  @override
  void dispose() {
    _enterCtrl.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: FadeTransition(
                  opacity: _fadeIn,
                  child: SlideTransition(
                    position: _slideUp,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // ── Logo ──────────────────────────────────────────
                        _LogoWidget(),
                        const SizedBox(height: 4),
                        // ── Word-mark ─────────────────────────────────────
                        Text(
                          'BenGo',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 36,
                            fontWeight: FontWeight.w700,
                            color: _kInk,
                            letterSpacing: -1,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'MASTERY THROUGH FOCUS',
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 2.8,
                            color: _kMuted,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // ── Form card ─────────────────────────────────────
                        Container(
                          decoration: BoxDecoration(
                            color: _kSurface,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x0C000000),
                                blurRadius: 24,
                                offset: Offset(0, 8),
                              ),
                              BoxShadow(
                                color: Color(0x06000000),
                                blurRadius: 6,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.fromLTRB(22, 26, 22, 26),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Heading
                              Text(
                                'Welcome back',
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: _kInk,
                                  letterSpacing: -0.4,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Sign in to continue your session',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: _kMuted,
                                ),
                              ),
                              const SizedBox(height: 22),

                              // Email or username
                              _FieldLabel(label: 'Email address or username'),
                              const SizedBox(height: 6),
                              _M3FilledField(
                                controller: _emailController,
                                focusNode: _emailFocus,
                                hint: 'student@bengo.edu or student123',
                                prefixIcon: Icons.alternate_email_rounded,
                                keyboardType: TextInputType.emailAddress,
                                onSubmitted: (_) => _passwordFocus.requestFocus(),
                              ),
                              const SizedBox(height: 16),

                              // Password
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const _FieldLabel(label: 'Password'),
                                  GestureDetector(
                                    onTap: () {},
                                    child: Text(
                                      'Forgot password?',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: _kAccent,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              _M3FilledField(
                                controller: _passwordController,
                                focusNode: _passwordFocus,
                                hint: '••••••••',
                                prefixIcon: Icons.lock_outline_rounded,
                                isPassword: true,
                                obscureText: _obscurePassword,
                                onToggleObscure: () => setState(
                                    () => _obscurePassword = !_obscurePassword),
                                onSubmitted: (_) { if (!_isLoading) _login(); },
                              ),
                              const SizedBox(height: 20),

                              // Error banner
                              if (_errorMsg.isNotEmpty) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFF0F2),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                        color: const Color(0xFFFFCDD2),
                                        width: 1),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.error_outline_rounded,
                                          color: _kAccent, size: 16),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          _errorMsg,
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            color: _kAccent,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],

                              // Primary CTA — pill, colored shadow
                              _PillButton(
                                label: 'Enter Session',
                                isLoading: _isLoading,
                                onPressed: _isLoading ? null : _login,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 28),

                        // ── Divider ───────────────────────────────────────
                        Row(
                          children: [
                            Expanded(
                                child: Divider(
                                    color: _kDivider, thickness: 1)),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 14),
                              child: Text(
                                'or continue with',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: _kMuted,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                            Expanded(
                                child: Divider(
                                    color: _kDivider, thickness: 1)),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // ── Social buttons ────────────────────────────────
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _SocialButton(
                              onTap: () {},
                              label: 'Google',
                              icon: _GoogleSvgIcon(),
                            ),
                            const SizedBox(width: 14),
                            _SocialButton(
                              onTap: () {},
                              label: 'Apple',
                              icon: const Icon(Icons.apple,
                                  color: _kInk, size: 22),
                            ),
                            const SizedBox(width: 14),
                            _SocialButton(
                              onTap: () {},
                              label: 'SSO',
                              icon: const Icon(
                                  Icons.business_center_outlined,
                                  color: _kInk,
                                  size: 20),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),

                        // ── Sign-up link ──────────────────────────────────
                        GestureDetector(
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => const CreateAccountScreen()),
                          ),
                          child: RichText(
                            textAlign: TextAlign.center,
                            text: TextSpan(
                              text: "New to BenGo? ",
                              style: GoogleFonts.inter(
                                  fontSize: 13, color: _kMuted),
                              children: [
                                TextSpan(
                                  text: 'Create an account',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: _kAccent,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
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

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
      _errorMsg = '';
    });
    try {
      await ApiService.instance.login(
        identifier: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainShell()),
      );
    } on ApiException catch (e) {
      setState(() => _errorMsg =
          e.message.replaceAll(RegExp(r'[{}\[\]]'), ''));
    } catch (_) {
      setState(() => _errorMsg = 'Could not connect to server.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}

// ── Logo widget — dark monogram in squircle with focus-ring arc ─────────────
class _LogoWidget extends StatefulWidget {
  @override
  State<_LogoWidget> createState() => _LogoWidgetState();
}

class _LogoWidgetState extends State<_LogoWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _arcCtrl;
  late final Animation<double> _arcAnim;

  @override
  void initState() {
    super.initState();
    _arcCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: false);
    _arcAnim = CurvedAnimation(parent: _arcCtrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _arcCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 110,
      height: 110,
      child: AnimatedBuilder(
        animation: _arcAnim,
        builder: (_, __) {
          return CustomPaint(
            painter: _FocusRingArcPainter(progress: _arcAnim.value),
                child: Center(
                  child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x28000000),
                      blurRadius: 18,
                      offset: Offset(0, 8),
                      spreadRadius: -2,
                    ),
                    BoxShadow(
                      color: Color(0x12000000),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: 56,
                    height: 56,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// Draws a rounded-square arc that sweeps around the logo, like a focus ring
class _FocusRingArcPainter extends CustomPainter {
  final double progress;
  _FocusRingArcPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..color = _kAccent.withOpacity(0.85);

    const padding = 6.0;
    final rect = Rect.fromLTWH(
      padding,
      padding,
      size.width - padding * 2,
      size.height - padding * 2,
    );
    const radius = 26.0;
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(radius));

    // Perimeter-based sweep: progress 0→1 sweeps once around the ring
    final sweepAngle = math.pi * 2 * 0.35; // 35% arc visible
    final startAngle = -math.pi / 2 + (math.pi * 2 * progress);

    final path = Path()..addRRect(rrect);
    final metrics = path.computeMetrics().first;
    final totalLen = metrics.length;
    final arcLen = totalLen * 0.35;
    final startLen = totalLen * progress;

    // Draw the arc segment along the rrect path
    final segPath = metrics.extractPath(
      startLen % totalLen,
      (startLen + arcLen) % totalLen,
    );
    // Handle wrap-around
    if (startLen + arcLen > totalLen) {
      final wrapPath = metrics.extractPath(0, (startLen + arcLen) - totalLen);
      canvas.drawPath(segPath, paint);
      canvas.drawPath(wrapPath, paint);
    } else {
      canvas.drawPath(segPath, paint);
    }
  }

  @override
  bool shouldRepaint(_FocusRingArcPainter old) => old.progress != progress;
}

// ── M3 Filled field — top-rounded, bottom-flat (M3 spec) ───────────────────
class _M3FilledField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String hint;
  final IconData prefixIcon;
  final bool isPassword;
  final bool obscureText;
  final VoidCallback? onToggleObscure;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onSubmitted;

  const _M3FilledField({
    required this.controller,
    required this.focusNode,
    required this.hint,
    required this.prefixIcon,
    this.isPassword = false,
    this.obscureText = false,
    this.onToggleObscure,
    this.keyboardType,
    this.onSubmitted,
  });

  @override
  State<_M3FilledField> createState() => _M3FilledFieldState();
}

class _M3FilledFieldState extends State<_M3FilledField> {
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    setState(() => _focused = widget.focusNode.hasFocus);
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFocusChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
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
            color: _focused ? _kFieldBorderFocus : _kFieldBorder,
            width: _focused ? 2 : 1,
          ),
        ),
      ),
      child: TextField(
        controller: widget.controller,
        focusNode: widget.focusNode,
        obscureText: widget.isPassword && widget.obscureText,
        keyboardType: widget.keyboardType,
        onSubmitted: widget.onSubmitted,
        style: GoogleFonts.inter(
          fontSize: 15,
          color: _kInk,
          fontWeight: FontWeight.w500,
        ),
        cursorColor: _kAccent,
        decoration: InputDecoration(
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 14, right: 10),
            child: Icon(
              widget.prefixIcon,
              color: _focused ? _kAccent : _kMuted,
              size: 20,
            ),
          ),
          prefixIconConstraints:
              const BoxConstraints(minWidth: 48, minHeight: 52),
          suffixIcon: widget.isPassword
              ? IconButton(
                  icon: Icon(
                    widget.obscureText
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: _kMuted,
                    size: 20,
                  ),
                  onPressed: widget.onToggleObscure,
                )
              : null,
          hintText: widget.hint,
          hintStyle:
              GoogleFonts.inter(color: _kMuted.withOpacity(0.7), fontSize: 14),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 0, vertical: 16),
        ),
      ),
    );
  }
}

// ── Field label ─────────────────────────────────────────────────────────────
class _FieldLabel extends StatelessWidget {
  final String label;
  const _FieldLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: _kInk.withOpacity(0.75),
        letterSpacing: 0.1,
      ),
    );
  }
}

// ── Pill CTA button with elevation shadow ────────────────────────────────────
class _PillButton extends StatefulWidget {
  final String label;
  final bool isLoading;
  final VoidCallback? onPressed;

  const _PillButton({
    required this.label,
    required this.isLoading,
    this.onPressed,
  });

  @override
  State<_PillButton> createState() => _PillButtonState();
}

class _PillButtonState extends State<_PillButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onPressed?.call();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 54,
          decoration: BoxDecoration(
            color: widget.onPressed == null
                ? _kAccent.withOpacity(0.5)
                : _kAccent,
            borderRadius: BorderRadius.circular(100),
            boxShadow: widget.onPressed == null
                ? []
                : [
                    BoxShadow(
                      color: _kAccentShadow,
                      blurRadius: 0,
                      offset: const Offset(0, 4),
                      spreadRadius: 0,
                    ),
                    BoxShadow(
                      color: _kAccentShadow.withOpacity(0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 8),
                    ),
                  ],
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
                      letterSpacing: 0.4,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

// ── Outlined rounded-square social button ────────────────────────────────────
class _SocialButton extends StatefulWidget {
  final VoidCallback onTap;
  final String label;
  final Widget icon;

  const _SocialButton({
    required this.onTap,
    required this.label,
    required this.icon,
  });

  @override
  State<_SocialButton> createState() => _SocialButtonState();
}

class _SocialButtonState extends State<_SocialButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _hovered = true),
      onTapUp: (_) => setState(() => _hovered = false),
      onTapCancel: () => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 88,
        height: 50,
        decoration: BoxDecoration(
          color: _hovered ? const Color(0xFFFAF0F1) : _kSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _hovered ? _kAccent.withOpacity(0.4) : _kDivider,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            widget.icon,
            const SizedBox(width: 6),
            Text(
              widget.label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _kInk,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Google colour icon ───────────────────────────────────────────────────────
class _GoogleSvgIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Four-colour G drawn with Text widgets layered
    return const SizedBox(
      width: 18,
      height: 18,
      child: _GooglePainterWidget(),
    );
  }
}

class _GooglePainterWidget extends StatelessWidget {
  const _GooglePainterWidget();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _GoogleIconPainter());
  }
}

class _GoogleIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;

    // Draw a simplified 4-color G
    final paint = Paint()..style = PaintingStyle.fill;

    // Blue sector
    paint.color = const Color(0xFF4285F4);
    canvas.drawArc(Rect.fromCircle(center: c, radius: r),
        -math.pi / 2, math.pi / 2, true, paint);
    // Red sector
    paint.color = const Color(0xFFEA4335);
    canvas.drawArc(Rect.fromCircle(center: c, radius: r),
        math.pi, math.pi / 2, true, paint);
    // Yellow sector
    paint.color = const Color(0xFFFBBC04);
    canvas.drawArc(Rect.fromCircle(center: c, radius: r),
        math.pi * 1.5, math.pi / 2, true, paint);
    // Green sector
    paint.color = const Color(0xFF34A853);
    canvas.drawArc(Rect.fromCircle(center: c, radius: r),
        0, math.pi / 2, true, paint);

    // White circle in centre
    paint.color = Colors.white;
    canvas.drawCircle(c, r * 0.55, paint);

    // "G" bar — white horizontal right extension
    final barPaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(c.dx, c.dy - r * 0.18, r * 0.95, r * 0.36),
        const Radius.circular(2),
      ),
      barPaint,
    );

    // Small white cover on the right half of centre
    paint.color = Colors.white;
    canvas.drawCircle(c, r * 0.38, paint);
  }

  @override
  bool shouldRepaint(_GoogleIconPainter old) => false;
}
