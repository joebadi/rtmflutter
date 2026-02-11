import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/auth_provider.dart';
import '../../services/profile_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscurePassword = true;

  Future<void> _submit() async {
    // Validate form first
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final auth = context.read<AuthProvider>();
    final success = await auth.login(
      _emailCtrl.text.trim(),
      _passCtrl.text.trim(),
    );

    if (!success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(auth.error ?? 'Login failed'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    if (!mounted) return;

    // Check user's onboarding status to route appropriately
    try {
      final profileService = ProfileService();
      final profileData = await profileService.getMyProfile();

      if (profileData == null || profileData['data'] == null) {
        // No profile data - might need OTP verification or profile setup
        // For now, go to profile details
        if (mounted) context.go('/profile-details');
        return;
      }

      final user = profileData['data'];

      // Check if email/phone is verified
      // Check if email is verified (Phone verification is optional/future feature)
      if (user['emailVerified'] == false) {
        // Need to verify OTP
        if (mounted) {
          context.push(
            '/otp-verification',
            extra: {
              'phoneNumber': user['phoneNumber'] ?? '',
              'email': user['email'] ?? '',
              'firstName': user['firstName'],
              'lastName': user['lastName'],
            },
          );
        }
        return;
      }

      // Step 2: Basic Profile (DOB/Gender)
      // Check if firstName/lastName needed? usually in registration
      final profile = user['profile'];
      if (profile == null ||
          profile['dateOfBirth'] == null ||
          profile['gender'] == null) {
        if (mounted) {
          context.go(
            '/profile-details',
            extra: {
              'firstName': user['firstName'],
              'lastName': user['lastName'],
            },
          );
        }
        return;
      }

      // Step 3: Photos
      final photos = profile['photos'] as List?;
      if (photos == null || photos.isEmpty) {
        if (mounted) context.go('/image-upload');
        return;
      }

      // Step 4: Verification (Video) - Optional for now or handled elsewhere?
      // Step 5: Match Preferences
      // Check if matchPreferences exists on user object
      // (Backend needs to include it in getMyProfile response, which it does based on verify_db_data output)
      // However, user['matchPreferences'] might not be in the response of getMyProfile unless included.
      // let's assume if aboutMe is missing, we go to complete profile first.
      
      // Step 6: Complete Profile (Bio/AboutMe)
      if (profile['aboutMe'] == null) {
        if (mounted) context.go('/complete-profile');
        return;
      }

      // Everything complete - go to home
      if (mounted) context.go('/home');
    } catch (e) {
      print('Error checking onboarding status: $e');
      // On error, default to home
      if (mounted) context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Image.asset('assets/images/login_bg.png', fit: BoxFit.cover),
          ),

          // Dark Gradient Overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.2),
                    Colors.black.withOpacity(0.5),
                    Colors.black.withOpacity(0.8),
                  ],
                  stops: const [0.0, 0.5, 0.9],
                ),
              ),
            ),
          ),

          // Content
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: Column(
                        children: [
                          // Back Button
                          Align(
                            alignment: Alignment.topLeft,
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.3),
                                  shape: BoxShape.circle,
                                ),
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.arrow_back,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  onPressed: () => context.pop(),
                                ),
                              ),
                            ),
                          ),

                          const Spacer(),

                          // Glassmorphic Form Card
                          Container(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 20,
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                child: Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.2),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Form(
                                    key: _formKey,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // Title
                                        Text(
                                          'Log in',
                                          style: GoogleFonts.poppins(
                                            fontSize: 28,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          'Welcome back! Sign in to continue',
                                          style: GoogleFonts.poppins(
                                            fontSize: 13,
                                            color: Colors.white.withOpacity(0.8),
                                          ),
                                        ),

                                        const SizedBox(height: 24),

                                        // Email Field
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Email',
                                              style: GoogleFonts.poppins(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.white.withOpacity(0.9),
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            TextFormField(
                                              controller: _emailCtrl,
                                              keyboardType: TextInputType.emailAddress,
                                              style: GoogleFonts.poppins(
                                                color: Colors.black87,
                                                fontSize: 13,
                                              ),
                                              validator: (value) {
                                                if (value == null || value.isEmpty) {
                                                  return 'Email is required';
                                                }
                                                if (!value.contains('@')) {
                                                  return 'Please enter a valid email';
                                                }
                                                return null;
                                              },
                                              decoration: InputDecoration(
                                                hintText: 'Enter your email',
                                                hintStyle: GoogleFonts.poppins(
                                                  color: Colors.grey.shade400,
                                                  fontSize: 13,
                                                ),
                                                filled: true,
                                                fillColor: Colors.white.withOpacity(0.95),
                                                contentPadding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 16,
                                                      vertical: 14,
                                                    ),
                                                enabledBorder: OutlineInputBorder(
                                                  borderRadius: BorderRadius.circular(12),
                                                  borderSide: BorderSide(
                                                    color: Colors.white.withOpacity(0.3),
                                                    width: 1,
                                                  ),
                                                ),
                                                focusedBorder: OutlineInputBorder(
                                                  borderRadius: BorderRadius.circular(12),
                                                  borderSide: const BorderSide(
                                                    color: Color(0xFFFF6B35),
                                                    width: 2,
                                                  ),
                                                ),
                                                errorBorder: OutlineInputBorder(
                                                  borderRadius: BorderRadius.circular(12),
                                                  borderSide: BorderSide(
                                                    color: Colors.red.shade300,
                                                    width: 1,
                                                  ),
                                                ),
                                                focusedErrorBorder: OutlineInputBorder(
                                                  borderRadius: BorderRadius.circular(12),
                                                  borderSide: const BorderSide(
                                                    color: Colors.red,
                                                    width: 2,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),

                                        const SizedBox(height: 12),

                                        // Password Field
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Password',
                                              style: GoogleFonts.poppins(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.white.withOpacity(0.9),
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            TextFormField(
                                              controller: _passCtrl,
                                              obscureText: _obscurePassword,
                                              style: GoogleFonts.poppins(
                                                color: Colors.black87,
                                                fontSize: 13,
                                              ),
                                              validator: (value) {
                                                if (value == null || value.isEmpty) {
                                                  return 'Password is required';
                                                }
                                                if (value.length < 6) {
                                                  return 'Password must be at least 6 characters';
                                                }
                                                return null;
                                              },
                                              decoration: InputDecoration(
                                                hintText: 'Enter your password',
                                                hintStyle: GoogleFonts.poppins(
                                                  color: Colors.grey.shade400,
                                                  fontSize: 13,
                                                ),
                                                filled: true,
                                                fillColor: Colors.white.withOpacity(0.95),
                                                contentPadding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 16,
                                                      vertical: 14,
                                                    ),
                                                suffixIcon: IconButton(
                                                  icon: Icon(
                                                    _obscurePassword
                                                        ? Icons.visibility_off
                                                        : Icons.visibility,
                                                    color: Colors.grey,
                                                    size: 20,
                                                  ),
                                                  onPressed: () => setState(
                                                    () => _obscurePassword =
                                                        !_obscurePassword,
                                                  ),
                                                ),
                                                enabledBorder: OutlineInputBorder(
                                                  borderRadius: BorderRadius.circular(12),
                                                  borderSide: BorderSide(
                                                    color: Colors.white.withOpacity(0.3),
                                                    width: 1,
                                                  ),
                                                ),
                                                focusedBorder: OutlineInputBorder(
                                                  borderRadius: BorderRadius.circular(12),
                                                  borderSide: const BorderSide(
                                                    color: Color(0xFFFF6B35),
                                                    width: 2,
                                                  ),
                                                ),
                                                errorBorder: OutlineInputBorder(
                                                  borderRadius: BorderRadius.circular(12),
                                                  borderSide: BorderSide(
                                                    color: Colors.red.shade300,
                                                    width: 1,
                                                  ),
                                                ),
                                                focusedErrorBorder: OutlineInputBorder(
                                                  borderRadius: BorderRadius.circular(12),
                                                  borderSide: const BorderSide(
                                                    color: Colors.red,
                                                    width: 2,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),

                                        const SizedBox(height: 20),

                                        // Continue Button
                                        SizedBox(
                                          width: double.infinity,
                                          height: 50,
                                          child: ElevatedButton(
                                            onPressed: auth.isLoading ? null : _submit,
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(0xFFFF6B35),
                                              disabledBackgroundColor: const Color(
                                                0xFFFF6B35,
                                              ).withOpacity(0.6),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              elevation: 0,
                                              padding: const EdgeInsets.symmetric(
                                                vertical: 14,
                                              ),
                                            ),
                                            child: auth.isLoading
                                                ? const SizedBox(
                                                    width: 22,
                                                    height: 22,
                                                    child: CircularProgressIndicator(
                                                      color: Colors.white,
                                                      strokeWidth: 2.5,
                                                    ),
                                                  )
                                                : Text(
                                                    'Continue',
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 15,
                                                      fontWeight: FontWeight.w600,
                                                      color: Colors.white,
                                                      letterSpacing: 0.5,
                                                    ),
                                                  ),
                                          ),
                                        ),

                                        const SizedBox(height: 12),

                                        // Forgot Password
                                        Center(
                                          child: TextButton(
                                            onPressed: () => _showForgotPasswordSheet(context),
                                            child: Text(
                                              'Forgot your password?',
                                              style: GoogleFonts.poppins(
                                                color: const Color(0xFFFF6B35),
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ),

                                        const SizedBox(height: 12),

                                        // Sign Up Link
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              "Don't have an account? ",
                                              style: GoogleFonts.poppins(
                                                color: Colors.white.withOpacity(0.8),
                                                fontSize: 13,
                                              ),
                                            ),
                                            TextButton(
                                              onPressed: () => context.push('/register'),
                                              style: TextButton.styleFrom(
                                                padding: EdgeInsets.zero,
                                                minimumSize: const Size(0, 0),
                                                tapTargetSize:
                                                    MaterialTapTargetSize.shrinkWrap,
                                              ),
                                              child: Text(
                                                'Sign up',
                                                style: GoogleFonts.poppins(
                                                  color: const Color(0xFFFF6B35),
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
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
                            ),
                          ),

                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showForgotPasswordSheet(BuildContext context) {
    final emailController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _ForgotPasswordSheet(
        emailController: emailController,
        formKey: formKey,
      ),
    );
  }
}

class _ForgotPasswordSheet extends StatefulWidget {
  final TextEditingController emailController;
  final GlobalKey<FormState> formKey;

  const _ForgotPasswordSheet({
    required this.emailController,
    required this.formKey,
  });

  @override
  State<_ForgotPasswordSheet> createState() => _ForgotPasswordSheetState();
}

class _ForgotPasswordSheetState extends State<_ForgotPasswordSheet> {
  // 0 = email entry, 1 = token+password entry, 2 = success
  int _step = 0;
  bool _isLoading = false;
  String? _errorMessage;
  final _tokenCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  bool _obscureNewPass = true;
  bool _obscureConfirmPass = true;

  @override
  void dispose() {
    _tokenCtrl.dispose();
    _newPassCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendResetLink() async {
    if (!widget.formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final auth = context.read<AuthProvider>();
    final success = await auth.forgotPassword(widget.emailController.text.trim());

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (success) {
      setState(() => _step = 1);
    } else {
      setState(() => _errorMessage = auth.error ?? 'Failed to send reset link');
    }
  }

  Future<void> _resetPassword() async {
    if (_tokenCtrl.text.isEmpty) {
      setState(() => _errorMessage = 'Please enter the reset token');
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

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final auth = context.read<AuthProvider>();
    final success = await auth.resetPassword(
      _tokenCtrl.text.trim(),
      _newPassCtrl.text,
    );

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (success) {
      setState(() => _step = 2);
    } else {
      setState(() => _errorMessage = auth.error ?? 'Failed to reset password');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag handle
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),

                if (_step == 0) _buildEmailStep(),
                if (_step == 1) _buildResetStep(),
                if (_step == 2) _buildSuccessStep(),

                SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmailStep() {
    return Form(
      key: widget.formKey,
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFFFF6B35).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.lock_reset_rounded,
              size: 32,
              color: Color(0xFFFF6B35),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Reset Password',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Enter your email address and we\'ll send\nyou a reset token.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: Colors.grey[600],
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: widget.emailController,
            keyboardType: TextInputType.emailAddress,
            style: GoogleFonts.poppins(fontSize: 14),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Email is required';
              if (!value.contains('@')) return 'Enter a valid email';
              return null;
            },
            decoration: InputDecoration(
              hintText: 'Enter your email',
              hintStyle: GoogleFonts.poppins(color: Colors.grey[400], fontSize: 14),
              prefixIcon: Icon(Icons.email_outlined, color: Colors.grey[400], size: 20),
              filled: true,
              fillColor: Colors.grey[50],
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFFF6B35), width: 1.5),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Colors.red.shade300),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Colors.red, width: 1.5),
              ),
            ),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red[400], size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: GoogleFonts.poppins(fontSize: 12, color: Colors.red[700]),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _sendResetLink,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6B35),
                disabledBackgroundColor: const Color(0xFFFF6B35).withOpacity(0.6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 22, height: 22,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                    )
                  : Text(
                      'Send Reset Token',
                      style: GoogleFonts.poppins(
                        fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResetStep() {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: const Color(0xFFFF6B35).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.mark_email_read_rounded,
            size: 32,
            color: Color(0xFFFF6B35),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Check Your Email',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'We sent a reset token to\n${widget.emailController.text}',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[600], height: 1.5),
        ),
        const SizedBox(height: 24),
        _buildSheetField(
          controller: _tokenCtrl,
          hint: 'Paste reset token',
          icon: Icons.key_rounded,
        ),
        const SizedBox(height: 12),
        _buildSheetField(
          controller: _newPassCtrl,
          hint: 'New password (min 8 chars)',
          icon: Icons.lock_outline_rounded,
          obscure: _obscureNewPass,
          toggleObscure: () => setState(() => _obscureNewPass = !_obscureNewPass),
        ),
        const SizedBox(height: 12),
        _buildSheetField(
          controller: _confirmPassCtrl,
          hint: 'Confirm new password',
          icon: Icons.lock_outline_rounded,
          obscure: _obscureConfirmPass,
          toggleObscure: () => setState(() => _obscureConfirmPass = !_obscureConfirmPass),
        ),
        if (_errorMessage != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red[400], size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: GoogleFonts.poppins(fontSize: 12, color: Colors.red[700]),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _resetPassword,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6B35),
              disabledBackgroundColor: const Color(0xFFFF6B35).withOpacity(0.6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 22, height: 22,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                  )
                : Text(
                    'Reset Password',
                    style: GoogleFonts.poppins(
                      fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessStep() {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_circle_rounded,
            size: 48,
            color: Colors.green,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Password Reset!',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Your password has been reset successfully.\nYou can now log in with your new password.',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[600], height: 1.5),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6B35),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            child: Text(
              'Back to Login',
              style: GoogleFonts.poppins(
                fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSheetField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    VoidCallback? toggleObscure,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: GoogleFonts.poppins(fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.poppins(color: Colors.grey[400], fontSize: 14),
        prefixIcon: Icon(icon, color: Colors.grey[400], size: 20),
        suffixIcon: toggleObscure != null
            ? IconButton(
                icon: Icon(
                  obscure ? Icons.visibility_off : Icons.visibility,
                  color: Colors.grey[400],
                  size: 20,
                ),
                onPressed: toggleObscure,
              )
            : null,
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFFF6B35), width: 1.5),
        ),
      ),
    );
  }
}
