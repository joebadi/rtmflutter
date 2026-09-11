import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../services/profile_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  static const _brandMark = 'assets/icon/compatible_mark.png';

  late final AnimationController _entranceController;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      duration: const Duration(milliseconds: 1050),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0, 0.72, curve: Curves.easeOutCubic),
    );
    _scaleAnimation = Tween<double>(begin: 0.88, end: 1).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0, 0.82, curve: Curves.easeOutBack),
      ),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.18), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _entranceController,
            curve: const Interval(0.16, 1, curve: Curves.easeOutCubic),
          ),
        );

    _entranceController.forward();
    _checkAuth();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  Future<void> _checkAuth() async {
    // Let the brand entrance finish, but begin the real startup work immediately.
    final minimumDisplay = Future<void>.delayed(
      const Duration(milliseconds: 1850),
    );

    String? seenOnboarding;
    final authProvider = context.read<AuthProvider>();

    try {
      const storage = FlutterSecureStorage();
      seenOnboarding = await storage.read(key: 'seenOnboarding');
      await authProvider.checkAuthStatus();
    } catch (error) {
      // Secure storage failures should never leave someone trapped on splash.
      debugPrint('Startup session check failed: $error');
    }

    await minimumDisplay;
    if (!mounted) return;

    // Priority: onboarding -> authentication -> profile completion -> home.
    if (seenOnboarding != 'true') {
      context.go('/onboarding');
    } else if (authProvider.isAuthenticated) {
      await _routeBasedOnProfileStatus();
    } else {
      context.go('/login');
    }
  }

  Future<void> _routeBasedOnProfileStatus() async {
    try {
      final profileData = await ProfileService().getMyProfile();

      if (!mounted) return;
      if (profileData == null || profileData['data'] == null) {
        context.go('/profile-details');
        return;
      }

      final user = profileData['data'];
      if (user['emailVerified'] == false && user['phoneVerified'] == false) {
        context.go(
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
      if (profile == null ||
          profile['aboutMe'] == null ||
          profile['dateOfBirth'] == null ||
          profile['gender'] == null) {
        context.go(
          '/profile-details',
          extra: {
            'firstName': profile?['firstName'] ?? user['firstName'],
            'lastName': profile?['lastName'] ?? user['lastName'],
          },
        );
        return;
      }

      final photos = profile['photos'] as List?;
      if (photos == null || photos.isEmpty) {
        context.go('/image-upload');
        return;
      }

      context.go('/home');
    } catch (error) {
      debugPrint('Profile routing check failed: $error');
      if (mounted) context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF210E18),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _BrandBackdrop(),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxHeight < 650;
                final proposedSize = constraints.maxWidth * 0.42;
                final markSize = proposedSize.clamp(118.0, 166.0);

                return Padding(
                  padding: EdgeInsets.fromLTRB(
                    26,
                    compact ? 16 : 28,
                    26,
                    compact ? 20 : 30,
                  ),
                  child: Column(
                    children: [
                      const Spacer(flex: 3),
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: ScaleTransition(
                          scale: _scaleAnimation,
                          child: _LogoStage(
                            assetPath: _brandMark,
                            markSize: markSize,
                          ),
                        ),
                      ),
                      SizedBox(height: compact ? 18 : 28),
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: SlideTransition(
                          position: _slideAnimation,
                          child: Column(
                            children: [
                              Text(
                                'Compatible',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(
                                  color: const Color(0xFFFFFAF6),
                                  fontSize: compact ? 34 : 41,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -1.25,
                                  height: 1.05,
                                ),
                              ),
                              SizedBox(height: compact ? 8 : 12),
                              Text(
                                'Meaningful connections, rooted in Africa.',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(
                                  color: const Color(
                                    0xFFFFE8DD,
                                  ).withValues(alpha: 0.78),
                                  fontSize: compact ? 12.5 : 14,
                                  fontWeight: FontWeight.w400,
                                  letterSpacing: 0.1,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Spacer(flex: 4),
                      const _BrandLoader(),
                      const SizedBox(height: 18),
                      Text(
                        'MEET WITH INTENTION',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          color: const Color(
                            0xFFF4B860,
                          ).withValues(alpha: 0.82),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 2.5,
                        ),
                      ),
                    ],
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

class _LogoStage extends StatelessWidget {
  const _LogoStage({required this.assetPath, required this.markSize});

  final String assetPath;
  final double markSize;

  @override
  Widget build(BuildContext context) {
    final stageSize = markSize + 62;

    return Semantics(
      image: true,
      label: 'Compatible logo',
      child: SizedBox.square(
        dimension: stageSize,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: stageSize,
              height: stageSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFF45B45).withValues(alpha: 0.20),
                    const Color(0xFFF45B45).withValues(alpha: 0.055),
                    Colors.transparent,
                  ],
                  stops: const [0, 0.56, 1],
                ),
              ),
            ),
            Container(
              width: markSize + 30,
              height: markSize + 30,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.045),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.10),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0B0308).withValues(alpha: 0.32),
                    blurRadius: 32,
                    offset: const Offset(0, 16),
                  ),
                ],
              ),
            ),
            Image.asset(
              assetPath,
              width: markSize,
              height: markSize,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
              excludeFromSemantics: true,
              errorBuilder: (_, __, ___) => Icon(
                Icons.favorite_rounded,
                size: markSize * 0.62,
                color: const Color(0xFFF45B45),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BrandBackdrop extends StatelessWidget {
  const _BrandBackdrop();

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF180B14),
                  Color(0xFF3A1128),
                  Color(0xFF210E18),
                ],
                stops: [0, 0.5, 1],
              ),
            ),
          ),
          Positioned(
            top: -150,
            right: -130,
            child: _GlowOrb(
              size: 360,
              color: const Color(0xFFF45B45).withValues(alpha: 0.17),
            ),
          ),
          Positioned(
            bottom: -190,
            left: -145,
            child: _GlowOrb(
              size: 410,
              color: const Color(0xFFF4B860).withValues(alpha: 0.10),
            ),
          ),
          const Positioned.fill(
            child: ExcludeSemantics(
              child: CustomPaint(painter: _ConnectionPatternPainter()),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, Colors.transparent]),
      ),
    );
  }
}

