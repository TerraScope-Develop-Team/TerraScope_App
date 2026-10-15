import 'package:flutter/material.dart';
import 'package:terrascope/services/auth_service.dart';
import 'package:terrascope/services/session_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final SessionService _sessionService = SessionService(); // ← Instanciar
  bool isLoading = false;

  Future<void> _login() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Por favor ingresa todos los campos.")),
      );
      return;
    }

    setState(() => isLoading = true);

    final user = await AuthService().login(email, password);

    if (user != null) {
      // Guardar la sesion
      final sessionSaved = await _sessionService.saveSession(user);

      setState(() => isLoading = false);

      if (sessionSaved) {
        debugPrint('Sesion guardada correctamente');
        debugPrint('Usuario: ${user['nombre_usuario']}');

        // Navegar sin pasar argumentos (ya están en la sesión)
        Navigator.pushReplacementNamed(context, '/home');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("¡Bienvenido ${user['nombre_usuario']}!"),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Error al guardar la sesión"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Correo o contraseña incorrectos")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF5C6445),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "TerraScope",
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFE0E0E0),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Image.asset("assets/logo.png", height: 45),
                  ],
                ),
                const SizedBox(height: 40),

                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0E0E0),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
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
                          "Iniciar sesión",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F1D33),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "Ingresa tus datos para acceder a tu cuenta",
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF224275),
                          ),
                        ),
                        const SizedBox(height: 30),

                        // Campo correo
                        TextField(
                          controller: emailController,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
                            labelText: "Correo electrónico",
                            prefixIcon: const Icon(
                              Icons.email_outlined,
                              color: Color(0xFF5C6445),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 20),

                        // Campo contraseña
                        TextField(
                          controller: passwordController,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
                            labelText: "Contraseña",
                            prefixIcon: const Icon(
                              Icons.lock_outline,
                              color: Color(0xFF5C6445),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          obscureText: true,
                        ),
                        const SizedBox(height: 30),

                        // Boton
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: isLoading ? null : _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0F1D33),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: isLoading
                                ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                : const Text(
                                    "Continuar",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFFE0E0E0),
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        Center(
                          child: TextButton(
                            onPressed: () =>
                                Navigator.pushNamed(context, '/register'),
                            child: const Text(
                              "¿No tienes cuenta? Regístrate",
                              style: TextStyle(color: Color(0xFF224275)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                const Text(
                  "Al hacer clic en continuar, aceptas nuestros\nTérminos de servicio y Política de privacidad.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Color(0xFFE0E0E0)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
