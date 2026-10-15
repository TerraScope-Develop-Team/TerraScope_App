import '../components/models/avistamiento_model.dart';
import '../components/models/comentario.dart';
import '../components/models/zona_frecuente.dart';
import 'fauna_flora_service.dart';

/// Capa de compatibilidad para código existente que aún referencia [AvistamientoService].
///
/// Delega todas las operaciones a [FaunaFloraService].
@deprecated
class AvistamientoService {
  static final FaunaFloraService _service = FaunaFloraService();

  static Future<List<Avistamiento>> getAvistamientos({
    String? especie,
    String? busqueda,
    String? cursor,
    int limit = 100,
  }) {
    return _service.getAllFaunaFlora(
      especie: especie,
      busqueda: busqueda,
      cursor: cursor,
      limit: limit,
    );
  }

  static Future<Avistamiento?> getAvistamientoById(String id) {
    return _service.getFaunaFloraById(id);
  }

  static Future<List<Avistamiento>> getFeedAvistamientos() {
    return _service.getFeed();
  }

  static Future<List<ZonaFrecuente>> getZonasFrecuentes() {
    return _service.getZonasFrecuentes();
  }

  static Future<Map<String, dynamic>> toggleLike(String avistamientoId) {
    return _service.toggleLike(avistamientoId);
  }

  static Future<Comentario?> addComentario(
    String avistamientoId,
    String comentario,
  ) {
    return _service.addComentario(avistamientoId, comentario);
  }

  static Future<bool> deleteComentario(
    String avistamientoId,
    String comentarioId,
  ) {
    return _service.deleteComentario(avistamientoId, comentarioId);
  }

<<<<<<< HEAD
  static Future<List<Avistamiento>> searchAvistamientos(String query) {
    return _service.searchAvistamientos(query);
=======
  static Future<List<Avistamiento>> searchAvistamientos(String query) async {
    return getAvistamientos(busqueda: query);
>>>>>>> a2d45c8161740bbf522f151d6d3f963cdf420e95
  }
}
