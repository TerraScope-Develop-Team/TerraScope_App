import 'package:flutter/material.dart';
import 'package:terrascope/providers/request_state.dart';
import 'package:terrascope/services/ia_service.dart';

class IARegistro with ChangeNotifier, RequestStateMixin {
  // Resultado de validación
  Map<String, dynamic>? _validacionResultado;
  Map<String, dynamic>? get validacionResultado => _validacionResultado;

  // Mensaje de error compatible
  String? get error => errorMessage;

  /// Valida un registro de fauna o flora usando IA
  Future<void> validarRegistro({
    required String nombreComun,
    required String nombreCientifico,
    required String especie,
    required String descripcion,
    required String tipo,
    required String comportamiento,
    required String estadoExtincion,
    required Map<String, dynamic> habitat,
  }) => executeRequest(() async {
    _validacionResultado = await IAService.validarRegistro(
      nombreComun: nombreComun,
      nombreCientifico: nombreCientifico,
      especie: especie,
      descripcion: descripcion,
      tipo: tipo,
      comportamiento: comportamiento,
      estadoExtincion: estadoExtincion,
      habitat: habitat,
    );
  });

  /// Limpia resultados y errores
  void limpiar() {
    _validacionResultado = null;
    resetState();
  }
}
