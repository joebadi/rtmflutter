import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../services/notification_service.dart';

class NotificationIcon extends StatelessWidget {
  final bool isDark;

  const NotificationIcon({super.key, this.isDark = false});

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationService>(
      builder: (context, notificationService, child) {
        final count = notificationService.unreadCount;

        return Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            IconButton(
              onPressed: () => context.push('/notifications'),
              icon: Icon(
                count > 0
                    ? Icons.notifications_active_rounded
                    : Icons.notifications_outlined,
                color: isDark ? Colors.white : Colors.black87,
                size: 26,
              ),
            ),
            if (count > 0)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF5722),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark ? Colors.black : Colors.white,
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF5722).withOpacity(0.4),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 18,
                    minHeight: 18,
                  ),
                  child: Center(
                    child: Text(
                      count > 9 ? '9+' : '$count',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        height: 1,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
