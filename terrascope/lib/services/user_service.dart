import 'dart:convert';

import '../components/models/usuario_model.dart';
import '../config/api_config.dart';
import 'api_client.dart';
import 'api_response.dart';

/// Servicio para operaciones de perfil y relaciones sociales de usuario.
///
/// Consolidado de la antigua clase `ApiService` en `user_service.dart`.
/// Las operaciones CRUD basicas de usuario estan en [AuthService].
class UserService {
  static const String baseUrl = ApiConfig.baseUrl;

  /// Obtener todos los usuarios
  static Future<List<dynamic>> getUsuarios() async {
    final response = await ApiClient.get(
      Uri.parse('$baseUrl/usuarios'),
    );
    return json.decode(response.body);
  }

  /// Obtener todos los registros de fauna/flora
  static Future<List<dynamic>> getFaunaFlora() async {
    final response = await ApiClient.get(
      Uri.parse('$baseUrl/fauna-flora'),
    );
    return json.decode(response.body);
  }

  /// Obtener perfil de usuario (con metricas sociales)
  static Future<UsuarioPerfil> getPerfilUsuario(String userId) async {
    final response = await ApiClient.get(
      Uri.parse('$baseUrl/usuarios/$userId'),
    );
    final data = json.decode(response.body) as Map<String, dynamic>;
    return UsuarioPerfil.fromJson(data);
  }

  /// Seguir a un usuario (POST /usuarios/:id/seguir)
  static Future<Map<String, dynamic>> seguirUsuario(
    String targetUserId,
  ) async {
    final response = await ApiClient.post(
      Uri.parse('$baseUrl/usuarios/$targetUserId/seguir'),
    );
    return json.decode(response.body) as Map<String, dynamic>;
  }

  /// Dejar de seguir a un usuario (POST /usuarios/:id/dejar-seguir)
  static Future<Map<String, dynamic>> dejarDeSeguirUsuario(
    String targetUserId,
  ) async {
    final response = await ApiClient.post(
      Uri.parse('$baseUrl/usuarios/$targetUserId/dejar-seguir'),
    );
    return json.decode(response.body) as Map<String, dynamic>;
  }

  /// Obtener lista de seguidores (GET /usuarios/:id/seguidores)
  static Future<List<UsuarioResumen>> getSeguidores(String userId) async {
    final response = await ApiClient.get(
      Uri.parse('$baseUrl/usuarios/$userId/seguidores'),
    );

    final dataList = ApiResponse.extractList(
      response.body,
      listKey: 'seguidores',
    );
    return dataList
        .map((item) => UsuarioResumen.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// Obtener lista de usuarios seguidos (GET /usuarios/:id/seguidos)
  static Future<List<UsuarioResumen>> getSeguidos(String userId) async {
    final response = await ApiClient.get(
      Uri.parse('$baseUrl/usuarios/$userId/seguidos'),
    );

    final dataList = ApiResponse.extractList(
      response.body,
      listKey: 'seguidos',
    );
    return dataList
        .map((item) => UsuarioResumen.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}
