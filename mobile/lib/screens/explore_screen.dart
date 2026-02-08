import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import '../config/theme.dart';
import '../config/api_config.dart';
import '../services/match_service.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> with TickerProviderStateMixin {
  // 0 = Map (Default), 1 = Cards, 2 = Grid
  int _viewMode = 0; 
  final CardSwiperController swipeController = CardSwiperController();
  final MapController mapController = MapController();
  final ScrollController _horizontalScrollController = ScrollController();
  final MatchService _matchService = MatchService();

  // State
  bool _isLoading = true;
  LatLng? _currentLocation;
  List<dynamic> _nearbyUsers = [];
  List<dynamic> _suggestions = [];
  String _locationName = 'Locating...';

  // Two-tap interaction state
  String? _selectedUserId;
  int? _selectedCardIndex;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Filter State
  RangeValues _ageRange = const RangeValues(18, 100);
  double _distance = 50;
  String? _genderFilter;
  RangeValues _heightRange = const RangeValues(140, 220);
  String? _bodyTypeFilter;
  String? _religionFilter;
  String? _smokingFilter;
  String? _drinkingFilter;
  String? _educationFilter;
  String? _hasChildrenFilter;
  String? _relationshipStatusFilter;
  bool _showOnlyVerified = false;
  bool _showOnlyPremium = false;
  bool _showOnlyOnline = false;

  @override
  void initState() {
    super.initState();
    // Initialize pulse animation for selected marker
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _initializeData();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _horizontalScrollController.dispose();
    super.dispose();
  }

  Future<void> _initializeData() async {
    await _getCurrentLocation();
    if (_currentLocation != null) {
      await _fetchNearbyUsers();
    }
    await _fetchSuggestions();
    setState(() => _isLoading = false);
  }

  Future<void> _getCurrentLocation() async {
    try {
      // Check permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      
      if (permission == LocationPermission.whileInUse || 
          permission == LocationPermission.always) {
        final position = await Geolocator.getCurrentPosition();
        setState(() {
          _currentLocation = LatLng(position.latitude, position.longitude);
        });
        // Reverse geocode to get location name
        await _updateLocationName(_currentLocation!);
      }
    } catch (e) {
      debugPrint('Error getting location: $e');
      setState(() => _locationName = 'Location unavailable');
    }
  }

  Future<void> _updateLocationName(LatLng location) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        location.latitude,
        location.longitude,
      );
      
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final city = place.locality ?? place.subAdministrativeArea ?? '';
        final state = place.administrativeArea ?? '';
        final country = place.country ?? '';
        
        String locationText = '';
        if (city.isNotEmpty) {
          locationText = city;
          if (state.isNotEmpty) locationText += ', $state';
        } else if (state.isNotEmpty) {
          locationText = state;
          if (country.isNotEmpty) locationText += ', $country';
        } else if (country.isNotEmpty) {
          locationText = country;
        } else {
          locationText = 'Unknown location';
        }
        
        setState(() => _locationName = locationText);
      }
    } catch (e) {
      debugPrint('Error reverse geocoding: $e');
      setState(() => _locationName = 'Location found');
    }
  }

  void _onMapEvent(MapEvent event) {
    // Update location when map stops moving
    if (event is MapEventMoveEnd) {
      final center = mapController.camera.center;
      _updateLocationName(center);
      // Optionally fetch users at new location
      // _fetchNearbyUsersAtLocation(center);
    }
  }

  // Helper method to construct full photo URLs
  String _getFullPhotoUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    if (url.startsWith('http')) return url;
    return '${ApiConfig.socketUrl}$url';
  }

  // Two-tap interaction helpers
  void _handleUserTap(dynamic user, {bool fromCard = false}) {
    final userId = (user['user']?['id'] ?? user['userId'])?.toString();
    if (userId == null) return;

    // Check if this is the second tap on the same user
    if (_selectedUserId == userId) {
      // Second tap - open profile
      context.push('/user-profile', extra: user);
      return;
    }

    // First tap - select user and sync
    setState(() {
      _selectedUserId = userId;
      _selectedCardIndex = _nearbyUsers.indexWhere((u) {
        final uId = (u['user']?['id'] ?? u['userId'])?.toString();
        return uId == userId;
      });
    });

    if (fromCard) {
      // Tapped from card - center map on marker
      final lat = user['latitude'] ?? user['lat'];
      final lng = user['longitude'] ?? user['lng'];
      if (lat != null && lng != null) {
        _centerMapOnUser(lat.toDouble(), lng.toDouble());
      }
    } else {
      // Tapped from marker - scroll to card
      if (_selectedCardIndex != null && _selectedCardIndex! >= 0) {
        _scrollToCard(_selectedCardIndex!);
      }
    }
  }

  void _centerMapOnUser(double lat, double lng) {
    final camera = mapController.camera;
    final currentZoom = camera.zoom;
    
    // Use animated rotation with custom curve for smooth, natural movement
    mapController.moveAndRotate(
      LatLng(lat, lng),
      currentZoom,
      0.0,
    );
    
    // For even smoother transition, we can use a custom animation
    // This simulates finger-dragging movement
    final currentCenter = camera.center;
    final targetCenter = LatLng(lat, lng);
    
    // Calculate distance to determine animation duration
    final distance = const Distance().as(
      LengthUnit.Kilometer,
      currentCenter,
      targetCenter,
    );
    
    // Longer distances = longer animation (max 1.5 seconds)
    final duration = Duration(
      milliseconds: (distance * 100).clamp(300, 1500).toInt(),
    );
    
    // Animate with easeInOutCubic curve for natural feel
    _animateMapCamera(currentCenter, targetCenter, currentZoom, duration);
  }
  
  void _animateMapCamera(
    LatLng start,
    LatLng end,
    double zoom,
    Duration duration,
  ) {
    final startTime = DateTime.now();
    
    void animate() {
      final elapsed = DateTime.now().difference(startTime);
      final progress = (elapsed.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0);
      
      if (progress >= 1.0) {
        mapController.move(end, zoom);
        return;
      }
      
      // Cubic easing for smooth deceleration
      final t = progress < 0.5
          ? 4 * progress * progress * progress
          : 1 - pow(-2 * progress + 2, 3) / 2;
      
      final lat = start.latitude + (end.latitude - start.latitude) * t;
      final lng = start.longitude + (end.longitude - start.longitude) * t;
      
      mapController.move(LatLng(lat, lng), zoom);
      
      Future.delayed(const Duration(milliseconds: 16), animate);
    }
    
    animate();
  }

  void _scrollToCard(int index) {
    if (!_horizontalScrollController.hasClients) return;
    
    final cardWidth = 280.0; // Card width (260) + margin (20)
    final screenWidth = MediaQuery.of(context).size.width;
    final targetOffset = (index * cardWidth) - (screenWidth / 2) + (cardWidth / 2);
    
    _horizontalScrollController.animateTo(
      targetOffset.clamp(0.0, _horizontalScrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _fetchNearbyUsers() async {
    // Default to 0,0 (Atlantic Ocean) if location unavailable, just to fetch users!
    final double lat = _currentLocation?.latitude ?? 0.0;
    final double lng = _currentLocation?.longitude ?? 0.0;

    try {
      final users = await _matchService.getNearbyUsers(
        latitude: lat,
        longitude: lng,
        radius: 50, // 50km
      );
      
      // DEBUG: Print full response to see data structure
      debugPrint('=== NEARBY USERS DEBUG ===');
      debugPrint('Total users: ${users.length}');
      if (users.isNotEmpty) {
        debugPrint('First user data: ${users[0]}');
        final firstUser = users[0];
        debugPrint('Profile: ${firstUser['profile']}');
        debugPrint('Photos: ${firstUser['profile']?['photos']}');
      }
      debugPrint('=========================');
      
      setState(() => _nearbyUsers = users);
    } catch (e) {
      debugPrint('Error fetching nearby users: $e');
      if (mounted) {
        if (e.toString().contains('UNAUTHORIZED')) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Session expired. Please login again.'),
                backgroundColor: Colors.red,
              ),
            );
            // clear navigation stack and go to login
            context.go('/login'); 
            return;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load nearby users. Please try re-logging in.'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: _fetchNearbyUsers,
            ),
          ),
        );
      }
    }
  }

  Future<void> _fetchSuggestions() async {
    try {
      final users = await _matchService.getMatchSuggestions(limit: 10);
      setState(() => _suggestions = users);
    } catch (e) {
      debugPrint('Error fetching suggestions: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine background color based on view mode (Map handles its own background)
    Color backgroundColor = Colors.white; 
    if (_viewMode == 2) backgroundColor = Colors.grey[100]!; // Grid view background
    
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),

            // Location Chip
            if (_viewMode == 0) // Only show on Map for now
              _buildLocationChip(),

            const SizedBox(height: 16),

            // Tab Switcher
            _buildViewSwitcher(),

            const SizedBox(height: 16),

            // Content
            Expanded(
              child: _isLoading 
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF5722))) 
                : _buildContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Explore',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.tune, color: Colors.black87),
                onPressed: _showFilterModal,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLocationChip() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: _showLocationSearch,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white,
                    Colors.grey[50]!,
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFFF5722).withOpacity(0.3), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.location_on, color: Color(0xFFFF5722), size: 16),
                  const SizedBox(width: 6),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 200),
                    child: Text(
                      _locationName,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(Icons.keyboard_arrow_down, color: Colors.grey[600], size: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewSwitcher() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildSwitchButton('Map', Icons.map, 0),
          const SizedBox(width: 10),
          _buildSwitchButton('Cards', Icons.style, 1),
          const SizedBox(width: 10),
          _buildSwitchButton('Grid', Icons.grid_view, 2),
        ],
      ),
    );
  }

  Widget _buildSwitchButton(String label, IconData icon, int index) {
    final bool isActive = _viewMode == index;
    
    return GestureDetector(
      onTap: () => setState(() => _viewMode = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(horizontal: isActive ? 16 : 12, vertical: 8),
        decoration: BoxDecoration(
          gradient: isActive 
              ? const LinearGradient(colors: [Color(0xFFFF5722), Color(0xFFFF7043)]) 
              : null,
          color: isActive 
              ? null 
              : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? Colors.transparent : Colors.grey[300]!,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon, 
              size: 18, 
              color: isActive ? Colors.white : Colors.grey[700],
            ),
            if (isActive) ...[
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    switch (_viewMode) {
      case 0:
        return _buildMapView();
      case 1:
        return _buildCardSwipeView();
      case 2:
        return _buildGridView();
      default:
        return _buildMapView();
    }
  }

  // --- MAP VIEW ---
  Widget _buildMapView() {
    if (_currentLocation == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.location_disabled, color: Colors.grey, size: 48),
            const SizedBox(height: 12),
            Text(
              'Location unavailable',
              style: GoogleFonts.poppins(color: Colors.grey[600]),
            ),
            TextButton(
              onPressed: _initializeData,
              child: const Text('Retry', style: TextStyle(color: Color(0xFFFF5722))),
            )
          ],
        ),
      );
    }

    return Stack(
      children: [
        // Map Layer
        FlutterMap(
          mapController: mapController,
          options: MapOptions(
            initialCenter: _currentLocation!,
            initialZoom: 11.0,
            keepAlive: true,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all & ~InteractiveFlag.rotate, 
            ),
          ),
          children: [
            TileLayer(
              // CartoDB Positron (Light) - Friendly, Google Maps-like
              urlTemplate: 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}@2x.png',
              subdomains: const ['a', 'b', 'c', 'd'],
              userAgentPackageName: 'com.rtm.mobile',
            ),
            MarkerLayer(
              markers: [
                // User's own location
                Marker(
                  point: _currentLocation!,
                  width: 60,
                  height: 60,
                  child: _buildPulsingUserMarker(),
                ),
                ..._nearbyUsers.map((user) {
                  // Parse backend user to marker
                  final lat = (user['latitude'] as num?)?.toDouble() ?? 0.0;
                  final lng = (user['longitude'] as num?)?.toDouble() ?? 0.0;
                  final userId = (user['user']?['id'] ?? user['userId'])?.toString();
                  final isSelected = userId == _selectedUserId;
                  
                  // Backend returns photos at root level now
                  final photos = user['photos'] as List? ?? [];
                  final rawUrl = photos.isNotEmpty
                      ? (photos.firstWhere(
                          (p) => p['isPrimary'] == true,
                          orElse: () => photos.first,
                        )['url'] ?? '')
                      : '';
                  final photoUrl = _getFullPhotoUrl(rawUrl);

                  return Marker(
                    point: LatLng(lat, lng),
                    width: 50,
                    height: 50,
                    child: GestureDetector(
                      onTap: () => _handleUserTap(user, fromCard: false),
                      child: AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: isSelected ? _pulseAnimation.value : 1.0,
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected ? const Color(0xFFFF5722) : Colors.white,
                                  width: isSelected ? 3 : 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: isSelected 
                                        ? const Color(0xFFFF5722).withOpacity(0.6)
                                        : Colors.black.withOpacity(0.3),
                                    blurRadius: isSelected ? 12 : 4,
                                    offset: const Offset(0, 2),
                                    spreadRadius: isSelected ? 2 : 0,
                                  ),
                                ],
                              ),
                              child: photoUrl.isNotEmpty
                                ? CircleAvatar(
                                    backgroundImage: NetworkImage(photoUrl),
                                  )
                                : CircleAvatar(
                                    backgroundColor: const Color(0xFFFF5722).withOpacity(0.2),
                                    child: const Icon(
                                      Icons.person,
                                      color: Color(0xFFFF5722),
                                      size: 30,
                                    ),
                                  ),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                }),
              ],
            ),
          ],
        ),

        // Top Gradient Overlay for Visual Separation
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: IgnorePointer(
            child: Container(
              height: 60,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.15),
                    Colors.black.withOpacity(0.08),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),
        ),

        // Horizontal Scrollable User Cards at Bottom
        if (_nearbyUsers.isNotEmpty)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 180,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.1),
                  ],
                ),
              ),
              child: ListView.builder(
                controller: _horizontalScrollController,
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                itemCount: _nearbyUsers.length,
                itemBuilder: (context, index) {
                  final user = _nearbyUsers[index];
                  final userId = (user['user']?['id'] ?? user['userId'])?.toString();
                  final isSelected = userId == _selectedUserId;
                  return _buildHorizontalUserCard(user, isSelected: isSelected);
                },
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildHorizontalUserCard(dynamic user, {bool isSelected = false}) {
    // Backend now returns data at root level, not nested under 'profile'
    final photos = user['photos'] as List? ?? [];
    final userObj = user['user'] ?? {};
    
    final firstName = user['firstName'] ?? 'User';
    final age = user['dateOfBirth'] != null 
        ? (DateTime.now().year - DateTime.parse(user['dateOfBirth']).year).toString()
        : user['age']?.toString() ?? '??';
    
    // Get primary photo or first photo
    final rawUrl = photos.isNotEmpty
        ? (photos.firstWhere(
            (p) => p['isPrimary'] == true,
            orElse: () => photos.first,
          )['url'] ?? '')
        : '';
    final photoUrl = _getFullPhotoUrl(rawUrl);
    
    final distance = user['distance']?.toString() ?? '0';
    final isOnline = userObj['isOnline'] ?? false;
    final isPremium = userObj['isPremium'] ?? false;

    return GestureDetector(
      onTap: () => _handleUserTap(user, fromCard: true),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: Matrix4.identity()..scale(isSelected ? 1.05 : 1.0),
        width: 140,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: isSelected 
              ? Border.all(color: const Color(0xFFFF5722), width: 3)
              : null,
          boxShadow: [
            BoxShadow(
              color: isSelected 
                  ? const Color(0xFFFF5722).withOpacity(0.4)
                  : Colors.black.withOpacity(0.15),
              blurRadius: isSelected ? 15 : 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              // Background Image
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFFFF5722).withOpacity(0.2),
                      const Color(0xFFFF7043).withOpacity(0.2),
                    ],
                  ),
                ),
                child: photoUrl.isNotEmpty
                    ? Image.network(
                        photoUrl,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        errorBuilder: (context, error, stackTrace) {
                          return Center(
                            child: Icon(
                              Icons.person,
                              size: 40,
                              color: Colors.white.withOpacity(0.7),
                            ),
                          );
                        },
                      )
                    : Center(
                        child: Icon(
                          Icons.person,
                          size: 40,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
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

              // Premium Badge
              if (isPremium)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFFD700).withOpacity(0.4),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.diamond,
                      color: Colors.white,
                      size: 10,
                    ),
                  ),
                ),

              // Online Indicator
              if (isOnline)
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF4CAF50).withOpacity(0.5),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ),

              // User Info at Bottom
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              '$firstName, $age',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                height: 1.2,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 3),
                          Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: Color(0xFF4CAF50),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 8,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            color: Color(0xFFFF5722),
                            size: 12,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '${distance}km away',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
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
    );
  }

  Widget _buildPulsingUserMarker() {
     // TODO: Add complex animation if desired
     return Container(
       decoration: BoxDecoration(
         color: const Color(0xFFFF5722).withOpacity(0.3),
         shape: BoxShape.circle,
       ),
       child: Center(
         child: Container(
           width: 20,
           height: 20,
           decoration: BoxDecoration(
             color: const Color(0xFFFF5722),
             shape: BoxShape.circle,
             border: Border.all(color: Colors.white, width: 2),
             boxShadow: const [
               BoxShadow(color: Colors.black26, blurRadius: 4),
             ],
           ),
         ),
       ),
     );
  }

  void _showUserPreview(dynamic user) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        // Backend returns data at root level now
        final photos = user['photos'] as List? ?? [];
        final userObj = user['user'] ?? {};
        
        final firstName = user['firstName'] ?? 'User';
        final lastName = user['lastName'] ?? '';
        final age = user['dateOfBirth'] != null 
            ? (DateTime.now().year - DateTime.parse(user['dateOfBirth']).year).toString()
            : user['age']?.toString() ?? '??';
        
        // Get primary photo or first photo
        final rawUrl = photos.isNotEmpty
            ? (photos.firstWhere(
                (p) => p['isPrimary'] == true,
                orElse: () => photos.first,
              )['url'] ?? '')
            : '';
        final photoUrl = _getFullPhotoUrl(rawUrl);
        
        final distance = user['distance']?.toString() ?? '0';
        final isOnline = userObj['isOnline'] ?? false;
        final isPremium = userObj['isPremium'] ?? false;

        return Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: Stack(
              children: [
                // Background Image with Gradient Overlay
                Container(
                  height: 280,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        const Color(0xFFFF5722).withOpacity(0.1),
                        const Color(0xFFFF5722).withOpacity(0.05),
                      ],
                    ),
                  ),
                  child: photoUrl.isNotEmpty
                      ? Image.network(
                          photoUrl,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildPlaceholderImage();
                          },
                        )
                      : _buildPlaceholderImage(),
                ),

                // Gradient Overlay for Text Readability
                Container(
                  height: 280,
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

                // Glassmorphic Content Card
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withOpacity(0.95),
                          Colors.white.withOpacity(0.85),
                        ],
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(32),
                        topRight: Radius.circular(32),
                      ),
                      border: Border(
                        top: BorderSide(
                          color: Colors.white.withOpacity(0.5),
                          width: 1.5,
                        ),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Name, Age, and Badges Row
                        Row(
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      '$firstName, $age',
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 24,
                                        color: Colors.black87,
                                        height: 1.2,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // Verified Badge
                                  Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF4CAF50),
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF4CAF50).withOpacity(0.3),
                                          blurRadius: 8,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.check,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                  if (isPremium) ...[
                                    const SizedBox(width: 6),
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
                                            'PREMIUM',
                                            style: GoogleFonts.poppins(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            // Online Status Indicator
                            if (isOnline)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF4CAF50).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: const Color(0xFF4CAF50),
                                    width: 1.5,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF4CAF50),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Online',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF4CAF50),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // Distance and Location
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF5722).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.location_on,
                                color: Color(0xFFFF5722),
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${distance}km away',
                                    style: GoogleFonts.poppins(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  Text(
                                    'Nearby',
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Action Button
                        GestureDetector(
                          onTap: () {
                            context.pop();
                            // Navigate to full profile
                            context.push('/user-profile', extra: user);
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFF5722), Color(0xFFFF7043)],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFFF5722).withOpacity(0.4),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'View Full Profile',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(
                                  Icons.arrow_forward_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFFF5722).withOpacity(0.3),
            const Color(0xFFFF7043).withOpacity(0.3),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.person,
          size: 80,
          color: Colors.white.withOpacity(0.7),
        ),
      ),
    );
  }

  // --- CARDS VIEW ---
  Widget _buildCardSwipeView() {
    // Fallback to nearby users if suggestions are empty
    final users = _suggestions.isNotEmpty ? _suggestions : _nearbyUsers;

    if (users.isEmpty) {
       return _buildEmptyState('No active people nearby.', Icons.explore_off);
    }

    return Column(
      children: [
        Expanded(
          child: CardSwiper(
            controller: swipeController,
            cardsCount: users.length,
            numberOfCardsDisplayed: 3,
            backCardOffset: const Offset(0, 40),
            padding: const EdgeInsets.all(16),
            cardBuilder: (context, index, horizontalOffset, verticalOffset) {
              final user = users[index];
              return _buildSwipeCard(user);
            },
          ),
        ),
        // Action Buttons
        Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildActionButton(Icons.refresh, Colors.orange, () => swipeController.undo()),
              _buildActionButton(Icons.close, Colors.red, () => swipeController.swipe(CardSwiperDirection.left)),
              _buildActionButton(Icons.star, Colors.blue, () => swipeController.swipe(CardSwiperDirection.top)),
              _buildActionButton(Icons.favorite, Colors.green, () => swipeController.swipe(CardSwiperDirection.right)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSwipeCard(dynamic user) {
    // Better data extraction with fallbacks
    final profile = user['profile'] ?? user;
    final photos = profile['photos'] as List? ?? [];
    final userObj = profile['user'] ?? {};
    
    final firstName = profile['firstName'] ?? 'User';
    final age = profile['dateOfBirth'] != null 
        ? (DateTime.now().year - DateTime.parse(profile['dateOfBirth']).year).toString()
        : profile['age']?.toString() ?? '??';
    
    final bio = profile['aboutMe'] ?? 'No bio yet.';
    final city = profile['city'] ?? '';
    final state = profile['state'] ?? '';
    final location = city.isNotEmpty ? (state.isNotEmpty ? '$city, $state' : city) : 'Nearby';
    
    // Get primary photo or first photo
    String photoUrl = photos.isNotEmpty
        ? (photos.firstWhere(
            (p) => p['isPrimary'] == true,
            orElse: () => photos.first,
          )['url'] ?? '')
        : '';
    
    // Ensure full URL
    photoUrl = _getFullPhotoUrl(photoUrl);
    
    final distance = user['distance']?.toString() ?? '0';
    final isOnline = userObj['isOnline'] ?? false;
    final isPremium = userObj['isPremium'] ?? false;

    return Container(
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
          children: [
            // Background Image
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFFFF5722).withOpacity(0.1),
                    const Color(0xFFFF5722).withOpacity(0.05),
                  ],
                ),
              ),
              child: photoUrl.isNotEmpty
                  ? Image.network(
                      photoUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      errorBuilder: (context, error, stackTrace) {
                        return _buildPlaceholderImage();
                      },
                    )
                  : _buildPlaceholderImage(),
            ),

            // Gradient Overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.85),
                  ],
                  stops: const [0.5, 1.0],
                ),
              ),
            ),

            // Top Badges
            Positioned(
              top: 20,
              right: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (isPremium)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFFD700).withOpacity(0.4),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.diamond,
                            color: Colors.white,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'PREMIUM',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (isOnline) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4CAF50),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF4CAF50).withOpacity(0.4),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Online',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Bottom Content
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Name and Age
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            '$firstName, $age',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              height: 1.2,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4CAF50),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF4CAF50).withOpacity(0.4),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Location and Distance
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          color: Color(0xFFFF5722),
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${distance}km away',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (location.isNotEmpty) ...[
                          Text(
                            ' • ',
                            style: GoogleFonts.poppins(
                              color: Colors.white70,
                              fontSize: 15,
                            ),
                          ),
                          Flexible(
                            child: Text(
                              location,
                              style: GoogleFonts.poppins(
                                color: Colors.white70,
                                fontSize: 15,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Bio
                    Text(
                      bio,
                      style: GoogleFonts.poppins(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                        height: 1.5,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

   Widget _buildActionButton(IconData icon, Color color, VoidCallback onPressed) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, color: color),
        iconSize: 30,
        padding: const EdgeInsets.all(16),
      ),
    );
  }

  // --- GRID VIEW ---
  Widget _buildGridView() {
    if (_nearbyUsers.isEmpty) {
       return _buildEmptyState('No users nearby yet.', Icons.people_outline);
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.75,
      ),
      itemCount: _nearbyUsers.length,
      itemBuilder: (context, index) {
        final user = _nearbyUsers[index];
        return _buildGridItem(user);
      },
    );
  }

  Widget _buildGridItem(dynamic user) {
    // Better data extraction with fallbacks
    final profile = user['profile'] ?? user;
    final photos = profile['photos'] as List? ?? [];
    final userObj = profile['user'] ?? {};
    
    final firstName = profile['firstName'] ?? 'User';
    final age = profile['dateOfBirth'] != null 
        ? (DateTime.now().year - DateTime.parse(profile['dateOfBirth']).year).toString()
        : profile['age']?.toString() ?? '??';
    
    // Get primary photo or first photo
    String photoUrl = photos.isNotEmpty
        ? (photos.firstWhere(
            (p) => p['isPrimary'] == true,
            orElse: () => photos.first,
          )['url'] ?? '')
        : '';

    photoUrl = _getFullPhotoUrl(photoUrl);
    
    final distance = user['distance']?.toString() ?? '0';
    final isOnline = userObj['isOnline'] ?? false;
    final isPremium = userObj['isPremium'] ?? false;

    return GestureDetector(
      onTap: () => context.push('/user-profile', extra: user),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              // Background Image
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFFFF5722).withOpacity(0.2),
                      const Color(0xFFFF7043).withOpacity(0.2),
                    ],
                  ),
                ),
                child: photoUrl.isNotEmpty
                    ? Image.network(
                        photoUrl,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        errorBuilder: (context, error, stackTrace) {
                          return Center(
                            child: Icon(
                              Icons.person,
                              size: 50,
                              color: Colors.white.withOpacity(0.7),
                            ),
                          );
                        },
                      )
                    : Center(
                        child: Icon(
                          Icons.person,
                          size: 50,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
              ),

              // Gradient Overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.75),
                    ],
                    stops: const [0.5, 1.0],
                  ),
                ),
              ),

              // Top Right Badges
              Positioned(
                top: 8,
                right: 8,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
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
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFFD700).withOpacity(0.4),
                              blurRadius: 6,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.diamond,
                          color: Colors.white,
                          size: 12,
                        ),
                      ),
                    if (isOnline) ...[
                      const SizedBox(height: 6),
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: const Color(0xFF4CAF50),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF4CAF50).withOpacity(0.5),
                              blurRadius: 6,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Distance Badge
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.location_on,
                        color: Color(0xFFFF5722),
                        size: 12,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${distance}km',
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

              // Bottom Info
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              '$firstName, $age',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                height: 1.2,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(
                              color: Color(0xFF4CAF50),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 10,
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
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 60, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            message,
            style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  void _showLocationSearch() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(32),
              topRight: Radius.circular(32),
            ),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Select Location',
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              // Search input
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search city or location...',
                    hintStyle: GoogleFonts.poppins(color: Colors.grey[400]),
                    prefixIcon: const Icon(Icons.search, color: Color(0xFFFF5722)),
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onSubmitted: (value) async {
                    if (value.isNotEmpty) {
                      try {
                        final locations = await locationFromAddress(value);
                        if (locations.isNotEmpty) {
                          final loc = locations.first;
                          final newLocation = LatLng(loc.latitude, loc.longitude);
                          mapController.move(newLocation, 11.0);
                          await _updateLocationName(newLocation);
                          await _fetchNearbyUsers();
                          if (mounted) Navigator.pop(context);
                        }
                      } catch (e) {
                        debugPrint('Error searching location: $e');
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Location not found'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    }
                  },
                ),
              ),

              const SizedBox(height: 24),

              // Popular locations
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    Text(
                      'Popular Locations',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildLocationItem('New York, USA', 40.7128, -74.0060),
                    _buildLocationItem('London, UK', 51.5074, -0.1278),
                    _buildLocationItem('Paris, France', 48.8566, 2.3522),
                    _buildLocationItem('Tokyo, Japan', 35.6762, 139.6503),
                    _buildLocationItem('Dubai, UAE', 25.2048, 55.2708),
                    _buildLocationItem('Sydney, Australia', -33.8688, 151.2093),
                    _buildLocationItem('Lagos, Nigeria', 6.5244, 3.3792),
                    _buildLocationItem('Mumbai, India', 19.0760, 72.8777),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLocationItem(String name, double lat, double lng) {
    return GestureDetector(
      onTap: () async {
        final newLocation = LatLng(lat, lng);
        mapController.move(newLocation, 11.0);
        setState(() {
          _currentLocation = newLocation;
          _locationName = name;
        });
        await _fetchNearbyUsers();
        if (mounted) Navigator.pop(context);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFF5722).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.location_city,
                color: Color(0xFFFF5722),
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                name,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  void _showFilterModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.9,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(32),
                topRight: Radius.circular(32),
              ),
            ),
            child: Column(
              children: [
                // Handle bar
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // Header
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Filter Users',
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setModalState(() {
                            _ageRange = const RangeValues(18, 100);
                            _distance = 50;
                            _genderFilter = null;
                            _heightRange = const RangeValues(140, 220);
                            _bodyTypeFilter = null;
                            _religionFilter = null;
                            _smokingFilter = null;
                            _drinkingFilter = null;
                            _educationFilter = null;
                            _hasChildrenFilter = null;
                            _relationshipStatusFilter = null;
                            _showOnlyVerified = false;
                            _showOnlyPremium = false;
                            _showOnlyOnline = false;
                          });
                        },
                        child: Text(
                          'Clear All',
                          style: GoogleFonts.poppins(
                            color: const Color(0xFFFF5722),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Scrollable Filters
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    children: [
                      // Age Range
                      _buildFilterSection(
                        'Age Range',
                        Column(
                          children: [
                            RangeSlider(
                              values: _ageRange,
                              min: 18,
                              max: 100,
                              divisions: 82,
                              activeColor: const Color(0xFFFF5722),
                              labels: RangeLabels(
                                _ageRange.start.round().toString(),
                                _ageRange.end.round().toString(),
                              ),
                              onChanged: (values) {
                                setModalState(() => _ageRange = values);
                              },
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('${_ageRange.start.round()} years',
                                    style: GoogleFonts.poppins(fontSize: 13)),
                                Text('${_ageRange.end.round()} years',
                                    style: GoogleFonts.poppins(fontSize: 13)),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Distance
                      _buildFilterSection(
                        'Distance',
                        Column(
                          children: [
                            Slider(
                              value: _distance,
                              min: 1,
                              max: 500,
                              divisions: 499,
                              activeColor: const Color(0xFFFF5722),
                              label: '${_distance.round()} km',
                              onChanged: (value) {
                                setModalState(() => _distance = value);
                              },
                            ),
                            Text('${_distance.round()} km away',
                                style: GoogleFonts.poppins(fontSize: 13)),
                          ],
                        ),
                      ),

                      // Gender
                      _buildFilterSection(
                        'Gender',
                        Wrap(
                          spacing: 8,
                          children: [
                            _buildChip('Male', _genderFilter == 'MALE', () {
                              setModalState(() => _genderFilter =
                                  _genderFilter == 'MALE' ? null : 'MALE');
                            }),
                            _buildChip('Female', _genderFilter == 'FEMALE', () {
                              setModalState(() => _genderFilter =
                                  _genderFilter == 'FEMALE' ? null : 'FEMALE');
                            }),
                          ],
                        ),
                      ),

                      // Height Range
                      _buildFilterSection(
                        'Height Range (cm)',
                        Column(
                          children: [
                            RangeSlider(
                              values: _heightRange,
                              min: 140,
                              max: 220,
                              divisions: 80,
                              activeColor: const Color(0xFFFF5722),
                              labels: RangeLabels(
                                _heightRange.start.round().toString(),
                                _heightRange.end.round().toString(),
                              ),
                              onChanged: (values) {
                                setModalState(() => _heightRange = values);
                              },
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('${_heightRange.start.round()} cm',
                                    style: GoogleFonts.poppins(fontSize: 13)),
                                Text('${_heightRange.end.round()} cm',
                                    style: GoogleFonts.poppins(fontSize: 13)),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Body Type
                      _buildFilterSection(
                        'Body Type',
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _buildChip('Slim', _bodyTypeFilter == 'Slim', () {
                              setModalState(() => _bodyTypeFilter =
                                  _bodyTypeFilter == 'Slim' ? null : 'Slim');
                            }),
                            _buildChip('Athletic', _bodyTypeFilter == 'Athletic',
                                () {
                              setModalState(() => _bodyTypeFilter =
                                  _bodyTypeFilter == 'Athletic'
                                      ? null
                                      : 'Athletic');
                            }),
                            _buildChip('Average', _bodyTypeFilter == 'Average',
                                () {
                              setModalState(() => _bodyTypeFilter =
                                  _bodyTypeFilter == 'Average'
                                      ? null
                                      : 'Average');
                            }),
                            _buildChip('Curvy', _bodyTypeFilter == 'Curvy', () {
                              setModalState(() => _bodyTypeFilter =
                                  _bodyTypeFilter == 'Curvy' ? null : 'Curvy');
                            }),
                          ],
                        ),
                      ),

                      // Religion
                      _buildFilterSection(
                        'Religion',
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _buildChip(
                                'Christianity', _religionFilter == 'Christianity',
                                () {
                              setModalState(() => _religionFilter =
                                  _religionFilter == 'Christianity'
                                      ? null
                                      : 'Christianity');
                            }),
                            _buildChip('Islam', _religionFilter == 'Islam', () {
                              setModalState(() => _religionFilter =
                                  _religionFilter == 'Islam' ? null : 'Islam');
                            }),
                            _buildChip('Hindu', _religionFilter == 'Hindu', () {
                              setModalState(() => _religionFilter =
                                  _religionFilter == 'Hindu' ? null : 'Hindu');
                            }),
                            _buildChip('Other', _religionFilter == 'Other', () {
                              setModalState(() => _religionFilter =
                                  _religionFilter == 'Other' ? null : 'Other');
                            }),
                          ],
                        ),
                      ),

                      // Smoking
                      _buildFilterSection(
                        'Smoking',
                        Wrap(
                          spacing: 8,
                          children: [
                            _buildChip('Yes', _smokingFilter == 'Yes', () {
                              setModalState(() => _smokingFilter =
                                  _smokingFilter == 'Yes' ? null : 'Yes');
                            }),
                            _buildChip('No', _smokingFilter == 'No', () {
                              setModalState(() => _smokingFilter =
                                  _smokingFilter == 'No' ? null : 'No');
                            }),
                            _buildChip(
                                'Occasionally', _smokingFilter == 'Occasionally',
                                () {
                              setModalState(() => _smokingFilter =
                                  _smokingFilter == 'Occasionally'
                                      ? null
                                      : 'Occasionally');
                            }),
                          ],
                        ),
                      ),

                      // Drinking
                      _buildFilterSection(
                        'Drinking',
                        Wrap(
                          spacing: 8,
                          children: [
                            _buildChip('Yes', _drinkingFilter == 'Yes', () {
                              setModalState(() => _drinkingFilter =
                                  _drinkingFilter == 'Yes' ? null : 'Yes');
                            }),
                            _buildChip('No', _drinkingFilter == 'No', () {
                              setModalState(() => _drinkingFilter =
                                  _drinkingFilter == 'No' ? null : 'No');
                            }),
                            _buildChip('Socially', _drinkingFilter == 'Socially',
                                () {
                              setModalState(() => _drinkingFilter =
                                  _drinkingFilter == 'Socially'
                                      ? null
                                      : 'Socially');
                            }),
                          ],
                        ),
                      ),

                      // Toggles Section
                      _buildFilterSection(
                        'Show Only',
                        Column(
                          children: [
                            _buildToggle('Verified Users', _showOnlyVerified,
                                (value) {
                              setModalState(() => _showOnlyVerified = value);
                            }),
                            _buildToggle('Premium Users', _showOnlyPremium,
                                (value) {
                              setModalState(() => _showOnlyPremium = value);
                            }),
                            _buildToggle('Online Users', _showOnlyOnline,
                                (value) {
                              setModalState(() => _showOnlyOnline = value);
                            }),
                          ],
                        ),
                      ),

                      const SizedBox(height: 100),
                    ],
                  ),
                ),

                // Apply Button
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        // Apply filters to state
                      });
                      Navigator.pop(context);
                      _fetchNearbyUsers();
                      _fetchSuggestions();
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF5722), Color(0xFFFF7043)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF5722).withOpacity(0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Text(
                        'Apply Filters',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterSection(String title, Widget content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        content,
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [Color(0xFFFF5722), Color(0xFFFF7043)],
                )
              : null,
          color: isSelected ? null : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.transparent : Colors.grey[300]!,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }

  Widget _buildToggle(String label, bool value, Function(bool) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 15,
              color: Colors.black87,
            ),
          ),
          Switch(
            value: value,
            activeColor: const Color(0xFFFF5722),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
