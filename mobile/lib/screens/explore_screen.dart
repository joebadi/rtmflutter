import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/theme.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  int _viewMode = 0; // 0 = Card Swipe, 1 = Map, 2 = Grid
  final CardSwiperController controller = CardSwiperController();

  // Mock Data
  final List<Map<String, dynamic>> _candidates = [
    {
      'name': 'Sophia Williams',
      'age': 25,
      'bio':
          'Book lover, coffee enthusiast, and part-time traveler. Looking for someone to share deep conversations.',
      'color': Colors.orangeAccent,
      'distance': '3.5 km',
    },
    {
      'name': 'Mia Kennedy',
      'age': 23,
      'bio':
          'Yoga instructor 🧘‍♀️ and vegan foodie. Let\'s explore the city together!',
      'color': Colors.blueAccent,
      'distance': '1.2 km',
    },
    {
      'name': 'Olivia Thompson',
      'age': 27,
      'bio':
          'Artist by day, gamer by night. Swipe right if you can beat me at Mario Kart.',
      'color': Colors.purpleAccent,
      'distance': '2.8 km',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _viewMode == 0 ? Colors.white : Colors.grey[100],
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Explore',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: [
                      if (_viewMode != 0)
                        IconButton(
                          icon: const Icon(Icons.search),
                          onPressed: () {},
                        ),
                      IconButton(
                        icon: const Icon(Icons.tune),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Location Chip (only for Map and Grid views)
            if (_viewMode != 0)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Row(
                        children: [
                          Text(
                            'Los Angeles, CA',
                            style: GoogleFonts.poppins(fontSize: 13),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.keyboard_arrow_down, size: 18),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 16),

            // Embossed Pill Filter Buttons (Left-aligned)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  // Cards Button
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    decoration: BoxDecoration(
                      gradient: _viewMode == 0
                          ? const LinearGradient(
                              colors: [Color(0xFFFF5722), Color(0xFFFF7043)],
                            )
                          : null,
                      color: _viewMode == 0
                          ? null
                          : Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _viewMode == 0
                            ? Colors.transparent
                            : Colors.grey[300]!,
                        width: 1.5,
                      ),
                      boxShadow: [
                        if (_viewMode == 0)
                          BoxShadow(
                            color: const Color(0xFFFF5722).withOpacity(0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => setState(() => _viewMode = 0),
                        borderRadius: BorderRadius.circular(20),
                        child: AnimatedPadding(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeInOut,
                          padding: EdgeInsets.symmetric(
                            horizontal: _viewMode == 0 ? 12 : 10,
                            vertical: 8,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.style,
                                size: 18,
                                color: _viewMode == 0
                                    ? Colors.white
                                    : Colors.grey[700],
                              ),
                              AnimatedSize(
                                duration: const Duration(milliseconds: 250),
                                curve: Curves.easeInOut,
                                child: _viewMode == 0
                                    ? Row(
                                        children: [
                                          const SizedBox(width: 5),
                                          Text(
                                            'Cards',
                                            style: GoogleFonts.poppins(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      )
                                    : const SizedBox.shrink(),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Map Button
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    decoration: BoxDecoration(
                      gradient: _viewMode == 1
                          ? const LinearGradient(
                              colors: [Color(0xFFFF5722), Color(0xFFFF7043)],
                            )
                          : null,
                      color: _viewMode == 1
                          ? null
                          : Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _viewMode == 1
                            ? Colors.transparent
                            : Colors.grey[300]!,
                        width: 1.5,
                      ),
                      boxShadow: [
                        if (_viewMode == 1)
                          BoxShadow(
                            color: const Color(0xFFFF5722).withOpacity(0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => setState(() => _viewMode = 1),
                        borderRadius: BorderRadius.circular(20),
                        child: AnimatedPadding(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeInOut,
                          padding: EdgeInsets.symmetric(
                            horizontal: _viewMode == 1 ? 12 : 10,
                            vertical: 8,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.location_on,
                                size: 18,
                                color: _viewMode == 1
                                    ? Colors.white
                                    : Colors.grey[700],
                              ),
                              AnimatedSize(
                                duration: const Duration(milliseconds: 250),
                                curve: Curves.easeInOut,
                                child: _viewMode == 1
                                    ? Row(
                                        children: [
                                          const SizedBox(width: 5),
                                          Text(
                                            'Map',
                                            style: GoogleFonts.poppins(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      )
                                    : const SizedBox.shrink(),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Grid Button
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    decoration: BoxDecoration(
                      gradient: _viewMode == 2
                          ? const LinearGradient(
                              colors: [Color(0xFFFF5722), Color(0xFFFF7043)],
                            )
                          : null,
                      color: _viewMode == 2
                          ? null
                          : Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _viewMode == 2
                            ? Colors.transparent
                            : Colors.grey[300]!,
                        width: 1.5,
                      ),
                      boxShadow: [
                        if (_viewMode == 2)
                          BoxShadow(
                            color: const Color(0xFFFF5722).withOpacity(0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => setState(() => _viewMode = 2),
                        borderRadius: BorderRadius.circular(20),
                        child: AnimatedPadding(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeInOut,
                          padding: EdgeInsets.symmetric(
                            horizontal: _viewMode == 2 ? 12 : 10,
                            vertical: 8,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.grid_view,
                                size: 18,
                                color: _viewMode == 2
                                    ? Colors.white
                                    : Colors.grey[700],
                              ),
                              AnimatedSize(
                                duration: const Duration(milliseconds: 250),
                                curve: Curves.easeInOut,
                                child: _viewMode == 2
                                    ? Row(
                                        children: [
                                          const SizedBox(width: 5),
                                          Text(
                                            'Grid',
                                            style: GoogleFonts.poppins(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      )
                                    : const SizedBox.shrink(),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Content based on view mode
            Expanded(child: _buildContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildSegmentButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
    required SegmentPosition position,
  }) {
    BorderRadius borderRadius;
    switch (position) {
      case SegmentPosition.left:
        borderRadius = const BorderRadius.only(
          topLeft: Radius.circular(25),
          bottomLeft: Radius.circular(25),
        );
        break;
      case SegmentPosition.center:
        borderRadius = BorderRadius.zero;
        break;
      case SegmentPosition.right:
        borderRadius = const BorderRadius.only(
          topRight: Radius.circular(25),
          bottomRight: Radius.circular(25),
        );
        break;
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: isActive ? Colors.deepOrange : Colors.grey[200],
          borderRadius: borderRadius,
          boxShadow: isActive
              ? [
                  // Depressed/inset shadow for active
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                    spreadRadius: -1,
                  ),
                  BoxShadow(
                    color: Colors.deepOrange.shade700.withOpacity(0.5),
                    blurRadius: 6,
                    offset: const Offset(0, 1),
                    spreadRadius: -2,
                  ),
                ]
              : [
                  // Beveled/raised shadow for inactive
                  BoxShadow(
                    color: Colors.white.withOpacity(0.8),
                    blurRadius: 2,
                    offset: const Offset(-1, -1),
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 2,
                    offset: const Offset(1, 1),
                  ),
                ],
        ),
        child: Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: ScaleTransition(scale: animation, child: child),
              );
            },
            child: isActive
                ? Row(
                    key: ValueKey('active_$label'),
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, size: 20, color: Colors.white),
                      const SizedBox(width: 6),
                      Text(
                        label,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  )
                : Icon(
                    key: ValueKey('inactive_$label'),
                    icon,
                    size: 20,
                    color: Colors.grey[600],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    switch (_viewMode) {
      case 0:
        return _buildCardSwipeView();
      case 1:
        return _buildMapView();
      case 2:
        return _buildGridView();
      default:
        return _buildCardSwipeView();
    }
  }

  // Card Swipe View
  Widget _buildCardSwipeView() {
    return Column(
      children: [
        Expanded(
          child: CardSwiper(
            controller: controller,
            cardsCount: _candidates.length,
            numberOfCardsDisplayed: 3,
            backCardOffset: const Offset(0, 40),
            padding: const EdgeInsets.all(16),
            cardBuilder: (context, index, horizontalOffset, verticalOffset) {
              final candidate = _candidates[index];
              return _buildSwipeCard(candidate);
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildActionButton(
                Icons.refresh,
                Colors.orange,
                () => controller.undo(),
              ),
              _buildActionButton(
                Icons.close,
                Colors.red,
                () => controller.swipe(CardSwiperDirection.left),
              ),
              _buildActionButton(
                Icons.star,
                Colors.blue,
                () => controller.swipe(CardSwiperDirection.top),
              ),
              _buildActionButton(
                Icons.favorite,
                Colors.green,
                () => controller.swipe(CardSwiperDirection.right),
              ),
              _buildActionButton(Icons.flash_on, Colors.purple, () {}),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSwipeCard(Map<String, dynamic> candidate) {
    return Container(
      decoration: BoxDecoration(
        color: candidate['color'],
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            candidate['color'].withOpacity(0.8),
            Colors.black.withOpacity(0.9),
          ],
        ),
      ),
      child: Stack(
        children: [
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
                      '${candidate['name']}, ${candidate['age']}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.verified, color: Colors.blue, size: 24),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  candidate['bio'],
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Positioned(
            top: 20,
            left: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_on, color: Colors.white, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    '${candidate['distance']} away',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
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

  // Map View
  Widget _buildMapView() {
    return Stack(
      children: [
        Container(
          color: Colors.grey[200],
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.map, size: 80, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'Map View',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          top: 100,
          left: 100,
          child: _buildUserMarker('https://i.pravatar.cc/150?img=47', true),
        ),
        Positioned(
          top: 200,
          right: 80,
          child: _buildUserMarker('https://i.pravatar.cc/150?img=23', false),
        ),
        Positioned(
          bottom: 20,
          left: 16,
          right: 16,
          child: SizedBox(
            height: 200,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildUserCard(
                  'Charlotte Martin, 24',
                  'Los Angeles, CA',
                  '1.6 Km',
                  'https://i.pravatar.cc/300?img=47',
                ),
                const SizedBox(width: 12),
                _buildUserCard(
                  'Lily Foster, 26',
                  'Los Angeles, CA',
                  '1.2 Km',
                  'https://i.pravatar.cc/300?img=23',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUserMarker(String imageUrl, bool isActive) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isActive ? AppTheme.primary : Colors.white,
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: CircleAvatar(backgroundImage: NetworkImage(imageUrl)),
    );
  }

  Widget _buildUserCard(
    String name,
    String location,
    String distance,
    String imageUrl,
  ) {
    return Container(
      width: 160,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(imageUrl, fit: BoxFit.cover),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                ),
              ),
            ),
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  distance,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 12,
              left: 12,
              right: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    location,
                    style: GoogleFonts.poppins(
                      color: Colors.white70,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Grid View
  Widget _buildGridView() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: 6,
      itemBuilder: (context, index) {
        final names = [
          'Charlotte Martin, 24',
          'Lily Foster, 26',
          'Emma Wilson, 23',
          'Sophia Davis, 25',
          'Olivia Brown, 27',
          'Mia Johnson, 24',
        ];
        final distances = [
          '1.6 Km',
          '1.2 Km',
          '2.3 Km',
          '0.8 Km',
          '3.1 Km',
          '1.9 Km',
        ];
        final images = [47, 23, 32, 28, 45, 9];

        return _buildGridCard(
          names[index],
          'Los Angeles, CA',
          distances[index],
          'https://i.pravatar.cc/300?img=${images[index]}',
        );
      },
    );
  }

  Widget _buildGridCard(
    String name,
    String location,
    String distance,
    String imageUrl,
  ) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(imageUrl, fit: BoxFit.cover),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                ),
              ),
            ),
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  distance,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 8,
              left: 8,
              right: 8,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    location,
                    style: GoogleFonts.poppins(
                      color: Colors.white70,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum SegmentPosition { left, center, right }
