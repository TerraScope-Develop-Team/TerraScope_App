import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:terrascope/components/screens/login_page.dart';
import 'package:terrascope/components/screens/pagina_inicio.dart';
import 'package:terrascope/components/screens/profile_page.dart';
import 'package:terrascope/components/screens/register_page.dart';
import 'package:terrascope/components/screens/retos_activos_screen.dart';
import 'package:terrascope/components/screens/logros_screen.dart';
import 'package:terrascope/providers/retos_observer_provider.dart';
import 'package:terrascope/services/theme_service.dart';
import 'package:terrascope/services/notification_service.dart';
import 'package:terrascope/components/notification_banner.dart';
import 'components/map/map_page.dart';

// Navigator key global para poder navegar desde cualquier contexto (ej: NotificationBanner)
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() {
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
    });
  }

  @override
  Widget build(BuildContext context) {
    // Esto hace que 'MyApp' escuche los cambios y se reconstruya cuando cambias el switch
    final themeProvider = context.watch<ThemeProvider>();

    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'TerraScope',

      theme: themeProvider.lightTheme, // Usamos el tema claro del provider
      darkTheme: themeProvider.darkTheme, // Usamos el tema oscuro del provider
      themeMode: themeProvider.isDarkMode
          ? ThemeMode.dark
          : ThemeMode.light, // El interruptor global

      initialRoute: '/login',
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
