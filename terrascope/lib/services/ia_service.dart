import 'dart:convert';

import '../config/api_config.dart';
import 'api_client.dart';

class IAService {
  /// Envia una imagen en base64 al backend para identificar la especie.
  /// Devuelve un mapa con el nombre cientifico, comun y el nivel de confianza.
  static Future<Map<String, dynamic>> identificarEspecie(
    String imagenBase64,
  ) async {
    final response = await ApiClient.post(
      Uri.parse('${ApiConfig.baseUrl}/ia/identificar'),
      body: json.encode({'imagen': imagenBase64}),
    );

    final data = json.decode(response.body);
    return {
      'nombre_cientifico': data['nombre_cientifico'] ?? 'Desconocido',
      'nombre_comun': data['nombre_comun'] ?? 'Desconocido',
      'nivel_confianza': data['nivel_confianza'] ?? 'Desconocido',
    };
  }

  /// Envia los datos del registro de fauna o flora al backend para validacion
  /// contextual con IA.
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
    final response = await ApiClient.post(
      Uri.parse('${ApiConfig.baseUrl}/ia/validar-registro'),
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

    final data = json.decode(response.body);
    return {
      'es_coherente': data['es_coherente'] ?? false,
      'errores_detectados': List<String>.from(
        data['errores_detectados'] ?? [],
      ),
      'sugerencia': data['sugerencia'] ?? 'No se recibio sugerencia',
    };
  }
}
