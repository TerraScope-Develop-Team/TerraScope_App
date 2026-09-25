import 'dart:convert';
import 'package:terrascope/services/api_client.dart' as http;
import '../components/models/reto_model.dart';
import '../config/api_config.dart';

class RetosService {
  final String baseUrl = '${ApiConfig.baseUrl}/retos';

  // Obtener todos los retos activos
  Future<List<Reto>> getRetosActivos() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/activos'));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Reto.fromJson(json)).toList();
      } else {
        throw Exception('Error al cargar retos: ${response.statusCode}');
      }
    } catch (e) {
      print('Error en getRetosActivos: $e');
      rethrow;
    }
  }

  // Obtener reto por ID
  Future<Reto?> getRetoById(String retoId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/$retoId'));

      if (response.statusCode == 200) {
        return Reto.fromJson(json.decode(response.body));
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw Exception('Error al cargar reto');
      }
    } catch (e) {
      print('Error en getRetoById: $e');
      rethrow;
    }
  }

  // Inscribirse a un reto
  Future<bool> inscribirseReto(String retoId, String usuarioId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/inscribirse'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'retoId': retoId, 'usuarioId': usuarioId}),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error en inscribirseReto: $e');
      return false;
    }
  }

  // Desinscribirse de un reto
  Future<bool> desinscribirseReto(String retoId, String usuarioId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/desinscribirse'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'retoId': retoId, 'usuarioId': usuarioId}),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error en desinscribirseReto: $e');
      return false;
    }
  }

  // Obtener tabla de posiciones
  Future<Map<String, dynamic>?> getTablaPosiciones(String retoId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/$retoId/posiciones'));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      print('Error en getTablaPosiciones: $e');
      return null;
    }
  }

  // Obtener logros del usuario
  Future<Map<String, dynamic>?> getLogrosUsuario(String usuarioId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/usuario/$usuarioId/logros'),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      print('Error en getLogrosUsuario: $e');
      return null;
    }
  }

  // Cambiar visibilidad de logro
  Future<bool> toggleMostrarLogro(String usuarioId, String logroId) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/logro/visibilidad'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'usuarioId': usuarioId, 'logroId': logroId}),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error en toggleMostrarLogro: $e');
      return false;
    }
  }

  // Obtener progreso en un reto
  Future<Map<String, dynamic>?> getProgresoReto(
    String retoId,
    String usuarioId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/$retoId/progreso/$usuarioId'),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      print('Error en getProgresoReto: $e');
      return null;
    }
  }
}
