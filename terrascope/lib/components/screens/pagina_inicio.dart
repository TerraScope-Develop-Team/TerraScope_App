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
import '../../services/danger_alert_presenter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import '../ui/slide_to_confirm.dart';
import 'notification_center_screen.dart';

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
  bool _mostrarSoloSeguidos = false;
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
        onAlert: (title, body, alertData) async {
          try {
            await DangerAlertPresenter.present(
              notificationService: notificationService,
              alert: alertData,
              title: title,
              message: body,
            );
          } catch (error) {
            debugPrint('No se pudo presentar la alerta de fauna: $error');
          }
        },
      );

      _actualizarRetosYNotificaciones();
      _loadDangerousAlerts(notificationService);
    });
  }

  Future<void> _loadDangerousAlerts(
    NotificationService notificationService,
  ) async {
    try {
      final userData = await _sessionService.getUserData();
      final receiveDangerAlerts = userData?['recibir_alertas_peligro'] ?? true;
      final alertaService = AlertaService();

      if (receiveDangerAlerts) {
        try {
          var permission = await Geolocator.checkPermission();
          if (permission == LocationPermission.denied) {
            permission = await Geolocator.requestPermission();
          }

          if (permission != LocationPermission.denied &&
              permission != LocationPermission.deniedForever) {
            var position = await Geolocator.getLastKnownPosition();
            position ??= await Geolocator.getCurrentPosition(
              locationSettings: const LocationSettings(
                accuracy: LocationAccuracy.low,
                timeLimit: Duration(seconds: 3),
              ),
            );
            await alertaService.getNearbyDangerousAlerts(
              position.latitude,
              position.longitude,
            );
          }
        } catch (error) {
          debugPrint('No se pudieron sincronizar alertas cercanas: $error');
        }
      }

      final alerts = await alertaService.getDangerousAlerts();
      if (!mounted) return;

      notificationService.setUnreadDangerousAlerts(
        alerts
            .where((alert) => alert['leida'] != true)
            .map((alert) => alert['id']?.toString())
            .whereType<String>(),
      );

      if (!receiveDangerAlerts) return;

      final now = DateTime.now();
      for (final alert in alerts) {
        final createdAt = DateTime.tryParse(
          alert['createdAt']?.toString() ?? '',
        )?.toLocal();
        final isRecent =
            createdAt != null &&
            !createdAt.isAfter(now) &&
            now.difference(createdAt) <= const Duration(hours: 24);
        if (alert['mostrada'] == true || !isRecent) continue;

        try {
          await DangerAlertPresenter.present(
            notificationService: notificationService,
            alert: alert,
            title: '¡Precaución! Zona de riesgo',
            message:
                'Especie peligrosa detectada cerca: ${alert['especie'] ?? 'Desconocida'}',
          );
        } catch (error) {
          debugPrint('No se pudo presentar la alerta pendiente: $error');
        }
        break;
      }
    } catch (e) {
      debugPrint('Error al cargar alertas de fauna: $e');
    }
  }

  Future<void> _refreshUnreadAlertCount() async {
    try {
      final alerts = await AlertaService().getDangerousAlerts();
      if (!mounted) return;
      Provider.of<NotificationService>(
        context,
        listen: false,
      ).setUnreadDangerousAlerts(
        alerts
            .where((alert) => alert['leida'] != true)
            .map((alert) => alert['id']?.toString())
            .whereType<String>(),
      );
    } catch (error) {
      debugPrint('Error al actualizar el contador de alertas: $error');
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

      final avistamientos = _mostrarSoloSeguidos
          ? await _service.getFeed()
          : await _service.getAllFaunaFlora();

      if (mounted) {
        setState(() {
          _avistamientos = avistamientos;
          _avistamientosFiltrados = avistamientos;
          _isLoading = false;
        });
        _filtrarAvistamientos();
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
    final unreadAlertCount = Provider.of<NotificationService>(
      context,
    ).unreadDangerousAlertCount;
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
            tooltip: 'Centro de notificaciones',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const NotificationCenterScreen(),
                ),
              );
              await _refreshUnreadAlertCount();
            },
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(Icons.notifications_outlined, color: appBarTextColor),
                if (unreadAlertCount > 0)
                  Positioned(
                    right: -7,
                    top: -7,
                    child: Container(
                      constraints: const BoxConstraints(
                        minWidth: 17,
                        minHeight: 17,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        unreadAlertCount > 99 ? '99+' : '$unreadAlertCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
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
                                Container(
                                  width: 120,
                                  height: 14,
                                  color: Colors.grey.withOpacity(0.2),
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  width: 80,
                                  height: 10,
                                  color: Colors.grey.withOpacity(0.2),
                                ),
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
                        Container(
                          width: 200,
                          height: 16,
                          color: Colors.grey.withOpacity(0.2),
                        ),
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
                                _mostrarSoloSeguidos
                                    ? Icons.people_outline
                                    : Icons.pets_outlined,
                                size: 80,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _mostrarSoloSeguidos
                                    ? 'Tu feed está vacío'
                                    : 'No hay avistamientos',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[400],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (_mostrarSoloSeguidos) ...[
                                const SizedBox(height: 8),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 32,
                                  ),
                                  child: Text(
                                    'Sigue a otros exploradores para ver sus publicaciones aquí.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                ),
                              ],
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
      floatingActionButton: null,
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFFE0E0E0),
        selectedItemColor: const Color(0xFF5C6445),
        unselectedItemColor: Colors.grey,
        currentIndex: _currentIndex > 1 ? 1 : _currentIndex,
        onTap: (index) {
          if (index == 0) {
            setState(() {
              _currentIndex = 0;
            });
          } else if (index == 1) {
            // SOS
            showModalBottomSheet(
              context: context,
              backgroundColor: Colors.transparent,
              builder: (ctx) => Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.red,
                      size: 48,
                    ),
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
                      style: TextStyle(
                        color: Colors.black87,
                        height: 1.4,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 32),
                    SlideToConfirm(
                      baseColor: Colors.red.shade700,
                      onConfirm: () async {
                        Navigator.pop(ctx);
                        double lat = 0.0;
                        double lng = 0.0;
                        try {
                          Position position =
                              await Geolocator.getCurrentPosition(
                                desiredAccuracy: LocationAccuracy.high,
                                timeLimit: const Duration(seconds: 10),
                              );
                          lat = position.latitude;
                          lng = position.longitude;
                          final alertaService = AlertaService();
                          await alertaService.sendSOS(lat, lng);
                        } catch (e) {
                          // Continúa con llamada aunque falle envío
                        }
                        final Uri url = Uri(scheme: 'tel', path: '911');
                        if (await canLaunchUrl(url)) await launchUrl(url);
                      },
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text(
                        'Cancelar',
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            );
          } else if (index == 2) {
            Navigator.pushReplacementNamed(context, '/map');
          }
        },
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Inicio',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.emergency, color: Colors.red),
            label: 'SOS',
          ),
          const BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Mapa'),
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
          // 🔹 Selector de Feed: Explorar todo vs Siguiendo
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(25),
            ),
            padding: const EdgeInsets.all(4),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () {
                      if (_mostrarSoloSeguidos) {
                        setState(() => _mostrarSoloSeguidos = false);
                        _cargarAvistamientos();
                      }
                    },
                    borderRadius: BorderRadius.circular(22),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: !_mostrarSoloSeguidos
                            ? Colors.white
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Center(
                        child: Text(
                          'Explorar todo',
                          style: TextStyle(
                            color: !_mostrarSoloSeguidos
                                ? Colors.black87
                                : Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () {
                      if (!_mostrarSoloSeguidos) {
                        setState(() => _mostrarSoloSeguidos = true);
                        _cargarAvistamientos();
                      }
                    },
                    borderRadius: BorderRadius.circular(22),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: _mostrarSoloSeguidos
                            ? Colors.white
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.people,
                              size: 16,
                              color: _mostrarSoloSeguidos
                                  ? Colors.black87
                                  : Colors.white,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Siguiendo',
                              style: TextStyle(
                                color: _mostrarSoloSeguidos
                                    ? Colors.black87
                                    : Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
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

  late bool _userHasLiked;
  late int _totalLikes;
  bool _isTogglingLike = false;

  @override
  void initState() {
    super.initState();
    _totalLikes = widget.data.totalLikes;
    _userHasLiked = widget.data.userHasLiked;
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
        _idUsuario = userData['_id'] ?? userData['id'] ?? '';
        _rolUsuario = userData['rol_usuario'] ?? userData['rol'] ?? 'Usuario';
        if (_idUsuario.isNotEmpty && widget.data.likes.isNotEmpty) {
          _userHasLiked = widget.data.likes.contains(_idUsuario);
        }
      });

      print("👤 [DEBUG] Usuario actual → ID: $_idUsuario | Rol: $_rolUsuario");
    } else {
      print("⚠️ [DEBUG] No hay sesión activa o los datos son nulos.");
    }
  }

  Future<void> _toggleLike() async {
    if (_isTogglingLike) return;
    setState(() {
      _isTogglingLike = true;
      _userHasLiked = !_userHasLiked;
      _totalLikes += _userHasLiked ? 1 : -1;
      if (_totalLikes < 0) _totalLikes = 0;
    });

    try {
      final res = await widget.service.toggleLike(widget.data.id);
      if (mounted) {
        setState(() {
          _userHasLiked = res['liked'] == true;
          _totalLikes = (res['total_likes'] as num).toInt();
          _isTogglingLike = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _userHasLiked = !_userHasLiked;
          _totalLikes += _userHasLiked ? 1 : -1;
          if (_totalLikes < 0) _totalLikes = 0;
          _isTogglingLike = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al alternar like: $e')));
      }
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
      await widget.service.votarAvistamiento(
        widget.data.id,
        idUsuario: _idUsuario,
      );
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
      await widget.service.validarComoExperto(
        widget.data.id,
        idUsuario: _idUsuario,
        rol: _rolUsuario,
      );
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
                InkWell(
                  onTap: () {
                    if (widget.data.idUsuario != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProfileScreen(
                            userId: widget.data.idUsuario,
                            nombreUsuario: widget.data.nombreUsuario,
                          ),
                        ),
                      );
                    }
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: const Color(0xFF5C6445),
                        radius: 18,
                        child: Text(
                          widget.data.nombreUsuario.isNotEmpty
                              ? widget.data.nombreUsuario[0].toUpperCase()
                              : 'U',
                          style: const TextStyle(
                            color: Color(0xFFE0E0E0),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '@${widget.data.nombreUsuario}',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: primaryTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
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

          // 🔹 Barra de acciones sociales (Like, Comentarios)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Row(
              children: [
                InkWell(
                  onTap: _toggleLike,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _userHasLiked
                          ? Colors.red.withOpacity(0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _userHasLiked
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: _userHasLiked ? Colors.red : primaryTextColor,
                          size: 22,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '$_totalLikes',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: _userHasLiked
                                ? Colors.red
                                : primaryTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                InkWell(
                  onTap: widget.onTap,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          color: primaryTextColor,
                          size: 20,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${widget.data.totalComentarios > 0 ? widget.data.totalComentarios : widget.data.comentarios.length}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: primaryTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
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
                if (widget.data.comentarios.isNotEmpty)
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
