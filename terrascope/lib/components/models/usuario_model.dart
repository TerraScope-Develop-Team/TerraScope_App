class UsuarioResumen {
  final String id;
  final String nombreUsuario;
  final String emailUsuario;
  final String? imagenPerfil;
  final String rol;

  UsuarioResumen({
    required this.id,
    required this.nombreUsuario,
    required this.emailUsuario,
    this.imagenPerfil,
    required this.rol,
  });

  factory UsuarioResumen.fromJson(Map<String, dynamic> json) {
    return UsuarioResumen(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      nombreUsuario: json['nombre_usuario'] ?? '',
      emailUsuario: json['email_usuario'] ?? '',
      imagenPerfil: json['imagen_perfil']?.toString(),
      rol: json['rol']?.toString() ?? 'Usuario',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'nombre_usuario': nombreUsuario,
    'email_usuario': emailUsuario,
    if (imagenPerfil != null) 'imagen_perfil': imagenPerfil,
    'rol': rol,
  };
}

class UsuarioPerfil {
  final String id;
  final String nombreUsuario;
  final String emailUsuario;
  final String? telefonoUsuario;
  final String? fechaNacUsuario;
  final String? imagenPerfil;
  final String rol;
  final int totalSeguidores;
  final int totalSeguidos;
  final bool isFollowing;
  final List<String> seguidores;
  final List<String> seguidos;
  final Map<String, dynamic>? tituloActivo;
  final String? createdAt;

  UsuarioPerfil({
    required this.id,
    required this.nombreUsuario,
    required this.emailUsuario,
    this.telefonoUsuario,
    this.fechaNacUsuario,
    this.imagenPerfil,
    required this.rol,
    this.totalSeguidores = 0,
    this.totalSeguidos = 0,
    this.isFollowing = false,
    this.seguidores = const [],
    this.seguidos = const [],
    this.tituloActivo,
    this.createdAt,
  });

  factory UsuarioPerfil.fromJson(Map<String, dynamic> json) {
    final rawSeguidores = (json['seguidores'] as List?)
            ?.map((e) => e.toString())
            .toList() ??
        <String>[];
    final rawSeguidos = (json['seguidos'] as List?)
            ?.map((e) => e.toString())
            .toList() ??
        <String>[];

    final seguidoresCount = json['total_seguidores'] is num
        ? (json['total_seguidores'] as num).toInt()
        : rawSeguidores.length;
    final seguidosCount = json['total_seguidos'] is num
        ? (json['total_seguidos'] as num).toInt()
        : rawSeguidos.length;

    return UsuarioPerfil(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      nombreUsuario: json['nombre_usuario'] ?? '',
      emailUsuario: json['email_usuario'] ?? '',
      telefonoUsuario: json['telefono_usuario']?.toString(),
      fechaNacUsuario: json['fecha_nac_usuario']?.toString(),
      imagenPerfil: json['imagen_perfil']?.toString(),
      rol: json['rol']?.toString() ?? 'Usuario',
      totalSeguidores: seguidoresCount,
      totalSeguidos: seguidosCount,
      isFollowing: json['is_following'] == true,
      seguidores: rawSeguidores,
      seguidos: rawSeguidos,
      tituloActivo: json['titulo_activo'] is Map<String, dynamic>
          ? json['titulo_activo']
          : null,
      createdAt: json['createdAt']?.toString(),
    );
  }

  UsuarioPerfil copyWith({
    String? id,
    String? nombreUsuario,
    String? emailUsuario,
    String? telefonoUsuario,
    String? fechaNacUsuario,
    String? imagenPerfil,
    String? rol,
    int? totalSeguidores,
    int? totalSeguidos,
    bool? isFollowing,
    List<String>? seguidores,
    List<String>? seguidos,
    Map<String, dynamic>? tituloActivo,
    String? createdAt,
  }) {
    return UsuarioPerfil(
      id: id ?? this.id,
      nombreUsuario: nombreUsuario ?? this.nombreUsuario,
      emailUsuario: emailUsuario ?? this.emailUsuario,
      telefonoUsuario: telefonoUsuario ?? this.telefonoUsuario,
      fechaNacUsuario: fechaNacUsuario ?? this.fechaNacUsuario,
      imagenPerfil: imagenPerfil ?? this.imagenPerfil,
      rol: rol ?? this.rol,
      totalSeguidores: totalSeguidores ?? this.totalSeguidores,
      totalSeguidos: totalSeguidos ?? this.totalSeguidos,
      isFollowing: isFollowing ?? this.isFollowing,
      seguidores: seguidores ?? this.seguidores,
      seguidos: seguidos ?? this.seguidos,
      tituloActivo: tituloActivo ?? this.tituloActivo,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
