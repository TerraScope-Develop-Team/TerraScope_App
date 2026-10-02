import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:terrascope/components/screens/profile_page.dart';
import 'dart:convert';
import '../../services/fauna_flora_service.dart';
import '../../components/models/avistamiento_model.dart';
import '../../config/api_config.dart';
import '../map/map_page.dart';
import '../map/avistamiento_detail_loader.dart';
import '../screens/registro_avistamiento_screen.dart';
import '../../services/session_service.dart';
import '../../providers/retos_observer_provider.dart';
import '../../services/notification_service.dart';
import '../../services/theme_service.dart';
import '../../services/routing_service.dart';
import '../../services/alerta_service.dart';
import '../../services/socket_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final FaunaFloraService _service;
  final SessionService _sessionService = SessionService();
  List<Avistamiento> _avistamientos = [];
  List<Avistamiento> _avistamientosFiltrados = [];
  bool _isLoading = true;
  String? _error;
  int _currentIndex = 0;
  String? _filtroTipo;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _service = FaunaFloraService(baseUrl: ApiConfig.baseUrl);
    _cargarAvistamientos();
    // Asegurar conexión al WebSocket (se hace en addPostFrameCallback)
    // Ensure notification service is set and then update retos and notifications
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<RetosObserverProvider>(
        context,
        listen: false,
      );
      final notificationService = Provider.of<NotificationService>(
        context,
        listen: false,
      );
      provider.setNotificationService(notificationService);
      
      SocketService().initSocket(
        onAlert: (title, body) {
          notificationService.showNotification(
            AppNotification(
              id: 'alerta_peligro_${DateTime.now().millisecondsSinceEpoch}',
              title: title,
              message: body,
              type: NotificationType.error,
              duration: const Duration(seconds: 10),
            )
          );
        }
      );

      _actualizarRetosYNotificaciones();
      _checkNearbyAlerts(notificationService);
    });
  }

  Future<void> _checkNearbyAlerts(NotificationService notificationService) async {
    try {
      final userData = await _sessionService.getUserData();
      final recibirAlertas = userData?['recibir_alertas_peligro'] ?? true;
      if (!recibirAlertas) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }

      Position? position = await Geolocator.getLastKnownPosition();
      if (position == null) {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.low,
          timeLimit: const Duration(seconds: 3),
        );
      }

      final alertas = await AlertaService().getNearbyDangerousAlerts(
        position.latitude, 
        position.longitude
      );

      if (alertas.isNotEmpty) {
        // Mostramos notificación de que hay animales peligrosos en el área
        final count = alertas.length;
        notificationService.showNotification(
          AppNotification(
            id: 'alerta_peligro_cercana_${DateTime.now().millisecondsSinceEpoch}',
            title: '¡Precaución! Zona de riesgo',
            message: 'Hay $count especie(s) peligrosa(s) reportada(s) cerca de ti recientemente.',
            type: NotificationType.error,
            duration: const Duration(seconds: 15),
          )
        );
      }
    } catch (e) {
      print('Error al buscar alertas cercanas: $e');
    }
  }

  Future<void> _actualizarRetosYNotificaciones() async {
    final provider = Provider.of<RetosObserverProvider>(context, listen: false);
    await provider.actualizarRetosYNotificaciones();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _cargarAvistamientos() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final avistamientos = await _service.getAllFaunaFlora();

      if (mounted) {
        setState(() {
          _avistamientos = avistamientos;
          _avistamientosFiltrados = avistamientos;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error al cargar avistamientos: $e';
          _isLoading = false;
        });
      }
    }
  }

  void _applyFilter(String? tipo) {
    setState(() {
      _filtroTipo = tipo;
    });
    _filtrarAvistamientos();
  }

  void _filtrarAvistamientos() {
    List<Avistamiento> filtrados = _avistamientos;

    if (_filtroTipo != null) {
      filtrados = filtrados
          .where((a) => a.tipo.toLowerCase() == _filtroTipo!.toLowerCase())
          .toList();
    }

    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      filtrados = filtrados
          .where(
            (a) =>
                a.nombreComun.toLowerCase().contains(query) ||
                a.nombreCientifico.toLowerCase().contains(query),
          )
          .toList();
    }

    setState(() {
      _avistamientosFiltrados = filtrados;
    });
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
            icon: Icon(Icons.emoji_events, color: appBarTextColor),
            onPressed: () {
              Navigator.pushNamed(context, '/retos');
            },
            tooltip: 'Desafíos',
          ),
          IconButton(
            icon: Icon(Icons.account_circle, color: appBarTextColor),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );

              if (result == true) {
                _cargarAvistamientos();
              }
            },
          ),
          IconButton(
            icon: Icon(Icons.camera_alt, color: appBarTextColor),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CreateAvistamientoScreen(),
                ),
              );

              if (result == true) {
                _cargarAvistamientos();
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? ListView.builder(
              itemCount: 3,
              padding: const EdgeInsets.all(16),
              itemBuilder: (context, index) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                  color: Colors.grey.withOpacity(0.1),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 40, 
                              height: 40, 
                              decoration: BoxDecoration(
                                color: Colors.grey.withOpacity(0.2), 
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(width: 120, height: 14, color: Colors.grey.withOpacity(0.2)),
                                const SizedBox(height: 6),
                                Container(width: 80, height: 10, color: Colors.grey.withOpacity(0.2)),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity, 
                          height: 200, 
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.2), 
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(width: 200, height: 16, color: Colors.grey.withOpacity(0.2)),
                      ],
                    ),
                  ),
                );
              },
            )
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFFE0E0E0),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _cargarAvistamientos,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reintentar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF939E69),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : Column(
              children: [
                _buildSearchAndFilters(primaryColor),
                Expanded(
                  child: _avistamientosFiltrados.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.pets_outlined,
                                size: 80,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No hay avistamientos',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[400],
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _cargarAvistamientos,
                          color: const Color(0xFF5C6445),
                          child: ListView.builder(
                            itemCount: _avistamientosFiltrados.length,
                            padding: const EdgeInsets.only(bottom: 16),
                            itemBuilder: (context, index) {
                              return AvistamientoCard(
                                data: _avistamientosFiltrados[index],
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          AvistamientoDetailLoader(
                                            avistamientoId:
                                                _avistamientosFiltrados[index]
                                                    .id,
                                            service: _service,
                                          ),
                                    ),
                                  );
                                },
                                service: _service,
                                sessionService: _sessionService,
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.red.withOpacity(0.4),
              blurRadius: 16,
              spreadRadius: 2,
              offset: const Offset(0, 4),
            )
          ],
          borderRadius: BorderRadius.circular(30),
        ),
        child: FloatingActionButton.extended(
          backgroundColor: Colors.red.shade700,
          foregroundColor: Colors.white,
          elevation: 0,
          onPressed: () async {
            // Confirmar con el usuario
            final confirm = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                title: const Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
                    SizedBox(width: 10),
                    Text('Emergencia SOS', style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                content: const Text(
                  '¿Estás seguro de que deseas enviar una alerta SOS?\n\n'
                  'Esto enviará tu ubicación a las autoridades y te conectará con el 911.',
                  style: TextStyle(height: 1.4),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancelar', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade700,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                    child: const Text('ENVIAR SOS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            );

          if (confirm != true) return;

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Obteniendo ubicación...'), duration: Duration(seconds: 2)),
          );

          // Obtener ubicación
          double lat = 0.0;
          double lng = 0.0;
          try {
            Position position = await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.high,
              timeLimit: const Duration(seconds: 10),
            );
            lat = position.latitude;
            lng = position.longitude;
            
            // Enviar al backend
            final alertaService = AlertaService();
            await alertaService.sendSOS(lat, lng);
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('No se pudo enviar ubicación al servidor, llamando al 911...')),
            );
          }

          // Llamar al 911
          final Uri url = Uri(scheme: 'tel', path: '911');
          if (await canLaunchUrl(url)) {
            await launchUrl(url);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('No se pudo abrir la aplicación de llamadas.')),
            );
          }
        },
        icon: const Icon(Icons.emergency, color: Colors.white, size: 26),
        label: const Text(
          'SOS', 
          style: TextStyle(
            fontWeight: FontWeight.bold, 
            fontSize: 16, 
            letterSpacing: 1.2
          )
        ),
      ),
    ),
    bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFFE0E0E0),
        selectedItemColor: const Color(0xFF5C6445),
        unselectedItemColor: Colors.grey,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });

          if (index == 1) {
            Navigator.pushReplacementNamed(context, '/map');
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: ''),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters(Color primaryColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: primaryColor,
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            onChanged: (value) => _filtrarAvistamientos(),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              hintText: 'Buscar...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildFilterChip('Todos', null),
              const SizedBox(width: 8),
              _buildFilterChip('Fauna', 'Fauna'),
              const SizedBox(width: 8),
              _buildFilterChip('Flora', 'Flora'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String? value) {
    final isSelected = _filtroTipo == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        _applyFilter(selected ? value : null);
      },
      backgroundColor: Colors.white,
      selectedColor: const Color(0xFF939E69),
      labelStyle: TextStyle(
        color: isSelected ? Colors.black : Colors.grey[700],
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }
}

