# 📱 TerraScope Mobile App

> **Aplicación Móvil en Flutter para Monitoreo de Biodiversidad, Captura Asistida por IA, Gamificación Comunitaria y Seguridad Ambiental.**

[![Flutter](https://img.shields.io/badge/Flutter-v3.x-blue.svg?logo=flutter)](https://flutter.dev/)
[![Dart](https://img.shields.io/badge/Dart-v3.9+-0175C2.svg?logo=dart)](https://dart.dev/)
[![Provider](https://img.shields.io/badge/State-Provider%20v6.1.1-purple.svg)](https://pub.dev/packages/provider)
[![Platform](https://img.shields.io/badge/Platforms-Android%20%7C%20iOS%20%7C%20Web-lightgrey.svg)](https://flutter.dev)
[![Socket.IO Client](https://img.shields.io/badge/RealTime-Socket.IO%20Client-black.svg?logo=socket.io)](https://pub.dev/packages/socket_io_client)
[![Firebase](https://img.shields.io/badge/Push-Firebase%20FCM-orange.svg?logo=firebase)](https://firebase.google.com/)

---

## 📌 Tabla de Contenidos

- [Descripción General](#-descripción-general)
- [Arquitectura de la Aplicación](#-arquitectura-de-la-aplicación)
- [Stack Tecnológico y Dependencias](#-stack-tecnológico-y-dependencias)
- [Módulos y Pantallas Principales](#-módulos-y-pantallas-principales)
  - [1. Feed Social y Exploración de Avistamientos](#1-feed-social-y-exploración-de-avistamientos)
  - [2. Sistema de Validación Comunitaria (MVP04)](#2-sistema-de-validación-comunitaria-mvp04)
  - [3. Registro y Clasificación Asistida por IA (Google Gemini)](#3-registro-y-clasificación-asistida-por-ia-google-gemini)
  - [4. Modo Emergencia SOS y Alertas Tempranas de Peligro](#4-modo-emergencia-sos-y-alertas-tempranas-de-peligro)
  - [5. Mapa Interactivo y Zonas Frecuentes](#5-mapa-interactivo-y-zonas-frecuentes)
  - [6. Gamificación, Retos y Logros](#6-gamificación-retos-y-logros)
- [Estructura del Proyecto (`lib/`)](#-estructura-del-proyecto-lib)
- [Configuración de Red y Seguridad](#-configuración-de-red-y-seguridad)
- [Permisos del Dispositivo (Android / iOS)](#-permisos-del-dispositivo-android--ios)
- [Guía de Instalación y Ejecución](#-guía-de-instalación-y-ejecución)
- [Pruebas y Análisis de Calidad](#-pruebas-y-análisis-de-calidad)

---

## 📖 Descripción General

**TerraScope App** es una aplicación móvil moderna que convierte a cualquier explorador o ciudadano en un científico participativo. Permite documentar la riqueza ecológica regional, validar colaborativamente la precisión de las clasificaciones taxonómicas, recibir alertas preventivas ante especies peligrosas en el entorno inmediato y solicitar auxilio geoespacial inmediato en zonas agrestes.

---

## 🏛 Arquitectura de la Aplicación

La aplicación implementa una arquitectura desacoplada por responsabilidades (*Feature & Layer-Based Architecture*) apoyada en el patrón de inyección de estado **Provider**:

```
┌─────────────────────────────────────────────────────────────┐
│                    Presentation Layer                       │
│    (Screens, Widgets, Cards, Modals, SlideToConfirm)        │
└──────────────────────────────┬──────────────────────────────┘
                               │ Observa y notifica
                               ▼
┌─────────────────────────────────────────────────────────────┐
│                 State Management (Providers)                │
│ (FaunaFloraProvider, RetosObserverProvider, RequestStateMixin)│
└──────────────────────────────┬──────────────────────────────┘
                               │ Consume
                               ▼
┌─────────────────────────────────────────────────────────────┐
│                       Services Layer                        │
│ (FaunaFloraService, LocationService, AlertaService, Socket) │
└──────────────┬───────────────────────────────┬──────────────┘
               │                               │
               ▼                               ▼
┌──────────────────────────────┐ ┌─────────────────────────────┐
│       Network Client         │ │     Local Persistence       │
│  (ApiClient, AuthClient,     │ │ (FlutterSecureStorage JWT,  │
│   ApiResponse, ApiException) │ │  SharedPreferences Cache)   │
└──────────────────────────────┘ └─────────────────────────────┘
```

### Características Arquitectónicas
- **Manejo Unificado de Estado Asíncrono (`RequestStateMixin`)**: Encapsula el ciclo de vida `idle -> loading -> success | error` y mapea excepciones de red (`ApiException`) a mensajes legibles sin repetir lógica en los controladores.
- **Cliente HTTP Centralizado (`ApiClient` / `AuthClient`)**: Inyección automática de cabeceras de autorización (`Bearer <token>`), interceptores de códigos HTTP y formateo consistente de peticiones multipart y JSON.
- **Persistencia Segura en Dos Niveles**:
  - `FlutterSecureStorage`: Almacena el token criptográfico JWT en el KeyStore (Android) o Keychain (iOS).
  - `SharedPreferences`: Almacena perfiles de usuario, roles y preferencias de interfaz (modo oscuro/claro).

---

## 🛠 Stack Tecnológico y Dependencias

| Categoría | Paquete | Versión | Rol en el Proyecto |
| :--- | :--- | :--- | :--- |
| **Framework Base** | Flutter / Dart | >= 3.x / ^3.9.2 | Núcleo de la interfaz multiplataforma |
| **Estado Global** | `provider` | ^6.1.1 | Inyección de dependencias y reactividad |
| **Networking** | `http` | ^1.5.0 | Consumo de la API RESTful de TerraScope |
| **WebSockets** | `socket_io_client` | ^3.1.6 | Conexión en tiempo real para alertas |
| **Mapas & GIS** | `flutter_map` / `latlong2` | ^6.0.1 / ^0.9.0 | Renderizado de mosaicos OpenStreetMap |
| **Geolocalización** | `geolocator` | ^14.0.2 | Coordenadas GPS y cálculo de radio de riesgo |
| **Cámara & Fotos** | `image_picker` / `image` | ^1.2.0 / ^4.3.0 | Captura, compresión y codificación Base64 |
| **Notificaciones** | `firebase_messaging` / `flutter_local_notifications` | ^16.7.0 / ^22.3.1 | Notificaciones push remotas y banner de cabecera |
| **Almacenamiento**| `flutter_secure_storage` / `shared_preferences` | ^9.2.4 / ^2.2.2 | Seguridad de tokens y persistencia local |
| **Exportación** | `pdf` / `excel` / `open_file` | ^3.10.7 / ^2.0.1 / ^3.3.3 | Reportes de campo y diplomas de retos |
| **Integraciones** | `url_launcher` | ^6.3.3 | Marcación directa al 911 en emergencias SOS |

---

## 📱 Módulos y Pantallas Principales

### 1. Feed Social y Exploración de Avistamientos
* Ubicación: [`lib/components/screens/pagina_inicio.dart`](file:///c:/Desarrollo%20Movil%20Integral/TerraScope/TerraScope_App/terrascope/lib/components/screens/pagina_inicio.dart).
* Alternancia fluida entre **"Explorar todo"** y **"Siguiendo"** (feed curado de amigos y expertos).
* Búsqueda en vivo por nombre común o científico y filtrado por categoría taxonómica (`Fauna` / `Flora`).
* Interacciones sociales integradas: contador y animación de Likes en tiempo real, acceso a comentarios y perfiles de exploradores.

### 2. Sistema de Validación Comunitaria (MVP04)
Implementado en [`lib/components/screens/pagina_inicio.dart`](file:///c:/Desarrollo%20Movil%20Integral/TerraScope/TerraScope_App/terrascope/lib/components/screens/pagina_inicio.dart) y respaldado por [`Validacion`](file:///c:/Desarrollo%20Movil%20Integral/TerraScope/TerraScope_App/terrascope/lib/components/models/validacion_model.dart):
* **Panel de Evaluación Comunitaria**:
  * Visualización del **tiempo restante** del periodo de votación (ej. `"Cierra en 18h 32m"`).
  * Contadores desglosados: **A favor** (positivos) y **En contra** (negativos).
  * **Barra de Proporción Dinámica**: Muestra la correlación visual de aprobación vs. rechazo de la comunidad.
* **Acciones**:
  * Dos botones independientes: **"A favor"** (verde `#5C6445`) y **"En contra"** (rojo `Colors.red.shade700`).
  * Indicador de confirmación: `"Votaste a favor"` o `"Votaste en contra"`.
  * Validación por Experto: Si el usuario cuenta con rol de `Investigador`, `Experto` o `Administrador`, puede certificar formalmente la especie como válida con un botón directo.
* **Borrado Reactivo**: Si el avistamiento alcanza la mayoría de votos negativos o vence sin votos, la tarjeta lo detecta, emite un aviso informativo y **lo remueve automáticamente de la lista** en pantalla.

### 3. Registro y Clasificación Asistida por IA (Google Gemini)
* Ubicación: [`lib/components/screens/registro_avistamiento_screen.dart`](file:///c:/Desarrollo%20Movil%20Integral/TerraScope/TerraScope_App/terrascope/lib/components/screens/registro_avistamiento_screen.dart).
* Captura de fotografía desde la cámara o galería con auto-rotación y optimización.
* Componente [`ia_registro.dart`](file:///c:/Desarrollo%20Movil%20Integral/TerraScope/TerraScope_App/terrascope/lib/components/ia/ia_registro.dart): Envía el especimen al backend para obtener una sugerencia taxonómica instantánea (nombre científico, riesgo de extinción, advertencia de toxicidad).
* Auto-rellenado inteligente de campos para acelerar el registro en campo.

### 4. Modo Emergencia SOS y Alertas Tempranas de Peligro
* **Protocolo SOS**:
  * Botón persistente en la barra de navegación inferior.
  * Modal de alta seguridad con componente interactivo **`SlideToConfirm`** para prevenir pulsaciones accidentales.
  * Al confirmarse, despacha las coordenadas GPS al backend y lanza automáticamente la marcación telefónica hacia las autoridades (911).
* **Alertas Tempranas de Fauna Peligrosa**:
  * [`danger_alert_presenter.dart`](file:///c:/Desarrollo%20Movil%20Integral/TerraScope/TerraScope_App/terrascope/lib/services/danger_alert_presenter.dart): Notificaciones emergentes inmediatas si se reporta un espécimen venenoso o agresivo en un radio cercano al usuario.

### 5. Mapa Interactivo y Zonas Frecuentes
* Ubicación: [`lib/components/map/map_page.dart`](file:///c:/Desarrollo%20Movil%20Integral/TerraScope/TerraScope_App/terrascope/lib/components/map/map_page.dart).
* Renderizado de marcadores agrupados sobre OpenStreetMap.
* Visualización de capas de hábitats y zonas de alta concentración de avistamientos.

### 6. Gamificación, Retos y Logros
* Ubicación: [`lib/providers/retos_observer_provider.dart`](file:///c:/Desarrollo%20Movil%20Integral/TerraScope/TerraScope_App/terrascope/lib/providers/retos_observer_provider.dart).
* Sistema de progreso por categorías (Mamíferos, Aves, Hongos, etc.).
* Desbloqueo de medallas, títulos honoríficos y recepción de certificados digitales.

---

## 📂 Estructura del Proyecto (`lib/`)

```
lib/
├── components/
│   ├── ia/
│   │   └── ia_registro.dart          # Integración cliente con Gemini AI
│   ├── map/
│   │   ├── avistamiento_detail_loader.dart
│   │   └── map_page.dart             # Mapa interactivo con flutter_map
│   ├── models/                       # Modelos de datos inmutables
│   │   ├── avistamiento_model.dart
│   │   ├── comentario.dart
│   │   ├── habitat.dart
│   │   ├── validacion_model.dart     # Modelo de validación y votos MVP04
│   │   └── zona_frecuente.dart
│   ├── screens/                      # Vistas y pantallas principales
│   │   ├── notification_center_screen.dart
│   │   ├── pagina_inicio.dart        # Feed, tarjetas y validación comunitaria
│   │   ├── profile_page.dart
│   │   └── registro_avistamiento_screen.dart
│   ├── ui/
│   │   └── slide_to_confirm.dart     # Control táctil para activación de SOS
│   └── validations/
│       └── avistamiento_validacion.dart # Provider de validaciones
├── config/
│   ├── api_config.dart               # Base URLs y endpoints
│   ├── auth_client.dart              # Cliente con inyección de JWT
│   └── session_service.dart          # Almacenamiento seguro de credenciales
├── providers/                        # Gestores de estado (ChangeNotifier)
│   ├── fauna_flora_provider.dart
│   ├── request_state.dart            # Mixin de ciclo de vida asíncrono
│   └── retos_observer_provider.dart
├── services/                         # Capa de comunicación REST y hardware
│   ├── alerta_service.dart
│   ├── api_client.dart
│   ├── danger_alert_presenter.dart
│   ├── fauna_flora_service.dart
│   ├── location_service.dart
│   ├── notification_service.dart
│   └── socket_service.dart           # Cliente WebSockets
└── main.dart                         # Punto de arranque e inyección de Providers
```

---

## ⚙️ Configuración de Red y Seguridad

El archivo [`lib/config/api_config.dart`](file:///c:/Desarrollo%20Movil%20Integral/TerraScope/TerraScope_App/terrascope/lib/config/api_config.dart) centraliza el punto de enlace con el Backend:

```dart
class ApiConfig {
  // Para emulador Android: 10.0.2.2:3000
  // Para dispositivo físico: IP local de la máquina en red WiFi (ej. 192.168.1.X:3000)
  // Para producción: Dominio HTTPS oficial
  static const String baseUrl = 'http://10.0.2.2:3000';
  static const String socketUrl = 'http://10.0.2.2:3000';
}
```

---

## 🔒 Permisos del Dispositivo (Android / iOS)

Para que todas las funciones de hardware operen adecuadamente, la app requiere:

### Android (`android/app/src/main/AndroidManifest.xml`)
* `android.permission.INTERNET`: Acceso a servicios web y WebSockets.
* `android.permission.ACCESS_FINE_LOCATION` y `ACCESS_COARSE_LOCATION`: Geolocalización de alta precisión para avistamientos y SOS.
* `android.permission.CAMERA`: Captura de especímenes biológicos en vivo.
* `android.permission.POST_NOTIFICATIONS`: Despliegue de alertas de fauna peligrosa.
* `android.permission.CALL_PHONE`: Marcación automática al 911 en protocolo SOS.

### iOS (`ios/Runner/Info.plist`)
* `NSLocationWhenInUseUsageDescription`: Georreferenciación de registros.
* `NSCameraUsageDescription`: Acceso a cámara para fotografía botánica y zoológica.
* `NSPhotoLibraryUsageDescription`: Selección de imágenes existentes.

---

## 🚀 Guía de Instalación y Ejecución

### Requisitos Previos
* **Flutter SDK**: Versión 3.24 o superior (`flutter --version`).
* **Java SDK**: JDK 17 o 21 (para compilación Gradle en Android).
* **Android Studio** o **VS Code** con extensiones de Flutter y Dart.

### Pasos de Instalación

1. Navegar al directorio del frontend:
   ```bash
   cd TerraScope_App/terrascope
   ```

2. Descargar paquetes y dependencias de `pubspec.yaml`:
   ```bash
   flutter pub get
   ```

3. Verificar que los dispositivos conectados o emuladores estén listos:
   ```bash
   flutter devices
   ```

4. Ejecutar la aplicación en modo Debug:
   ```bash
   flutter run
   ```

5. Compilar APK para distribución en Android:
   ```bash
   flutter build apk --release
   ```

---

## 🧪 Pruebas y Análisis de Calidad

Para garantizar que el código respete los estándares de ingeniería y no contenga advertencias ni errores de tipado estático:

```bash
# Análisis estático de código Dart
dart analyze

# Ejecución de pruebas unitarias y de widgets
flutter test
```

---

## 👥 Contribuciones y Autoría

* **Equipo TerraScope** — Desarrollo Móvil Integral.
* Desarrollado con Flutter y Material Design 3.

