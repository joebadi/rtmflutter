import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import '../config/theme.dart';
import '../services/match_service.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  // 0 = Map (Default), 1 = Cards, 2 = Grid
  int _viewMode = 0; 
  final CardSwiperController swipeController = CardSwiperController();
  final MapController mapController = MapController();
  final MatchService _matchService = MatchService();

  // State
  bool _isLoading = true;
  LatLng? _currentLocation;
  List<dynamic> _nearbyUsers = [];
  List<dynamic> _suggestions = [];
  String _locationName = 'Locating...';

  @override
  void initState() {
    super.initState();
    _initializeData();
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
      // Check permissions (simplified for now, ideally reused from a service)
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      
      if (permission == LocationPermission.whileInUse || 
          permission == LocationPermission.always) {
        final position = await Geolocator.getCurrentPosition();
        setState(() {
          _currentLocation = LatLng(position.latitude, position.longitude);
          // TODO: Reverse geocode for _locationName if needed, or pass from previous screen
          _locationName = 'New York, USA (Approx)'; 
        });
      }
    } catch (e) {
      debugPrint('Error getting location: $e');
    }
  }

  Future<void> _fetchNearbyUsers() async {
    if (_currentLocation == null) return;
    try {
      final users = await _matchService.getNearbyUsers(
        latitude: _currentLocation!.latitude,
        longitude: _currentLocation!.longitude,
        radius: 50, // 50km
      );
      setState(() => _nearbyUsers = users);
    } catch (e) {
      debugPrint('Error fetching nearby users: $e');
      if (mounted) {
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
                onPressed: () {}, // Filter modal
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Row(
              children: [
                const Icon(Icons.location_on, color: Color(0xFFFF5722), size: 14),
                const SizedBox(width: 4),
                Text(
                  _locationName,
                  style: GoogleFonts.poppins(fontSize: 12, color: Colors.black87),
                ),
              ],
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

    return FlutterMap(
      mapController: mapController,
      options: MapOptions(
        initialCenter: _currentLocation!, // San Francisco fallback if null logic fails
        initialZoom: 11.0,
        keepAlive: true, // Keep map state when switching tabs
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
               // Add safety check/defaults
              final lat = (user['latitude'] as num?)?.toDouble() ?? 0.0;
              final lng = (user['longitude'] as num?)?.toDouble() ?? 0.0;
              final profile = user['profile'];
              final photoUrl = (profile?['photos'] as List?)?.firstWhere(
                (p) => p['isPrimary'] == true,
                orElse: () => null,
              )?['url'];

              return Marker(
                point: LatLng(lat, lng),
                width: 50,
                height: 50,
                child: GestureDetector(
                  onTap: () => _showUserPreview(user),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      backgroundImage: photoUrl != null 
                        ? NetworkImage(photoUrl) 
                        : const AssetImage('assets/images/placeholder_avatar.png') as ImageProvider,
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ],
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
      builder: (context) {
        final profile = user['profile'];
        final firstName = profile?['firstName'] ?? 'User';
        final age = profile?['dateOfBirth'] != null 
            ? (DateTime.now().year - DateTime.parse(profile['dateOfBirth']).year).toString()
            : '??';
        final photoUrl = (profile?['photos'] as List?)?.firstWhere(
                (p) => p['isPrimary'] == true,
                orElse: () => null,
              )?['url'];

        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            children: [
               CircleAvatar(
                 radius: 30,
                 backgroundImage: photoUrl != null 
                    ? NetworkImage(photoUrl) 
                    : const AssetImage('assets/images/placeholder_avatar.png') as ImageProvider,
               ),
               const SizedBox(width: 16),
               Expanded(
                 child: Column(
                   mainAxisSize: MainAxisSize.min,
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     Text(
                       '$firstName, $age',
                       style: GoogleFonts.poppins(
                         fontWeight: FontWeight.bold,
                         fontSize: 18,
                       ),
                     ),
                     Text(
                       user['address'] ?? 'Nearby', // Fallback address
                       style: GoogleFonts.poppins(
                         color: Colors.grey[600],
                         fontSize: 14,
                       ),
                     ),
                   ],
                 ),
               ),
               IconButton(
                 icon: const Icon(Icons.arrow_forward_ios, color: Color(0xFFFF5722)),
                 onPressed: () {
                    context.pop(); // Close modal
                    // Navigate to full profile if route exists
                    // context.push('/profile-view', extra: user);
                 },
               )
            ],
          ),
        );
      },
    );
  }

  // --- CARDS VIEW ---
  Widget _buildCardSwipeView() {
    if (_suggestions.isEmpty) {
       return _buildEmptyState('No active matches nearby.', Icons.explore_off);
    }

    return Column(
      children: [
        Expanded(
          child: CardSwiper(
            controller: swipeController,
            cardsCount: _suggestions.length,
            numberOfCardsDisplayed: 3,
            backCardOffset: const Offset(0, 40),
            padding: const EdgeInsets.all(16),
            cardBuilder: (context, index, horizontalOffset, verticalOffset) {
              final user = _suggestions[index];
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
      final profile = user['profile'];
      final name = profile?['firstName'] ?? 'User';
      final age = profile?['dateOfBirth'] != null 
          ? (DateTime.now().year - DateTime.parse(profile['dateOfBirth']).year).toString()
          : '';
      final bio = profile?['aboutMe'] ?? 'No bio yet.';
      final photoUrl = (profile?['photos'] as List?)?.firstWhere(
              (p) => p['isPrimary'] == true,
              orElse: () => null,
            )?['url'];

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(20),
        image: photoUrl != null 
            ? DecorationImage(image: NetworkImage(photoUrl), fit: BoxFit.cover)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        children: [
           // Gradient Overlay
           Container(
             decoration: BoxDecoration(
               borderRadius: BorderRadius.circular(20),
               gradient: LinearGradient(
                 begin: Alignment.topCenter,
                 end: Alignment.bottomCenter,
                 colors: [
                   Colors.transparent,
                   Colors.black.withOpacity(0.9),
                 ],
                 stops: const [0.6, 1.0],
               ),
             ),
           ),
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '$name, $age',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.verified, color: Colors.blue, size: 24),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  bio,
                  style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
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
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, color: color),
        iconSize: 28,
        padding: const EdgeInsets.all(12),
      ),
    );
  }

  // --- GRID VIEW ---
  Widget _buildGridView() {
    if (_suggestions.isEmpty) {
       return _buildEmptyState('No one around yet.', Icons.people_outline);
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.75,
      ),
      itemCount: _suggestions.length,
      itemBuilder: (context, index) {
        final user = _suggestions[index];
        final profile = user['profile'];
        final photoUrl = (profile?['photos'] as List?)?.firstWhere(
                (p) => p['isPrimary'] == true,
                orElse: () => null,
              )?['url'];
        final name = profile?['firstName'] ?? 'User';

        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
             color: Colors.grey[200],
             image: photoUrl != null 
                ? DecorationImage(image: NetworkImage(photoUrl), fit: BoxFit.cover)
                : null,
          ),
          child: Stack(
            children: [
              Container(
                 decoration: BoxDecoration(
                   borderRadius: BorderRadius.circular(16),
                   gradient: LinearGradient(
                     begin: Alignment.topCenter,
                     end: Alignment.bottomCenter,
                     colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
                   ),
                 ),
               ),
               Positioned(
                 bottom: 12,
                 left: 12,
                 child: Text(
                   name,
                   style: GoogleFonts.poppins(
                     color: Colors.white,
                     fontWeight: FontWeight.bold,
                     fontSize: 16,
                   ),
                 ),
               ),
            ],
          ),
        );
      },
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
}
