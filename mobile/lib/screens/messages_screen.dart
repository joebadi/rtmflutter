import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final TextEditingController _searchController = TextEditingController();
  
  // Sample active chats for shortcuts
  final List<Map<String, dynamic>> _activeChats = [
    {
      'name': 'Olivia',
      'imageUrl': 'https://i.pravatar.cc/150?img=1',
      'isOnline': true,
    },
    {
      'name': 'Daniel',
      'imageUrl': 'https://i.pravatar.cc/150?img=12',
      'isOnline': true,
    },
    {
      'name': 'Sophia',
      'imageUrl': 'https://i.pravatar.cc/150?img=5',
      'isOnline': false,
    },
    {
      'name': 'William',
      'imageUrl': 'https://i.pravatar.cc/150?img=13',
      'isOnline': true,
    },
    {
      'name': 'Henry',
      'imageUrl': 'https://i.pravatar.cc/150?img=14',
      'isOnline': false,
    },
  ];

  // Sample chat list
  final List<Map<String, dynamic>> _chats = [
    {
      'name': 'Charlotte',
      'message': 'Hey, mate please a...',
      'time': '29 Jun',
      'imageUrl': 'https://i.pravatar.cc/150?img=1',
      'hasUnread': true,
      'unreadCount': 3,
      'isOnline': true,
    },
    {
      'name': 'Arafat Khan',
      'message': 'https://www.linkedin.com/post/har...',
      'time': '28 Jun',
      'imageUrl': 'https://i.pravatar.cc/150?img=12',
      'hasUnread': false,
      'isOnline': true,
    },
    {
      'name': 'Ajoy Mondal',
      'message': 'https://behance.net/gallery/24584...',
      'time': '26 Jun',
      'imageUrl': 'https://i.pravatar.cc/150?img=13',
      'hasUnread': false,
      'isOnline': false,
    },
    {
      'name': 'Patricia',
      'message': 'https://dribbble.com/short/20185',
      'time': '24 Jun',
      'imageUrl': 'https://i.pravatar.cc/150?img=5',
      'hasUnread': false,
      'isOnline': false,
    },
    {
      'name': 'Isabella',
      'message': 'Isabella sent you a attachment',
      'time': '20 Jun',
      'imageUrl': 'https://i.pravatar.cc/150?img=9',
      'hasUnread': false,
      'isOnline': true,
    },
    {
      'name': 'John Mendala',
      'message': 'The audio call ended',
      'time': '20 Jun',
      'imageUrl': 'https://i.pravatar.cc/150?img=14',
      'hasUnread': false,
      'isOnline': false,
    },
  ];

  void _deleteChat(int index) {
    setState(() {
      _chats.removeAt(index);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Chat deleted',
          style: GoogleFonts.poppins(),
        ),
        backgroundColor: const Color(0xFFFF5722),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  void _reportChat(int index) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Chat reported',
          style: GoogleFonts.poppins(),
        ),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: Text(
          'MESSAGES',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
            letterSpacing: 1.5,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.black87),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: TextField(
                controller: _searchController,
                style: GoogleFonts.poppins(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Search messages...',
                  hintStyle: GoogleFonts.poppins(
                    color: Colors.grey[400],
                    fontSize: 14,
                  ),
                  prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),
          ),

          // Active Chats Shortcuts
          Container(
            color: Colors.white,
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Active Chats',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 90,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: _activeChats.length,
                    itemBuilder: (context, index) {
                      final chat = _activeChats[index];
                      return _buildActiveChatItem(
                        chat['name'],
                        chat['imageUrl'],
                        chat['isOnline'],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Chat List Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'All Messages',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                Text(
                  '${_chats.length} conversations',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),

          // Chat List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: _chats.length,
              itemBuilder: (context, index) {
                final chat = _chats[index];
                return _buildChatItem(
                  index,
                  chat['name'],
                  chat['message'],
                  chat['time'],
                  chat['imageUrl'],
                  hasUnread: chat['hasUnread'],
                  unreadCount: chat['unreadCount'] ?? 0,
                  isOnline: chat['isOnline'],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveChatItem(String name, String imageUrl, bool isOnline) {
    return GestureDetector(
      onTap: () {
        // Navigate to individual chat
        context.push('/chat/$name');
      },
      child: Container(
        width: 70,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          children: [
            Stack(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFFF5722),
                      width: 2,
                    ),
                  ),
                  child: ClipOval(
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[300],
                          child: const Icon(Icons.person, size: 30),
                        );
                      },
                    ),
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
            const SizedBox(height: 6),
            Text(
              name,
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatItem(
    int index,
    String name,
    String message,
    String time,
    String imageUrl, {
    bool hasUnread = false,
    int unreadCount = 0,
    bool isOnline = false,
  }) {
    return Dismissible(
      key: Key('chat_$index'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        return false; // Prevent auto-dismiss, we'll handle it manually
      },
      background: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.report, color: Colors.white, size: 24),
                const SizedBox(height: 4),
                Text(
                  'Report',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 20),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.delete, color: Colors.white, size: 24),
                const SizedBox(height: 4),
                Text(
                  'Delete',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      child: GestureDetector(
        onTap: () {
          // Navigate to individual chat
          context.push('/chat/$name');
        },
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Profile Image
              GestureDetector(
                onLongPress: () {
                  // Navigate to user profile on long press
                  context.push('/user/$name');
                },
                child: Stack(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: hasUnread
                              ? const Color(0xFFFF5722)
                              : Colors.grey[300]!,
                          width: 2,
                        ),
                      ),
                      child: ClipOval(
                        child: Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[300],
                              child: const Icon(Icons.person, size: 28),
                            );
                          },
                        ),
                      ),
                    ),
                    if (isOnline)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 16,
                          height: 16,
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
              
              // Chat Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          name,
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          time,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            message,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: hasUnread
                                  ? Colors.black87
                                  : Colors.grey[600],
                              fontWeight:
                                  hasUnread ? FontWeight.w500 : FontWeight.normal,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (hasUnread && unreadCount > 0)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF5722),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '$unreadCount',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
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
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
