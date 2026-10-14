import 'alerta_service.dart';
import 'notification_service.dart';

class DangerAlertPresenter {
  static Future<bool> present({
    required NotificationService notificationService,
    required Map<String, dynamic> alert,
    String? title,
    String? message,
  }) async {
    final alertId = alert['id']?.toString();
    if (alertId == null || alertId.isEmpty) {
      throw const FormatException(
        'La alerta de fauna no tiene un identificador',
      );
    }

    final shouldPresent = await AlertaService().markDangerousAlertShown(
      alertId,
    );
    if (!shouldPresent) return false;

    final especie = alert['especie']?.toString() ?? 'Desconocida';
    notificationService.showNotification(
      AppNotification(
        id: 'alerta_peligro_$alertId',
        title: title ?? '¡Alerta de Fauna Peligrosa!',
        message:
            message ??
            'Se ha reportado la especie $especie cerca de tu ubicación.',
        type: NotificationType.error,
        duration: const Duration(seconds: 10),
        extra: {
          ...alert,
          'id_alerta': alertId,
          'especie': especie,
          'latitud': alert['latitud'],
          'longitud': alert['longitud'],
        },
      ),
    );
    notificationService.registerUnreadDangerousAlert(alertId);
    return true;
  }
}
