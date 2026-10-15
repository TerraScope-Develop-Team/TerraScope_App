import 'dart:convert';

/// Utilidad para parsear las respuestas de la API de forma consistente.
///
/// Elimina la lógica repetida de verificar si la respuesta es una lista,
/// un mapa con 'data', etc.
class ApiResponse {
  /// Decodifica el [body] de la respuesta y extrae la lista de datos.
  ///
  /// Soporta los siguientes formatos del backend:
  /// - Respuesta directa como `List`
  /// - Objeto con clave `data` (ej: `{"data": [...]}`)
  /// - Objeto con clave personalizada vía [listKey]
  static List<dynamic> extractList(String body, {String? listKey}) {
    final decoded = json.decode(body);

    if (decoded is List) {
      return decoded;
    }

    if (decoded is Map<String, dynamic>) {
      // Priorizar la clave específica si se proporciona
      if (listKey != null && decoded.containsKey(listKey)) {
        final value = decoded[listKey];
        if (value is List) return value;
      }

      // Intentar con 'data' como clave por defecto
      if (decoded.containsKey('data') && decoded['data'] is List) {
        return decoded['data'];
      }

      // Intentar encontrar la primera lista en el mapa
      for (final entry in decoded.entries) {
        if (entry.value is List) {
          return entry.value;
        }
      }
    }

    return [];
  }

  /// Decodifica el [body] y extrae un mapa de datos.
  ///
  /// Soporta respuestas directas como `Map` o anidadas con clave `data`.
  static Map<String, dynamic> extractMap(String body) {
    final decoded = json.decode(body);

    if (decoded is Map<String, dynamic>) {
      if (decoded.containsKey('data') && decoded['data'] is Map) {
        return decoded['data'] as Map<String, dynamic>;
      }
      return decoded;
    }

    return {};
  }

  /// Decodifica el [body] directamente como el tipo esperado.
  static dynamic decode(String body) => json.decode(body);
}
