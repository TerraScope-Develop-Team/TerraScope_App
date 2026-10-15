import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/api_exception.dart';
import '../../services/notification_service.dart';

/// Utilidad centralizada para mostrar errores de red de forma consistente.
///
/// Convierte [ApiException] en mensajes amigables usando el
/// [NotificationService] de la app (banners) o como alternativa un [SnackBar].
class ErrorHandler {
  /// Muestra el error como un banner de notificacion.
  ///
  /// Usa el [NotificationService] obtenido del contexto para mantener
  /// el mismo estilo visual en toda la app.
  static void showError(BuildContext context, Object error) {
    final message = _extractMessage(error);

    try {
      final notificationService = Provider.of<NotificationService>(
        context,
        listen: false,
      );

      notificationService.showNotification(
        AppNotification(
          id: 'error_${DateTime.now().millisecondsSinceEpoch}',
          title: 'Error',
          message: message,
          type: NotificationType.error,
          duration: const Duration(seconds: 5),
        ),
      );
    } catch (_) {
      // Fallback a SnackBar si no se puede acceder al NotificationService
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  /// Muestra un mensaje de advertencia (warning) como notificacion.
  static void showWarning(BuildContext context, String message) {
    try {
      final notificationService = Provider.of<NotificationService>(
        context,
        listen: false,
      );

      notificationService.showNotification(
        AppNotification(
          id: 'warning_${DateTime.now().millisecondsSinceEpoch}',
          title: 'Atencion',
          message: message,
          type: NotificationType.warning,
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.orange.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// Extrae un mensaje amigable del error.
  static String _extractMessage(Object error) {
    if (error is ApiException) {
      return error.userFriendlyMessage;
    }
    if (error is Exception) {
      final msg = error.toString();
      // Limpiar el prefijo "Exception: " de Dart
      if (msg.startsWith('Exception: ')) {
        return msg.substring(11);
      }
      return msg;
    }
    return 'Ocurrio un error inesperado. Intenta de nuevo.';
  }
}
