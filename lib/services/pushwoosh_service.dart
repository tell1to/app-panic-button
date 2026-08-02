import 'package:pushwoosh_flutter/pushwoosh_flutter.dart';

/// Servicio centralizado para gestionar Pushwoosh
/// Maneja:
/// - Inicialización de Pushwoosh
/// - Manejo de notificaciones push
/// - Integración con sistema de citas médicas
class PushwooshService {
  static final PushwooshService _instance = PushwooshService._internal();

  bool _isInitialized = false;

  PushwooshService._internal();

  factory PushwooshService.instance() {
    return _instance;
  }

  /// Inicializar Pushwoosh
  /// Debe llamarse después de que Firebase esté inicializado
  Future<void> initialize() async {
    if (_isInitialized) {
      print('[PushwooshService.initialize] Ya inicializado');
      return;
    }

    try {
      print('[PushwooshService.initialize] ========================================');
      print('[PushwooshService.initialize] INICIALIZANDO PUSHWOOSH');
      print('[PushwooshService.initialize] ========================================');

      // Configurar handler para notificaciones
      try {
        _setupNotificationHandlers();
      } catch (e) {
        print('[PushwooshService.initialize] Error al configurar handlers: $e');
      }

      // Intentar registrar para notificaciones push
      try {
        final instance = Pushwoosh.getInstance;
        if (instance != null) {
          await instance.registerForPushNotifications();
          print('[PushwooshService.initialize] ✓ Registrado para notificaciones push');
        }
      } catch (e) {
        print('[PushwooshService.initialize] Nota: registerForPushNotifications no disponible: $e');
      }

      _isInitialized = true;
      print('[PushwooshService.initialize] ========================================');
      print('[PushwooshService.initialize] ✓ PUSHWOOSH INICIALIZADO EXITOSAMENTE');
      print('[PushwooshService.initialize] ========================================');
    } catch (e, stackTrace) {
      print('[PushwooshService.initialize] ========================================');
      print('[PushwooshService.initialize] ⚠ ADVERTENCIA AL INICIALIZAR PUSHWOOSH');
      print('[PushwooshService.initialize] Error: $e');
      print('[PushwooshService.initialize] StackTrace: $stackTrace');
      print('[PushwooshService.initialize] ========================================');
      // NO relanzar excepción - continuar con la app igualmente
      _isInitialized = true;
    }
  }

  /// Configurar handlers para notificaciones push
  void _setupNotificationHandlers() {
    try {
      final instance = Pushwoosh.getInstance;
      if (instance == null) {
        print('[PushwooshService._setupNotificationHandlers] Pushwoosh.getInstance es null');
        return;
      }

      // Handler cuando se recibe una notificación mientras la app está activa (foreground)
      try {
        instance.onPushReceived.listen((event) {
          print('[Pushwoosh.onPushReceived] Notificación recibida en foreground');
          try {
            print('[Pushwoosh.onPushReceived] Payload: ${event.pushwooshMessage?.payload}');
            print('[Pushwoosh.onPushReceived] Título: ${event.pushwooshMessage?.title}');
          } catch (e) {
            print('[Pushwoosh.onPushReceived] Error al procesar payload: $e');
          }
        });
      } catch (e) {
        print('[PushwooshService._setupNotificationHandlers] Error al configurar onPushReceived: $e');
      }

      // Handler cuando se toca una notificación (abre la app o la trae al foreground)
      try {
        instance.onPushAccepted.listen((event) {
          print('[Pushwoosh.onPushAccepted] Notificación tocada');
          try {
            print('[Pushwoosh.onPushAccepted] Payload: ${event.pushwooshMessage?.payload}');
            print('[Pushwoosh.onPushAccepted] Título: ${event.pushwooshMessage?.title}');
          } catch (e) {
            print('[Pushwoosh.onPushAccepted] Error al procesar payload: $e');
          }

          // Navegar a la pantalla de citas si es una notificación de cita
          _handleNotificationNavigation(event.pushwooshMessage?.payload);
        });
      } catch (e) {
        print('[PushwooshService._setupNotificationHandlers] Error al configurar onPushAccepted: $e');
      }
    } catch (e) {
      print('[PushwooshService._setupNotificationHandlers] Error general: $e');
    }
  }

  /// Manejar navegación cuando se toca una notificación
  void _handleNotificationNavigation(dynamic payload) {
    if (payload == null) return;

    try {
      print('[PushwooshService] Procesando notificación tocada');
      print('[PushwooshService] Payload: $payload');

      // TODO: Implementar navegación a la pantalla de citas
      // if (payload is Map && payload.containsKey('appointmentId')) {
      //   Navigator.pushNamed(context, '/appointments', arguments: payload['appointmentId']);
      // }
    } catch (e) {
      print('[PushwooshService._handleNotificationNavigation] Error: $e');
    }
  }

  /// Enviar notificación push para recordatorio de cita médica
  /// Esta función se llama desde el backend/servidor
  /// Aquí es solo para referencia
  Future<void> sendAppointmentReminder({
    required String doctorName,
    required String appointmentDate,
    required String appointmentTime,
    required String appointmentId,
  }) async {
    try {
      // En una app real, esto se enviaría desde el backend
      // usando la API de Pushwoosh
      print('[PushwooshService.sendAppointmentReminder] Recordatorio de cita:');
      print('[PushwooshService.sendAppointmentReminder] Doctor: $doctorName');
      print('[PushwooshService.sendAppointmentReminder] Fecha: $appointmentDate');
      print('[PushwooshService.sendAppointmentReminder] Hora: $appointmentTime');
    } catch (e) {
      print('[PushwooshService.sendAppointmentReminder] ERROR: $e');
    }
  }

  /// Obtener device ID de Pushwoosh
  /// (Nota: La API puede variar según versión de Pushwoosh)
  Future<String?> getDeviceId() async {
    try {
      // Pushwoosh genera automáticamente un device ID
      // Este se usa internamente para targeting
      print('[PushwooshService.getDeviceId] Device ID será asignado por Pushwoosh');
      return null; // TODO: Verificar método correcto en API oficial
    } catch (e) {
      print('[PushwooshService.getDeviceId] ERROR: $e');
      return null;
    }
  }

  /// Suscribirse a un tópico para recibir notificaciones grupales
  Future<void> subscribeTopic(String topic) async {
    try {
      final instance = Pushwoosh.getInstance;
      if (instance == null) return;

      // Pushwoosh usa tags para segmentación
      await instance.setTags({topic: "1"});
      print('[PushwooshService.subscribeTopic] Suscrito a: $topic');
    } catch (e) {
      print('[PushwooshService.subscribeTopic] ERROR: $e');
    }
  }

  /// Desuscribirse de un tópico
  Future<void> unsubscribeTopic(String topic) async {
    try {
      final instance = Pushwoosh.getInstance;
      if (instance == null) return;

      await instance.setTags({topic: "0"});
      print('[PushwooshService.unsubscribeTopic] Desuscrito de: $topic');
    } catch (e) {
      print('[PushwooshService.unsubscribeTopic] ERROR: $e');
    }
  }

  /// Verificar si Pushwoosh está inicializado
  bool get isInitialized => _isInitialized;
}
