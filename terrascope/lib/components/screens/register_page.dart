import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:terrascope/services/auth_service.dart';
import 'package:intl/intl.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();

  final TextEditingController nombreController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController telefonoController = TextEditingController();
  final TextEditingController fechaController = TextEditingController();

  String rolSeleccionado = 'Usuario';
  String? imagenBase64;
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
    nombreController.dispose();
    emailController.dispose();
    passwordController.dispose();
    telefonoController.dispose();
    fechaController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedImage = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (pickedImage != null) {
      final bytes = await pickedImage.readAsBytes();
      setState(() {
        imagenBase64 = base64Encode(bytes);
      });
    }
  }

  Future<void> _registrarUsuario() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    final usuarioData = {
      "nombre_usuario": nombreController.text.trim(),
      "email_usuario": emailController.text.trim(),
      "contrasenia_usuario": passwordController.text.trim(),
      "telefono_usuario": telefonoController.text.trim(),
      "fecha_nac_usuario": fechaController.text.isNotEmpty
          ? fechaController.text
          : null,
      "rol": rolSeleccionado,
      "imagen_perfil": imagenBase64 ?? "",
    };

    final success = await _authService.crearUsuario(usuarioData);

    setState(() => isLoading = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Text("Usuario registrado correctamente"),
            ],
          ),
          backgroundColor: Colors.green[600],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 12),
              Text("Error al registrar usuario"),
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const SizedBox(height: 20),

                    // Logo y título
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 20,
                            spreadRadius: 3,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.eco,
                        color: Color(0xFFE0E0E0),
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "TerraScope",
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFE0E0E0),
                        letterSpacing: 1.5,
                        shadows: [
                          Shadow(
                            color: Colors.black26,
                            offset: Offset(0, 3),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Crea tu cuenta",
                      style: TextStyle(
                        fontSize: 16,
                        color: const Color(0xFFE0E0E0).withOpacity(0.8),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Foto de perfil mejorada
                    Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 60,
                            backgroundColor: Colors.white,
                            backgroundImage: imagenBase64 != null
                                ? MemoryImage(base64Decode(imagenBase64!))
                                : null,
                            child: imagenBase64 == null
                                ? const Icon(
                                    Icons.person,
                                    size: 50,
                                    color: Color(0xFF5C6445),
                                  )
                                : null,
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _pickImage,
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFF5C6445),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 3,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Toca el ícono para añadir foto",
                      style: TextStyle(
                        fontSize: 12,
                        color: const Color(0xFFE0E0E0).withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Card principal
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
                        padding: const EdgeInsets.all(28.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Información personal",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Nombre
                            _buildTextField(
                              controller: nombreController,
                              label: "Nombre completo",
                              icon: Icons.person_outline,
                              validator: (value) =>
                                  value!.isEmpty ? "Campo obligatorio" : null,
                            ),
                            const SizedBox(height: 18),

                            // Email
                            _buildTextField(
                              controller: emailController,
                              label: "Correo electrónico",
                              icon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return "Campo obligatorio";
                                }

                                // Expresión regular para validar correos
                                final emailRegex = RegExp(
                                  r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                                );
                                if (!emailRegex.hasMatch(value)) {
                                  return "Correo electrónico no válido";
                                }

                                return null;
                              },
                            ),
                            const SizedBox(height: 18),

                            // Contraseña
                            _buildTextField(
                              controller: passwordController,
                              label: "Contraseña",
                              icon: Icons.lock_outline,
                              obscureText: _obscurePassword,
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
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return "Campo obligatorio";
                                }

                                if (value.length < 6) {
                                  return "Debe tener al menos 6 caracteres";
                                }

                                // Al menos una mayúscula y un carácter especial
                                final upperCaseRegex = RegExp(r'[A-Z]');
                                final specialCharRegex = RegExp(
                                  r'[!@#\$%^&*(),.?":{}|<>]',
                                );

                                if (!upperCaseRegex.hasMatch(value)) {
                                  return "Debe incluir al menos una letra mayúscula";
                                }

                                if (!specialCharRegex.hasMatch(value)) {
                                  return "Debe incluir al menos un carácter especial";
                                }

                                return null;
                              },
                            ),

                            const SizedBox(height: 18),

                            // Teléfono
                            _buildTextField(
                              controller: telefonoController,
                              label: "Teléfono (opcional)",
                              icon: Icons.phone_outlined,
                              keyboardType: TextInputType.phone,
                            ),
                            const SizedBox(height: 18),

                            // Fecha de nacimiento
                            _buildTextField(
                              controller: fechaController,
                              label: "Fecha de nacimiento",
                              icon: Icons.calendar_today_outlined,
                              readOnly: true,
                              suffixIcon: IconButton(
                                icon: const Icon(
                                  Icons.event,
                                  color: Color(0xFF5C6445),
                                ),
                                onPressed: () async {
                                  final DateTime? pickedDate =
                                      await showDatePicker(
                                        context: context,
                                        initialDate: DateTime(2000),
                                        firstDate: DateTime(1900),
                                        lastDate: DateTime.now(),
                                        builder: (context, child) {
                                          return Theme(
                                            data: Theme.of(context).copyWith(
                                              colorScheme:
                                                  const ColorScheme.light(
                                                    primary: Color(0xFF5C6445),
                                                    onPrimary: Colors.white,
                                                  ),
                                            ),
                                            child: child!,
                                          );
                                        },
                                      );
                                  if (pickedDate != null) {
                                    setState(() {
                                      fechaController.text = pickedDate
                                          .toIso8601String();
                                    });
                                  }
                                },
                              ),
                              hintText: fechaController.text.isNotEmpty
                                  ? DateFormat('dd/MM/yyyy').format(
                                      DateTime.parse(fechaController.text),
                                    )
                                  : "Selecciona tu fecha",
                            ),
                            const SizedBox(height: 18),

                            // Rol
                            Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFFF5F5F5),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: DropdownButtonFormField<String>(
                                value: rolSeleccionado,
                                items: const [
                                  DropdownMenuItem(
                                    value: "Administrador",
                                    child: Text("Administrador"),
                                  ),
                                  DropdownMenuItem(
                                    value: "Investigador",
                                    child: Text("Investigador"),
                                  ),
                                  DropdownMenuItem(
                                    value: "Usuario",
                                    child: Text("Usuario"),
                                  ),
                                ],
                                onChanged: (value) {
                                  setState(() => rolSeleccionado = value!);
                                },
                                decoration: InputDecoration(
                                  labelText: "Rol",
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
                                      Icons.badge_outlined,
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
                              ),
                            ),
                            const SizedBox(height: 30),

                            // Botón registrarse
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                onPressed: isLoading ? null : _registrarUsuario,
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
                                            "Crear cuenta",
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                          SizedBox(width: 8),
                                          Icon(
                                            Icons.check_circle_outline,
                                            size: 20,
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Divider
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

                            // Link a login
                            Center(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    "¿Ya tienes cuenta?",
                                    style: TextStyle(
                                      color: Colors.grey[700],
                                      fontSize: 14,
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                      ),
                                    ),
                                    child: const Text(
                                      "Inicia sesión",
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
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hintText,
    bool obscureText = false,
    bool readOnly = false,
    TextInputType? keyboardType,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      readOnly: readOnly,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFFF5F5F5),
        labelText: label,
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
        labelStyle: const TextStyle(color: Color(0xFF5C6445), fontSize: 14),
        prefixIcon: Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF5C6445).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: const Color(0xFF5C6445), size: 20),
        ),
        suffixIcon: suffixIcon,
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
          borderSide: const BorderSide(color: Color(0xFF5C6445), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
      ),
    );
  }
}
