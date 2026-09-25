import 'dart:io';
import 'package:flutter/material.dart';
import 'package:terrascope/services/auth_service.dart';
import 'package:terrascope/services/session_service.dart';
import 'package:terrascope/services/camera_service.dart';
import 'dart:convert';

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const EditProfileScreen({super.key, required this.userData});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();
  final SessionService _sessionService = SessionService();
  final CameraService _cameraService = CameraService();

  late TextEditingController _nombreController;
  late TextEditingController _telefonoController;
  
  DateTime? _fechaNacimiento;
  File? _nuevaImagen;
  String? _imagenActual;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(text: widget.userData['nombre_usuario'] ?? '');
    _telefonoController = TextEditingController(text: widget.userData['telefono_usuario'] ?? '');
    _imagenActual = widget.userData['imagen_perfil'];
    
    // Parsear fecha de nacimiento si existe
    if (widget.userData['fecha_nac_usuario'] != null) {
      try {
        _fechaNacimiento = DateTime.parse(widget.userData['fecha_nac_usuario']);
      } catch (e) {
        _fechaNacimiento = null;
      }
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _telefonoController.dispose();
    super.dispose();
  }

  Future<void> _seleccionarImagen() async {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Tomar foto'),
              onTap: () {
                Navigator.pop(context);
                _tomarFoto();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Seleccionar de galería'),
              onTap: () {
                Navigator.pop(context);
                _seleccionarDeGaleria();
              },
            ),
            if (_nuevaImagen != null || _imagenActual != null)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Eliminar foto', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _nuevaImagen = null;
                    _imagenActual = null;
                  });
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _tomarFoto() async {
    try {
      final foto = await _cameraService.takePhoto();
      if (foto != null) {
        final size = await _cameraService.getImageSizeInMB(foto);
        if (size > 5) {
          _mostrarError('La imagen es demasiado grande. Máximo 5MB.');
          return;
        }
        setState(() {
          _nuevaImagen = foto;
        });
      }
    } catch (e) {
      _mostrarError('Error al tomar foto: $e');
    }
  }

  Future<void> _seleccionarDeGaleria() async {
    try {
      final imagen = await _cameraService.pickImageFromGallery();
      if (imagen != null) {
        final size = await _cameraService.getImageSizeInMB(imagen);
        if (size > 5) {
          _mostrarError('La imagen es demasiado grande. Máximo 5MB.');
          return;
        }
        setState(() {
          _nuevaImagen = imagen;
        });
      }
    } catch (e) {
      _mostrarError('Error al seleccionar imagen: $e');
    }
  }

  Future<void> _seleccionarFecha() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _fechaNacimiento ?? DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      locale: const Locale('es', 'ES'),
      helpText: 'Selecciona tu fecha de nacimiento',
    );
    if (picked != null) {
      setState(() {
        _fechaNacimiento = picked;
      });
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'No especificada';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Future<void> _guardarCambios() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final userId = widget.userData['id']?.toString() ?? widget.userData['_id']?.toString();
      if (userId == null) {
        throw Exception('ID de usuario no encontrado');
      }
      // Preparar datos a actualizar
      Map<String, dynamic> datosActualizados = {
        'nombre_usuario': _nombreController.text.trim(),
        'telefono_usuario': _telefonoController.text.trim().isEmpty 
            ? null 
            : _telefonoController.text.trim(),
        'fecha_nac_usuario': _fechaNacimiento?.toIso8601String(),
      };

      // Si hay nueva imagen, convertir a base64
      if (_nuevaImagen != null) {
        final base64Image = await _cameraService.convertImageToBase64(_nuevaImagen!);
        datosActualizados['imagen_perfil'] = 'data:image/jpeg;base64,$base64Image';
      } else if (_imagenActual == null && widget.userData['imagen_perfil'] != null) {
        // Si se eliminó la imagen
        datosActualizados['imagen_perfil'] = null;
      }

      // Actualizar en el backend
      final success = await _authService.actualizarUsuario(userId, datosActualizados);

      if (success) {
        // Actualizar sesión local
        await _sessionService.updateUserData({
          'nombre_usuario': datosActualizados['nombre_usuario'],
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Perfil actualizado correctamente'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true); // Retornar true para indicar que hubo cambios
        }
      } else {
        _mostrarError('No se pudo actualizar el perfil');
      }
    } catch (e) {
      _mostrarError('Error al guardar: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Perfil'),
        centerTitle: true,
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _guardarCambios,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildImagePicker(),
              const SizedBox(height: 32),
              _buildNombreField(),
              const SizedBox(height: 16),
              _buildTelefonoField(),
              const SizedBox(height: 16),
              _buildFechaNacimientoField(),
              const SizedBox(height: 32),
              _buildGuardarButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePicker() {
    ImageProvider? imageProvider;
    
    if (_nuevaImagen != null) {
      imageProvider = FileImage(_nuevaImagen!);
    } else if (_imagenActual != null && _imagenActual!.isNotEmpty) {
      // Si es base64
      if (_imagenActual!.startsWith('data:image')) {
        final base64String = _imagenActual!.split(',').last;
        imageProvider = MemoryImage(base64Decode(base64String));
      } else {
        // Si es URL
        imageProvider = NetworkImage(_imagenActual!);
      }
    }

    return Center(
      child: Stack(
        children: [
          CircleAvatar(
            radius: 60,
            backgroundColor: Colors.green[100],
            backgroundImage: imageProvider,
            child: imageProvider == null
                ? Icon(Icons.person, size: 60, color: Colors.green[700])
                : null,
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: _seleccionarImagen,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNombreField() {
    return TextFormField(
      controller: _nombreController,
      decoration: const InputDecoration(
        labelText: 'Nombre',
        prefixIcon: Icon(Icons.person),
        border: OutlineInputBorder(),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'El nombre es requerido';
        }
        if (value.trim().length < 3) {
          return 'El nombre debe tener al menos 3 caracteres';
        }
        return null;
      },
    );
  }

  Widget _buildTelefonoField() {
    return TextFormField(
      controller: _telefonoController,
      decoration: const InputDecoration(
        labelText: 'Teléfono',
        prefixIcon: Icon(Icons.phone),
        border: OutlineInputBorder(),
        hintText: 'Opcional',
      ),
      keyboardType: TextInputType.phone,
      validator: (value) {
        if (value != null && value.isNotEmpty && value.length < 10) {
          return 'El teléfono debe tener al menos 10 dígitos';
        }
        return null;
      },
    );
  }

  Widget _buildFechaNacimientoField() {
    return InkWell(
      onTap: _seleccionarFecha,
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Fecha de Nacimiento',
          prefixIcon: Icon(Icons.cake),
          border: OutlineInputBorder(),
          hintText: 'Opcional',
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _formatDate(_fechaNacimiento),
              style: TextStyle(
                color: _fechaNacimiento == null ? Colors.grey : Colors.black,
              ),
            ),
            const Icon(Icons.calendar_today, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildGuardarButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _guardarCambios,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text('Guardar Cambios', style: TextStyle(fontSize: 16)),
      ),
    );
  }
}
