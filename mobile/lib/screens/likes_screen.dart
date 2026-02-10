import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../services/like_service.dart';
import '../config/api_config.dart';
import '../widgets/notification_badge.dart';

class LikesScreen extends StatefulWidget {
  const LikesScreen({super.key});

  @override
  State<LikesScreen> createState() => _LikesScreenState();
}

class _LikesScreenState extends State<LikesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final LikeService _likeService = LikeService();

  List<dynamic> _receivedLikes = [];
  List<dynamic> _sentLikes = [];
  List<dynamic> _matches = [];

  bool _isLoadingReceived = true;
  bool _isLoadingSent = true;
  bool _isLoadingMatches = true;

  // Helper to safely get photo URL from a like's user profile
  String _getUserPhotoUrl(Map<String, dynamic>? user) {
    if (user == null) return '';
    final profile = user['profile'] as Map<String, dynamic>?;
    if (profile == null) return '';
    final photos = profile['photos'] as List?;
    if (photos == null || photos.isEmpty) return '';
    final url = photos[0]['url']?.toString() ?? '';
    if (url.isEmpty) return '';
    if (url.startsWith('http')) return url;
    return '${ApiConfig.socketUrl}$url';
  }

  String _getUserName(Map<String, dynamic>? user) {
    final profile = user?['profile'] as Map<String, dynamic>?;
    return profile?['firstName']?.toString() ?? 'User';
  }

  int _getUserAge(Map<String, dynamic>? user) {
    final profile = user?['profile'] as Map<String, dynamic>?;
    return profile?['age'] as int? ?? 0;
  }

  String _getUserLocation(Map<String, dynamic>? user) {
    final profile = user?['profile'] as Map<String, dynamic>?;
    if (profile == null) return '';
    final parts = [
      profile['city'],
      profile['state'],
    ].where((s) => s != null && s.toString().isNotEmpty);
    return parts.join(', ');
  }

  String _getUserId(Map<String, dynamic>? user) {
    return user?['id']?.toString() ?? '';
  }

  bool _isUserOnline(Map<String, dynamic>? user) {
    return user?['isOnline'] == true;
  }

  String _formatTimeAgo(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '';
    try {
      final date = DateTime.parse(dateStr);
      final diff = DateTime.now().difference(date);
      if (diff.inDays == 0) return 'Today';
      if (diff.inDays == 1) return 'Yesterday';
      if (diff.inDays < 7) return '${diff.inDays} days ago';
      if (diff.inDays < 30) return '${(diff.inDays / 7).floor()} weeks ago';
      return '${(diff.inDays / 30).floor()} months ago';
    } catch (e) {
      return '';
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    await Future.wait([
      _loadReceivedLikes(),
      _loadSentLikes(),
      _loadMatches(),
    ]);
  }

  Future<void> _loadReceivedLikes() async {
    try {
      setState(() => _isLoadingReceived = true);
      final likes = await _likeService.getReceivedLikes();
      if (mounted) {
        setState(() {
          _receivedLikes = likes;
          _isLoadingReceived = false;
        });
      }
    } catch (e) {
      debugPrint('[LikesScreen] Error loading received likes: $e');
      if (mounted) {
        setState(() => _isLoadingReceived = false);
      }
    }
  }

  Future<void> _loadSentLikes() async {
    try {
      setState(() => _isLoadingSent = true);
      final likes = await _likeService.getSentLikes();
      if (mounted) {
        setState(() {
          _sentLikes = likes;
          _isLoadingSent = false;
        });
      }
    } catch (e) {
      debugPrint('[LikesScreen] Error loading sent likes: $e');
      if (mounted) {
        setState(() => _isLoadingSent = false);
      }
    }
  }

  Future<void> _loadMatches() async {
    try {
      setState(() => _isLoadingMatches = true);
      final matches = await _likeService.getMutualLikes();
      if (mounted) {
        setState(() {
          _matches = matches;
          _isLoadingMatches = false;
        });
      }
    } catch (e) {
      debugPrint('[LikesScreen] Error loading matches: $e');
      if (mounted) {
        setState(() => _isLoadingMatches = false);
      }
    }
  }

  Future<void> _handleLikeBack(String userId) async {
    try {
      final result = await _likeService.sendLike(userId);
      await _loadAllData();
      if (mounted) {
        final isMutual = result['isMutual'] == true;
        if (isMutual) {
          _showMatchCelebration(userId);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Liked back!', style: GoogleFonts.poppins()),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('[LikesScreen] Error liking back: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().contains('already liked')
                  ? 'Already liked this user'
                  : 'Failed to send like',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showMatchCelebration(String matchedUserId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
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
                child: const Icon(Icons.favorite, color: Colors.white, size: 44),
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
                'You can now chat freely!',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                  ),
                  child: Text(
                    'Continue',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFFF5722),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleUnlike(String userId) async {
    try {
      await _likeService.unlikeUser(userId);
      await _loadAllData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unliked', style: GoogleFonts.poppins()),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('[LikesScreen] Error unliking: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to unlike', style: GoogleFonts.poppins()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _navigateToProfile(Map<String, dynamic>? user) {
    if (user == null) return;
    final profile = user['profile'] as Map<String, dynamic>?;
    if (profile == null) return;

    // Build userData in the format UserProfilePage expects
    final userData = {
      ...profile,
      'user': user,
    };
    context.push('/user-profile', extra: userData);
  }

  void _navigateToChat(Map<String, dynamic>? user) {
    if (user == null) return;
    final userId = _getUserId(user);
    final name = _getUserName(user);
    final photoUrl = _getUserPhotoUrl(user);

    context.push('/chat/$userId', extra: {
      'receiverId': userId,
      'receiverName': name,
      'receiverPhoto': photoUrl,
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: Text(
          'LIKES',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
            letterSpacing: 1.5,
          ),
        ),
        centerTitle: true,
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 8.0),
            child: NotificationBadge(),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              indicatorColor: const Color(0xFFFF5722),
              indicatorWeight: 3,
              labelColor: const Color(0xFFFF5722),
              unselectedLabelColor: Colors.grey[600],
              labelStyle: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              tabs: [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Received'),
                      if (_receivedLikes.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(left: 6),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF5722),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${_receivedLikes.length}',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const Tab(text: 'Sent'),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Matches'),
                      if (_matches.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(left: 6),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${_matches.length}',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildReceivedLikesGrid(),
          _buildSentLikesGrid(),
          _buildMatchesList(),
        ],
      ),
    );
  }

  // ── Received Likes Tab ──

  Widget _buildReceivedLikesGrid() {
    if (_isLoadingReceived) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFFF5722)),
      );
    }

    if (_receivedLikes.isEmpty) {
      return _buildEmptyState(
        icon: Icons.favorite_border,
        title: 'No likes yet',
        subtitle: 'Keep exploring to find your match!',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadReceivedLikes,
      color: const Color(0xFFFF5722),
      child: GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.7,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: _receivedLikes.length,
        itemBuilder: (context, index) {
          final like = _receivedLikes[index] as Map<String, dynamic>;
          // Received likes have 'liker' as the other user
          final user = like['liker'] as Map<String, dynamic>?;
          final likerId = _getUserId(user);
          final name = _getUserName(user);
          final age = _getUserAge(user);
          final location = _getUserLocation(user);
          final photoUrl = _getUserPhotoUrl(user);
          final isMutual = like['isMutual'] == true;

          return _buildLikeCard(
            photoUrl: photoUrl,
            name: name,
            age: age,
            location: location,
            onTap: () => _navigateToProfile(user),
            badgeWidget: isMutual
                ? _buildBadge('Matched', Colors.green)
                : null,
            bottomWidget: isMutual
                ? null
                : Row(
                    children: [
                      // Pass button
                      Expanded(
                        child: _buildCardButton(
                          icon: Icons.close,
                          color: Colors.grey,
                          outlined: true,
                          onTap: () {},
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Like back button
                      Expanded(
                        child: _buildCardButton(
                          icon: Icons.favorite,
                          color: Colors.white,
                          gradient: true,
                          onTap: () => _handleLikeBack(likerId),
                        ),
                      ),
                    ],
                  ),
          );
        },
      ),
    );
  }

  // ── Sent Likes Tab ──

  Widget _buildSentLikesGrid() {
    if (_isLoadingSent) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFFF5722)),
      );
    }

    if (_sentLikes.isEmpty) {
      return _buildEmptyState(
        icon: Icons.send,
        title: 'No sent likes',
        subtitle: 'Start liking profiles to see them here!',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadSentLikes,
      color: const Color(0xFFFF5722),
      child: GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.7,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: _sentLikes.length,
        itemBuilder: (context, index) {
          final like = _sentLikes[index] as Map<String, dynamic>;
          // Sent likes have 'likedUser' as the other user
          final user = like['likedUser'] as Map<String, dynamic>?;
          final likedUserId = _getUserId(user);
          final name = _getUserName(user);
          final age = _getUserAge(user);
          final location = _getUserLocation(user);
          final photoUrl = _getUserPhotoUrl(user);
          final isMutual = like['isMutual'] == true;

          return _buildLikeCard(
            photoUrl: photoUrl,
            name: name,
            age: age,
            location: location,
            onTap: () => _navigateToProfile(user),
            badgeWidget: _buildBadge(
              isMutual ? 'Matched' : 'Pending',
              isMutual ? Colors.green : Colors.orange,
            ),
            bottomWidget: Padding(
              padding: const EdgeInsets.all(8),
              child: SizedBox(
                width: double.infinity,
                height: 36,
                child: OutlinedButton(
                  onPressed: () => _handleUnlike(likedUserId),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.grey[300]!, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    'Unlike',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Matches Tab ──

  Widget _buildMatchesList() {
    if (_isLoadingMatches) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFFF5722)),
      );
    }

    if (_matches.isEmpty) {
      return _buildEmptyState(
        icon: Icons.favorite,
        title: 'No matches yet',
        subtitle: 'When someone likes you back, they\'ll appear here!',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadMatches,
      color: const Color(0xFFFF5722),
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _matches.length,
        itemBuilder: (context, index) {
          final match = _matches[index] as Map<String, dynamic>;
          // Matches (from getMutualLikes) have 'likedUser' as the other user
          final user = match['likedUser'] as Map<String, dynamic>?;
          final name = _getUserName(user);
          final age = _getUserAge(user);
          final location = _getUserLocation(user);
          final photoUrl = _getUserPhotoUrl(user);
          final isOnline = _isUserOnline(user);
          final matchDate = _formatTimeAgo(match['createdAt']?.toString());

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _navigateToChat(user),
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      // Profile Image
                      GestureDetector(
                        onTap: () => _navigateToProfile(user),
                        child: Stack(
                          children: [
                            Container(
                              width: 70,
                              height: 70,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFFFF5722),
                                  width: 2,
                                ),
                                color: Colors.grey[200],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: photoUrl.isNotEmpty
                                    ? Image.network(
                                        photoUrl,
                                        fit: BoxFit.cover,
                                        width: 70,
                                        height: 70,
                                        errorBuilder: (_, __, ___) =>
                                            const Icon(Icons.person, size: 30, color: Colors.grey),
                                      )
                                    : const Icon(Icons.person, size: 30, color: Colors.grey),
                              ),
                            ),
                            if (isOnline)
                              Positioned(
                                right: 2,
                                bottom: 2,
                                child: Container(
                                  width: 14,
                                  height: 14,
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Match Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    age > 0 ? '$name, $age' : name,
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.pink.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.favorite, color: Colors.pink, size: 12),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Match',
                                        style: GoogleFonts.poppins(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.pink,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            if (location.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.location_on, color: Colors.grey, size: 14),
                                  const SizedBox(width: 2),
                                  Expanded(
                                    child: Text(
                                      location,
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            if (matchDate.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Matched $matchDate',
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      // Chat Button
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF5722), Color(0xFFFF7043)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF5722).withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => _navigateToChat(user),
                            borderRadius: BorderRadius.circular(12),
                            child: const Icon(
                              Icons.chat_bubble,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Shared Card Builder ──

  Widget _buildLikeCard({
    required String photoUrl,
    required String name,
    required int age,
    required String location,
    required VoidCallback onTap,
    Widget? badgeWidget,
    Widget? bottomWidget,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Section
            Expanded(
              child: Stack(
                children: [
                  // Profile Image
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                      color: Colors.grey[200],
                      image: photoUrl.isNotEmpty
                          ? DecorationImage(
                              image: NetworkImage(photoUrl),
                              fit: BoxFit.cover,
                              onError: (_, __) {},
                            )
                          : null,
                    ),
                    child: photoUrl.isEmpty
                        ? const Center(
                            child: Icon(Icons.person, size: 50, color: Colors.grey),
                          )
                        : null,
                  ),

                  // Gradient Overlay
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
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

                  // Badge
                  if (badgeWidget != null)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: badgeWidget,
                    ),

                  // Name and Location
                  Positioned(
                    bottom: 8,
                    left: 8,
                    right: 8,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          age > 0 ? '$name, $age' : name,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (location.isNotEmpty)
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on,
                                color: Colors.white,
                                size: 12,
                              ),
                              const SizedBox(width: 2),
                              Expanded(
                                child: Text(
                                  location,
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    color: Colors.white,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Bottom Widget (action buttons)
            if (bottomWidget != null)
              Padding(
                padding: const EdgeInsets.all(8),
                child: bottomWidget,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.4),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildCardButton({
    required IconData icon,
    required Color color,
    bool outlined = false,
    bool gradient = false,
    required VoidCallback onTap,
  }) {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        gradient: gradient
            ? const LinearGradient(
                colors: [Color(0xFFFF5722), Color(0xFFFF7043)],
              )
            : null,
        border: outlined
            ? Border.all(color: Colors.grey[300]!, width: 1.5)
            : null,
        borderRadius: BorderRadius.circular(10),
        boxShadow: gradient
            ? [
                BoxShadow(
                  color: const Color(0xFFFF5722).withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Icon(icon, color: color, size: 20),
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 50, color: Colors.grey[400]),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
