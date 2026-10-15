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

        return Positioned(
          top: 24,
          right: 16,
          width: 300,
          child: Column(
            children: notifications.map((notification) {
              return _buildNotificationCard(
                context,
                notification,
                notificationService,
              );
            }).toList(),
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
    Color textColor;
    IconData icon;

    switch (notification.type) {
      case NotificationType.success:
        backgroundColor = Colors.green.shade50;
        textColor = Colors.green.shade900;
        icon = Icons.check_circle;
        break;
      case NotificationType.warning:
        backgroundColor = Colors.orange.shade50;
        textColor = Colors.orange.shade900;
        icon = Icons.warning;
        break;
      case NotificationType.error:
        backgroundColor = Colors.red.shade50;
        textColor = Colors.red.shade900;
        icon = Icons.error;
        break;
      default:
        backgroundColor = Colors.blue.shade50;
        textColor = Colors.blue.shade900;
        icon = Icons.info;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: backgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: textColor.withValues(alpha: 0.3), width: 1),
      ),
      child: InkWell(
        onTap: notification.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: textColor, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.message,
                      style: TextStyle(
                        fontSize: 14,
                        color: textColor.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.close,
                  color: textColor.withValues(alpha: 0.6),
                  size: 20,
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
    );
  }
}
