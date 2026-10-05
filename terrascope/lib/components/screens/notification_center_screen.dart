import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../map/location_preview_map.dart';
import '../../services/alerta_service.dart';
import '../../services/notification_service.dart';

class NotificationCenterScreen extends StatefulWidget {
  const NotificationCenterScreen({super.key});

  @override
  State<NotificationCenterScreen> createState() =>
      _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends State<NotificationCenterScreen> {
  final AlertaService _alertaService = AlertaService();
  List<Map<String, dynamic>> _alerts = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAlerts();
  }

  Future<void> _loadAlerts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final alerts = await _alertaService.getDangerousAlerts();
      if (!mounted) return;
      context.read<NotificationService>().setUnreadDangerousAlerts(
        alerts
            .where((alert) => alert['leida'] != true)
            .map((alert) => alert['id']?.toString())
            .whereType<String>(),
      );
      setState(() {
        _alerts = alerts;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = 'No se pudieron cargar las notificaciones: $error';
        _isLoading = false;
      });
    }
  }

  Future<void> _openAlert(Map<String, dynamic> alert) async {
    final alertId = alert['id']?.toString();
    if (alertId == null || alertId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Esta notificación no tiene un identificador válido.'),
        ),
      );
      return;
    }

    try {
      await _alertaService.markDangerousAlertRead(alertId);
      if (!mounted) return;
      context.read<NotificationService>().markDangerousAlertRead(alertId);
      setState(() {
        _alerts = _alerts.map((item) {
          if (item['id'] == alertId) return {...item, 'leida': true};
          return item;
        }).toList();
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo actualizar la notificación: $error'),
        ),
      );
      return;
    }

    final latitude = _coordinate(alert['latitud']);
    final longitude = _coordinate(alert['longitud']);
    final hasCoords =
        latitude != null &&
        longitude != null &&
        latitude >= -90 &&
        latitude <= 90 &&
        longitude >= -180 &&
        longitude <= 180;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.red.shade700,
                      size: 32,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        alert['especie']?.toString() ?? 'Fauna peligrosa',
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Text(
                  'Ubicación',
                  style: TextStyle(color: Colors.black54, fontSize: 14),
                ),
                const SizedBox(height: 10),
                if (hasCoords)
                  LocationPreviewMap(latitude: latitude, longitude: longitude)
                else
                  Container(
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
                const SizedBox(height: 12),
                Text(
                  _formatDate(alert['createdAt']),
                  style: const TextStyle(color: Colors.black54, fontSize: 13),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cerrar'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  double? _coordinate(dynamic value) {
    final result = value is num
        ? value.toDouble()
        : double.tryParse(value?.toString() ?? '');
    return result != null && result.isFinite ? result : null;
  }

  String _formatDate(dynamic value) {
    final date = DateTime.tryParse(value?.toString() ?? '')?.toLocal();
    if (date == null) return 'Fecha no disponible';
    final datePart =
        '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    final timePart =
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    return '$datePart · $timePart';
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _alerts.where((alert) => alert['leida'] != true).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Centro de notificaciones'),
        actions: [
          if (unreadCount > 0)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  '$unreadCount sin leer',
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_error!, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: _loadAlerts,
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            )
          : _alerts.isEmpty
          ? const Center(child: Text('Todavía no tienes notificaciones.'))
          : RefreshIndicator(
              onRefresh: _loadAlerts,
              child: ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: _alerts.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final alert = _alerts[index];
                  final isUnread = alert['leida'] != true;
                  return ListTile(
                    leading: Icon(
                      isUnread
                          ? Icons.notifications_active
                          : Icons.notifications_none,
                      color: isUnread ? Colors.red.shade700 : Colors.grey,
                    ),
                    title: Text(
                      alert['especie']?.toString() ?? 'Fauna peligrosa',
                      style: TextStyle(
                        fontWeight: isUnread
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    subtitle: Text(_formatDate(alert['createdAt'])),
                    trailing: isUnread
                        ? Icon(
                            Icons.circle,
                            size: 10,
                            color: Colors.red.shade700,
                          )
                        : null,
                    onTap: () => _openAlert(alert),
                  );
                },
              ),
            ),
    );
  }
}
