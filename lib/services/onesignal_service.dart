import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'secure_storage_service.dart';

/// Servicio centralizado para OneSignal
/// Maneja:
/// - Inicialización de OneSignal
/// - Gestión de suscriptores (vincular usuario con player_id)
/// - Programación de notificaciones push
class OneSignalService {
  static final OneSignalService _instance = OneSignalService._internal();

  static OneSignalService get instance => _instance;

  bool _isInitialized = false;
  String? _currentPlayerId;

  // IMPORTANTE: Reemplazar con tu App ID de OneSignal
  static const String oneSignalAppId = 'YOUR_ONESIGNAL_APP_ID';

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
      _currentPlayerId = await OneSignal.User.getOnesignalId();
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
    OneSignal.Notifications.addClickListener((notification) {
      print('[OneSignal.onNotificationOpened] Notificación abierta: ${notification.notification.title}');
    });
  }

  /// Programar una notificación push para un tiempo específico
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
      if (!_isInitialized) {
        print('[OneSignalService.scheduleNotification] OneSignal no inicializado');
        return false;
      }

      print('[OneSignalService.scheduleNotification] Programando notificación: $title');
      print('[OneSignalService.scheduleNotification] Hora: $scheduledTime');

      // Formatear hora para OneSignal (ISO 8601)
      final String sendAfter = scheduledTime.toUtc().toIso8601String();

      // Crear modelo de notificación
      final notificationModel = {
        'contents': {'en': body},
        'headings': {'en': title},
        'send_after': sendAfter,
        'include_player_ids': [_currentPlayerId],
        if (data != null) 'data': data,
      };

      print('[OneSignalService.scheduleNotification] Modelo: $notificationModel');

      // Programar con OneSignal
      await OneSignal.Notifications.sendNotification(notificationModel);

      print('[OneSignalService.scheduleNotification] ✓ Notificación programada exitosamente');
      return true;
    } catch (e) {
      print('[OneSignalService.scheduleNotification] ✗ Error programando notificación: $e');
      return false;
    }
  }

  /// Enviar notificación inmediata
  /// Útil para alertas urgentes
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

      print('[OneSignalService.sendImmediateNotification] Enviando notificación inmediata: $title');

      final notificationModel = {
        'contents': {'en': body},
        'headings': {'en': title},
        'include_player_ids': [_currentPlayerId],
        if (data != null) 'data': data,
      };

      await OneSignal.Notifications.sendNotification(notificationModel);

      print('[OneSignalService.sendImmediateNotification] ✓ Notificación enviada exitosamente');
      return true;
    } catch (e) {
      print('[OneSignalService.sendImmediateNotification] ✗ Error enviando notificación: $e');
      return false;
    }
  }

  /// Obtener player_id actual del dispositivo
  String? getPlayerId() => _currentPlayerId;

  /// Verificar si OneSignal está inicializado
  bool isInitialized() => _isInitialized;
}
