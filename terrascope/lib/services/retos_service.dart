import 'dart:convert';

import '../components/models/reto_model.dart';
import '../config/api_config.dart';
import 'api_client.dart';

class RetosService {
  final String baseUrl = '${ApiConfig.baseUrl}/retos';

  /// Obtener todos los retos activos
  Future<List<Reto>> getRetosActivos() async {
    final response = await ApiClient.get(Uri.parse('$baseUrl/activos'));
    final List<dynamic> data = json.decode(response.body);
    return data.map((json) => Reto.fromJson(json)).toList();
  }

  /// Obtener reto por ID. Retorna `null` si no existe (404).
  Future<Reto?> getRetoById(String retoId) async {
    final response = await ApiClient.get(
      Uri.parse('$baseUrl/$retoId'),
      allowedCodes: [200, 404],
    );

    if (response.statusCode == 404) return null;
    return Reto.fromJson(json.decode(response.body));
  }

  /// Inscribirse a un reto.
  ///
  /// Retorna `true` si la inscripcion fue exitosa, `false` en caso contrario.
  Future<bool> inscribirseReto(String retoId) async {
    if (retoId.trim().isEmpty) {
      throw ArgumentError('Se requiere el ID del reto.');
    }

    final response = await ApiClient.post(
      Uri.parse('$baseUrl/inscribirse'),
      body: json.encode({'retoId': retoId}),
      allowedCodes: [200, 400, 409],
    );

    return response.statusCode == 200;
  }

  /// Desinscribirse de un reto
  Future<bool> desinscribirseReto(String retoId, String usuarioId) async {
    final response = await ApiClient.post(
      Uri.parse('$baseUrl/desinscribirse'),
      body: json.encode({'retoId': retoId, 'usuarioId': usuarioId}),
      allowedCodes: [200, 400, 404],
    );

    return response.statusCode == 200;
  }

  /// Obtener tabla de posiciones
  Future<Map<String, dynamic>?> getTablaPosiciones(String retoId) async {
    final response = await ApiClient.get(
      Uri.parse('$baseUrl/$retoId/posiciones'),
      allowedCodes: [200, 404],
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    return null;
  }

  /// Obtener logros del usuario
  Future<Map<String, dynamic>?> getLogrosUsuario(String usuarioId) async {
    final response = await ApiClient.get(
      Uri.parse('$baseUrl/usuario/$usuarioId/logros'),
      allowedCodes: [200, 404],
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    return null;
  }

  /// Cambiar visibilidad de logro
  Future<bool> toggleMostrarLogro(String usuarioId, String logroId) async {
    final response = await ApiClient.patch(
      Uri.parse('$baseUrl/logro/visibilidad'),
      body: json.encode({'usuarioId': usuarioId, 'logroId': logroId}),
    );
    return response.statusCode == 200;
  }

  /// Obtener progreso en un reto
  Future<Map<String, dynamic>?> getProgresoReto(
    String retoId,
    String usuarioId,
  ) async {
    final response = await ApiClient.get(
      Uri.parse('$baseUrl/$retoId/progreso/$usuarioId'),
      allowedCodes: [200, 404],
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    return null;
  }
}
