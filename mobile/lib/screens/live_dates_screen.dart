import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/theme.dart';
import '../widgets/notification_icon.dart';

class LiveDatesScreen extends StatefulWidget {
  const LiveDatesScreen({super.key});

  @override
  State<LiveDatesScreen> createState() => _LiveDatesScreenState();
}

class _LiveDatesScreenState extends State<LiveDatesScreen> {
  bool _isInRoom = false;
  bool _isOnCall = false;
  String? _selectedUserId;

  // Mock data for available users
  final List<Map<String, dynamic>> _availableUsers = [
    {
      'id': '1',
      'name': 'Sarah Johnson',
      'age': 24,
      'image': 'https://i.pravatar.cc/300?img=47',
      'isAvailable': true,
    },
    {
      'id': '2',
      'name': 'Emily Davis',
      'age': 26,
      'image': 'https://i.pravatar.cc/300?img=23',
      'isAvailable': true,
    },
    {
      'id': '3',
      'name': 'Jessica Wilson',
      'age': 25,
      'image': 'https://i.pravatar.cc/300?img=32',
      'isAvailable': false,
    },
    {
      'id': '4',
      'name': 'Amanda Brown',
      'age': 27,
      'image': 'https://i.pravatar.cc/300?img=28',
      'isAvailable': true,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
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
                    'Live Dates',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Row(
                    children: [
                      const NotificationIcon(isDark: true),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.tune, color: Colors.white),
                        onPressed: () {
                          // Show filter dialog
                        },
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
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
                              '${_availableUsers.where((u) => u['isAvailable'] == true).length} Online',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Main Content
            Expanded(child: _isInRoom ? _buildDateRoom() : _buildLobby()),
          ],
        ),
      ),
    );
  }

  // Lobby View (Before joining room)
  Widget _buildLobby() {
    return Column(
      children: [
        const SizedBox(height: 20),

        // Illustration/Icon
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.primary, AppTheme.primaryLight],
            ),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.video_call, size: 60, color: Colors.white),
        ),

        const SizedBox(height: 30),

        // Title
        Text(
          'Instant Video Dates',
          style: GoogleFonts.poppins(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),

        const SizedBox(height: 12),

        // Description
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            'Connect with people instantly through live video dates. Meet face-to-face and spark real connections.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.white.withOpacity(0.7),
              height: 1.5,
            ),
          ),
        ),

        const SizedBox(height: 40),

        // Stats Cards
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  '${_availableUsers.where((u) => u['isAvailable'] == true).length}',
                  'Available Now',
                  Icons.people,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  '${_availableUsers.where((u) => u['isAvailable'] == false).length}',
                  'On Dates',
                  Icons.video_call,
                  Colors.orange,
                ),
              ),
            ],
          ),
        ),

        const Spacer(),

        // Join Button
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => setState(() => _isInRoom = true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.video_call, color: Colors.white),
                      const SizedBox(width: 8),
                      Text(
                        'Join Date Room',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Your camera will be activated when you join',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.5),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String value,
    String label,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.white.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  // Date Room View (After joining)
  Widget _buildDateRoom() {
    return Column(
      children: [
        // Video Preview Area
        Expanded(
          flex: 3,
          child: Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
                width: 2,
              ),
            ),
            child: Stack(
              children: [
                // Video placeholder
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.videocam_off,
                        size: 60,
                        color: Colors.white.withOpacity(0.3),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _isOnCall ? 'Connecting...' : 'Waiting for match',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                ),

                // Self preview (small)
                Positioned(
                  top: 16,
                  right: 16,
                  child: Container(
                    width: 100,
                    height: 140,
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Icon(
                        Icons.person,
                        size: 40,
                        color: Colors.white.withOpacity(0.5),
                      ),
                    ),
                  ),
                ),

                // Controls overlay
                Positioned(
                  bottom: 16,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildCallButton(Icons.mic_off, Colors.white, () {}),
                      const SizedBox(width: 16),
                      _buildCallButton(Icons.videocam_off, Colors.white, () {}),
                      const SizedBox(width: 16),
                      _buildCallButton(Icons.call_end, Colors.red, () {
                        setState(() {
                          _isOnCall = false;
                          _selectedUserId = null;
                        });
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // Available Users List
        Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Available for Date',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => setState(() => _isInRoom = false),
                    icon: const Icon(
                      Icons.exit_to_app,
                      color: Colors.red,
                      size: 18,
                    ),
                    label: Text(
                      'Leave Room',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 140,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _availableUsers.length,
                  itemBuilder: (context, index) {
                    final user = _availableUsers[index];
                    return _buildUserCard(user);
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCallButton(IconData icon, Color color, VoidCallback onPressed) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, color: color),
        iconSize: 28,
        padding: const EdgeInsets.all(12),
      ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    final isAvailable = user['isAvailable'] as bool;
    final isSelected = _selectedUserId == user['id'];

    return GestureDetector(
      onTap: isAvailable
          ? () {
              setState(() {
                _selectedUserId = user['id'];
                _isOnCall = true;
              });
              // Show request dialog or start call
            }
          : null,
      child: Container(
        width: 100,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          children: [
            Stack(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.primary
                          : (isAvailable ? Colors.green : Colors.grey),
                      width: 3,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(user['image'], fit: BoxFit.cover),
                        if (!isAvailable)
                          Container(
                            color: Colors.black.withOpacity(0.6),
                            child: const Center(
                              child: Icon(
                                Icons.videocam,
                                color: Colors.white,
                                size: 30,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: isAvailable ? Colors.green : Colors.grey,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              user['name'],
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            Text(
              isAvailable ? 'Available' : 'On Date',
              style: GoogleFonts.poppins(
                fontSize: 10,
                color: isAvailable ? Colors.green : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
