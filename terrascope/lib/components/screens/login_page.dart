import 'package:provider/provider.dart';
import 'package:terrascope/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:terrascope/services/auth_service.dart';
import 'package:terrascope/services/session_service.dart';
import 'package:terrascope/services/socket_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:terrascope/services/alerta_service.dart';
import 'package:terrascope/services/danger_alert_presenter.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final SessionService _sessionService = SessionService();
  bool isLoading = false;
  bool _obscurePassword = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.white),
              SizedBox(width: 12),
              Text("Por favor ingresa todos los campos"),
            ],
          ),
          backgroundColor: Colors.orange[700],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    final user = await AuthService().login(email, password);

    if (user != null) {
      final sessionSaved = await _sessionService.saveSession(user);

      setState(() => isLoading = false);

      if (sessionSaved) {
        print('✅ Sesión guardada correctamente');
        print('👤 Usuario: ${user['nombre_usuario']}');

        // Conectar al WebSocket para recibir alertas en tiempo real
        final notificationService = Provider.of<NotificationService>(
          context,
          listen: false,
        );
        await SocketService().initSocket(
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

        // Enviar ubicación actual al backend para que pueda notificarnos
        try {
          Position position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
            timeLimit: const Duration(seconds: 10),
          );
          await AlertaService().updateLocation(
            position.latitude,
            position.longitude,
          );
          print('📍 Ubicación enviada al iniciar sesión');
        } catch (e) {
          print('⚠️ No se pudo enviar ubicación al login: $e');
        }

        Navigator.pushReplacementNamed(context, '/home');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Text("¡Bienvenido ${user['nombre_usuario']}!"),
              ],
            ),
            backgroundColor: Colors.green[600],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white),
                SizedBox(width: 12),
                Text("Error al guardar la sesión"),
              ],
            ),
            backgroundColor: Colors.red[700],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } else {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.cancel_outlined, color: Colors.white),
              SizedBox(width: 12),
              Text("Correo o contraseña incorrectos"),
            ],
          ),
          backgroundColor: Colors.red[700],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF5C6445),
              const Color(0xFF4A5237),
              const Color(0xFF3A4129),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo animado
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 30,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.eco,
                        color: Color(0xFFE0E0E0),
                        size: 60,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "TerraScope",
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFE0E0E0),
                        letterSpacing: 2,
                        shadows: [
                          Shadow(
                            color: Colors.black26,
                            offset: Offset(0, 4),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Monitoreo ambiental inteligente",
                      style: TextStyle(
                        fontSize: 14,
                        color: const Color(0xFFE0E0E0).withOpacity(0.8),
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 50),

                    // Card con glassmorphism
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.95),
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 30,
                            offset: const Offset(0, 15),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              "Bienvenido de nuevo",
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F1D33),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Ingresa tus credenciales para continuar",
                              style: TextStyle(
                                fontSize: 14,
                                color: const Color(0xFF224275).withOpacity(0.7),
                              ),
                            ),
                            const SizedBox(height: 35),

                            // Campo correo mejorado
                            TextField(
                              controller: emailController,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: const Color(0xFFF5F5F5),
                                labelText: "Correo electrónico",
                                labelStyle: const TextStyle(
                                  color: Color(0xFF5C6445),
                                  fontSize: 14,
                                ),
                                prefixIcon: Container(
                                  margin: const EdgeInsets.all(12),
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFF5C6445,
                                    ).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.email_outlined,
                                    color: Color(0xFF5C6445),
                                    size: 20,
                                  ),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(
                                    color: Color(0xFF5C6445),
                                    width: 2,
                                  ),
                                ),
                              ),
                              keyboardType: TextInputType.emailAddress,
                            ),
                            const SizedBox(height: 20),

                            // Campo contraseña mejorado
                            TextField(
                              controller: passwordController,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: const Color(0xFFF5F5F5),
                                labelText: "Contraseña",
                                labelStyle: const TextStyle(
                                  color: Color(0xFF5C6445),
                                  fontSize: 14,
                                ),
                                prefixIcon: Container(
                                  margin: const EdgeInsets.all(12),
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFF5C6445,
                                    ).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.lock_outline,
                                    color: Color(0xFF5C6445),
                                    size: 20,
                                  ),
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                    color: const Color(0xFF5C6445),
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(
                                    color: Color(0xFF5C6445),
                                    width: 2,
                                  ),
                                ),
                              ),
                              obscureText: _obscurePassword,
                            ),

                            const SizedBox(height: 16),

                            // Botón con gradiente
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                onPressed: isLoading ? null : _login,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0F1D33),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  shadowColor: const Color(
                                    0xFF0F1D33,
                                  ).withOpacity(0.4),
                                ),
                                child: isLoading
                                    ? const SizedBox(
                                        height: 24,
                                        width: 24,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2.5,
                                        ),
                                      )
                                    : const Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            "Iniciar sesión",
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                          SizedBox(width: 8),
                                          Icon(Icons.arrow_forward, size: 20),
                                        ],
                                      ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Divider con "o"
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    height: 1,
                                    color: Colors.grey[300],
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  child: Text(
                                    "o",
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Container(
                                    height: 1,
                                    color: Colors.grey[300],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            // Botón registrarse
                            Center(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    "¿No tienes cuenta?",
                                    style: TextStyle(
                                      color: Colors.grey[700],
                                      fontSize: 14,
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pushNamed(
                                      context,
                                      '/register',
                                    ),
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                      ),
                                    ),
                                    child: const Text(
                                      "Regístrate aquí",
                                      style: TextStyle(
                                        color: Color(0xFF5C6445),
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    Text(
                      "Al iniciar sesión, aceptas nuestros\nTérminos de servicio y Política de privacidad",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        color: const Color(0xFFE0E0E0).withOpacity(0.7),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
