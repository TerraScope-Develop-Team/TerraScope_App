import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'map/location_preview_map.dart';
import '../services/alerta_service.dart';
import '../services/notification_service.dart';
import 'package:terrascope/main.dart' show navigatorKey;

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
    Color backgroundColor = Colors.black.withOpacity(0.9);
    Color iconColor;
    IconData icon;

    switch (notification.type) {
      case NotificationType.success:
        iconColor = Colors.greenAccent;
        icon = Icons.check_circle;
        break;
      case NotificationType.warning:
        iconColor = Colors.orangeAccent;
        icon = Icons.warning_rounded;
        break;
      case NotificationType.error:
        iconColor = Colors.redAccent;
        icon = Icons.error_rounded;
        break;
      default:
        iconColor = Colors.lightBlueAccent;
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
