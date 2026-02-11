import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../config/api_config.dart';
import '../services/like_service.dart';

class UserProfilePage extends StatefulWidget {
  final Map<String, dynamic> userData;

  const UserProfilePage({super.key, required this.userData});

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
  late PageController _pageController;

  final LikeService _likeService = LikeService();
  bool _isLiked = false;
  bool _isLiking = false;

  List<String> _images = [];
  late Map<String, dynamic> _user;
  late Map<String, dynamic> _userObj;

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
    _pageController = PageController();
    
    // Extract user data
    _user = widget.userData;
    _userObj = _user['user'] ?? {};
    
    // Load images
    _loadImages();

    // Check if already liked
    _checkLikeStatus();
  }

  Future<void> _checkLikeStatus() async {
    final userId = _userObj['id'] ?? _user['userId'];
    if (userId != null) {
      final liked = await _likeService.checkIfLiked(userId.toString());
      if (mounted) {
        setState(() => _isLiked = liked);
      }
    }
  }

  void _loadImages() {
    final List photos = _user['photos'] ?? [];
    if (photos.isNotEmpty) {
      _images = photos.map((p) {
        String url = p['url'] ?? '';
        if (url.isNotEmpty && !url.startsWith('http')) {
          url = '${ApiConfig.socketUrl}$url';
        }
        return url;
      }).where((u) => u.isNotEmpty).toList();
    }
    
    // Fallback to placeholder if no photos
    if (_images.isEmpty) {
      _images = ['https://ui-avatars.com/api/?name=${_getFullName()}&size=600&background=FF5722&color=fff'];
    }
  }

  String _getFullName() {
    final firstName = _user['firstName'] ?? 'User';
    final lastName = _user['lastName'] ?? '';
    return '$firstName $lastName'.trim();
  }

  int _getAge() {
    if (_user['dateOfBirth'] != null) {
      try {
        final dob = DateTime.parse(_user['dateOfBirth']);
        return DateTime.now().year - dob.year;
      } catch (e) {
        return _user['age'] ?? 0;
      }
    }
    return _user['age'] ?? 0;
  }

  String _getLocation() {
    final parts = [
      _user['city'],
      _user['state'],
      _user['country'],
    ].where((s) => s != null && s.toString().isNotEmpty);
    return parts.join(', ');
  }

  @override
  void dispose() {
    _menuAnimationController.dispose();
    _tabController.dispose();
    _pageController.dispose();
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

  Future<void> _likeUser() async {
    if (_isLiking || _isLiked) return;

    final userId = _userObj['id'] ?? _user['userId'];
    if (userId == null) return;

    setState(() => _isLiking = true);

    try {
      final result = await _likeService.sendLike(userId.toString());
      final isMutual = result['isMutual'] == true;

      if (mounted) {
        setState(() {
          _isLiked = true;
          _isLiking = false;
        });

        if (isMutual) {
          _showMatchCelebration();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'You liked ${_user['firstName']}!',
                style: GoogleFonts.poppins(),
              ),
              backgroundColor: const Color(0xFFFF5722),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLiking = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().contains('already liked')
                  ? 'You already liked this user'
                  : 'Failed to send like',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showMatchCelebration() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFF5722), Color(0xFFE91E63)],
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF5722).withOpacity(0.5),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.favorite,
                  color: Colors.white,
                  size: 44,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                "It's a Match!",
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'You and ${_user['firstName']} liked each other',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.9),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white, width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(
                        'Keep Browsing',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _startChat();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                      ),
                      child: Text(
                        'Send Message',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFFF5722),
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
    );
  }

  void _startChat() {
    final userId = _userObj['id'] ?? _user['userId'];
    final firstName = _user['firstName'] ?? 'User';
    final photoUrl = _images.isNotEmpty ? _images[0] : null;
    
    // Use userId as conversationId for now - backend will handle conversation creation
    context.push('/chat/$userId', extra: {
      'receiverId': userId,
      'receiverName': firstName,
      'receiverPhoto': photoUrl,
    });
  }

  @override
  Widget build(BuildContext context) {
    final fullName = _getFullName();
    final age = _getAge();
    final location = _getLocation();
    final isOnline = _userObj['isOnline'] ?? false;
    final isPremium = _userObj['isPremium'] ?? false;
    final isVerified = _user['isVerified'] ?? false;

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
              controller: _pageController,
              itemCount: _images.length,
              onPageChanged: (index) =>
                  setState(() => _currentImageIndex = index),
              itemBuilder: (context, index) {
                final imageWidget = Image.network(
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
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      color: Colors.grey[900],
                      child: Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                          color: const Color(0xFFFF5722),
                        ),
                      ),
                    );
                  },
                );

                // Only hero the first image to match the grid thumbnail
                if (index == 0) {
                  return Hero(
                    tag: 'user-photo-${_userObj['id'] ?? _user['userId'] ?? ''}',
                    child: Material(
                      color: Colors.transparent,
                      child: imageWidget,
                    ),
                  );
                }
                return imageWidget;
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

            // Bottom Gradient with User Info
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
                          // Name, Age, Verification, and Badges
                          Row(
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        '$fullName, $age',
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
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (isVerified) ...[
                                      const SizedBox(width: 8),
                                      const Icon(
                                        Icons.verified,
                                        color: Color(0xFFFF5722),
                                        size: 24,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Status Badges
                              if (isPremium)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.diamond,
                                        color: Colors.white,
                                        size: 12,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'PRO',
                                        style: GoogleFonts.poppins(
                                          fontSize: 10,
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
                          // Location and Online Status
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
                                  location.isNotEmpty ? location : 'Location not set',
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
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isOnline) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF4CAF50).withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: const Color(0xFF4CAF50),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 6,
                                        height: 6,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFF4CAF50),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Online',
                                        style: GoogleFonts.poppins(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFF4CAF50),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
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
                                      onTap: _startChat,
                                      borderRadius: BorderRadius.circular(12),
                                      child: Center(
                                        child: Text(
                                          'CHAT WITH ${_user['firstName']?.toString().toUpperCase() ?? 'USER'}',
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
                                  color: _isLiked
                                      ? const Color(0xFFFF5722)
                                      : Colors.white.withOpacity(0.2),
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
                                    child: _isLiking
                                        ? const Padding(
                                            padding: EdgeInsets.all(13),
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : Icon(
                                            _isLiked
                                                ? Icons.favorite
                                                : Icons.favorite_border,
                                            color: _isLiked
                                                ? Colors.white
                                                : const Color(0xFFFF5722),
                                            size: 24,
                                          ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          // Thumbnail Strip
                          if (_images.length > 1)
                            SizedBox(
                              height: 70,
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
                          if (_images.length > 1) const SizedBox(height: 16),
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
                                  'Swipe up for full profile',
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
                                          '$fullName, $age',
                                          style: GoogleFonts.poppins(
                                            fontSize: 28,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                      if (isVerified)
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
                                          location.isNotEmpty ? location : 'Location not set',
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

                                  // Embossed Pill Tabs
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
                                      dividerColor: Colors.transparent,
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
                                        Container(
                                          padding: const EdgeInsets.only(
                                            left: 20,
                                            right: 24,
                                            top: 12,
                                            bottom: 12,
                                          ),
                                          alignment: Alignment.centerLeft,
                                          child: const Text('Profile'),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.only(
                                            left: 24,
                                            right: 20,
                                            top: 12,
                                            bottom: 12,
                                          ),
                                          alignment: Alignment.centerRight,
                                          child: const Text(
                                            'Preferences',
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

  Widget _buildInfoSection(String title, String? content) {
    if (content == null || content.isEmpty) return const SizedBox.shrink();
    
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

  Widget _buildDetailItem(IconData icon, String label, String? value) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    
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
          Flexible(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              textAlign: TextAlign.right,
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
                onTap: _startChat,
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
                        'Chat',
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
            color: _isLiked
                ? const Color(0xFFFF5722)
                : Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFFF5722), width: 1.5),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _likeUser,
              borderRadius: BorderRadius.circular(10),
              child: _isLiking
                  ? const Padding(
                      padding: EdgeInsets.all(11),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(
                      _isLiked ? Icons.favorite : Icons.favorite_border,
                      color: _isLiked ? Colors.white : const Color(0xFFFF5722),
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
          _buildInfoSection('About Me', _user['aboutMe']),
          if (_user['aboutMe'] != null && _user['aboutMe'].toString().isNotEmpty)
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
          _buildDetailItem(Icons.height, 'Height', _user['height']),
          _buildDetailItem(Icons.church, 'Religion', _user['religion']),
          _buildDetailItem(Icons.school, 'Education', _user['education']),
          _buildDetailItem(Icons.work, 'Work Status', _user['workStatus']),
          _buildDetailItem(Icons.favorite, 'Relationship', _user['relationshipStatus']),
          _buildDetailItem(Icons.language, 'Language', _user['language']),
          _buildDetailItem(Icons.star, 'Zodiac Sign', _user['zodiacSign']),
          _buildDetailItem(Icons.psychology, 'Personality', _user['personalityType']),

          const SizedBox(height: 20),

          // Physical Attributes
          Text(
            'Physical Attributes',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: const Color(0xFFFF5722),
            ),
          ),
          const SizedBox(height: 10),
          _buildDetailItem(Icons.fitness_center, 'Body Type', _user['bodyType']),
          _buildDetailItem(Icons.palette, 'Skin Color', _user['skinColor']),
          _buildDetailItem(Icons.remove_red_eye, 'Eye Color', _user['eyeColor']),
          _buildDetailItem(Icons.auto_awesome, 'Best Feature', _user['bestFeature']),

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
          _buildDetailItem(Icons.medical_services, 'Genotype', _user['genotype']),
          _buildDetailItem(Icons.bloodtype, 'Blood Group', _user['bloodGroup']),

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
          _buildDetailItem(Icons.local_bar, 'Drinking', _user['drinkingStatus']),
          _buildDetailItem(Icons.smoking_rooms, 'Smoking', _user['smokingStatus']),
          _buildDetailItem(Icons.child_care, 'Has Children', _user['hasChildren']),
          _buildDetailItem(Icons.home, 'Living Conditions', _user['livingConditions']),

          const SizedBox(height: 24),

          // Action Buttons at bottom
          _buildActionButtons(),

          const SizedBox(height: 80),
        ],
      ),
    );
  }

  String _formatList(dynamic value) {
    if (value == null) return 'Any';
    if (value is List) {
      if (value.isEmpty) return 'Any';
      return value.map((e) => e.toString()).join(', ');
    }
    return value.toString();
  }

  Widget _buildPreferenceItem(IconData icon, String label, String value) {
    if (value == 'Any' || value.isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFFFF5722), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.white.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withOpacity(0.95),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreferredPartnerTab() {
    final prefs = _user['preferences']
        ?? _user['matchPreferences']
        ?? _userObj['matchPreferences']
        ?? {};
    final bool hasPrefs = prefs is Map && prefs.isNotEmpty;

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
                  Icons.favorite_border,
                  color: Color(0xFFFF5722),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'What ${_user['firstName'] ?? 'they'} is looking for',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          if (!hasPrefs)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Column(
                  children: [
                    Icon(
                      Icons.favorite_border,
                      color: Colors.white.withOpacity(0.3),
                      size: 48,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Partner preferences not shared yet',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            // Age Range
            if (prefs['ageMin'] != null && prefs['ageMax'] != null)
              _buildPreferenceItem(
                Icons.calendar_today,
                'Preferred Age',
                '${prefs['ageMin']} - ${prefs['ageMax']} years',
              ),

            // Relationship Status
            _buildPreferenceItem(
              Icons.favorite,
              'Relationship Status',
              _formatList(prefs['relationshipStatus']),
            ),

            // Location
            if (prefs['locationCountry'] != null)
              _buildPreferenceItem(
                Icons.location_on,
                'Preferred Location',
                prefs['locationCountry'].toString(),
              ),

            // States
            _buildPreferenceItem(
              Icons.map,
              'Preferred States',
              _formatList(prefs['locationStates']),
            ),

            // Tribes
            _buildPreferenceItem(
              Icons.people,
              'Preferred Tribe(s)',
              _formatList(prefs['locationTribes']),
            ),

            // Religion
            _buildPreferenceItem(
              Icons.auto_awesome,
              'Preferred Religion',
              _formatList(prefs['religion']),
            ),

            // Zodiac
            _buildPreferenceItem(
              Icons.stars,
              'Preferred Zodiac',
              _formatList(prefs['zodiac']),
            ),

            // Genotype
            _buildPreferenceItem(
              Icons.medical_services,
              'Preferred Genotype',
              _formatList(prefs['genotype']),
            ),

            // Blood Group
            _buildPreferenceItem(
              Icons.bloodtype,
              'Preferred Blood Group',
              _formatList(prefs['bloodGroup']),
            ),

            // Height
            if (prefs['heightMin'] != null && prefs['heightMax'] != null)
              _buildPreferenceItem(
                Icons.height,
                'Preferred Height',
                '${prefs['heightMin']} to ${prefs['heightMax']}',
              ),

            // Body Type
            _buildPreferenceItem(
              Icons.accessibility_new,
              'Preferred Body Type',
              _formatList(prefs['bodyType']),
            ),

            // Tattoos
            if (prefs['tattoosAcceptable'] != null)
              _buildPreferenceItem(
                Icons.brush,
                'Tattoos',
                prefs['tattoosAcceptable'] == true ? 'Yes' : 'No',
              ),

            // Piercings
            if (prefs['piercingsAcceptable'] != null)
              _buildPreferenceItem(
                Icons.circle,
                'Piercings',
                prefs['piercingsAcceptable'] == true ? 'Yes' : 'No',
              ),
          ],

          const SizedBox(height: 24),

          // Action Buttons at bottom
          _buildActionButtons(),

          const SizedBox(height: 80),
        ],
      ),
    );
  }
}
