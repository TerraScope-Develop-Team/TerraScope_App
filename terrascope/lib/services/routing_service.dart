import 'dart:convert';
import 'package:terrascope/services/api_client.dart' as http;
import 'package:latlong2/latlong.dart';

class RoutingService {
  // Obtener ruta usando OSRM (Open Source Routing Machine)
  static Future<List<LatLng>> getRoute(LatLng start, LatLng end) async {
    try {
      final url =
          'https://router.project-osrm.org/route/v1/driving/${start.longitude},${start.latitude};${end.longitude},${end.latitude}?overview=full&geometries=geojson';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final coordinates =
              data['routes'][0]['geometry']['coordinates'] as List;

          return coordinates.map((coord) {
            return LatLng(coord[1].toDouble(), coord[0].toDouble());
          }).toList();
        }
      }

      return [];
    } catch (e) {
      print('Error obteniendo ruta: $e');
      return [];
    }
  }

  // Calcular distancia entre dos puntos en kilómetros
  static double calculateDistance(LatLng start, LatLng end) {
    const Distance distance = Distance();
    return distance.as(LengthUnit.Kilometer, start, end);
  }
}
