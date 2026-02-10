import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../services/message_service.dart';
import '../services/like_service.dart';
import '../config/api_config.dart';
import 'package:provider/provider.dart';
import '../providers/message_provider.dart';

class ChatScreen extends StatefulWidget {
  final String conversationId;
  final String receiverId;
  final String receiverName;
  final String? receiverPhoto;

  const ChatScreen({
    super.key,
    required this.conversationId,
    required this.receiverId,
    required this.receiverName,
    this.receiverPhoto,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final MessageService _messageService = MessageService();

  bool _isLoading = true;
  bool _isSending = false;
  List<dynamic> _messages = [];
  String? _error;

  // Helper function to convert relative URLs to full URLs
  String _getFullPhotoUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    if (url.startsWith('http')) return url;
    return '${ApiConfig.socketUrl}$url';
  }

  @override
  void initState() {
    super.initState();
    debugPrint('[ChatScreen] Initialized with:');
    debugPrint('[ChatScreen] - conversationId: ${widget.conversationId}');
    debugPrint('[ChatScreen] - receiverId: ${widget.receiverId}');
    debugPrint('[ChatScreen] - receiverName: ${widget.receiverName}');
    debugPrint('[ChatScreen] - receiverPhoto: ${widget.receiverPhoto}');
    debugPrint('[ChatScreen] - receiverPhoto: ${widget.receiverPhoto}');
    _setupSocketListener();
    _loadMessages();
  }

  void _setupSocketListener() {
    final messageProvider = context.read<MessageProvider>();
    final socket = messageProvider.socket;

    if (socket != null && socket.connected) {
      debugPrint('[ChatScreen] Setting up socket listener');
      
      socket.on('new_message', (data) {
        if (!mounted) return;
        debugPrint('[ChatScreen] New message received via socket: $data');
        
        // check if this message belongs to the current conversation
        // The data structure might vary, check how backend emits it
        final conversationId = data['conversationId'];
        
        if (conversationId == widget.conversationId) {
          final message = data['message'];
          
          setState(() {
            // Add to list (at start since reversed)
            _messages.insert(0, message);
          });
          
          // Mark as read immediately since user is looking at it
          _messageService.markAsRead(message['id']);
        }
      });
    } else {
      debugPrint('[ChatScreen] Socket not connected, cannot listen for messages');
    }
  }

  Future<void> _loadMessages() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    debugPrint('[ChatScreen] Loading messages for conversation: ${widget.conversationId}');

    try {
      final messages = await _messageService.getMessages(widget.conversationId);
      debugPrint('[ChatScreen] Loaded ${messages.length} messages');
      
      setState(() {
        _messages = messages.reversed.toList(); // Reverse to show oldest first
        _isLoading = false;
      });

      // Mark conversation as read (only if conversation exists)
      try {
        await _messageService.markConversationAsRead(widget.conversationId);
      } catch (e) {
        // Ignore 404 errors for new conversations that don't exist yet
        debugPrint('[ChatScreen] Could not mark as read (conversation may not exist yet): $e');
      }

      // Scroll to bottom
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        }
      });
    } catch (e) {
      debugPrint('[ChatScreen] Error loading messages: $e');
      
      // If conversation doesn't exist yet (404), just show empty messages
      // This happens when starting a new chat with someone
      if (e.toString().contains('404') || e.toString().contains('not found')) {
        setState(() {
          _messages = [];
          _isLoading = false;
          _error = null; // Don't show error for new conversations
        });
      } else {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });

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
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _isSending) return;

    final content = _messageController.text.trim();
    _messageController.clear();

    setState(() => _isSending = true);

    debugPrint('[ChatScreen] Sending message to ${widget.receiverId}');

    try {
      await _messageService.sendMessage(
        receiverId: widget.receiverId,
        content: content,
      );

      debugPrint('[ChatScreen] Message sent successfully');

      // Reload messages from server to get the actual conversation
      await _loadMessages();

      setState(() => _isSending = false);
    } catch (e) {
      debugPrint('[ChatScreen] Error sending message: $e');
      setState(() => _isSending = false);
      
      // Handle match required error
      if (e.toString().contains('MATCH_REQUIRED')) {
        _showMatchRequiredDialog();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send message: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showMatchRequiredDialog() {
    final LikeService likeService = LikeService();
    bool isLiking = false;

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF5722).withOpacity(0.15),
                  blurRadius: 40,
                  offset: const Offset(0, 16),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top gradient accent bar
                Container(
                  height: 4,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFFF5722), Color(0xFFE91E63), Color(0xFFFF5722)],
                    ),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.fromLTRB(28, 32, 28, 28),
                  child: Column(
                    children: [
                      // Icon with animated ring
                      Container(
                        width: 88,
                        height: 88,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              const Color(0xFFFF5722).withOpacity(0.12),
                              const Color(0xFFE91E63).withOpacity(0.08),
                            ],
                          ),
                        ),
                        child: Container(
                          margin: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFFFF5722), Color(0xFFE91E63)],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFF5722).withOpacity(0.35),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.favorite_rounded,
                            color: Colors.white,
                            size: 36,
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Title
                      Text(
                        'Match to Continue',
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                          letterSpacing: -0.3,
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Description
                      RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey[600],
                            height: 1.5,
                          ),
                          children: [
                            const TextSpan(
                              text: 'You\'ve sent your icebreaker message! Like ',
                            ),
                            TextSpan(
                              text: widget.receiverName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Color(0xFFFF5722),
                              ),
                            ),
                            const TextSpan(
                              text: '\'s profile to match and unlock unlimited messaging.',
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Info pill
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.info_outline_rounded,
                                size: 16, color: Colors.grey[500]),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                'Both users get one free icebreaker message',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 28),

                      // Like Now button (primary CTA)
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFF5722), Color(0xFFE91E63)],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFF5722).withOpacity(0.35),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: isLiking
                                  ? null
                                  : () async {
                                      setDialogState(() => isLiking = true);
                                      try {
                                        final result = await likeService
                                            .sendLike(widget.receiverId);
                                        if (dialogContext.mounted) {
                                          Navigator.pop(dialogContext);
                                        }
                                        if (mounted) {
                                          final isMutual =
                                              result['isMutual'] == true;
                                          if (isMutual) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  "It's a Match! You can now chat freely.",
                                                  style: GoogleFonts.poppins(),
                                                ),
                                                backgroundColor: Colors.green,
                                              ),
                                            );
                                          } else {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  'You liked ${widget.receiverName}! Waiting for them to like you back.',
                                                  style: GoogleFonts.poppins(),
                                                ),
                                                backgroundColor:
                                                    const Color(0xFFFF5722),
                                              ),
                                            );
                                          }
                                        }
                                      } catch (e) {
                                        setDialogState(() => isLiking = false);
                                        if (mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                e.toString().contains(
                                                        'already liked')
                                                    ? 'You already liked this user. Waiting for them to match!'
                                                    : 'Could not send like',
                                                style: GoogleFonts.poppins(),
                                              ),
                                              backgroundColor:
                                                  e.toString().contains(
                                                          'already liked')
                                                      ? const Color(0xFFFF5722)
                                                      : Colors.red,
                                            ),
                                          );
                                          if (dialogContext.mounted) {
                                            Navigator.pop(dialogContext);
                                          }
                                        }
                                      }
                                    },
                              borderRadius: BorderRadius.circular(16),
                              child: Center(
                                child: isLiking
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.favorite_rounded,
                                              color: Colors.white, size: 20),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Like ${widget.receiverName}',
                                            style: GoogleFonts.poppins(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white,
                                              letterSpacing: 0.2,
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Dismiss button (secondary)
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: TextButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          style: TextButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            'Maybe Later',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[500],
                            ),
                          ),
                        ),
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => context.pop(),
        ),
        title: Row(
          children: [
            Stack(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFFF5722),
                      width: 2,
                    ),
                  ),
                  child: ClipOval(
                    child: widget.receiverPhoto != null && widget.receiverPhoto!.isNotEmpty
                        ? Image.network(
                            _getFullPhotoUrl(widget.receiverPhoto),
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                color: Colors.grey[200],
                                child: Center(
                                  child: CircularProgressIndicator(
                                    value: loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress.cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                        : null,
                                    strokeWidth: 2,
                                    color: const Color(0xFFFF5722),
                                  ),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              debugPrint('[ChatScreen] Header avatar error: $error');
                              debugPrint('[ChatScreen] Photo URL: ${_getFullPhotoUrl(widget.receiverPhoto)}');
                              return Container(
                                color: Colors.grey[300],
                                child: const Icon(Icons.person, size: 20, color: Colors.grey),
                              );
                            },
                          )
                        : Container(
                            color: Colors.grey[300],
                            child: const Icon(Icons.person, size: 20, color: Colors.grey),
                          ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.receiverName,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black87),
            onPressed: _loadMessages,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFFF5722)),
            )
          : _error != null
              ? _buildErrorState()
              : Column(
                  children: [
                    // Date Divider
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Today',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                    ),

                    // Messages List
                    Expanded(
                      child: _messages.isEmpty
                          ? Center(
                              child: Text(
                                'No messages yet. Say hi!',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Colors.grey[500],
                                ),
                              ),
                            )
                          : ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: _messages.length,
                              itemBuilder: (context, index) {
                                final message = _messages[index];
                                return _buildMessageBubble(message);
                              },
                            ),
                    ),

                    // Message Input - PREMIUM DESIGN
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 20,
                            offset: const Offset(0, -4),
                          ),
                        ],
                      ),
                      child: SafeArea(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(35),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 20,
                                offset: const Offset(0, 5),
                              ),
                              BoxShadow(
                                color: const Color(0xFFFF5722).withOpacity(0.08),
                                blurRadius: 10,
                                offset: const Offset(0, -2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              // Attachment Button
                              Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () {
                                    // Handle attachments (future feature)
                                  },
                                  borderRadius: BorderRadius.circular(50),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Icon(
                                      Icons.add_circle_outline_rounded,
                                      color: const Color(0xFFFF5722).withOpacity(0.8),
                                      size: 26,
                                    ),
                                  ),
                                ),
                              ),

                              // Text Input
                              Expanded(
                                child: TextField(
                                  controller: _messageController,
                                  style: GoogleFonts.poppins(
                                    fontSize: 15,
                                    color: Colors.black87,
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: 0.2,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'Type a message...',
                                    hintStyle: GoogleFonts.poppins(
                                      color: Colors.grey[400],
                                      fontSize: 15,
                                      fontWeight: FontWeight.w400,
                                    ),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 12,
                                    ),
                                    isDense: true,
                                  ),
                                  maxLines: null,
                                  textCapitalization: TextCapitalization.sentences,
                                  onSubmitted: (_) => _sendMessage(),
                                ),
                              ),

                              // Send Button
                              Container(
                                margin: const EdgeInsets.all(4),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: _isSending ? null : _sendMessage,
                                    borderRadius: BorderRadius.circular(50),
                                    child: Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        gradient: _isSending
                                            ? null
                                            : const LinearGradient(
                                                colors: [
                                                  Color(0xFFFF5722),
                                                  Color(0xFFFF8A65)
                                                ],
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                              ),
                                        color: _isSending ? Colors.grey[200] : null,
                                        shape: BoxShape.circle,
                                        boxShadow: _isSending
                                            ? null
                                            : [
                                                BoxShadow(
                                                  color: const Color(0xFFFF5722).withOpacity(0.3),
                                                  blurRadius: 8,
                                                  offset: const Offset(0, 4),
                                                ),
                                              ],
                                      ),
                                      child: _isSending
                                          ? const Padding(
                                              padding: EdgeInsets.all(12),
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.grey,
                                              ),
                                            )
                                          : Transform.translate(
                                              offset: const Offset(1, 0),
                                              child: const Icon(
                                                Icons.send_rounded,
                                                color: Colors.white,
                                                size: 20,
                                              ),
                                            ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
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
            onPressed: _loadMessages,
            child: const Text('Retry', style: TextStyle(color: Color(0xFFFF5722))),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(dynamic message) {
    final isSent = message['senderId'] != widget.receiverId;
    final content = message['content'] ?? '';
    final createdAt = message['createdAt'] ?? '';
    
    // Get sender info from message
    final sender = message['sender'];
    final senderPhoto = sender?['profile']?['photos']?.isNotEmpty == true
        ? sender['profile']['photos'][0]['url']
        : null;

    // Format time
    String formattedTime = '';
    if (createdAt.isNotEmpty) {
      try {
        final dateTime = DateTime.parse(createdAt);
        formattedTime = '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
      } catch (e) {
        formattedTime = '';
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: isSent
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Receiver's photo (for received messages)
          if (!isSent) ...[
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFFF5722),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF5722).withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipOval(
                child: widget.receiverPhoto != null && widget.receiverPhoto!.isNotEmpty
                    ? Image.network(
                        _getFullPhotoUrl(widget.receiverPhoto),
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            color: Colors.grey[200],
                            child: const Center(
                              child: SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFFFF5722),
                                ),
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          debugPrint('[ChatScreen] Receiver bubble avatar error: $error');
                          return Container(
                            color: Colors.grey[300],
                            child: const Icon(Icons.person, size: 18, color: Colors.grey),
                          );
                        },
                      )
                    : Container(
                        color: Colors.grey[300],
                        child: const Icon(Icons.person, size: 18, color: Colors.grey),
                      ),
              ),
            ),
            const SizedBox(width: 10),
          ],

          // Message Bubble
          Flexible(
            child: Column(
              crossAxisAlignment: isSent
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    gradient: isSent
                        ? const LinearGradient(
                            colors: [Color(0xFFFF5722), Color(0xFFFF7043)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: isSent ? null : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(20),
                      topRight: const Radius.circular(20),
                      bottomLeft: Radius.circular(isSent ? 20 : 4),
                      bottomRight: Radius.circular(isSent ? 4 : 20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isSent
                            ? const Color(0xFFFF5722).withOpacity(0.3)
                            : Colors.black.withOpacity(0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Text(
                    content,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      color: isSent ? Colors.white : Colors.black87,
                      height: 1.5,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
                if (formattedTime.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    formattedTime,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: Colors.grey[500],
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Sender's photo (for sent messages)
          if (isSent) ...[
            const SizedBox(width: 10),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFFF5722),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF5722).withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipOval(
                child: senderPhoto != null && senderPhoto.isNotEmpty
                    ? Image.network(
                        _getFullPhotoUrl(senderPhoto),
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            color: Colors.grey[200],
                            child: const Center(
                              child: SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFFFF5722),
                                ),
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          debugPrint('[ChatScreen] Sender bubble avatar error: $error');
                          debugPrint('[ChatScreen] Sender photo URL: $senderPhoto');
                          return Container(
                            color: Colors.grey[300],
                            child: const Icon(Icons.person, size: 18, color: Colors.grey),
                          );
                        },
                      )
                    : Container(
                        color: Colors.grey[300],
                        child: const Icon(Icons.person, size: 18, color: Colors.grey),
                      ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  void dispose() {
    // Remove listener to prevent memory leaks or unwanted updates
    final messageProvider = context.read<MessageProvider>();
    final socket = messageProvider.socket;
    socket?.off('new_message');
    
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
