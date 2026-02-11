import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import '../services/profile_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(
      begin: 0.95,
      end: 1.05,
    ).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));

    _controller.forward();
    _checkAuth();
  }

  @override
  void dispose() {
    _controller.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _checkAuth() async {
    // Wait for animation
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    const storage = FlutterSecureStorage();
    final String? seenOnboarding = await storage.read(key: 'seenOnboarding');

    final authProvider = context.read<AuthProvider>();
    await authProvider.checkAuthStatus();

    if (mounted) {
      // Priority: Onboarding → Login → Profile Check → Home
      if (seenOnboarding != 'true') {
        context.go('/onboarding');
      } else if (authProvider.isAuthenticated) {
        // Check profile completion status
        await _routeBasedOnProfileStatus();
      } else {
        context.go('/login');
      }
    }
  }

  Future<void> _routeBasedOnProfileStatus() async {
    try {
      final profileService = ProfileService();
      final profileData = await profileService.getMyProfile();

      if (!mounted) return;

      if (profileData == null || profileData['data'] == null) {
        // No profile data found
        context.go('/profile-details');
        return;
      }

      final user = profileData['data'];

      // 1. Check verified status
      if (user['emailVerified'] == false && user['phoneVerified'] == false) {
        context.push(
          '/otp-verification',
          extra: {
            'phoneNumber': user['phoneNumber'] ?? '',
            'email': user['email'] ?? '',
            'firstName': user['firstName'],
            'lastName': user['lastName'],
          },
        );
        return;
      }

      final profile = user['profile'];

      // 2. Check basic profile details
      if (profile == null ||
          profile['aboutMe'] == null ||
          profile['dateOfBirth'] == null ||
          profile['gender'] == null) {
        
        // Backend stores names in Profile, not User.
        // If profile is null, we can't get names easily unless provided in user object
        // by a custom backend projection, but based on schema it's in Profile.
        // Assuming profile is at least created with names during registration.
        final fName = profile != null ? profile['firstName'] : user['firstName'];
        final lName = profile != null ? profile['lastName'] : user['lastName'];

        context.go(
          '/profile-details',
          extra: {'firstName': fName, 'lastName': lName},
        );
        return;
      }

      // 3. Check photos
      if (profile['photos'] == null || (profile['photos'] as List).isEmpty) {
        context.go('/image-upload');
        return;
      }

      // 4. Check preferences (Optional but good to check)
      // if (profile['preferences'] == null) {
      //   context.go('/preferred-partner');
      //   return;
      // }

      // All good - go to home
      context.go('/home');
    } catch (e) {
      print('Error checking profile status: $e');
      // Fallback: If network fails, maybe let them go home or stay on splash with retry?
      // For now, let's go home and let the home page handle errors/empty state
      if (mounted) context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1A1A2E),
              Color(0xFF16213E),
              Color(0xFF0F3460),
            ],
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Pulsing Logo with glow
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _pulseAnimation.value,
                        child: Container(
                          width: 130,
                          height: 130,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xFFFF6B35),
                                Color(0xFFFF5722),
                                Color(0xFFE64A19),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFF6B35).withOpacity(0.4),
                                blurRadius: 30,
                                spreadRadius: 5,
                              ),
                              BoxShadow(
                                color: const Color(0xFFFF5722).withOpacity(0.2),
                                blurRadius: 60,
                                spreadRadius: 10,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.favorite_rounded,
                            size: 60,
                            color: Colors.white,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 36),
                  // App Name
                  Text(
                    'Ready to Marry',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Find Your Perfect Match',
                    style: GoogleFonts.poppins(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 60),
                  // Premium loading dots
                  const _PremiumLoadingDots(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PremiumLoadingDots extends StatefulWidget {
  const _PremiumLoadingDots();

  @override
  State<_PremiumLoadingDots> createState() => _PremiumLoadingDotsState();
}

class _PremiumLoadingDotsState extends State<_PremiumLoadingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1400),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (index) {
            final delay = index * 0.2;
            final progress = (_controller.value - delay).clamp(0.0, 1.0);
            final bounce = (progress < 0.5)
                ? Curves.easeOut.transform(progress * 2)
                : Curves.easeIn.transform((1 - progress) * 2);

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 5),
              child: Transform.translate(
                offset: Offset(0, -8 * bounce),
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: Color.lerp(
                      const Color(0xFFFF6B35).withOpacity(0.4),
                      const Color(0xFFFF6B35),
                      bounce,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF6B35).withOpacity(0.3 * bounce),
                        blurRadius: 8,
                        spreadRadius: 2 * bounce,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
