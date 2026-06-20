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
import '../services/profile_service.dart';
import '../data/nigeria_locations.dart';
import '../widgets/notification_icon.dart';
import '../widgets/premium_message.dart';
import '../widgets/app_logo.dart';
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
  String? _genderFilter; // mandatory single choice; defaults to the opposite user
  String? _userGender; // current user's gender, for the default above
  RangeValues _heightRange = const RangeValues(160, 185);
  // Multi-select facets (empty list = "Any").
  final List<String> _bodyTypeFilter = [];
  final List<String> _religionFilter = [];
  final List<String> _smokingFilter = [];
  final List<String> _drinkingFilter = [];
  final List<String> _educationFilter = [];
  final List<String> _hasChildrenFilter = [];
  final List<String> _relationshipStatusFilter = [];
  final List<String> _hivPartnerViewFilter = [];
  final List<String> _residenceStateFilter = []; // where they live
  final List<String> _stateOfOriginFilter = [];
  final List<String> _tribeFilter = [];
  final List<String> _zodiacFilter = [];
  final List<String> _genotypeFilter = [];
  final List<String> _bloodGroupFilter = [];
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

  Future<void> _loadUserGender() async {
    try {
      final data = await ProfileService().getMyProfile();
      final gender = data?['data']?['profile']?['gender'] ??
          data?['data']?['gender'];
      if (gender is String && gender.isNotEmpty) {
        _userGender = gender.toUpperCase();
        // Default the gender filter to the opposite gender.
        _genderFilter ??= _userGender == 'MALE' ? 'FEMALE' : 'MALE';
        if (mounted) setState(() {});
      }
    } catch (_) {
      // Non-fatal: gender filter simply stays unset.
    }
  }

  String get _defaultGender =>
      _userGender == 'MALE' ? 'FEMALE' : (_userGender == 'FEMALE' ? 'MALE' : 'FEMALE');

  Future<void> _initializeData() async {
    _loadUserGender();
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

      // Multi-select facets: empty list = no constraint; otherwise the
      // candidate's value must be one of the selected options.
      bool fails(List<String> selected, dynamic value) =>
          selected.isNotEmpty && !selected.contains(value);

      if (fails(_bodyTypeFilter, profile['bodyType'])) return false;
      if (fails(_religionFilter, profile['religion'])) return false;
      if (fails(_residenceStateFilter, profile['state'])) return false;
      if (fails(_stateOfOriginFilter, profile['stateOfOrigin'])) return false;
      if (fails(_tribeFilter, profile['tribe'])) return false;
      if (fails(_zodiacFilter, profile['zodiacSign'])) return false;
      if (fails(_genotypeFilter, profile['genotype'])) return false;
      if (fails(_bloodGroupFilter, profile['bloodGroup'])) return false;
      if (fails(_hivPartnerViewFilter, profile['hivPartnerView'])) return false;
      if (fails(_smokingFilter, profile['smokingStatus'])) return false;
      if (fails(_drinkingFilter, profile['drinkingStatus'])) return false;
      if (fails(_educationFilter, profile['education'])) return false;
      if (fails(_hasChildrenFilter, profile['hasChildren'])) return false;
      if (fails(_relationshipStatusFilter, profile['relationshipStatus'])) {
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

            const SizedBox(height: 10),

            // Tab Switcher (with the location field on the right)
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
          const AppLogo(height: 26),
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

  Widget _buildViewSwitcher() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildSwitchButton('Map', Icons.map, 0),
          const SizedBox(width: 10),
          _buildSwitchButton('Swipe', Icons.style, 1),
          const Spacer(flex: 1),
          // Location field — sits on the same line, far right. Give it the
          // bulk of the remaining width so the location text isn't squeezed.
          Expanded(flex: 4, child: _buildLocationButton()),
        ],
      ),
    );
  }

  Widget _buildLocationButton() {
    return GestureDetector(
      onTap: _showLocationSearch,
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 7, 10, 7),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
              color: const Color(0xFFFF5722).withOpacity(0.3), width: 1.4),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF5722).withOpacity(0.10),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          children: [
            Container(
              padding: const EdgeInsets.all(5),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                    colors: [Color(0xFFFF5722), Color(0xFFFF7043)]),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.place_rounded,
                  color: Colors.white, size: 13),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                _locationName,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            Icon(Icons.keyboard_arrow_down_rounded,
                color: Colors.grey[500], size: 16),
          ],
        ),
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

        // Bottom feature box: "View Grid" on top, then horizontal cards,
        // flush against the bottom nav bar (no padding below).
        if (_nearbyUsers.isNotEmpty)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // View Grid button (top of the feature)
                Center(
                  child: GestureDetector(
                    onTap: _showGridOverlay,
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
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
                          const Icon(Icons.grid_view,
                              color: Colors.white, size: 16),
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
                const SizedBox(height: 6),
                // Horizontal scrollable user cards
                Container(
                  height: 165,
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: _nearbyUsers.length,
                    itemBuilder: (context, index) {
                      final user = _nearbyUsers[index];
                      final userId =
                          (user['user']?['id'] ?? user['userId'])?.toString();
                      final isSelected = userId == _selectedUserId;
                      return _buildHorizontalUserCard(user,
                          isSelected: isSelected);
                    },
                  ),
                ),
              ],
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
              decoration: BoxDecoration(
                color: AppTheme.bg(context),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.fg(context, 0.2),
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
                                color: AppTheme.textPrimary(context),
                              ),
                            ),
                            Text(
                              '${_nearbyUsers.length} ${_nearbyUsers.length == 1 ? 'person' : 'people'} found',
                              style: GoogleFonts.poppins(
                                fontSize: 11.5,
                                color: AppTheme.textSecondary(context),
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
                              color: AppTheme.fg(context, 0.08),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(Icons.close_rounded,
                                size: 17, color: AppTheme.fg(context, 0.7)),
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
              color: AppTheme.textPrimary(context),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Try widening your filters',
            style: GoogleFonts.poppins(
              fontSize: 12.5,
              color: AppTheme.textSecondary(context),
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
    var locating = false;
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
            // Geo-locate the device, then recenter on it.
            Future<void> useDevice() async {
              setModalState(() => locating = true);
              try {
                final loc = await _locationSearchService.getCurrentLocation();
                if (!sheetContext.mounted) return;
                setModalState(() => locating = false);
                if (loc != null) {
                  _selectSearchResult(loc, sheetContext);
                } else {
                  showPremiumSnack(context, 'Could not determine your location');
                }
              } catch (_) {
                if (!sheetContext.mounted) return;
                setModalState(() => locating = false);
                showPremiumSnack(context,
                    'Location unavailable. Enable location access and try again.');
              }
            }

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
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD7DAE0),
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
                                color: const Color(0xFF1A1D1E))),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => Navigator.pop(sheetContext),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE9EBEF),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.close_rounded,
                                size: 17, color: const Color(0xFF6B7280)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Search field — light field with black text + geo-locate
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: query.isNotEmpty
                              ? AppTheme.accent
                              : Colors.black.withOpacity(0.08),
                          width: 1.4,
                        ),
                      ),
                      child: TextField(
                        controller: searchController,
                        autofocus: true,
                        textInputAction: TextInputAction.search,
                        cursorColor: AppTheme.accent,
                        style: GoogleFonts.poppins(
                            color: Colors.black87,
                            fontSize: 15,
                            fontWeight: FontWeight.w500),
                        onChanged: runSearch,
                        decoration: InputDecoration(
                          hintText: 'Type a city, state or country',
                          hintStyle: GoogleFonts.poppins(
                              color: Colors.grey.shade500, fontSize: 14),
                          prefixIcon: const Icon(Icons.search_rounded,
                              color: AppTheme.accent, size: 22),
                          suffixIcon: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (query.isNotEmpty)
                                IconButton(
                                  icon: Icon(Icons.close_rounded,
                                      color: Colors.grey.shade500, size: 20),
                                  onPressed: () {
                                    searchController.clear();
                                    runSearch('');
                                  },
                                ),
                              // Use my location
                              Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: locating
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: Padding(
                                          padding: EdgeInsets.all(2),
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2.2,
                                              color: AppTheme.accent),
                                        ),
                                      )
                                    : IconButton(
                                        tooltip: 'Use my location',
                                        icon: const Icon(Icons.my_location_rounded,
                                            color: AppTheme.accent, size: 22),
                                        onPressed: useDevice,
                                      ),
                              ),
                            ],
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
                    color: const Color(0xFF1A1D1E))),
            const SizedBox(height: 6),
            Text(subtitle,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                    fontSize: 12.5, color: const Color(0xFF6B7280), height: 1.4)),
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
            color: const Color(0xFFF2F3F5),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0x14000000)),
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
                            color: const Color(0xFF1A1D1E))),
                    const SizedBox(height: 2),
                    Text(r.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                            fontSize: 11.5, color: const Color(0xFF9AA0A6))),
                  ],
                ),
              ),
              const Icon(Icons.north_east_rounded,
                  color: const Color(0xFFD7DAE0), size: 16),
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
    // Tribe options across all states (used when no state of origin is chosen).
    final allTribes = (<String>{for (final t in kStateTribes.values) ...t}.toList()
      ..sort());

    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          // Whitish-grey multi-select field; opens a checkbox sheet.
          Widget multiField(
            String label,
            IconData icon,
            List<String> selected,
            List<String> options, {
            List<({String? header, List<String> options})>? sections,
          }) {
            final summary = selected.isEmpty ? 'Any' : selected.join(', ');
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: AppTheme.surface(context),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.hairline(context)),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () async {
                    await _openMultiSelect(
                      title: label,
                      sections:
                          sections ?? [(header: null, options: options)],
                      selected: selected,
                    );
                    setModalState(() {});
                  },
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                    child: Row(
                      children: [
                        Icon(icon, size: 18, color: AppTheme.accent),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(label,
                                  style: GoogleFonts.poppins(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w500,
                                      color: AppTheme.textSecondary(context))),
                              const SizedBox(height: 1),
                              Text(
                                summary,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                    fontSize: 13.5,
                                    fontWeight: selected.isEmpty
                                        ? FontWeight.w500
                                        : FontWeight.w600,
                                    color: selected.isEmpty
                                        ? AppTheme.textFaint(context)
                                        : AppTheme.textPrimary(context)),
                              ),
                            ],
                          ),
                        ),
                        if (selected.isNotEmpty)
                          Container(
                            margin: const EdgeInsets.only(right: 6),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.accent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text('${selected.length}',
                                style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white)),
                          ),
                        Icon(Icons.keyboard_arrow_down_rounded,
                            color: AppTheme.textFaint(context)),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }

          // Gender stays a single mandatory choice (defaults to opposite user).
          Widget genderField() {
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.surface(context),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.hairline(context)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.wc_rounded, size: 18, color: AppTheme.accent),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Gender',
                            style: GoogleFonts.poppins(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.textSecondary(context))),
                        SizedBox(
                          height: 30,
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              isExpanded: true,
                              isDense: true,
                              value: _genderFilter ?? _defaultGender,
                              dropdownColor: AppTheme.surface(context),
                              borderRadius: BorderRadius.circular(14),
                              icon: Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  color: AppTheme.textFaint(context)),
                              style: GoogleFonts.poppins(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimary(context)),
                              items: const [
                                DropdownMenuItem(
                                    value: 'MALE', child: Text('Male')),
                                DropdownMenuItem(
                                    value: 'FEMALE', child: Text('Female')),
                              ],
                              onChanged: (v) => setModalState(
                                  () => _genderFilter = v ?? _defaultGender),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }

          // Tribe: sectionalized under each selected state of origin.
          Widget tribeField() {
            final sections = _stateOfOriginFilter.isEmpty
                ? [(header: null, options: allTribes)]
                : [
                    for (final s in _stateOfOriginFilter)
                      (header: s, options: tribesForState(s))
                  ];
            return multiField('Tribe', Icons.diversity_3_outlined, _tribeFilter,
                allTribes,
                sections: sections);
          }

          Widget sliderField(
              String label, IconData icon, String valueText, Widget slider) {
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
              decoration: BoxDecoration(
                color: AppTheme.surface(context),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.hairline(context)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(icon, size: 16, color: AppTheme.accent),
                      const SizedBox(width: 8),
                      Text(label,
                          style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textSecondary(context))),
                      const Spacer(),
                      Text(valueText,
                          style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.accent)),
                    ],
                  ),
                  _slimSlider(slider),
                ],
              ),
            );
          }

          return Container(
            height: MediaQuery.of(context).size.height * 0.9,
            decoration: BoxDecoration(
              color: AppTheme.bg(context),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.fg(context, 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 12, 12, 8),
                  child: Row(
                    children: [
                      Text('Filters',
                          style: GoogleFonts.poppins(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary(context))),
                      const Spacer(),
                      TextButton(
                        onPressed: () => setModalState(() {
                          _ageRange = const RangeValues(25, 35);
                          _distance = 50;
                          _genderFilter = _defaultGender;
                          _heightRange = const RangeValues(160, 185);
                          _bodyTypeFilter.clear();
                          _religionFilter.clear();
                          _smokingFilter.clear();
                          _drinkingFilter.clear();
                          _educationFilter.clear();
                          _hasChildrenFilter.clear();
                          _relationshipStatusFilter.clear();
                          _hivPartnerViewFilter.clear();
                          _residenceStateFilter.clear();
                          _stateOfOriginFilter.clear();
                          _tribeFilter.clear();
                          _zodiacFilter.clear();
                          _genotypeFilter.clear();
                          _bloodGroupFilter.clear();
                          _showOnlyVerified = false;
                          _showOnlyPremium = false;
                          _showOnlyOnline = false;
                        }),
                        child: Text('Reset',
                            style: GoogleFonts.poppins(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.accent)),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: AppTheme.fg(context, 0.08),
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: Icon(Icons.close_rounded,
                              size: 16, color: AppTheme.fg(context, 0.7)),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(2, 0, 2, 14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Find your kind of person',
                                style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.textPrimary(context))),
                            const SizedBox(height: 3),
                            Text(
                                'Dial in the details and we\'ll surface the matches that fit.',
                                style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: AppTheme.textSecondary(context),
                                    height: 1.35)),
                          ],
                        ),
                      ),
                      genderField(),
                      sliderField(
                        'Age',
                        Icons.cake_outlined,
                        '${_ageRange.start.round()}–${_ageRange.end.round()} yrs',
                        RangeSlider(
                          values: _ageRange,
                          min: 18,
                          max: 100,
                          divisions: 82,
                          activeColor: AppTheme.accent,
                          inactiveColor: AppTheme.fg(context, 0.12),
                          labels: RangeLabels('${_ageRange.start.round()}',
                              '${_ageRange.end.round()}'),
                          onChanged: (v) => setModalState(() => _ageRange = v),
                        ),
                      ),
                      sliderField(
                        'Distance',
                        Icons.social_distance_rounded,
                        'Within ${_distance.round()} km',
                        Slider(
                          value: _distance,
                          min: 1,
                          max: 500,
                          divisions: 499,
                          activeColor: AppTheme.accent,
                          inactiveColor: AppTheme.fg(context, 0.12),
                          label: '${_distance.round()} km',
                          onChanged: (v) => setModalState(() => _distance = v),
                        ),
                      ),
                      multiField('Location (lives in)', Icons.place_outlined,
                          _residenceStateFilter, kNigerianStates),
                      multiField('State of Origin', Icons.flag_outlined,
                          _stateOfOriginFilter, kNigerianStates),
                      tribeField(),
                      multiField(
                          'Zodiac',
                          Icons.star_outline_rounded,
                          _zodiacFilter,
                          const [
                            'Aries', 'Taurus', 'Gemini', 'Cancer', 'Leo',
                            'Virgo', 'Libra', 'Scorpio', 'Sagittarius',
                            'Capricorn', 'Aquarius', 'Pisces'
                          ]),
                      multiField(
                          'Religion',
                          Icons.church_outlined,
                          _religionFilter,
                          const ['Christianity', 'Islam', 'Traditional', 'Other']),
                      multiField('Genotype', Icons.biotech_outlined,
                          _genotypeFilter, const ['AA', 'AS', 'SS', 'AC', 'SC']),
                      multiField(
                          'Blood Group',
                          Icons.bloodtype_outlined,
                          _bloodGroupFilter,
                          const ['O+', 'O-', 'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-']),
                      sliderField(
                        'Height',
                        Icons.height_rounded,
                        '${_heightRange.start.round()}–${_heightRange.end.round()} cm',
                        RangeSlider(
                          values: _heightRange,
                          min: 140,
                          max: 220,
                          divisions: 80,
                          activeColor: AppTheme.accent,
                          inactiveColor: AppTheme.fg(context, 0.12),
                          labels: RangeLabels('${_heightRange.start.round()}',
                              '${_heightRange.end.round()}'),
                          onChanged: (v) =>
                              setModalState(() => _heightRange = v),
                        ),
                      ),
                      multiField(
                          'Body Type',
                          Icons.accessibility_new_rounded,
                          _bodyTypeFilter,
                          const [
                            'Slim', 'Petite', 'Average', 'Athletic', 'Muscular',
                            'Curvy', 'Stocky', 'Full-figured', 'Heavyset'
                          ]),
                      multiField(
                          'Education',
                          Icons.school_outlined,
                          _educationFilter,
                          const [
                            'High School', 'Bachelor\'s Degree',
                            'Master\'s Degree', 'PhD'
                          ]),
                      multiField(
                          'Relationship Status',
                          Icons.favorite_border_rounded,
                          _relationshipStatusFilter,
                          const ['Single', 'Divorced', 'Widowed', 'Separated']),
                      multiField('Children', Icons.child_care_outlined,
                          _hasChildrenFilter,
                          const ['Yes', 'No', 'Want children']),
                      multiField('Smoking', Icons.smoking_rooms_outlined,
                          _smokingFilter, const ['Yes', 'No', 'Occasionally']),
                      multiField('Drinking', Icons.local_bar_outlined,
                          _drinkingFilter, const ['Yes', 'No', 'Socially']),
                      multiField(
                          'Views on HIV+ Partner',
                          Icons.health_and_safety_outlined,
                          _hivPartnerViewFilter,
                          const ['Open to discussion', 'Yes', 'No']),
                      Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.fromLTRB(14, 4, 14, 4),
                        decoration: BoxDecoration(
                          color: AppTheme.surface(context),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppTheme.hairline(context)),
                        ),
                        child: Column(
                          children: [
                            _filterToggle('Verified users', _showOnlyVerified,
                                (v) => setModalState(() => _showOnlyVerified = v)),
                            _filterToggle('Premium users', _showOnlyPremium,
                                (v) => setModalState(() => _showOnlyPremium = v)),
                            _filterToggle('Online now', _showOnlyOnline,
                                (v) => setModalState(() => _showOnlyOnline = v)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
                  decoration: BoxDecoration(
                    color: AppTheme.bg(context),
                    border: Border(
                        top: BorderSide(color: AppTheme.hairline(context))),
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
                            _applyFiltersWithAnimation(onApplied);
                          },
                          child: Center(
                            child: Text('Apply Filters',
                                style: GoogleFonts.poppins(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white)),
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

  /// Opens a checkbox bottom sheet for a multi-select facet. [sections] lets the
  /// tribe picker group options under each selected state of origin. Mutates
  /// [selected] in place; returns when the user is done.
  Future<void> _openMultiSelect({
    required String title,
    required List<({String? header, List<String> options})> sections,
    required List<String> selected,
  }) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (sheetCtx, setSheet) {
          return Container(
            height: MediaQuery.of(sheetCtx).size.height * 0.7,
            decoration: BoxDecoration(
              color: AppTheme.bg(sheetCtx),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: AppTheme.fg(sheetCtx, 0.2),
                      borderRadius: BorderRadius.circular(2)),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 12, 12, 6),
                  child: Row(
                    children: [
                      Text(title,
                          style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary(sheetCtx))),
                      const Spacer(),
                      if (selected.isNotEmpty)
                        TextButton(
                          onPressed: () => setSheet(() => selected.clear()),
                          child: Text('Clear',
                              style: GoogleFonts.poppins(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.accent)),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                    children: [
                      for (final section in sections) ...[
                        if (section.header != null)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(4, 12, 4, 6),
                            child: Text(section.header!.toUpperCase(),
                                style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.6,
                                    color: AppTheme.accent)),
                          ),
                        ...section.options.map((o) {
                          final on = selected.contains(o);
                          return GestureDetector(
                            onTap: () => setSheet(() =>
                                on ? selected.remove(o) : selected.add(o)),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 13),
                              decoration: BoxDecoration(
                                color: on
                                    ? AppTheme.accent.withOpacity(0.16)
                                    : AppTheme.surface(sheetCtx),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: on
                                        ? AppTheme.accent
                                        : AppTheme.hairline(sheetCtx)),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    on
                                        ? Icons.check_box_rounded
                                        : Icons.check_box_outline_blank_rounded,
                                    color: on
                                        ? AppTheme.accent
                                        : AppTheme.textFaint(sheetCtx),
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(o,
                                        style: GoogleFonts.poppins(
                                            fontSize: 13.5,
                                            fontWeight: on
                                                ? FontWeight.w600
                                                : FontWeight.w500,
                                            color: AppTheme.textPrimary(sheetCtx))),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ],
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 14),
                  child: SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: AppTheme.accentGradient,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () => Navigator.pop(sheetCtx),
                          child: Center(
                            child: Text(
                              selected.isEmpty
                                  ? 'Done'
                                  : 'Done · ${selected.length} selected',
                              style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white),
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

  Widget _filterToggle(String label, bool value, ValueChanged<bool> onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: GoogleFonts.poppins(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: AppTheme.textPrimary(context))),
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
    );
  }

  /// Runs the post-filter refresh behind an animated "filtering" overlay so it
  /// feels like results are actively being matched.
  Future<void> _applyFiltersWithAnimation(VoidCallback? onApplied) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      builder: (_) => const _FilteringOverlay(),
    );
    final started = DateTime.now();
    if (onApplied != null) {
      onApplied();
    } else {
      setState(() {});
      await Future.wait([_fetchNearbyUsers(), _fetchSuggestions()]);
    }
    // Keep the animation on screen long enough to register.
    const minDuration = Duration(milliseconds: 1100);
    final elapsed = DateTime.now().difference(started);
    if (elapsed < minDuration) {
      await Future.delayed(minDuration - elapsed);
    }
    if (mounted) Navigator.of(context, rootNavigator: true).pop();
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
}

/// Animated overlay shown while filters are being applied — pulsing rings around
/// a heart give the feeling that matches are actively being found.
class _FilteringOverlay extends StatefulWidget {
  const _FilteringOverlay();

  @override
  State<_FilteringOverlay> createState() => _FilteringOverlayState();
}

class _FilteringOverlayState extends State<_FilteringOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 26),
        decoration: BoxDecoration(
          color: AppTheme.darkSurface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 30,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 76,
              height: 76,
              child: AnimatedBuilder(
                animation: _c,
                builder: (context, child) {
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      // Expanding rings
                      for (int i = 0; i < 3; i++)
                        _ring((i / 3.0)),
                      // Center heart
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: AppTheme.accentGradient,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.accent.withOpacity(0.5),
                              blurRadius: 16,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: const Icon(Icons.favorite_rounded,
                            color: Colors.white, size: 22),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Finding your matches…',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _ring(double phase) {
    final t = (_c.value + phase) % 1.0;
    final size = 30 + t * 46;
    final opacity = (1.0 - t).clamp(0.0, 1.0) * 0.5;
    return Opacity(
      opacity: opacity,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppTheme.accent, width: 2),
        ),
      ),
    );
  }
}
