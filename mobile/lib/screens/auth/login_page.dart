import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/auth_provider.dart';
import '../../services/profile_service.dart';
import '../../widgets/premium_loader.dart';
import '../../widgets/premium_message.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _emailFocus = FocusNode();
  final _passFocus = FocusNode();
  bool _obscurePassword = true;
  bool _emailFocused = false;
  bool _passFocused = false;

  late final AnimationController _entrance;
  late final AnimationController _shake;
  late final Animation<double> _fadeIn;
  late final Animation<Offset> _slideUp;
  late final Animation<Offset> _shakeAnim;

  @override
  void initState() {
    super.initState();

    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _shake = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );

    _fadeIn = CurvedAnimation(
      parent: _entrance,
      curve: const Interval(0.0, 0.75, curve: Curves.easeOutCubic),
    );
    _slideUp = Tween<Offset>(
      begin: const Offset(0, 0.22),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entrance,
      curve: const Interval(0.0, 0.85, curve: Curves.easeOutBack),
    ));
    _shakeAnim = TweenSequence<Offset>([
      TweenSequenceItem(tween: Tween(begin: Offset.zero, end: const Offset(0.025, 0)), weight: 1),
      TweenSequenceItem(tween: Tween(begin: const Offset(0.025, 0), end: const Offset(-0.025, 0)), weight: 2),
      TweenSequenceItem(tween: Tween(begin: const Offset(-0.025, 0), end: const Offset(0.016, 0)), weight: 2),
      TweenSequenceItem(tween: Tween(begin: const Offset(0.016, 0), end: const Offset(-0.01, 0)), weight: 2),
      TweenSequenceItem(tween: Tween(begin: const Offset(-0.01, 0), end: Offset.zero), weight: 1),
    ]).animate(CurvedAnimation(parent: _shake, curve: Curves.easeInOut));

    _emailFocus.addListener(() => setState(() => _emailFocused = _emailFocus.hasFocus));
    _passFocus.addListener(() => setState(() => _passFocused = _passFocus.hasFocus));

    WidgetsBinding.instance.addPostFrameCallback((_) => _entrance.forward());
  }

  @override
  void dispose() {
    _entrance.dispose();
    _shake.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _emailFocus.dispose();
    _passFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      HapticFeedback.lightImpact();
      _shake.forward(from: 0);
      return;
    }

    final auth = context.read<AuthProvider>();
    final success = await auth.login(
      _emailCtrl.text.trim(),
      _passCtrl.text.trim(),
    );

    if (!success) {
      if (mounted) {
        HapticFeedback.mediumImpact();
        _shake.forward(from: 0);
        showPremiumSnack(context, auth.error ?? 'Login failed', kind: MessageKind.error);
      }
      return;
    }

    if (!mounted) return;
    HapticFeedback.selectionClick();

    try {
      final profileService = ProfileService();
      final profileData = await profileService.getMyProfile();

      if (profileData == null || profileData['data'] == null) {
        if (mounted) context.go('/profile-details');
        return;
      }

      final user = profileData['data'];

      if (user['emailVerified'] == false) {
        if (mounted) {
          context.push('/otp-verification', extra: {
            'phoneNumber': user['phoneNumber'] ?? '',
            'email': user['email'] ?? '',
            'firstName': user['firstName'],
            'lastName': user['lastName'],
          });
        }
        return;
      }

      final profile = user['profile'];
      if (profile == null || profile['dateOfBirth'] == null || profile['gender'] == null) {
        if (mounted) {
          context.go('/profile-details', extra: {
            'firstName': user['firstName'],
            'lastName': user['lastName'],
          });
        }
        return;
      }

      final photos = profile['photos'] as List?;
      if (photos == null || photos.isEmpty) {
        if (mounted) context.go('/image-upload');
        return;
      }

      if (profile['aboutMe'] == null) {
        if (mounted) context.go('/complete-profile');
        return;
      }

      if (mounted) context.go('/home');
    } catch (_) {
      if (mounted) context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/images/login_bg.png', fit: BoxFit.cover),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.15),
                    Colors.black.withOpacity(0.45),
                    Colors.black.withOpacity(0.9),
                  ],
                  stops: const [0.0, 0.42, 0.88],
                ),
              ),
            ),
          ),

          GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            behavior: HitTestBehavior.translucent,
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: _GlassBackButton(onTap: () => context.pop()),
                    ),
                  ),

                  const Expanded(child: SizedBox()),

                  AnimatedPadding(
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeOutCubic,
                    padding: EdgeInsets.fromLTRB(
                      16, 0, 16,
                      keyboardHeight > 0 ? keyboardHeight + 10 : 24,
                    ),
                    child: FadeTransition(
                      opacity: _fadeIn,
                      child: SlideTransition(
                        position: _slideUp,
                        child: SlideTransition(
                          position: _shakeAnim,
                          child: _buildCard(auth),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(AuthProvider auth) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 26, sigmaY: 26),
        child: Container(
          padding: const EdgeInsets.fromLTRB(22, 26, 22, 18),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.09),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withOpacity(0.14), width: 1),
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Welcome back',
                  style: GoogleFonts.poppins(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.4,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Sign in to continue your journey',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.5),
                  ),
                ),

                const SizedBox(height: 22),

                _GlassField(
                  controller: _emailCtrl,
                  focusNode: _emailFocus,
                  isFocused: _emailFocused,
                  label: 'Email',
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  onFieldSubmitted: (_) => FocusScope.of(context).requestFocus(_passFocus),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Email is required';
                    if (!v.contains('@')) return 'Enter a valid email';
                    return null;
                  },
                ),

                const SizedBox(height: 10),

                _GlassField(
                  controller: _passCtrl,
                  focusNode: _passFocus,
                  isFocused: _passFocused,
                  label: 'Password',
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _submit(),
                  suffixIcon: GestureDetector(
                    onTap: () => setState(() => _obscurePassword = !_obscurePassword),
                    child: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: _passFocused
                          ? Colors.white.withOpacity(0.8)
                          : Colors.white.withOpacity(0.4),
                      size: 20,
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Password is required';
                    if (v.length < 6) return 'Min 6 characters';
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                _GradientButton(
                  isLoading: auth.isLoading,
                  label: 'Sign in',
                  onPressed: _submit,
                ),

                const SizedBox(height: 8),

                Center(
                  child: TextButton(
                    onPressed: () => _showForgotPasswordSheet(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'Forgot password?',
                      style: GoogleFonts.poppins(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 2),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account? ",
                      style: GoogleFonts.poppins(
                        color: Colors.white.withOpacity(0.55),
                        fontSize: 13,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        context.push('/register');
                      },
                      child: Text(
                        'Sign up',
                        style: GoogleFonts.poppins(
                          color: const Color(0xFFFF5722),
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showForgotPasswordSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _ForgotPasswordSheet(),
    );
  }
}

// ─── Glass back button ────────────────────────────────────────────────────────

class _GlassBackButton extends StatelessWidget {
  final VoidCallback onTap;
  const _GlassBackButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.18)),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
              size: 16,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Animated glass input field ──────────────────────────────────────────────

class _GlassField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isFocused;
  final String label;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onFieldSubmitted;
  final String? Function(String?)? validator;
  final bool obscureText;
  final Widget? suffixIcon;

  const _GlassField({
    required this.controller,
    required this.focusNode,
    required this.isFocused,
    required this.label,
    this.keyboardType,
    this.textInputAction,
    this.onFieldSubmitted,
    this.validator,
    this.obscureText = false,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: isFocused
            ? [
                BoxShadow(
                  color: const Color(0xFFFF5722).withOpacity(0.22),
                  blurRadius: 18,
                  offset: const Offset(0, 4),
                ),
              ]
            : [],
      ),
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        onFieldSubmitted: onFieldSubmitted,
        validator: validator,
        obscureText: obscureText,
        autocorrect: false,
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        cursorColor: const Color(0xFFFF5722),
        cursorWidth: 1.5,
        cursorRadius: const Radius.circular(2),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.poppins(
            color: isFocused
                ? const Color(0xFFFF5722)
                : Colors.white.withOpacity(0.45),
            fontSize: 14,
          ),
          floatingLabelStyle: GoogleFonts.poppins(
            color: const Color(0xFFFF5722),
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.4,
          ),
          floatingLabelBehavior: FloatingLabelBehavior.auto,
          suffixIcon: suffixIcon != null
              ? Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: suffixIcon,
                )
              : null,
          filled: true,
          fillColor: isFocused
              ? Colors.white.withOpacity(0.12)
              : Colors.white.withOpacity(0.07),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: Colors.white.withOpacity(0.18),
              width: 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFFF5722), width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.red.withOpacity(0.65), width: 1),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFFF6B6B), width: 1.5),
          ),
          errorStyle: GoogleFonts.poppins(
            color: const Color(0xFFFF6B6B),
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

// ─── Gradient submit button ───────────────────────────────────────────────────

class _GradientButton extends StatefulWidget {
  final bool isLoading;
  final String label;
  final VoidCallback onPressed;

  const _GradientButton({
    required this.isLoading,
    required this.label,
    required this.onPressed,
  });

  @override
  State<_GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<_GradientButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        if (!widget.isLoading) widget.onPressed();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: double.infinity,
          height: 52,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFF5722), Color(0xFFFF7043)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF5722).withOpacity(_pressed ? 0.18 : 0.42),
                blurRadius: _pressed ? 6 : 20,
                offset: Offset(0, _pressed ? 2 : 6),
              ),
            ],
          ),
          child: Center(
            child: widget.isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: PremiumLoader(color: Colors.white, strokeWidth: 2.5),
                  )
                : Text(
                    widget.label,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
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

// ─── Forgot password bottom sheet ────────────────────────────────────────────

class _ForgotPasswordSheet extends StatefulWidget {
  const _ForgotPasswordSheet();

  @override
  State<_ForgotPasswordSheet> createState() => _ForgotPasswordSheetState();
}

class _ForgotPasswordSheetState extends State<_ForgotPasswordSheet> {
  final _emailCtrl = TextEditingController();
  final _tokenCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _emailFocus = FocusNode();

  int _step = 0;
  bool _isLoading = false;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _tokenCtrl.dispose();
    _newPassCtrl.dispose();
    _confirmPassCtrl.dispose();
    _emailFocus.dispose();
    super.dispose();
  }

  Future<void> _sendResetLink() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; _errorMessage = null; });

    final auth = context.read<AuthProvider>();
    final ok = await auth.forgotPassword(_emailCtrl.text.trim());

    if (!mounted) return;
    setState(() => _isLoading = false);
    if (ok) {
      setState(() => _step = 1);
    } else {
      setState(() => _errorMessage = auth.error ?? 'Failed to send reset link');
    }
  }

  Future<void> _resetPassword() async {
    if (_tokenCtrl.text.isEmpty) {
      setState(() => _errorMessage = 'Enter the reset token');
      return;
    }
    if (_newPassCtrl.text.length < 8) {
      setState(() => _errorMessage = 'Password must be at least 8 characters');
      return;
    }
    if (_newPassCtrl.text != _confirmPassCtrl.text) {
      setState(() => _errorMessage = 'Passwords do not match');
      return;
    }

    setState(() { _isLoading = true; _errorMessage = null; });
    final auth = context.read<AuthProvider>();
    final ok = await auth.resetPassword(_tokenCtrl.text.trim(), _newPassCtrl.text);

    if (!mounted) return;
    setState(() => _isLoading = false);
    if (ok) setState(() => _step = 2);
    else setState(() => _errorMessage = auth.error ?? 'Failed to reset password');
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(
            top: BorderSide(color: Colors.white.withOpacity(0.1), width: 1),
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 14, 22, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 22),
                if (_step == 0) _buildEmailStep(),
                if (_step == 1) _buildResetStep(),
                if (_step == 2) _buildSuccessStep(),
                SizedBox(height: MediaQuery.of(context).padding.bottom),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmailStep() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          _sheetIcon(Icons.lock_reset_rounded),
          const SizedBox(height: 16),
          _sheetTitle('Reset Password'),
          const SizedBox(height: 8),
          _sheetSubtitle("Enter your email and we'll send a reset token"),
          const SizedBox(height: 24),
          _sheetField(
            controller: _emailCtrl,
            focusNode: _emailFocus,
            hint: 'Email address',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: (v) {
              if (v == null || v.isEmpty) return 'Email is required';
              if (!v.contains('@')) return 'Enter a valid email';
              return null;
            },
          ),
          if (_errorMessage != null) _errorBox(_errorMessage!),
          const SizedBox(height: 20),
          _sheetButton('Send Reset Token', _isLoading, _sendResetLink),
        ],
      ),
    );
  }

  Widget _buildResetStep() {
    return Column(
      children: [
        _sheetIcon(Icons.mark_email_read_rounded),
        const SizedBox(height: 16),
        _sheetTitle('Check Your Email'),
        const SizedBox(height: 8),
        _sheetSubtitle('Token sent to ${_emailCtrl.text}'),
        const SizedBox(height: 24),
        _sheetField(controller: _tokenCtrl, hint: 'Paste reset token', icon: Icons.key_rounded),
        const SizedBox(height: 10),
        _sheetField(
          controller: _newPassCtrl,
          hint: 'New password (min 8 chars)',
          icon: Icons.lock_outline_rounded,
          obscure: _obscureNew,
          toggleObscure: () => setState(() => _obscureNew = !_obscureNew),
        ),
        const SizedBox(height: 10),
        _sheetField(
          controller: _confirmPassCtrl,
          hint: 'Confirm new password',
          icon: Icons.lock_outline_rounded,
          obscure: _obscureConfirm,
          toggleObscure: () => setState(() => _obscureConfirm = !_obscureConfirm),
        ),
        if (_errorMessage != null) _errorBox(_errorMessage!),
        const SizedBox(height: 20),
        _sheetButton('Reset Password', _isLoading, _resetPassword),
      ],
    );
  }

  Widget _buildSuccessStep() {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_circle_rounded, size: 40, color: Colors.green),
        ),
        const SizedBox(height: 18),
        _sheetTitle('Password Reset!'),
        const SizedBox(height: 8),
        _sheetSubtitle('You can now sign in with your new password.'),
        const SizedBox(height: 28),
        _sheetButton('Back to Login', false, () => Navigator.pop(context)),
      ],
    );
  }

  Widget _sheetIcon(IconData icon) => Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: const Color(0xFFFF5722).withOpacity(0.12),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 30, color: const Color(0xFFFF5722)),
      );

  Widget _sheetTitle(String t) => Text(
        t,
        style: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      );

  Widget _sheetSubtitle(String t) => Text(
        t,
        textAlign: TextAlign.center,
        style: GoogleFonts.poppins(
          fontSize: 13,
          color: Colors.white.withOpacity(0.55),
          height: 1.5,
        ),
      );

  Widget _errorBox(String msg) => Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Container(
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.red.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.error_outline_rounded, color: Colors.red[400], size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  msg,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.red[300],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _sheetField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    FocusNode? focusNode,
    TextInputType? keyboardType,
    bool obscure = false,
    VoidCallback? toggleObscure,
    String? Function(String?)? validator,
  }) {
    final field = TextField(
      controller: controller,
      focusNode: focusNode,
      obscureText: obscure,
      keyboardType: keyboardType,
      style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
      cursorColor: const Color(0xFFFF5722),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.poppins(color: Colors.white.withOpacity(0.3), fontSize: 14),
        prefixIcon: Icon(icon, color: Colors.white.withOpacity(0.35), size: 20),
        suffixIcon: toggleObscure != null
            ? IconButton(
                icon: Icon(
                  obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: Colors.white.withOpacity(0.4),
                  size: 20,
                ),
                onPressed: toggleObscure,
              )
            : null,
        filled: true,
        fillColor: Colors.white.withOpacity(0.06),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.15)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFFF5722), width: 1.5),
        ),
      ),
    );

    if (validator != null) {
      return TextFormField(
        controller: controller,
        focusNode: focusNode,
        keyboardType: keyboardType,
        validator: validator,
        style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
        cursorColor: const Color(0xFFFF5722),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.poppins(color: Colors.white.withOpacity(0.3), fontSize: 14),
          prefixIcon: Icon(icon, color: Colors.white.withOpacity(0.35), size: 20),
          filled: true,
          fillColor: Colors.white.withOpacity(0.06),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.15)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFFF5722), width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.red.withOpacity(0.6)),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFFF6B6B), width: 1.5),
          ),
          errorStyle: GoogleFonts.poppins(color: const Color(0xFFFF6B6B), fontSize: 11),
        ),
      );
    }

    return field;
  }

  Widget _sheetButton(String label, bool loading, VoidCallback onTap) => SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed: loading ? null : onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF5722),
            disabledBackgroundColor: const Color(0xFFFF5722).withOpacity(0.4),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 0,
          ),
          child: loading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: PremiumLoader(color: Colors.white, strokeWidth: 2.5),
                )
              : Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
        ),
      );
}
