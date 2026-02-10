import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import '../widgets/notification_icon.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final CardSwiperController controller = CardSwiperController();

  // Mock Data for "Wow" Effect
  final List<Map<String, dynamic>> _candidates = [
    {
      'name': 'Sophia Williams',
      'age': 25,
      'bio':
          'Book lover, coffee enthusiast, and part-time traveler. Looking for someone to share deep conversations.',
      'image':
          'assets/profile1.jpg', // We'll use a placeholder gradient since we don't have assets yet
      'color': Colors.orangeAccent,
    },
    {
      'name': 'Mia Kennedy',
      'age': 23,
      'bio':
          'Yoga instructor 🧘‍♀️ and vegan foodie. Let\'s explore the city together!',
      'image': 'assets/profile2.jpg',
      'color': Colors.blueAccent,
    },
    {
      'name': 'Olivia Thompson',
      'age': 27,
      'bio':
          'Artist by day, gamer by night. Swipe right if you can beat me at Mario Kart.',
      'image': 'assets/profile3.jpg',
      'color': Colors.purpleAccent,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Nearby You',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const NotificationIcon(),
                      IconButton(
                        onPressed: () {}, // TODO: Filters
                        icon: const Icon(Icons.tune_rounded),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Card Stack
            Expanded(
              child: CardSwiper(
                controller: controller,
                cardsCount: _candidates.length,
                numberOfCardsDisplayed: 3,
                backCardOffset: const Offset(0, 40),
                padding: const EdgeInsets.all(16),
                cardBuilder:
                    (context, index, horizontalOffset, verticalOffset) {
                      final candidate = _candidates[index];
                      return _buildCard(candidate);
                    },
              ),
            ),

            // Bottom Action Bar (Floating above the card stack effectively in layouts,
            // but here we put it below to ensure tap targets are clear like standard apps)
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
        ),
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> candidate) {
    return Container(
      decoration: BoxDecoration(
        color: candidate['color'], // Fallback color
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
            Colors.black.withOpacity(0.9), // Darker at bottom
          ],
        ),
      ),
      child: Stack(
        children: [
          // Content Overlay
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

          // Distance Badge
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
                children: const [
                  Icon(Icons.location_on, color: Colors.white, size: 16),
                  SizedBox(width: 4),
                  Text(
                    '3.5 km away',
                    style: TextStyle(
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
}
