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

    // Si es alerta de peligro, usamos colores rojos neón
    final isDanger =
        notification.title.toLowerCase().contains('peligrosa') ||
        notification.type == NotificationType.error;
    if (isDanger) {
      backgroundColor = Colors.black87;
      iconColor = Colors.redAccent;
    }

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.up,
      onDismissed: (direction) {
        notificationService.removeNotificationById(notification.id);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.9,
        ),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(
            40,
          ), // Estilo píldora (Isla Dinámica)
          boxShadow: [
            BoxShadow(
              color: isDanger
                  ? Colors.redAccent.withOpacity(0.3)
                  : Colors.black.withOpacity(0.2),
              blurRadius: 15,
              spreadRadius: 1,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(40),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () async {
                notificationService.removeNotificationById(notification.id);
                if (isDanger) {
                  final extra = notification.extra;
                  final alertId = extra?['id_alerta']?.toString();
                  if (alertId != null && alertId.isNotEmpty) {
                    try {
                      await AlertaService().markDangerousAlertRead(alertId);
                      notificationService.markDangerousAlertRead(alertId);
                    } catch (error) {
                      debugPrint(
                        'Error al marcar la alerta como leída: $error',
                      );
                    }
                  }
                  if (!context.mounted) return;
                  final navContext = navigatorKey.currentContext;
                  if (navContext == null) return;

                  final especie =
                      extra?['especie']?.toString() ?? 'Desconocida';
                  final latRaw = extra?['latitud'];
                  final lngRaw = extra?['longitud'];
                  final lat = latRaw is num
                      ? latRaw.toDouble()
                      : double.tryParse(latRaw?.toString() ?? '');
                  final lng = lngRaw is num
                      ? lngRaw.toDouble()
                      : double.tryParse(lngRaw?.toString() ?? '');
                  final hasCoords =
                      lat != null &&
                      lng != null &&
                      lat.isFinite &&
                      lng.isFinite &&
                      lat >= -90 &&
                      lat <= 90 &&
                      lng >= -180 &&
                      lng <= 180;

                  showModalBottomSheet(
                    context: navContext,
                    backgroundColor: Colors.transparent,
                    isScrollControlled: true,
                    builder: (ctx) => Container(
                      padding: const EdgeInsets.all(24),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(24),
                        ),
                      ),
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.warning_amber_rounded,
                                    color: Colors.red.shade700,
                                    size: 32,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Fauna Peligrosa Detectada',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.red.shade700,
                                        ),
                                      ),
                                      const Text(
                                        'Hay una especie peligrosa cerca de tu ubicacion',
                                        style: TextStyle(
                                          color: Colors.black54,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            const Divider(),
                            const SizedBox(height: 12),

                            // Especie
                            Row(
                              children: [
                                const Icon(
                                  Icons.pest_control,
                                  color: Colors.grey,
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                const Text(
                                  'Especie:',
                                  style: TextStyle(
                                    color: Colors.black54,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    especie,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            const Row(
                              children: [
                                Icon(
                                  Icons.location_on,
                                  color: Colors.grey,
                                  size: 20,
                                ),
                                SizedBox(width: 10),
                                Text(
                                  'Ubicación:',
                                  style: TextStyle(
                                    color: Colors.black54,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            if (hasCoords)
                              LocationPreviewMap(latitude: lat, longitude: lng)
                            else
                              Container(
                                width: double.infinity,
                                height: 120,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'Ubicación no disponible',
                                  style: TextStyle(color: Colors.black54),
                                ),
                              ),
                            const SizedBox(height: 8),

                            SizedBox(
                              width: double.infinity,
                              child: TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: const Text(
                                  'Cerrar',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, color: iconColor, size: 24),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            notification.title,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 0.3,
                            ),
                          ),
                          if (notification.message.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                notification.message,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white.withOpacity(0.8),
                                ),
                              ),
                            ),
                        ],
                      ),
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
