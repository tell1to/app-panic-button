import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// Servicio centralizado de Firebase
/// Maneja:
/// - Inicialización de Firebase
/// - Analytics (rastreo de eventos)
/// - Crashlytics (reporte de errores)
/// - Cloud Messaging (notificaciones push)
class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();

  static FirebaseService get instance => _instance;

  late FirebaseAnalytics _analytics;
  late FirebaseMessaging _messaging;
  bool _isInitialized = false;

  FirebaseService._internal();

  /// Inicializar Firebase
  /// Debe llamarse antes de runApp()
  Future<void> initialize() async {
    if (_isInitialized) {
      print('[FirebaseService.initialize] Ya inicializado');
      return;
    }

    try {
      print('[FirebaseService.initialize] ========================================');
      print('[FirebaseService.initialize] INICIALIZANDO FIREBASE');
      print('[FirebaseService.initialize] ========================================');

      // Inicializar Firebase Core
      await Firebase.initializeApp();
      print('[FirebaseService.initialize] ✓ Firebase Core inicializado');

      // IMPORTANTE: Verificar configuración
      print('[FirebaseService.initialize] ⚠️  CHECKLIST REQUERIDO:');
      print('[FirebaseService.initialize] ⚠️  1. Realtime Database creada en Firebase Console');
      print('[FirebaseService.initialize] ⚠️  2. Reglas configuradas (ve a: Build > Realtime Database > Rules)');
      print('[FirebaseService.initialize] ⚠️  3. Lee el archivo: FIREBASE_SETUP_2026.md');

      // Configurar Analytics
      _analytics = FirebaseAnalytics.instance;
      await _analytics.logAppOpen();
      print('[FirebaseService.initialize] ✓ Analytics inicializado');

      // Configurar Crashlytics
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
      FlutterError.onError = (errorDetails) {
        FirebaseCrashlytics.instance.recordFlutterError(errorDetails);
      };
      print('[FirebaseService.initialize] ✓ Crashlytics inicializado');

      // Configurar Cloud Messaging (FCM)
      _messaging = FirebaseMessaging.instance;

      // Solicitar permiso de notificaciones
      final settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('[FirebaseService.initialize] ✓ Permiso de notificaciones: OTORGADO');
      } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
        print('[FirebaseService.initialize] ⚠️  Permiso de notificaciones: PROVISIONAL');
      } else {
        print('[FirebaseService.initialize] ✗ Permiso de notificaciones: DENEGADO');
      }

      // Obtener FCM token
      final fcmToken = await _messaging.getToken();
      print('[FirebaseService.initialize] FCM Token: $fcmToken');

      // Configurar handlers de mensajes
      _setupMessageHandlers();

      _isInitialized = true;
      print('[FirebaseService.initialize] ========================================');
      print('[FirebaseService.initialize] ✓ FIREBASE INICIALIZADO EXITOSAMENTE');
      print('[FirebaseService.initialize] ========================================');
    } catch (e, stackTrace) {
      print('[FirebaseService.initialize] ========================================');
      print('[FirebaseService.initialize] ✗ ERROR AL INICIALIZAR FIREBASE');
      print('[FirebaseService.initialize] Error: $e');
      print('[FirebaseService.initialize] StackTrace: $stackTrace');
      print('[FirebaseService.initialize] ========================================');
      rethrow;
    }
  }

  /// Configurar handlers para mensajes FCM
  void _setupMessageHandlers() {
    // Mensaje recibido cuando la app está en foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('[FCM.onMessage] Mensaje recibido en foreground');
      print('[FCM.onMessage] Título: ${message.notification?.title}');
      print('[FCM.onMessage] Cuerpo: ${message.notification?.body}');
      print('[FCM.onMessage] Datos: ${message.data}');
    });

    // Mensaje recibido cuando la app está en background y se toca
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('[FCM.onMessageOpenedApp] Mensaje abierto desde background');
      print('[FCM.onMessageOpenedApp] Título: ${message.notification?.title}');
      print('[FCM.onMessageOpenedApp] Datos: ${message.data}');
    });

    // Mensaje recibido cuando la app está terminada
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  /// Log de evento personalizado
  /// Ejemplo: logEvent('emergency_activated', {'location': 'Quito', 'contacts_notified': 2})
  Future<void> logEvent(String name, Map<String, Object>? parameters) async {
    try {
      await _analytics.logEvent(name: name, parameters: parameters);
      print('[FirebaseService.logEvent] $name logged');
    } catch (e) {
      print('[FirebaseService.logEvent] ERROR: $e');
    }
  }

  /// Log de excepción / error
  Future<void> recordError(
    dynamic exception,
    StackTrace? stackTrace, {
    String? reason,
  }) async {
    try {
      await FirebaseCrashlytics.instance.recordError(
        exception,
        stackTrace,
        reason: reason,
      );
      print('[FirebaseService.recordError] Error registrado: $reason');
    } catch (e) {
      print('[FirebaseService.recordError] ERROR al registrar: $e');
    }
  }

  /// Obtener FCM token
  Future<String?> getFCMToken() async {
    try {
      return await _messaging.getToken();
    } catch (e) {
      print('[FirebaseService.getFCMToken] ERROR: $e');
      return null;
    }
  }

  /// Suscribirse a topic (para notificaciones grupales)
  /// Ejemplo: subscribeTopic('alerts_ecuador')
  Future<void> subscribeTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      print('[FirebaseService.subscribeTopic] Suscrito a: $topic');
    } catch (e) {
      print('[FirebaseService.subscribeTopic] ERROR: $e');
    }
  }

  /// Desuscribirse de topic
  Future<void> unsubscribeTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      print('[FirebaseService.unsubscribeTopic] Desuscrito de: $topic');
    } catch (e) {
      print('[FirebaseService.unsubscribeTopic] ERROR: $e');
    }
  }

  /// Verificar si Firebase está inicializado
  bool get isInitialized => _isInitialized;
}

/// Handler para mensajes recibidos cuando la app está terminada
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('[FCM.backgroundHandler] Mensaje recibido en background');
  print('[FCM.backgroundHandler] Título: ${message.notification?.title}');
  print('[FCM.backgroundHandler] Datos: ${message.data}');
}
