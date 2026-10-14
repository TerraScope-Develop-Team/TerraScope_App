import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http_types;
import '../config/auth_http.dart' as http;
import '../config/api_config.dart';

class IAService {
  static const Duration _requestTimeout = Duration(seconds: 15);

  static Future<http_types.Response> _postWithTimeout(
    Uri url, {
    required String body,
  }) async {
    try {
      return await http
          .post(url, headers: {'Content-Type': 'application/json'}, body: body)
          .timeout(_requestTimeout);
    } on TimeoutException {
      throw Exception(
        'La solicitud a IA superó los 15 segundos. Inténtalo nuevamente.',
      );
    }
  }

  /// Envía una imagen en base64 al backend para identificar la especie.
  /// Devuelve un mapa con el nombre científico, común y el nivel de confianza.
  static Future<Map<String, dynamic>> identificarEspecie(
    String imagenBase64,
  ) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/ia/identificar');

    final response = await _postWithTimeout(
      url,
      body: json.encode({'imagen': imagenBase64}),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      return {
        'nombre_cientifico': data['nombre_cientifico'] ?? 'Desconocido',
        'nombre_comun': data['nombre_comun'] ?? 'Desconocido',
        'nivel_confianza': data['nivel_confianza'] ?? 'Desconocido',
      };
    } else {
      throw Exception(
        'Error al identificar la especie: ${response.statusCode} - ${response.body}',
      );
    }
  }

  /// Envía los datos del registro de fauna o flora al backend para validación contextual con IA.
  /// Devuelve un mapa con es_coherente, errores_detectados y sugerencia.
  static Future<Map<String, dynamic>> validarRegistro({
    required String nombreComun,
    required String nombreCientifico,
    required String especie,
    required String descripcion,
    required String tipo,
    required String comportamiento,
    required String estadoExtincion,
    required Map<String, dynamic> habitat,
  }) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/ia/validar-registro');

    final response = await _postWithTimeout(
      url,
      body: json.encode({
        'nombre_comun': nombreComun,
        'nombre_cientifico': nombreCientifico,
        'especie': especie,
        'descripcion': descripcion,
        'tipo': tipo,
        'comportamiento': comportamiento,
        'estado_extincion': estadoExtincion,
        'habitat': habitat,
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return {
        'es_coherente': data['es_coherente'] ?? false,
        'errores_detectados': List<String>.from(
          data['errores_detectados'] ?? [],
        ),
        'sugerencia': data['sugerencia'] ?? 'No se recibió sugerencia',
      };
    } else {
      throw Exception(
        'Error al validar registro: ${response.statusCode} - ${response.body}',
      );
    }
  }
}
