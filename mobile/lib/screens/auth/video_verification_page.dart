import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math';
import '../../widgets/premium_loader.dart';

class VideoVerificationPage extends StatefulWidget {
  const VideoVerificationPage({super.key});

  @override
  State<VideoVerificationPage> createState() => _VideoVerificationPageState();
}

class _VideoVerificationPageState extends State<VideoVerificationPage> {
  bool _isVerifying = false;
  bool _isVerified = false;
  String _currentChallenge = '';
  final List<String> _challenges = [
    'Please smile and wave at the camera',
    'Turn your head slowly to the left',
    'Turn your head slowly to the right',
    'Blink your eyes three times',
    'Say "I am verifying my account"',
    'Show your thumbs up to the camera',
    'Nod your head up and down',
    'Touch your nose with your finger',
  ];

  @override
  void initState() {
    super.initState();
    _generateChallenge();
  }

  void _generateChallenge() {
    final random = Random();
    setState(() {
      _currentChallenge = _challenges[random.nextInt(_challenges.length)];
    });
  }

  void _startVerification() {
    setState(() {
      _isVerifying = true;
    });

    // Simulate AI verification process
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _isVerifying = false;
          _isVerified = true;
        });

        // Auto navigate after success
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            context.go('/complete-profile');
          }
        });
      }
    });
  }

  void _skipVerification() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Skip Verification?',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Video verification helps build trust in our community. You can verify later in settings, but some features may be limited.',
          style: GoogleFonts.poppins(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: Colors.grey[600]),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.go('/complete-profile');
            },
            child: Text(
              'Skip',
              style: GoogleFonts.poppins(
                color: const Color(0xFFFF5722),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => context.pop(),
                  ),
                  TextButton(
                    onPressed: _skipVerification,
                    child: Text(
                      'Skip',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 20),

                    // Title
                    Text(
                      'Video Verification',
                      style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),

                    const SizedBox(height: 12),

                    Text(
                      'Verify your identity to build trust',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 40),

                    // Video Preview Area
                    Container(
                      width: double.infinity,
                      height: 400,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.grey[900]!, Colors.grey[800]!],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          // Camera placeholder
                          Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (!_isVerifying && !_isVerified) ...[
                                  Icon(
                                    Icons.videocam,
                                    size: 80,
                                    color: Colors.white.withOpacity(0.3),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Camera will activate\nwhen you start',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white.withOpacity(0.5),
                                      fontSize: 14,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ] else if (_isVerifying) ...[
                                  const SizedBox(
                                    width: 60,
                                    height: 60,
                                    child: PremiumLoader(
                                      color: Color(0xFFFF5722),
                                      strokeWidth: 4,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  Text(
                                    'Verifying...',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ] else if (_isVerified) ...[
                                  Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withOpacity(0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.check_circle,
                                      size: 80,
                                      color: Colors.green,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  Text(
                                    'Verified Successfully!',
                                    style: GoogleFonts.poppins(
                                      color: Colors.green,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),

                          // AI Badge
                          Positioned(
                            top: 16,
                            right: 16,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFFF5722),
                                    Color(0xFFFF7043),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFFFF5722,
                                    ).withOpacity(0.4),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.psychology,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'AI Powered',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Challenge Card
                    if (!_isVerified)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFFFF5722).withOpacity(0.1),
                              const Color(0xFFFF7043).withOpacity(0.05),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFFFF5722).withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFF5722),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.lightbulb,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Your Challenge',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFFFF5722),
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.refresh,
                                    color: Color(0xFFFF5722),
                                  ),
                                  onPressed: _isVerifying
                                      ? null
                                      : _generateChallenge,
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _currentChallenge,
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                                height: 1.4,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 30),

                    // Benefits
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Why verify?',
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildBenefit(
                            Icons.verified,
                            'Get verified badge on profile',
                          ),
                          _buildBenefit(
                            Icons.security,
                            'Build trust with matches',
                          ),
                          _buildBenefit(Icons.block, 'Prevent fake accounts'),
                          _buildBenefit(Icons.star, 'Unlock premium features'),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Start Button
                    if (!_isVerified)
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: _isVerifying ? null : _startVerification,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF5722),
                            disabledBackgroundColor: Colors.grey[300],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                          child: Text(
                            _isVerifying
                                ? 'Verifying...'
                                : 'Start Verification',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefit(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFFFF5722)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[700]),
            ),
          ),
        ],
      ),
    );
  }
}
