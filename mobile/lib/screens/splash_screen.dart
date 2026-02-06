import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import '../config/theme.dart';
import '../services/profile_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

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

    _controller.forward();
    _checkAuth();
  }

  @override
  void dispose() {
    _controller.dispose();
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
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.primaryDark,
              AppTheme.primary,
              AppTheme.primaryLight,
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
                  // Logo Container
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.favorite,
                      size: 60,
                      color: AppTheme.primary,
                    ),
                  ),
                  const SizedBox(height: 30),
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
                  const SizedBox(height: 10),
                  Text(
                    'Find Your Perfect Match',
                    style: GoogleFonts.poppins(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 16,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                  const SizedBox(height: 50),
                  // Loading Indicator
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.white.withOpacity(0.8),
                      ),
                      strokeWidth: 3,
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
