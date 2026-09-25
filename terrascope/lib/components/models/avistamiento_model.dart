import 'habitat.dart';
import '../models/comentario.dart';
import '../models/validacion_model.dart';

class Avistamiento {
  final String id;
  final String? idUsuario; 
  final String nombreComun;
  final String nombreCientifico;
  final String especie;
  final String descripcion;
  final String imagen;
  final Ubicacion ubicacion;
  final String comportamiento;
  final String estadoExtincion;
  final String estadoEspecimen;
  final Habitat habitat;
  final List<Comentario> comentarios;
  final String tipo;
  final String nombreUsuario;
  final Validacion validacion;

  Avistamiento({
    required this.id,
    this.idUsuario, 
    required this.nombreComun,
    required this.nombreCientifico,
    required this.especie,
    required this.descripcion,
    required this.imagen,
    required this.ubicacion,
    required this.comportamiento,
    required this.estadoExtincion,
    required this.estadoEspecimen,
    required this.habitat,
    required this.comentarios,
    required this.tipo,
    required this.nombreUsuario,
    Validacion? validacion,
  }) : validacion = validacion ?? Validacion();

  factory Avistamiento.fromJson(Map<String, dynamic> json) {
    return Avistamiento(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      idUsuario: json['id_usuario'], 
      nombreComun: json['nombre_comun'] ?? '',
      nombreCientifico: json['nombre_cientifico'] ?? '',
      especie: json['especie'] ?? '',
      descripcion: json['descripcion'] ?? '',
      imagen: json['imagen'] ?? '',
      tipo: json['tipo'] ?? '',
      nombreUsuario: json['nombre_usuario'] ?? '',
      ubicacion: Ubicacion.fromJson(json['ubicacion'] ?? {}),
      comportamiento: json['comportamiento'] ?? '',
      estadoExtincion: json['estado_extincion'] ?? '',
      estadoEspecimen: json['estado_especimen'] ?? '',
      habitat: Habitat.fromJson(json['habitat'] ?? {}),
      comentarios: (json['comentarios'] as List?)
              ?.map((c) => Comentario.fromJson(c))
              .toList() ??
          [],
      validacion: Validacion.fromJson(json['validacion'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'id_usuario': idUsuario, 
      'nombre_comun': nombreComun,
      'nombre_cientifico': nombreCientifico,
      'especie': especie,
      'descripcion': descripcion,
      'imagen': imagen,
      'tipo': tipo,
      'nombre_usuario': nombreUsuario,
      'ubicacion': ubicacion.toJson(),
      'comportamiento': comportamiento,
      'estado_extincion': estadoExtincion,
      'estado_especimen': estadoEspecimen,
      'habitat': habitat.toJson(),
      'validacion': validacion.toJson(),
      'comentarios': comentarios.map((c) => c.toJson()).toList(),
    };
  }

  @override
  String toString() {
    return 'Avistamiento(id: $id, usuario: $nombreUsuario, especie: $especie)';
  }
}

class Ubicacion {
  final double latitud;
  final double longitud;

  Ubicacion({required this.latitud, required this.longitud});

  factory Ubicacion.fromJson(Map<String, dynamic> json) {
    return Ubicacion(
      latitud: (json['latitud'] ?? 0).toDouble(),
      longitud: (json['longitud'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'latitud': latitud, 'longitud': longitud};
  }

  @override
  String toString() => 'Ubicacion(lat: $latitud, lng: $longitud)';
}
