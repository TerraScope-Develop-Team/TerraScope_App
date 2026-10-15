import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import 'api_exception.dart';
import 'session_service.dart';

/// Cliente HTTP centralizado para toda la aplicación.
///
/// Responsabilidades:
/// - Inyectar automáticamente el token JWT en peticiones a la API.
/// - Agregar `Content-Type: application/json` en métodos con cuerpo.
/// - Validar el código de respuesta y lanzar [ApiException] si corresponde.
/// - Cerrar sesión automáticamente ante un 401.
class ApiClient {
  static final SessionService _sessionService = SessionService();
  static final http.Client _inner = http.Client();

  // --- Helpers internos ------------------------------------------------

  /// Determina si la [uri] apunta al backend propio de TerraScope.
  static bool _isApiRequest(Uri uri) {
    final apiUri = Uri.parse(ApiConfig.baseUrl);
    final apiPath = apiUri.path.replaceFirst(RegExp(r'/$'), '');
    return uri.scheme == apiUri.scheme &&
        uri.host == apiUri.host &&
        uri.port == apiUri.port &&
        (uri.path == apiPath || uri.path.startsWith('$apiPath/'));
  }

  /// Construye los headers fusionando los proporcionados, el token JWT
  /// (si aplica) y Content-Type para métodos con cuerpo.
  static Future<Map<String, String>> _buildHeaders(
    Uri uri,
    Map<String, String>? extra, {
    bool withContentType = false,
  }) async {
    final headers = <String, String>{...?extra};

    if (withContentType && !headers.containsKey('Content-Type')) {
      headers['Content-Type'] = 'application/json';
    }

    if (!_isApiRequest(uri)) return headers;

    final token = await _sessionService.getToken();
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  /// Valida la respuesta HTTP y lanza [ApiException] si no es exitosa.
  /// /// Si [allowedCodes] no es `null`, solo esos códigos se consideran exitosos.
  /// Por defecto acepta cualquier 2xx.
  static http.Response _validate(
    http.Response response, {
    String? endpoint,
    List<int>? allowedCodes,
  }) {
    final code = response.statusCode;
    final isOk = allowedCodes != null
        ? allowedCodes.contains(code)
        : (code >= 200 && code < 300);

    if (isOk) return response;

    // Sesion expirada: cerrar sesión sin esperar
    if (code == 401) {
      _sessionService.logout();
    }

    throw ApiException.fromResponse(
      statusCode: code,
      body: response.body,
      endpoint: endpoint,
    );
  }

  /// Envuelve la petición real para capturar errores de red.
  static Future<http.Response> _safeRequest(
    Future<http.Response> Function() request, {
    String? endpoint,
  }) async {
    try {
      return await request();
    } on ApiException {
      rethrow;
    } on SocketException catch (e) {
      throw NetworkException(message: e.message, endpoint: endpoint);
    } on http.ClientException catch (e) {
      throw NetworkException(message: e.message, endpoint: endpoint);
    } on FormatException catch (e) {
      throw ApiException(message: 'Respuesta mal formada: ${e.message}', endpoint: endpoint);
    } catch (e) {
      throw NetworkException(message: e.toString(), endpoint: endpoint);
    }
  }

  // --- Métodos HTTP públicos -------------------------------------------

  /// Realiza una petición GET.
  /// /// Lanza [ApiException] si la respuesta no es exitosa.
  static Future<http.Response> get(
    Uri uri, {
    Map<String, String>? headers,
    List<int>? allowedCodes,
  }) async {
    return _safeRequest(
      () async {
        final h = await _buildHeaders(uri, headers);
        final response = await _inner.get(uri, headers: h);
        return _validate(response, endpoint: uri.toString(), allowedCodes: allowedCodes);
      },
      endpoint: uri.toString(),
    );
  }

  /// Realiza una petición POST.
  /// /// Agrega `Content-Type: application/json` automáticamente si no se provee.
  static Future<http.Response> post(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
    List<int>? allowedCodes,
  }) async {
    return _safeRequest(
      () async {
        final h = await _buildHeaders(uri, headers, withContentType: true);
        final response = await _inner.post(uri, headers: h, body: body);
        return _validate(response, endpoint: uri.toString(), allowedCodes: allowedCodes);
      },
      endpoint: uri.toString(),
    );
  }

  /// Realiza una petición PUT.
  static Future<http.Response> put(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
    List<int>? allowedCodes,
  }) async {
    return _safeRequest(
      () async {
        final h = await _buildHeaders(uri, headers, withContentType: true);
        final response = await _inner.put(uri, headers: h, body: body);
        return _validate(response, endpoint: uri.toString(), allowedCodes: allowedCodes);
      },
      endpoint: uri.toString(),
    );
  }

  /// Realiza una petición PATCH.
  static Future<http.Response> patch(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
    List<int>? allowedCodes,
  }) async {
    return _safeRequest(
      () async {
        final h = await _buildHeaders(uri, headers, withContentType: true);
        final response = await _inner.patch(uri, headers: h, body: body);
        return _validate(response, endpoint: uri.toString(), allowedCodes: allowedCodes);
      },
      endpoint: uri.toString(),
    );
  }

  /// Realiza una petición DELETE.
  static Future<http.Response> delete(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
    List<int>? allowedCodes,
  }) async {
    return _safeRequest(
      () async {
        final h = await _buildHeaders(uri, headers, withContentType: true);
        final response = await _inner.delete(uri, headers: h, body: body);
        return _validate(response, endpoint: uri.toString(), allowedCodes: allowedCodes);
      },
      endpoint: uri.toString(),
    );
  }
}
