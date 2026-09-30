import 'dart:convert';
import 'package:terrascope/services/api_client.dart' as http;
import 'package:terrascope/components/models/zona_frecuente.dart';
import '../components/models/avistamiento_model.dart';
import '../components/models/comentario.dart';
import '../config/api_config.dart';

class AvistamientoService {
  static Future<List<Avistamiento>> getAvistamientos({String? especie}) async {
    String url = '${ApiConfig.baseUrl}/fauna-flora';
    if (especie != null) {
      url += '?categoria=$especie';
    }

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      List<dynamic> data;
      if (decoded is List) {
        data = decoded;
      } else if (decoded is Map && decoded.containsKey('data')) {
        data = decoded['data'];
      } else {
        data = [];
      }
      return data.map((item) => Avistamiento.fromJson(item)).toList();
    } else {
      throw Exception('Error al cargar avistamientos');
    }
  }

  static Future<Avistamiento> getAvistamientoById(String id) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/fauna-flora/$id'),
    );

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      final data = (decoded is Map && decoded.containsKey('data'))
          ? decoded['data']
          : decoded;
      return Avistamiento.fromJson(data);
    } else {
      throw Exception('Error al cargar avistamiento');
    }
  }

  /// Obtener el feed de usuarios seguidos (GET /fauna-flora/feed)
  static Future<List<Avistamiento>> getFeedAvistamientos() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/fauna-flora/feed'),
    );

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      List<dynamic> data = [];
      if (decoded is Map && decoded.containsKey('feed')) {
        data = decoded['feed'];
      } else if (decoded is List) {
        data = decoded;
      }
      return data.map((item) => Avistamiento.fromJson(item)).toList();
    } else {
      throw Exception('Error al cargar feed de seguidos: ${response.statusCode}');
    }
  }

  static Future<List<ZonaFrecuente>> getZonasFrecuentes() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/fauna-flora/frequent-zones'),
    );

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((json) => ZonaFrecuente.fromJson(json)).toList();
    } else {
      throw Exception('Error al cargar zonas frecuentes');
    }
  }

  /// Alternar Like en un avistamiento (POST /fauna-flora/:id/like)
  static Future<Map<String, dynamic>> toggleLike(String avistamientoId) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/fauna-flora/$avistamientoId/like'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Error al procesar el like: ${response.body}');
    }
  }

  /// Agregar comentario a un avistamiento (POST /fauna-flora/:id/comentarios)
  static Future<Comentario?> addComentario(
    String avistamientoId,
    String comentario,
  ) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/fauna-flora/$avistamientoId/comentarios'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'comentario': comentario}),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final decoded = json.decode(response.body);
      if (decoded is Map && decoded.containsKey('comentario')) {
        return Comentario.fromJson(decoded['comentario']);
      }
      return null;
    } else {
      throw Exception('Error al agregar comentario: ${response.body}');
    }
  }

  /// Eliminar comentario con moderación (DELETE /fauna-flora/:id/comentarios/:comentarioId)
  static Future<bool> deleteComentario(
    String avistamientoId,
    String comentarioId,
  ) async {
    final response = await http.delete(
      Uri.parse(
        '${ApiConfig.baseUrl}/fauna-flora/$avistamientoId/comentarios/$comentarioId',
      ),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      return true;
    } else if (response.statusCode == 403) {
      throw Exception('No tienes permisos para eliminar este comentario');
    } else {
      throw Exception('Error al eliminar comentario: ${response.body}');
    }
  }

  static Future<List<Avistamiento>> searchAvistamientos(String query) async {
    final avistamientos = await getAvistamientos();

    return avistamientos.where((avistamiento) {
      return avistamiento.nombreComun.toLowerCase().contains(
            query.toLowerCase(),
          ) ||
          avistamiento.nombreCientifico.toLowerCase().contains(
            query.toLowerCase(),
          ) ||
          avistamiento.especie.toLowerCase().contains(query.toLowerCase());
    }).toList();
  }
}
