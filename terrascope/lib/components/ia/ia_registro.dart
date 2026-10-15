import 'package:flutter/material.dart';
import 'package:terrascope/services/ia_service.dart';

class IARegistro extends ChangeNotifier {
  // Estado de carga
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Resultado de validación
  Map<String, dynamic>? _validacionResultado;
  Map<String, dynamic>? get validacionResultado => _validacionResultado;

  // Mensaje de error
  String? _error;
  String? get error => _error;

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
  }) async {
    _setLoading(true);
    _error = null;
    try {
      final resultado = await IAService.validarRegistro(
        nombreComun: nombreComun,
        nombreCientifico: nombreCientifico,
        especie: especie,
        descripcion: descripcion,
        tipo: tipo,
        comportamiento: comportamiento,
        estadoExtincion: estadoExtincion,
        habitat: habitat,
      );
      _validacionResultado = resultado;
    } catch (e) {
      _error = e.toString();
      _validacionResultado = null;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  /// Limpia resultados y errores
  void limpiar() {
    _validacionResultado = null;
    _error = null;
    notifyListeners();
  }
}
