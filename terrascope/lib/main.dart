import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:terrascope/components/map/avistamiento_detail_page.dart';
import 'package:terrascope/components/screens/reto_detalle_screen.dart';
import 'package:terrascope/components/screens/login_page.dart';
import 'package:terrascope/components/screens/pagina_inicio.dart';
import 'package:terrascope/components/screens/profile_page.dart';
import 'package:terrascope/components/screens/register_page.dart';
import 'package:terrascope/components/screens/retos_activos_screen.dart';
import 'package:terrascope/components/screens/logros_screen.dart';
import 'package:terrascope/providers/retos_observer_provider.dart';
import 'package:terrascope/services/avistamiento_service.dart';
import 'package:terrascope/services/retos_service.dart';
import 'package:terrascope/services/session_service.dart';
import 'package:terrascope/services/theme_service.dart';
import 'package:terrascope/services/notification_service.dart';
import 'package:terrascope/components/notification_banner.dart';
import 'components/map/map_page.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
  } catch (error, stackTrace) {
    debugPrint('Firebase no está configurado para TerraScope: $error');
    debugPrintStack(stackTrace: stackTrace);
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => RetosObserverProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => NotificationService()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    // Initialize the NotificationService in the RetosObserverProvider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final retosProvider = Provider.of<RetosObserverProvider>(
        context,
        listen: false,
      );
      final notificationService = Provider.of<NotificationService>(
        context,
        listen: false,
      );
      retosProvider.setNotificationService(notificationService);
      unawaited(
        notificationService.initialize(onNotificationTap: _openNotification),
      );
    });
  }

  Future<void> _openNotification(Map<String, dynamic> data) async {
    final navigator = appNavigatorKey.currentState;
    if (navigator == null) return;

    final type = data['type']?.toString();
    final targetId = data['targetId']?.toString();
    if (targetId == null || targetId.isEmpty) return;

    try {
      if (type == 'challenge_expiring') {
        final reto = await RetosService().getRetoById(targetId);
        if (reto == null) throw Exception('El reto ya no está disponible');
        navigator.push(
          MaterialPageRoute(builder: (_) => RetoDetalleScreen(reto: reto)),
        );
        return;
      }

      if (type == 'sighting_nearby' ||
          type == 'sighting_comment' ||
          type == 'sighting_like') {
        final avistamiento = await AvistamientoService.getAvistamientoById(
          targetId,
        );
        final session = await SessionService().getUserData();
        navigator.push(
          MaterialPageRoute(
            builder: (_) => AvistamientoDetailPage(
              avistamiento: avistamiento,
              usuarioId: session?['_id']?.toString(),
              nombreUsuario: session?['nombre_usuario']?.toString(),
            ),
          ),
        );
      }
    } catch (error, stackTrace) {
      debugPrint('No se pudo abrir el destino de la notificación: $error');
      debugPrintStack(stackTrace: stackTrace);
      final context = appNavigatorKey.currentContext;
      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No se pudo abrir el contenido de esta notificación.',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Esto hace que 'MyApp' escuche los cambios y se reconstruya cuando cambias el switch
    final themeProvider = context.watch<ThemeProvider>();

    return MaterialApp(
      navigatorKey: appNavigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'TerraScope',

      theme: themeProvider.lightTheme, // Usamos el tema claro del provider
      darkTheme: themeProvider.darkTheme, // Usamos el tema oscuro del provider
      themeMode: themeProvider.isDarkMode
          ? ThemeMode.dark
          : ThemeMode.light, // El interruptor global

      home: const _SessionStartPage(),
      routes: {
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/map': (context) => const MapPage(),
        '/home': (context) => const HomePage(),
        '/profile': (context) => const ProfileScreen(),
        '/retos': (context) => const RetosActivosScreen(),
        '/logros': (context) => const LogrosScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/home') {}

        if (settings.name == '/map') {
          final args = settings.arguments as Map<String, dynamic>?;
          return MaterialPageRoute(
            builder: (context) => MapPage(
              usuarioId: args?['id_usuario'],
              nombreUsuario: args?['nombre_usuario'],
            ),
          );
        }

        return null;
      },
      builder: (context, child) =>
          Stack(children: [child!, const NotificationBanner()]),
    );
  }
}

class _SessionStartPage extends StatefulWidget {
  const _SessionStartPage();

  @override
  State<_SessionStartPage> createState() => _SessionStartPageState();
}

class _SessionStartPageState extends State<_SessionStartPage> {
  late final Future<bool> _hasSavedSession;

  @override
  void initState() {
    super.initState();
    _hasSavedSession = SessionService().hasSavedSession();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _hasSavedSession,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return snapshot.data == true ? const HomePage() : const LoginPage();
      },
    );
  }
}
