class Comentario {
  final String? id;
  final String? idUsuario;
  final String nombreUsuario;
  final String? imagenPerfil;
  final String comentario;
  final DateTime fecha;

  Comentario({
    this.id,
    this.idUsuario,
    required this.nombreUsuario,
    this.imagenPerfil,
    required this.comentario,
    required this.fecha,
  });

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    'id_usuario': idUsuario,
    'nombre_usuario': nombreUsuario,
    if (imagenPerfil != null) 'imagen_perfil': imagenPerfil,
    'comentario': comentario,
    'fecha': fecha.toIso8601String(),
  };

  factory Comentario.fromJson(Map<String, dynamic> json) {
    return Comentario(
      id: json['id']?.toString() ?? json['_id']?.toString(),
      idUsuario: json['id_usuario']?.toString(),
      nombreUsuario: json['nombre_usuario'] ?? '',
      imagenPerfil: json['imagen_perfil']?.toString(),
      comentario: json['comentario'] ?? '',
      fecha: json['fecha'] != null
          ? DateTime.tryParse(json['fecha'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  String get fechaFormateada {
    return '${fecha.day}/${fecha.month}/${fecha.year}';
  }

  @override
  String toString() {
    return 'Comentario(id: $id, usuario: $nombreUsuario, fecha: $fechaFormateada)';
  }
}
