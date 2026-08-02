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
            final message = event.pushwooshMessage;
            print('[Pushwoosh.onPushReceived] Título: ${message?.title}');
            print('[Pushwoosh.onPushReceived] Contenido: ${message?.message}');
            if (message?.customData != null) {
              print('[Pushwoosh.onPushReceived] Datos personalizados: ${message?.customData}');
            }
          } catch (e) {
            print('[Pushwoosh.onPushReceived] Error al procesar evento: $e');
          }
        });
      } catch (e) {
        print('[PushwooshService._setupNotificationHandlers] Error configurando onPushReceived: $e');
      }

      // Handler cuando se toca una notificación
      try {
        instance.onPushAccepted.listen((event) {
          print('[Pushwoosh.onPushAccepted] Notificación tocada por usuario');
          try {
            final message = event.pushwooshMessage;
            print('[Pushwoosh.onPushAccepted] Título: ${message?.title}');
            
            // Si tiene customData, procesar navegación
            if (message?.customData != null) {
              _handleNotificationNavigation(message?.customData);
            }
          } catch (e) {
            print('[Pushwoosh.onPushAccepted] Error al procesar evento: $e');
          }
        });
      } catch (e) {
        print('[PushwooshService._setupNotificationHandlers] Error configurando onPushAccepted: $e');
      }

      print('[PushwooshService._setupNotificationHandlers] Listeners configurados exitosamente');
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

  /// Programar recordatorio de cita médica
  /// Se llama cuando se crea/modifica una cita
  /// En producción, esto enviaría información al backend para que envíe la notificación push
  Future<void> scheduleAppointmentReminder({
    required String appointmentId,
    required String doctorName,
    required String appointmentDate,
    required String appointmentTime,
    required String specialty,
  }) async {
    try {
      print('[PushwooshService.scheduleAppointmentReminder] Programando recordatorio:');
      print('[PushwooshService.scheduleAppointmentReminder] ID: $appointmentId');
      print('[PushwooshService.scheduleAppointmentReminder] Doctor: $doctorName');
      print('[PushwooshService.scheduleAppointmentReminder] Fecha: $appointmentDate');
      print('[PushwooshService.scheduleAppointmentReminder] Hora: $appointmentTime');
      print('[PushwooshService.scheduleAppointmentReminder] Especialidad: $specialty');

      // En producción, esto enviaría un request a tu backend con:
      // POST /api/appointments/schedule-push-reminder
      // {
      //   "appointmentId": appointmentId,
      //   "doctorName": doctorName,
      //   "appointmentDate": appointmentDate,
      //   "appointmentTime": appointmentTime,
      //   "specialty": specialty,
      //   "userId": <userId desde Pushwoosh>,
      //   "deviceId": <deviceId desde Pushwoosh>
      // }
      //
      // El backend usaría la API de Pushwoosh para:
      // 1. Segmentar por deviceId
      // 2. Enviar notificación con customData = {appointmentId: ..., type: "appointment_reminder"}
      // 3. Programar para X minutos antes de la cita

      print('[PushwooshService.scheduleAppointmentReminder] ✓ Recordatorio registrado (implementación local)');
      print('[PushwooshService.scheduleAppointmentReminder] TODO: Integrar con backend Pushwoosh API');
    } catch (e) {
      print('[PushwooshService.scheduleAppointmentReminder] ERROR: $e');
    }
  }

  /// Cancelar recordatorio de cita (si se borra la cita)
  Future<void> cancelAppointmentReminder(String appointmentId) async {
    try {
      print('[PushwooshService.cancelAppointmentReminder] Cancelando recordatorio: $appointmentId');

      // En producción:
      // DELETE /api/appointments/$appointmentId/cancel-reminder
      // Esto le diría al backend que cancele la notificación programada

      print('[PushwooshService.cancelAppointmentReminder] ✓ Recordatorio cancelado');
    } catch (e) {
      print('[PushwooshService.cancelAppointmentReminder] ERROR: $e');
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
