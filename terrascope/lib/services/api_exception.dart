import 'dart:convert';

/// Excepción base para todos los errores de la API.
///
/// Contiene el [statusCode] HTTP, un [message] técnico y el [endpoint]
/// donde ocurrió el error. Usa [userFriendlyMessage] para mostrar al usuario.
class ApiException implements Exception {
  final int? statusCode;
  final String message;
  final String? endpoint;

  const ApiException({
    this.statusCode,
    required this.message,
    this.endpoint,
  });

  /// Mensaje legible para mostrar al usuario en la UI.
  String get userFriendlyMessage {
    if (statusCode == null) {
      return 'No se pudo conectar con el servidor. Revisa tu conexión a internet.';
    }
    return switch (statusCode!) {
      400 => 'La solicitud no es válida. Verifica los datos ingresados.',
      401 => 'Tu sesión ha expirado. Inicia sesión nuevamente.',
      403 => 'No tienes permisos para realizar esta acción.',
      404 => 'El recurso solicitado no fue encontrado.',
      409 => 'Conflicto: el recurso ya existe o fue modificado.',
      422 => 'Los datos enviados no son válidos.',
      429 => 'Demasiadas solicitudes. Intenta de nuevo en unos momentos.',
      >= 500 => 'Error en el servidor. Intenta de nuevo más tarde.',
      _ => 'Ocurrió un error inesperado ($statusCode).',
    };
  }

  /// Construye la excepción apropiada según el código HTTP.
  factory ApiException.fromResponse({
    required int statusCode,
    required String body,
    String? endpoint,
  }) {
    String message = body;
    try {
      final decoded = json.decode(body);
      if (decoded is Map<String, dynamic>) {
        if (decoded['message'] != null) {
          message = decoded['message'].toString();
        } else if (decoded['error'] != null) {
          message = decoded['error'].toString();
        }
      }
    } catch (_) {
      // Si no es JSON válido, usamos el cuerpo crudo como mensaje.
    }

    return switch (statusCode) {
      401 => UnauthorizedException(
          message: message,
          endpoint: endpoint,
        ),
      403 => ForbiddenException(
          message: message,
          endpoint: endpoint,
        ),
      404 => NotFoundException(
          message: message,
          endpoint: endpoint,
        ),
      >= 500 => ServerException(
          statusCode: statusCode,
          message: message,
          endpoint: endpoint,
        ),
      _ => ApiException(
          statusCode: statusCode,
          message: message,
          endpoint: endpoint,
        ),
    };
  }

  @override
  String toString() =>
      'ApiException($statusCode): $message${endpoint != null ? ' [$endpoint]' : ''}';
}

/// Error de conectividad (sin internet, timeout, DNS, etc.).
class NetworkException extends ApiException {
  const NetworkException({
    required super.message,
    super.endpoint,
  }) : super(statusCode: null);

  @override
  String get userFriendlyMessage =>
      'No se pudo conectar con el servidor. Revisa tu conexión a internet.';
}

/// Token inválido o expirado (HTTP 401).
class UnauthorizedException extends ApiException {
  const UnauthorizedException({
    required super.message,
    super.endpoint,
  }) : super(statusCode: 401);

  @override
  String get userFriendlyMessage =>
      'Tu sesión ha expirado. Inicia sesión nuevamente.';
}

/// Sin permisos (HTTP 403).
class ForbiddenException extends ApiException {
  const ForbiddenException({
    required super.message,
    super.endpoint,
  }) : super(statusCode: 403);

  @override
  String get userFriendlyMessage =>
      'No tienes permisos para realizar esta acción.';
}

/// Recurso no encontrado (HTTP 404).
class NotFoundException extends ApiException {
  const NotFoundException({
    required super.message,
    super.endpoint,
  }) : super(statusCode: 404);

  @override
  String get userFriendlyMessage =>
      'El recurso solicitado no fue encontrado.';
}

/// Error del servidor (HTTP 5xx).
class ServerException extends ApiException {
  const ServerException({
    required super.statusCode,
    required super.message,
    super.endpoint,
  });

  @override
  String get userFriendlyMessage =>
      'Error en el servidor. Intenta de nuevo más tarde.';
}
