import 'dart:convert';
import 'package:terrascope/config/api_config.dart';
import 'package:terrascope/services/api_client.dart' as auth_http;

class AlertaService {
  final String _baseUrl = '${ApiConfig.baseUrl}/alertas';

  /// Enviar una señal de SOS con ubicación actual
  Future<bool> sendSOS(double latitud, double longitud) async {
    try {
      final response = await auth_http.post(
        Uri.parse('$_baseUrl/sos'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'latitud': latitud, 'longitud': longitud}),
      );

      if (response.statusCode == 201) {
        return true;
      }
      return false;
    } catch (e) {
      print('Error al enviar SOS: $e');
      return false;
    }
  }

  /// Obtener notificaciones de fauna peligrosa para el usuario
  Future<List<Map<String, dynamic>>> getDangerousAlerts() async {
    final response = await auth_http.get(Uri.parse('$_baseUrl/peligro'));

    if (response.statusCode != 200) {
      throw Exception('Error al obtener alertas: ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final alertas = decoded['alertas'];
    if (alertas is! List) {
      throw const FormatException(
        'La respuesta de alertas no contiene una lista',
      );
    }

    return alertas
        .whereType<Map>()
        .map((alerta) => Map<String, dynamic>.from(alerta))
        .toList();
  }

  /// Marcar una alerta como presentada para no repetir el aviso emergente.
  Future<bool> markDangerousAlertShown(String alertId) async {
    final response = await auth_http.patch(
      Uri.parse('$_baseUrl/peligro/$alertId/mostrada'),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Error al registrar la alerta como presentada: ${response.statusCode}',
      );
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    return decoded['mostrada'] == true;
  }

  /// Marcar como leída una alerta del centro de notificaciones.
  Future<void> markDangerousAlertRead(String alertId) async {
    final response = await auth_http.patch(
      Uri.parse('$_baseUrl/peligro/$alertId/leida'),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Error al marcar la alerta como leída: ${response.statusCode}',
      );
    }
  }

  /// Obtener alertas peligrosas activas cercanas (basado en lat/lng)
  Future<List<dynamic>> getNearbyDangerousAlerts(
    double latitud,
    double longitud,
  ) async {
    final uri = Uri.parse('$_baseUrl/peligro/cercanos').replace(
      queryParameters: {'latitud': '$latitud', 'longitud': '$longitud'},
    );
    final response = await auth_http.get(uri);

    if (response.statusCode != 200) {
      throw Exception(
        'Error al sincronizar alertas cercanas: ${response.statusCode}',
      );
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final alertas = decoded['alertas'];
    if (alertas is! List) {
      throw const FormatException(
        'La respuesta de alertas cercanas no contiene una lista',
      );
    }
    return alertas;
  }

  /// Actualizar preferencia para recibir alertas
  Future<bool> updateAlertSettings(bool recibirAlertas) async {
    try {
      final response = await auth_http.patch(
        Uri.parse('$_baseUrl/configuracion'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'recibir_alertas_peligro': recibirAlertas}),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error al actualizar configuración de alertas: $e');
      return false;
    }
  }

  /// Actualizar ubicación del usuario en segundo plano
  Future<bool> updateLocation(double latitud, double longitud) async {
    try {
      final response = await auth_http.patch(
        Uri.parse('$_baseUrl/ubicacion'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'latitud': latitud, 'longitud': longitud}),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error al actualizar ubicación de usuario: $e');
      return false;
    }
  }
}
