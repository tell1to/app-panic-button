import 'dart:async';
import 'notification_service.dart';

/// Servicio para enviar notificaciones de prueba a intervalos específicos
/// Útil para testing manual y desarrollo
class NotificationTestService {
  static final NotificationTestService _instance =
      NotificationTestService._internal();

  late NotificationService _notificationService;
  Timer? _testTimer;
  int _testNotificationCount = 0;

  NotificationTestService._internal();

  factory NotificationTestService.instance() {
    return _instance;
  }

  /// Inicializar el servicio
  Future<void> initialize() async {
    _notificationService = NotificationService.instance();
    print('[NotificationTestService] Inicializado');
  }

  /// Iniciar envío de notificaciones de prueba a intervalos específicos
  /// Intervalos: 30s, 1m, 2m
  Future<void> startTestNotifications() async {
    print('[NotificationTestService] Iniciando test de notificaciones...');
    _testNotificationCount = 0;

    // Primera notificación: 30 segundos
    _scheduleNotification(
      delay: const Duration(seconds: 30),
      title: '🔔 Notificación #1',
      body: 'Primera notificación enviada después de 30 segundos',
      index: 1,
    );

    // Segunda notificación: 1 minuto
    _scheduleNotification(
      delay: const Duration(minutes: 1),
      title: '🔔 Notificación #2',
      body: 'Segunda notificación enviada después de 1 minuto',
      index: 2,
    );

    // Tercera notificación: 2 minutos
    _scheduleNotification(
      delay: const Duration(minutes: 2),
      title: '🔔 Notificación #3',
      body: 'Tercera notificación enviada después de 2 minutos',
      index: 3,
    );

    print('[NotificationTestService] Test programado. Total de notificaciones: 3');
  }

  /// Programar una notificación individual
  void _scheduleNotification({
    required Duration delay,
    required String title,
    required String body,
    required int index,
  }) {
    Timer(delay, () {
      _testNotificationCount++;
      print(
        '[NotificationTestService] Enviando notificación #$index '
        'después de ${_formatDuration(delay)}',
      );

      _showTestNotification(
        title: title,
        body: body,
        index: index,
      );
    });
  }

  /// Mostrar notificación de prueba
  void _showTestNotification({
    required String title,
    required String body,
    required int index,
  }) {
    // Aquí se enviaría la notificación FCM real
    // Por ahora, solo registramos en logs
    print(
      '[NotificationTestService] 📤 Notificación #$index enviada\n'
      '  Título: $title\n'
      '  Contenido: $body\n'
      '  Timestamp: ${DateTime.now()}',
    );

    // Si quieres enviar una notificación real a través de FCM:
    // Necesitarías un backend que llame a la Firebase Cloud Messaging API
    // O usar el método sendTestNotification del NotificationService
  }

  /// Detener todas las notificaciones de prueba
  void stopTestNotifications() {
    _testTimer?.cancel();
    print('[NotificationTestService] Test detenido');
  }

  /// Obtener información del estado actual del test
  TestNotificationInfo getInfo() {
    return TestNotificationInfo(
      totalSent: _testNotificationCount,
      isRunning: _testTimer?.isActive ?? false,
    );
  }

  /// Formatear duración
  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;

    if (minutes == 0) {
      return '${seconds}s';
    } else if (seconds == 0) {
      return '${minutes}m';
    } else {
      return '${minutes}m ${seconds}s';
    }
  }
}

/// Información del estado de test
class TestNotificationInfo {
  final int totalSent;
  final bool isRunning;

  TestNotificationInfo({
    required this.totalSent,
    required this.isRunning,
  });

  String getStatus() {
    if (isRunning) {
      return 'Notificaciones en progreso ($totalSent enviadas)';
    } else {
      return 'Test finalizado ($totalSent notificaciones enviadas)';
    }
  }
}
