import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../services/notification_service.dart';

class NotificationIcon extends StatelessWidget {
  final bool isDark;

  const NotificationIcon({super.key, this.isDark = false});

  @override
  Widget build(BuildContext context) {
    final unreadCount = context.watch<NotificationService>().unreadCount;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          onPressed: () => context.push('/notifications'),
          icon: Icon(
            Icons.notifications_outlined,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        if (unreadCount > 0)
          Positioned(
            right: 8,
            top: 8,
            child: _PulsingDot(),
          ),
      ],
    );
  }
}

class _PulsingDot extends StatefulWidget {
  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot> {
  @override
  Widget build(BuildContext context) {
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
}
