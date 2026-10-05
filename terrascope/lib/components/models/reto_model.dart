class Reto {
  final String id;
  final String nombreReto;
  final String descripcionReto;
  final DateTime? fechaInicio;
  final DateTime? fechaFinal;
  final Map<String, int> condiciones;
  final List<String> usuariosInscritos;
  final List<UsuarioFinalizado> usuariosFinalizados;
  final String estado;
  final bool esTemporal;

  Reto({
    required this.id,
    required this.nombreReto,
    required this.descripcionReto,
    this.fechaInicio,
    this.fechaFinal,
    required this.condiciones,
    required this.usuariosInscritos,
    required this.usuariosFinalizados,
    required this.estado,
    required this.esTemporal,
  });

  factory Reto.fromJson(Map<String, dynamic> json) {
    final rawConditions = json['condiciones'];
    final conditions = <String, int>{};

    void flattenConditions(Map<String, dynamic> values, String prefix) {
      for (final entry in values.entries) {
        final key = prefix.isEmpty ? entry.key : '$prefix.${entry.key}';
        final value = entry.value;
        if (value is Map) {
          flattenConditions(Map<String, dynamic>.from(value), key);
        } else if (value is num) {
          conditions[key] = value.toInt();
        } else {
          throw FormatException(
            'La condición "$key" debe tener un valor numérico.',
          );
        }
      }
    }

    if (rawConditions is Map) {
      flattenConditions(Map<String, dynamic>.from(rawConditions), '');
    } else if (rawConditions != null) {
      throw const FormatException(
        'Las condiciones del reto deben ser un objeto JSON.',
      );
    }

    return Reto(
      id: (json['id'] ?? json['_id'])?.toString() ?? '',
      nombreReto: json['nombre_reto'] ?? '',
      descripcionReto: json['descripcion_reto'] ?? '',
      fechaInicio: json['fecha_inicio'] != null
          ? DateTime.parse(json['fecha_inicio'])
          : null,
      fechaFinal: json['fecha_final'] != null
          ? DateTime.parse(json['fecha_final'])
          : null,
      condiciones: conditions,
      usuariosInscritos: (json['usuarios_inscritos'] as List? ?? [])
          .map((usuarioId) => usuarioId.toString())
          .toList(),
      usuariosFinalizados:
          (json['usuarios_finalizados'] as List?)
              ?.map((u) => UsuarioFinalizado.fromJson(u))
              .toList() ??
          [],
      estado: json['estado'] ?? 'activo',
      esTemporal: json['es_temporal'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'nombre_reto': nombreReto,
      'descripcion_reto': descripcionReto,
      'fecha_inicio': fechaInicio?.toIso8601String(),
      'fecha_final': fechaFinal?.toIso8601String(),
      'condiciones': condiciones,
      'usuarios_inscritos': usuariosInscritos,
      'usuarios_finalizados': usuariosFinalizados
          .map((u) => u.toJson())
          .toList(),
      'estado': estado,
      'es_temporal': esTemporal,
    };
  }
}

class UsuarioFinalizado {
  final String usuarioId;
  final DateTime fechaCompletado;
  final int posicion;

  UsuarioFinalizado({
    required this.usuarioId,
    required this.fechaCompletado,
    required this.posicion,
  });

  factory UsuarioFinalizado.fromJson(Map<String, dynamic> json) {
    return UsuarioFinalizado(
      usuarioId: json['usuario_id'] ?? '',
      fechaCompletado: DateTime.parse(json['fecha_completado']),
      posicion: json['posicion'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'usuario_id': usuarioId,
      'fecha_completado': fechaCompletado.toIso8601String(),
      'posicion': posicion,
    };
  }
}

class Logro {
  final String id;
  final String idRetoBase;
  final String nombreLogro;
  final String descripcionTitulo;
  final DateTime fechaObtencion;
  final bool esMostrado;

  Logro({
    required this.id,
    required this.idRetoBase,
    required this.nombreLogro,
    required this.descripcionTitulo,
    required this.fechaObtencion,
    required this.esMostrado,
  });

  factory Logro.fromJson(Map<String, dynamic> json) {
    // Handle id_reto_base being either a string or an object (when populated)
    String idRetoBaseValue;
    if (json['id_reto_base'] is Map) {
      idRetoBaseValue = json['id_reto_base']['_id'] ?? '';
    } else {
      idRetoBaseValue = json['id_reto_base'] ?? '';
    }

    return Logro(
      id: json['_id'] ?? '',
      idRetoBase: idRetoBaseValue,
      nombreLogro: json['nombre_logro'] ?? '',
      descripcionTitulo: json['descripcion_titulo'] ?? '',
      fechaObtencion: DateTime.parse(json['fecha_obtencion']),
      esMostrado: json['es_mostrado'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'id_reto_base': idRetoBase,
      'nombre_logro': nombreLogro,
      'descripcion_titulo': descripcionTitulo,
      'fecha_obtencion': fechaObtencion.toIso8601String(),
      'es_mostrado': esMostrado,
    };
  }
}

class ProgresoReto {
  final int actual;
  final int requerido;
  final double porcentaje;

  ProgresoReto({
    required this.actual,
    required this.requerido,
    required this.porcentaje,
  });

  factory ProgresoReto.fromJson(Map<String, dynamic> json) {
    return ProgresoReto(
      actual: json['actual'] ?? 0,
      requerido: json['requerido'] ?? 0,
      porcentaje: (json['porcentaje'] ?? 0).toDouble(),
    );
  }
}
