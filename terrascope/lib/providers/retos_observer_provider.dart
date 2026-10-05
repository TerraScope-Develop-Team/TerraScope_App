import 'dart:async';
import 'package:flutter/material.dart';
import '../components/models/reto_model.dart';
import '../services/retos_service.dart';
import '../services/session_service.dart';
import '../services/notification_service.dart';

class RetosObserverProvider with ChangeNotifier {
  final RetosService _retosService = RetosService();
  final SessionService _sessionService = SessionService();
  NotificationService? _notificationService;

  List<Reto> _retosActivos = [];
  List<Logro> _logrosUsuario = [];
  Map<String, dynamic> _historialUsuario = {};
  bool _isLoading = false;
  String? _error;

  List<Reto> get retosActivos => _retosActivos;
  List<Logro> get logrosUsuario => _logrosUsuario;
  Map<String, dynamic> get historialUsuario => _historialUsuario;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Cargar retos activos
  Future<void> cargarRetosActivos() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _retosActivos = await _retosService.getRetosActivos();
      print('✅ Retos cargados: ${_retosActivos.length}');
    } catch (e) {
      _error = 'Error al cargar retos: $e';
      print('❌ $_error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Cargar logros del usuario
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

        print('✅ Logros cargados: ${_logrosUsuario.length}');
        notifyListeners();
      }
    } catch (e) {
      print('❌ Error cargando logros: $e');
    }
  }

  // Inscribirse a un reto
  Future<bool> inscribirseReto(String retoId) async {
    try {
      final success = await _retosService.inscribirseReto(retoId);

      if (success) {
        await cargarRetosActivos();
        await cargarLogrosUsuario();
        // Notificación de suscripción a reto
        final notification = AppNotification(
          id: 'suscripcion_$retoId',
          title: 'Suscrito a Reto',
          message: 'Te has suscrito al reto. ¡Estate atento, pronto cerrará!',
          type: NotificationType.info,
        );
        _notificationService!.showNotification(notification);
      }

      return success;
    } catch (e) {
      print('❌ Error inscribiéndose al reto: $e');
      return false;
    }
  }

  // Desinscribirse de un reto
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
      print('❌ Error desinscribiéndose del reto: $e');
      return false;
    }
  }

  // Obtener progreso en un reto
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
      print('❌ Error obteniendo progreso: $e');
      return null;
    }
  }

  // Toggle visibilidad de logro
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
      print('❌ Error cambiando visibilidad: $e');
      return false;
    }
  }

  // Verificar si el usuario está inscrito en un reto
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

  // Verificar si el usuario completó un reto
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

  // Actualiza retos activos, cargas logros y genera notificaciones para nuevos retos y retos completados
  Future<void> actualizarRetosYNotificaciones() async {
    // Guardar estado previo de retos finalizados del usuario y retos activos
    final prevRetosFinalizados = List<String>.from(_retosFinalizadosPrevios);
    final prevRetos = List<Reto>.from(_retosPrevios);

    await cargarRetosActivos();
    await cargarLogrosUsuario();

    // Detectar nuevos retos finalizados
    final userData = await _sessionService.getUserData();
    final usuarioId = userData?['_id'];

    final retosFinalizadosActuales = _retosActivos
        .where(
          (r) => r.usuariosFinalizados.any((u) => u.usuarioId == usuarioId),
        )
        .map((r) => r.id)
        .toList();

    // Retos completados nuevos (en actuales y no en previos)
    final nuevosRetosCompletados = retosFinalizadosActuales
        .where((id) => !prevRetosFinalizados.contains(id))
        .toList();

    // Detectar nuevos retos disponibles
    final nuevosRetos = _retosActivos
        .where((reto) => !prevRetos.any((prevReto) => prevReto.id == reto.id))
        .toList();

    // Actualizar el estado previo
    _retosFinalizadosPrevios = retosFinalizadosActuales;
    _retosPrevios = List<Reto>.from(_retosActivos);

    // Notificar nuevos retos completados
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
          title: '¡Reto Completado!',
          message: 'Has completado el reto "${reto.nombreReto}". ¡Felicidades!',
          type: NotificationType.success,
        );
        _notificationService!.showNotification(notification);
      }
    }

    // Notificar solo si hay nuevos retos disponibles
    if (nuevosRetos.isNotEmpty) {
      final notification = AppNotification(
        id: 'nuevo_reto',
        title: 'Nuevos Retos Disponibles',
        message: 'Se han generado nuevos retos para ti. ¡Échales un vistazo!',
        type: NotificationType.success,
      );
      _notificationService!.showNotification(notification);
    }
  }
}
