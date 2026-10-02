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
        body: jsonEncode({
          'latitud': latitud,
          'longitud': longitud,
        }),
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
  Future<List<dynamic>> getDangerousAlerts() async {
    try {
      final response = await auth_http.get(
        Uri.parse('$_baseUrl/peligro'),
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        return decoded['alertas'] ?? [];
      }
      return [];
    } catch (e) {
      print('Error al obtener alertas: $e');
      return [];
    }
  }

  /// Obtener alertas peligrosas activas cercanas (basado en lat/lng)
  Future<List<dynamic>> getNearbyDangerousAlerts(double latitud, double longitud) async {
    try {
      final uri = Uri.parse('$_baseUrl/peligro/cercanos?latitud=$latitud&longitud=$longitud');
      final response = await auth_http.get(uri); // Puede que no necesite auth si es get

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        return decoded['alertas'] ?? [];
      }
      return [];
    } catch (e) {
      print('Error al obtener alertas cercanas: $e');
      return [];
    }
  }

  /// Actualizar preferencia para recibir alertas
  Future<bool> updateAlertSettings(bool recibirAlertas) async {
    try {
      final response = await auth_http.patch(
        Uri.parse('$_baseUrl/configuracion'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'recibir_alertas_peligro': recibirAlertas,
        }),
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
        body: jsonEncode({
          'latitud': latitud,
          'longitud': longitud,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error al actualizar ubicación de usuario: $e');
      return false;
    }
  }
}
