import 'dart:convert';

import '../config/api_config.dart';
import 'api_client.dart';

class AuthService {
  final String baseUrl = '${ApiConfig.baseUrl}/usuarios';

  /// LOGIN (valida usuario por email y contrasena)
  ///
  /// Retorna los datos del usuario si las credenciales son correctas,
  /// o `null` si son invalidas (400/401).
  Future<Map<String, dynamic>?> login(String email, String password) async {
    final response = await ApiClient.post(
      Uri.parse('$baseUrl/login'),
      body: json.encode({
        'email_usuario': email,
        'contrasenia_usuario': password,
      }),
      allowedCodes: [200, 400, 401],
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    return null;
  }

  /// Crear usuario
  Future<bool> crearUsuario(Map<String, dynamic> usuarioData) async {
    final response = await ApiClient.post(
      Uri.parse(baseUrl),
      body: json.encode(usuarioData),
      allowedCodes: [201],
    );
    return response.statusCode == 201;
  }

  /// Obtener todos los usuarios
  Future<List<dynamic>> obtenerUsuarios() async {
    final response = await ApiClient.get(Uri.parse(baseUrl));
    return json.decode(response.body);
  }

  /// Obtener usuario por ID
  ///
  /// Retorna `null` si no se encuentra (404).
  Future<Map<String, dynamic>?> obtenerUsuarioPorId(String id) async {
    final response = await ApiClient.get(
      Uri.parse('$baseUrl/$id'),
      allowedCodes: [200, 404],
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    return null;
  }

  /// Actualizar usuario
  Future<bool> actualizarUsuario(
    String id,
    Map<String, dynamic> datosActualizados,
  ) async {
    final response = await ApiClient.patch(
      Uri.parse('$baseUrl/$id'),
      body: json.encode(datosActualizados),
    );
    return response.statusCode == 200;
  }

  /// Eliminar usuario
  Future<bool> eliminarUsuario(String id) async {
    final response = await ApiClient.delete(Uri.parse('$baseUrl/$id'));
    return response.statusCode == 200;
  }

  /// Seleccionar titulo activo de logro
  Future<bool> seleccionarTituloActivo(String usuarioId, String logroId) async {
    final response = await ApiClient.patch(
      Uri.parse('$baseUrl/titulo-activo'),
      body: json.encode({'usuarioId': usuarioId, 'logroId': logroId}),
    );
    return response.statusCode == 200;
  }

  /// Quitar titulo activo
  Future<bool> quitarTituloActivo(String usuarioId) async {
    final response = await ApiClient.delete(
      Uri.parse('$baseUrl/titulo-activo'),
      body: json.encode({'usuarioId': usuarioId}),
    );
    return response.statusCode == 200;
  }

  /// Seguir usuario (POST /usuarios/:id/seguir)
  Future<Map<String, dynamic>?> seguirUsuario(String targetUserId) async {
    final response = await ApiClient.post(
      Uri.parse('$baseUrl/$targetUserId/seguir'),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    }
    return null;
  }

  /// Dejar de seguir usuario (POST /usuarios/:id/dejar-seguir)
  Future<Map<String, dynamic>?> dejarDeSeguirUsuario(
    String targetUserId,
  ) async {
    final response = await ApiClient.post(
      Uri.parse('$baseUrl/$targetUserId/dejar-seguir'),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    }
    return null;
  }

  /// Obtener seguidores (GET /usuarios/:id/seguidores)
  Future<List<dynamic>> obtenerSeguidores(String userId) async {
    final response = await ApiClient.get(
      Uri.parse('$baseUrl/$userId/seguidores'),
    );

    final decoded = json.decode(response.body);
    if (decoded is Map && decoded.containsKey('seguidores')) {
      return decoded['seguidores'];
    } else if (decoded is List) {
      return decoded;
    }
    return [];
  }

  /// Obtener seguidos (GET /usuarios/:id/seguidos)
  Future<List<dynamic>> obtenerSeguidos(String userId) async {
    final response = await ApiClient.get(
      Uri.parse('$baseUrl/$userId/seguidos'),
    );

    final decoded = json.decode(response.body);
    if (decoded is Map && decoded.containsKey('seguidos')) {
      return decoded['seguidos'];
    } else if (decoded is List) {
      return decoded;
    }
    return [];
  }
}
