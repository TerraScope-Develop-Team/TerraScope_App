import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/avistamiento_model.dart';
import '../models/zona_frecuente.dart';
import '../../services/avistamiento_service.dart';
import '../../services/alerta_service.dart';
import '../ui/slide_to_confirm.dart';
import 'avistamiento_detail_card.dart';
import 'avistamiento_detail_page.dart';
import '../screens/pagina_inicio.dart';
import '../export/export_dialog.dart';
import '../../services/routing_service.dart';
import '../../services/theme_service.dart';

class MapPage extends StatefulWidget {
  final String? usuarioId;
  final String? nombreUsuario;
  const MapPage({super.key, this.usuarioId, this.nombreUsuario});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  LatLng? _currentPosition;
  List<Avistamiento> _avistamientos = [];
  List<Avistamiento> _filteredAvistamientos = [];
  List<ZonaFrecuente> _zonasFrecuentes = [];
  String? _filtroEspecie;
  Avistamiento? _selectedAvistamiento;
  bool _isLoading = true;
  bool _locationError = false;
  bool _isSearching = false;
  int _currentIndex = 0;
  List<LatLng> _routePoints = [];
  bool _isLoadingRoute = false;

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  Future<void> _initializeMap() async {
    await _requestLocationPermission();
    await _getCurrentLocation();
    await _loadAvistamientos();
    await _loadZonasFrecuentes();
  }

