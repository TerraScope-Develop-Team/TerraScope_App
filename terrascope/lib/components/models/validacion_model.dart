class Validacion {
  final String estado;
  final int votosComunidad;
  final int votosPositivos;
  final int votosNegativos;
  final int requeridosComunidad;
  final List<String> usuariosValidadores;
  final List<String> usuariosPositivos;
  final List<String> usuariosNegativos;
  final bool validadoPorExperto;
  final DateTime? fechaInicioVotacion;
  final DateTime? fechaFinVotacion;

  Validacion({
    this.estado = 'pendiente',
    this.votosComunidad = 0,
    int? votosPositivos,
    this.votosNegativos = 0,
    this.requeridosComunidad = 5,
    this.usuariosValidadores = const [],
    this.usuariosPositivos = const [],
    this.usuariosNegativos = const [],
    this.validadoPorExperto = false,
    this.fechaInicioVotacion,
    this.fechaFinVotacion,
  }) : votosPositivos = votosPositivos ?? votosComunidad;

  factory Validacion.fromJson(Map<String, dynamic> json) {
    final rawComunidad = (json['votos_comunidad'] as num?)?.toInt() ?? 0;
    final rawPositivos = (json['votos_positivos'] as num?)?.toInt();
    final rawNegativos = (json['votos_negativos'] as num?)?.toInt() ?? 0;
    final positivos = rawPositivos ?? rawComunidad;

    return Validacion(
      estado: json['estado']?.toString() ?? 'pendiente',
      votosComunidad: positivos,
      votosPositivos: positivos,
      votosNegativos: rawNegativos,
      requeridosComunidad: (json['requeridos_comunidad'] as num?)?.toInt() ?? 5,
      usuariosValidadores: (json['usuarios_validadores'] as List?)
              ?.map((id) => id.toString())
              .toList() ??
          [],
      usuariosPositivos: (json['usuarios_positivos'] as List?)
              ?.map((id) => id.toString())
              .toList() ??
          [],
      usuariosNegativos: (json['usuarios_negativos'] as List?)
              ?.map((id) => id.toString())
              .toList() ??
          [],
      validadoPorExperto: json['validado_por_experto'] == true,
      fechaInicioVotacion: json['fecha_inicio_votacion'] != null
          ? DateTime.tryParse(json['fecha_inicio_votacion'].toString())
          : null,
      fechaFinVotacion: json['fecha_fin_votacion'] != null
          ? DateTime.tryParse(json['fecha_fin_votacion'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'estado': estado,
      'votos_comunidad': votosPositivos,
      'votos_positivos': votosPositivos,
      'votos_negativos': votosNegativos,
      'requeridos_comunidad': requeridosComunidad,
      'usuarios_validadores': usuariosValidadores,
      'usuarios_positivos': usuariosPositivos,
      'usuarios_negativos': usuariosNegativos,
      'validado_por_experto': validadoPorExperto,
      if (fechaInicioVotacion != null)
        'fecha_inicio_votacion': fechaInicioVotacion!.toIso8601String(),
      if (fechaFinVotacion != null)
        'fecha_fin_votacion': fechaFinVotacion!.toIso8601String(),
    };
  }

  // Métodos útiles
  bool get esPendiente => estado == 'pendiente';
  bool get esValidadoComunidad => estado == 'validado_comunidad';
  bool get esValidadoExperto => estado == 'validado_experto';
  bool get esEliminado => estado == 'eliminado';

  int get totalVotos => votosPositivos + votosNegativos;
  bool get tieneMayoriaPositiva => votosPositivos > votosNegativos;
  bool get tieneMayoriaNegativa => votosNegativos > votosPositivos;
  double get proporcionPositiva =>
      totalVotos > 0 ? votosPositivos / totalVotos : 0.0;

  int get votosRestantes => requeridosComunidad - votosPositivos;
  bool get alcanzaVotosComunidad => votosPositivos >= requeridosComunidad;

  @override
  String toString() {
    return 'Validacion(estado: $estado, +$votosPositivos/-$votosNegativos, experto: $validadoPorExperto)';
  }
}