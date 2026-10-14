import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:terrascope/components/ia/ia_registro.dart';
import 'package:terrascope/services/ia_service.dart';
import '../../providers/retos_observer_provider.dart';
import '../../services/camera_service.dart';
import '../../services/fauna_flora_service.dart';
import '../../services/session_service.dart';
import '../../services/habitat_service.dart';
import '../../components/models/avistamiento_model.dart';
import '../../components/models/habitat.dart';
import '../../config/api_config.dart';
import '../models/validacion_model.dart';

class CreateAvistamientoScreen extends StatefulWidget {
  const CreateAvistamientoScreen({super.key});

  @override
  State<CreateAvistamientoScreen> createState() =>
      _CreateAvistamientoScreenState();
}

class _CreateAvistamientoScreenState extends State<CreateAvistamientoScreen> {
  final _formKey = GlobalKey<FormState>();
  final CameraService _cameraService = CameraService();
  final FaunaFloraService _service = FaunaFloraService(
    baseUrl: ApiConfig.baseUrl,
  );
  final SessionService _sessionService = SessionService();
  final HabitatService _habitatService = HabitatService(
    baseUrl: ApiConfig.baseUrl,
  );
  final IARegistro _iaRegistro = IARegistro();

  // Controladores de texto
  final TextEditingController _nombreComunController = TextEditingController();
  final TextEditingController _nombreCientificoController =
      TextEditingController();
  final TextEditingController _descripcionController = TextEditingController();
  final TextEditingController _especieController = TextEditingController();
  final TextEditingController _latitudController = TextEditingController();
  final TextEditingController _longitudController = TextEditingController();
  final TextEditingController _comportamientoController =
      TextEditingController();
  final TextEditingController _estadoEspecimenController =
      TextEditingController();

  File? _imageFile;
  String? _imageBase64;
  bool _isLoadingLocation = false;
  bool _isSaving = false;
  bool _isLoadingHabitats = true;
  String _tipo = 'Fauna';
  String _estadoExtincion = 'Preocupación menor';
  String _especieSeleccionada = 'Mamífero';
  List<Habitat> _habitats = [];
  Habitat? _selectedHabitat;
  bool _cargando = false;
  bool _esPeligrosa = false;
  Map<String, dynamic>? _resultadoIA;

  final List<String> _comportamientosComunes = [
    'Agresivo',
    'Tranquilo',
    'Temeroso',
    'Curioso',
    'Territorial',
  ];

  final List<String> _especiesDisponibles = [
    'Mamífero',
    'Ave',
    'Reptil',
    'Anfibio',
    'Pez',
    'Insecto',
    'Planta',
    'Otro',
  ];

  // 🆕 Lista de especies para Flora
  final List<String> _especiesFlora = [
    'Planta',
    'Árbol',
    'Arbusto',
    'Hierba',
    'Hongo',
    'Otro',
  ];

  @override
  void initState() {
    super.initState();
    _loadHabitats();
  }

  Future<void> _loadHabitats() async {
    try {
      print('🔍 Intentando cargar hábitats...');
      final habitats = await _habitatService.getAllHabitats();
      print('✅ Hábitats cargados: ${habitats.length}');

      if (habitats.isNotEmpty) {
        print('📋 Primer hábitat: ${habitats[0].nombreHabitat}');
      }

      if (mounted) {
        setState(() {
          _habitats = habitats;
          _isLoadingHabitats = false;
        });
      }
    } catch (e, stackTrace) {
      print('❌ Error al cargar hábitats: $e');
      print('📍 Stack trace: $stackTrace');

      if (mounted) {
        setState(() {
          _isLoadingHabitats = false;
        });
        _showError('Error al cargar hábitats: $e');
      }
    }
  }

  // 🆕 Método para actualizar campos cuando cambia el tipo
  void _actualizarCamposSegunTipo(String nuevoTipo) {
    setState(() {
      _tipo = nuevoTipo;

      if (nuevoTipo == 'Flora') {
        // Establecer valores por defecto para Flora
        _especieSeleccionada = 'Planta';
        _comportamientoController.text = 'No aplica';
        _estadoEspecimenController.text = 'Observado';
      } else {
        // Restaurar valores por defecto para Fauna
        // Verificar si el valor actual es válido en Fauna, si no, usar Mamífero
        if (!_especiesDisponibles.contains(_especieSeleccionada)) {
          _especieSeleccionada = 'Mamífero';
        }
        _comportamientoController.text = '';
        _estadoEspecimenController.text = '';
      }
    });
  }