  Future<void> _requestLocationPermission() async {
    final status = await Permission.location.request();
    if (!status.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Permiso de ubicación denegado')),
        );
      }
    }
  }

  Future<void> _showRouteToAvistamiento(Avistamiento avistamiento) async {
    if (_currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo obtener tu ubicación'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoadingRoute = true;
      _routePoints = [];
    });

    try {
      final start = _currentPosition!;
      final end = LatLng(
        avistamiento.ubicacion.latitud,
        avistamiento.ubicacion.longitud,
      );

      // Calcular distancia
      final distance = RoutingService.calculateDistance(start, end);

      if (distance > 50) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'El avistamiento está a ${distance.toStringAsFixed(1)} km. Debe estar dentro de 50 km.',
            ),
            backgroundColor: Colors.orange,
          ),
        );
        setState(() {
          _isLoadingRoute = false;
        });
        return;
      }

      // Obtener ruta
      final route = await RoutingService.getRoute(start, end);

      if (route.isEmpty) {
        throw Exception('No se pudo calcular la ruta');
      }

      setState(() {
        _routePoints = route;
        _isLoadingRoute = false;
        _selectedAvistamiento = avistamiento;
      });

      // Centrar mapa en la ruta
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: LatLngBounds.fromPoints([start, end]),
          padding: const EdgeInsets.all(50),
        ),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ruta trazada: ${distance.toStringAsFixed(1)} km'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _isLoadingRoute = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al calcular ruta: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Servicios de ubicación deshabilitados');
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (mounted) {
        setState(() {
          _currentPosition = LatLng(position.latitude, position.longitude);
          _locationError = false;
        });

        _mapController.move(_currentPosition!, 13.0);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _locationError = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ubicación obtenida correctamente')),
        );
      }
    }
  }

  Future<void> _loadAvistamientos() async {
    try {
      final avistamientos = await AvistamientoService.getAvistamientos(
        especie: _filtroEspecie,
      );
      if (mounted) {
        setState(() {
          _avistamientos = avistamientos;
          _filteredAvistamientos = avistamientos;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar avistamientos: $e')),
        );
      }
    }
  }

  Future<void> _loadZonasFrecuentes() async {
    try {
      final zonas = await AvistamientoService.getZonasFrecuentes();
      if (mounted) {
        setState(() {
          _zonasFrecuentes = zonas;
        });
      }
    } catch (e) {
      print('Error al cargar zonas frecuentes: $e');
    }
  }

  void _applyFilter(String? especie) {
    setState(() {
      _filtroEspecie = especie;
      _isLoading = true;
    });
    _loadAvistamientos();
  }

  Future<void> _searchAvistamientos(String query) async {
    setState(() => _isSearching = true);

    try {
      if (query.isEmpty) {
        setState(() {
          _filteredAvistamientos = _avistamientos;
          _isSearching = false;
        });
        return;
      }

      final results = await AvistamientoService.searchAvistamientos(query);
      setState(() {
        _filteredAvistamientos = results;
        _isSearching = false;
      });

      if (results.isNotEmpty) {
        _mapController.move(
          LatLng(
            results.first.ubicacion.latitud,
            results.first.ubicacion.longitud,
          ),
          15.0,
        );
      }
    } catch (e) {
      setState(() => _isSearching = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error en la búsqueda: $e')));
    }
  }

  void _centerOnUserLocation() {
    if (_currentPosition != null) {
      _mapController.move(_currentPosition!, 15.0);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Ubicación no disponible')));
    }
  }

  Future<void> _exportToExcel() async {
    showDialog(
      context: context,
      builder: (context) => ExportDialog(avistamientos: _filteredAvistamientos),
    );
  }

  List<Marker> _buildMarkers() {
    List<Marker> markers = [];

    // Marcador del usuario
    if (_currentPosition != null) {
      markers.add(
        Marker(
          point: _currentPosition!,
          width: 50,
          height: 50,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 6,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(Icons.person_pin, color: Colors.white, size: 30),
          ),
        ),
      );
    }

    for (var avistamiento in _filteredAvistamientos) {
      markers.add(
        Marker(
          point: LatLng(
            avistamiento.ubicacion.latitud,
            avistamiento.ubicacion.longitud,
          ),
          width: 50,
          height: 50,
          child: GestureDetector(
            onTap: () {
              setState(() {
                _selectedAvistamiento = avistamiento;
              });
            },
            child: Container(
              decoration: BoxDecoration(
                color: _getColorForEspecie(avistamiento.especie),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Icon(
                _getIconForEspecie(avistamiento.especie),
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ),
      );
    }

    return markers;
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
      case 'otro':
        return Icons.category;
      default:
        return Icons.help_outline;
    }
  }

  Color _getColorForEspecie(String especie) {
    switch (especie.toLowerCase()) {
      case 'mamífero':
      case 'mamifero':
        return const Color(0xFF8D6E63); // Café
      case 'ave':
        return const Color(0xFF42A5F5); // Azul cielo
      case 'reptil':
        return const Color(0xFF66BB6A); // Verde
      case 'anfibio':
        return const Color(0xFF26C6DA); // Cyan
      case 'pez':
        return const Color(0xFF29B6F6); // Azul agua
      case 'insecto':
        return const Color(0xFFFFCA28); // Amarillo
      case 'planta':
        return const Color(0xFF4CAF50); // Verde planta
      case 'otro':
        return const Color(0xFF9E9E9E); // Gris
      default:
        return const Color(0xFF757575); // Gris oscuro
    }
  }

  List<CircleMarker> _buildCircles() {
    List<CircleMarker> circles = [];

    for (var zona in _zonasFrecuentes) {
      circles.add(
        CircleMarker(
          point: LatLng(zona.lat, zona.lng),
          radius: 600,
          useRadiusInMeter: true,
          color: Colors.red.withOpacity(0.2),
          borderColor: Colors.red.withOpacity(0.5),
          borderStrokeWidth: 2,
        ),
      );
    }

    for (var avistamiento in _filteredAvistamientos) {
      final estado = avistamiento.estadoExtincion.toLowerCase();
      if (estado == 'preocupación menor') {
        circles.add(
          CircleMarker(
            point: LatLng(
              avistamiento.ubicacion.latitud,
              avistamiento.ubicacion.longitud,
            ),
            radius: 500,
            useRadiusInMeter: true,
            color: Colors.green.withOpacity(0.15),
            borderColor: Colors.green.withOpacity(0.6),
            borderStrokeWidth: 3,
          ),
        );
      } else if (estado == 'vulnerable') {
        circles.add(
          CircleMarker(
            point: LatLng(
              avistamiento.ubicacion.latitud,
              avistamiento.ubicacion.longitud,
            ),
            radius: 500,
            useRadiusInMeter: true,
            color: Colors.yellow.withOpacity(0.15),
            borderColor: Colors.yellow.withOpacity(0.6),
            borderStrokeWidth: 3,
          ),
        );
      } else if (estado == 'en peligro') {
        circles.add(
          CircleMarker(
            point: LatLng(
              avistamiento.ubicacion.latitud,
              avistamiento.ubicacion.longitud,
            ),
            radius: 500,
            useRadiusInMeter: true,
            color: Colors.orange.withOpacity(0.15),
            borderColor: Colors.orange.withOpacity(0.6),
            borderStrokeWidth: 3,
          ),
        );
      } else if (estado == 'en peligro crítico') {
        circles.add(
          CircleMarker(
            point: LatLng(
              avistamiento.ubicacion.latitud,
              avistamiento.ubicacion.longitud,
            ),
            radius: 500,
            useRadiusInMeter: true,
            color: Colors.red.withOpacity(0.15),
            borderColor: Colors.red.withOpacity(0.6),
            borderStrokeWidth: 3,
          ),
        );
      } else if (estado == 'extinto') {
        circles.add(
          CircleMarker(
            point: LatLng(
              avistamiento.ubicacion.latitud,
              avistamiento.ubicacion.longitud,
            ),
            radius: 500,
            useRadiusInMeter: true,
            color: Colors.black.withOpacity(0.15),
            borderColor: Colors.black.withOpacity(0.6),
            borderStrokeWidth: 3,
          ),
        );
      }
    }

    return circles;
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    // Theme-aware colors
    final primaryColor = isDark
        ? themeProvider.darkTheme.primaryColor
        : const Color(0xFF5C6445);
    final secondaryColor = isDark
        ? themeProvider.darkTheme.scaffoldBackgroundColor
        : const Color(0xFFE0E0E0);
    final accentColor = isDark
        ? themeProvider.darkTheme.colorScheme.secondary
        : const Color(0xFF939E69);
    final appBarTextColor = isDark ? Colors.white : secondaryColor;

    return Scaffold(
      backgroundColor: primaryColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'TerraScope',
              style: TextStyle(
                color: appBarTextColor,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.eco, color: appBarTextColor, size: 28),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.file_download, color: appBarTextColor),
            onPressed: _exportToExcel,
            tooltip: 'Exportar a Excel',
          ),
          IconButton(
            icon: Icon(Icons.settings, color: appBarTextColor),
            onPressed: () {},
          ),
        ],
      ),
      body: _isLoading && _avistamientos.isEmpty
          ? Center(child: CircularProgressIndicator(color: secondaryColor))
          : Stack(
              children: [
                Column(
                  children: [
                    _buildSearchAndFilters(),
                    Expanded(child: _buildMap()),
                  ],
                ),
                if (_selectedAvistamiento != null)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: AvistamientoDetailCard(
                      avistamiento: _selectedAvistamiento!,
                      userPosition: _currentPosition != null
                          ? Position(
                              latitude: _currentPosition!.latitude,
                              longitude: _currentPosition!.longitude,
                              timestamp: DateTime.now(),
                              accuracy: 0,
                              altitude: 0,
                              altitudeAccuracy: 0,
                              heading: 0,
                              headingAccuracy: 0,
                              speed: 0,
                              speedAccuracy: 0,
                            )
                          : null,
                      onClose: () {
                        setState(() {
                          _selectedAvistamiento = null;
                          _routePoints = []; // Limpiar ruta
                        });
                      },
                      onViewDetails: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AvistamientoDetailPage(
                              avistamiento: _selectedAvistamiento!,
                              usuarioId: widget.usuarioId,
                              nombreUsuario: widget.nombreUsuario,
                            ),
                          ),
                        );
                      },
                      onShowRoute: () {
                        _showRouteToAvistamiento(_selectedAvistamiento!);
                      },
                    ),
                  ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _centerOnUserLocation,
        backgroundColor: primaryColor,
        child: Icon(Icons.my_location, color: secondaryColor),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: secondaryColor,
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.grey,
        currentIndex: _currentIndex > 1 ? 0 : _currentIndex,
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacementNamed(context, '/home');
          } else if (index == 1) {
            // SOS
            showModalBottomSheet(
              context: context,
              backgroundColor: Colors.transparent,
              builder: (context) => Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 48),
                    const SizedBox(height: 16),
                    const Text(
                      'Emergencia SOS',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Esto enviará tu ubicación a las autoridades y te conectará con el 911 de inmediato.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.black87, height: 1.4, fontSize: 16),
                    ),
                    const SizedBox(height: 32),
                    SlideToConfirm(
                      baseColor: Colors.red.shade700,
                      onConfirm: () async {
                        Navigator.pop(context);
                        double lat = _currentPosition?.latitude ?? 0.0;
                        double lng = _currentPosition?.longitude ?? 0.0;
                        try {
                          if (lat == 0.0) {
                            final position = await Geolocator.getCurrentPosition(
                              desiredAccuracy: LocationAccuracy.high,
                              timeLimit: const Duration(seconds: 10),
                            );
                            lat = position.latitude;
                            lng = position.longitude;
                          }
                          final alertaService = AlertaService();
                          await alertaService.sendSOS(lat, lng);
                        } catch (e) {
                          // continúa con llamada aunque falle el envío
                        }
                        final Uri url = Uri(scheme: 'tel', path: '911');
                        if (await canLaunchUrl(url)) {
                          await launchUrl(url);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancelar', style: TextStyle(color: Colors.grey, fontSize: 16)),
                    ),
                  ],
                ),
              ),
            );
          } else if (index == 2) {
            // Ya estamos en el mapa
            setState(() { _currentIndex = 2; });
          }
        },
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
          const BottomNavigationBarItem(
            icon: Icon(Icons.emergency, color: Colors.red),
            label: 'SOS',
          ),
          const BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Mapa'),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    // Theme-aware colors
    final primaryColor = isDark
        ? themeProvider.darkTheme.primaryColor
        : const Color(0xFF5C6445);
    final secondaryColor = isDark
        ? themeProvider.darkTheme.scaffoldBackgroundColor
        : const Color(0xFFE0E0E0);

    return Container(
      padding: const EdgeInsets.all(16),
      color: primaryColor,
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            onChanged: (value) {
              _searchAvistamientos(value);
            },
            decoration: InputDecoration(
              filled: true,
              fillColor: secondaryColor,
              hintText: 'Buscar por nombre, especie...',
              prefixIcon: _isSearching
                  ? const Padding(
                      padding: EdgeInsets.all(12.0),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _searchAvistamientos('');
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('Todos', null),
                const SizedBox(width: 8),
                _buildFilterChip('Mamífero', 'Mamífero'),
                const SizedBox(width: 8),
                _buildFilterChip('Ave', 'Ave'),
                const SizedBox(width: 8),
                _buildFilterChip('Reptil', 'Reptil'),
                const SizedBox(width: 8),
                _buildFilterChip('Anfibio', 'Anfibio'),
                const SizedBox(width: 8),
                _buildFilterChip('Pez', 'Pez'),
                const SizedBox(width: 8),
                _buildFilterChip('Insecto', 'Insecto'),
                const SizedBox(width: 8),
                _buildFilterChip('Planta', 'Planta'),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: secondaryColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${_filteredAvistamientos.length} resultados',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String? value) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    // Theme-aware colors
    final secondaryColor = isDark
        ? themeProvider.darkTheme.scaffoldBackgroundColor
        : const Color(0xFFE0E0E0);
    final accentColor = isDark
        ? themeProvider.darkTheme.colorScheme.secondary
        : const Color(0xFF939E69);

    final isSelected = _filtroEspecie == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        _applyFilter(selected ? value : null);
      },
      backgroundColor: secondaryColor,
      selectedColor: accentColor,
      labelStyle: TextStyle(
        color: isSelected ? Colors.black : Colors.grey[700],
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildMap() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    // Theme-aware colors
    final secondaryColor = isDark
        ? themeProvider.darkTheme.scaffoldBackgroundColor
        : const Color(0xFFE0E0E0);

    if (_currentPosition == null && !_locationError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: secondaryColor),
            const SizedBox(height: 16),
            Text(
              'Obteniendo ubicación...',
              style: TextStyle(color: secondaryColor),
            ),
          ],
        ),
      );
    }

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _currentPosition ?? const LatLng(0, 0),
        initialZoom: 13.0,
        onTap: (_, __) {
          setState(() {
            _selectedAvistamiento = null;
            _routePoints = []; // Limpiar ruta al tocar el mapa
          });
        },
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.terrascope',
        ),
        CircleLayer(circles: _buildCircles()),

        // AGREGAR ESTA CAPA PARA LA RUTA
        if (_routePoints.isNotEmpty)
          PolylineLayer(
            polylines: [
              Polyline(
                points: _routePoints,
                strokeWidth: 4.0,
                color: const Color(0xFF2E7D32),
                borderStrokeWidth: 2.0,
                borderColor: Colors.white,
              ),
            ],
          ),

        MarkerLayer(markers: _buildMarkers()),

        // Indicador de carga de ruta
        if (_isLoadingRoute)
          Positioned(
            top: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 8),
                  Text('Calculando ruta...'),
                ],
              ),
            ),
          ),
      ],
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