class AvistamientoCard extends StatefulWidget {
  final Avistamiento data;
  final VoidCallback onTap;
  final FaunaFloraService service;
  final SessionService sessionService;

  const AvistamientoCard({
    super.key,
    required this.data,
    required this.onTap,
    required this.service,
    required this.sessionService,
  });

  @override
  State<AvistamientoCard> createState() => _AvistamientoCardState();
}

class _AvistamientoCardState extends State<AvistamientoCard> {
  String _idUsuario = '';
  String _rolUsuario = 'Usuario';
  bool _isLoadingValidacion = false;
  Map<String, dynamic>? _estadoValidacion;
  bool _yaVoto = false;

  @override
  void initState() {
    super.initState();
    _cargarUsuarioYValidacion();
  }

  /// 🔹 Carga usuario y validación en orden
  Future<void> _cargarUsuarioYValidacion() async {
    await _cargarUsuario();
    await _cargarEstadoValidacion();
  }

  /// 🔹 Cargar sesión de usuario
  Future<void> _cargarUsuario() async {
    final userData = await widget.sessionService.getUserData();

    print("🧠 [DEBUG] Datos de sesión obtenidos → $userData");

    if (mounted && userData != null) {
      setState(() {
        _idUsuario = userData['_id'] ?? '';
        _rolUsuario = userData['rol_usuario'] ?? 'Usuario';
      });

      print("👤 [DEBUG] Usuario actual → ID: $_idUsuario | Rol: $_rolUsuario");
    } else {
      print("⚠️ [DEBUG] No hay sesión activa o los datos son nulos.");
    }
  }

