import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../components/models/reto_model.dart';
import '../services/notification_service.dart';
import '../services/retos_service.dart';
import '../services/session_service.dart';
import 'request_state.dart';

class RetosObserverProvider with ChangeNotifier, RequestStateMixin {
  final RetosService _retosService = RetosService();
  final SessionService _sessionService = SessionService();
  NotificationService? _notificationService;

  List<Reto> _retosActivos = [];
  List<Logro> _logrosUsuario = [];
  Map<String, dynamic> _historialUsuario = {};

  List<Reto> get retosActivos => _retosActivos;
  List<Logro> get logrosUsuario => _logrosUsuario;
  Map<String, dynamic> get historialUsuario => _historialUsuario;

  /// Compatibilidad con código existente que lee `.error`
  String? get error => errorMessage;

  /// Cargar retos activos usando el mixin de estado
  Future<void> cargarRetosActivos() async {
    await executeRequest(() async {
      _retosActivos = await _retosService.getRetosActivos();
      debugPrint('Retos cargados: ${_retosActivos.length}');
      return _retosActivos;
    });
  }

  /// Cargar logros del usuario
  Future<void> cargarLogrosUsuario() async {
    try {
      final userData = await _sessionService.getUserData();
      if (userData == null || userData['_id'] == null) {
        throw Exception('Usuario no autenticado');
      }

      final String usuarioId = userData['_id'];
      final data = await _retosService.getLogrosUsuario(usuarioId);

      if (data != null) {
        _logrosUsuario = (data['logros'] as List)
            .map((l) => Logro.fromJson(l))
            .toList();
        _historialUsuario = data['historial'] ?? {};

        debugPrint('Logros cargados: ${_logrosUsuario.length}');
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error cargando logros: $e');
    }
  }

  /// Inscribirse a un reto
  Future<bool> inscribirseReto(String retoId) async {
    try {
      final success = await _retosService.inscribirseReto(retoId);

      if (success) {
        await cargarRetosActivos();
        await cargarLogrosUsuario();
        final notification = AppNotification(
          id: 'suscripcion_$retoId',
          title: 'Suscrito a Reto',
          message: 'Te has suscrito al reto. Estate atento, pronto cerrará!',
          type: NotificationType.info,
        );
        _notificationService?.showNotification(notification);
      }

      return success;
    } catch (e) {
      debugPrint('Error inscribiendose al reto: $e');
      return false;
    }
  }

  /// Desinscribirse de un reto
  Future<bool> desinscribirseReto(String retoId) async {
    try {
      final userData = await _sessionService.getUserData();
      if (userData == null) return false;

      final usuarioId = userData['_id'];
      final success = await _retosService.desinscribirseReto(retoId, usuarioId);

      if (success) {
        await cargarRetosActivos();
      }

      return success;
    } catch (e) {
      debugPrint('Error desinscribiendose del reto: $e');
      return false;
    }
  }

  /// Obtener progreso en un reto
  Future<Map<String, ProgresoReto>?> getProgresoReto(String retoId) async {
    try {
      final userData = await _sessionService.getUserData();
      if (userData == null) return null;

      final usuarioId = userData['_id'];
      final data = await _retosService.getProgresoReto(retoId, usuarioId);

      if (data != null && data['progreso'] != null) {
        final Map<String, ProgresoReto> progreso = {};
        (data['progreso'] as Map<String, dynamic>).forEach((key, value) {
          progreso[key] = ProgresoReto.fromJson(value);
        });
        return progreso;
      }

      return null;
    } catch (e) {
      debugPrint('Error obteniendo progreso: $e');
      return null;
    }
  }

  /// Toggle visibilidad de logro
  Future<bool> toggleMostrarLogro(String logroId) async {
    try {
      final userData = await _sessionService.getUserData();
      if (userData == null) return false;

      final usuarioId = userData['_id'];
      final success = await _retosService.toggleMostrarLogro(
        usuarioId,
        logroId,
      );

      if (success) {
        await cargarLogrosUsuario();
      }

      return success;
    } catch (e) {
      debugPrint('Error cambiando visibilidad: $e');
      return false;
    }
  }

  /// Verificar si el usuario está inscrito en un reto
  bool estaInscrito(String retoId, String? usuarioId) {
    if (usuarioId == null) return false;

    final reto = _retosActivos.firstWhere(
      (r) => r.id == retoId,
      orElse: () => Reto(
        id: '',
        nombreReto: '',
        descripcionReto: '',
        condiciones: {},
        usuariosInscritos: [],
        usuariosFinalizados: [],
        estado: '',
        esTemporal: false,
      ),
    );

    return reto.usuariosInscritos.contains(usuarioId);
  }

  /// Verificar si el usuario completó un reto
  bool haCompletado(String retoId, String? usuarioId) {
    if (usuarioId == null) return false;

    final reto = _retosActivos.firstWhere(
      (r) => r.id == retoId,
      orElse: () => Reto(
        id: '',
        nombreReto: '',
        descripcionReto: '',
        condiciones: {},
        usuariosInscritos: [],
        usuariosFinalizados: [],
        estado: '',
        esTemporal: false,
      ),
    );

    return reto.usuariosFinalizados.any((u) => u.usuarioId == usuarioId);
  }

  List<String> _retosFinalizadosPrevios = [];
  List<Reto> _retosPrevios = [];

  void setNotificationService(NotificationService service) {
    _notificationService = service;
  }

  /// Actualiza retos activos, carga logros y genera notificaciones
  Future<void> actualizarRetosYNotificaciones() async {
    final prevRetosFinalizados = List<String>.from(_retosFinalizadosPrevios);
    final prevRetos = List<Reto>.from(_retosPrevios);

    await cargarRetosActivos();
    await cargarLogrosUsuario();

    final userData = await _sessionService.getUserData();
    final usuarioId = userData?['_id'];

    final retosFinalizadosActuales = _retosActivos
        .where(
          (r) => r.usuariosFinalizados.any((u) => u.usuarioId == usuarioId),
        )
        .map((r) => r.id)
        .toList();

    final nuevosRetosCompletados = retosFinalizadosActuales
        .where((id) => !prevRetosFinalizados.contains(id))
        .toList();

    final nuevosRetos = _retosActivos
        .where((reto) => !prevRetos.any((prevReto) => prevReto.id == reto.id))
        .toList();

    _retosFinalizadosPrevios = retosFinalizadosActuales;
    _retosPrevios = List<Reto>.from(_retosActivos);

    for (var retoId in nuevosRetosCompletados) {
      final reto = _retosActivos.firstWhere(
        (r) => r.id == retoId,
        orElse: () => Reto(
          id: '',
          nombreReto: '',
          descripcionReto: '',
          condiciones: {},
          usuariosInscritos: [],
          usuariosFinalizados: [],
          estado: '',
          esTemporal: false,
        ),
      );
      if (reto.id != '') {
        final notification = AppNotification(
          id: 'reto_completado_$retoId',
          title: 'Reto Completado',
          message: 'Has completado el reto "${reto.nombreReto}". Felicitaciones!',
          type: NotificationType.success,
        );
        _notificationService?.showNotification(notification);
      }
    }

    if (nuevosRetos.isNotEmpty) {
      final notification = AppNotification(
        id: 'nuevo_reto',
        title: 'Nuevos Retos Disponibles',
        message: 'Se han generado nuevos retos para ti. Revisa la seccion de retos.',
        type: NotificationType.success,
      );
      _notificationService?.showNotification(notification);
    }
  }
}
