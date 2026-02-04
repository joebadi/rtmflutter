import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      title: 'Find Your\nPerfect Match',
      subtitle: 'Meet New People, Spark Real Connections,\nAnd See Where It Goes.',
      color: const Color(0xFFB85C4E),
    ),
    OnboardingPage(
      title: 'Instant Video\nDates',
      subtitle: 'Connect face-to-face instantly.\nNo more catfishing, just real connections.',
      color: const Color(0xFF7B68EE),
    ),
    OnboardingPage(
      title: 'Secure &\nVerified',
      subtitle: 'Join a community of verified users\nlooking for serious relationships.',
      color: const Color(0xFF667EEA),
    ),
  ];

  Future<void> _completeOnboarding() async {
    const storage = FlutterSecureStorage();
    await storage.write(key: 'seenOnboarding', value: 'true');
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: SafeArea(
        child: Stack(
          children: [
            // Page View
            PageView.builder(
              controller: _pageController,
              itemCount: _pages.length,
              onPageChanged: (index) => setState(() => _currentPage = index),
              itemBuilder: (context, index) {
                return _buildPage(_pages[index], index);
              },
            ),
            
            // Top Bar with App Name and Skip Buttons
            Positioned(
              top: 20,
              left: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Connexa',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Row(
                      children: [
                        // Demo Mode Skip
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.orange),
                          ),
                          child: GestureDetector(
                            onTap: () => context.go('/home'),
                            child: Row(
                              children: [
                                const Icon(Icons.developer_mode, color: Colors.orange, size: 16),
                                const SizedBox(width: 4),
                                Text(
                                  'Demo',
                                  style: GoogleFonts.poppins(
                                    color: Colors.orange,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Regular Skip
                        TextButton(
                          onPressed: _completeOnboarding,
                          child: Text(
                            'Skip',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 16,
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
            
            // Bottom Section (Text areas allow swipe, button remains clickable)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 40, 24, 40),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      const Color(0xFF1A1A1A).withOpacity(0.8),
                      const Color(0xFF1A1A1A),
                    ],
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Title (Allows swipe through)
                    IgnorePointer(
                      child: Text(
                        _pages[_currentPage].title,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Subtitle (Allows swipe through)
                    IgnorePointer(
                      child: Text(
                        _pages[_currentPage].subtitle,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.7),
                          height: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    
                    // Page Indicators (Allows swipe through)
                    IgnorePointer(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          _pages.length,
                          (index) => AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: _currentPage == index ? 24 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _currentPage == index
                                  ? Colors.white
                                  : Colors.white.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    
                    // Get Started Button (Fully interactive)
                    Container(
                      width: double.infinity,
                      height: 60,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2A2A2A),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Row(
                        children: [
                          // Heart Icon
                          Container(
                            margin: const EdgeInsets.all(6),
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: _pages[_currentPage].color,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.favorite,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          // Button Text
                          Expanded(
                            child: Text(
                              _currentPage == _pages.length - 1 ? 'Get Started' : 'Next',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          // Arrow Icon
                          Container(
                            margin: const EdgeInsets.only(right: 16),
                            child: Icon(
                              Icons.arrow_forward,
                              color: Colors.white.withOpacity(0.5),
                              size: 24,
                            ),
                          ),
                        ],
                      ),
                    ).onTap(() {
                      if (_currentPage == _pages.length - 1) {
                        _completeOnboarding();
                      } else {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeInOut,
                        );
                      }
                    }),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(OnboardingPage page, int index) {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Profile Cards (Tilted)
          Positioned(
            top: MediaQuery.of(context).size.height * 0.15,
            child: Transform.rotate(
              angle: -0.1,
              child: _buildProfileCard(
                'https://i.pravatar.cc/300?img=33',
                'Jasmin',
                const Color(0xFF6B4EFF),
                Icons.calendar_today,
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).size.height * 0.2,
            right: MediaQuery.of(context).size.width * 0.15,
            child: Transform.rotate(
              angle: 0.1,
              child: _buildProfileCard(
                'https://i.pravatar.cc/300?img=47',
                'Julia Lode, 27',
                page.color,
                Icons.favorite,
              ),
            ),
          ),
          
          // Floating Icons
          Positioned(
            top: MediaQuery.of(context).size.height * 0.25,
            left: 40,
            child: _buildFloatingIcon(Icons.chat_bubble, const Color(0xFF6B4EFF)),
          ),
          Positioned(
            top: MediaQuery.of(context).size.height * 0.18,
            right: 60,
            child: _buildFloatingIcon(Icons.email, const Color(0xFF4E9FFF)),
          ),
          Positioned(
            top: MediaQuery.of(context).size.height * 0.35,
            right: 40,
            child: _buildFloatingIcon(Icons.favorite, page.color),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard(String imageUrl, String name, Color accentColor, IconData icon) {
    return Container(
      width: 180,
      height: 240,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              imageUrl,
              fit: BoxFit.cover,
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 16,
              left: 16,
              child: Text(
                name,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingIcon(IconData icon, Color color) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.4),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Icon(
        icon,
        color: Colors.white,
        size: 24,
      ),
    );
  }
}

class OnboardingPage {
  final String title;
  final String subtitle;
  final Color color;

  OnboardingPage({
    required this.title,
    required this.subtitle,
    required this.color,
  });
}

extension WidgetExtension on Widget {
  Widget onTap(VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: this,
    );
  }
}
