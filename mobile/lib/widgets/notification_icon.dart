import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/notification_service.dart';
import '../config/api_config.dart';
import 'package:timeago/timeago.dart' as timeago;

class NotificationIcon extends StatefulWidget {
  final bool isDark;

  const NotificationIcon({super.key, this.isDark = false});

  @override
  State<NotificationIcon> createState() => _NotificationIconState();
}

class _NotificationIconState extends State<NotificationIcon> {
  final _storage = const FlutterSecureStorage();
  final Dio _dio = Dio();
  List<dynamic> _notifications = [];
  bool _isLoading = false;
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();

  Future<void> _fetchNotifications() async {
    setState(() => _isLoading = true);
    try {
      final token = await _storage.read(key: 'access_token');
      if (token == null) return;

      final response = await _dio.get(
        '${ApiConfig.baseUrl}/notifications',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        setState(() {
          _notifications = response.data['notifications'] ?? [];
        });
      }
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _toggleNotificationDropdown() {
    if (_overlayEntry != null) {
      _closeDropdown();
    } else {
      _showDropdown();
    }
  }

  void _showDropdown() {
    _fetchNotifications();

    _overlayEntry = OverlayEntry(
      builder: (context) => GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: _closeDropdown,
        child: Stack(
          children: [
            Positioned(
              width: 360,
              child: CompositedTransformFollower(
                link: _layerLink,
                targetAnchor: Alignment.bottomRight,
                followerAnchor: Alignment.topRight,
                offset: const Offset(0, 8),
                child: Material(
                  elevation: 8,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    constraints: const BoxConstraints(maxHeight: 500),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Header
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(color: Colors.grey[200]!),
                            ),
                          ),
                          child: Row(
                            children: [
                              Text(
                                'Notifications',
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const Spacer(),
                              if (_notifications.isNotEmpty)
                                TextButton(
                                  onPressed: () async {
                                    await context
                                        .read<NotificationService>()
                                        .markAllRead();
                                    _fetchNotifications();
                                  },
                                  child: Text(
                                    'Mark all read',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: const Color(0xFFFF5722),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),

                        // Notifications list
                        Flexible(
                          child: _isLoading
                              ? const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(32.0),
                                    child: CircularProgressIndicator(
                                      color: Color(0xFFFF5722),
                                    ),
                                  ),
                                )
                              : _notifications.isEmpty
                                  ? Center(
                                      child: Padding(
                                        padding: const EdgeInsets.all(32.0),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.notifications_off_outlined,
                                              size: 48,
                                              color: Colors.grey[300],
                                            ),
                                            const SizedBox(height: 12),
                                            Text(
                                              'No notifications yet',
                                              style: GoogleFonts.poppins(
                                                fontSize: 14,
                                                color: Colors.grey[500],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    )
                                  : ListView.builder(
                                      shrinkWrap: true,
                                      padding: EdgeInsets.zero,
                                      itemCount: _notifications.length,
                                      itemBuilder: (context, index) {
                                        final notification =
                                            _notifications[index];
                                        return _buildNotificationItem(
                                            notification);
                                      },
                                    ),
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
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _closeDropdown() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  Widget _buildNotificationItem(dynamic notification) {
    final isRead = notification['isRead'] == true;
    final type = notification['type'] ?? 'GENERAL';
    final createdAt = notification['createdAt'];
    String timeAgo = '';

    if (createdAt != null) {
      try {
        final dateTime = DateTime.parse(createdAt);
        timeAgo = timeago.format(dateTime);
      } catch (e) {
        timeAgo = '';
      }
    }

    IconData icon;
    Color iconColor;

    switch (type) {
      case 'NEW_LIKE':
        icon = Icons.favorite;
        iconColor = const Color(0xFFE91E63);
        break;
      case 'MUTUAL_MATCH':
        icon = Icons.favorite;
        iconColor = const Color(0xFFFF5722);
        break;
      case 'NEW_MESSAGE':
        icon = Icons.chat_bubble;
        iconColor = const Color(0xFF2196F3);
        break;
      default:
        icon = Icons.notifications;
        iconColor = Colors.grey;
    }

    return Container(
      decoration: BoxDecoration(
        color: isRead ? Colors.white : const Color(0xFFFF5722).withOpacity(0.05),
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: iconColor.withOpacity(0.1),
          ),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        title: Text(
          notification['title'] ?? '',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: isRead ? FontWeight.w500 : FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              notification['message'] ?? '',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (timeAgo.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                timeAgo,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ],
        ),
        trailing: !isRead
            ? Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFFF5722),
                ),
              )
            : null,
      ),
    );
  }

  Widget _buildPulsingDot() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 1000),
      builder: (context, value, child) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.red,
            boxShadow: [
              BoxShadow(
                color: Colors.red.withOpacity(0.6 * value),
                blurRadius: 6 * value,
                spreadRadius: 2 * value,
              ),
            ],
          ),
        );
      },
      onEnd: () {
        if (mounted) {
          setState(() {}); // Restart animation
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = context.watch<NotificationService>().unreadCount;

    return CompositedTransformTarget(
      link: _layerLink,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          IconButton(
            onPressed: _toggleNotificationDropdown,
            icon: Icon(
              Icons.notifications_outlined,
              color: widget.isDark ? Colors.white : Colors.black87,
            ),
          ),
          if (unreadCount > 0)
            Positioned(
              right: 8,
              top: 8,
              child: _buildPulsingDot(),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _closeDropdown();
    super.dispose();
  }
}
