import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:terrascope/services/alerta_service.dart';
import 'package:terrascope/services/auth_service.dart';
import 'package:terrascope/services/danger_alert_presenter.dart';
import 'package:terrascope/services/notification_service.dart';
import 'package:terrascope/services/session_service.dart';
import 'package:terrascope/services/socket_service.dart';

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
  late Animation<Offset> _slideAnimation;

  // Paleta de colores institucional TerraScope
  static const Color primaryGreen = Color(0xFF5C6445);
  static const Color secondaryGreen = Color(0xFF939E69);
  static const Color darkNavy = Color(0xFF0F1D33);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
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
        debugPrint('Sesión guardada correctamente');
        debugPrint('Usuario: ${user['nombre_usuario']}');

        // Conectar al WebSocket para recibir alertas en tiempo real
        if (mounted) {
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
        }

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
          debugPrint('Ubicación enviada al iniciar sesión');
        } catch (e) {
          debugPrint('No se pudo enviar ubicación al login: $e');
        }

        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/home');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white),
                const SizedBox(width: 12),
                Text("¡Bienvenido ${user['nombre_usuario']}!"),
              ],
            ),
            backgroundColor: primaryGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.error_outline_rounded, color: Colors.white),
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
      if (!mounted) return;
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
      resizeToAvoidBottomInset: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF383F28),
              Color(0xFF4A5237),
              Color(0xFF5C6445),
            ],
          ),
        ),
        child: Stack(
          children: [
            // Círculos decorativos ambientales
            Positioned(
              top: -60,
              right: -60,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: secondaryGreen.withOpacity(0.18),
                ),
              ),
            ),
            Positioned(
              bottom: -40,
              left: -50,
              child: Container(
                width: 170,
                height: 170,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.06),
                ),
              ),
            ),

            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: IntrinsicHeight(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24.0,
                            vertical: 14.0,
                          ),
                          child: SlideTransition(
                            position: _slideAnimation,
                            child: FadeTransition(
                              opacity: _fadeAnimation,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Spacer(flex: 1),

                                  // 1. Emblema e identidad compacta
                                  Container(
                                    padding: const EdgeInsets.all(3),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.25),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Container(
                                      padding: const EdgeInsets.all(13),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.white.withOpacity(0.15),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.18),
                                            blurRadius: 16,
                                            offset: const Offset(0, 6),
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.eco_rounded,
                                        color: Colors.white,
                                        size: 34,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    "TerraScope",
                                    style: TextStyle(
                                      fontSize: 27,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                      letterSpacing: 1.8,
                                      shadows: [
                                        Shadow(
                                          color: Colors.black26,
                                          offset: Offset(0, 2),
                                          blurRadius: 6,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 3.5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.14),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.22),
                                        width: 0.8,
                                      ),
                                    ),
                                    child: const Text(
                                      "EXPLORACIÓN & BIODIVERSIDAD",
                                      style: TextStyle(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                        letterSpacing: 1.1,
                                      ),
                                    ),
                                  ),

                                  const Spacer(flex: 1),

                                  // 2. Tarjeta del Formulario
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(24),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.22),
                                          blurRadius: 24,
                                          offset: const Offset(0, 10),
                                        ),
                                      ],
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 22.0,
                                        vertical: 18.0,
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Text(
                                            "¡Bienvenido explorador!",
                                            style: TextStyle(
                                              fontSize: 19,
                                              fontWeight: FontWeight.w800,
                                              color: darkNavy,
                                              letterSpacing: -0.2,
                                            ),
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            "Ingresa tus credenciales para continuar",
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                          const SizedBox(height: 16),

                                          // Correo
                                          Text(
                                            "Correo electrónico",
                                            style: TextStyle(
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.w700,
                                              color: darkNavy.withOpacity(0.85),
                                              letterSpacing: 0.2,
                                            ),
                                          ),
                                          const SizedBox(height: 5),
                                          TextField(
                                            controller: emailController,
                                            keyboardType: TextInputType.emailAddress,
                                            textInputAction: TextInputAction.next,
                                            style: const TextStyle(
                                              color: darkNavy,
                                              fontSize: 13.5,
                                              fontWeight: FontWeight.w500,
                                            ),
                                            decoration: InputDecoration(
                                              filled: true,
                                              fillColor: const Color(0xFFF6F8F4),
                                              hintText: "ejemplo@correo.com",
                                              hintStyle: TextStyle(
                                                color: Colors.grey[400],
                                                fontSize: 13,
                                              ),
                                              prefixIcon: Container(
                                                margin: const EdgeInsets.all(8),
                                                padding: const EdgeInsets.all(5),
                                                decoration: BoxDecoration(
                                                  color: primaryGreen.withOpacity(0.12),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: const Icon(
                                                  Icons.alternate_email_rounded,
                                                  color: primaryGreen,
                                                  size: 16,
                                                ),
                                              ),
                                              contentPadding: const EdgeInsets.symmetric(
                                                horizontal: 14,
                                                vertical: 11,
                                              ),
                                              border: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(12),
                                                borderSide: BorderSide(
                                                  color: Colors.grey[200]!,
                                                  width: 1,
                                                ),
                                              ),
                                              enabledBorder: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(12),
                                                borderSide: BorderSide(
                                                  color: Colors.grey[300]!,
                                                  width: 1,
                                                ),
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(12),
                                                borderSide: const BorderSide(
                                                  color: primaryGreen,
                                                  width: 1.8,
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 12),

                                          // Contraseña
                                          Text(
                                            "Contraseña",
                                            style: TextStyle(
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.w700,
                                              color: darkNavy.withOpacity(0.85),
                                              letterSpacing: 0.2,
                                            ),
                                          ),
                                          const SizedBox(height: 5),
                                          TextField(
                                            controller: passwordController,
                                            obscureText: _obscurePassword,
                                            textInputAction: TextInputAction.done,
                                            onSubmitted: (_) {
                                              if (!isLoading) _login();
                                            },
                                            style: const TextStyle(
                                              color: darkNavy,
                                              fontSize: 13.5,
                                              fontWeight: FontWeight.w500,
                                            ),
                                            decoration: InputDecoration(
                                              filled: true,
                                              fillColor: const Color(0xFFF6F8F4),
                                              hintText: "••••••••",
                                              hintStyle: TextStyle(
                                                color: Colors.grey[400],
                                                fontSize: 13,
                                              ),
                                              prefixIcon: Container(
                                                margin: const EdgeInsets.all(8),
                                                padding: const EdgeInsets.all(5),
                                                decoration: BoxDecoration(
                                                  color: primaryGreen.withOpacity(0.12),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: const Icon(
                                                  Icons.lock_outline_rounded,
                                                  color: primaryGreen,
                                                  size: 16,
                                                ),
                                              ),
                                              suffixIcon: IconButton(
                                                icon: Icon(
                                                  _obscurePassword
                                                      ? Icons.visibility_outlined
                                                      : Icons.visibility_off_outlined,
                                                  color: primaryGreen,
                                                  size: 18,
                                                ),
                                                onPressed: () {
                                                  setState(() {
                                                    _obscurePassword = !_obscurePassword;
                                                  });
                                                },
                                              ),
                                              contentPadding: const EdgeInsets.symmetric(
                                                horizontal: 14,
                                                vertical: 11,
                                              ),
                                              border: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(12),
                                                borderSide: BorderSide(
                                                  color: Colors.grey[200]!,
                                                  width: 1,
                                                ),
                                              ),
                                              enabledBorder: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(12),
                                                borderSide: BorderSide(
                                                  color: Colors.grey[300]!,
                                                  width: 1,
                                                ),
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(12),
                                                borderSide: const BorderSide(
                                                  color: primaryGreen,
                                                  width: 1.8,
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 16),

                                          // Botón Iniciar sesión
                                          SizedBox(
                                            width: double.infinity,
                                            height: 46,
                                            child: ElevatedButton(
                                              onPressed: isLoading ? null : _login,
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: primaryGreen,
                                                foregroundColor: Colors.white,
                                                elevation: 2,
                                                shadowColor: primaryGreen.withOpacity(0.4),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                              ),
                                              child: isLoading
                                                  ? const SizedBox(
                                                      height: 19,
                                                      width: 19,
                                                      child: CircularProgressIndicator(
                                                        color: Colors.white,
                                                        strokeWidth: 2.2,
                                                      ),
                                                    )
                                                  : const Row(
                                                      mainAxisAlignment: MainAxisAlignment.center,
                                                      children: [
                                                        Text(
                                                          "Iniciar sesión",
                                                          style: TextStyle(
                                                            fontSize: 14,
                                                            fontWeight: FontWeight.bold,
                                                            letterSpacing: 0.4,
                                                          ),
                                                        ),
                                                        SizedBox(width: 8),
                                                        Icon(
                                                          Icons.arrow_forward_rounded,
                                                          size: 16,
                                                        ),
                                                      ],
                                                    ),
                                            ),
                                          ),
                                          const SizedBox(height: 14),

                                          // Divisor "O"
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Divider(
                                                  color: Colors.grey[200],
                                                  thickness: 1,
                                                ),
                                              ),
                                              Padding(
                                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                                child: Text(
                                                  "O",
                                                  style: TextStyle(
                                                    color: Colors.grey[400],
                                                    fontSize: 10.5,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                              Expanded(
                                                child: Divider(
                                                  color: Colors.grey[200],
                                                  thickness: 1,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 12),

                                          // Registrarse
                                          Container(
                                            width: double.infinity,
                                            decoration: BoxDecoration(
                                              color: primaryGreen.withOpacity(0.06),
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(
                                                color: primaryGreen.withOpacity(0.18),
                                                width: 1,
                                              ),
                                            ),
                                            child: Material(
                                              color: Colors.transparent,
                                              child: InkWell(
                                                borderRadius: BorderRadius.circular(12),
                                                onTap: () => Navigator.pushNamed(
                                                  context,
                                                  '/register',
                                                ),
                                                child: Padding(
                                                  padding: const EdgeInsets.symmetric(
                                                    vertical: 9,
                                                    horizontal: 14,
                                                  ),
                                                  child: Row(
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    children: [
                                                      Text(
                                                        "¿No tienes cuenta? ",
                                                        style: TextStyle(
                                                          color: Colors.grey[700],
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                      const Text(
                                                        "Regístrate aquí",
                                                        style: TextStyle(
                                                          color: primaryGreen,
                                                          fontSize: 12,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 4),
                                                      const Icon(
                                                        Icons.arrow_forward_ios_rounded,
                                                        size: 11,
                                                        color: primaryGreen,
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
                                  ),

                                  const Spacer(flex: 1),

                                  // 3. Footer
                                  Padding(
                                    padding: const EdgeInsets.only(top: 6.0, bottom: 2.0),
                                    child: Text(
                                      "Al iniciar sesión, aceptas los Términos de Servicio\ny la Política de Privacidad de TerraScope",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.white.withOpacity(0.75),
                                        height: 1.35,
                                      ),
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
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
