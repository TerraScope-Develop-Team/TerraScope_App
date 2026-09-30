import 'dart:convert';
import '../config/auth_http.dart' as http;
import 'package:terrascope/config/api_config.dart';

class AuthService {
  final String baseUrl = '${ApiConfig.baseUrl}/usuarios';

  /// 🔹 LOGIN (valida usuario por email y contraseña)
  Future<Map<String, dynamic>?> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email_usuario': email,
          'contrasenia_usuario': password,
        }),
      );

      if (response.statusCode == 200) {
        final userData = json.decode(response.body);
        print('✅ Usuario autenticado: $userData');
        return userData;
      } else {
        print('⚠️ Usuario no encontrado o credenciales inválidas. Status: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('⚠️ Error al iniciar sesión: $e');
      return null;
    }
  }

  /// 🔹 CREAR USUARIO
  Future<bool> crearUsuario(Map<String, dynamic> usuarioData) async {
    try {
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(usuarioData),
      );

      return response.statusCode == 201;
    } catch (e) {
      print('Error al crear usuario: $e');
      return false;
    }
  }

  /// 🔹 OBTENER TODOS LOS USUARIOS
  Future<List<dynamic>> obtenerUsuarios() async {
    try {
      final response = await http.get(Uri.parse(baseUrl));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print('Error al obtener usuarios: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error al obtener usuarios: $e');
      return [];
    }
  }

  /// 🔹 OBTENER USUARIO POR ID
  Future<Map<String, dynamic>?> obtenerUsuarioPorId(String id) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/$id'));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print('Usuario no encontrado (${response.statusCode})');
        return null;
      }
    } catch (e) {
      print('Error al obtener usuario por ID: $e');
      return null;
    }
  }

  /// 🔹 ACTUALIZAR USUARIO
  Future<bool> actualizarUsuario(
    String id,
    Map<String, dynamic> datosActualizados,
  ) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/$id'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(datosActualizados),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error al actualizar usuario: $e');
      return false;
    }
  }

  /// 🔹 ELIMINAR USUARIO
  Future<bool> eliminarUsuario(String id) async {
    try {
      final response = await http.delete(Uri.parse('$baseUrl/$id'));
      return response.statusCode == 200;
    } catch (e) {
      print('Error al eliminar usuario: $e');
      return false;
    }
  }

  Future<bool> seleccionarTituloActivo(String usuarioId, String logroId) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/titulo-activo'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'usuarioId': usuarioId, 'logroId': logroId}),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Error al seleccionar título: $e');
      return false;
    }
  }

  /// Quitar título activo
  Future<bool> quitarTituloActivo(String usuarioId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/titulo-activo'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'usuarioId': usuarioId}),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Error al quitar título: $e');
      return false;
    }
  }

  /// Seguir usuario (POST /usuarios/:id/seguir)
  Future<Map<String, dynamic>?> seguirUsuario(String targetUserId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/$targetUserId/seguir'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('Error al seguir usuario: $e');
      return null;
    }
  }

  /// Dejar de seguir usuario (POST /usuarios/:id/dejar-seguir)
  Future<Map<String, dynamic>?> dejarDeSeguirUsuario(String targetUserId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/$targetUserId/dejar-seguir'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('Error al dejar de seguir usuario: $e');
      return null;
    }
  }

  /// Obtener seguidores (GET /usuarios/:id/seguidores)
  Future<List<dynamic>> obtenerSeguidores(String userId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/$userId/seguidores'));
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is Map && decoded.containsKey('seguidores')) {
          return decoded['seguidores'];
        } else if (decoded is List) {
          return decoded;
        }
      }
      return [];
    } catch (e) {
      print('Error al obtener seguidores: $e');
      return [];
    }
  }

  /// Obtener seguidos (GET /usuarios/:id/seguidos)
  Future<List<dynamic>> obtenerSeguidos(String userId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/$userId/seguidos'));
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is Map && decoded.containsKey('seguidos')) {
          return decoded['seguidos'];
        } else if (decoded is List) {
          return decoded;
        }
      }
      return [];
    } catch (e) {
      print('Error al obtener seguidos: $e');
      return [];
    }
  }
}
