import 'dart:convert';
import '../config/auth_http.dart' as http;
import '../config/api_config.dart';

class ApiService {
  static const String baseUrl = ApiConfig.baseUrl;

  // obtener todos los usuarios
  static Future<List<dynamic>> getUsuarios() async {
    final response = await http.get(Uri.parse('$baseUrl/usuarios'));

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Error al cargar usuarios');
    }
  }

  static Future<List<dynamic>> getFaunaFlora() async {
    final responde = await http.get(Uri.parse('$baseUrl/fauna-flora'));

    if (responde.statusCode == 200) {
      return json.decode(responde.body);
    } else {
      throw Exception('Error al cargar usuarios');
    }
  }
}
