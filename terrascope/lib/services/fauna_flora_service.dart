import 'dart:convert';

import '../components/models/avistamiento_model.dart';
import '../components/models/comentario.dart';
import '../components/models/zona_frecuente.dart';
import '../config/api_config.dart';
import 'api_client.dart';
import 'api_response.dart';

/// Servicio unificado para operaciones de fauna y flora.
///
/// Consolida la lógica de los antiguos `FaunaFloraService` y
/// `AvistamientoService` en un solo punto de acceso.
class FaunaFloraService {
  final String baseUrl;

  FaunaFloraService({String? baseUrl})
      : baseUrl = baseUrl ?? ApiConfig.baseUrl;

  // --- Crear / Actualizar / Eliminar -----------------------------------

  /// Crear nuevo avistamiento
  Future<Avistamiento?> createFaunaFlora(Avistamiento data) async {
    final response = await ApiClient.post(
      Uri.parse('$baseUrl/fauna-flora'),
      body: json.encode(data.toJson()),
    );

    final jsonData = ApiResponse.extractMap(response.body);
    return Avistamiento.fromJson(jsonData);
  }

  /// Actualizar avistamiento
  Future<Avistamiento?> updateFaunaFlora(
    String id,
    Map<String, dynamic> updates,
  ) async {
    final response = await ApiClient.put(
      Uri.parse('$baseUrl/fauna-flora/$id'),
      body: json.encode(updates),
    );

    final jsonData = ApiResponse.extractMap(response.body);
    return Avistamiento.fromJson(jsonData);
  }

  /// Eliminar avistamiento
  Future<bool> deleteFaunaFlora(String id) async {
    final response = await ApiClient.delete(
      Uri.parse('$baseUrl/fauna-flora/$id'),
    );
    return response.statusCode == 200;
  }

  // --- Consultas -------------------------------------------------------

