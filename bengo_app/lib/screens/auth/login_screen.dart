import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../../services/api_service.dart';
import '../main_shell.dart';
import 'create_account_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String _errorMsg = '';
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _emailController.text = '';
    _passwordController.text = '';
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: SlideTransition(
                    position: _slideAnim,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Skeuomorphic brand header
                        Container(
                          width: 180,
                          height: 180,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30),
                            gradient: const LinearGradient(
                              begin: Alignment(-0.8, -0.6),
                              end: Alignment(0.8, 0.6),
                              colors: [Color(0xFFEAF2FF), Color(0xFFD9E8FF)],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.white.withOpacity(0.9),
                                offset: const Offset(-8, -8),
                                blurRadius: 16,
                              ),
                              BoxShadow(
                                color: Colors.black.withOpacity(0.12),
                                offset: const Offset(8, 8),
                                blurRadius: 20,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text('BenGo',
                                style: AppTextStyles.brandName.copyWith(
                                    fontSize: 42,
                                    shadows: [
                                      const Shadow(
                                        color: Colors.white70,
                                        offset: Offset(-1, -1),
                                        blurRadius: 0,
                                      ),
                                      Shadow(
                                        color: Colors.black.withOpacity(0.18),
                                        offset: const Offset(2, 2),
                                        blurRadius: 6,
                                      ),
                                    ])),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'MASTERY THROUGH FOCUS',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 3,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 28),
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.bgWhite,
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.06),
                                blurRadius: 26,
                                offset: const Offset(0, 16),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 28),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildFieldLabel('Email Address'),
                              const SizedBox(height: 10),
                              _buildTextField(
                                controller: _emailController,
                                hint: 'student@bengo.edu',
                                prefixIcon: Icons.mail_outline_rounded,
                              ),
                              const SizedBox(height: 20),
                              _buildFieldLabel('Password'),
                              const SizedBox(height: 10),
                              _buildTextField(
                                controller: _passwordController,
                                hint: '••••••••',
                                prefixIcon: Icons.lock_outline_rounded,
                                isPassword: true,
                              ),
                              const SizedBox(height: 22),
                              if (_errorMsg.isNotEmpty)
                                Container(
                                  margin: const EdgeInsets.only(bottom: 14),
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: Colors.red.shade100),
                                  ),
                                  child: Text(
                                    _errorMsg,
                                    style: GoogleFonts.inter(color: Colors.red.shade700, fontSize: 13),
                                  ),
                                ),
                              SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _login,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                        )
                                      : Text(
                                          'ENTER SESSION',
                                          style: GoogleFonts.inter(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 1.6,
                                          ),
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                        Row(
                          children: [
                            Expanded(child: Divider(color: AppColors.textSecondary.withOpacity(0.25))),
                            const SizedBox(width: 14),
                            Text('OR CONNECT', style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary)),
                            const SizedBox(width: 14),
                            Expanded(child: Divider(color: AppColors.textSecondary.withOpacity(0.25))),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _SocialButton(
                              onTap: () {},
                              child: _GoogleIcon(),
                            ),
                            const SizedBox(width: 18),
                            _SocialButton(
                              onTap: () {},
                              child: const Icon(Icons.apple, color: Colors.black, size: 24),
                              backgroundColor: AppColors.bgWhite,
                            ),
                          ],
                        ),
                        const SizedBox(height: 34),
                        GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const CreateAccountScreen()),
                            );
                          },
                          child: RichText(
                            textAlign: TextAlign.center,
                            text: TextSpan(
                              text: 'New to the Dojo? ',
                              style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
                              children: [
                                TextSpan(
                                  text: 'CREATE ACCOUNT',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ],
                            ),
                          ),
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
    );
  }

  Future<void> _login() async {
    setState(() { _isLoading = true; _errorMsg = ''; });
    try {
      await ApiService.instance.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainShell()),
      );
    } on ApiException catch (e) {
      setState(() => _errorMsg = e.message.replaceAll(RegExp(r'[{}\[\]]'), ''));
    } catch (e) {
      setState(() => _errorMsg = 'Could not connect to server.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label.toUpperCase(),
      style: GoogleFonts.inter(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.5,
        color: AppColors.textSecondary,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData prefixIcon,
    bool isPassword = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FD),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8EDF5)),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword && _obscurePassword,
        style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 15),
        decoration: InputDecoration(
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 12, right: 8),
            child: Icon(prefixIcon, color: AppColors.primary, size: 20),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                  onPressed: () {
                    setState(() => _obscurePassword = !_obscurePassword);
                  },
                )
              : null,
          hintText: hint,
          hintStyle: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 14),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final VoidCallback onTap;
  final Widget child;
  final Color backgroundColor;

  const _SocialButton({
    required this.onTap,
    required this.child,
    this.backgroundColor = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 58,
        height: 58,
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Center(child: child),
      ),
    );
  }
}

class _GoogleIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Text(
      'G',
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
    );
  }
}