  /// 🔹 Cargar estado de validación
  Future<void> _cargarEstadoValidacion() async {
    if (widget.data.id.isEmpty) {
      print(
        "⚠️ [DEBUG] ID de avistamiento vacío, no se puede cargar validación.",
      );
      return;
    }

    setState(() => _isLoadingValidacion = true);
    try {
      final estado = await widget.service.getEstadoValidacion(widget.data.id);
      print("📋 [DEBUG] Estado de validación recibido → $estado");

      if (mounted) {
        setState(() {
          _estadoValidacion = estado;
          _yaVoto = estado?['yaVoto'] ?? false;
        });
      }
    } catch (e) {
      print('❌ Error al cargar validación: $e');
    } finally {
      if (mounted) setState(() => _isLoadingValidacion = false);
    }
  }

  /// 🔹 Votar como comunidad
  Future<void> _votar() async {
    if (_idUsuario.isEmpty) {
      print("⚠️ [DEBUG] No se puede votar: ID de usuario vacío.");
      return;
    }

    setState(() => _isLoadingValidacion = true);
    try {
      print(
        "📨 [DEBUG] Enviando voto de usuario $_idUsuario para ${widget.data.id}",
      );
      await widget.service.votarAvistamiento(widget.data.id);
    } catch (e) {
      // ⚠️ Aquí capturamos el error 400 y seguimos
      if (e.toString().contains('400')) {
        print('⚠️ Usuario ya votó, actualizando estado de validación...');
      } else {
        print('❌ Error al votar: $e');
      }
    } finally {
      // 🔹 Siempre recargamos estado de validación
      await _cargarEstadoValidacion();
      if (mounted) setState(() => _isLoadingValidacion = false);
    }
  }

  /// 🔹 Validar como experto
  Future<void> _validarComoExperto() async {
    if (_idUsuario.isEmpty) return;
    setState(() => _isLoadingValidacion = true);
    try {
      print("👨‍🔬 [DEBUG] Validación experta por $_rolUsuario ($_idUsuario)");
      await widget.service.validarComoExperto(widget.data.id);
      await _cargarEstadoValidacion();
    } catch (e) {
      print('❌ Error al validar como experto: $e');
    } finally {
      if (mounted) setState(() => _isLoadingValidacion = false);
    }
  }

