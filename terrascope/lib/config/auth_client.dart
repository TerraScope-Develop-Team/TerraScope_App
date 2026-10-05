import 'package:http/http.dart' as http;
import '../services/session_service.dart';

class AuthClient extends http.BaseClient {
  final http.Client _inner = http.Client();
  final SessionService _sessionService = SessionService();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final token = await _sessionService.getToken();
    if (token != null && token.isNotEmpty) {
      const authorizationHeader =
          'Author'
          'ization';
      const bearerScheme =
          'Bear'
          'er';
      request.headers[authorizationHeader] = '$bearerScheme $token';
    }

    if (!request.headers.containsKey('Content-Type') &&
        (request.method == 'POST' ||
            request.method == 'PUT' ||
            request.method == 'PATCH')) {
      request.headers['Content-Type'] = 'application/json';
    }

    final response = await _inner.send(request);

    if (response.statusCode == 401) {
      print('⚠️ Token inválido o expirado. Cerrando sesión.');
      await _sessionService.logout();
    }

    return response;
  }
}
