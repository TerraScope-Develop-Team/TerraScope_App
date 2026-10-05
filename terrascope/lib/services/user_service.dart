import 'dart:convert';
import '../config/auth_http.dart' as http;
import '../config/api_config.dart';
import '../components/models/usuario_model.dart';

class ApiService {
  static const String baseUrl = ApiConfig.baseUrl;

  // Obtener todos los usuarios
  static Future<List<dynamic>> getUsuarios() async {
    final response = await http.get(Uri.parse('$baseUrl/usuarios'));

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Error al cargar usuarios');
    }
  }

  static Future<List<dynamic>> getFaunaFlora() async {
    final response = await http.get(Uri.parse('$baseUrl/fauna-flora'));

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Error al cargar fauna/flora');
    }
  }

  /// Obtener perfil de usuario (con métricas sociales)
  static Future<UsuarioPerfil> getPerfilUsuario(String userId) async {
    final response = await http.get(Uri.parse('$baseUrl/usuarios/$userId'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body) as Map<String, dynamic>;
      return UsuarioPerfil.fromJson(data);
    } else {
      throw Exception('Error al cargar perfil de usuario: ${response.statusCode}');
    }
  }

  /// Seguir a un usuario (POST /usuarios/:id/seguir)
  static Future<Map<String, dynamic>> seguirUsuario(String targetUserId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/usuarios/$targetUserId/seguir'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Error al seguir usuario: ${response.body}');
    }
  }

  /// Dejar de seguir a un usuario (POST /usuarios/:id/dejar-seguir)
  static Future<Map<String, dynamic>> dejarDeSeguirUsuario(String targetUserId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/usuarios/$targetUserId/dejar-seguir'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Error al dejar de seguir usuario: ${response.body}');
    }
  }

  /// Obtener lista de seguidores (GET /usuarios/:id/seguidores)
  static Future<List<UsuarioResumen>> getSeguidores(String userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/usuarios/$userId/seguidores'),
    );

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      List<dynamic> list = [];
      if (decoded is Map && decoded.containsKey('seguidores')) {
        list = decoded['seguidores'];
      } else if (decoded is List) {
        list = decoded;
      }
      return list
          .map((item) => UsuarioResumen.fromJson(item as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception('Error al cargar seguidores: ${response.statusCode}');
    }
  }

  /// Obtener lista de usuarios seguidos (GET /usuarios/:id/seguidos)
  static Future<List<UsuarioResumen>> getSeguidos(String userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/usuarios/$userId/seguidos'),
    );

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      List<dynamic> list = [];
      if (decoded is Map && decoded.containsKey('seguidos')) {
        list = decoded['seguidos'];
      } else if (decoded is List) {
        list = decoded;
      }
      return list
          .map((item) => UsuarioResumen.fromJson(item as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception('Error al cargar seguidos: ${response.statusCode}');
    }
  }
}
