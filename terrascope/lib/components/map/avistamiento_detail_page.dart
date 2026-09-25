import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/avistamiento_model.dart';
import '../models/comentario.dart';
import '../../services/avistamiento_service.dart';
import '../../services/session_service.dart';
import '../../services/theme_service.dart';

class AvistamientoDetailPage extends StatefulWidget {
  final Avistamiento avistamiento;
  final String? usuarioId;
  final String? nombreUsuario;

  const AvistamientoDetailPage({
    super.key,
    required this.avistamiento,
    this.usuarioId,
    this.nombreUsuario,
  });

  @override
  State<AvistamientoDetailPage> createState() => _AvistamientoDetailPageState();
}

class _AvistamientoDetailPageState extends State<AvistamientoDetailPage> {
  final TextEditingController _comentarioController = TextEditingController();
  late List<Comentario> _comentarios;
  bool _isSubmitting = false;
  final SessionService _sessionService = SessionService();

  @override
  void initState() {
    super.initState();
    _comentarios = List.from(widget.avistamiento.comentarios);
  }

  Future<void> _agregarComentario() async {
    if (_comentarioController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor ingresa un comentario')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Obtener el nombre del usuario de la sesión
      final nombreUsuario = await _sessionService.getUserName();

      if (nombreUsuario == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No hay sesión activa. Por favor inicia sesión.'),
          ),
        );
        setState(() => _isSubmitting = false);
        return;
      }

      await AvistamientoService.addComentario(
        widget.avistamiento.id,
        _comentarioController.text.trim(),
      );

