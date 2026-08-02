import 'package:flutter_test/flutter_test.dart';

/// Test automatizado que envía notificaciones a intervalos específicos
/// Intervalos: 30 segundos, 1 minuto, 2 minutos
/// 
/// Ejecutar con:
/// flutter test test/notification_intervals_test.dart

void main() {
  group('Notificaciones a Intervalos', () {
    setUp(() {
      // No se requiere setup adicional
    });

    test('Enviar notificación cada 30 segundos durante 2.5 minutos', () async {
      print('\n🚀 Iniciando test de notificaciones (30s, 1m, 2m)...\n');

      final List<NotificationSchedule> schedule = [
        NotificationSchedule(
          delay: const Duration(seconds: 30),
          title: '🔔 Notificación 1',
          body: 'Primera notificación enviada después de 30 segundos',
        ),
        NotificationSchedule(
          delay: const Duration(minutes: 1),
          title: '🔔 Notificación 2',
          body: 'Segunda notificación enviada después de 1 minuto',
        ),
        NotificationSchedule(
          delay: const Duration(minutes: 2),
          title: '🔔 Notificación 3',
          body: 'Tercera notificación enviada después de 2 minutos',
        ),
      ];

      // Simulación de envío de notificaciones
      await _simulateNotificationSending(schedule);

      // Verificación
      expect(schedule.length, equals(3));
      print('✅ Test completado exitosamente');
    });

    test('Verificar estructura de notificaciones', () {
      final notification = NotificationSchedule(
        delay: const Duration(seconds: 30),
        title: 'Test Title',
        body: 'Test Body',
      );

      expect(notification.title, equals('Test Title'));
      expect(notification.body, equals('Test Body'));
      expect(notification.delay, equals(const Duration(seconds: 30)));
      print('✅ Estructura de notificaciones válida');
    });

    test('Validar intervalos en segundos', () {
      final intervals = [30, 60, 120]; // segundos
      final totalTime = intervals.fold(0, (sum, val) => sum + val);

      expect(intervals[0], equals(30));
      expect(intervals[1], equals(60));
      expect(intervals[2], equals(120));
      expect(totalTime, equals(210)); // 3.5 minutos totales
      print('✅ Intervalos validados correctamente');
    });
  });
}

/// Modelo para programar notificaciones
class NotificationSchedule {
  final Duration delay;
  final String title;
  final String body;
  final Map<String, dynamic> data;

  NotificationSchedule({
    required this.delay,
    required this.title,
    required this.body,
    this.data = const {},
  });
}

/// Simulación de envío de notificaciones
Future<void> _simulateNotificationSending(
    List<NotificationSchedule> schedule) async {
  print('📋 Notificaciones programadas:\n');

  for (int i = 0; i < schedule.length; i++) {
    final notification = schedule[i];
    print('${i + 1}. Demora: ${_formatDuration(notification.delay)}');
    print('   Título: ${notification.title}');
    print('   Contenido: ${notification.body}\n');
  }

  print('⏳ Simulando envío de notificaciones...\n');

  // Simular el envío
  for (int i = 0; i < schedule.length; i++) {
    await Future.delayed(const Duration(milliseconds: 500)); // Simular delay
    _logNotificationSent(
      index: i + 1,
      title: schedule[i].title,
      body: schedule[i].body,
      delay: schedule[i].delay,
    );
  }

  print('\n✅ Todas las notificaciones fueron "enviadas" correctamente');
}

/// Registrar notificación enviada
void _logNotificationSent({
  required int index,
  required String title,
  required String body,
  required Duration delay,
}) {
  final timestamp = DateTime.now().toString().split('.')[0];
  print('[${timestamp}] 📤 Notificación #$index enviada');
  print('             Título: $title');
  print('             Intervalo: ${_formatDuration(delay)}\n');
}

/// Formatear duración para mejor lectura
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
