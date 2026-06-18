import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/message_service.dart';
import '../config/api_config.dart';
import '../config/theme.dart';
import '../widgets/notification_icon.dart';
import '../widgets/premium_loader.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final TextEditingController _searchController = TextEditingController();
  final MessageService _messageService = MessageService();
  final _storage = const FlutterSecureStorage();

  bool _isLoading = true;
  List<dynamic> _conversations = [];
  String? _error;
  String? _currentUserId;
  String _query = '';

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

      // Decode JWT payload locally to extract userId (no API call needed)
      final parts = token.split('.');
      if (parts.length != 3) {
        debugPrint('[MessagesScreen] Invalid JWT format');
        return;
      }

      // JWT payload is base64url encoded
      String payload = parts[1];
      // Add padding if needed
      switch (payload.length % 4) {
        case 2:
          payload += '==';
          break;
        case 3:
          payload += '=';
          break;
      }
      final decoded = utf8.decode(base64Url.decode(payload));
      final Map<String, dynamic> data = json.decode(decoded);
      final userId = data['userId']?.toString();
      debugPrint('[MessagesScreen] Decoded userId from JWT: $userId');
      if (userId != null) {
        _currentUserId = userId;
      }
    } catch (e) {
      debugPrint('[MessagesScreen] Error decoding JWT: $e');
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

  // Name of the other participant, for search.
  String _otherName(dynamic conversation) {
    final participants = conversation['participants'] as List? ?? [];
    final other = participants.isNotEmpty ? participants[0] : null;
    return (other?['user']?['profile']?['firstName'] ?? 'User').toString();
  }

  List<dynamic> get _filtered {
    if (_query.trim().isEmpty) return _conversations;
    final q = _query.toLowerCase();
    return _conversations.where((c) {
      final name = _otherName(c).toLowerCase();
      final messages = c['messages'] as List? ?? [];
      final last = (messages.isNotEmpty ? messages[0]['content'] : '')
          ?.toString()
          .toLowerCase() ?? '';
      return name.contains(q) || last.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg(context),
      body: SafeArea(
        child: Column(
          children: [
            _header(),
            Expanded(
              child: _isLoading
                  ? const Center(child: PremiumLoader())
                  : _error != null
                      ? _buildErrorState()
                      : _conversations.isEmpty
                          ? _buildEmptyState()
                          : _buildConversationsList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Messages',
                    style: GoogleFonts.poppins(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary(context))),
                const SizedBox(height: 2),
                Text(
                  _conversations.isEmpty
                      ? 'Your conversations'
                      : '${_conversations.length} conversation${_conversations.length > 1 ? 's' : ''}',
                  style: GoogleFonts.poppins(
                      fontSize: 13, color: AppTheme.textSecondary(context)),
                ),
              ],
            ),
          ),
          NotificationIcon(isDark: !AppTheme.isLight(context)),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cloud_off_rounded,
              size: 44, color: AppTheme.fg(context, 0.4)),
          const SizedBox(height: 14),
          Text('Failed to load messages',
              style: GoogleFonts.poppins(color: AppTheme.textSecondary(context), fontSize: 14)),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _loadConversations,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.accent.withOpacity(0.15),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.accent.withOpacity(0.4)),
              ),
              child: Text('Retry',
                  style: GoogleFonts.poppins(
                      color: AppTheme.accent,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: AppTheme.accent.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.forum_rounded,
                  size: 46, color: AppTheme.accent.withOpacity(0.85)),
            ),
            const SizedBox(height: 18),
            Text('No messages yet',
                style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary(context))),
            const SizedBox(height: 8),
            Text('Match with someone to start a conversation.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    color: AppTheme.fg(context, 0.5),
                    height: 1.45)),
            const SizedBox(height: 22),
            GestureDetector(
              onTap: () => context.go('/matches'),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
                decoration: BoxDecoration(
                  gradient: AppTheme.accentGradient,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text('See your matches',
                    style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConversationsList() {
    final list = _filtered;
    return Column(
      children: [
        // Search Bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.surface(context),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.hairline(context)),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _query = v),
              cursorColor: AppTheme.accent,
              style: GoogleFonts.poppins(
                  fontSize: 14, color: AppTheme.textPrimary(context)),
              decoration: InputDecoration(
                hintText: 'Search conversations…',
                hintStyle:
                    GoogleFonts.poppins(color: AppTheme.textFaint(context), fontSize: 14),
                prefixIcon:
                    const Icon(Icons.search_rounded, color: AppTheme.accent),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        icon: Icon(Icons.close_rounded,
                            color: AppTheme.textFaint(context), size: 20),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                      ),
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadConversations,
            color: AppTheme.accent,
            backgroundColor: AppTheme.surface(context),
            child: list.isEmpty
                ? ListView(
                    children: [
                      const SizedBox(height: 80),
                      Center(
                        child: Text('No matches for "$_query"',
                            style: GoogleFonts.poppins(
                                color: AppTheme.textFaint(context), fontSize: 13)),
                      ),
                    ],
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 2, 16, 100),
                    itemCount: list.length,
                    itemBuilder: (context, index) =>
                        _buildChatItem(list[index]),
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
    final contentColor =
        hasUnread ? AppTheme.textPrimary(context) : AppTheme.fg(context, 0.5);

    if (sentByMe == null) {
      return Text(
        messageContent,
        style: GoogleFonts.poppins(
          fontSize: 13,
          color: contentColor,
          fontWeight: hasUnread ? FontWeight.w500 : FontWeight.normal,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    return Row(
      children: [
        Icon(
          sentByMe ? Icons.subdirectory_arrow_right_rounded : Icons.south_west_rounded,
          size: 13,
          color: sentByMe ? AppTheme.textFaint(context) : AppTheme.accent,
        ),
        const SizedBox(width: 5),
        Expanded(
          child: RichText(
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            text: TextSpan(
              children: [
                TextSpan(
                  text: sentByMe ? 'You: ' : '',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: AppTheme.textFaint(context),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextSpan(
                  text: messageContent,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: contentColor,
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

    String formattedTime = '';
    if (lastMessageTime.toString().isNotEmpty) {
      try {
        final dateTime = DateTime.parse(lastMessageTime.toString()).toLocal();
        final now = DateTime.now();
        final difference = now.difference(dateTime);
        if (difference.inDays == 0) {
          formattedTime =
              '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
        } else if (difference.inDays == 1) {
          formattedTime = 'Yesterday';
        } else if (difference.inDays < 7) {
          formattedTime = '${difference.inDays}d';
        } else {
          formattedTime = '${dateTime.day}/${dateTime.month}';
        }
      } catch (_) {
        formattedTime = '';
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () async {
            await context.push(
              '/chat/${conversation['id']}',
              extra: {
                'conversationId': conversation['id'],
                'receiverId': otherUser?['id'],
                'receiverName': firstName,
                'receiverPhoto': photoUrl,
              },
            );
            if (mounted) _loadConversations();
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: hasUnread
                  ? AppTheme.accent.withOpacity(0.10)
                  : AppTheme.surface(context),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: hasUnread
                    ? AppTheme.accent.withOpacity(0.4)
                    : AppTheme.hairline(context),
              ),
            ),
            child: Row(
              children: [
                // Avatar
                Stack(
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: hasUnread
                              ? AppTheme.accent
                              : AppTheme.hairline(context),
                          width: 2,
                        ),
                      ),
                      child: ClipOval(
                        child: photoUrl != null
                            ? Image.network(
                                _getFullPhotoUrl(photoUrl),
                                fit: BoxFit.cover,
                                loadingBuilder: (context, child, progress) =>
                                    progress == null
                                        ? child
                                        : Container(
                                            color: AppTheme.surface2(context),
                                            child: const Center(
                                              child: PremiumLoader(
                                                  strokeWidth: 2,
                                                  color: AppTheme.accent),
                                            ),
                                          ),
                                errorBuilder: (_, __, ___) => Container(
                                  color: AppTheme.surface2(context),
                                  child: Icon(Icons.person,
                                      size: 26, color: AppTheme.textFaint(context)),
                                ),
                              )
                            : Container(
                                color: AppTheme.surface2(context),
                                child: Icon(Icons.person,
                                    size: 26, color: AppTheme.textFaint(context)),
                              ),
                      ),
                    ),
                    if (isOnline)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 15,
                          height: 15,
                          decoration: BoxDecoration(
                            color: const Color(0xFF4CAF50),
                            shape: BoxShape.circle,
                            border:
                                Border.all(color: AppTheme.bg(context), width: 2.5),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              firstName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: hasUnread
                                    ? FontWeight.w700
                                    : FontWeight.w600,
                                color: AppTheme.textPrimary(context),
                              ),
                            ),
                          ),
                          if (formattedTime.isNotEmpty)
                            Text(
                              formattedTime,
                              style: GoogleFonts.poppins(
                                fontSize: 11.5,
                                fontWeight: hasUnread
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                color: hasUnread
                                    ? AppTheme.accentBright
                                    : AppTheme.textFaint(context),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 5),
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
                          if (hasUnread)
                            Container(
                              margin: const EdgeInsets.only(left: 8),
                              constraints: const BoxConstraints(minWidth: 20),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                gradient: AppTheme.accentGradient,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '$unreadCount',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
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
      ),
    );
  }


  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
