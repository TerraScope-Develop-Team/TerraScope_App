import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:terrascope/services/auth_service.dart';

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
      "fecha_nac_usuario":
          fechaController.text.isNotEmpty ? fechaController.text : null,
      "rol": rolSeleccionado,
      "imagen_perfil": imagenBase64 ?? "",
    };

    final success = await _authService.crearUsuario(usuarioData);

    if (!mounted) return;
    setState(() => isLoading = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white),
              SizedBox(width: 12),
              Text("¡Usuario registrado correctamente!"),
            ],
          ),
          backgroundColor: primaryGreen,
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
              Icon(Icons.error_outline_rounded, color: Colors.white),
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
              top: -50,
              right: -50,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: secondaryGreen.withOpacity(0.18),
                ),
              ),
            ),
            Positioned(
              top: 200,
              left: -60,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.06),
                ),
              ),
            ),

            SafeArea(
              child: Column(
                children: [
                  // 1. Barra superior con botón volver
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 6.0,
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          tooltip: 'Volver al login',
                          icon: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          "Registro de Explorador",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.eco_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 2. Contenido desplazable del formulario
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 22.0,
                        vertical: 10.0,
                      ),
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: FadeTransition(
                          opacity: _fadeAnimation,
                          child: Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                // Selector de Avatar de Perfil
                                Stack(
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white.withOpacity(0.35),
                                          width: 3,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.2),
                                            blurRadius: 18,
                                            offset: const Offset(0, 6),
                                          ),
                                        ],
                                      ),
                                      child: CircleAvatar(
                                        radius: 46,
                                        backgroundColor: const Color(0xFFF6F8F4),
                                        backgroundImage: imagenBase64 != null
                                            ? MemoryImage(
                                                base64Decode(imagenBase64!),
                                              )
                                            : null,
                                        child: imagenBase64 == null
                                            ? const Icon(
                                                Icons.person_outline_rounded,
                                                size: 42,
                                                color: primaryGreen,
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
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: primaryGreen,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: Colors.white,
                                              width: 2.5,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black
                                                    .withOpacity(0.25),
                                                blurRadius: 6,
                                                offset: const Offset(0, 3),
                                              ),
                                            ],
                                          ),
                                          child: const Icon(
                                            Icons.camera_alt_rounded,
                                            color: Colors.white,
                                            size: 16,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  "Toca el ícono de cámara para subir tu foto",
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: Colors.white.withOpacity(0.8),
                                  ),
                                ),
                                const SizedBox(height: 20),

                                // Tarjeta principal del formulario
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
                                      vertical: 20.0,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          "Información personal",
                                          style: TextStyle(
                                            fontSize: 19,
                                            fontWeight: FontWeight.w800,
                                            color: darkNavy,
                                            letterSpacing: -0.2,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          "Completa tus datos para crear tu cuenta",
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                        const SizedBox(height: 18),

                                        // Nombre completo
                                        _buildFieldLabel("Nombre completo *"),
                                        const SizedBox(height: 5),
                                        _buildTextField(
                                          controller: nombreController,
                                          hintText: "Ej. Alex Rivera",
                                          icon: Icons.person_outline_rounded,
                                          validator: (val) => val == null ||
                                                  val.trim().isEmpty
                                              ? "Campo obligatorio"
                                              : null,
                                        ),
                                        const SizedBox(height: 14),

                                        // Correo electrónico
                                        _buildFieldLabel(
                                            "Correo electrónico *"),
                                        const SizedBox(height: 5),
                                        _buildTextField(
                                          controller: emailController,
                                          hintText: "ejemplo@correo.com",
                                          icon: Icons.alternate_email_rounded,
                                          keyboardType:
                                              TextInputType.emailAddress,
                                          validator: (value) {
                                            if (value == null ||
                                                value.trim().isEmpty) {
                                              return "Campo obligatorio";
                                            }
                                            final emailRegex = RegExp(
                                              r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                                            );
                                            if (!emailRegex.hasMatch(value)) {
                                              return "Correo electrónico no válido";
                                            }
                                            return null;
                                          },
                                        ),
                                        const SizedBox(height: 14),

                                        // Contraseña
                                        _buildFieldLabel("Contraseña *"),
                                        const SizedBox(height: 5),
                                        _buildTextField(
                                          controller: passwordController,
                                          hintText: "Mínimo 6 caracteres",
                                          icon: Icons.lock_outline_rounded,
                                          obscureText: _obscurePassword,
                                          suffixIcon: IconButton(
                                            icon: Icon(
                                              _obscurePassword
                                                  ? Icons.visibility_outlined
                                                  : Icons
                                                      .visibility_off_outlined,
                                              color: primaryGreen,
                                              size: 18,
                                            ),
                                            onPressed: () {
                                              setState(() {
                                                _obscurePassword =
                                                    !_obscurePassword;
                                              });
                                            },
                                          ),
                                          validator: (value) {
                                            if (value == null ||
                                                value.isEmpty) {
                                              return "Campo obligatorio";
                                            }
                                            if (value.length < 6) {
                                              return "Debe tener al menos 6 caracteres";
                                            }
                                            final upperCaseRegex =
                                                RegExp(r'[A-Z]');
                                            final specialCharRegex = RegExp(
                                              r'[!@#\$%^&*(),.?":{}|<>]',
                                            );
                                            if (!upperCaseRegex
                                                .hasMatch(value)) {
                                              return "Incluye al menos una mayúscula";
                                            }
                                            if (!specialCharRegex
                                                .hasMatch(value)) {
                                              return "Incluye al menos un símbolo especial";
                                            }
                                            return null;
                                          },
                                        ),
                                        const SizedBox(height: 14),

                                        // Teléfono
                                        _buildFieldLabel("Teléfono (opcional)"),
                                        const SizedBox(height: 5),
                                        _buildTextField(
                                          controller: telefonoController,
                                          hintText: "Ej. 5512345678",
                                          icon: Icons.phone_outlined,
                                          keyboardType: TextInputType.phone,
                                        ),
                                        const SizedBox(height: 14),

                                        // Fecha de nacimiento
                                        _buildFieldLabel(
                                            "Fecha de nacimiento"),
                                        const SizedBox(height: 5),
                                        _buildTextField(
                                          controller: fechaController,
                                          readOnly: true,
                                          hintText: fechaController
                                                  .text.isNotEmpty
                                              ? DateFormat('dd/MM/yyyy').format(
                                                  DateTime.parse(
                                                    fechaController.text,
                                                  ),
                                                )
                                              : "Selecciona tu fecha",
                                          icon: Icons.calendar_today_outlined,
                                          suffixIcon: IconButton(
                                            icon: const Icon(
                                              Icons.event_rounded,
                                              color: primaryGreen,
                                              size: 20,
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
                                                    data: Theme.of(context)
                                                        .copyWith(
                                                      colorScheme:
                                                          const ColorScheme
                                                              .light(
                                                        primary: primaryGreen,
                                                        onPrimary: Colors.white,
                                                      ),
                                                    ),
                                                    child: child!,
                                                  );
                                                },
                                              );
                                              if (pickedDate != null) {
                                                setState(() {
                                                  fechaController.text =
                                                      pickedDate
                                                          .toIso8601String();
                                                });
                                              }
                                            },
                                          ),
                                        ),
                                        const SizedBox(height: 14),

                                        // Rol en la plataforma
                                        _buildFieldLabel(
                                            "Rol en la plataforma"),
                                        const SizedBox(height: 5),
                                        Container(
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF6F8F4),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            border: Border.all(
                                              color: Colors.grey[300]!,
                                              width: 1,
                                            ),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                          ),
                                          child:
                                              DropdownButtonFormField<String>(
                                            value: rolSeleccionado,
                                            items: const [
                                              DropdownMenuItem(
                                                value: "Usuario",
                                                child: Text("Usuario"),
                                              ),
                                              DropdownMenuItem(
                                                value: "Investigador",
                                                child: Text("Investigador"),
                                              ),
                                              DropdownMenuItem(
                                                value: "Administrador",
                                                child: Text("Administrador"),
                                              ),
                                            ],
                                            onChanged: (value) {
                                              if (value != null) {
                                                setState(() =>
                                                    rolSeleccionado = value);
                                              }
                                            },
                                            style: const TextStyle(
                                              color: darkNavy,
                                              fontSize: 13.5,
                                              fontWeight: FontWeight.w500,
                                            ),
                                            decoration: InputDecoration(
                                              prefixIcon: Container(
                                                margin: const EdgeInsets.all(8),
                                                padding:
                                                    const EdgeInsets.all(5),
                                                decoration: BoxDecoration(
                                                  color: primaryGreen
                                                      .withOpacity(0.12),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: const Icon(
                                                  Icons.badge_outlined,
                                                  color: primaryGreen,
                                                  size: 16,
                                                ),
                                              ),
                                              border: InputBorder.none,
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                vertical: 8,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 22),

                                        // Botón Crear cuenta
                                        SizedBox(
                                          width: double.infinity,
                                          height: 48,
                                          child: ElevatedButton(
                                            onPressed: isLoading
                                                ? null
                                                : _registrarUsuario,
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: primaryGreen,
                                              foregroundColor: Colors.white,
                                              elevation: 2,
                                              shadowColor: primaryGreen
                                                  .withOpacity(0.4),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                            ),
                                            child: isLoading
                                                ? const SizedBox(
                                                    height: 20,
                                                    width: 20,
                                                    child:
                                                        CircularProgressIndicator(
                                                      color: Colors.white,
                                                      strokeWidth: 2.2,
                                                    ),
                                                  )
                                                : const Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment.center,
                                                    children: [
                                                      Text(
                                                        "Crear cuenta",
                                                        style: TextStyle(
                                                          fontSize: 14.5,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          letterSpacing: 0.4,
                                                        ),
                                                      ),
                                                      SizedBox(width: 8),
                                                      Icon(
                                                        Icons
                                                            .check_circle_outline_rounded,
                                                        size: 18,
                                                      ),
                                                    ],
                                                  ),
                                          ),
                                        ),
                                        const SizedBox(height: 16),

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
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 10,
                                              ),
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
                                        const SizedBox(height: 14),

                                        // Iniciar sesión
                                        Container(
                                          width: double.infinity,
                                          decoration: BoxDecoration(
                                            color:
                                                primaryGreen.withOpacity(0.06),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            border: Border.all(
                                              color: primaryGreen
                                                  .withOpacity(0.18),
                                              width: 1,
                                            ),
                                          ),
                                          child: Material(
                                            color: Colors.transparent,
                                            child: InkWell(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              onTap: () =>
                                                  Navigator.pop(context),
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  vertical: 10,
                                                  horizontal: 14,
                                                ),
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Text(
                                                      "¿Ya tienes cuenta? ",
                                                      style: TextStyle(
                                                        color: Colors.grey[700],
                                                        fontSize: 12.5,
                                                      ),
                                                    ),
                                                    const Text(
                                                      "Inicia sesión",
                                                      style: TextStyle(
                                                        color: primaryGreen,
                                                        fontSize: 12.5,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 4),
                                                    const Icon(
                                                      Icons
                                                          .arrow_forward_ios_rounded,
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
                                const SizedBox(height: 24),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 11.5,
        fontWeight: FontWeight.w700,
        color: darkNavy.withOpacity(0.85),
        letterSpacing: 0.2,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
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
      style: const TextStyle(
        color: darkNavy,
        fontSize: 13.5,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFFF6F8F4),
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
        prefixIcon: Container(
          margin: const EdgeInsets.all(8),
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: primaryGreen.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: primaryGreen, size: 16),
        ),
        suffixIcon: suffixIcon,
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
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Colors.red,
            width: 1,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Colors.red,
            width: 1.8,
          ),
        ),
      ),
    );
  }
}
