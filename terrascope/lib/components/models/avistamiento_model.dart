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
  final List<String> likes;
  final int totalLikes;
  final bool userHasLiked;
  final int totalComentarios;

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
    this.likes = const [],
    this.totalLikes = 0,
    this.userHasLiked = false,
    this.totalComentarios = 0,
  }) : validacion = validacion ?? Validacion();

  factory Avistamiento.fromJson(Map<String, dynamic> json) {
    final rawLikes = (json['likes'] as List?)
            ?.map((e) => e.toString())
            .toList() ??
        <String>[];

    final calculatedLikes = json['total_likes'] is num
        ? (json['total_likes'] as num).toInt()
        : rawLikes.length;

    final parsedComentarios = (json['comentarios'] as List?)
            ?.map((c) => Comentario.fromJson(c is Map<String, dynamic> ? c : {}))
            .toList() ??
        <Comentario>[];

    final calculatedComentarios = json['total_comentarios'] is num
        ? (json['total_comentarios'] as num).toInt()
        : parsedComentarios.length;

    return Avistamiento(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      idUsuario: json['id_usuario']?.toString(),
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
      comentarios: parsedComentarios,
      validacion: Validacion.fromJson(json['validacion'] ?? {}),
      likes: rawLikes,
      totalLikes: calculatedLikes,
      userHasLiked: json['user_has_liked'] == true,
      totalComentarios: calculatedComentarios,
    );
  }

  Avistamiento copyWith({
    String? id,
    String? idUsuario,
    String? nombreComun,
    String? nombreCientifico,
    String? especie,
    String? descripcion,
    String? imagen,
    Ubicacion? ubicacion,
    String? comportamiento,
    String? estadoExtincion,
    String? estadoEspecimen,
    Habitat? habitat,
    List<Comentario>? comentarios,
    String? tipo,
    String? nombreUsuario,
    Validacion? validacion,
    List<String>? likes,
    int? totalLikes,
    bool? userHasLiked,
    int? totalComentarios,
  }) {
    return Avistamiento(
      id: id ?? this.id,
      idUsuario: idUsuario ?? this.idUsuario,
      nombreComun: nombreComun ?? this.nombreComun,
      nombreCientifico: nombreCientifico ?? this.nombreCientifico,
      especie: especie ?? this.especie,
      descripcion: descripcion ?? this.descripcion,
      imagen: imagen ?? this.imagen,
      ubicacion: ubicacion ?? this.ubicacion,
      comportamiento: comportamiento ?? this.comportamiento,
      estadoExtincion: estadoExtincion ?? this.estadoExtincion,
      estadoEspecimen: estadoEspecimen ?? this.estadoEspecimen,
      habitat: habitat ?? this.habitat,
      comentarios: comentarios ?? this.comentarios,
      tipo: tipo ?? this.tipo,
      nombreUsuario: nombreUsuario ?? this.nombreUsuario,
      validacion: validacion ?? this.validacion,
      likes: likes ?? this.likes,
      totalLikes: totalLikes ?? this.totalLikes,
      userHasLiked: userHasLiked ?? this.userHasLiked,
      totalComentarios: totalComentarios ?? this.totalComentarios,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'id': id,
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
      'likes': likes,
      'total_likes': totalLikes,
      'user_has_liked': userHasLiked,
      'total_comentarios': totalComentarios,
    };
  }

  @override
  String toString() {
    return 'Avistamiento(id: $id, usuario: $nombreUsuario, likes: $totalLikes, comentarios: $totalComentarios)';
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
