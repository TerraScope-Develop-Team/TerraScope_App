import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class SessionService {
  static const String _keyUserData = 'user_data';
  static const String _keyIsLoggedIn = 'is_logged_in';
  static const String _keyToken = 'auth_token';

  /// Guardar sesión del usuario
  Future<bool> saveSession(Map<String, dynamic> userData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyUserData, json.encode(userData));
      final token = userData['token'] as String?;
      if (token == null || token.isEmpty) {
        return false;
      }
      await prefs.setString(_keyToken, token);
      await prefs.setBool(_keyIsLoggedIn, true);
      return true;
    } catch (e) {
      print('Error al guardar sesión: $e');
      return false;
    }
  }

  Future<String?> getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyToken);
    } catch (e) {
      print('Error al obtener el token: $e');
      return null;
    }
  }

  /// Obtener datos del usuario actual
  Future<Map<String, dynamic>?> getUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataString = prefs.getString(_keyUserData);

      if (userDataString != null) {
        return json.decode(userDataString) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('Error al obtener datos del usuario: $e');
      return null;
    }
  }

  /// Obtener solo el nombre del usuario
  Future<String?> getUserName() async {
    final userData = await getUserData();
    return userData?['nombre_usuario'] as String?;
  }
Future<String?> getUserId() async {
  final userData = await getUserData();
  return userData?['_id'] as String?;
}
  /// Obtener solo el email del usuario
  Future<String?> getUserEmail() async {
    final userData = await getUserData();
    return userData?['email_usuario'] as String?;
  }

  /// Verificar si hay sesión activa
  Future<bool> isLoggedIn() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_keyIsLoggedIn) ?? false;
    } catch (e) {
      print('Error al verificar sesión: $e');
      return false;
    }
  }

  /// Cerrar sesión
  Future<bool> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyUserData);
      await prefs.remove(_keyToken);
      await prefs.setBool(_keyIsLoggedIn, false);
      return true;
    } catch (e) {
      print('Error al cerrar sesión: $e');
      return false;
    }
  }

  /// Actualizar datos del usuario
  Future<bool> updateUserData(Map<String, dynamic> newData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentData = await getUserData();

      if (currentData != null) {
        final updatedData = {...currentData, ...newData};
        await prefs.setString(_keyUserData, json.encode(updatedData));
        return true;
      }
      return false;
    } catch (e) {
      print('Error al actualizar datos del usuario: $e');
      return false;
    }
  }
}
