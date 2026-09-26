import 'package:http/http.dart' as http;
import 'package:terrascope/config/api_config.dart';
import 'package:terrascope/services/session_service.dart';

class ApiClient {
  static final SessionService _sessionService = SessionService();

  static Future<Map<String, String>> _headers(
    Uri uri,
    Map<String, String>? headers,
  ) async {
    final result = <String, String>{...?headers};
    final apiUri = Uri.parse(ApiConfig.baseUrl);
    final apiPath = apiUri.path.replaceFirst(RegExp(r'/$'), '');
    final isApiRequest =
        uri.scheme == apiUri.scheme &&
        uri.host == apiUri.host &&
        uri.port == apiUri.port &&
        (uri.path == apiPath || uri.path.startsWith('$apiPath/'));

    if (!isApiRequest) return result;

    final token = await _sessionService.getToken();
    if (token != null && token.isNotEmpty) {
      result['Authorization'] = 'Bearer $token';
    }
    return result;
  }

  static Future<http.Response> get(
    Uri uri, {
    Map<String, String>? headers,
  }) async {
    return http.get(uri, headers: await _headers(uri, headers));
  }

  static Future<http.Response> post(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    return http.post(uri, headers: await _headers(uri, headers), body: body);
  }

  static Future<http.Response> put(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    return http.put(uri, headers: await _headers(uri, headers), body: body);
  }

  static Future<http.Response> patch(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    return http.patch(uri, headers: await _headers(uri, headers), body: body);
  }

  static Future<http.Response> delete(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    return http.delete(uri, headers: await _headers(uri, headers), body: body);
  }
}

Future<http.Response> get(Uri uri, {Map<String, String>? headers}) {
  return ApiClient.get(uri, headers: headers);
}

Future<http.Response> post(
  Uri uri, {
  Map<String, String>? headers,
  Object? body,
}) {
  return ApiClient.post(uri, headers: headers, body: body);
}

Future<http.Response> put(
  Uri uri, {
  Map<String, String>? headers,
  Object? body,
}) {
  return ApiClient.put(uri, headers: headers, body: body);
}

Future<http.Response> patch(
  Uri uri, {
  Map<String, String>? headers,
  Object? body,
}) {
  return ApiClient.patch(uri, headers: headers, body: body);
}

Future<http.Response> delete(
  Uri uri, {
  Map<String, String>? headers,
  Object? body,
}) {
  return ApiClient.delete(uri, headers: headers, body: body);
}
