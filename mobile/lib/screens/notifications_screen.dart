import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import '../config/api_config.dart';
import '../services/notification_service.dart';
import '../widgets/premium_loader.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _storage = const FlutterSecureStorage();
  final Dio _dio = Dio();

  bool _isLoading = true;
  List<dynamic> _allNotifications = [];
  String? _error;
  int _currentPage = 1;
  int _totalPages = 1;
  bool _isLoadingMore = false;

  // Personal notification types (user-to-user interactions)
  static const _personalTypes = {
    'NEW_LIKE',
    'MUTUAL_MATCH',
    'NEW_MESSAGE',
    'PROFILE_VIEW',
  };

  // Platform notification types (system notifications)
  static const _platformTypes = {
    'VERIFICATION_APPROVED',
    'VERIFICATION_REJECTED',
    'PREMIUM_EXPIRING',
    'SYSTEM_ANNOUNCEMENT',
    'GENERAL',
  };

  List<dynamic> get _personalNotifications => _allNotifications
      .where((n) => _personalTypes.contains(n['type']))
      .toList();

  List<dynamic> get _platformNotifications => _allNotifications
      .where((n) => _platformTypes.contains(n['type']))
      .toList();

  String _getFullPhotoUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    if (url.startsWith('http')) return url;
    return '${ApiConfig.socketUrl}$url';
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchNotifications();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchNotifications({bool loadMore = false}) async {
    if (loadMore) {
      if (_isLoadingMore || _currentPage >= _totalPages) return;
      setState(() => _isLoadingMore = true);
    } else {
      setState(() {
        _isLoading = true;
        _error = null;
        _currentPage = 1;
      });
    }

    try {
      final token = await _storage.read(key: 'access_token');
      if (token == null) {
        if (mounted) context.go('/login');
        return;
      }

      final page = loadMore ? _currentPage + 1 : 1;
      final response = await _dio.get(
        '${ApiConfig.baseUrl}/notifications?page=$page&limit=30',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        final notifications = response.data['notifications'] ?? [];
        final pagination = response.data['pagination'];

        setState(() {
          if (loadMore) {
            _allNotifications.addAll(notifications);
          } else {
            _allNotifications = List.from(notifications);
          }
          _currentPage = pagination?['page'] ?? 1;
          _totalPages = pagination?['totalPages'] ?? 1;
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
      setState(() {
        _error = 'Failed to load notifications';
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  Future<void> _markAllRead() async {
    try {
      await context.read<NotificationService>().markAllRead();
      setState(() {
        for (var i = 0; i < _allNotifications.length; i++) {
          _allNotifications[i] = {
            ..._allNotifications[i],
            'isRead': true,
          };
        }
      });
    } catch (e) {
      debugPrint('Error marking all read: $e');
    }
  }

  Future<void> _markAsRead(String notificationId) async {
    try {
      final token = await _storage.read(key: 'access_token');
      if (token == null) return;

      await _dio.patch(
        '${ApiConfig.baseUrl}/notifications/$notificationId/read',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      setState(() {
        final index =
            _allNotifications.indexWhere((n) => n['id'] == notificationId);
        if (index != -1) {
          _allNotifications[index] = {
            ..._allNotifications[index],
            'isRead': true,
          };
        }
      });

      // Update the unread count in the service
      context.read<NotificationService>().markAllRead();
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  int _calculateAge(String? dateOfBirth) {
    if (dateOfBirth == null) return 0;
    try {
      final dob = DateTime.parse(dateOfBirth);
      final now = DateTime.now();
      int age = now.year - dob.year;
      if (now.month < dob.month ||
          (now.month == dob.month && now.day < dob.day)) {
        age--;
      }
      return age;
    } catch (e) {
      return 0;
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('d MMM, yyyy').format(date);
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasUnread = _allNotifications.any((n) => n['isRead'] != true);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => context.pop(),
          child: Center(
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFF5722).withOpacity(0.1),
              ),
              child: const Icon(
                Icons.chevron_left,
                color: Color(0xFFFF5722),
                size: 26,
              ),
            ),
          ),
        ),
        title: Text(
          'NOTIFICATIONS',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
            letterSpacing: 1.5,
          ),
        ),
        centerTitle: true,
        actions: [
          if (hasUnread)
            TextButton(
              onPressed: _markAllRead,
              child: Text(
                'Read all',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: const Color(0xFFFF5722),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: const Color(0xFFFF5722).withOpacity(0.3),
            height: 1,
          ),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 12),
          // Tab bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(10),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(10),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.grey[600],
                labelStyle: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                unselectedLabelStyle: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                dividerColor: Colors.transparent,
                tabs: const [
                  Tab(text: 'Personal'),
                  Tab(text: 'Platform'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Tab content
          Expanded(
            child: _isLoading
                ? const Center(
                    child:
                        PremiumLoader(),
                  )
                : _error != null
                    ? _buildErrorState()
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          _buildNotificationList(_personalNotifications),
                          _buildNotificationList(_platformNotifications),
                        ],
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
          Icon(Icons.error_outline, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 12),
          Text(
            _error ?? 'Something went wrong',
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: _fetchNotifications,
            child: Text(
              'Retry',
              style: GoogleFonts.poppins(
                color: const Color(0xFFFF5722),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationList(List<dynamic> notifications) {
    if (notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_off_outlined,
                size: 48, color: Colors.grey[300]),
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
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchNotifications,
      color: const Color(0xFFFF5722),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          final notification = notifications[index];
          return _buildNotificationItem(notification);
        },
      ),
    );
  }

  Widget _buildNotificationItem(dynamic notification) {
    final isRead = notification['isRead'] == true;
    final type = notification['type'] ?? 'GENERAL';
    final createdAt = _formatDate(notification['createdAt']);
    final body = notification['body'] ?? notification['message'] ?? '';
    final title = notification['title'] ?? '';

    // Extract related user data
    final relatedUser = notification['relatedUser'];
    final profile = relatedUser?['profile'];
    final firstName = profile?['firstName'] ?? '';
    final lastName = profile?['lastName'] ?? '';
    final fullName = '$firstName $lastName'.trim();
    final dateOfBirth = profile?['dateOfBirth'];
    final age = _calculateAge(dateOfBirth);
    final photos = profile?['photos'] as List? ?? [];
    final photoUrl = photos.isNotEmpty ? photos[0]['url'] : null;

    final bool isPersonal = _personalTypes.contains(type);

    return GestureDetector(
      onTap: () {
        if (!isRead) {
          _markAsRead(notification['id']);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: isRead ? Colors.white : const Color(0xFFFF5722).withOpacity(0.04),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar or icon
            if (isPersonal && photoUrl != null)
              ClipOval(
                child: Image.network(
                  _getFullPhotoUrl(photoUrl),
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return _buildFallbackAvatar(type);
                  },
                ),
              )
            else
              _buildFallbackAvatar(type),
            const SizedBox(width: 12),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: RichText(
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          text: TextSpan(
                            children: [
                              if (isPersonal && fullName.isNotEmpty) ...[
                                TextSpan(
                                  text: fullName,
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                if (age > 0)
                                  TextSpan(
                                    text: ' $age',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w400,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                              ] else ...[
                                TextSpan(
                                  text: title,
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      if (createdAt.isNotEmpty)
                        Text(
                          createdAt,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isPersonal && fullName.isNotEmpty
                        ? _buildPersonalBody(fullName, type)
                        : body,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (!isRead)
              Padding(
                padding: const EdgeInsets.only(left: 8, top: 6),
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFFF5722),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _buildPersonalBody(String name, String type) {
    switch (type) {
      case 'NEW_LIKE':
        return '$name has liked your profile.';
      case 'MUTUAL_MATCH':
        return "You and $name are a match!";
      case 'NEW_MESSAGE':
        return '$name sent you a message.';
      case 'PROFILE_VIEW':
        return '$name viewed your profile.';
      default:
        return '';
    }
  }

  Widget _buildFallbackAvatar(String type) {
    IconData icon;
    Color color;

    switch (type) {
      case 'NEW_LIKE':
        icon = Icons.favorite;
        color = const Color(0xFFE91E63);
        break;
      case 'MUTUAL_MATCH':
        icon = Icons.favorite;
        color = const Color(0xFFFF5722);
        break;
      case 'NEW_MESSAGE':
        icon = Icons.chat_bubble;
        color = const Color(0xFF2196F3);
        break;
      case 'PROFILE_VIEW':
        icon = Icons.visibility;
        color = const Color(0xFF9C27B0);
        break;
      case 'VERIFICATION_APPROVED':
        icon = Icons.verified;
        color = Colors.green;
        break;
      case 'VERIFICATION_REJECTED':
        icon = Icons.cancel;
        color = Colors.red;
        break;
      case 'PREMIUM_EXPIRING':
        icon = Icons.star;
        color = Colors.amber;
        break;
      case 'SYSTEM_ANNOUNCEMENT':
        icon = Icons.campaign;
        color = const Color(0xFFFF5722);
        break;
      default:
        icon = Icons.notifications;
        color = Colors.grey;
    }

    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(0.1),
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }
}
