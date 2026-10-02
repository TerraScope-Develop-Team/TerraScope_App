import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:terrascope/components/models/reto_model.dart';
import 'package:terrascope/services/auth_service.dart';
import 'package:terrascope/services/retos_service.dart';
import 'package:terrascope/services/session_service.dart';
import 'package:terrascope/services/theme_service.dart';
import 'package:terrascope/services/alerta_service.dart';
import 'package:terrascope/components/screens/edit_page.dart';

class ProfileScreen extends StatefulWidget {
  final String? userId;
  final String? nombreUsuario;

  const ProfileScreen({super.key, this.userId, this.nombreUsuario});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final SessionService _sessionService = SessionService();
  final AuthService _authService = AuthService();
  final RetosService _retosService = RetosService();

  Map<String, dynamic>? _userData;
  List<Reto> _retosActivos = [];
  bool _isLoading = true;
  bool _isLoadingRetos = false;
  String? _error;

  bool _isOwnProfile = true;
  bool _isFollowing = false;
  bool _isTogglingFollow = false;
  int _totalSeguidores = 0;
  int _totalSeguidos = 0;
  String? _targetUserId;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _navigateToEdit() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfileScreen(userData: _userData!),
      ),
    );

    if (result == true) {
      _loadUserProfile();
    }
  }

  Future<void> _loadUserProfile() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final sessionData = await _sessionService.getUserData();
      final currentSessionUserId = sessionData?['_id'] ?? sessionData?['id'];
      _targetUserId = widget.userId ?? currentSessionUserId;
      _isOwnProfile = widget.userId == null || widget.userId == currentSessionUserId;

      if (_targetUserId == null) {
        setState(() {
          _error = 'No se encontró la sesión del usuario';
          _isLoading = false;
        });
        return;
      }

      final userData = await _authService.obtenerUsuarioPorId(_targetUserId!);

      if (userData != null) {
        final seguidoresCount = userData['total_seguidores'] is num
            ? (userData['total_seguidores'] as num).toInt()
            : ((userData['seguidores'] as List?)?.length ?? 0);
        final seguidosCount = userData['total_seguidos'] is num
            ? (userData['total_seguidos'] as num).toInt()
            : ((userData['seguidos'] as List?)?.length ?? 0);

        setState(() {
          _userData = userData;
          _totalSeguidores = seguidoresCount;
          _totalSeguidos = seguidosCount;
          _isFollowing = userData['is_following'] == true;
          _isLoading = false;
        });

        // Cargar detalles de los retos activos
        _loadRetosActivos();
      } else {
        setState(() {
          _error = 'No se pudieron cargar los datos del usuario';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'No especificada';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  Future<void> _loadRetosActivos() async {
    final retosIds = _userData?['retos_activos'] as List<dynamic>? ?? [];
    if (retosIds.isEmpty) return;

    setState(() => _isLoadingRetos = true);

    try {
      List<Reto> retosData = [];

      for (var retoId in retosIds) {
        final reto = await _retosService.getRetoById(retoId.toString());
        if (reto != null) {
          retosData.add(reto);
        }
      }

      setState(() {
        _retosActivos = retosData;
        _isLoadingRetos = false;
      });
    } catch (e) {
      print('Error al cargar retos: $e');
      setState(() => _isLoadingRetos = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isOwnProfile
              ? 'Mi Perfil'
              : '@${_userData?['nombre_usuario'] ?? widget.nombreUsuario ?? 'Perfil'}',
        ),
        centerTitle: true,
        actions: [
          if (_isOwnProfile)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: _userData != null ? _navigateToEdit : null,
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUserProfile,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadUserProfile,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (_userData == null) {
      return const Center(child: Text('No hay datos disponibles'));
    }

    return RefreshIndicator(
      onRefresh: _loadUserProfile,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileHeader(),
            const SizedBox(height: 24),
            _buildInfoSection(),
            if (_isOwnProfile) ...[
              const SizedBox(height: 24),
              _buildThemeSection(),
            ],
            const SizedBox(height: 24),
            _buildHistorialSection(),
            const SizedBox(height: 24),
            _buildLogrosSection(),
            const SizedBox(height: 24),
            _buildRetosActivosSection(),
            if (_isOwnProfile) ...[
              const SizedBox(height: 32),
              _buildLogoutButton(),
            ],
          ],
        ),
      ),
    );
  }

  ImageProvider? _getImageProvider(String? imagenPerfil) {
    if (imagenPerfil == null || imagenPerfil.isEmpty) return null;

    // Si es base64
    if (imagenPerfil.startsWith('data:image')) {
      final base64String = imagenPerfil.split(',').last;
      return MemoryImage(base64Decode(base64String));
    }

    // Si es URL
    return NetworkImage(imagenPerfil);
  }

  Widget _buildProfileHeader() {
    final imagenPerfil = _userData?['imagen_perfil'];
    final nombre = _userData?['nombre_usuario'] ?? 'Usuario';
    final rol = _userData?['rol'] ?? 'Usuario';
    final tituloActivo = _userData?['titulo_activo'];
    final imageProvider = _getImageProvider(imagenPerfil);

    return Center(
      child: Column(
        children: [
          CircleAvatar(
            radius: 60,
            backgroundColor: Colors.green[100],
            backgroundImage: imageProvider,
            child: imageProvider == null
                ? Icon(Icons.person, size: 60, color: Colors.green[700])
                : null,
          ),
          const SizedBox(height: 16),
          Text(
            nombre,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: _getRolColor(rol),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              rol,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
          // 👇 NUEVO: Mostrar título activo
          if (tituloActivo != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.purple[400]!, Colors.purple[600]!],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.purple.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.military_tech,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    tituloActivo['descripcion_titulo'] ??
                        tituloActivo['nombre_logro'] ??
                        'Título',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 18),

          // 🔹 Métricas sociales: Seguidores y Seguidos
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              InkWell(
                onTap: () => _mostrarListaUsuarios(
                  'Seguidores',
                  _authService.obtenerSeguidores(_targetUserId!),
                ),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Column(
                    children: [
                      Text(
                        '$_totalSeguidores',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Seguidores',
                        style: TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
              Container(height: 36, width: 1, color: Colors.grey[300]),
              InkWell(
                onTap: () => _mostrarListaUsuarios(
                  'Siguiendo',
                  _authService.obtenerSeguidos(_targetUserId!),
                ),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Column(
                    children: [
                      Text(
                        '$_totalSeguidos',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Siguiendo',
                        style: TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // 🔹 Botón Seguir / Dejar de seguir si es perfil ajeno
          if (!_isOwnProfile) ...[
            const SizedBox(height: 14),
            ElevatedButton.icon(
              onPressed: _isTogglingFollow ? null : _toggleSeguir,
              icon: Icon(
                _isFollowing ? Icons.person_remove : Icons.person_add,
                size: 18,
              ),
              label: Text(_isFollowing ? 'Dejar de seguir' : 'Seguir'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _isFollowing
                    ? Colors.grey[300]
                    : const Color(0xFF5C6445),
                foregroundColor: _isFollowing ? Colors.black87 : Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _toggleSeguir() async {
    if (_isTogglingFollow || _targetUserId == null) return;
    setState(() => _isTogglingFollow = true);
    try {
      if (_isFollowing) {
        final res = await _authService.dejarDeSeguirUsuario(_targetUserId!);
        if (res != null) {
          setState(() {
            _isFollowing = false;
            _totalSeguidores = (_totalSeguidores - 1).clamp(0, 999999);
          });
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No se pudo dejar de seguir al usuario')),
          );
        }
      } else {
        final res = await _authService.seguirUsuario(_targetUserId!);
        if (res != null) {
          setState(() {
            _isFollowing = true;
            _totalSeguidores += 1;
          });
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No se pudo seguir al usuario')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al procesar seguimiento: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isTogglingFollow = false);
    }
  }

  void _mostrarListaUsuarios(String titulo, Future<List<dynamic>> futureUsuarios) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.6,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                titulo,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Divider(),
              Expanded(
                child: FutureBuilder<List<dynamic>>(
                  future: futureUsuarios,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }
                    final usuarios = snapshot.data ?? [];
                    if (usuarios.isEmpty) {
                      return Center(
                        child: Text(
                          'No hay $titulo todavía',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      );
                    }
                    return ListView.builder(
                      itemCount: usuarios.length,
                      itemBuilder: (context, index) {
                        final u = usuarios[index] is Map<String, dynamic>
                            ? usuarios[index]
                            : {};
                        final uId = u['_id'] ?? u['id'] ?? '';
                        final uNombre = u['nombre_usuario'] ?? 'Usuario';
                        final uRol = u['rol'] ?? 'Usuario';
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: const Color(0xFF5C6445),
                            child: Text(
                              uNombre.isNotEmpty
                                  ? uNombre[0].toUpperCase()
                                  : 'U',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          title: Text(uNombre, style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text(uRol, style: const TextStyle(fontSize: 12)),
                          trailing: const Icon(Icons.chevron_right, size: 20),
                          onTap: () {
                            Navigator.pop(context);
                            if (uId.isNotEmpty && uId != _targetUserId) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ProfileScreen(
                                    userId: uId,
                                    nombreUsuario: uNombre,
                                  ),
                                ),
                              );
                            }
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _getRolColor(String rol) {
    switch (rol) {
      case 'Administrador':
        return Colors.red;
      case 'Investigador':
        return Colors.blue;
      default:
        return Colors.green;
    }
  }

  Widget _buildInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Información Personal',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            _buildInfoRow(
              Icons.email,
              'Email',
              _userData?['email_usuario'] ?? 'No especificado',
            ),
            _buildInfoRow(
              Icons.phone,
              'Teléfono',
              _userData?['telefono_usuario'] ?? 'No especificado',
            ),
            _buildInfoRow(
              Icons.cake,
              'Fecha de nacimiento',
              _formatDate(_userData?['fecha_nac_usuario']),
            ),
            _buildInfoRow(
              Icons.calendar_today,
              'Miembro desde',
              _formatDate(_userData?['createdAt']),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.green[700]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                Text(value, style: const TextStyle(fontSize: 16)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeSection() {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Configuración',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Divider(),
                SwitchListTile(
                  title: const Text('Modo Nocturno'),
                  subtitle: const Text('Cambiar entre tema claro y oscuro'),
                  value: themeProvider.isDarkMode,
                  onChanged: (value) {
                    themeProvider.toggleTheme(value);
                  },
                  secondary: Icon(
                    themeProvider.isDarkMode
                        ? Icons.dark_mode
                        : Icons.light_mode,
                    color: themeProvider.isDarkMode
                        ? Colors.blue
                        : Colors.orange,
                  ),
                ),
                const Divider(),
                SwitchListTile(
                  title: const Text('Alertas de fauna peligrosa'),
                  subtitle: const Text('Recibir notificaciones cuando haya especies peligrosas cerca'),
                  value: _userData?['recibir_alertas_peligro'] ?? true,
                  onChanged: (value) async {
                    setState(() {
                      _userData?['recibir_alertas_peligro'] = value;
                    });
                    final alertaService = AlertaService();
                    final success = await alertaService.updateAlertSettings(value);
                    if (!success) {
                      setState(() {
                        _userData?['recibir_alertas_peligro'] = !value;
                      });
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Error al actualizar configuración')),
                        );
                      }
                    }
                  },
                  secondary: Icon(
                    Icons.warning_amber_rounded,
                    color: (_userData?['recibir_alertas_peligro'] ?? true)
                        ? Colors.red
                        : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHistorialSection() {
    final historial = _userData?['historial'];
    if (historial == null) return const SizedBox.shrink();

    final fauna = historial['fauna'] as Map<String, dynamic>? ?? {};
    final flora = historial['flora'] as Map<String, dynamic>? ?? {};

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Historial de Registros',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.pets, color: Colors.orange[700]),
                const SizedBox(width: 8),
                const Text(
                  'Fauna',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: fauna.entries
                  .map((e) => _buildStatChip(e.key, e.value, Colors.orange))
                  .toList(),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.local_florist, color: Colors.green[700]),
                const SizedBox(width: 8),
                const Text(
                  'Flora',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: flora.entries
                  .map((e) => _buildStatChip(e.key, e.value, Colors.green))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip(String label, dynamic value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(color: color.withValues(alpha: 0.8), fontSize: 12),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$value',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogrosSection() {
    final logros = _userData?['logros'] as List<dynamic>? ?? [];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Logros',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.amber[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${logros.length}',
                    style: TextStyle(
                      color: Colors.amber[800],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(),
            if (logros.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: Text(
                    'Aún no tienes logros',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              ...logros.map((logro) => _buildLogroItem(logro)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildLogroItem(Map<String, dynamic> logro) {
    final esMostrado = logro['es_mostrado'] ?? true;
    final tituloActivo = _userData?['titulo_activo'];
    final esActivo =
        tituloActivo != null && tituloActivo['id_logro'] == logro['_id'];

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      elevation: esActivo ? 3 : 1,
      color: esActivo ? Colors.purple[50] : null,
      child: ListTile(
        leading: Icon(
          Icons.emoji_events,
          color: esActivo
              ? Colors.purple
              : (esMostrado ? Colors.amber : Colors.grey),
          size: 32,
        ),
        title: Text(
          logro['nombre_logro'] ?? 'Logro',
          style: TextStyle(
            fontWeight: esActivo ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (logro['descripcion_titulo'] != null)
              Text(
                logro['descripcion_titulo'],
                style: TextStyle(color: esActivo ? Colors.purple[700] : null),
              ),
            Text(
              'Obtenido: ${_formatDate(logro['fecha_obtencion'])}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (esMostrado)
              const Icon(Icons.visibility, color: Colors.green, size: 20)
            else
              const Icon(Icons.visibility_off, color: Colors.grey, size: 20),
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(
                esActivo ? Icons.star : Icons.star_border,
                color: esActivo ? Colors.purple : Colors.grey,
              ),
              onPressed: () => _handleTituloSelection(logro, esActivo),
              tooltip: esActivo ? 'Quitar título' : 'Usar como título',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRetosActivosSection() {
    final retos = _userData?['retos_activos'] as List<dynamic>? ?? [];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Retos Activos',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_retosActivos.length}',
                    style: TextStyle(
                      color: Colors.blue[800],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(),
            if (retos.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: Text(
                    'No tienes retos activos',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else if (_isLoadingRetos)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_retosActivos.isEmpty && retos.isNotEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: Text(
                    'No se pudieron cargar los detalles de los retos',
                    style: TextStyle(color: Colors.orange),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else
              ..._retosActivos
                  .map(
                    (reto) => ListTile(
                      leading: const Icon(Icons.flag, color: Colors.blue),
                      title: Text(reto.nombreReto),
                      subtitle: Text(
                        reto.descripcionReto,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _handleLogout,
        icon: const Icon(Icons.logout),
        label: const Text('Cerrar Sesión'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Future<void> _handleTituloSelection(
    Map<String, dynamic> logro,
    bool esActivo,
  ) async {
    final userId = _userData?['_id'];
    if (userId == null) return;

    try {
      bool success;

      if (esActivo) {
        // Quitar título activo
        final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Quitar Título'),
            content: const Text('¿Deseas quitar este título de tu perfil?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Quitar'),
              ),
            ],
          ),
        );

        if (confirm != true) return;

        success = await _authService.quitarTituloActivo(userId);

        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Título removido'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } else {
        // Establecer nuevo título
        success = await _authService.seleccionarTituloActivo(
          userId,
          logro['_id'],
        );

        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Título "${logro['descripcion_titulo'] ?? logro['nombre_logro']}" activado',
              ),
              backgroundColor: Colors.purple,
            ),
          );
        }
      }

      if (success) {
        _loadUserProfile(); // Recargar perfil
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error al actualizar título'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('Error al manejar título: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al actualizar título'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Estás seguro de que quieres cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Cerrar Sesión'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _sessionService.logout();
      if (mounted) {
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/login', (route) => false);
      }
    }
  }
}
