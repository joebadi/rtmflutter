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
                                            onPressed: () {},
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

                                        const SizedBox(height: 8),

                                        // Demo Mode (Development)
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: Colors.orange.withOpacity(0.15),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(
                                              color: Colors.orange.withOpacity(0.4),
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              const Icon(
                                                Icons.developer_mode,
                                                color: Colors.orange,
                                                size: 14,
                                              ),
                                              const SizedBox(width: 6),
                                              TextButton(
                                                onPressed: () => context.go('/home'),
                                                style: TextButton.styleFrom(
                                                  padding: EdgeInsets.zero,
                                                  minimumSize: const Size(0, 0),
                                                  tapTargetSize:
                                                      MaterialTapTargetSize.shrinkWrap,
                                                ),
                                                child: Text(
                                                  'Demo Mode - Skip Login',
                                                  style: GoogleFonts.poppins(
                                                    color: Colors.orange,
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                            ],
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
}
