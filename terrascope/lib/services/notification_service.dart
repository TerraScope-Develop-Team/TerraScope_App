import 'dart:async';
import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../config/auth_http.dart' as http;
import 'session_service.dart';

enum NotificationType { info, success, warning, error }

class AppNotification {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final Duration duration;
  final VoidCallback? onTap;

  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    this.type = NotificationType.info,
    this.duration = const Duration(seconds: 4),
    this.onTap,
  });
}

class NotificationService with ChangeNotifier {
  static const _permissionPromptKey =
      'push_permission_prompted_after_challenge';
  static const _foregroundChannelId = 'terrascope_foreground_alerts_v1';

  final List<AppNotification> _notifications = [];
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final SessionService _sessionService = SessionService();
  StreamSubscription<RemoteMessage>? _foregroundSubscription;
  StreamSubscription<RemoteMessage>? _openedSubscription;
  StreamSubscription<String>? _tokenSubscription;
  Future<void> Function(Map<String, dynamic>)? _onNotificationTap;
  bool _initialized = false;
  bool _localNotificationsReady = false;
  bool _permissionPromptInProgress = false;

  List<AppNotification> get notifications => List.unmodifiable(_notifications);

  Future<void> initialize({
    required Future<void> Function(Map<String, dynamic>) onNotificationTap,
  }) async {
    if (_initialized) return;
    if (Firebase.apps.isEmpty) {
      debugPrint(
        'FCM no está disponible: falta configurar Firebase para esta app.',
      );
      return;
    }

    _initialized = true;
    _onNotificationTap = onNotificationTap;
    try {
      final messaging = FirebaseMessaging.instance;

      if (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS) {
        await messaging.setForegroundNotificationPresentationOptions(
          alert: false,
          badge: false,
          sound: false,
        );
      }

      await _initializeLocalNotifications();
      _foregroundSubscription = FirebaseMessaging.onMessage.listen(
        (message) => unawaited(_showRemoteNotification(message)),
        onError: (Object error) {
          debugPrint(
            'Error recibiendo notificaciones FCM en primer plano: $error',
          );
        },
      );
      _openedSubscription = FirebaseMessaging.onMessageOpenedApp.listen(
        (message) => _openRemoteNotification(message.data),
        onError: (Object error) {
          debugPrint('Error abriendo una notificación FCM: $error');
        },
      );
      _tokenSubscription = messaging.onTokenRefresh.listen(
        _registerRefreshedToken,
        onError: (Object error) {
          debugPrint('Error actualizando el token FCM: $error');
        },
      );

      final initialMessage = await messaging.getInitialMessage();
      if (initialMessage != null) {
        await _openRemoteNotification(initialMessage.data);
      } else {
        final localLaunchDetails = await _localNotifications
            .getNotificationAppLaunchDetails();
        final localResponse = localLaunchDetails?.notificationResponse;
        if (localLaunchDetails?.didNotificationLaunchApp == true &&
            localResponse != null) {
          _handleLocalNotificationTap(localResponse);
        }
      }

      final settings = await messaging.getNotificationSettings();
      if (_isPermissionGranted(settings.authorizationStatus)) {
        final token = await messaging.getToken();
        if (token != null) await _registerDeviceToken(token);
      }
    } catch (error, stackTrace) {
      _initialized = false;
      debugPrint(
        'No se pudo inicializar la recepción de notificaciones FCM: $error',
      );
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> requestPermissionAfterFirstChallengeAcceptance(
    BuildContext context,
  ) async {
    if (_permissionPromptInProgress) return;
    _permissionPromptInProgress = true;

    try {
      final preferences = await SharedPreferences.getInstance();
      if (preferences.getBool(_permissionPromptKey) ?? false) return;

      if (!_initialized || Firebase.apps.isEmpty) {
        showNotification(
          AppNotification(
            id: 'push_firebase_not_configured',
            title: 'Notificaciones no disponibles',
            message: 'Firebase aún no está configurado para esta aplicación.',
            type: NotificationType.warning,
          ),
        );
        return;
      }

      final messaging = FirebaseMessaging.instance;
      final currentSettings = await messaging.getNotificationSettings();
      if (_isPermissionGranted(currentSettings.authorizationStatus)) {
        await preferences.setBool(_permissionPromptKey, true);
        final token = await messaging.getToken();
        if (token == null || !await _registerDeviceToken(token)) {
          showNotification(
            AppNotification(
              id: 'push_registration_failed',
              title: 'No se pudieron activar',
              message: 'Inténtalo de nuevo más tarde.',
              type: NotificationType.error,
            ),
          );
        }
        return;
      }

      if (!context.mounted) return;

      final wantsNotifications = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Recibe avisos de TerraScope'),
          content: const Text(
            'Podemos avisarte cuando un reto esté por vencer y sobre actividad '
            'en tus avistamientos. ¿Quieres activar las notificaciones?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Ahora no'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Continuar'),
            ),
          ],
        ),
      );

      await preferences.setBool(_permissionPromptKey, true);
      if (wantsNotifications != true || !context.mounted) return;

      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      if (!_isPermissionGranted(settings.authorizationStatus)) {
        showNotification(
          AppNotification(
            id: 'push_permission_denied',
            title: 'Notificaciones desactivadas',
            message:
                'Puedes activarlas después desde los ajustes del dispositivo.',
            type: NotificationType.warning,
          ),
        );
        return;
      }

      final token = await messaging.getToken();
      if (token == null || !await _registerDeviceToken(token)) {
        showNotification(
          AppNotification(
            id: 'push_registration_failed',
            title: 'No se pudieron activar',
            message: 'Inténtalo de nuevo más tarde.',
            type: NotificationType.error,
          ),
        );
      }
    } catch (error, stackTrace) {
      debugPrint('No se pudo solicitar o registrar el permiso FCM: $error');
      debugPrintStack(stackTrace: stackTrace);
      showNotification(
        AppNotification(
          id: 'push_setup_failed',
          title: 'No se pudieron activar',
          message: 'Ocurrió un error al configurar las notificaciones.',
          type: NotificationType.error,
        ),
      );
    } finally {
      _permissionPromptInProgress = false;
    }
  }

  bool _isPermissionGranted(AuthorizationStatus status) =>
      status == AuthorizationStatus.authorized ||
      status == AuthorizationStatus.provisional;

  Future<void> _initializeLocalNotifications() async {
    try {
      await _localNotifications.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('ic_stat_notification'),
          iOS: DarwinInitializationSettings(),
        ),
        onDidReceiveNotificationResponse: _handleLocalNotificationTap,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(
            const AndroidNotificationChannel(
              _foregroundChannelId,
              'Notificaciones de TerraScope',
              description: 'Avisos recibidos mientras la app está abierta.',
              importance: Importance.high,
            ),
          );
      _localNotificationsReady = true;
    } catch (error, stackTrace) {
      debugPrint(
        'No se pudieron activar los avisos nativos en primer plano: $error',
      );
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> _showRemoteNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) {
      debugPrint(
        'FCM en primer plano llegó sin título ni cuerpo de notificación.',
      );
      return;
    }
    final notificationId =
        message.messageId ?? DateTime.now().microsecondsSinceEpoch.toString();

    showNotification(
      AppNotification(
        id: notificationId,
        title: notification.title ?? 'TerraScope',
        message: notification.body ?? '',
        onTap: message.data.isEmpty
            ? null
            : () {
                removeNotificationById(notificationId);
                unawaited(_openRemoteNotification(message.data));
              },
      ),
    );

    if (!_localNotificationsReady) {
      debugPrint('FCM llegó, pero las notificaciones nativas no están listas.');
      return;
    }

    try {
      await _localNotifications.show(
        id: notificationId.hashCode & 0x7fffffff,
        title: notification.title ?? 'TerraScope',
        body: notification.body ?? '',
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            _foregroundChannelId,
            'Notificaciones de TerraScope',
            channelDescription:
                'Avisos recibidos mientras la app está abierta.',
            importance: Importance.high,
            priority: Priority.high,
            icon: 'ic_stat_notification',
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: json.encode(message.data),
      );
    } catch (error, stackTrace) {
      debugPrint('No se pudo mostrar el aviso nativo recibido por FCM: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  void _handleLocalNotificationTap(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null || payload.isEmpty) return;

    try {
      final decoded = json.decode(payload);
      if (decoded is! Map) {
        debugPrint('El destino del aviso nativo no tiene formato válido.');
        return;
      }
      unawaited(_openRemoteNotification(Map<String, dynamic>.from(decoded)));
    } catch (error, stackTrace) {
      debugPrint('No se pudo interpretar el destino del aviso nativo: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> _openRemoteNotification(Map<String, dynamic> data) async {
    final onTap = _onNotificationTap;
    if (onTap == null) return;
    await onTap(data);
  }

  Future<void> _registerRefreshedToken(String token) async {
    final settings = await FirebaseMessaging.instance.getNotificationSettings();
    if (_isPermissionGranted(settings.authorizationStatus)) {
      await _registerDeviceToken(token);
    }
  }

  Future<bool> _registerDeviceToken(String token) async {
    try {
      final userData = await _sessionService.getUserData();
      if (userData == null) {
        debugPrint('No se registra el token FCM: no hay una sesión activa.');
        return false;
      }

      final platform = switch (defaultTargetPlatform) {
        TargetPlatform.android => 'android',
        TargetPlatform.iOS => 'ios',
        TargetPlatform.macOS => 'macos',
        TargetPlatform.windows => 'windows',
        TargetPlatform.linux => 'linux',
        TargetPlatform.fuchsia => 'fuchsia',
      };
      final location = await _getAvailableLocation();
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/notificaciones/dispositivos'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'token': token,
          'plataforma': platform,
          ...location,
        }),
      );

      if (response.statusCode != 200) {
        debugPrint(
          'El backend rechazó el registro del token FCM '
          '(${response.statusCode}): ${response.body}',
        );
        return false;
      }
      return true;
    } catch (error, stackTrace) {
      debugPrint('No se pudo registrar el dispositivo FCM: $error');
      debugPrintStack(stackTrace: stackTrace);
      return false;
    }
  }

  Future<Map<String, double>> _getAvailableLocation() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return {};

      final permission = await Geolocator.checkPermission();
      if (permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always) {
        return {};
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      return {
        'latitud': position.latitude,
        'longitud': position.longitude,
        'precision_ubicacion_m': position.accuracy,
      };
    } catch (error) {
      debugPrint('No se pudo obtener una ubicación para FCM: $error');
      return {};
    }
  }

  void showNotification(AppNotification notification) {
    _notifications.add(notification);
    notifyListeners();

    // Auto remove notification after its duration
    Timer(notification.duration, () {
      removeNotificationById(notification.id);
    });
  }

  void removeNotificationById(String id) {
    _notifications.removeWhere((n) => n.id == id);
    notifyListeners();
  }

  void clearAll() {
    _notifications.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _foregroundSubscription?.cancel();
    _openedSubscription?.cancel();
    _tokenSubscription?.cancel();
    super.dispose();
  }
}