  @override
  void dispose() {
    _nombreComunController.dispose();
    _nombreCientificoController.dispose();
    _descripcionController.dispose();
    _latitudController.dispose();
    _longitudController.dispose();
    _comportamientoController.dispose();
    _estadoEspecimenController.dispose();
    super.dispose();
  }

  Future<void> _takePhoto() async {
    try {
      final File? photo = await _cameraService.takePhoto();
      if (photo != null) {
        final String base64 = await _cameraService.convertImageToBase64(photo);
        if (mounted) {
          setState(() {
            _imageFile = photo;
            _imageBase64 = base64;
          });
        }
      }
    } catch (e) {
      _showError('Error al tomar foto: $e');
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final File? image = await _cameraService.pickImageFromGallery();
      if (image != null) {
        final String base64 = await _cameraService.convertImageToBase64(image);
        if (mounted) {
          setState(() {
            _imageFile = image;
            _imageBase64 = base64;
          });
        }
      }
    } catch (e) {
      _showError('Error al seleccionar imagen: $e');
    }
  }

  Future<void> _showSpeciesModal() async {
    if (_resultadoIA == null) return;

    final nombreComunIA = _resultadoIA!['nombre_comun'] ?? '';
    final nombreCientificoIA = _resultadoIA!['nombre_cientifico'] ?? '';
    final descripcionIA = _resultadoIA!['descripcion'] ?? '';
    final nivelConfianza = _resultadoIA!['nivel_confianza'] ?? '';

    bool isUnknown =
        nombreComunIA.toLowerCase() == 'desconocido' ||
        nombreCientificoIA.toLowerCase() == 'desconocido';

    double getConfidencePercent(String nivel) {
      switch (nivel.toLowerCase()) {
        case 'alto':
          return 1.0;
        case 'medio':
          return 0.66;
        case 'bajo':
          return 0.33;
        default:
          return 0.0;
      }
    }

    Color getColorForConfidence(String nivel) {
      switch (nivel.toLowerCase()) {
        case 'alto':
          return const Color(0xFF4CAF50);
        case 'medio':
          return const Color(0xFFFFA726);
        case 'bajo':
          return const Color(0xFFEF5350);
        default:
          return Colors.grey;
      }
    }

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        final percent = getConfidencePercent(nivelConfianza);
        final color = getColorForConfidence(nivelConfianza);

        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(maxHeight: 650),
            decoration: BoxDecoration(
              color: const Color(0xFFE0E0E0),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 30,
                  offset: const Offset(0, 15),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(28),
                  decoration: const BoxDecoration(
                    color: Color(0xFF5C6445),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(28),
                      topRight: Radius.circular(28),
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE0E0E0).withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.pets,
                          color: Color(0xFFE0E0E0),
                          size: 48,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Información del Avistamiento',
                        style: TextStyle(
                          color: Color(0xFFE0E0E0),
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Identificación por IA',
                        style: TextStyle(
                          color: const Color(0xFFE0E0E0).withOpacity(0.8),
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (nombreComunIA.isNotEmpty) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFF5C6445).withOpacity(0.2),
                                width: 1.5,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: const Color(
                                          0xFF5C6445,
                                        ).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        Icons.label_outline,
                                        color: Color(0xFF5C6445),
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Nombre Común',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: const Color(
                                          0xFF224275,
                                        ).withOpacity(0.7),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  nombreComunIA,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        if (nombreCientificoIA.isNotEmpty) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFF5C6445).withOpacity(0.2),
                                width: 1.5,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: const Color(
                                          0xFF5C6445,
                                        ).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        Icons.science_outlined,
                                        color: Color(0xFF5C6445),
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Nombre Científico',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: const Color(
                                          0xFF224275,
                                        ).withOpacity(0.7),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  nombreCientificoIA,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        if (descripcionIA.isNotEmpty) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFF5C6445).withOpacity(0.2),
                                width: 1.5,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: const Color(
                                          0xFF5C6445,
                                        ).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        Icons.description_outlined,
                                        color: Color(0xFF5C6445),
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Descripción',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: const Color(
                                          0xFF224275,
                                        ).withOpacity(0.7),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  descripcionIA,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        if (nivelConfianza.isNotEmpty) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: color.withOpacity(0.3),
                                width: 1.5,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: color.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Icon(
                                            Icons.analytics_outlined,
                                            color: color,
                                            size: 18,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Text(
                                          'Nivel de Confianza',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: const Color(
                                              0xFF224275,
                                            ).withOpacity(0.7),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      '${(percent * 100).toInt()}%',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: color,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: LinearProgressIndicator(
                                    value: percent,
                                    color: color,
                                    backgroundColor: color.withOpacity(0.2),
                                    minHeight: 12,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    nivelConfianza.toUpperCase(),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: color,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        if (isUnknown) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFA726).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFFFA726).withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.info_outline,
                                  color: Color(0xFFFFA726),
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'No se pudo identificar la especie. Completa los campos manualmente.',
                                    style: TextStyle(
                                      color: Colors.orange[900],
                                      fontSize: 13,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            side: BorderSide(
                              color: Colors.grey[400]!,
                              width: 1.5,
                            ),
                          ),
                          child: const Text(
                            'Cerrar',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: isUnknown
                              ? null
                              : () {
                                  setState(() {
                                    _nombreComunController.text = nombreComunIA;
                                    _nombreCientificoController.text =
                                        nombreCientificoIA;
                                  });
                                  Navigator.of(context).pop();
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0F1D33),
                            foregroundColor: const Color(0xFFE0E0E0),
                            disabledBackgroundColor: Colors.grey[300],
                            disabledForegroundColor: Colors.grey[600],
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.auto_fix_high, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Autocompletar',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _identificarEspecie(String imagenBase64) async {
    try {
      setState(() => _cargando = true);

      final resultado = await IAService.identificarEspecie(imagenBase64);

      if (mounted) {
        setState(() {
          _resultadoIA = resultado;
        });
        _showSpeciesModal();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Identificación completada')),
      );
    } catch (e) {
      _showError('Error al identificar: $e');
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _validarRegistro() async {
    print('🔹 Datos a validar:');
    print('  - Nombre Común: ${_nombreComunController.text}');
    print('  - Nombre Científico: ${_nombreCientificoController.text}');
    print('  - Especie: $_especieSeleccionada');
    print('  - Descripción: ${_descripcionController.text}');
    print(
      '  - Hábitat: ${_selectedHabitat != null ? _selectedHabitat!.nombreHabitat : "No seleccionado"}',
    );

    if (_nombreComunController.text.isEmpty ||
        _nombreCientificoController.text.isEmpty ||
        _especieSeleccionada.isEmpty ||
        _descripcionController.text.isEmpty ||
        _selectedHabitat == null) {
      _showError('Faltan campos obligatorios para la validación contextual.');
      return;
    }

    setState(() => _cargando = true);

    try {
      await _iaRegistro.validarRegistro(
        nombreComun: _nombreComunController.text,
        nombreCientifico: _nombreCientificoController.text,
        especie: _especieSeleccionada,
        descripcion: _descripcionController.text,
        tipo: _tipo,
        comportamiento: _comportamientoController.text,
        estadoExtincion: _estadoExtincion,
        habitat: _selectedHabitat != null
            ? {
                'idHabitat': _selectedHabitat!.idHabitat,
                'nombre_habitat': _selectedHabitat!.nombreHabitat,
              }
            : {},
      );

      if (_iaRegistro.error != null) {
        _showError(_iaRegistro.error!);
        return;
      }

      if (mounted) {
        setState(() {
          _resultadoIA = _iaRegistro.validacionResultado;
        });
      }

      if (_resultadoIA != null) {
        final esCoherente = _resultadoIA!['es_coherente'] ?? false;
        final errores = _resultadoIA!['errores_detectados'] ?? [];
        final sugerencia = _resultadoIA!['sugerencia'] ?? '';

        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              elevation: 0,
              backgroundColor: Colors.transparent,
              child: Container(
                constraints: const BoxConstraints(maxHeight: 600),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0E0E0),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 30,
                      offset: const Offset(0, 15),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(28),
                      decoration: const BoxDecoration(
                        color: Color(0xFF5C6445),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(28),
                          topRight: Radius.circular(28),
                        ),
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE0E0E0).withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              esCoherente
                                  ? Icons.check_circle_outline
                                  : Icons.warning_amber_rounded,
                              color: const Color(0xFFE0E0E0),
                              size: 52,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            esCoherente
                                ? '¡Validación Exitosa!'
                                : 'Validación con Observaciones',
                            style: const TextStyle(
                              color: Color(0xFFE0E0E0),
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            esCoherente
                                ? 'Los datos ingresados son coherentes'
                                : 'Se detectaron algunas inconsistencias',
                            style: TextStyle(
                              color: const Color(0xFFE0E0E0).withOpacity(0.8),
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: const Color(
                                    0xFF5C6445,
                                  ).withOpacity(0.2),
                                  width: 1.5,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFF5C6445,
                                      ).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      esCoherente
                                          ? Icons.verified
                                          : Icons.priority_high,
                                      color: const Color(0xFF5C6445),
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Estado de Coherencia',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: const Color(
                                              0xFF224275,
                                            ).withOpacity(0.7),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          esCoherente
                                              ? 'Datos coherentes ✓'
                                              : 'Requiere revisión',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            if (errores.isNotEmpty) ...[
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFFEF5350,
                                      ).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.error_outline,
                                      color: Color(0xFFEF5350),
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  const Text(
                                    'Incoherencias Detectadas',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: const Color(
                                      0xFFEF5350,
                                    ).withOpacity(0.3),
                                    width: 1.5,
                                  ),
                                ),
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  children: errores.map<Widget>((error) {
                                    return Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 12,
                                      ),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Icon(
                                            Icons.cancel_rounded,
                                            color: Color(0xFFEF5350),
                                            size: 20,
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              error.toString(),
                                              style: const TextStyle(
                                                fontSize: 14,
                                                height: 1.5,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                              const SizedBox(height: 20),
                            ],
                            if (sugerencia.isNotEmpty) ...[
                              Row(
                                children: [
                                  const Icon(
                                    Icons.lightbulb_outline,
                                    color: Color(0xFF5C6445),
                                    size: 22,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Sugerencia de IA',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF5C6445),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      const Color(0xFF5C6445).withOpacity(0.1),
                                      const Color(0xFF4A5237).withOpacity(0.05),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color(
                                      0xFF5C6445,
                                    ).withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(
                                      Icons.auto_awesome,
                                      color: Color(0xFF5C6445),
                                      size: 24,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        sugerencia,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          height: 1.5,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                      child: SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0F1D33),
                            foregroundColor: const Color(0xFFE0E0E0),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                esCoherente ? 'Continuar' : 'Entendido',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                esCoherente ? Icons.arrow_forward : Icons.check,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(
                    esCoherente ? Icons.check_circle : Icons.info_outline,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 12),
                  const Text('Validación completada'),
                ],
              ),
              backgroundColor: esCoherente
                  ? const Color(0xFF5C6445)
                  : const Color(0xFFF57C00),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      }
    } catch (e) {
      _showError('Error en la validación: $e');
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _getCurrentLocation() async {
    if (!mounted) return;

    setState(() {
      _isLoadingLocation = true;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception(
          'Los servicios de ubicación están deshabilitados. Por favor actívalos en configuración.',
        );
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Permisos de ubicación denegados');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception(
          'Los permisos de ubicación están denegados permanentemente. Ve a configuración para habilitarlos.',
        );
      }

      Position? lastPosition = await Geolocator.getLastKnownPosition();

      if (lastPosition != null) {
        if (mounted) {
          setState(() {
            _latitudController.text = lastPosition.latitude.toStringAsFixed(6);
            _longitudController.text = lastPosition.longitude.toStringAsFixed(
              6,
            );
            _isLoadingLocation = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ubicación obtenida (última conocida)'),
              duration: Duration(seconds: 2),
              backgroundColor: Colors.green,
            ),
          );
        }
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );

      if (mounted) {
        setState(() {
          _latitudController.text = position.latitude.toStringAsFixed(6);
          _longitudController.text = position.longitude.toStringAsFixed(6);
          _isLoadingLocation = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ubicación obtenida exitosamente'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on TimeoutException {
      if (mounted) {
        setState(() {
          _isLoadingLocation = false;
        });
        _showError(
          'Tiempo de espera agotado. Intenta de nuevo en un lugar con mejor señal GPS.',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingLocation = false;
        });
        _showError('Error al obtener ubicación: $e');
      }
    }
  }

  Future<void> _saveAvistamiento() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_imageBase64 == null) {
      _showError('Por favor, toma una foto primero');
      return;
    }

    if (_latitudController.text.isEmpty || _longitudController.text.isEmpty) {
      _showError('Por favor, obtén la ubicación primero');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final nombreUsuario = await _sessionService.getUserName();
      final idUsuario = await _sessionService.getUserId();

      if (nombreUsuario == null || idUsuario == null) {
        _showError('No hay sesión activa. Por favor inicia sesión.');
        setState(() {
          _isSaving = false;
        });
        return;
      }

      if (_selectedHabitat == null) {
        _showError('Por favor selecciona un hábitat');
        setState(() {
          _isSaving = false;
        });
        return;
      }

      final avistamiento = Avistamiento(
        id: '',
        idUsuario: idUsuario,
        nombreComun: _nombreComunController.text,
        nombreCientifico: _nombreCientificoController.text,
        especie: _especieSeleccionada,
        descripcion: _descripcionController.text,
        imagen: _imageBase64!,
        ubicacion: Ubicacion(
          latitud: double.parse(_latitudController.text),
          longitud: double.parse(_longitudController.text),
        ),
        comportamiento: _comportamientoController.text,
        estadoExtincion: _estadoExtincion,
        estadoEspecimen: _estadoEspecimenController.text,
        habitat: _selectedHabitat!,
        comentarios: [],
        tipo: _tipo,
        nombreUsuario: nombreUsuario,
        esPeligrosa: _esPeligrosa,
      );

      print('📤 Datos a enviar:');
      print('  - Nombre: ${avistamiento.nombreComun}');
      print('  - Usuario: ${avistamiento.nombreUsuario}');
      print('  - Tipo: ${avistamiento.tipo}');
      print('  - Habitat ID: ${avistamiento.habitat.idHabitat}');
      print(
        '  - Ubicación: ${avistamiento.ubicacion.latitud}, ${avistamiento.ubicacion.longitud}',
      );
      print(
        '  - Validación: ${avistamiento.validacion.estado}, votos: ${avistamiento.validacion.votosComunidad}',
      );

      final jsonData = avistamiento.toJson();
      print('📋 JSON completo:');
      print(jsonData);

      await _service.createFaunaFlora(avistamiento);

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Avistamiento creado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        // Refresh retos and logros after successful avistamiento registration
        context.read<RetosObserverProvider>().cargarRetosActivos();
        context.read<RetosObserverProvider>().cargarLogrosUsuario();
      }
    } catch (e) {
      _showError('Error al guardar: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 0,
        title: const Text(
          'Nuevo Avistamiento',
          style: TextStyle(color: Color(0xFFE0E0E0)),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFFE0E0E0)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _imageFile == null ? _buildCameraStep() : _buildFormStep(),
    );
  }

  Widget _buildCameraStep() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.camera_alt, size: 100, color: Colors.grey[400]),
            const SizedBox(height: 24),
            const Text(
              'Captura la imagen del avistamiento',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Toma una foto clara del animal o planta',
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _takePhoto,
                icon: const Icon(Icons.camera),
                label: const Text('Tomar Foto'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5C6445),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: _pickImageFromGallery,
                icon: const Icon(Icons.photo_library),
                label: const Text('Seleccionar de Galería'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF5C6445),
                  side: const BorderSide(color: Color(0xFF5C6445)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormStep() {
    // 🆕 Determinar si es Flora para deshabilitar campos
    final bool esFlora = _tipo == 'Flora';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                image: DecorationImage(
                  image: FileImage(_imageFile!),
                  fit: BoxFit.cover,
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: 8,
                    right: 8,
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () {
                        setState(() {
                          _imageFile = null;
                          _imageBase64 = null;
                        });
                      },
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black54,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            if (_imageBase64 != null)
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _cargando
                      ? null
                      : () => _identificarEspecie(_imageBase64!),
                  icon: _cargando
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.search),
                  label: const Text('Identificar Especie'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5C6445),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 24),

            // Tipo (Fauna/Flora) - 🆕 Con callback actualizado
            const Text(
              'Tipo',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'Fauna', label: Text('Fauna')),
                ButtonSegment(value: 'Flora', label: Text('Flora')),
              ],
              selected: {_tipo},
              onSelectionChanged: (Set<String> newSelection) {
                _actualizarCamposSegunTipo(newSelection.first);
              },
            ),
            const SizedBox(height: 16),

            _buildTextField(
              controller: _nombreComunController,
              label: 'Nombre Común',
              hint: 'Ej: Jaguar',
              validator: (value) =>
                  value?.isEmpty ?? true ? 'Campo requerido' : null,
            ),

            _buildTextField(
              controller: _nombreCientificoController,
              label: 'Nombre Científico',
              hint: 'Ej: Panthera onca',
              validator: (value) =>
                  value?.isEmpty ?? true ? 'Campo requerido' : null,
            ),

            _buildTextField(
              controller: _descripcionController,
              label: 'Descripción',
              hint: 'Describe las características observadas',
              maxLines: 3,
              validator: (value) =>
                  value?.isEmpty ?? true ? 'Campo requerido' : null,
            ),

            // 🆕 Especie - Cambia opciones según tipo
            const Text(
              'Especie',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _especieSeleccionada,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: esFlora ? Colors.grey[200] : Colors.white,
              ),
              items: (esFlora ? _especiesFlora : _especiesDisponibles).map((
                especie,
              ) {
                return DropdownMenuItem<String>(
                  value: especie,
                  child: Row(
                    children: [
                      Icon(
                        _getIconForEspecie(especie),
                        color: _getColorForEspecie(especie),
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        especie,
                        style: TextStyle(
                          color: _getColorForEspecie(especie),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: esFlora
                  ? null
                  : (value) {
                      if (value != null) {
                        setState(() {
                          _especieSeleccionada = value;
                        });
                      }
                    },
            ),

            // 🆕 Mensaje informativo cuando es Flora
            if (esFlora) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF5C6445).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFF5C6445).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: const Color(0xFF5C6445),
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Los campos específicos de fauna se completarán automáticamente',
                        style: TextStyle(
                          fontSize: 12,
                          color: const Color(0xFF5C6445),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            const SizedBox(height: 24),
            // Toggle de Fauna Peligrosa
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _esPeligrosa ? Colors.red[50] : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _esPeligrosa ? Colors.red : Colors.grey[300]!,
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: _esPeligrosa ? Colors.red : Colors.grey[600],
                    size: 28,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '¿Es una especie peligrosa?',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _esPeligrosa ? Colors.red[900] : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Activa esto si el animal representa un riesgo para las personas cercanas',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _esPeligrosa,
                    activeColor: Colors.red,
                    onChanged: (value) {
                      setState(() {
                        _esPeligrosa = value;
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            const SizedBox(height: 16),

            const Text(
              'Ubicación',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _latitudController,
                    label: 'Latitud',
                    keyboardType: TextInputType.number,
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'Requerido' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTextField(
                    controller: _longitudController,
                    label: 'Longitud',
                    keyboardType: TextInputType.number,
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'Requerido' : null,
                  ),
                ),
                IconButton(
                  icon: _isLoadingLocation
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.my_location),
                  onPressed: _isLoadingLocation ? null : _getCurrentLocation,
                  tooltip: 'Obtener ubicación actual',
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 🆕 Comportamiento - Deshabilitado para Flora
            const Text(
              'Comportamiento',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            if (esFlora)
              // Campo de texto deshabilitado para Flora
              TextFormField(
                controller: _comportamientoController,
                enabled: false,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.grey[200],
                  hintText: 'No aplica para flora',
                ),
              )
            else
              // Dropdown normal para Fauna
              DropdownButtonFormField<String>(
                value: _comportamientoController.text.isEmpty
                    ? null
                    : _comportamientoController.text,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                hint: const Text('Selecciona un comportamiento'),
                items: _comportamientosComunes
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    _comportamientoController.text = value;
                  }
                },
                validator: (value) => value == null ? 'Campo requerido' : null,
              ),
            const SizedBox(height: 16),

            const Text(
              'Estado de Extinción',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _estadoExtincion,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              items: [
                'Preocupación menor',
                'Vulnerable',
                'En peligro',
                'En peligro crítico',
                'Extinto',
              ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _estadoExtincion = value;
                  });
                }
              },
            ),
            const SizedBox(height: 16),

            // 🆕 Estado del Especimen - Deshabilitado para Flora
            _buildTextField(
              controller: _estadoEspecimenController,
              label: 'Estado del Espécimen',
              hint: esFlora ? 'Observado' : 'Ej: Saludable, Herido, etc.',
              enabled: !esFlora,
              validator: (value) =>
                  value?.isEmpty ?? true ? 'Campo requerido' : null,
            ),

            const Divider(height: 32),
            const Text(
              'Hábitat',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Color(0xFF5C6445),
              ),
            ),
            const SizedBox(height: 16),

            _isLoadingHabitats
                ? const Center(child: CircularProgressIndicator())
                : _habitats.isEmpty
                ? Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning, color: Colors.orange[700]),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'No hay hábitats disponibles. Verifica la conexión.',
                            style: TextStyle(color: Colors.orange[900]),
                          ),
                        ),
                        TextButton(
                          onPressed: _loadHabitats,
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  )
                : DropdownButtonFormField<Habitat>(
                    value: _selectedHabitat,
                    decoration: InputDecoration(
                      labelText: 'Selecciona un hábitat',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    hint: const Text('Selecciona un hábitat'),
                    items: _habitats.map((habitat) {
                      return DropdownMenuItem<Habitat>(
                        value: habitat,
                        child: Text(
                          habitat.nombreHabitat,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (Habitat? value) {
                      setState(() {
                        _selectedHabitat = value;
                      });
                    },
                    validator: (value) =>
                        value == null ? 'Selecciona un hábitat' : null,
                  ),

            const SizedBox(height: 32),

            if (_imageBase64 != null)
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _cargando ? null : _validarRegistro,
                  icon: _cargando
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Icon(Icons.verified, size: 22),
                  label: const Text(
                    'Validar Registro',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5C6445),
                    foregroundColor: const Color(0xFFE0E0E0),
                    disabledBackgroundColor: Colors.grey[300],
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    shadowColor: const Color(0xFF5C6445).withOpacity(0.4),
                  ),
                ),
              ),

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveAvistamiento,
                icon: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Icon(Icons.save_outlined, size: 22),
                label: const Text(
                  'Guardar Avistamiento',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F1D33),
                  foregroundColor: const Color(0xFFE0E0E0),
                  disabledBackgroundColor: Colors.grey[300],
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  shadowColor: const Color(0xFF0F1D33).withOpacity(0.4),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    bool enabled = true, // 🆕 Parámetro para habilitar/deshabilitar
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: keyboardType,
            validator: validator,
            enabled: enabled, // 🆕 Aplicar habilitación
            decoration: InputDecoration(
              hintText: hint,
              filled: true,
              fillColor: enabled
                  ? Colors.white
                  : Colors.grey[200], // 🆕 Color cuando está deshabilitado
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              disabledBorder: OutlineInputBorder(
                // 🆕 Borde cuando está deshabilitado
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF5C6445)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 🆕 Iconos actualizados para incluir Flora
  IconData _getIconForEspecie(String especie) {
    switch (especie.toLowerCase()) {
      case 'mamífero':
      case 'mamifero':
        return Icons.pets;
      case 'ave':
        return Icons.flutter_dash;
      case 'reptil':
        return Icons.workspaces_outline;
      case 'anfibio':
        return Icons.water;
      case 'pez':
        return Icons.phishing;
      case 'insecto':
        return Icons.bug_report;
      case 'planta':
        return Icons.local_florist;
      case 'árbol':
      case 'arbol':
        return Icons.park;
      case 'arbusto':
        return Icons.nature;
      case 'hierba':
        return Icons.grass;
      case 'hongo':
        return Icons.eco;
      case 'otro':
        return Icons.category;
      default:
        return Icons.help_outline;
    }
  }

  // 🆕 Colores actualizados para incluir Flora
  Color _getColorForEspecie(String especie) {
    switch (especie.toLowerCase()) {
      case 'mamífero':
      case 'mamifero':
        return const Color(0xFF8D6E63);
      case 'ave':
        return const Color(0xFF42A5F5);
      case 'reptil':
        return const Color(0xFF66BB6A);
      case 'anfibio':
        return const Color(0xFF26C6DA);
      case 'pez':
        return const Color(0xFF29B6F6);
      case 'insecto':
        return const Color(0xFFFFCA28);
      case 'planta':
        return const Color(0xFF4CAF50);
      case 'árbol':
      case 'arbol':
        return const Color(0xFF2E7D32);
      case 'arbusto':
        return const Color(0xFF689F38);
      case 'hierba':
        return const Color(0xFF9CCC65);
      case 'hongo':
        return const Color(0xFF8D6E63);
      case 'otro':
        return const Color(0xFF9E9E9E);
      default:
        return const Color(0xFF757575);
    }
  }
}
