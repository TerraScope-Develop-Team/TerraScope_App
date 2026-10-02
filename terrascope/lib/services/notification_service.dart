import 'dart:async';
import 'package:flutter/material.dart';

enum NotificationType { info, success, warning, error }

class AppNotification {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final Duration duration;
  // Datos adicionales opcionales (ej: para alertas de peligro)
  final Map<String, dynamic>? extra;

  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    this.type = NotificationType.info,
    this.duration = const Duration(seconds: 4),
    this.extra,
  });
}

class NotificationService with ChangeNotifier {
  final List<AppNotification> _notifications = [];
  final Set<String> _unreadDangerousAlertIds = {};

  List<AppNotification> get notifications => List.unmodifiable(_notifications);
  int get unreadDangerousAlertCount => _unreadDangerousAlertIds.length;

  void setUnreadDangerousAlerts(Iterable<String> alertIds) {
    _unreadDangerousAlertIds
      ..clear()
      ..addAll(alertIds);
    notifyListeners();
  }

  void registerUnreadDangerousAlert(String alertId) {
    if (_unreadDangerousAlertIds.add(alertId)) {
      notifyListeners();
    }
  }

  void markDangerousAlertRead(String alertId) {
    if (_unreadDangerousAlertIds.remove(alertId)) {
      notifyListeners();
    }
  }

  void showNotification(AppNotification notification) {
    _notifications.add(notification);
    notifyListeners();

    // Auto remove notification after its duration
    Timer(notification.duration, () {
      removeNotificationById(notification.id);
    });
  }

  void removeNotificationById(String id) {
    _notifications.removeWhere((n) => n.id == id);
    notifyListeners();
  }

  void clearAll() {
    _notifications.clear();
    notifyListeners();
  }
}
