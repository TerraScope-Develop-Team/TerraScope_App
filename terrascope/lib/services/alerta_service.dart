import 'dart:convert';

import '../config/api_config.dart';
import 'api_client.dart';

class AlertaService {
  final String _baseUrl = '${ApiConfig.baseUrl}/alertas';

  /// Enviar una senal de SOS con ubicacion actual
  Future<bool> sendSOS(double latitud, double longitud) async {
    final response = await ApiClient.post(
      Uri.parse('$_baseUrl/sos'),
      body: jsonEncode({'latitud': latitud, 'longitud': longitud}),
      allowedCodes: [201, 200],
    );
    return response.statusCode == 201;
  }

  /// Obtener notificaciones de fauna peligrosa para el usuario
  Future<List<Map<String, dynamic>>> getDangerousAlerts() async {
    final response = await ApiClient.get(Uri.parse('$_baseUrl/peligro'));

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
    final response = await ApiClient.patch(
      Uri.parse('$_baseUrl/peligro/$alertId/mostrada'),
    );

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    return decoded['mostrada'] == true;
  }

  /// Marcar como leida una alerta del centro de notificaciones.
  Future<void> markDangerousAlertRead(String alertId) async {
    await ApiClient.patch(
      Uri.parse('$_baseUrl/peligro/$alertId/leida'),
    );
  }

  /// Obtener alertas peligrosas activas cercanas (basado en lat/lng)
  Future<List<dynamic>> getNearbyDangerousAlerts(
    double latitud,
    double longitud,
  ) async {
    final uri = Uri.parse('$_baseUrl/peligro/cercanos').replace(
      queryParameters: {'latitud': '$latitud', 'longitud': '$longitud'},
    );
    final response = await ApiClient.get(uri);

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
    final response = await ApiClient.patch(
      Uri.parse('$_baseUrl/configuracion'),
      body: jsonEncode({'recibir_alertas_peligro': recibirAlertas}),
      allowedCodes: [200, 400],
    );
    return response.statusCode == 200;
  }

  /// Actualizar ubicacion del usuario en segundo plano
  Future<bool> updateLocation(double latitud, double longitud) async {
    final response = await ApiClient.patch(
      Uri.parse('$_baseUrl/ubicacion'),
      body: jsonEncode({'latitud': latitud, 'longitud': longitud}),
      allowedCodes: [200, 400],
    );
    return response.statusCode == 200;
  }
}
