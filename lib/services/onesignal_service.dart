import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'secure_storage_service.dart';

/// Servicio centralizado para OneSignal
/// 
/// Rol en Life Alert:
/// - ✅ Recibe y gestiona notificaciones push desde servidor
/// - ✅ Registra dispositivo con player_id único
/// - ✅ Vincula CI del usuario con player_id para targeting
/// - ✅ Configura listeners para notificaciones (foreground, click)
/// 
/// Limitaciones (por diseño de OneSignal):
/// - ❌ NO programa notificaciones (se hace desde servidor/backend)
/// - ❌ NO envía notificaciones directas desde cliente
/// 
/// Arquitectura de Notificaciones en Life Alert:
/// 1. LOCAL (flutter_local_notifications) → Funciona sin internet, siempre confiable
/// 2. PUSH (OneSignal)                   → Funciona con internet, UX mejorada
/// 
/// Para recordatorios de citas:
/// - Se programa con flutter_local_notifications (siempre funciona)
/// - Se intenta con OneSignal si está disponible (mejor UX)
class OneSignalService {
  static final OneSignalService _instance = OneSignalService._internal();

  static OneSignalService get instance => _instance;

  bool _isInitialized = false;
  String? _currentPlayerId;

  // IMPORTANTE: Reemplazar con tu App ID de OneSignal
  static const String oneSignalAppId = 'ea14f407-6f2d-4be0-b326-a93c029c8add';

  OneSignalService._internal();

  /// Inicializar OneSignal
  /// Debe llamarse en main() después de WidgetsFlutterBinding.ensureInitialized()
  Future<void> initialize() async {
    if (_isInitialized) {
      print('[OneSignalService.initialize] Ya inicializado');
      return;
    }

    try {
      print('[OneSignalService.initialize] ========================================');
      print('[OneSignalService.initialize] INICIALIZANDO ONESIGNAL');
      print('[OneSignalService.initialize] ========================================');

      // Inicializar OneSignal
      await OneSignal.initialize(oneSignalAppId);

      // Solicitar permiso de notificaciones (iOS 13+)
      await OneSignal.Notifications.requestPermission(true);

      // Obtener player_id del dispositivo
      _currentPlayerId = OneSignal.User.pushSubscription.id;
      print('[OneSignalService.initialize] Player ID: $_currentPlayerId');

      // Vincular usuario actual con OneSignal
      await _setupUserVinculo();

      // Configurar listeners
      _setupListeners();

      _isInitialized = true;
      print('[OneSignalService.initialize] ========================================');
      print('[OneSignalService.initialize] ✓ ONESIGNAL INICIALIZADO EXITOSAMENTE');
      print('[OneSignalService.initialize] ========================================');
    } catch (e, stackTrace) {
      print('[OneSignalService.initialize] ========================================');
      print('[OneSignalService.initialize] ✗ ERROR AL INICIALIZAR ONESIGNAL');
      print('[OneSignalService.initialize] Error: $e');
      print('[OneSignalService.initialize] StackTrace: $stackTrace');
      print('[OneSignalService.initialize] ========================================');
      // No relanzar excepción, permitir que la app continúe sin OneSignal
    }
  }

  /// Vincular usuario actual con OneSignal (crear relación CI <-> player_id)
  Future<void> _setupUserVinculo() async {
    try {
      // Obtener CI del usuario desde secure storage
      final userCI = await SecureStorageService.getCI();

      if (userCI != null && userCI.isNotEmpty) {
        // Guardar relación en SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('onesignal_player_id', _currentPlayerId ?? '');
        await prefs.setString('onesignal_user_ci', userCI);

        print('[OneSignalService._setupUserVinculo] Vínculo creado: $userCI -> $_currentPlayerId');
      } else {
        print('[OneSignalService._setupUserVinculo] No hay CI configurado, usando player_id genérico');
      }
    } catch (e) {
      print('[OneSignalService._setupUserVinculo] Error vinculando usuario: $e');
    }
  }

  /// Configurar listeners para eventos de OneSignal
  void _setupListeners() {
    // Escuchar notificaciones recibidas cuando app está en foreground
    OneSignal.Notifications.addForegroundWillDisplayListener((notification) {
      print('[OneSignal.onNotificationWillDisplay] Notificación en foreground: ${notification.notification.title}');
    });

    // Escuchar click en notificaciones
    OneSignal.Notifications.addClickListener((event) {
      print('[OneSignal.onNotificationOpened] Notificación abierta: ${event.notification.title}');
    });
  }

  /// Programar una notificación push para un tiempo específico
  /// NOTA: Las notificaciones programadas se manejan con flutter_local_notifications
  /// OneSignal solo envía notificaciones inmediatas (real-time push)
  /// Este método es un placeholder que retorna true para mantener compatibilidad
  /// 
  /// [title] - Título de la notificación
  /// [body] - Cuerpo del mensaje
  /// [scheduledTime] - Hora en que se debe enviar la notificación
  /// [data] - Datos adicionales (Map<String, dynamic>)
  Future<bool> scheduleNotification({
    required String title,
    required String body,
    required DateTime scheduledTime,
    Map<String, dynamic>? data,
  }) async {
    try {
      print('[OneSignalService.scheduleNotification] ========================================');
      print('[OneSignalService.scheduleNotification] Notificación programada: $title');
      print('[OneSignalService.scheduleNotification] Hora: $scheduledTime');
      print('[OneSignalService.scheduleNotification] Nota: flutter_local_notifications maneja la programación');
      print('[OneSignalService.scheduleNotification] OneSignal solo envía push inmediatos');
      print('[OneSignalService.scheduleNotification] ========================================');
      
      // OneSignal no soporta programación desde cliente
      // Las notificaciones programadas se manejan con flutter_local_notifications
      // Este retorna true para indicar que se procesó correctamente
      return true;
    } catch (e) {
      print('[OneSignalService.scheduleNotification] ✗ Error: $e');
      return false;
    }
  }

  /// Enviar notificación inmediata
  /// En OneSignal, las notificaciones se envían típicamente desde el servidor
  /// Este método es un placeholder que registra la intención
  /// Para uso en producción, usa la API REST de OneSignal desde tu backend
  /// 
  /// [title] - Título de la notificación
  /// [body] - Cuerpo del mensaje
  /// [data] - Datos adicionales (Map<String, dynamic>)
  Future<bool> sendImmediateNotification({
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      if (!_isInitialized) {
        print('[OneSignalService.sendImmediateNotification] OneSignal no inicializado');
        return false;
      }

      print('[OneSignalService.sendImmediateNotification] ========================================');
      print('[OneSignalService.sendImmediateNotification] Enviando notificación inmediata: $title');
      print('[OneSignalService.sendImmediateNotification] Body: $body');
      print('[OneSignalService.sendImmediateNotification] Player ID: $_currentPlayerId');
      print('[OneSignalService.sendImmediateNotification] Data: $data');
      print('[OneSignalService.sendImmediateNotification] ========================================');
      
      // Nota: OneSignal está inicializado y listo para recibir notificaciones push
      // Desde el servidor/backend, usa su API REST para enviar notificaciones
      // Endpoint: https://onesignal.com/api/v1/notifications
      // Con: Authorization: Basic YOUR_REST_API_KEY
      
      return true;
    } catch (e) {
      print('[OneSignalService.sendImmediateNotification] ✗ Error: $e');
      return false;
    }
  }

  /// Obtener player_id actual del dispositivo
  String? getPlayerId() => _currentPlayerId;

  /// Verificar si OneSignal está inicializado
  bool isInitialized() => _isInitialized;
}
