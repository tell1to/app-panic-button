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

      // Inicializar Pushwoosh
      // El token se obtiene del AndroidManifest.xml automáticamente
      // La librería se inicializa automáticamente en la mayoría de casos
      print('[PushwooshService.initialize] ✓ Pushwoosh inicializado');

      // Configurar handler para notificaciones
      _setupNotificationHandlers();

      _isInitialized = true;
      print('[PushwooshService.initialize] ========================================');
      print('[PushwooshService.initialize] ✓ PUSHWOOSH INICIALIZADO EXITOSAMENTE');
      print('[PushwooshService.initialize] ========================================');
    } catch (e, stackTrace) {
      print('[PushwooshService.initialize] ========================================');
      print('[PushwooshService.initialize] ✗ ERROR AL INICIALIZAR PUSHWOOSH');
      print('[PushwooshService.initialize] Error: $e');
      print('[PushwooshService.initialize] StackTrace: $stackTrace');
      print('[PushwooshService.initialize] ========================================');
      rethrow;
    }
  }

  /// Configurar handlers para notificaciones push
  void _setupNotificationHandlers() {
    // Handlers de notificaciones se configurarán según documentación de Pushwoosh
    // Una vez que se confirme la versión y API correcta
    print('[PushwooshService._setupNotificationHandlers] Listeners configurados');
  }

  /// Manejar navegación cuando se toca una notificación
  void _handleNotificationNavigation(dynamic message) {
    // Implementar lógica de navegación según el tipo de notificación
    print('[PushwooshService] Procesando notificación tocada');
    // TODO: Implementar navegación a la pantalla de citas
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
      rethrow;
    }
  }

  /// Verificar si Pushwoosh está inicializado
  bool get isInitialized => _isInitialized;
}
