import 'dart:ui';
import 'package:flutter/material.dart';
import 'match_preferences_page.dart';
import '../../widgets/notification_icon.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/profile_provider.dart';
import '../../config/api_config.dart';
import '../../widgets/premium_loader.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfileProvider>().fetchProfile();
    });
  }

  void _showProfileDetails(BuildContext context, Map<String, dynamic> profile) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ProfileDetailsModal(profile: profile),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Consumer<ProfileProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && !provider.hasProfile) {
            return const Center(child: PremiumLoader());
          }

          final profileData = provider.profile?['data']?['profile'];
          
          if (profileData == null) {
             return Center(
               child: Column(
                 mainAxisAlignment: MainAxisAlignment.center,
                 children: [
                   const Text('Unable to load profile'),
                   const SizedBox(height: 10),
                   ElevatedButton(
                     onPressed: () => provider.fetchProfile(),
                     child: const Text('Retry'),
                   )
                 ],
               ),
             );
          }

          final user = profileData['user'] ?? {};
          // Assuming firstName is in profileData or user
          final name = '${profileData['firstName'] ?? ''} ${profileData['lastName'] ?? ''}'.trim();
          final age = profileData['age']?.toString() ?? '?';
          final city = profileData['city'] ?? '';
          final state = profileData['state'] ?? '';
          final country = profileData['country'] ?? '';
          final location = [city, state, country].where((s) => s != null && s.isNotEmpty).join(', ');
          
          // Photos
          final List photos = profileData['photos'] ?? [];
          String? mainPhotoUrl;
          if (photos.isNotEmpty) {
            final primary = photos.firstWhere((p) => p['isPrimary'] == true, orElse: () => photos.first);
            if (primary['url'] != null) {
              mainPhotoUrl = primary['url'];
              if (mainPhotoUrl != null && !mainPhotoUrl.startsWith('http')) {
                mainPhotoUrl = '${ApiConfig.socketUrl}$mainPhotoUrl';
              }
            }
          }
          // Default fallback
          mainPhotoUrl ??= 'https://randomuser.me/api/portraits/men/32.jpg';

          return SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Logo/Brand
                      Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: const BoxDecoration(
                              color: Color(0xFFFF5722),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.favorite,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'ReadytoMarry',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      // Icons
                      Row(
                        children: [
                          const NotificationIcon(),
                          IconButton(
                            icon: const Icon(Icons.search, size: 26),
                            onPressed: () {},
                            color: Colors.black87,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Profile Card
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: GestureDetector(
                      onTap: () => _showProfileDetails(context, profileData),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              // Background Image
                              Image.network(
                                mainPhotoUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(color: Colors.grey);
                                },
                              ),

                              // Gradient Overlay
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.transparent,
                                      Colors.black.withOpacity(0.7),
                                    ],
                                    stops: const [0.5, 1.0],
                                  ),
                                ),
                              ),

                              // Profile Info
                              Positioned(
                                bottom: 0,
                                left: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.transparent,
                                        Colors.black.withOpacity(0.3),
                                      ],
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Name and Verification
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Text(
                                                      name.isNotEmpty ? name : 'User',
                                                      style: GoogleFonts.poppins(
                                                        fontSize: 28,
                                                        fontWeight: FontWeight.bold,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    if (profileData['isVerified'] == true) // Check if verified
                                                    const Icon(
                                                      Icons.verified,
                                                      color: Color(0xFFFF5722),
                                                      size: 24,
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  '$age years old',
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 16,
                                                    color: Colors.white.withOpacity(
                                                      0.9,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),

                                      const SizedBox(height: 12),

                                      // Location
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.location_on,
                                            color: Color(0xFFFF5722),
                                            size: 18,
                                          ),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              location.isNotEmpty ? location : 'No location set',
                                              style: GoogleFonts.poppins(
                                                fontSize: 14,
                                                color: Colors.white.withOpacity(
                                                  0.8,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),

                                      const SizedBox(height: 16),

                                      // Tap to view profile hint
                                      Center(
                                        child: Text(
                                          'Tap to view profile',
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            color: Colors.white.withOpacity(0.6),
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      ),

                                      const SizedBox(height: 16),

                                      // Edit Profile and More Options Buttons (Same Line)
                                      Row(
                                        children: [
                                          // Edit Profile Button (Embossed Orange Gradient with Shine)
                                          Expanded(
                                            child: _ShinyButton(
                                              onTap: () =>
                                                  context.push('/complete-profile', extra: {'isEditing': true}).then((_) => provider.fetchProfile()),
                                              text: 'EDIT PROFILE',
                                            ),
                                          ),

                                          const SizedBox(width: 12),

                                          // More Options Button (3 dots)
                                          Container(
                                            width: 52,
                                            height: 52,
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                color: Colors.white.withOpacity(
                                                  0.5,
                                                ),
                                                width: 1.5,
                                              ),
                                              borderRadius: BorderRadius.circular(
                                                14,
                                              ),
                                            ),
                                            child: Material(
                                              color: Colors.transparent,
                                              child: InkWell(
                                                onTap: () =>
                                                    context.push('/options'),
                                                borderRadius: BorderRadius.circular(
                                                  14,
                                                ),
                                                splashColor: Colors.white
                                                    .withOpacity(0.3),
                                                child: const Icon(
                                                  Icons.more_horiz,
                                                  color: Colors.white,
                                                  size: 24,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
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

                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }
}

// Shiny Button Widget with Animated Shine Effect
class _ShinyButton extends StatefulWidget {
  final VoidCallback onTap;
  final String text;

  const _ShinyButton({required this.onTap, required this.text});

  @override
  State<_ShinyButton> createState() => _ShinyButtonState();
}

class _ShinyButtonState extends State<_ShinyButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          height: 52,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFF5722), Color(0xFFFF7043)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF5722).withOpacity(0.5),
                blurRadius: 16,
                offset: const Offset(0, 6),
                spreadRadius: 0,
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Emboss overlay
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withOpacity(0.2),
                      Colors.transparent,
                      Colors.black.withOpacity(0.1),
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
              // Animated shine
              Positioned(
                left: -100 + (_animation.value * 300),
                top: 0,
                bottom: 0,
                child: Container(
                  width: 100,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Colors.white.withOpacity(0.0),
                        Colors.white.withOpacity(0.3),
                        Colors.white.withOpacity(0.0),
                      ],
                    ),
                  ),
                ),
              ),
              // Button content
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: widget.onTap,
                  borderRadius: BorderRadius.circular(14),
                  splashColor: Colors.white.withOpacity(0.3),
                  highlightColor: Colors.white.withOpacity(0.1),
                  child: Center(
                    child: Text(
                      widget.text,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.2,
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.3),
                            offset: const Offset(0, 1),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// Profile Details Modal with Full Screen Image and Info Overlay
class ProfileDetailsModal extends StatefulWidget {
  final Map<String, dynamic> profile;
  const ProfileDetailsModal({super.key, required this.profile});

  @override
  State<ProfileDetailsModal> createState() => _ProfileDetailsModalState();
}

class _ProfileDetailsModalState extends State<ProfileDetailsModal> {
  int _currentImageIndex = 0;
  bool _showInfo = false;
  late PageController _pageController;

  List<String> _images = [];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _loadImages();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _loadImages() {
    final List photos = widget.profile['photos'] ?? [];
    if (photos.isNotEmpty) {
      _images = photos.map((p) {
        String url = p['url'] ?? '';
        if (url.isNotEmpty && !url.startsWith('http')) {
          url = '${ApiConfig.socketUrl}$url';
        }
        return url;
      }).where((u) => u.isNotEmpty).toList();
    }
    
    // Add primary photo to start if not there or ensure order? 
    // Usually backend returns list. We just use it.
    // If no photos, fallback
    if (_images.isEmpty) {
      _images = ['https://randomuser.me/api/portraits/men/32.jpg'];
    }
    
    // Check if there is a primary photo and if we want it first?
    // Not strictly necessary but good polish.
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onVerticalDragUpdate: (details) {
        if (details.primaryDelta! < -10) {
          setState(() => _showInfo = true);
        } else if (details.primaryDelta! > 10 && _showInfo) {
          setState(() => _showInfo = false);
        }
      },
      child: Container(
        height: MediaQuery.of(context).size.height,
        color: Colors.black,
        child: Stack(
          children: [
            // Full Screen Image Viewer
            PageView.builder(
              controller: _pageController,
              itemCount: _images.length,
              onPageChanged: (index) =>
                  setState(() => _currentImageIndex = index),
              itemBuilder: (context, index) {
                return Image.network(_images[index], fit: BoxFit.cover);
              },
            ),

            // Top Bar with Indicators
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.6),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                          size: 28,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Row(
                          children: List.generate(_images.length, (index) {
                            return Expanded(
                              child: Container(
                                height: 3,
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: index == _currentImageIndex
                                      ? Colors.white
                                      : Colors.white.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.more_vert,
                          color: Colors.white,
                          size: 28,
                        ),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Thumbnail Strip at Bottom
            Positioned(
              bottom: _showInfo ? 400 : 20,
              left: 0,
              right: 0,
              child: AnimatedOpacity(
                opacity: _showInfo ? 0.0 : 1.0,
                duration: const Duration(milliseconds: 300),
                child: Container(
                  height: 80,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _images.length,
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () {
                          setState(() => _currentImageIndex = index);
                          _pageController.animateToPage(
                            index,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                        child: Container(
                          width: 60,
                          margin: const EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: index == _currentImageIndex
                                  ? const Color(0xFFFF5722)
                                  : Colors.white.withOpacity(0.5),
                              width: index == _currentImageIndex ? 3 : 2,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              _images[index],
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),

            // Swipe Up Indicator
            if (!_showInfo)
              Positioned(
                bottom: 110,
                left: 0,
                right: 0,
                child: Center(
                  child: Column(
                    children: [
                      const Icon(
                        Icons.keyboard_arrow_up,
                        color: Colors.white,
                        size: 32,
                      ),
                      Text(
                        'Swipe up for profile',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Profile Info Overlay with Glassmorphism
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              bottom: _showInfo ? 0 : -600,
              left: 0,
              right: 0,
              child: SizedBox(
                height: 600,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.4),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(24),
                        ),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, -5),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Drag Handle
                          const SizedBox(height: 12),
                          Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Profile Info Content
                          Expanded(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Name and Verification
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          '${widget.profile['firstName'] ?? ''} ${widget.profile['lastName'] ?? ''}, ${widget.profile['age'] ?? '?'}',
                                          style: GoogleFonts.poppins(
                                            fontSize: 28,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                      if (widget.profile['isVerified'] == true)
                                      const Icon(
                                        Icons.verified,
                                        color: Color(0xFFFF5722),
                                        size: 28,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.location_on,
                                        color: Color(0xFFFF5722),
                                        size: 18,
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          [
                                            widget.profile['city'],
                                            widget.profile['state'],
                                            widget.profile['country']
                                          ].where((s) => s != null && s.toString().isNotEmpty).join(', '),
                                          style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            color: Colors.white.withOpacity(
                                              0.9,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 24),

                                  // About Me
                                  if (widget.profile['aboutMe'] != null && widget.profile['aboutMe'].toString().isNotEmpty)
                                  _buildInfoSection(
                                    'About Me',
                                    widget.profile['aboutMe'],
                                  ),

                                  const SizedBox(height: 20),

                                  // Personal Details
                                  Text(
                                    'Personal Details',
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFFFF5722),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Column(
                                    children: [
                                      _buildDetailItem(
                                        Icons.height,
                                        'Height',
                                        widget.profile['height'] ?? 'Not specified',
                                      ),
                                      _buildDetailItem(
                                        Icons.church,
                                        'Religion',
                                        widget.profile['religion'] ?? 'Not specified',
                                      ),
                                      _buildDetailItem(
                                        Icons.school,
                                        'Education',
                                        widget.profile['education'] ?? 'Not specified',
                                      ),
                                      _buildDetailItem(
                                        Icons.work,
                                        'Work',
                                        widget.profile['workStatus'] ?? 'Not specified',
                                      ),
                                      _buildDetailItem(
                                        Icons.favorite,
                                        'Status',
                                        widget.profile['relationshipStatus'] ?? 'Not specified',
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 20),

                                  // Medical Info
                                  Text(
                                    'Medical Info',
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFFFF5722),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Column(
                                    children: [
                                      _buildDetailItem(
                                        Icons.medical_services,
                                        'Genotype',
                                        widget.profile['genotype'] ?? 'Not specified',
                                      ),
                                      _buildDetailItem(
                                        Icons.bloodtype,
                                        'Blood Group',
                                        widget.profile['bloodGroup'] ?? 'Not specified',
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 20),

                                  // Lifestyle
                                  Text(
                                    'Lifestyle',
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFFFF5722),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Column(
                                    children: [
                                      _buildDetailItem(
                                        Icons.local_bar,
                                        'Drinks',
                                        widget.profile['drinkingStatus'] ?? 'Not specified',
                                      ),
                                      _buildDetailItem(
                                        Icons.smoking_rooms,
                                        'Smokes',
                                        widget.profile['smokingStatus'] ?? 'Not specified',
                                      ),
                                      _buildDetailItem(
                                        Icons.child_care,
                                        'Children',
                                        widget.profile['hasChildren'] ?? 'Not specified',
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 40),
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
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: const Color(0xFFFF5722),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.white.withOpacity(0.9),
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFFF5722), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.white.withOpacity(0.7),
              ),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