class _ConnectionPatternPainter extends CustomPainter {
  const _ConnectionPatternPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = const Color(0xFFF4B860).withValues(alpha: 0.075)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final dotPaint = Paint()
      ..color = const Color(0xFFFFE8DD).withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;

    final topCenter = Offset(size.width * 0.96, size.height * 0.08);
    for (final radius in <double>[92, 132, 172]) {
      canvas.drawArc(
        Rect.fromCircle(center: topCenter, radius: radius),
        math.pi * 0.58,
        math.pi * 0.72,
        false,
        linePaint,
      );
    }

    final bottomCenter = Offset(size.width * 0.02, size.height * 0.90);
    for (var index = 0; index < 8; index++) {
      final angle = -math.pi * 0.44 + index * 0.17;
      final radius = 104 + (index.isEven ? 0 : 18);
      canvas.drawCircle(
        Offset(
          bottomCenter.dx + math.cos(angle) * radius,
          bottomCenter.dy + math.sin(angle) * radius,
        ),
        index % 3 == 0 ? 2.3 : 1.45,
        dotPaint,
      );
    }

    final connectionPath = Path()
      ..moveTo(size.width * 0.10, size.height * 0.31)
      ..cubicTo(
        size.width * 0.28,
        size.height * 0.22,
        size.width * 0.34,
        size.height * 0.43,
        size.width * 0.50,
        size.height * 0.35,
      )
      ..cubicTo(
        size.width * 0.66,
        size.height * 0.27,
        size.width * 0.72,
        size.height * 0.48,
        size.width * 0.90,
        size.height * 0.39,
      );
    canvas.drawPath(connectionPath, linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _BrandLoader extends StatefulWidget {
  const _BrandLoader();

  @override
  State<_BrandLoader> createState() => _BrandLoaderState();
}

class _BrandLoaderState extends State<_BrandLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1250),
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
    return Semantics(
      label: 'Preparing Compatible',
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Container(
            width: 72,
            height: 4,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(99),
            ),
            child: Align(
              alignment: Alignment(-1 + (_controller.value * 2), 0),
              child: Container(
                width: 28,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(99),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF45B45), Color(0xFFF4B860)],
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
