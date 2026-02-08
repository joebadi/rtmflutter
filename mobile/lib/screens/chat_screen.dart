import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../services/message_service.dart';

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

  @override
  void initState() {
    super.initState();
    debugPrint('[ChatScreen] Initialized with:');
    debugPrint('[ChatScreen] - conversationId: ${widget.conversationId}');
    debugPrint('[ChatScreen] - receiverId: ${widget.receiverId}');
    debugPrint('[ChatScreen] - receiverName: ${widget.receiverName}');
    debugPrint('[ChatScreen] - receiverPhoto: ${widget.receiverPhoto}');
    _loadMessages();
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

      // Mark conversation as read
      await _messageService.markConversationAsRead(widget.conversationId);

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
      final message = await _messageService.sendMessage(
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.favorite, color: Color(0xFFFF5722), size: 24),
            SizedBox(width: 8),
            Text(
              'Match Required',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        content: Text(
          'You\'ve sent your intro message! To continue chatting, you need to match with ${widget.receiverName}.',
          style: GoogleFonts.poppins(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'OK',
              style: GoogleFonts.poppins(color: Colors.grey[600]),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigate back to profile to like
              context.pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFFF5722),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'View Profile',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
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
                            widget.receiverPhoto!,
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
                              debugPrint('[ChatScreen] Photo URL: ${widget.receiverPhoto}');
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
                        child: Row(
                          children: [
                            // Text Input - Enhanced Design with BETTER VISIBILITY
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(28),
                                  border: Border.all(
                                    color: const Color(0xFFFF5722).withOpacity(0.5), // Darker border
                                    width: 2, // Thicker border
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFFF5722).withOpacity(0.15),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: TextField(
                                  controller: _messageController,
                                  style: GoogleFonts.poppins(
                                    fontSize: 15,
                                    color: Colors.black87,
                                    fontWeight: FontWeight.w500, // Bolder text
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'Type a message...',
                                    hintStyle: GoogleFonts.poppins(
                                      color: Colors.grey[600], // Darker hint text
                                      fontSize: 15,
                                      fontWeight: FontWeight.w400,
                                    ),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 14,
                                    ),
                                  ),
                                  maxLines: null,
                                  textCapitalization: TextCapitalization.sentences,
                                  onSubmitted: (_) => _sendMessage(),
                                ),
                              ),
                            ),

                            const SizedBox(width: 12),

                            // Send Button - Enhanced Design
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                gradient: _isSending
                                    ? null
                                    : const LinearGradient(
                                        colors: [Color(0xFFFF5722), Color(0xFFFF7043)],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                color: _isSending ? Colors.grey[300] : null,
                                shape: BoxShape.circle,
                                boxShadow: _isSending
                                    ? null
                                    : [
                                        BoxShadow(
                                          color: const Color(0xFFFF5722).withOpacity(0.4),
                                          blurRadius: 12,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                              ),
                              child: _isSending
                                  ? const Padding(
                                      padding: EdgeInsets.all(14),
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2.5,
                                      ),
                                    )
                                  : IconButton(
                                      icon: const Icon(
                                        Icons.send_rounded,
                                        color: Colors.white,
                                        size: 22,
                                      ),
                                      onPressed: _sendMessage,
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
                        widget.receiverPhoto!,
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
                        senderPhoto,
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
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