  /// Obtener todos los avistamientos, opcionalmente filtrados por [especie].
  Future<List<Avistamiento>> getAllFaunaFlora({String? especie}) async {
    String url = '$baseUrl/fauna-flora';
    if (especie != null) {
      url += '?categoria=$especie';
    }

    final response = await ApiClient.get(Uri.parse(url));

    final dataList = ApiResponse.extractList(response.body);
    return dataList
        .map((json) => Avistamiento.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Obtener avistamiento por ID. Retorna `null` si no existe (404).
  Future<Avistamiento?> getFaunaFloraById(String id) async {
    final response = await ApiClient.get(
      Uri.parse('$baseUrl/fauna-flora/$id'),
      allowedCodes: [200, 404],
    );

    if (response.statusCode == 404) return null;

    final jsonData = ApiResponse.extractMap(response.body);
    return Avistamiento.fromJson(jsonData);
  }

  /// Obtener avistamientos cercanos por ubicacion
  Future<List<Avistamiento>> getFaunaFloraCerca(
    double latitud,
    double longitud,
    double distanciaKm,
  ) async {
    final response = await ApiClient.get(
      Uri.parse('$baseUrl/fauna-flora/cerca/$latitud/$longitud/$distanciaKm'),
    );

    final dataList = ApiResponse.extractList(response.body);
    return dataList
        .map((json) => Avistamiento.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Obtener avistamientos por especie
  Future<List<Avistamiento>> getFaunaFloraByEspecie(String especie) async {
    final response = await ApiClient.get(
      Uri.parse(
        '$baseUrl/fauna-flora/especie/${Uri.encodeComponent(especie)}',
      ),
    );

    final dataList = ApiResponse.extractList(response.body);
    return dataList
        .map((json) => Avistamiento.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Obtener avistamientos por usuario
  Future<List<Avistamiento>> getFaunaFloraByUsuario(
    String nombreUsuario,
  ) async {
    final response = await ApiClient.get(
      Uri.parse(
        '$baseUrl/fauna-flora/usuario/${Uri.encodeComponent(nombreUsuario)}',
      ),
    );

    final dataList = ApiResponse.extractList(response.body);
    return dataList
        .map((json) => Avistamiento.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Buscar avistamientos por texto (filtra localmente)
  Future<List<Avistamiento>> searchAvistamientos(String query) async {
    final avistamientos = await getAllFaunaFlora();
    final queryLower = query.toLowerCase();

    return avistamientos.where((avistamiento) {
      return avistamiento.nombreComun.toLowerCase().contains(queryLower) ||
          avistamiento.nombreCientifico.toLowerCase().contains(queryLower) ||
          avistamiento.especie.toLowerCase().contains(queryLower);
    }).toList();
  }

  // --- Feed ------------------------------------------------------------

  /// Obtener el feed de usuarios seguidos (GET /fauna-flora/feed)
  Future<List<Avistamiento>> getFeed() async {
    final response = await ApiClient.get(
      Uri.parse('$baseUrl/fauna-flora/feed'),
    );

    final dataList = ApiResponse.extractList(response.body, listKey: 'feed');
    return dataList
        .map((json) => Avistamiento.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Obtener zonas frecuentes de avistamientos
  Future<List<ZonaFrecuente>> getZonasFrecuentes() async {
    final response = await ApiClient.get(
      Uri.parse('$baseUrl/fauna-flora/frequent-zones'),
    );

    final dataList = ApiResponse.extractList(response.body);
    return dataList
        .map((json) => ZonaFrecuente.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  // --- Interacciones sociales ------------------------------------------

  /// Alternar Like en un avistamiento (POST /fauna-flora/:id/like)
  Future<Map<String, dynamic>> toggleLike(String avistamientoId) async {
    final response = await ApiClient.post(
      Uri.parse('$baseUrl/fauna-flora/$avistamientoId/like'),
    );
    return json.decode(response.body) as Map<String, dynamic>;
  }

  /// Agregar comentario a un avistamiento
  Future<Comentario?> addComentario(
    String avistamientoId,
    String comentario,
  ) async {
    final response = await ApiClient.post(
      Uri.parse('$baseUrl/fauna-flora/$avistamientoId/comentarios'),
      body: json.encode({'comentario': comentario}),
      allowedCodes: [200, 201],
    );

    final decoded = json.decode(response.body);
    if (decoded is Map && decoded.containsKey('comentario')) {
      return Comentario.fromJson(decoded['comentario']);
    }
    return null;
  }

  /// Eliminar comentario con moderacion
  Future<bool> deleteComentario(
    String avistamientoId,
    String comentarioId,
  ) async {
    final response = await ApiClient.delete(
      Uri.parse(
        '$baseUrl/fauna-flora/$avistamientoId/comentarios/$comentarioId',
      ),
    );
    return response.statusCode == 200;
  }

  // --- Validacion ------------------------------------------------------

  /// Votar por un avistamiento (comunidad)
  Future<void> votarAvistamiento(
    String idAvistamiento, {
    String? idUsuario,
  }) async {
    await ApiClient.put(
      Uri.parse('$baseUrl/fauna-flora/$idAvistamiento/votar'),
      body: json.encode({
        if (idUsuario != null && idUsuario.isNotEmpty) 'id_usuario': idUsuario,
      }),
    );
  }

  /// Validar avistamiento como experto
  Future<void> validarComoExperto(
    String idAvistamiento, {
    String? idUsuario,
    String? rol,
  }) async {
    await ApiClient.put(
      Uri.parse('$baseUrl/fauna-flora/$idAvistamiento/validar-experto'),
      body: json.encode({
        if (idUsuario != null && idUsuario.isNotEmpty) 'id_usuario': idUsuario,
        if (rol != null && rol.isNotEmpty) 'rol': rol,
      }),
    );
  }

  /// Obtener estado de validacion (incluye yaVoto y usuarios_validadores)
  Future<Map<String, dynamic>?> getEstadoValidacion(
    String idAvistamiento,
  ) async {
    final response = await ApiClient.get(
      Uri.parse('$baseUrl/fauna-flora/$idAvistamiento/validacion'),
    );
    return json.decode(response.body) as Map<String, dynamic>;
  }
}
