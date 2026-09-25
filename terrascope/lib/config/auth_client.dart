import 'package:http/http.dart' as http;
import '../services/session_service.dart';

class AuthClient extends http.BaseClient {
  final http.Client _inner = http.Client();
  final SessionService _sessionService = SessionService();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final token = await _sessionService.getToken();
    
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    // Asegurarse de que Content-Type esté presente si es JSON (para no pisar otros)
    if (!request.headers.containsKey('Content-Type') && 
        (request.method == 'POST' || request.method == 'PUT' || request.method == 'PATCH')) {
      request.headers['Content-Type'] = 'application/json';
    }

    final response = await _inner.send(request);

    if (response.statusCode == 401) {
      // Si el token expiró o es inválido, cerrar sesión
      print('⚠️ Token inválido o expirado. Cerrando sesión.');
      await _sessionService.logout();
      // Opcionalmente se puede emitir un evento para redirigir al login
      // Dependiendo de cómo se maneje el estado global.
    }

    return response;
  }
}
