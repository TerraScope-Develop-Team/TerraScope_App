import 'dart:convert';
import '../config/auth_http.dart' as http;
import '../components/models/habitat.dart';

class HabitatService {
  final String baseUrl;

  HabitatService({required this.baseUrl});

  /// Obtener todos los hábitats
  Future<List<Habitat>> getAllHabitats() async {
    try {
      print('🌐 Haciendo petición a: $baseUrl/habitats');
      
      final response = await http.get(
        Uri.parse('$baseUrl/habitats'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      print('📡 Status code: ${response.statusCode}');
      print('📄 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        print('🔍 Tipo de responseData: ${responseData.runtimeType}');
        
        List<dynamic> dataList;

        // Caso 1: La respuesta es directamente un array
        if (responseData is List) {
          print('✅ Respuesta es List directa');
          dataList = responseData;
        } 
        // Caso 2: La respuesta es un objeto con 'data'
        else if (responseData is Map && responseData.containsKey('data')) {
          print('✅ Respuesta tiene campo "data"');
          dataList = responseData['data'];
        } 
        // Caso 3: La respuesta es un objeto con 'habitats'
        else if (responseData is Map && responseData.containsKey('habitats')) {
          print('✅ Respuesta tiene campo "habitats"');
          dataList = responseData['habitats'];
        }
        // Caso 4: La respuesta es un objeto con 'results'
        else if (responseData is Map && responseData.containsKey('results')) {
          print('✅ Respuesta tiene campo "results"');
          dataList = responseData['results'];
        }
        // Caso 5: La respuesta es un Map, convertir sus valores a lista
        else if (responseData is Map) {
          print('⚠️ Respuesta es Map sin campo conocido');
          print('📋 Claves disponibles: ${responseData.keys}');
          
          // Intentar encontrar el primer valor que sea una lista
          final listEntry = responseData.entries.firstWhere(
            (entry) => entry.value is List,
            orElse: () => throw Exception(
              'No se encontró ninguna lista en la respuesta. Claves: ${responseData.keys}'
            ),
          );
          dataList = listEntry.value;
        }
        else {
          throw Exception(
            'Formato de respuesta no reconocido. Tipo: ${responseData.runtimeType}'
          );
        }

        print('📊 Cantidad de hábitats encontrados: ${dataList.length}');
        
        if (dataList.isEmpty) {
          print('⚠️ La lista de hábitats está vacía');
          return [];
        }

        // Mostrar el primer elemento para debug
        if (dataList.isNotEmpty) {
          print('🔍 Primer elemento: ${dataList[0]}');
        }

        final habitats = dataList
            .map((json) => Habitat.fromJson(json as Map<String, dynamic>))
            .toList();
            
        print('✅ Hábitats parseados correctamente: ${habitats.length}');
        return habitats;
        
      } else {
        throw Exception(
          'Error al obtener hábitats: ${response.statusCode}\nBody: ${response.body}'
        );
      }
    } catch (e, stackTrace) {
      print('❌ Error en getAllHabitats: $e');
      print('📍 Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Obtener hábitat por ID
  Future<Habitat?> getHabitatById(String id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/habitats/$id'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        final data = responseData is Map && responseData.containsKey('data')
            ? responseData['data']
            : responseData;

        return Habitat.fromJson(data as Map<String, dynamic>);
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw Exception('Error al obtener hábitat: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Crear un nuevo hábitat (solo si el usuario tiene permisos)
  Future<Habitat?> createHabitat(Habitat habitat) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/habitats'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(habitat.toJson()),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = json.decode(response.body);
        final jsonData = responseData is Map && responseData.containsKey('data')
            ? responseData['data']
            : responseData;
        return Habitat.fromJson(jsonData as Map<String, dynamic>);
      } else {
        throw Exception('Error al crear hábitat: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Actualizar hábitat
  Future<Habitat?> updateHabitat(String id, Map<String, dynamic> updates) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/habitats/$id'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(updates),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final jsonData = responseData is Map && responseData.containsKey('data')
            ? responseData['data']
            : responseData;
        return Habitat.fromJson(jsonData as Map<String, dynamic>);
      } else {
        throw Exception('Error al actualizar hábitat: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Eliminar hábitat
  Future<bool> deleteHabitat(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/habitats/$id'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception('Error al eliminar hábitat: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }
}