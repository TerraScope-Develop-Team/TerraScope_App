import 'package:flutter/foundation.dart';
import '../components/models/avistamiento_model.dart';
import '../services/fauna_flora_service.dart';
import 'request_state.dart';

/// Provider centralizado para avistamientos de fauna y flora.
/// Implementa [RequestStateMixin] para unificar el manejo de carga y errores.
class FaunaFloraProvider with ChangeNotifier, RequestStateMixin {
  final FaunaFloraService _service;

  FaunaFloraProvider({FaunaFloraService? service})
      : _service = service ?? FaunaFloraService();

  List<Avistamiento> _avistamientos = [];
  List<Avistamiento> get avistamientos => List.unmodifiable(_avistamientos);

  /// Carga la lista de avistamientos con soporte para filtros opcionales.
  Future<List<Avistamiento>?> cargarAvistamientos({
    String? especie,
    String? busqueda,
    String? cursor,
    int limit = 100,
  }) async {
    return executeRequest(() async {
      final items = await _service.getAllFaunaFlora(
        especie: especie,
        busqueda: busqueda,
        cursor: cursor,
        limit: limit,
      );
      _avistamientos = items;
      return items;
    });
  }

  /// Carga el feed principal de avistamientos.
  Future<List<Avistamiento>?> cargarFeed() async {
    return executeRequest(() async {
      final items = await _service.getFeed();
      _avistamientos = items;
      return items;
    });
  }

  /// Alterna 'me gusta' en un avistamiento.
  Future<Map<String, dynamic>?> toggleLike(String avistamientoId) async {
    return executeRequest(() async {
      return await _service.toggleLike(avistamientoId);
    });
  }
}
