import 'dart:convert';
import 'package:terrascope/services/api_client.dart' as http;
import 'package:terrascope/components/models/zona_frecuente.dart';
import '../components/models/avistamiento_model.dart';
import '../config/api_config.dart';

class AvistamientoService {
  static Future<List<Avistamiento>> getAvistamientos({
    String? especie,
    String? busqueda,
    String? cursor,
    int limit = 100,
  }) async {
    final queryParameters = <String, String>{'limit': '$limit'};
    if (especie != null) queryParameters['categoria'] = especie;
    if (busqueda != null && busqueda.trim().isNotEmpty) {
      queryParameters['buscar'] = busqueda.trim();
    }
    if (cursor != null && cursor.isNotEmpty) {
      queryParameters['cursor'] = cursor;
    }

    final url = Uri.parse(
      '${ApiConfig.baseUrl}/fauna-flora',
    ).replace(queryParameters: queryParameters);
    final response = await http.get(url);

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((json) => Avistamiento.fromJson(json)).toList();
    } else {
      throw Exception('Error al cargar avistamientos');
    }
  }

  static Future<Avistamiento> getAvistamientoById(String id) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/fauna-flora/$id'),
    );

    if (response.statusCode == 200) {
      return Avistamiento.fromJson(json.decode(response.body));
    } else {
      throw Exception('Error al cargar avistamiento');
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

  static Future<void> addComentario(
    String avistamientoId,
    String comentario,
  ) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/fauna-flora/$avistamientoId/comentarios'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'comentario': comentario}),
    );

    if (response.statusCode != 200) {
      throw Exception('Error al agregar comentario: ${response.body}');
    }
  }

  static Future<List<Avistamiento>> searchAvistamientos(String query) async {
    return getAvistamientos(busqueda: query);
  }
}