      setState(() {
        _comentarios.add(
          Comentario(
            idUsuario: widget.usuarioId,
            nombreUsuario: nombreUsuario,
            comentario: _comentarioController.text.trim(),
            fecha: DateTime.now(),
          ),
        );
        _comentarioController.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Comentario agregado exitosamente')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al agregar comentario: $e')),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    // Theme-aware colors
    final backgroundColor = isDark
        ? themeProvider.darkTheme.scaffoldBackgroundColor
        : const Color(0xFFE0E0E0);
    final appBarColor = const Color(0xFF5C6445);
    final appBarTextColor = const Color(0xFFE0E0E0);
    final cardBackgroundColor = isDark
        ? themeProvider.darkTheme.cardColor
        : Colors.white;
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF0F1D33);
    final secondaryTextColor = isDark ? Colors.white70 : Colors.grey[700]!;
    final tertiaryTextColor = isDark ? Colors.white60 : Colors.grey[600]!;
    final commentBackgroundColor = isDark
        ? themeProvider.darkTheme.cardColor
        : const Color(0xFFF5F5F5);
    final inputFillColor = isDark
        ? themeProvider.darkTheme.cardColor
        : const Color(0xFFF5F5F5);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: appBarColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: appBarTextColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Detalles del Avistamiento',
          style: TextStyle(color: appBarTextColor),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImageSection(),
            _buildSpeciesInfo(),
            _buildLocationSection(),
            _buildDescriptionSection(),
            _buildCommentsSection(context),
            _buildAddCommentSection(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return Stack(
      children: [
        _buildMainImage(),
        Positioned(
          top: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _getEstadoColor(widget.avistamiento.estadoExtincion),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.shield, color: Colors.white, size: 16),
                const SizedBox(width: 4),
                Text(
                  widget.avistamiento.estadoExtincion.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMainImage() {
    try {
      if (widget.avistamiento.imagen.startsWith('http')) {
        return Image.network(
          widget.avistamiento.imagen,
          width: double.infinity,
          height: 250,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _placeholderImage(),
        );
      } else if (widget.avistamiento.imagen.isNotEmpty) {
        return Image.memory(
          base64Decode(widget.avistamiento.imagen),
          width: double.infinity,
          height: 250,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _placeholderImage(),
        );
      } else {
        return _placeholderImage();
      }
    } catch (e) {
      return _placeholderImage();
    }
  }

  Widget _placeholderImage() {
    return Container(
      width: double.infinity,
      height: 250,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [const Color(0xFF5C6445), const Color(0xFF939E69)],
        ),
      ),
      child: Icon(
        _getIconForEspecie(widget.avistamiento.especie),
        size: 80,
        color: Colors.white.withOpacity(0.5),
      ),
    );
  }

  Widget _buildSpeciesInfo() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final cardBackgroundColor = isDark
        ? themeProvider.darkTheme.cardColor
        : Colors.white;
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF0F1D33);
    final secondaryTextColor = isDark ? Colors.white70 : Colors.grey[700]!;

    return Container(
      padding: const EdgeInsets.all(20),
      color: cardBackgroundColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.avistamiento.nombreComun,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: primaryTextColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.avistamiento.nombreCientifico,
                      style: TextStyle(
                        fontSize: 16,
                        fontStyle: FontStyle.italic,
                        color: secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF5C6445).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getIconForEspecie(widget.avistamiento.especie),
                  size: 32,
                  color: const Color(0xFF5C6445),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            Icons.category,
            'Especie',
            widget.avistamiento.especie,
            primaryTextColor,
            secondaryTextColor,
          ),
          const SizedBox(height: 8),
          _buildInfoRow(
            Icons.forest,
            'Hábitat',
            widget.avistamiento.habitat.nombreHabitat,
            primaryTextColor,
            secondaryTextColor,
          ),
          const SizedBox(height: 8),
          _buildInfoRow(
            Icons.visibility,
            'Estado Espécimen',
            widget.avistamiento.estadoEspecimen,
            primaryTextColor,
            secondaryTextColor,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value,
    Color primaryTextColor,
    Color secondaryTextColor,
  ) {
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF5C6445)),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: primaryTextColor,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(fontSize: 14, color: secondaryTextColor),
          ),
        ),
      ],
    );
  }

  Widget _buildLocationSection() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final cardBackgroundColor = isDark
        ? themeProvider.darkTheme.cardColor
        : Colors.white;
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF0F1D33);
    final tertiaryTextColor = isDark ? Colors.white60 : Colors.grey[600]!;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.all(20),
      color: cardBackgroundColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'DATOS DE UBICACIÓN',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: primaryTextColor,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    const Icon(Icons.location_on, color: Color(0xFF5C6445)),
                    const SizedBox(height: 8),
                    Text(
                      'Latitud:',
                      style: TextStyle(fontSize: 12, color: tertiaryTextColor),
                    ),
                    Text(
                      widget.avistamiento.ubicacion.latitud.toStringAsFixed(6),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: primaryTextColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Longitud:',
                      style: TextStyle(fontSize: 12, color: tertiaryTextColor),
                    ),
                    Text(
                      widget.avistamiento.ubicacion.longitud.toStringAsFixed(6),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: primaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  height: 150,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  clipBehavior: Clip.hardEdge,
                  child: FlutterMap(
                    options: MapOptions(
                      initialCenter: LatLng(
                        widget.avistamiento.ubicacion.latitud,
                        widget.avistamiento.ubicacion.longitud,
                      ),
                      initialZoom: 14.0,
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.none,
                      ),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: LatLng(
                              widget.avistamiento.ubicacion.latitud,
                              widget.avistamiento.ubicacion.longitud,
                            ),
                            width: 40,
                            height: 40,
                            child: const Icon(
                              Icons.location_on,
                              color: Colors.red,
                              size: 40,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionSection() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final cardBackgroundColor = isDark
        ? themeProvider.darkTheme.cardColor
        : Colors.white;
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF0F1D33);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      color: cardBackgroundColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'DESCRIPCIÓN DEL AVISTAMIENTO',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: primaryTextColor,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF5C6445),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Descripción',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.avistamiento.descripcion,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Comportamiento',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.avistamiento.comportamiento,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentsSection(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final cardBackgroundColor = isDark
        ? themeProvider.darkTheme.cardColor
        : Colors.white;
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF0F1D33);
    final tertiaryTextColor = isDark ? Colors.white60 : Colors.grey[600]!;
    final commentBackgroundColor = isDark
        ? themeProvider.darkTheme.cardColor
        : const Color(0xFFF5F5F5);

    return Container(
      padding: const EdgeInsets.all(20),
      color: cardBackgroundColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'COMENTARIOS',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: primaryTextColor,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          if (_comentarios.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'No hay comentarios aún',
                  style: TextStyle(
                    color: tertiaryTextColor,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            )
          else
            ..._comentarios.map((comentario) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: commentBackgroundColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: const Color(0xFF5C6445),
                          radius: 20,
                          child: Text(
                            comentario.nombreUsuario[0].toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                comentario.nombreUsuario,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: primaryTextColor,
                                ),
                              ),
                              Text(
                                _formatDate(comentario.fecha),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: tertiaryTextColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      comentario.comentario,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.4,
                        color: primaryTextColor,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
        ],
      ),
    );
  }

  Widget _buildAddCommentSection() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final cardBackgroundColor = isDark
        ? themeProvider.darkTheme.cardColor
        : Colors.white;
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF0F1D33);
    final tertiaryTextColor = isDark ? Colors.white60 : Colors.grey[600]!;
    final inputFillColor = isDark
        ? themeProvider.darkTheme.cardColor
        : const Color(0xFFF5F5F5);

    return Container(
      padding: const EdgeInsets.all(20),
      color: cardBackgroundColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'AGREGAR COMENTARIO',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: primaryTextColor,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(width: 8),
              if (widget.nombreUsuario != null)
                Expanded(
                  child: Text(
                    'como ${widget.nombreUsuario}',
                    style: TextStyle(
                      fontSize: 12,
                      color: tertiaryTextColor,
                      fontStyle: FontStyle.italic,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _comentarioController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Escribe tu comentario aquí...',
              filled: true,
              fillColor: inputFillColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFF5C6445),
                  width: 2,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _agregarComentario,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5C6445),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Publicar Comentario',
                      style: TextStyle(
                        color: Color(0xFFE0E0E0),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

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
      default:
        return Icons.category;
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'Ene',
      'Feb',
      'Mar',
      'Abr',
      'May',
      'Jun',
      'Jul',
      'Ago',
      'Sep',
      'Oct',
      'Nov',
      'Dic',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  Color _getEstadoColor(String estado) {
    switch (estado.toLowerCase()) {
      case 'en peligro':
        return Colors.red;
      case 'vulnerable':
        return Colors.orange;
      case 'preocupación menor':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  void dispose() {
    _comentarioController.dispose();
    super.dispose();
  }
}
