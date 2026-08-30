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
      debugPrint('Error checking profile status: $e');
      // Fallback: If network fails, maybe let them go home or stay on splash with retry?
      // For now, let's go home and let the home page handle errors/empty state
      if (mounted) context.go('/home');
    }
  }

  // Romantic Pexels hero (verified). Swappable; a gradient fallback renders if
  // it fails to load so the splash always looks premium.
  static const String _heroImage =
      'https://images.pexels.com/photos/1024993/pexels-photo-1024993.jpeg?auto=compress&cs=tinysrgb&w=1200';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF120A07),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background imagery
          Image.network(
            _heroImage,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, progress) =>
                progress == null ? child : _gradientBackdrop(),
            errorBuilder: (_, __, ___) => _gradientBackdrop(),
          ),
          // Readability scrim
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.45),
                  Colors.black.withOpacity(0.35),
                  const Color(0xFF120A07).withOpacity(0.92),
                ],
                stops: const [0.0, 0.45, 1.0],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 5),
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: Column(
                      children: [
                        // Pulsing logo with glow
                        AnimatedBuilder(
                          animation: _pulseAnimation,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _pulseAnimation.value,
                              child: child,
                            );
                          },
                          child: Container(
                            width: 116,
                            height: 116,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.12),
                              border: Border.all(
                                  color: Colors.white.withOpacity(0.25), width: 1.5),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFFF6B35).withOpacity(0.5),
                                  blurRadius: 40,
                                  spreadRadius: 4,
                                ),
                              ],
                            ),
                            child: Image.asset(
                              'assets/icon/app_icon.png',
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.favorite_rounded,
                                size: 52,
                                color: Color(0xFFFF6B35),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),
                        // App name
                        ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [Colors.white, Color(0xFFFFE0D2)],
                          ).createShader(bounds),
                          child: Text(
                            'Compatible',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 42,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.10),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.15)),
                          ),
                          child: Text(
                            'Find someone truly compatible',
                            style: GoogleFonts.poppins(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 13.5,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(flex: 5),
                const _PremiumLoadingDots(),
                const SizedBox(height: 48),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _gradientBackdrop() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2A1206), Color(0xFF16100E), Color(0xFF0F0A14)],
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
