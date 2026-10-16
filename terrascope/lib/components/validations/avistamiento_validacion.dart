import 'package:flutter/material.dart';
import 'dart:developer';
import '../../providers/request_state.dart';
import '../../services/fauna_flora_service.dart';
import '../../services/session_service.dart';
import '../models/avistamiento_model.dart';

/// Gestiona la lógica de validación de avistamientos
/// y centraliza el consumo de FaunaFloraService.
class AvistamientoValidacionProvider with ChangeNotifier, RequestStateMixin {
  final FaunaFloraService _service;
  final SessionService _sessionService = SessionService();

  AvistamientoValidacionProvider({required String baseUrl})
    : _service = FaunaFloraService(baseUrl: baseUrl);

  /// Lista de avistamientos
  List<Avistamiento> _avistamientos = [];
  List<Avistamiento> get avistamientos => _avistamientos;

  /// Error actual (mantiene compatibilidad)
  String? get error => errorMessage;

  /// Cargar todos los avistamientos
  Future<void> cargarAvistamientos() => executeRequest(() async {
    log("Cargando lista de avistamientos...");
    _avistamientos = await _service.getAllFaunaFlora();
    log("Avistamientos cargados: ${_avistamientos.length}");
  });

  /// Votar validación comunitaria
  Future<void> votar(String idAvistamiento) => executeRequest(() async {
    log("Iniciando proceso de voto para avistamiento $idAvistamiento...");
    final userData = await _sessionService.getUserData();

    // Verificar datos en sesión
    log("Datos de sesión al votar: $userData");

    final idUsuario = userData?['_id'] ?? userData?['id'];
    if (idUsuario == null) {
      throw Exception(
        'No se encontró el usuario en sesión o falta el _id',
      );
    }

    log(
      "Enviando voto de usuario $idUsuario avistamiento $idAvistamiento",
    );

    await _service.votarAvistamiento(
      idAvistamiento,
      idUsuario: idUsuario.toString(),
    );

    log("Voto enviado correctamente. Recargando lista...");
    _avistamientos = await _service.getAllFaunaFlora();
  });

  /// Validar avistamiento como experto (solo Administrador o Investigador)
  Future<void> validarComoExperto(String idAvistamiento) =>
      executeRequest(() async {
        log(
          "Iniciando validación de experto para avistamiento $idAvistamiento...",
        );
        final userData = await _sessionService.getUserData();

        // Mostrar datos completos del usuario
        log("Datos de sesión al validar como experto: $userData");

        final idUsuario = userData?['_id'] ?? userData?['id'];
        final rol = userData?['rol'];
        if (idUsuario == null || rol == null) {
          throw Exception(
            'No se encontró información válida de usuario o rol',
          );
        }

        log("Enviando validación como experto usuario $idUsuario ($rol)");

        await _service.validarComoExperto(
          idAvistamiento,
          idUsuario: idUsuario.toString(),
          rol: rol.toString(),
        );

        log("Validación por experto exitosa. Recargando lista...");
        _avistamientos = await _service.getAllFaunaFlora();
      });

  /// Obtener estado actual de validación (con yaVoto)
  Future<Map<String, dynamic>?> obtenerEstadoValidacion(
    String idAvistamiento,
  ) => executeRequest<Map<String, dynamic>?>(() async {
    log("Consultando estado de validación para $idAvistamiento...");

    final userData = await _sessionService.getUserData();
    final idUsuario = userData?['_id'] ?? userData?['id'];
    if (idUsuario == null) {
      throw Exception('No se encontró usuario en sesión');
    }

    log("Usuario en sesión: $idUsuario");

    final estado = await _service.getEstadoValidacion(idAvistamiento);

    if (estado != null) {
      final yaVoto = estado['yaVoto'] ?? false;
      final votos = estado['votos_comunidad'] ?? 0;
      final requeridos = estado['requeridos_comunidad'] ?? 0;
      final validado = estado['validado_por_experto'] ?? false;

      log(
        "Estado recibido votos: $votos, requeridos: $requeridos, validado: $validado, yaVoto: $yaVoto",
      );
    }

    return estado;
  });
}
