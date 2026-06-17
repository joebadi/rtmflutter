import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import '../config/theme.dart';
import '../config/api_config.dart';
import '../services/match_service.dart';
import '../services/location_search_service.dart';
import '../widgets/notification_icon.dart';
import '../widgets/premium_loader.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> with TickerProviderStateMixin {
  // 0 = Map (Default), 1 = Swipe (Cards view)
  // Grid view (2) removed from tabs - now accessible via overlay from map
  int _viewMode = 0; 
  final CardSwiperController swipeController = CardSwiperController();
  final MapController mapController = MapController();
  final LocationSearchService _locationSearchService = LocationSearchService();
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
  RangeValues _ageRange = const RangeValues(25, 35);
  double _distance = 50;
  String? _genderFilter;
  RangeValues _heightRange = const RangeValues(160, 185);
  String? _bodyTypeFilter;
  String? _religionFilter;
  String? _smokingFilter;
  String? _drinkingFilter;
  String? _educationFilter;
  String? _hasChildrenFilter;
  String? _relationshipStatusFilter;
  String? _hivPartnerViewFilter;
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

  // Calculate distance between two coordinates (in kilometers)
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2) / 1000; // Convert meters to km
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

      // Calculate distance for each user
      final usersWithDistance = users.map((user) {
        if (_currentLocation != null && user['latitude'] != null && user['longitude'] != null) {
          final distance = _calculateDistance(
            _currentLocation!.latitude,
            _currentLocation!.longitude,
            user['latitude'] as double,
            user['longitude'] as double,
          );
          user['distance'] = distance.round(); // Store as integer km
        } else {
          user['distance'] = 0;
        }
        return user;
      }).toList();

      // Apply filters
      final filteredUsers = _applyFilters(usersWithDistance);

      // DEBUG: Print full response to see data structure
      debugPrint('=== NEARBY USERS DEBUG ===');
      debugPrint('Total users before filter: ${usersWithDistance.length}');
      debugPrint('Total users after filter: ${filteredUsers.length}');
      if (filteredUsers.isNotEmpty) {
        debugPrint('First user data: ${filteredUsers[0]}');
        final firstUser = filteredUsers[0];
        debugPrint('Profile: ${firstUser['profile']}');
        debugPrint('Photos: ${firstUser['profile']?['photos']}');
        debugPrint('Distance: ${firstUser['distance']} km');
      }
      debugPrint('=========================');

      setState(() => _nearbyUsers = filteredUsers);
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
      final filteredUsers = _applyFilters(users);
      setState(() => _suggestions = filteredUsers);
    } catch (e) {
      debugPrint('Error fetching suggestions: $e');
    }
  }

  // Apply client-side filters to users
  List<dynamic> _applyFilters(List<dynamic> users) {
    return users.where((user) {
      // Profile fields may be spread at the top level of the item (nearby /
      // suggestions without prefs) or nested under ['profile'] (suggestions
      // with prefs). Resolve a single base map for all profile reads, and the
      // nested user object for account-level flags.
      final profile = (user['profile'] ?? user) as Map;
      final userObj = (profile['user'] ?? user['user'] ?? {}) as Map;

      // Age filter
      final age = user['age'] ?? profile['age'];
      if (age != null && (age < _ageRange.start || age > _ageRange.end)) {
        return false;
      }

      // Distance filter (only computed for nearby users; top-level)
      final distance = user['distance'] ?? 0;
      if (distance > _distance.round()) {
        return false;
      }

      // Gender filter
      final gender = user['gender'] ?? profile['gender'];
      if (_genderFilter != null && gender != _genderFilter) {
        return false;
      }

      // Height filter
      if (profile['height'] != null) {
        final heightStr = profile['height'] as String;
        // Extract cm value from string like "5'6" (168 cm)"
        final cmMatch = RegExp(r'\((\d+)\s*cm\)').firstMatch(heightStr);
        if (cmMatch != null) {
          final heightCm = int.parse(cmMatch.group(1)!);
          if (heightCm < _heightRange.start || heightCm > _heightRange.end) {
            return false;
          }
        }
      }

      // Body type filter
      if (_bodyTypeFilter != null && profile['bodyType'] != _bodyTypeFilter) {
        return false;
      }

      // Religion filter
      if (_religionFilter != null && profile['religion'] != _religionFilter) {
        return false;
      }

      // HIV Partner View filter
      if (_hivPartnerViewFilter != null &&
          profile['hivPartnerView'] != _hivPartnerViewFilter) {
        return false;
      }

      // Smoking filter (Prisma field: smokingStatus)
      if (_smokingFilter != null && profile['smokingStatus'] != _smokingFilter) {
        return false;
      }

      // Drinking filter (Prisma field: drinkingStatus)
      if (_drinkingFilter != null &&
          profile['drinkingStatus'] != _drinkingFilter) {
        return false;
      }

      // Education filter
      if (_educationFilter != null && profile['education'] != _educationFilter) {
        return false;
      }

      // Has children filter
      if (_hasChildrenFilter != null &&
          profile['hasChildren'] != _hasChildrenFilter) {
        return false;
      }

      // Relationship status filter
      if (_relationshipStatusFilter != null &&
          profile['relationshipStatus'] != _relationshipStatusFilter) {
        return false;
      }

      // Verified filter
      if (_showOnlyVerified &&
          (user['isVerified'] ?? profile['isVerified'] ?? userObj['isVerified']) != true) {
        return false;
      }

      // Premium filter (account flag lives on the nested user object)
      if (_showOnlyPremium &&
          (userObj['isPremium'] ?? user['isPremium']) != true) {
        return false;
      }

      // Online filter (account flag lives on the nested user object)
      if (_showOnlyOnline &&
          (userObj['isOnline'] ?? user['isOnline']) != true) {
        return false;
      }

      return true;
    }).toList();
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
                ? const Center(child: PremiumLoader()) 
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
              const NotificationIcon(),
              const SizedBox(width: 8),
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
          Flexible(
            child: GestureDetector(
              onTap: _showLocationSearch,
              child: Container(
                padding: const EdgeInsets.fromLTRB(8, 7, 12, 7),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(
                      color: const Color(0xFFFF5722).withOpacity(0.25), width: 1.4),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF5722).withOpacity(0.10),
                      blurRadius: 12,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFFFF5722), Color(0xFFFF7043)],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.place_rounded,
                          color: Colors.white, size: 14),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Matches near',
                            style: GoogleFonts.poppins(
                              fontSize: 9,
                              color: Colors.grey[500],
                              fontWeight: FontWeight.w500,
                              height: 1,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            _locationName,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: Colors.black87,
                              fontWeight: FontWeight.w600,
                              height: 1.15,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(Icons.keyboard_arrow_down_rounded,
                        color: Colors.grey[500], size: 18),
                  ],
                ),
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
          _buildSwitchButton('Swipe', Icons.style, 1),
          // Grid view removed - now accessible via overlay button on map
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
            // User's own location marker (always on top)
            MarkerLayer(
              markers: [
                Marker(
                  point: _currentLocation!,
                  width: 60,
                  height: 60,
                  child: _buildPulsingUserMarker(),
                ),
              ],
            ),
            // Clustered markers for nearby users
            MarkerClusterLayerWidget(
              options: MarkerClusterLayerOptions(
                maxClusterRadius: 80,
                size: const Size(50, 50),
                markers: _buildOrderedMarkers(),
                builder: (context, markers) {
                  // Custom cluster builder
                  return Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFFF5722),
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        '${markers.length}',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                },
                onMarkerTap: (marker) {
                  // Find user from marker point
                  final user = _nearbyUsers.firstWhere(
                    (u) {
                      final lat = (u['latitude'] as num?)?.toDouble() ?? 0.0;
                      final lng = (u['longitude'] as num?)?.toDouble() ?? 0.0;
                      return marker.point.latitude == lat && marker.point.longitude == lng;
                    },
                    orElse: () => null,
                  );
                  if (user != null) {
                    _handleUserTap(user, fromCard: false);
                  }
                },
              ),
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

        // Horizontal Scrollable User Cards - shifted up to make room for link below
        if (_nearbyUsers.isNotEmpty)
          Positioned(
            bottom: 35, // Shifted up to make room for View Grid link
            left: 0,
            right: 0,
            child: Container(
              height: 165, // Slightly reduced height
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

        // View Grid button - small orange rounded button below horizontal slider
        if (_nearbyUsers.isNotEmpty)
          Positioned(
            bottom: 12,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: _showGridOverlay,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF5722), Color(0xFFFF7043)],
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF5722).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.grid_view, color: Colors.white, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        'View Grid',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
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
      ],
    );
  }

  // Build markers with selected user last (for z-index on top)
  List<Marker> _buildOrderedMarkers() {
    List<Marker> allMarkers = [];
    Marker? selectedMarker;

    for (var user in _nearbyUsers) {
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

      final marker = Marker(
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

      // Keep selected marker separate to add last
      if (isSelected) {
        selectedMarker = marker;
      } else {
        allMarkers.add(marker);
      }
    }

    // Add selected marker last so it renders on top
    if (selectedMarker != null) {
      allMarkers.add(selectedMarker);
    }

    return allMarkers;
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
            // Dynamically set to avoid assertion error if fewer cards than default (3)
            numberOfCardsDisplayed: users.length < 3 ? users.length : 3,
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

  /// Extracts a compatibility percentage from a user payload when present
  /// (match suggestions include `compatibility.score`); null otherwise.
  int? _matchScoreOf(dynamic user) {
    try {
      final c = user['compatibility'];
      if (c is Map && c['score'] is num) {
        return (c['score'] as num).round();
      }
    } catch (_) {}
    return null;
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
    final matchScore = _matchScoreOf(user);

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
                    ? Hero(
                        tag: 'user-photo-${userObj['id'] ?? profile['userId'] ?? ''}',
                        child: Material(
                          color: Colors.transparent,
                          child: Image.network(
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
                          ),
                        ),
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
                      if (matchScore != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.favorite_rounded,
                                  color: Colors.white, size: 9),
                              const SizedBox(width: 3),
                              Text(
                                '$matchScore% match',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 9.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 5),
                      ],
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              '$firstName, $age',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                height: 1.2,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isOnline) ...[
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
                                size: 9,
                              ),
                            ),
                          ],
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

  // Show grid view in full-screen dark overlay modal
  void _showGridOverlay() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setGridState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.95,
              decoration: const BoxDecoration(
                color: AppTheme.darkBg,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 12, 12, 10),
                    child: Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Browse Matches',
                              style: GoogleFonts.poppins(
                                fontSize: 19,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              '${_nearbyUsers.length} ${_nearbyUsers.length == 1 ? 'person' : 'people'} found',
                              style: GoogleFonts.poppins(
                                fontSize: 11.5,
                                color: Colors.white.withOpacity(0.5),
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        // In-page filter
                        GestureDetector(
                          onTap: () => _showFilterModal(
                            onApplied: () async {
                              await _fetchNearbyUsers();
                              await _fetchSuggestions();
                              setGridState(() {});
                            },
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 13, vertical: 8),
                            decoration: BoxDecoration(
                              gradient: AppTheme.accentGradient,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.tune_rounded,
                                    color: Colors.white, size: 15),
                                const SizedBox(width: 5),
                                Text(
                                  'Filter',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.close_rounded,
                                size: 17, color: Colors.white70),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Grid view
                  Expanded(
                    child: _nearbyUsers.isEmpty
                        ? _browseEmptyState()
                        : GridView.builder(
                            padding: const EdgeInsets.fromLTRB(14, 4, 14, 20),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 0.72,
                            ),
                            itemCount: _nearbyUsers.length,
                            itemBuilder: (context, index) =>
                                _buildGridItem(_nearbyUsers[index]),
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _browseEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppTheme.accent.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.people_outline_rounded,
                size: 44, color: AppTheme.accent.withOpacity(0.8)),
          ),
          const SizedBox(height: 16),
          Text(
            'No matches found',
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Try widening your filters',
            style: GoogleFonts.poppins(
              fontSize: 12.5,
              color: Colors.white.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }


  // Live location search backed by Nominatim (OpenStreetMap). Typing fetches
  // matching places; selecting one recenters the map and refetches matches.
  void _showLocationSearch() {
    final searchController = TextEditingController();
    final List<LocationSearchResult> results = [];
    Timer? debounce;
    var loading = false;
    var query = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(sheetContext).viewInsets.bottom),
        child: StatefulBuilder(
          builder: (context, setModalState) {
            void runSearch(String value) {
              query = value.trim();
              debounce?.cancel();
              if (query.length < 3) {
                setModalState(() {
                  loading = false;
                  results.clear();
                });
                return;
              }
              setModalState(() => loading = true);
              debounce = Timer(const Duration(milliseconds: 400), () async {
                final found = await _locationSearchService.searchPlaces(query);
                if (!sheetContext.mounted) return;
                setModalState(() {
                  loading = false;
                  results
                    ..clear()
                    ..addAll(found);
                });
              });
            }

            return Container(
              height: MediaQuery.of(context).size.height * 0.82,
              decoration: const BoxDecoration(
                color: AppTheme.darkBg,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 14, 12, 6),
                    child: Row(
                      children: [
                        Text('Search location',
                            style: GoogleFonts.poppins(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: Colors.white)),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => Navigator.pop(sheetContext),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.close_rounded,
                                size: 17, color: Colors.white70),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Search field
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppTheme.darkSurface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: query.isNotEmpty
                              ? AppTheme.accent.withOpacity(0.6)
                              : Colors.white.withOpacity(0.08),
                          width: 1.4,
                        ),
                      ),
                      child: TextField(
                        controller: searchController,
                        autofocus: true,
                        textInputAction: TextInputAction.search,
                        cursorColor: AppTheme.accent,
                        style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w500),
                        onChanged: runSearch,
                        decoration: InputDecoration(
                          hintText: 'Type a city, state or country',
                          hintStyle: GoogleFonts.poppins(
                              color: Colors.white38, fontSize: 14),
                          prefixIcon: const Icon(Icons.search_rounded,
                              color: AppTheme.accent, size: 22),
                          suffixIcon: query.isEmpty
                              ? null
                              : IconButton(
                                  icon: const Icon(Icons.close_rounded,
                                      color: Colors.white38, size: 20),
                                  onPressed: () {
                                    searchController.clear();
                                    runSearch('');
                                  },
                                ),
                          border: InputBorder.none,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: _locationSearchBody(
                      loading: loading,
                      query: query,
                      results: results,
                      sheetContext: sheetContext,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    ).whenComplete(() => debounce?.cancel());
  }

  Widget _locationSearchBody({
    required bool loading,
    required String query,
    required List<LocationSearchResult> results,
    required BuildContext sheetContext,
  }) {
    if (loading) {
      return const Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(strokeWidth: 2.4, color: AppTheme.accent),
        ),
      );
    }
    if (query.length < 3) {
      return _locationHint(
        Icons.travel_explore_rounded,
        'Search anywhere',
        'Type at least 3 letters to find a city, state or country.',
      );
    }
    if (results.isEmpty) {
      return _locationHint(
        Icons.location_off_rounded,
        'No places found',
        'No match for "$query". Try a different spelling.',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      itemCount: results.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) => _locationResultTile(results[i], sheetContext),
    );
  }

  Widget _locationHint(IconData icon, String title, String subtitle) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.accent.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppTheme.accent.withOpacity(0.85), size: 36),
            ),
            const SizedBox(height: 14),
            Text(title,
                style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withOpacity(0.85))),
            const SizedBox(height: 6),
            Text(subtitle,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                    fontSize: 12.5, color: Colors.white.withOpacity(0.5), height: 1.4)),
          ],
        ),
      ),
    );
  }

  Widget _locationResultTile(LocationSearchResult r, BuildContext sheetContext) {
    final label = [r.city, r.state, r.country]
        .where((s) => s.trim().isNotEmpty)
        .join(', ');
    final title = label.isNotEmpty ? label : r.displayName;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _selectSearchResult(r, sheetContext),
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: AppTheme.darkSurface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withOpacity(0.06)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: AppTheme.accent.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(Icons.location_on_rounded,
                    color: AppTheme.accent, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white)),
                    const SizedBox(height: 2),
                    Text(r.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                            fontSize: 11.5, color: Colors.white.withOpacity(0.45))),
                  ],
                ),
              ),
              const Icon(Icons.north_east_rounded,
                  color: Colors.white24, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _selectSearchResult(LocationSearchResult r, BuildContext sheetContext) {
    final newLocation = LatLng(r.lat, r.lon);
    final label = [r.city, r.state, r.country]
        .where((s) => s.trim().isNotEmpty)
        .join(', ');
    try {
      mapController.move(newLocation, 11.0);
    } catch (_) {
      // Map may not be mounted in non-map views; state update below still applies.
    }
    setState(() {
      _currentLocation = newLocation;
      _locationName = label.isNotEmpty ? label : r.displayName;
    });
    _fetchNearbyUsers();
    Navigator.pop(sheetContext);
  }


  /// Compact dark filter sheet. When [onApplied] is supplied (e.g. opened from
  /// Browse Matches), it's invoked on Apply instead of the default refetch so
  /// the caller can refresh its own view.
  Future<void> _showFilterModal({VoidCallback? onApplied}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          // Single-select chip group helper bound to this modal's setState.
          Widget group(String? current, List<String> options,
              ValueChanged<String?> onPick) {
            return Wrap(
              spacing: 7,
              runSpacing: 7,
              children: options
                  .map((o) => _buildChip(o, current == o,
                      () => setModalState(() => onPick(current == o ? null : o))))
                  .toList(),
            );
          }

          return Container(
            height: MediaQuery.of(context).size.height * 0.86,
            decoration: const BoxDecoration(
              color: AppTheme.darkBg,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 12, 12, 8),
                  child: Row(
                    children: [
                      Text(
                        'Filters',
                        style: GoogleFonts.poppins(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () => setModalState(() {
                          _ageRange = const RangeValues(25, 35);
                          _distance = 50;
                          _genderFilter = null;
                          _heightRange = const RangeValues(160, 185);
                          _bodyTypeFilter = null;
                          _religionFilter = null;
                          _smokingFilter = null;
                          _drinkingFilter = null;
                          _educationFilter = null;
                          _hasChildrenFilter = null;
                          _relationshipStatusFilter = null;
                          _hivPartnerViewFilter = null;
                          _showOnlyVerified = false;
                          _showOnlyPremium = false;
                          _showOnlyOnline = false;
                        }),
                        child: Text(
                          'Reset',
                          style: GoogleFonts.poppins(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.accent,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: const Icon(Icons.close_rounded,
                              size: 16, color: Colors.white70),
                        ),
                      ),
                    ],
                  ),
                ),
                // Filters
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
                    children: [
                      _buildFilterSection(
                        'Age',
                        Column(
                          children: [
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                '${_ageRange.start.round()} – ${_ageRange.end.round()} years',
                                style: GoogleFonts.poppins(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.accent),
                              ),
                            ),
                            _slimSlider(
                              RangeSlider(
                                values: _ageRange,
                                min: 18,
                                max: 100,
                                divisions: 82,
                                activeColor: AppTheme.accent,
                                inactiveColor: Colors.white24,
                                labels: RangeLabels('${_ageRange.start.round()}',
                                    '${_ageRange.end.round()}'),
                                onChanged: (v) =>
                                    setModalState(() => _ageRange = v),
                              ),
                            ),
                          ],
                        ),
                        icon: Icons.cake_outlined,
                      ),
                      _buildFilterSection(
                        'Distance',
                        Column(
                          children: [
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Within ${_distance.round()} km',
                                style: GoogleFonts.poppins(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.accent),
                              ),
                            ),
                            _slimSlider(
                              Slider(
                                value: _distance,
                                min: 1,
                                max: 500,
                                divisions: 499,
                                activeColor: AppTheme.accent,
                                inactiveColor: Colors.white24,
                                label: '${_distance.round()} km',
                                onChanged: (v) =>
                                    setModalState(() => _distance = v),
                              ),
                            ),
                          ],
                        ),
                        icon: Icons.location_on_outlined,
                      ),
                      _buildFilterSection(
                        'Gender',
                        group(_genderFilter, const ['MALE', 'FEMALE'],
                            (v) => _genderFilter = v),
                        icon: Icons.people_outline,
                      ),
                      _buildFilterSection(
                        'Height',
                        Column(
                          children: [
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                '${_heightRange.start.round()} – ${_heightRange.end.round()} cm',
                                style: GoogleFonts.poppins(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.accent),
                              ),
                            ),
                            _slimSlider(
                              RangeSlider(
                                values: _heightRange,
                                min: 140,
                                max: 220,
                                divisions: 80,
                                activeColor: AppTheme.accent,
                                inactiveColor: Colors.white24,
                                labels: RangeLabels(
                                    '${_heightRange.start.round()}',
                                    '${_heightRange.end.round()}'),
                                onChanged: (v) =>
                                    setModalState(() => _heightRange = v),
                              ),
                            ),
                          ],
                        ),
                        icon: Icons.height,
                      ),
                      _buildFilterSection(
                        'Body Type',
                        group(
                            _bodyTypeFilter,
                            const ['Slim', 'Athletic', 'Average', 'Curvy'],
                            (v) => _bodyTypeFilter = v),
                        icon: Icons.accessibility_new,
                      ),
                      _buildFilterSection(
                        'Religion',
                        group(
                            _religionFilter,
                            const ['Christianity', 'Islam', 'Hindu', 'Other'],
                            (v) => _religionFilter = v),
                        icon: Icons.church_outlined,
                      ),
                      _buildFilterSection(
                        'Views on HIV+ Partner',
                        group(
                            _hivPartnerViewFilter,
                            const ['Open to discussion', 'Yes', 'No'],
                            (v) => _hivPartnerViewFilter = v),
                        icon: Icons.health_and_safety_outlined,
                      ),
                      _buildFilterSection(
                        'Smoking',
                        group(_smokingFilter,
                            const ['Yes', 'No', 'Occasionally'],
                            (v) => _smokingFilter = v),
                        icon: Icons.smoking_rooms_outlined,
                      ),
                      _buildFilterSection(
                        'Drinking',
                        group(_drinkingFilter, const ['Yes', 'No', 'Socially'],
                            (v) => _drinkingFilter = v),
                        icon: Icons.local_bar_outlined,
                      ),
                      _buildFilterSection(
                        'Education',
                        group(
                            _educationFilter,
                            const [
                              'High School',
                              'Bachelor\'s Degree',
                              'Master\'s Degree',
                              'PhD'
                            ],
                            (v) => _educationFilter = v),
                        icon: Icons.school_outlined,
                      ),
                      _buildFilterSection(
                        'Children',
                        group(
                            _hasChildrenFilter,
                            const ['Yes', 'No', 'Want children'],
                            (v) => _hasChildrenFilter = v),
                        icon: Icons.child_care_outlined,
                      ),
                      _buildFilterSection(
                        'Relationship Status',
                        group(
                            _relationshipStatusFilter,
                            const ['Single', 'Divorced', 'Widowed'],
                            (v) => _relationshipStatusFilter = v),
                        icon: Icons.favorite_border,
                      ),
                      _buildFilterSection(
                        'Show only',
                        Column(
                          children: [
                            _buildToggle('Verified users', _showOnlyVerified,
                                (v) => setModalState(() => _showOnlyVerified = v)),
                            _buildToggle('Premium users', _showOnlyPremium,
                                (v) => setModalState(() => _showOnlyPremium = v)),
                            _buildToggle('Online now', _showOnlyOnline,
                                (v) => setModalState(() => _showOnlyOnline = v)),
                          ],
                        ),
                        icon: Icons.filter_list,
                      ),
                    ],
                  ),
                ),
                // Apply footer
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
                  decoration: BoxDecoration(
                    color: AppTheme.darkBg,
                    border: Border(
                        top: BorderSide(color: Colors.white.withOpacity(0.06))),
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: AppTheme.accentGradient,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                              color: AppTheme.accent.withOpacity(0.35),
                              blurRadius: 16,
                              offset: const Offset(0, 6)),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(15),
                          onTap: () {
                            Navigator.pop(context);
                            if (onApplied != null) {
                              onApplied();
                            } else {
                              setState(() {});
                              _fetchNearbyUsers();
                              _fetchSuggestions();
                            }
                          },
                          child: Center(
                            child: Text(
                              'Apply Filters',
                              style: GoogleFonts.poppins(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
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
          );
        },
      ),
    );
  }

  /// Wraps a slider in a compact theme so it doesn't dominate the sheet.
  Widget _slimSlider(Widget slider) {
    return SliderTheme(
      data: SliderThemeData(
        trackHeight: 3,
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
        rangeThumbShape: const RoundRangeSliderThumbShape(enabledThumbRadius: 8),
      ),
      child: slider,
    );
  }

  Widget _buildFilterSection(String title, Widget content, {IconData? icon}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(13, 11, 13, 13),
      decoration: BoxDecoration(
        color: AppTheme.darkSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 15, color: AppTheme.accent),
                const SizedBox(width: 8),
              ],
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          content,
        ],
      ),
    );
  }

  Widget _buildChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          gradient: isSelected ? AppTheme.accentGradient : null,
          color: isSelected ? null : AppTheme.darkSurface2,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? Colors.transparent : Colors.white.withOpacity(0.1),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? Colors.white : Colors.white.withOpacity(0.75),
          ),
        ),
      ),
    );
  }

  Widget _buildToggle(String label, bool value, Function(bool) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: Colors.white.withOpacity(0.85),
            ),
          ),
          Transform.scale(
            scale: 0.78,
            child: Switch(
              value: value,
              activeColor: AppTheme.accent,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}
