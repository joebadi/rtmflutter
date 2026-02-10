import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';
import '../services/message_service.dart';
import '../config/api_config.dart';
import '../widgets/notification_icon.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final TextEditingController _searchController = TextEditingController();
  final MessageService _messageService = MessageService();
  final _storage = const FlutterSecureStorage();
  final Dio _dio = Dio();

  bool _isLoading = true;
  List<dynamic> _conversations = [];
  String? _error;
  String? _currentUserId;

  // Helper function to convert relative URLs to full URLs
  String _getFullPhotoUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    if (url.startsWith('http')) return url;
    return '${ApiConfig.socketUrl}$url';
  }

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _fetchCurrentUserId();
    _loadConversations();
  }

  Future<void> _fetchCurrentUserId() async {
    try {
      final token = await _storage.read(key: 'access_token');
      if (token == null) {
        debugPrint('[MessagesScreen] No access token found');
        return;
      }

      final response = await _dio.get(
        '${ApiConfig.baseUrl}/auth/me',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        final userId = response.data['user']?['id'];
        debugPrint('[MessagesScreen] Fetched userId: $userId');
        if (userId != null) {
          _currentUserId = userId.toString();
        }
      }
    } catch (e) {
      debugPrint('[MessagesScreen] Error fetching current user: $e');
    }
  }

  Future<void> _loadConversations() async {
    // Only show loading spinner if we don't have data yet
    if (_conversations.isEmpty) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    } else {
      // For silent refresh, just clear error
      setState(() {
        _error = null;
      });
    }

    try {
      final conversations = await _messageService.getConversations();
      setState(() {
        _conversations = conversations;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('[MessagesScreen] Error loading conversations: $e');
      if (_conversations.isEmpty) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      } else {
        // If we have data, just stop loading and keep the old data
        // Maybe show a snackbar in a real app, but for now just log it
        setState(() {
          _isLoading = false;
        });
      }


      if (mounted && e.toString().contains('UNAUTHORIZED')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Session expired. Please login again.'),
            backgroundColor: Colors.red,
          ),
        );
        context.go('/login');
      }
    }
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
          const NotificationIcon(),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black87),
            onPressed: _loadConversations,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFFF5722)),
            )
          : _error != null
              ? _buildErrorState()
              : _conversations.isEmpty
                  ? _buildEmptyState()
                  : _buildConversationsList(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 60, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'Failed to load messages',
            style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _loadConversations,
            child: const Text('Retry', style: TextStyle(color: Color(0xFFFF5722))),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 60, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No messages yet',
            style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Start matching to begin conversations!',
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationsList() {
    return Column(
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
                '${_conversations.length} conversations',
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
          child: RefreshIndicator(
            onRefresh: _loadConversations,
            color: const Color(0xFFFF5722),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: _conversations.length,
              itemBuilder: (context, index) {
                final conversation = _conversations[index];
                return _buildChatItem(conversation);
              },
            ),
          ),
        ),
      ],
    );
  }

  /// Determines if the last message was sent by the current user.
  /// Returns null if we can't determine (no message or no userId).
  bool? _isSentByMe(dynamic lastMessage) {
    if (lastMessage == null || _currentUserId == null) {
      debugPrint('[MessagesScreen] _isSentByMe: lastMessage=${lastMessage != null}, currentUserId=$_currentUserId');
      return null;
    }
    final senderId = lastMessage['senderId']?.toString();
    debugPrint('[MessagesScreen] _isSentByMe: senderId=$senderId, currentUserId=$_currentUserId, match=${senderId == _currentUserId}');
    return senderId == _currentUserId;
  }

  Widget _buildLastMessagePreview(
    dynamic lastMessage,
    String messageContent,
    bool hasUnread,
    String otherUserName,
  ) {
    final sentByMe = _isSentByMe(lastMessage);

    // Fallback: can't determine sender
    if (sentByMe == null) {
      return Text(
        messageContent,
        style: GoogleFonts.poppins(
          fontSize: 13,
          color: hasUnread ? Colors.black87 : Colors.grey[600],
          fontWeight: hasUnread ? FontWeight.w500 : FontWeight.normal,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    return Row(
      children: [
        // Sent/received icon
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: sentByMe
                ? Colors.grey[300]
                : const Color(0xFFFF5722).withOpacity(0.15),
          ),
          child: Icon(
            sentByMe ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
            size: 12,
            color: sentByMe ? Colors.grey[600] : const Color(0xFFFF5722),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: RichText(
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            text: TextSpan(
              children: [
                TextSpan(
                  text: sentByMe ? 'You: ' : '$otherUserName: ',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: sentByMe
                        ? Colors.grey[500]
                        : const Color(0xFFFF5722),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextSpan(
                  text: messageContent,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: hasUnread ? Colors.black87 : Colors.grey[600],
                    fontWeight: hasUnread ? FontWeight.w500 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChatItem(dynamic conversation) {
    // Extract data from conversation
    final participants = conversation['participants'] as List? ?? [];
    final otherParticipant = participants.isNotEmpty ? participants[0] : null;
    final otherUser = otherParticipant?['user'];
    final profile = otherUser?['profile'];
    final photos = profile?['photos'] as List? ?? [];
    final photoUrl = photos.isNotEmpty ? photos[0]['url'] : null;
    
    final firstName = profile?['firstName'] ?? 'User';
    final messages = conversation['messages'] as List? ?? [];
    final lastMessage = messages.isNotEmpty ? messages[0] : null;
    final lastMessageContent = lastMessage?['content'] ?? 'No messages yet';
    final lastMessageTime = lastMessage?['createdAt'] ?? '';
    final unreadCount = conversation['unreadCount'] ?? 0;
    final hasUnread = unreadCount > 0;
    final isOnline = otherUser?['isOnline'] ?? false;

    // Format time
    String formattedTime = '';
    if (lastMessageTime.isNotEmpty) {
      try {
        final dateTime = DateTime.parse(lastMessageTime);
        final now = DateTime.now();
        final difference = now.difference(dateTime);
        
        if (difference.inDays == 0) {
          formattedTime = '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
        } else if (difference.inDays == 1) {
          formattedTime = 'Yesterday';
        } else if (difference.inDays < 7) {
          formattedTime = '${difference.inDays}d ago';
        } else {
          formattedTime = '${dateTime.day}/${dateTime.month}';
        }
      } catch (e) {
        formattedTime = '';
      }
    }

    return GestureDetector(
      onTap: () async {
        // Navigate to chat screen
        // Navigate to chat screen and wait for result
        await context.push(
          '/chat/${conversation['id']}',
          extra: {
            'conversationId': conversation['id'],
            'receiverId': otherUser?['id'],
            'receiverName': firstName,
            'receiverPhoto': photoUrl,
          },
        );
        // Refresh conversations when returning from chat
        if (mounted) {
          _loadConversations();
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
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
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border(
              left: BorderSide(
                color: _isSentByMe(lastMessage) == false
                    ? const Color(0xFFFF5722)
                    : _isSentByMe(lastMessage) == true
                        ? Colors.grey[300]!
                        : Colors.transparent,
                width: 3,
              ),
            ),
          ),
        child: Row(
          children: [
            // Profile Image
            Stack(
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
                    child: photoUrl != null
                        ? Image.network(
                            _getFullPhotoUrl(photoUrl),
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                color: Colors.grey[200],
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Color(0xFFFF5722),
                                  ),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              debugPrint('[MessagesScreen] Avatar error: $error');
                              debugPrint('[MessagesScreen] Photo URL: ${_getFullPhotoUrl(photoUrl)}');
                              return Container(
                                color: Colors.grey[300],
                                child: const Icon(Icons.person, size: 28, color: Colors.grey),
                              );
                            },
                          )
                        : Container(
                            color: Colors.grey[300],
                            child: const Icon(Icons.person, size: 28, color: Colors.grey),
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
                        firstName,
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      if (formattedTime.isNotEmpty)
                        Text(
                          formattedTime,
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
                        child: _buildLastMessagePreview(
                          lastMessage,
                          lastMessageContent,
                          hasUnread,
                          firstName,
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