  IconData _getExtincionIcon(String estado) {
    final estadoLower = estado.toLowerCase();
    if (estadoLower.contains('peligro') || estadoLower.contains('crítico')) {
      return Icons.warning;
    } else if (estadoLower.contains('vulnerable') ||
        estadoLower.contains('amenazado')) {
      return Icons.error_outline;
    } else if (estadoLower.contains('preocupación') ||
        estadoLower.contains('menor')) {
      return Icons.info_outline;
    }
    return Icons.check_circle_outline;
  }

  Color _getExtincionColor(String estado) {
    final estadoLower = estado.toLowerCase();
    if (estadoLower.contains('peligro') || estadoLower.contains('crítico')) {
      return Colors.red;
    } else if (estadoLower.contains('vulnerable') ||
        estadoLower.contains('amenazado')) {
      return Colors.orange;
    } else if (estadoLower.contains('preocupación') ||
        estadoLower.contains('menor')) {
      return Colors.amber;
    }
    return Colors.green;
  }

  Widget _buildPlaceholder() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Icon(Icons.image_outlined, size: 80, color: Colors.grey[400]),
        Positioned(
          bottom: 60,
          right: 80,
          child: Icon(Icons.pets, size: 50, color: Colors.grey[300]),
        ),
        Positioned(
          top: 80,
          left: 100,
          child: Icon(Icons.nature, size: 40, color: Colors.grey[300]),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, Color primaryTextColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 180,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: primaryTextColor,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 16, color: primaryTextColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComentarioCard(
    comentario,
    Color primaryTextColor,
    Color cardBackgroundColor,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: cardBackgroundColor,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFF5C6445),
                  radius: 16,
                  child: Text(
                    comentario.nombreUsuario[0].toUpperCase(),
                    style: const TextStyle(
                      color: Color(0xFFE0E0E0),
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  comentario.nombreUsuario,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: primaryTextColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              comentario.comentario,
              style: TextStyle(fontSize: 14, color: primaryTextColor),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    // Theme-aware colors
    final cardBackgroundColor = isDark
        ? themeProvider.darkTheme.cardColor
        : const Color(0xFFE0E0E0);
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF0F1D33);
    final secondaryTextColor = isDark ? Colors.white70 : Colors.grey[700]!;
    final tertiaryTextColor = isDark ? Colors.white60 : Colors.grey[600]!;

    final votos = _estadoValidacion?['votos_comunidad'] ?? 0;
    final requeridos = _estadoValidacion?['requeridos_comunidad'] ?? 0;
    final validado = _estadoValidacion?['validado_por_experto'] ?? false;
    final yaVoto = _estadoValidacion?['yaVoto'] ?? false;

    // 🔹 Logs para depuración
    print("🧠 Usuario: $_idUsuario | Rol: $_rolUsuario");
    print(
      "📊 Estado validación → votos: $votos, requeridos: $requeridos, validado: $validado",
    );

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
      elevation: 1,
      color: cardBackgroundColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🔹 Header con usuario
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFF5C6445),
                  radius: 20,
                  child: Text(
                    widget.data.nombreComun[0].toUpperCase(),
                    style: const TextStyle(
                      color: Color(0xFFE0E0E0),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '@${widget.data.nombreUsuario}',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: primaryTextColor,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.more_vert, color: primaryTextColor),
                  onPressed: () {},
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),

          // 🔹 Imagen del avistamiento
          GestureDetector(
            onTap: widget.onTap,
            child: Container(
              width: double.infinity,
              height: 250,
              color: Colors.grey[300],
              child: widget.data.imagen.isNotEmpty
                  ? Image.memory(
                      base64Decode(widget.data.imagen),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _buildPlaceholder(),
                    )
                  : _buildPlaceholder(),
            ),
          ),

          // 🔹 Información general
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.data.nombreComun,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: primaryTextColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.data.nombreCientifico,
                  style: TextStyle(
                    fontSize: 14,
                    color: secondaryTextColor,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 12),
                _buildInfoRow('Tipo', widget.data.tipo, primaryTextColor),
                _buildInfoRow('Especie', widget.data.especie, primaryTextColor),
                _buildInfoRow(
                  'Estado de conservación',
                  widget.data.estadoExtincion,
                  primaryTextColor,
                ),
                _buildInfoRow(
                  'Estado del especímen',
                  widget.data.estadoEspecimen,
                  primaryTextColor,
                ),
                const SizedBox(height: 12),

                // 🔹 Sección de validación y votos
                _isLoadingValidacion
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16.0),
                        child: Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Color(0xFF5C6445),
                            ),
                            strokeWidth: 3,
                          ),
                        ),
                      )
                    : Container(
                        margin: const EdgeInsets.only(top: 8),
                        padding: const EdgeInsets.all(14.0),
                        decoration: BoxDecoration(
                          color: validado
                              ? Colors.green.withOpacity(0.08)
                              : const Color(0xFF5C6445).withOpacity(0.05),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: validado
                                ? Colors.green.withOpacity(0.4)
                                : const Color(0xFF5C6445).withOpacity(0.2),
                            width: 1.5,
                          ),
                        ),
                        child: validado
                            ? Row(
                                mainAxisSize: MainAxisSize.max,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(7),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withOpacity(0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.verified,
                                      color: Colors.green,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Validado por experto',
                                          style: TextStyle(
                                            color: Colors.green,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                        Text(
                                          '$votos votos de la comunidad',
                                          style: TextStyle(
                                            color: Colors.green.shade700,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              )
                            : _rolUsuario.toLowerCase() != 'usuario'
                            ? ElevatedButton.icon(
                                onPressed: _validarComoExperto,
                                icon: const Icon(Icons.verified, size: 18),
                                label: const Text(
                                  'Validar como experto',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF5C6445),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  elevation: 1,
                                ),
                              )
                            : Column(
                                mainAxisSize:
                                    MainAxisSize.min, // 👈 CRÍTICO para scroll
                                crossAxisAlignment: CrossAxisAlignment
                                    .stretch, // 👈 Evita saltos
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.max,
                                    children: [
                                      Expanded(
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                          child: LinearProgressIndicator(
                                            value: requeridos > 0
                                                ? votos / requeridos
                                                : 0,
                                            backgroundColor:
                                                Colors.grey.shade300,
                                            valueColor:
                                                const AlwaysStoppedAnimation<
                                                  Color
                                                >(Color(0xFF5C6445)),
                                            minHeight: 6,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        '$votos/$requeridos',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF5C6445),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  !_yaVoto
                                      ? ElevatedButton.icon(
                                          onPressed: _idUsuario.isEmpty
                                              ? null
                                              : _votar,
                                          icon: const Icon(
                                            Icons.how_to_vote,
                                            size: 18,
                                          ),
                                          label: const Text(
                                            'Validar',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(
                                              0xFF5C6445,
                                            ),
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 12,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            elevation: 1,
                                            disabledBackgroundColor:
                                                Colors.grey.shade300,
                                            disabledForegroundColor:
                                                Colors.grey.shade500,
                                          ),
                                        )
                                      : Container(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 12,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(
                                              0xFF5C6445,
                                            ).withOpacity(0.12),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            border: Border.all(
                                              color: const Color(
                                                0xFF5C6445,
                                              ).withOpacity(0.35),
                                              width: 1.5,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.max,
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: const [
                                              Icon(
                                                Icons.check_circle,
                                                color: Color(0xFF5C6445),
                                                size: 18,
                                              ),
                                              SizedBox(width: 8),
                                              Text(
                                                'Ya has votado',
                                                style: TextStyle(
                                                  color: Color(0xFF5C6445),
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Se necesitan $requeridos votos',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                      ),

                const SizedBox(height: 16),

                // 🔹 Botón de detalle
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AvistamientoDetailLoader(
                            avistamientoId: widget.data.id,
                            service: widget.service,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5C6445),
                      foregroundColor: const Color(0xFFE0E0E0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 10,
                      ),
                    ),
                    child: const Text('Ver a detalle'),
                  ),
                ),

                const SizedBox(height: 16),

                // 🔹 Comentarios
                Text(
                  'Comentarios:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: primaryTextColor,
                  ),
                ),
                const SizedBox(height: 8),
                if (widget.data.comentarios != null &&
                    widget.data.comentarios.isNotEmpty)
                  ...widget.data.comentarios.map(
                    (c) => _buildComentarioCard(
                      c,
                      primaryTextColor,
                      cardBackgroundColor,
                    ),
                  )
                else
                  Text(
                    'No hay comentarios',
                    style: TextStyle(color: primaryTextColor),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
