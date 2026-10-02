import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/notification_service.dart';

class NotificationBanner extends StatelessWidget {
  const NotificationBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationService>(
      builder: (context, notificationService, child) {
        final notifications = notificationService.notifications;

        if (notifications.isEmpty) {
          return const SizedBox.shrink();
        }

        return SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: SizedBox(
                width: MediaQuery.of(context).size.width * 0.95,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: notifications.map((notification) {
                    return _buildNotificationCard(
                      context,
                      notification,
                      notificationService,
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNotificationCard(
    BuildContext context,
    AppNotification notification,
    NotificationService notificationService,
  ) {
    Color backgroundColor;
    Color iconColor;
    IconData icon;

    switch (notification.type) {
      case NotificationType.success:
        backgroundColor = const Color(0xFF1B5E20); // Dark Green
        iconColor = Colors.greenAccent;
        icon = Icons.check_circle_outline;
        break;
      case NotificationType.warning:
        backgroundColor = const Color(0xFFE65100); // Dark Orange
        iconColor = Colors.orangeAccent;
        icon = Icons.warning_amber_rounded;
        break;
      case NotificationType.error:
        backgroundColor = const Color(0xFFB71C1C); // Dark Red
        iconColor = Colors.redAccent;
        icon = Icons.error_outline;
        break;
      default:
        backgroundColor = const Color(0xFF0D47A1); // Dark Blue
        iconColor = Colors.lightBlueAccent;
        icon = Icons.info_outline;
    }

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.horizontal,
      onDismissed: (direction) {
        notificationService.removeNotificationById(notification.id);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: backgroundColor.withOpacity(0.95),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {},
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: iconColor, size: 28),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            notification.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            notification.message,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.9),
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.close,
                        color: Colors.white.withOpacity(0.7),
                        size: 22,
                      ),
                      onPressed: () {
                        notificationService.removeNotificationById(notification.id);
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
