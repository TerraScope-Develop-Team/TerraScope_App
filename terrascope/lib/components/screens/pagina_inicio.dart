import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../components/models/avistamiento_model.dart';
import '../../config/api_config.dart';
import '../../providers/retos_observer_provider.dart';
import '../../services/alerta_service.dart';
import '../../services/danger_alert_presenter.dart';
import '../../services/fauna_flora_service.dart';
import '../../services/notification_service.dart';
import '../../services/routing_service.dart';
import '../../services/session_service.dart';
import '../../services/socket_service.dart';
import '../../services/theme_service.dart';
import '../map/avistamiento_detail_loader.dart';
import '../map/map_page.dart';
import '../screens/notification_center_screen.dart';
import '../screens/profile_page.dart';
import '../screens/registro_avistamiento_screen.dart';
import '../ui/slide_to_confirm.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final FaunaFloraService _service;
  final SessionService _sessionService = SessionService();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isMenuOpen = false;

  List<Avistamiento> _avistamientos = [];
  List<Avistamiento> _avistamientosFiltrados = [];
  bool _isLoading = true;
  String? _error;
  int _currentIndex = 0;
  String? _filtroTipo;
  bool _mostrarSoloSeguidos = false;
  final TextEditingController _searchController = TextEditingController();

  // Estado y temporizador para la Social Bar lateral (modo reposo traslúcido / desplegado)
  bool _isSocialBarExpanded = false;
  Timer? _socialBarTimer;

  void _toggleMenu() {
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      Navigator.of(context).pop();
    } else {
      _scaffoldKey.currentState?.openDrawer();
    }
  }

  @override
  void initState() {
    super.initState();
    _service = FaunaFloraService(baseUrl: ApiConfig.baseUrl);
    _cargarAvistamientos();

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
    _socialBarTimer?.cancel();
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
                a.nombreCientifico.toLowerCase().contains(query) ||
                a.especie.toLowerCase().contains(query) ||
                a.nombreUsuario.toLowerCase().contains(query),
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

    // Colores de la paleta oficial de TerraScope
    const primaryGreen = Color(0xFF5C6445);
    const accentGreen = Color(0xFF939E69);
    const deepNavy = Color(0xFF0F1D33);
    final backgroundColor = isDark
        ? themeProvider.darkTheme.scaffoldBackgroundColor
        : const Color(0xFFF6F8F3);

    return Scaffold(
      key: _scaffoldKey,
      onDrawerChanged: (isOpen) {
        if (_isMenuOpen != isOpen) {
          setState(() => _isMenuOpen = isOpen);
        }
      },
      drawer: _buildLeftSideMenu(primaryGreen, isDark, unreadAlertCount),
      backgroundColor: backgroundColor,
      // AppBar moderno y estilizado
      appBar: AppBar(
        backgroundColor: primaryGreen,
        elevation: 0,
        centerTitle: false,
        titleSpacing: 16,
        leadingWidth: 0,
        automaticallyImplyLeading: false, // Evita icono por defecto para usar nuestro icono de la hoja personalizado
        title: Row(
          children: [
            // Icono de la hoja interactivo con animación que despliega el menú lateral izquierdo
            Tooltip(
              message: _isMenuOpen ? 'Cerrar menú' : 'Abrir búsqueda y notificaciones',
              child: InkWell(
                onTap: _toggleMenu,
                borderRadius: BorderRadius.circular(24),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: _isMenuOpen
                        ? Colors.white.withOpacity(0.35)
                        : Colors.white.withOpacity(0.18),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _isMenuOpen ? Colors.white : Colors.white.withOpacity(0.35),
                      width: 1.5,
                    ),
                  ),
                  child: AnimatedRotation(
                    turns: _isMenuOpen ? 0.25 : 0.0,
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOutCubic,
                    child: const Icon(
                      Icons.eco_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            InkWell(
              onTap: _toggleMenu,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'TerraScope',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                  Text(
                    'Monitoreo ambiental vivo',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // Botón Retos / Desafíos
          IconButton(
            tooltip: 'Desafíos de la comunidad',
            icon: const Icon(Icons.emoji_events_outlined, color: Colors.white, size: 24),
            onPressed: () => Navigator.pushNamed(context, '/retos'),
          ),
          // Botón Perfil
          IconButton(
            tooltip: 'Mi perfil',
            icon: const Icon(Icons.account_circle_outlined, color: Colors.white, size: 24),
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
          const SizedBox(width: 6),
        ],
      ),

      floatingActionButton: null,

      body: Stack(
        children: [
          Column(
            children: [
              // Cabecera interactiva con filtro de feed, buscador y chips
              _buildSearchAndFiltersHeader(primaryGreen, isDark),

              // Lista de avistamientos o estados
              Expanded(
                child: _isLoading
                    ? _buildShimmerLoading(isDark)
                    : _error != null
                        ? _buildErrorState(primaryGreen)
                        : _avistamientosFiltrados.isEmpty
                            ? _buildEmptyState(isDark)
                            : RefreshIndicator(
                                onRefresh: _cargarAvistamientos,
                                color: primaryGreen,
                                backgroundColor: Colors.white,
                                child: ListView.builder(
                                  physics: const AlwaysScrollableScrollPhysics(
                                    parent: BouncingScrollPhysics(),
                                  ),
                                  itemCount: _avistamientosFiltrados.length,
                                  padding: const EdgeInsets.only(
                                    top: 8,
                                    bottom: 85,
                                  ),
                                  itemBuilder: (context, index) {
                                    final item = _avistamientosFiltrados[index];
                                    return AvistamientoCard(
                                      key: ValueKey(item.id),
                                      data: item,
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                AvistamientoDetailLoader(
                                              avistamientoId: item.id,
                                              service: _service,
                                            ),
                                          ),
                                        );
                                      },
                                      onDeleted: () {
                                        if (!mounted) return;
                                        setState(() {
                                          _avistamientos.removeWhere(
                                            (a) => a.id == item.id,
                                          );
                                          _avistamientosFiltrados.removeWhere(
                                            (a) => a.id == item.id,
                                          );
                                        });
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

          // Capa transparente para colapsar la Social Bar al tocar fuera en la pantalla
          if (_isSocialBarExpanded)
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () {
                  _socialBarTimer?.cancel();
                  setState(() => _isSocialBarExpanded = false);
                },
              ),
            ),

          // Pestaña lateral flotante estilo Social Bar pegada al borde derecho
          Positioned(
            right: 0,
            bottom: 135,
            child: _buildRightSideSocialBar(primaryGreen, isDark),
          ),
        ],
      ),

      // Barra de navegación inferior estilizada
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF162338) : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: BottomNavigationBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              selectedItemColor: primaryGreen,
              unselectedItemColor: isDark ? Colors.white60 : Colors.grey[500],
              selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 11),
              currentIndex: _currentIndex > 1 ? 1 : _currentIndex,
              onTap: (index) {
                if (index == 0) {
                  setState(() => _currentIndex = 0);
                } else if (index == 1) {
                  _mostrarModalSOS(context);
                } else if (index == 2) {
                  Navigator.pushReplacementNamed(context, '/map');
                }
              },
              items: [
                const BottomNavigationBarItem(
                  icon: Icon(Icons.home_rounded),
                  activeIcon: Icon(Icons.home_rounded, size: 26),
                  label: 'Inicio',
                ),
                BottomNavigationBarItem(
                  icon: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.emergency_rounded, color: Colors.red, size: 20),
                  ),
                  label: 'SOS',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.explore_outlined),
                  activeIcon: Icon(Icons.explore, size: 26),
                  label: 'Mapa',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Cabecera moderna con selector de Feed y chips
  Widget _buildSearchAndFiltersHeader(Color primaryColor, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: primaryColor,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: Column(
        children: [
          // Selector de Feed (Explorar vs Siguiendo) tipo pestaña moderna
          Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.18),
              borderRadius: BorderRadius.circular(16),
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
                    borderRadius: BorderRadius.circular(12),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: !_mostrarSoloSeguidos ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: !_mostrarSoloSeguidos
                            ? [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.public_rounded,
                            size: 16,
                            color: !_mostrarSoloSeguidos ? primaryColor : Colors.white70,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Explorar todo',
                            style: TextStyle(
                              color: !_mostrarSoloSeguidos ? primaryColor : Colors.white70,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
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
                    borderRadius: BorderRadius.circular(12),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: _mostrarSoloSeguidos ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: _mostrarSoloSeguidos
                            ? [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.group_rounded,
                            size: 16,
                            color: _mostrarSoloSeguidos ? primaryColor : Colors.white70,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Siguiendo',
                            style: TextStyle(
                              color: _mostrarSoloSeguidos ? primaryColor : Colors.white70,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Chips de categoría con micro-iconos
          Row(
            children: [
              _buildCategoryPill('Todos', null, Icons.grid_view_rounded),
              const SizedBox(width: 8),
              _buildCategoryPill('Fauna', 'Fauna', Icons.pets_rounded),
              const SizedBox(width: 8),
              _buildCategoryPill('Flora', 'Flora', Icons.local_florist_rounded),
              const Spacer(),
              // Contador de resultados filtrados
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_avistamientosFiltrados.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),

          // Pill indicador de búsqueda activa en caso de que esté filtrado desde el menú
          if (_searchController.text.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search_rounded, size: 14, color: Colors.white),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Búsqueda: "${_searchController.text}"',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      _searchController.clear();
                      _filtrarAvistamientos();
                    },
                    child: const Icon(Icons.close_rounded, size: 16, color: Colors.white),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Menú lateral vertical que se despliega desde la izquierda (Panel con borde recto y elementos interiores redondeados)
  Widget _buildLeftSideMenu(Color primaryGreen, bool isDark, int unreadAlertCount) {
    final bgColor = isDark ? const Color(0xFF162338) : Colors.white;
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF0F1D33);
    final secondaryTextColor = isDark ? Colors.white70 : Colors.grey[600]!;

    return Drawer(
      backgroundColor: bgColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Encabezado del menú
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: primaryGreen.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.eco_rounded, color: primaryGreen, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Menú TerraScope',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: primaryTextColor,
                          ),
                        ),
                        Text(
                          'Búsqueda y notificaciones',
                          style: TextStyle(
                            fontSize: 12,
                            color: secondaryTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Cerrar menú',
                    icon: Icon(Icons.close_rounded, color: secondaryTextColor),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              const Divider(height: 1),
              const SizedBox(height: 18),

              // 2. Tarjeta del Centro de Notificaciones con bordes redondeados
              Text(
                'NOTIFICACIONES Y ALERTAS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: primaryGreen,
                ),
              ),
              const SizedBox(height: 10),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () async {
                    Navigator.of(context).pop();
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const NotificationCenterScreen(),
                      ),
                    );
                    await _refreshUnreadAlertCount();
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: unreadAlertCount > 0
                          ? Colors.red.withOpacity(0.08)
                          : primaryGreen.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: unreadAlertCount > 0
                            ? Colors.red.withOpacity(0.3)
                            : primaryGreen.withOpacity(0.15),
                        width: 1.2,
                      ),
                    ),
                    child: Row(
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: unreadAlertCount > 0
                                    ? Colors.red.withOpacity(0.12)
                                    : primaryGreen.withOpacity(0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.notifications_active_rounded,
                                color: unreadAlertCount > 0 ? Colors.red : primaryGreen,
                                size: 22,
                              ),
                            ),
                            if (unreadAlertCount > 0)
                              Positioned(
                                right: -2,
                                top: -2,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.redAccent,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '$unreadAlertCount',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Centro de Notificaciones',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: primaryTextColor,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                unreadAlertCount > 0
                                    ? '$unreadAlertCount alertas pendientes'
                                    : 'Sin alertas nuevas',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: unreadAlertCount > 0 ? Colors.red.shade700 : secondaryTextColor,
                                  fontWeight: unreadAlertCount > 0 ? FontWeight.w600 : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.arrow_forward_ios_rounded, size: 14, color: secondaryTextColor),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // 3. Buscador en Menú Lateral con bordes redondeados
              Text(
                'BUSCAR AVISTAMIENTOS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: primaryGreen,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F4ED),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: primaryGreen.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) => _filtrarAvistamientos(),
                  style: TextStyle(color: primaryTextColor, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Especie, nombre o explorador...',
                    hintStyle: TextStyle(color: secondaryTextColor, fontSize: 13),
                    prefixIcon: Icon(Icons.search_rounded, color: primaryGreen, size: 22),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18, color: Colors.grey),
                            onPressed: () {
                              _searchController.clear();
                              _filtrarAvistamientos();
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
              ),

              const SizedBox(height: 12),
              // Resultados en tiempo real
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Resultados encontrados:',
                    style: TextStyle(fontSize: 12, color: secondaryTextColor),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: primaryGreen.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${_avistamientosFiltrados.length}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: primaryGreen,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),
              Text(
                'Filtros rápidos de búsqueda:',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: secondaryTextColor),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _buildQuickSearchChip('Mamífero'),
                  _buildQuickSearchChip('Ave'),
                  _buildQuickSearchChip('Reptil'),
                  _buildQuickSearchChip('Anfibio'),
                  _buildQuickSearchChip('Pez'),
                  _buildQuickSearchChip('Insecto'),
                  _buildQuickSearchChip('Planta'),
                  _buildQuickSearchChip('Peligrosa'),
                ],
              ),

              const Spacer(),

              // Botones de acción inferior con esquinas redondeadas
              if (_searchController.text.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        _searchController.clear();
                        _filtrarAvistamientos();
                      },
                      icon: const Icon(Icons.restart_alt_rounded, size: 18),
                      label: const Text('Limpiar búsqueda'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red.shade700,
                        side: BorderSide(color: Colors.red.shade300),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.check_rounded, size: 18),
                  label: const Text('Ver avistamientos'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickSearchChip(String keyword) {
    final isSelected = _searchController.text.toLowerCase() == keyword.toLowerCase();
    return InkWell(
      onTap: () {
        if (isSelected) {
          _searchController.clear();
        } else {
          _searchController.text = keyword;
        }
        _filtrarAvistamientos();
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF5C6445) : const Color(0xFF5C6445).withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          keyword,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF5C6445),
          ),
        ),
      ),
    );
  }

  /// Barra lateral tipo "Social Bar" inspirada en arte conceptual (Modo reposo traslúcido / Modo activo desplegado)
  Widget _buildRightSideSocialBar(Color primaryGreen, bool isDark) {
    return GestureDetector(
      onTap: () async {
        if (!_isSocialBarExpanded) {
          // Desplegar estado activo
          setState(() {
            _isSocialBarExpanded = true;
          });
          // Auto-colapsar después de 4 segundos si no hay interacción
          _socialBarTimer?.cancel();
          _socialBarTimer = Timer(const Duration(seconds: 4), () {
            if (mounted && _isSocialBarExpanded) {
              setState(() {
                _isSocialBarExpanded = false;
              });
            }
          });
        } else {
          // Ya está desplegado: abrir pantalla de registro
          _socialBarTimer?.cancel();
          setState(() {
            _isSocialBarExpanded = false;
          });
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreateAvistamientoScreen(),
            ),
          );
          if (result == true) {
            _cargarAvistamientos();
          }
        }
      },
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity != null) {
          if (details.primaryVelocity! < 0 && !_isSocialBarExpanded) {
            // Deslizar hacia la izquierda: desplegar
            setState(() => _isSocialBarExpanded = true);
            _socialBarTimer?.cancel();
            _socialBarTimer = Timer(const Duration(seconds: 4), () {
              if (mounted && _isSocialBarExpanded) {
                setState(() => _isSocialBarExpanded = false);
              }
            });
          } else if (details.primaryVelocity! > 0 && _isSocialBarExpanded) {
            // Deslizar hacia la derecha: colapsar
            _socialBarTimer?.cancel();
            setState(() => _isSocialBarExpanded = false);
          }
        }
      },
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 250),
        opacity: _isSocialBarExpanded ? 1.0 : 0.45,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          height: 46,
          padding: EdgeInsets.symmetric(
            horizontal: _isSocialBarExpanded ? 14 : 12,
          ),
          decoration: BoxDecoration(
            color: _isSocialBarExpanded ? primaryGreen : primaryGreen.withOpacity(0.85),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(6),
              bottomLeft: Radius.circular(6),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(_isSocialBarExpanded ? 0.35 : 0.15),
                blurRadius: _isSocialBarExpanded ? 10 : 5,
                offset: const Offset(-2, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(
                Icons.camera_alt_rounded,
                color: Colors.white,
                size: 22,
              ),
              if (_isSocialBarExpanded) ...[
                const SizedBox(width: 10),
                const Text(
                  'REGISTRAR',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                    letterSpacing: 1.4,
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white70,
                  size: 13,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryPill(String label, String? value, IconData icon) {
    final isSelected = _filtroTipo == value;
    return InkWell(
      onTap: () => _applyFilter(isSelected ? null : value),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.white : Colors.white.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected ? const Color(0xFF5C6445) : Colors.white,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? const Color(0xFF5C6445) : Colors.white,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerLoading(bool isDark) {
    return ListView.builder(
      itemCount: 3,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 130,
                        height: 14,
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        width: 80,
                        height: 11,
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                height: 220,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              const SizedBox(height: 14),
              Container(
                width: 180,
                height: 18,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF5C6445).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _mostrarSoloSeguidos ? Icons.people_outline_rounded : Icons.nature_people_rounded,
                size: 64,
                color: const Color(0xFF5C6445),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _mostrarSoloSeguidos ? 'Tu feed de seguidos está vacío' : 'No se encontraron avistamientos',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF0F1D33),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _mostrarSoloSeguidos
                  ? 'Sigue a otros naturalistas y exploradores para ver sus descubrimientos en este espacio.'
                  : 'Sé el primero en documentar la biodiversidad local registrando un nuevo avistamiento.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                if (_mostrarSoloSeguidos) {
                  setState(() => _mostrarSoloSeguidos = false);
                  _cargarAvistamientos();
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CreateAvistamientoScreen(),
                    ),
                  ).then((value) {
                    if (value == true) _cargarAvistamientos();
                  });
                }
              },
              icon: Icon(
                _mostrarSoloSeguidos ? Icons.public_rounded : Icons.add_photo_alternate_rounded,
                size: 18,
              ),
              label: Text(_mostrarSoloSeguidos ? 'Ver explorar todo' : 'Registrar especie'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5C6445),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(Color primaryColor) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.wifi_off_rounded, size: 48, color: Colors.red),
            ),
            const SizedBox(height: 16),
            const Text(
              'No pudimos conectar con TerraScope',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Verifica tu conexión y reintenta.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _cargarAvistamientos,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reintentar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarModalSOS(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SafeArea(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.red,
                    size: 34,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Emergencia SOS',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Al confirmar se enviará tu ubicación satelital en tiempo real a las brigadas de emergencia y se iniciará una llamada al 911.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey[800],
                    height: 1.35,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 18),
                SlideToConfirm(
                  baseColor: Colors.red.shade700,
                  onConfirm: () async {
                    Navigator.pop(ctx);
                    double lat = 0.0;
                    double lng = 0.0;
                    try {
                      Position position = await Geolocator.getCurrentPosition(
                        desiredAccuracy: LocationAccuracy.high,
                        timeLimit: const Duration(seconds: 10),
                      );
                      lat = position.latitude;
                      lng = position.longitude;
                      final alertaService = AlertaService();
                      await alertaService.sendSOS(lat, lng);
                    } catch (e) {
                      debugPrint('Error enviando SOS: $e');
                    }
                    final Uri url = Uri(scheme: 'tel', path: '911');
                    if (await canLaunchUrl(url)) await launchUrl(url);
                  },
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(
                    'Cancelar',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Tarjeta moderna tipo red social para los avistamientos
class AvistamientoCard extends StatefulWidget {
  final Avistamiento data;
  final VoidCallback onTap;
  final VoidCallback? onDeleted;
  final FaunaFloraService service;
  final SessionService sessionService;

  const AvistamientoCard({
    super.key,
    required this.data,
    required this.onTap,
    this.onDeleted,
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
  String? _tipoVotoUsuario;

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

  Future<void> _cargarUsuarioYValidacion() async {
    await _cargarUsuario();
    await _cargarEstadoValidacion();
  }

  Future<void> _cargarUsuario() async {
    final userData = await widget.sessionService.getUserData();
    if (mounted && userData != null) {
      setState(() {
        _idUsuario = userData['_id'] ?? userData['id'] ?? '';
        _rolUsuario = userData['rol_usuario'] ?? userData['rol'] ?? 'Usuario';
        if (_idUsuario.isNotEmpty && widget.data.likes.isNotEmpty) {
          _userHasLiked = widget.data.likes.contains(_idUsuario);
        }
      });
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

  Future<void> _cargarEstadoValidacion() async {
    if (widget.data.id.isEmpty) return;

    setState(() => _isLoadingValidacion = true);
    try {
      final estado = await widget.service.getEstadoValidacion(widget.data.id);

      if (estado?['eliminado'] == true || estado?['estado'] == 'eliminado') {
        if (mounted) {
          final motivo = estado?['motivo']?.toString();
          final textoMotivo = motivo == 'sin_votos'
              ? 'Avistamiento eliminado automáticamente por no recibir votos en el periodo.'
              : 'Avistamiento eliminado automáticamente por mayoría de votos negativos.';
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(textoMotivo)));
          widget.onDeleted?.call();
        }
        return;
      }

      if (mounted) {
        setState(() {
          _estadoValidacion = estado;
          _yaVoto = estado?['yaVoto'] ?? false;
          _tipoVotoUsuario = estado?['tipo_voto_usuario']?.toString();
        });
      }
    } catch (e) {
      debugPrint('Error al cargar validación: $e');
    } finally {
      if (mounted) setState(() => _isLoadingValidacion = false);
    }
  }

  Future<void> _votar(String tipoVoto) async {
    if (_idUsuario.isEmpty) return;

    setState(() => _isLoadingValidacion = true);
    try {
      final res = await widget.service.votarAvistamiento(
        widget.data.id,
        idUsuario: _idUsuario,
        tipoVoto: tipoVoto,
      );

      if (res['eliminado'] == true) {
        if (mounted) {
          final msg =
              res['message']?.toString() ??
              'El avistamiento fue eliminado automáticamente por mayoría de votos negativos.';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(msg), backgroundColor: Colors.red.shade700),
          );
          widget.onDeleted?.call();
        }
        return;
      }
    } catch (e) {
      if (!e.toString().contains('400')) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('No se pudo votar: $e')));
        }
      }
    } finally {
      if (mounted) {
        await _cargarEstadoValidacion();
      }
    }
  }

  Future<void> _validarComoExperto() async {
    if (_idUsuario.isEmpty) return;
    setState(() => _isLoadingValidacion = true);
    try {
      await widget.service.validarComoExperto(
        widget.data.id,
        idUsuario: _idUsuario,
        rol: _rolUsuario,
      );
      await _cargarEstadoValidacion();
    } catch (e) {
      debugPrint('Error al validar como experto: $e');
    } finally {
      if (mounted) setState(() => _isLoadingValidacion = false);
    }
  }

  String _formatearTiempoRestante(String? fechaFinIso) {
    if (fechaFinIso == null || fechaFinIso.isEmpty) {
      return 'Periodo activo';
    }
    final fechaFin = DateTime.tryParse(fechaFinIso)?.toLocal();
    if (fechaFin == null) return 'Periodo activo';

    final diff = fechaFin.difference(DateTime.now());
    if (diff.isNegative || diff.inSeconds <= 0) {
      return 'Periodo finalizado';
    }
    if (diff.inHours >= 1) {
      final mins = diff.inMinutes % 60;
      return '${diff.inHours}h ${mins}m restantes';
    }
    if (diff.inMinutes >= 1) {
      return '${diff.inMinutes}m restantes';
    }
    return '${diff.inSeconds}s restantes';
  }

  Color _getExtincionColor(String estado) {
    final estadoLower = estado.toLowerCase();
    if (estadoLower.contains('peligro') || estadoLower.contains('crítico')) {
      return const Color(0xFFD32F2F);
    } else if (estadoLower.contains('vulnerable') ||
        estadoLower.contains('amenazado')) {
      return const Color(0xFFF57C00);
    } else if (estadoLower.contains('preocupación') ||
        estadoLower.contains('menor')) {
      return const Color(0xFF388E3C);
    }
    return const Color(0xFF5C6445);
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.grey[200],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.landscape_rounded, size: 56, color: Colors.grey[400]),
            const SizedBox(height: 8),
            Text(
              'Sin imagen disponible',
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
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

    const primaryGreen = Color(0xFF5C6445);
    const deepNavy = Color(0xFF0F1D33);
    final cardBgColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final primaryTextColor = isDark ? Colors.white : deepNavy;
    final secondaryTextColor = isDark ? Colors.white70 : Colors.grey[600]!;

    final votosPositivos =
        (_estadoValidacion?['votos_positivos'] ??
                _estadoValidacion?['votos_comunidad'] ??
                widget.data.validacion.votosPositivos)
            as int;
    final votosNegativos =
        (_estadoValidacion?['votos_negativos'] ??
                widget.data.validacion.votosNegativos)
            as int;
    final totalVotos = votosPositivos + votosNegativos;
    final requeridos =
        (_estadoValidacion?['requeridos_comunidad'] ??
                widget.data.validacion.requeridosComunidad)
            as int;
    final validadoExperto =
        (_estadoValidacion?['validado_por_experto'] ??
            widget.data.validacion.validadoPorExperto) ==
        true;
    final estadoActual =
        (_estadoValidacion?['estado'] ?? widget.data.validacion.estado)
            .toString();
    final validadoComunidad = estadoActual == 'validado_comunidad';
    final validado = validadoExperto || validadoComunidad;
    final yaVoto = (_estadoValidacion?['yaVoto'] ?? _yaVoto) == true;
    final tipoVotoUsuario =
        (_estadoValidacion?['tipo_voto_usuario'] ?? _tipoVotoUsuario)
            ?.toString();
    final esAutor =
        _idUsuario.isNotEmpty && widget.data.idUsuario == _idUsuario;
    final textoTiempo = _formatearTiempoRestante(
      _estadoValidacion?['fecha_fin_votacion']?.toString() ??
          widget.data.validacion.fechaFinVotacion?.toIso8601String(),
    );

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header con avatar del usuario y metadatos
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
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
                    borderRadius: BorderRadius.circular(24),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: primaryGreen, width: 1.5),
                          ),
                          child: CircleAvatar(
                            backgroundColor: primaryGreen.withOpacity(0.15),
                            radius: 17,
                            child: Text(
                              widget.data.nombreUsuario.isNotEmpty
                                  ? widget.data.nombreUsuario[0].toUpperCase()
                                  : 'U',
                              style: const TextStyle(
                                color: primaryGreen,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '@${widget.data.nombreUsuario}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: primaryTextColor,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                              Row(
                                children: [
                                  Icon(Icons.location_on_rounded, size: 12, color: Colors.grey[500]),
                                  const SizedBox(width: 2),
                                  Expanded(
                                    child: Text(
                                      '${widget.data.ubicacion.latitud.toStringAsFixed(3)}, ${widget.data.ubicacion.longitud.toStringAsFixed(3)}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey[500],
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Badge de tipo (Fauna / Flora)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: primaryGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        widget.data.tipo.toLowerCase() == 'fauna'
                            ? Icons.pets_rounded
                            : Icons.local_florist_rounded,
                        size: 13,
                        color: primaryGreen,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        widget.data.tipo,
                        style: const TextStyle(
                          color: primaryGreen,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 2. Imagen del avistamiento con tags flotantes modernos
          GestureDetector(
            onTap: widget.onTap,
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(0),
                  child: Container(
                    width: double.infinity,
                    height: 260,
                    color: Colors.grey[200],
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

                // Gradiente inferior sutil para legibilidad
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.1),
                          Colors.transparent,
                          Colors.black.withOpacity(0.4),
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                    ),
                  ),
                ),

                // Badge si es especie peligrosa
                if (widget.data.esPeligrosa)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.red.shade700,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.warning_amber_rounded, color: Colors.white, size: 14),
                          SizedBox(width: 4),
                          Text(
                            'Peligrosa',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Estado de validación flotante abajo a la izquierda
                Positioned(
                  bottom: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: validado ? Colors.green.shade700 : deepNavy.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.25),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          validado ? Icons.verified_rounded : Icons.how_to_vote_rounded,
                          color: Colors.white,
                          size: 14,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          validado
                              ? (validadoExperto ? 'Validado por Experto' : 'Validado Comunidad')
                              : 'En Votación Comunitaria',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
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

          // 3. Barra de interacciones sociales (Likes, Comentarios y Ver Detalle)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                // Botón de Like interactivo
                InkWell(
                  onTap: _toggleLike,
                  borderRadius: BorderRadius.circular(20),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _userHasLiked ? Colors.red.withOpacity(0.1) : Colors.grey.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _userHasLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          color: _userHasLiked ? Colors.red : secondaryTextColor,
                          size: 20,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '$_totalLikes',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: _userHasLiked ? Colors.red : primaryTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Botón de Comentarios
                InkWell(
                  onTap: widget.onTap,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.chat_bubble_outline_rounded,
                          color: secondaryTextColor,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${widget.data.totalComentarios > 0 ? widget.data.totalComentarios : widget.data.comentarios.length}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: primaryTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(),

                // Botón elegante "Ver a detalle"
                TextButton.icon(
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
                  icon: const Text(
                    'Detalles',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  label: const Icon(Icons.arrow_forward_rounded, size: 16),
                  style: TextButton.styleFrom(
                    foregroundColor: primaryGreen,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ],
            ),
          ),

          // 4. Datos del espécimen y tags taxonómicos
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.data.nombreComun,
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: primaryTextColor,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.data.nombreCientifico,
                  style: TextStyle(
                    fontSize: 14,
                    color: secondaryTextColor,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 10),

                // Tags de información rápida en pills
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _buildPillBadge(
                      label: widget.data.especie,
                      icon: Icons.category_rounded,
                      color: primaryGreen,
                    ),
                    _buildPillBadge(
                      label: widget.data.estadoExtincion,
                      icon: Icons.shield_outlined,
                      color: _getExtincionColor(widget.data.estadoExtincion),
                    ),
                    if (widget.data.estadoEspecimen.isNotEmpty)
                      _buildPillBadge(
                        label: widget.data.estadoEspecimen,
                        icon: Icons.health_and_safety_outlined,
                        color: Colors.blueGrey,
                      ),
                  ],
                ),
              ],
            ),
          ),

          // 5. Módulo de votación y validación comunitaria
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: _isLoadingValidacion
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(12.0),
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(primaryGreen),
                        strokeWidth: 2.5,
                      ),
                    ),
                  )
                : Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: validado
                          ? Colors.green.withOpacity(0.06)
                          : primaryGreen.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: validado
                            ? Colors.green.withOpacity(0.3)
                            : primaryGreen.withOpacity(0.15),
                        width: 1,
                      ),
                    ),
                    child: validado
                        ? Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.verified_rounded,
                                  color: Colors.green,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      validadoExperto
                                          ? 'Validado oficialmente por experto'
                                          : 'Validado por mayoría comunitaria',
                                      style: const TextStyle(
                                        color: Colors.green,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '$votosPositivos a favor · $votosNegativos en contra',
                                      style: TextStyle(
                                        color: Colors.green.shade800,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Cabecera de votación
                              Row(
                                children: [
                                  const Icon(
                                    Icons.how_to_vote_rounded,
                                    size: 15,
                                    color: primaryGreen,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      'Validación comunitaria',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: primaryTextColor,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 7,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: primaryGreen.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.schedule_rounded,
                                          size: 11,
                                          color: primaryGreen,
                                        ),
                                        const SizedBox(width: 3),
                                        Text(
                                          textoTiempo,
                                          style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color: primaryGreen,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),

                              // Barra de balance de votos
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: LinearProgressIndicator(
                                  value: totalVotos > 0 ? votosPositivos / totalVotos : 0.5,
                                  backgroundColor: totalVotos > 0
                                      ? Colors.red.shade300
                                      : Colors.grey.shade300,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    totalVotos > 0 ? primaryGreen : Colors.grey.shade400,
                                  ),
                                  minHeight: 6,
                                ),
                              ),
                              const SizedBox(height: 6),

                              // Textos de votos
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '$votosPositivos a favor',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: primaryGreen,
                                    ),
                                  ),
                                  Text(
                                    '$votosNegativos en contra',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.red.shade700,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // Botones de acción
                              if (esAutor)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                    horizontal: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    'Tu avistamiento está en periodo de validación',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: secondaryTextColor,
                                    ),
                                  ),
                                )
                              else if (!yaVoto)
                                Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: _idUsuario.isEmpty
                                            ? null
                                            : () => _votar('positivo'),
                                        icon: const Icon(
                                          Icons.thumb_up_alt_rounded,
                                          size: 15,
                                        ),
                                        label: const Text('A favor'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: primaryGreen,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(vertical: 9),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          elevation: 0,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: _idUsuario.isEmpty
                                            ? null
                                            : () => _votar('negativo'),
                                        icon: Icon(
                                          Icons.thumb_down_alt_rounded,
                                          size: 15,
                                          color: Colors.red.shade700,
                                        ),
                                        label: Text(
                                          'En contra',
                                          style: TextStyle(color: Colors.red.shade700),
                                        ),
                                        style: OutlinedButton.styleFrom(
                                          side: BorderSide(
                                            color: Colors.red.shade400,
                                            width: 1.2,
                                          ),
                                          padding: const EdgeInsets.symmetric(vertical: 9),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              else
                                Container(
                                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                  decoration: BoxDecoration(
                                    color: tipoVotoUsuario == 'negativo'
                                        ? Colors.red.withOpacity(0.08)
                                        : primaryGreen.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.max,
                                    children: [
                                      Icon(
                                        tipoVotoUsuario == 'negativo'
                                            ? Icons.thumb_down_rounded
                                            : Icons.check_circle_rounded,
                                        color: tipoVotoUsuario == 'negativo'
                                            ? Colors.red.shade700
                                            : primaryGreen,
                                        size: 15,
                                      ),
                                      const SizedBox(width: 6),
                                      Flexible(
                                        child: Text(
                                          tipoVotoUsuario == 'negativo'
                                              ? 'Votaste en contra'
                                              : 'Votaste a favor',
                                          style: TextStyle(
                                            color: tipoVotoUsuario == 'negativo'
                                                ? Colors.red.shade700
                                                : primaryGreen,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                              // Botón de validación de experto
                              if (_rolUsuario.toLowerCase() != 'usuario') ...[
                                const SizedBox(height: 8),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: _validarComoExperto,
                                    icon: const Icon(Icons.verified_rounded, size: 15),
                                    label: const Text(
                                      'Validar como experto',
                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: deepNavy,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      elevation: 0,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPillBadge({
    required String label,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.09),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
