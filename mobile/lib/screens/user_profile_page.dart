import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

class UserProfilePage extends StatefulWidget {
  final String userName;

  const UserProfilePage({super.key, required this.userName});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage>
    with TickerProviderStateMixin {
  int _currentImageIndex = 0;
  bool _showInfo = false;
  bool _showReportMenu = false;
  late AnimationController _menuAnimationController;
  late Animation<double> _menuAnimation;
  late TabController _tabController;

  final List<String> _images = [
    'https://i.pravatar.cc/600?img=13',
    'https://i.pravatar.cc/600?img=12',
    'https://i.pravatar.cc/600?img=14',
    'https://i.pravatar.cc/600?img=15',
  ];

  @override
  void initState() {
    super.initState();
    _menuAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _menuAnimation = CurvedAnimation(
      parent: _menuAnimationController,
      curve: Curves.easeInOut,
    );
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _menuAnimationController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _toggleReportMenu() {
    setState(() {
      _showReportMenu = !_showReportMenu;
      if (_showReportMenu) {
        _menuAnimationController.forward();
      } else {
        _menuAnimationController.reverse();
      }
    });
  }

  void _reportUser() {
    _toggleReportMenu();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Report User',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to report this user?',
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
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('User reported', style: GoogleFonts.poppins()),
                  backgroundColor: const Color(0xFFFF5722),
                ),
              );
            },
            child: Text(
              'Report',
              style: GoogleFonts.poppins(
                color: Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _likeUser() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'You liked ${widget.userName}!',
          style: GoogleFonts.poppins(),
        ),
        backgroundColor: const Color(0xFFFF5722),
        behavior: SnackBarBehavior.floating,
      ),
    );
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
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // Full Screen Image Viewer
            PageView.builder(
              itemCount: _images.length,
              onPageChanged: (index) =>
                  setState(() => _currentImageIndex = index),
              itemBuilder: (context, index) {
                return Image.network(
                  _images[index],
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[800],
                      child: const Icon(
                        Icons.person,
                        size: 100,
                        color: Colors.white,
                      ),
                    );
                  },
                );
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
                        onPressed: () => context.pop(),
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
                      const SizedBox(width: 12),
                      // Report Menu Button
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.more_vert,
                              color: Colors.white,
                              size: 28,
                            ),
                            onPressed: _toggleReportMenu,
                          ),
                          // Sophisticated Report Menu
                          if (_showReportMenu)
                            Positioned(
                              top: 50,
                              right: 0,
                              child: ScaleTransition(
                                scale: _menuAnimation,
                                alignment: Alignment.topRight,
                                child: Container(
                                  width: 180,
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.9),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.2),
                                      width: 1,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.5),
                                        blurRadius: 20,
                                        offset: const Offset(0, 5),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: BackdropFilter(
                                      filter: ImageFilter.blur(
                                        sigmaX: 10,
                                        sigmaY: 10,
                                      ),
                                      child: Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          onTap: _reportUser,
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 14,
                                            ),
                                            child: Row(
                                              children: [
                                                const Icon(
                                                  Icons.flag,
                                                  color: Colors.red,
                                                  size: 20,
                                                ),
                                                const SizedBox(width: 12),
                                                Text(
                                                  'Report User',
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w500,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
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
            ),

            // Bottom Gradient with User Info (No dark background card)
            if (!_showInfo)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withOpacity(0.9),
                        Colors.black.withOpacity(0.7),
                        Colors.black.withOpacity(0.4),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.3, 0.7, 1.0],
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 80, 20, 20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Name, Age, Verification, and Match Score
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'John Doe, 28',
                                  style: GoogleFonts.poppins(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black.withOpacity(0.5),
                                        offset: const Offset(0, 2),
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const Icon(
                                Icons.verified,
                                color: Color(0xFFFF5722),
                                size: 28,
                              ),
                              const SizedBox(width: 8),
                              // Match Score Badge
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
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
                                      Icons.favorite,
                                      color: Colors.white,
                                      size: 14,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '92%',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Location
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on,
                                color: Color(0xFFFF5722),
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  'Lagos, Lagos State, Nigeria',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: Colors.white.withOpacity(0.9),
                                    shadows: [
                                      Shadow(
                                        color: Colors.black.withOpacity(0.5),
                                        offset: const Offset(0, 1),
                                        blurRadius: 3,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          // Action Buttons
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  height: 50,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFFFF5722),
                                        Color(0xFFFF7043),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(
                                          0xFFFF5722,
                                        ).withOpacity(0.4),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () => context.push(
                                        '/chat/${widget.userName}',
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      child: Center(
                                        child: Text(
                                          'CHAT WITH ${widget.userName.toUpperCase()}',
                                          style: GoogleFonts.poppins(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color(0xFFFF5722),
                                    width: 2,
                                  ),
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: _likeUser,
                                    borderRadius: BorderRadius.circular(12),
                                    child: const Icon(
                                      Icons.favorite,
                                      color: Color(0xFFFF5722),
                                      size: 24,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          // Thumbnail Strip
                          SizedBox(
                            height: 70,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: _images.length,
                              itemBuilder: (context, index) {
                                return GestureDetector(
                                  onTap: () => setState(
                                    () => _currentImageIndex = index,
                                  ),
                                  child: Container(
                                    width: 60,
                                    margin: const EdgeInsets.only(right: 12),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: index == _currentImageIndex
                                            ? const Color(0xFFFF5722)
                                            : Colors.white.withOpacity(0.5),
                                        width: index == _currentImageIndex
                                            ? 3
                                            : 2,
                                      ),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: Image.network(
                                        _images[index],
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                              return Container(
                                                color: Colors.grey[700],
                                                child: const Icon(
                                                  Icons.person,
                                                  size: 30,
                                                  color: Colors.white,
                                                ),
                                              );
                                            },
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Swipe Up Indicator
                          Center(
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
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            // Profile Info Overlay with Glassmorphism
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              bottom: _showInfo ? 0 : -700,
              left: 0,
              right: 0,
              child: SizedBox(
                height: 700,
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
                                          'John Doe, 28',
                                          style: GoogleFonts.poppins(
                                            fontSize: 28,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                      const Icon(
                                        Icons.verified,
                                        color: Color(0xFFFF5722),
                                        size: 28,
                                      ),
                                      const SizedBox(width: 8),
                                      // Match Score Badge
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [
                                              Color(0xFFFF5722),
                                              Color(0xFFFF7043),
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.favorite,
                                              color: Colors.white,
                                              size: 14,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              '92%',
                                              style: GoogleFonts.poppins(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
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
                                          'Lagos, Lagos State, Nigeria',
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

                                  // Embossed Pill Tabs - Right after location
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(25),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.2),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: TabBar(
                                      controller: _tabController,
                                      indicatorSize: TabBarIndicatorSize.tab,
                                      indicator: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [
                                            Color(0xFFFF5722),
                                            Color(0xFFFF7043),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(25),
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
                                      labelColor: Colors.white,
                                      unselectedLabelColor: Colors.white
                                          .withOpacity(0.6),
                                      labelStyle: GoogleFonts.poppins(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      labelPadding: EdgeInsets.zero,
                                      indicatorPadding: EdgeInsets.zero,
                                      tabs: [
                                        // User's Profile - extends to left, padding on right
                                        Container(
                                          padding: const EdgeInsets.only(
                                            left: 20,
                                            right: 24,
                                            top: 12,
                                            bottom: 12,
                                          ),
                                          alignment: Alignment.centerLeft,
                                          child: const Text('User\'s Profile'),
                                        ),
                                        // Preferred Partner - extends to right, padding on left
                                        Container(
                                          padding: const EdgeInsets.only(
                                            left: 24,
                                            right: 20,
                                            top: 12,
                                            bottom: 12,
                                          ),
                                          alignment: Alignment.centerRight,
                                          child: const Text(
                                            'Preferred Partner',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(height: 20),

                                  // Tab Content
                                  SizedBox(
                                    height: 500,
                                    child: TabBarView(
                                      controller: _tabController,
                                      children: [
                                        _buildUserProfileTab(),
                                        _buildPreferredPartnerTab(),
                                      ],
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
                  ),
                ),
              ),
            ),

            // Tap outside to close report menu
            if (_showReportMenu)
              Positioned.fill(
                child: GestureDetector(
                  onTap: _toggleReportMenu,
                  child: Container(color: Colors.transparent),
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
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: const Color(0xFFFF5722),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          content,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.white.withOpacity(0.9),
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFFF5722), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.white.withOpacity(0.7),
              ),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        // Chat Button
        Expanded(
          child: Container(
            height: 42,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF5722), Color(0xFFFF7043)],
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF5722).withOpacity(0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => context.push('/chat/${widget.userName}'),
                borderRadius: BorderRadius.circular(10),
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.chat_bubble,
                        color: Colors.white,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Chat with ${widget.userName}',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        // Like Button
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFFF5722), width: 1.5),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _likeUser,
              borderRadius: BorderRadius.circular(10),
              child: const Icon(
                Icons.favorite,
                color: Color(0xFFFF5722),
                size: 20,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        // Report Button
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.red.withOpacity(0.6), width: 1.5),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _reportUser,
              borderRadius: BorderRadius.circular(10),
              child: const Icon(Icons.flag, color: Colors.red, size: 20),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUserProfileTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // About Me
          _buildInfoSection(
            'About Me',
            'I\'m a passionate individual looking for a meaningful connection. I enjoy traveling, reading, and spending time with loved ones.',
          ),

          const SizedBox(height: 20),

          // Personal Details
          Text(
            'Personal Details',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: const Color(0xFFFF5722),
            ),
          ),
          const SizedBox(height: 10),
          _buildDetailItem(Icons.height, 'Height', '5\'6"'),
          _buildDetailItem(Icons.church, 'Religion', 'Christianity'),
          _buildDetailItem(Icons.school, 'Education', 'Bachelor\'s Degree'),
          _buildDetailItem(Icons.work, 'Work', 'Employed'),
          _buildDetailItem(Icons.favorite, 'Status', 'Single'),

          const SizedBox(height: 20),

          // Medical Info
          Text(
            'Medical Info',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: const Color(0xFFFF5722),
            ),
          ),
          const SizedBox(height: 10),
          _buildDetailItem(Icons.medical_services, 'Genotype', 'AA'),
          _buildDetailItem(Icons.bloodtype, 'Blood Group', 'O+'),

          const SizedBox(height: 20),

          // Lifestyle
          Text(
            'Lifestyle',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: const Color(0xFFFF5722),
            ),
          ),
          const SizedBox(height: 10),
          _buildDetailItem(Icons.local_bar, 'Drinking', 'Socially'),
          _buildDetailItem(Icons.smoking_rooms, 'Smoking', 'No'),
          _buildDetailItem(Icons.child_care, 'Children', 'No'),
          _buildDetailItem(Icons.psychology, 'Personality', 'Extrovert'),

          const SizedBox(height: 24),

          // Action Buttons at bottom
          _buildActionButtons(),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildPreferredPartnerTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFF5722).withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFFF5722).withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  color: Color(0xFFFF5722),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'These are ${widget.userName}\'s partner preferences',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Basic Preferences
          Text(
            'Basic Preferences',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: const Color(0xFFFF5722),
            ),
          ),
          const SizedBox(height: 12),
          _buildDetailItem(Icons.calendar_today, 'Age Range', '25-32'),
          _buildDetailItem(Icons.location_on, 'Location', 'Lagos, Abuja'),
          _buildDetailItem(Icons.school, 'Education', 'Bachelor\'s or higher'),
          _buildDetailItem(Icons.work, 'Work', 'Employed'),
          _buildDetailItem(Icons.favorite, 'Status', 'Single'),

          const SizedBox(height: 16),

          // Physical Preferences
          Text(
            'Physical Preferences',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: const Color(0xFFFF5722),
            ),
          ),
          const SizedBox(height: 10),
          _buildDetailItem(Icons.height, 'Height', '5\'8" - 6\'2"'),
          _buildDetailItem(
            Icons.fitness_center,
            'Body Type',
            'Athletic or Average',
          ),

          const SizedBox(height: 16),

          // Lifestyle Preferences
          Text(
            'Lifestyle Preferences',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: const Color(0xFFFF5722),
            ),
          ),
          const SizedBox(height: 10),
          _buildDetailItem(Icons.child_care, 'Children', 'No'),
          _buildDetailItem(Icons.smoking_rooms, 'Smoking', 'No'),
          _buildDetailItem(Icons.local_bar, 'Drinking', 'Socially or No'),
          _buildDetailItem(Icons.church, 'Religion', 'Christianity'),

          const SizedBox(height: 24),

          // Action Buttons at bottom
          _buildActionButtons(),

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
