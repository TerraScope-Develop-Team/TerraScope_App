import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/reto_model.dart';
import '../../providers/retos_observer_provider.dart';
import '../../services/session_service.dart';
import '../../services/retos_service.dart';
import '../../services/notification_service.dart';

class RetoDetalleScreen extends StatefulWidget {
  final Reto reto;

  const RetoDetalleScreen({super.key, required this.reto});

  @override
  State<RetoDetalleScreen> createState() => _RetoDetalleScreenState();
}

class _RetoDetalleScreenState extends State<RetoDetalleScreen>
    with WidgetsBindingObserver {
  final SessionService _sessionService = SessionService();
  final RetosService _retosService = RetosService();
  String? _usuarioId;
  bool _isLoading = false;
  Map<String, ProgresoReto>? _progreso;
  Map<String, dynamic>? _tablaPosiciones;

  // Paleta de colores
  static const _oliva = Color(0xFF5C6445);
  static const _olivaClaro = Color(0xFF939E69);
  static const _azulOscuro = Color(0xFF0F1D33);
  static const _azulMedio = Color(0xFF224275);
  static const _grisClaro = Color(0xFFE0E0E0);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _cargarDatos();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _cargarProgreso();
    }
  }

  Future<void> _cargarDatos() async {
    final userData = await _sessionService.getUserData();
    if (mounted) {
      setState(() {
        _usuarioId = userData?['_id'];
      });
    }
    if (_usuarioId != null) {
      await _cargarProgreso();
    }
    await _cargarTablaPosiciones();
  }

  Future<void> _cargarProgreso() async {
    final provider = Provider.of<RetosObserverProvider>(context, listen: false);
    final progreso = await provider.getProgresoReto(widget.reto.id);
    if (mounted) {
      setState(() {
        _progreso = progreso;
      });
    }
  }

  Future<void> _cargarTablaPosiciones() async {
    final tabla = await _retosService.getTablaPosiciones(widget.reto.id);
    if (mounted) {
      setState(() {
        _tablaPosiciones = tabla;
      });
    }
  }

  Future<void> _inscribirse() async {
    setState(() => _isLoading = true);
    final provider = Provider.of<RetosObserverProvider>(context, listen: false);
    final success = await provider.inscribirseReto(widget.reto.id);
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? '¡Inscripción exitosa!' : 'Error al inscribirse',
          ),
          backgroundColor: success ? _olivaClaro : Colors.red,
        ),
      );
      if (success) {
        await _cargarDatos();
        if (!mounted) return;
        await Provider.of<NotificationService>(
          context,
          listen: false,
        ).requestPermissionAfterFirstChallengeAcceptance(context);
      }
    }
  }

  Future<void> _desinscribirse() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange[700]),
            const SizedBox(width: 10),
            const Text('Confirmar'),
          ],
        ),
        content: const Text('¿Deseas desinscribirte de este desafío?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancelar', style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[400],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Desinscribirse',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
    if (!mounted || confirmar != true) return;
    setState(() => _isLoading = true);
    final provider = Provider.of<RetosObserverProvider>(context, listen: false);
    final success = await provider.desinscribirseReto(widget.reto.id);
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Te has desinscrito del desafío'
                : 'Error al desinscribirse',
          ),
          backgroundColor: success ? Colors.orange : Colors.red,
        ),
      );
      if (success) await _cargarDatos();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Detalle del Desafío',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: Consumer<RetosObserverProvider>(
        builder: (context, provider, child) {
          final estaInscrito = provider.estaInscrito(
            widget.reto.id,
            _usuarioId,
          );
          final haCompletado = provider.haCompletado(
            widget.reto.id,
            _usuarioId,
          );

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(haCompletado, estaInscrito),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildInfoSection(),
                      if (estaInscrito && !haCompletado && _progreso != null)
                        _buildProgresoSection(),
                      _buildCondicionesSection(),
                      if (_tablaPosiciones != null)
                        _buildTablaPosicionesSection(),
                    ],
                  ),
                ),
                const SizedBox(height: 80),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildHeader(bool haCompletado, bool estaInscrito) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_oliva, _olivaClaro],
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _azulMedio,
              shape: BoxShape.circle,
              border: Border.all(color: _olivaClaro.withOpacity(0.5), width: 3),
            ),
            child: Icon(
              haCompletado
                  ? Icons.check_circle_rounded
                  : (estaInscrito
                        ? Icons.trending_up_rounded
                        : Icons.emoji_events_rounded),
              size: 50,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            widget.reto.nombreReto,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            widget.reto.descripcionReto,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.85),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          if (haCompletado) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: _olivaClaro,
                borderRadius: BorderRadius.circular(25),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.verified_rounded, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text(
                    '¡Desafío Completado!',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoSection() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _azulOscuro.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _azulMedio.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.info_outline_rounded,
                  color: _azulMedio,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'INFORMACIÓN',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (widget.reto.fechaInicio != null)
            _buildInfoRow(
              Icons.play_circle_outline_rounded,
              'Inicio',
              _formatearFechaCompleta(widget.reto.fechaInicio!),
            ),
          if (widget.reto.fechaFinal != null)
            _buildInfoRow(
              Icons.flag_outlined,
              'Finaliza',
              _formatearFechaCompleta(widget.reto.fechaFinal!),
            ),
          _buildInfoRow(
            Icons.people_outline_rounded,
            'Participantes',
            '${widget.reto.usuariosInscritos.length} inscritos',
          ),
          _buildInfoRow(
            Icons.emoji_events_outlined,
            'Completados',
            '${widget.reto.usuariosFinalizados.length} usuarios',
          ),
          if (widget.reto.esTemporal)
            _buildInfoRow(Icons.schedule_rounded, 'Tipo', 'Desafío Temporal'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Icon(icon, size: 22, color: _oliva),
          const SizedBox(width: 14),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                Text(
                  value,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgresoSection() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _azulOscuro.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _olivaClaro.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.trending_up_rounded, color: _oliva, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'TU PROGRESO',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ..._progreso!.entries.map((entry) {
            final key = entry.key;
            final progreso = entry.value;
            final isComplete = progreso.porcentaje >= 100;

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isComplete
                    ? _olivaClaro.withOpacity(0.1)
                    : _grisClaro.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isComplete
                      ? _olivaClaro.withOpacity(0.3)
                      : Colors.grey[300]!,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          if (isComplete)
                            Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: _olivaClaro,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 12,
                              ),
                            ),
                          Text(
                            key.split('.').last,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${progreso.actual} / ${progreso.requerido}',
                        style: TextStyle(
                          fontSize: 14,
                          color: _oliva,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: progreso.porcentaje / 100,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isComplete ? _olivaClaro : _oliva,
                      ),
                      minHeight: 8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${progreso.porcentaje.toStringAsFixed(0)}% completado',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildCondicionesSection() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _azulOscuro.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _azulMedio.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.checklist_rounded,
                  color: _azulMedio,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'REQUISITOS',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...widget.reto.condiciones.entries.map((entry) {
            final parts = entry.key.split('.');
            final categoria = parts[0];
            final especie = parts[1];
            final cantidad = entry.value;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _grisClaro.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _oliva.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _getIconForCategoria(categoria, especie),
                      color: _oliva,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          especie,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Registra $cantidad avistamientos',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: _oliva,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$cantidad',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
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

  Widget _buildTablaPosicionesSection() {
    final top3 = _tablaPosiciones!['top3'] as List<dynamic>;
    if (top3.isEmpty) return const SizedBox.shrink();

    // Organizar los puestos: 2do, 1ro, 3ro (como en los Juegos Olímpicos)
    final segundo = top3.firstWhere(
      (item) => item['posicion'] == 2,
      orElse: () => null,
    );
    final primero = top3.firstWhere(
      (item) => item['posicion'] == 1,
      orElse: () => null,
    );
    final tercero = top3.firstWhere(
      (item) => item['posicion'] == 3,
      orElse: () => null,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _azulOscuro.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.emoji_events_rounded,
                  color: Colors.amber,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'PODIO - PRIMEROS EN COMPLETAR',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Podium Layout
          SizedBox(
            height: 270,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // 2do lugar (izquierda)
                if (segundo != null) _buildPodiumStep(segundo, 2, 120),
                const SizedBox(width: 8),
                // 1er lugar (centro, más alto)
                if (primero != null) _buildPodiumStep(primero, 1, 160),
                const SizedBox(width: 8),
                // 3er lugar (derecha)
                if (tercero != null) _buildPodiumStep(tercero, 3, 100),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPodiumStep(
    Map<String, dynamic> item,
    int posicion,
    double height,
  ) {
    final usuario = item['usuario'];
    final fecha = DateTime.parse(item['fecha_completado']);
    final imagenPerfil = usuario['imagen_perfil'];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Avatar del usuario
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: _getGradientForPosition(posicion)[0],
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: _getGradientForPosition(posicion)[0].withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipOval(
            child: imagenPerfil != null && imagenPerfil.isNotEmpty
                ? Image.memory(
                    base64Decode(imagenPerfil),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        _buildDefaultAvatar(posicion),
                  )
                : _buildDefaultAvatar(posicion),
          ),
        ),
        const SizedBox(height: 6),
        // Nombre del usuario
        Container(
          constraints: const BoxConstraints(maxWidth: 80),
          child: Text(
            usuario['nombre_usuario'] ?? 'Usuario',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(height: 3),
        // Fecha de completado
        Text(
          _formatearFechaCorta(fecha),
          style: TextStyle(fontSize: 10, color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        // Escalón del podio
        Container(
          width: 80,
          height: height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _getGradientForPosition(posicion),
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            boxShadow: [
              BoxShadow(
                color: _getGradientForPosition(posicion)[0].withOpacity(0.3),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _getIconForPosition(posicion),
                color: Colors.white,
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                '$posicion°',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDefaultAvatar(int posicion) {
    return Container(
      color: _getGradientForPosition(posicion)[0].withOpacity(0.1),
      child: Icon(
        Icons.person,
        color: _getGradientForPosition(posicion)[0],
        size: 30,
      ),
    );
  }

  Widget _buildBottomBar() {
    return Consumer<RetosObserverProvider>(
      builder: (context, provider, child) {
        final estaInscrito = provider.estaInscrito(widget.reto.id, _usuarioId);
        final haCompletado = provider.haCompletado(widget.reto.id, _usuarioId);
        if (haCompletado) return const SizedBox.shrink();

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: _azulOscuro.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            child: SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _isLoading
                    ? null
                    : (estaInscrito ? _desinscribirse : _inscribirse),
                style: ElevatedButton.styleFrom(
                  backgroundColor: estaInscrito ? Colors.red[400] : _oliva,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : Text(
                        estaInscrito ? 'Desinscribirse' : 'Aceptar Desafío',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ),
        );
      },
    );
  }

  IconData _getIconForCategoria(String categoria, String especie) {
    if (categoria == 'fauna') {
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
        default:
          return Icons.category;
      }
    } else {
      return Icons.local_florist;
    }
  }

  List<Color> _getGradientForPosition(int posicion) {
    switch (posicion) {
      case 1:
        return [const Color(0xFFFFD700), const Color(0xFFFFB300)];
      case 2:
        return [const Color(0xFFC0C0C0), const Color(0xFF9E9E9E)];
      case 3:
        return [const Color(0xFFCD7F32), const Color(0xFF8B5A2B)];
      default:
        return [_oliva, _olivaClaro];
    }
  }

  IconData _getIconForPosition(int posicion) {
    switch (posicion) {
      case 1:
        return Icons.looks_one;
      case 2:
        return Icons.looks_two;
      case 3:
        return Icons.looks_3;
      default:
        return Icons.emoji_events;
    }
  }

  String _formatearFechaCompleta(DateTime fecha) {
    final meses = [
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
    return '${fecha.day} ${meses[fecha.month - 1]} ${fecha.year}';
  }

  String _formatearFechaCorta(DateTime fecha) {
    final meses = [
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
    return '${fecha.day} ${meses[fecha.month - 1]}';
  }
}
