import 'package:flutter/material.dart';
import '../services/api_exception.dart';

/// Estados posibles de una petición asíncrona.
enum RequestState {
  /// Sin actividad, estado inicial.
  idle,

  /// Petición en curso.
  loading,

  /// Petición completada exitosamente.
  success,

  /// Petición fallida.
  error,
}

/// Mixin reutilizable que agrega manejo de estado de carga a cualquier
/// [ChangeNotifier].
///
/// Proporciona [requestState], [errorMessage] y el método [executeRequest]
/// que encapsula automáticamente la lógica de loading/success/error.
///
/// Ejemplo de uso en un provider:
/// ```dart
/// class MiProvider with ChangeNotifier, RequestStateMixin {
///   Future<void> cargarDatos() => executeRequest(() async {
///     _datos = await miService.obtenerDatos();
///   });
/// }
/// ```
mixin RequestStateMixin on ChangeNotifier {
  RequestState _requestState = RequestState.idle;
  String? _errorMessage;

  /// Estado actual de la última petición.
  RequestState get requestState => _requestState;

  /// Mensaje de error de la última petición fallida, o `null` si no hubo error.
  String? get errorMessage => _errorMessage;

  /// `true` cuando hay una petición en curso.
  bool get isLoading => _requestState == RequestState.loading;

  /// `true` cuando la última petición falló.
  bool get hasError => _requestState == RequestState.error;

  /// Ejecuta [action] manejando automáticamente los estados de carga y error.
  ///
  /// Actualiza [requestState] a `loading` antes de ejecutar, luego a `success`
  /// o `error` según el resultado. Si el error es [ApiException], extrae
  /// el mensaje amigable; de lo contrario usa un mensaje genérico.
  Future<T?> executeRequest<T>(Future<T> Function() action) async {
    _requestState = RequestState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await action();
      _requestState = RequestState.success;
      notifyListeners();
      return result;
    } on ApiException catch (e) {
      _requestState = RequestState.error;
      _errorMessage = e.userFriendlyMessage;
      notifyListeners();
      return null;
    } catch (e) {
      _requestState = RequestState.error;
      _errorMessage = 'Ocurrió un error inesperado. Intenta de nuevo.';
      debugPrint('Error no esperado en executeRequest: $e');
      notifyListeners();
      return null;
    }
  }

  /// Resetea el estado a [RequestState.idle] limpiando cualquier error previo.
  void resetState() {
    _requestState = RequestState.idle;
    _errorMessage = null;
    notifyListeners();
  }
}
