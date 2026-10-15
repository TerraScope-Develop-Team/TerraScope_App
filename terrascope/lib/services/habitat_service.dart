import 'dart:convert';

import '../components/models/habitat.dart';
import 'api_client.dart';
import 'api_response.dart';

class HabitatService {
  final String baseUrl;

  HabitatService({required this.baseUrl});

  /// Obtener todos los habitats
  Future<List<Habitat>> getAllHabitats() async {
    final response = await ApiClient.get(
      Uri.parse('$baseUrl/habitats'),
    );

    final dataList = ApiResponse.extractList(
      response.body,
      listKey: 'habitats',
    );

    if (dataList.isEmpty) return [];

    return dataList
        .map((json) => Habitat.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Obtener habitat por ID. Retorna `null` si no existe (404).
  Future<Habitat?> getHabitatById(String id) async {
    final response = await ApiClient.get(
      Uri.parse('$baseUrl/habitats/$id'),
      allowedCodes: [200, 404],
    );

    if (response.statusCode == 404) return null;

    final data = ApiResponse.extractMap(response.body);
    return Habitat.fromJson(data);
  }

  /// Crear un nuevo habitat
  Future<Habitat?> createHabitat(Habitat habitat) async {
    final response = await ApiClient.post(
      Uri.parse('$baseUrl/habitats'),
      body: json.encode(habitat.toJson()),
      allowedCodes: [200, 201],
    );

    final jsonData = ApiResponse.extractMap(response.body);
    return Habitat.fromJson(jsonData);
  }

  /// Actualizar habitat
  Future<Habitat?> updateHabitat(
    String id,
    Map<String, dynamic> updates,
  ) async {
    final response = await ApiClient.put(
      Uri.parse('$baseUrl/habitats/$id'),
      body: json.encode(updates),
    );

    final jsonData = ApiResponse.extractMap(response.body);
    return Habitat.fromJson(jsonData);
  }

  /// Eliminar habitat
  Future<bool> deleteHabitat(String id) async {
    final response = await ApiClient.delete(
      Uri.parse('$baseUrl/habitats/$id'),
    );
    return response.statusCode == 200;
  }
}