// components/models/habitat.dart
class Habitat {
  final String idHabitat;
  final String nombreHabitat;
  final String descripcionHabitat;

  Habitat({
    required this.idHabitat,
    required this.nombreHabitat,
    required this.descripcionHabitat,
  });

  Map<String, dynamic> toJson() => {
    'id_habitat': idHabitat,
    'nombre_habitat': nombreHabitat,
    'descripcion_habitat': descripcionHabitat,
  };

  factory Habitat.fromJson(Map<String, dynamic> json) {
    // MongoDB retorna '_id' como ObjectId
    final id = (json['_id'] ?? json['id_habitat'])?.toString() ?? '';
    final nombre = json['nombre_habitat'] ?? 'Sin nombre';
    final descripcion = json['descripcion_habitat'] ?? 'Sin descripción';

    // Debug
    print('🔍 Habitat.fromJson - _id: ${json['_id']}, ID capturado: "$id"');

    return Habitat(
      idHabitat: id,
      nombreHabitat: nombre,
      descripcionHabitat: descripcion,
    );
  }

  @override
  String toString() => 'Habitat(id: $idHabitat, nombre: $nombreHabitat)';
}
