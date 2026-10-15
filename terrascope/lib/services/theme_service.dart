import 'package:flutter/material.dart';

class ThemeProvider extends ChangeNotifier {
  // Estado inicial (puedes cambiarlo a ThemeMode.system si prefieres)
  ThemeMode _themeMode = ThemeMode.light;

  // Getters
  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  // Lógica de cambio (El evento que notifica a los observadores)
  void toggleTheme(bool isDark) {
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners(); // Notifica el cambio de tema mediante Patron Observer
  }

  // --- DEFINICIÓN DE TEMAS ---
  // Tema Claro (TerraScope Día)
  final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF939E69),
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: Colors.white,
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF939E69),
      foregroundColor: Colors.white,
    ),
  );

  // Tema Oscuro (TerraScope Noche)
  final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF2E7D32), // Verde más oscuro
      brightness: Brightness.dark,
      surface: const Color(0xFF1E1E1E), // Gris muy oscuro para tarjetas
    ),
    scaffoldBackgroundColor: const Color(0xFF121212), // Fondo casi negro
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1B5E20),
      foregroundColor: Colors.white,
    ),
  );
}
