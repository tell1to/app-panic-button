import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';

/// Servicio para gestionar recordatorios automáticos de citas médicas
/// Envía notificaciones locales cuando se acerca la fecha de una cita
class AppointmentReminderService {
  static final AppointmentReminderService _instance = AppointmentReminderService._internal();

  late FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin;
  static const String _channelId = 'medical_appointments';
  static const String _channelName = 'Recordatorios de Citas Médicas';
  bool _isInitialized = false;

  AppointmentReminderService._internal();

  factory AppointmentReminderService.instance() {
    return _instance;
  }

  /// Inicializar el servicio de notificaciones locales
  Future<void> initialize() async {
    if (_isInitialized) {
      print('[AppointmentReminderService] Ya inicializado');
      return;
    }

    try {
      // Inicializar timezone
      tz_data.initializeTimeZones();
      
      _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

      // Configuración Android
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      // Configuración iOS
      const DarwinInitializationSettings iosSettings =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      // Combinar configuraciones
      final InitializationSettings settings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      // Inicializar
      await _flutterLocalNotificationsPlugin.initialize(
        settings,
        onDidReceiveNotificationResponse: _onNotificationResponse,
      );

      // Crear canal de notificaciones para Android
      await _createNotificationChannel();

      // Solicitar permiso de notificaciones (Android 13+)
      await _requestNotificationPermission();

      _isInitialized = true;
      print('[AppointmentReminderService] Inicializado correctamente');
    } catch (e) {
      print('[AppointmentReminderService] ERROR al inicializar: $e');
      rethrow;
    }
  }

  /// Solicitar permiso de notificaciones en tiempo de ejecución (Android 13+)
  Future<void> _requestNotificationPermission() async {
    try {
      print('[AppointmentReminderService] Solicitando permiso de notificaciones...');
      final status = await Permission.notification.request();
      print('[AppointmentReminderService] Estado del permiso de notificaciones: $status');
      if (status.isDenied) {
        print('[AppointmentReminderService] ⚠️ Permiso de notificaciones denegado');
      } else if (status.isGranted) {
        print('[AppointmentReminderService] ✅ Permiso de notificaciones otorgado');
      }
    } catch (e) {
      print('[AppointmentReminderService] ⚠️ No se pudo solicitar permiso (puede ser normal en emuladores): $e');
      // No rethrow - permitir que la app continúe incluso si el permiso falla
    }
  }

  /// Crear canal de notificaciones (Android 8+)
  Future<void> _createNotificationChannel() async {
    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: 'Notificaciones de recordatorio para citas médicas',
      importance: Importance.high,
      enableVibration: true,
    );

    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    print('[AppointmentReminderService] Canal de notificaciones creado');
  }

  /// Callback cuando se toca una notificación
  /// Navega al cajón de citas médicas cuando el usuario toca la notificación
  void _onNotificationResponse(NotificationResponse response) {
    print('[AppointmentReminderService] Notificación tocada: ${response.payload}');
    
    // Si el payload contiene "appointment:", navegar al cajón de citas
    if (response.payload?.startsWith('appointment:') ?? false) {
      print('[AppointmentReminderService] Abriendo cajón de citas médicas...');
      // El navegador se configura desde main.dart con NotificationService
    }
  }

  /// Programar recordatorio para una cita médica
  /// [appointmentId]: ID único de la cita (ej: "cita_cardiologo_2025")
  /// [appointmentDateTime]: Fecha y hora de la cita
  /// [doctorName]: Nombre del médico/especialidad
  /// [appointmentDate]: Fecha en formato DD/MM/YYYY
  /// [appointmentTime]: Hora en formato HH:MM
  /// [minutesBeforeReminder]: Minutos antes de la cita para enviar recordatorio
  /// 
  /// Programar recordatorio 24 horas antes de la cita médica
  /// Si la cita es en menos de 24 horas, programa el recordatorio en 5 minutos
  Future<void> scheduleAppointmentReminder({
    required String appointmentId,
    required DateTime appointmentDateTime,
    required String doctorName,
    required String appointmentDate, // Formato: "23/12/2025"
    required String appointmentTime, // Formato: "14:30"
    int minutesBeforeReminder = 1440, // 1440 minutos = 24 horas
  }) async {
    if (!_isInitialized) {
      print('[AppointmentReminderService] Servicio no inicializado. Llamar a initialize() primero');
      return;
    }

    try {
      final now = DateTime.now();
      final durationUntilAppointment = appointmentDateTime.difference(now);
      
      print('[AppointmentReminderService] DEBUG: Ahora: $now');
      print('[AppointmentReminderService] DEBUG: Cita programada: $appointmentDateTime');
      print('[AppointmentReminderService] DEBUG: Minutos hasta cita: ${durationUntilAppointment.inMinutes}');
      print('[AppointmentReminderService] DEBUG: Minutos solicitados para recordatorio: $minutesBeforeReminder');

      // Determinar cuándo enviar el recordatorio
      // El recordatorio se envía X minutos antes de la cita
      DateTime reminderTime = appointmentDateTime.subtract(
        Duration(minutes: minutesBeforeReminder),
      );
      
      print('[AppointmentReminderService] DEBUG: Hora calculada de recordatorio: $reminderTime');

      // Si la hora de recordatorio ya pasó, programar en 1 minuto desde ahora
      if (reminderTime.isBefore(now)) {
        print('[AppointmentReminderService] ⚠️ Hora de recordatorio ya pasó, programando en 1 minuto desde ahora');
        reminderTime = now.add(const Duration(minutes: 1));
      }

      print('[AppointmentReminderService] DEBUG: Hora de recordatorio: $reminderTime');

      // Convertir a zona horaria local
      final tzDateTime = tz.TZDateTime.from(reminderTime, tz.local);

      // Detalles de la notificación
      final title = '📅 Cita Médica Próxima';
      final body = '$doctorName\n$appointmentDate a las $appointmentTime';
      final payload = 'appointment:$appointmentId'; // Payload para navegar

      // Programar notificación
      await _flutterLocalNotificationsPlugin.zonedSchedule(
        appointmentId.hashCode, // ID único basado en appointmentId
        title,
        body,
        tzDateTime,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: 'Recordatorios de citas médicas',
            importance: Importance.high,
            priority: Priority.high,
            enableVibration: true,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: payload,
      );

      print('[AppointmentReminderService] ✅ Recordatorio programado:');
      print('  - ID: $appointmentId');
      print('  - Cita: ${_formatDate(appointmentDateTime)} a las ${_formatTime(appointmentDateTime)}');
      print('  - Médico: $doctorName');
      print('  - Recordatorio: ${_formatDate(reminderTime)} a las ${_formatTime(reminderTime)}');
      print('  - En: ${durationUntilAppointment.inHours}h ${durationUntilAppointment.inMinutes % 60}m');
    } catch (e) {
      print('[AppointmentReminderService] ❌ ERROR al programar recordatorio: $e');
    }
  }

  /// Cancelar recordatorio de una cita
  Future<void> cancelAppointmentReminder(String appointmentId) async {
    try {
      await _flutterLocalNotificationsPlugin.cancel(appointmentId.hashCode);
      print('[AppointmentReminderService] Recordatorio cancelado: $appointmentId');
    } catch (e) {
      print('[AppointmentReminderService] ERROR al cancelar recordatorio: $e');
    }
  }

  /// Cancelar todos los recordatorios
  Future<void> cancelAllReminders() async {
    try {
      await _flutterLocalNotificationsPlugin.cancelAll();
      print('[AppointmentReminderService] Todos los recordatorios cancelados');
    } catch (e) {
      print('[AppointmentReminderService] ERROR al cancelar todos los recordatorios: $e');
    }
  }

  /// Obtener todos los recordatorios pendientes
  Future<List<PendingNotificationRequest>> getPendingReminders() async {
    try {
      final pending = await _flutterLocalNotificationsPlugin.pendingNotificationRequests();
      print('[AppointmentReminderService] Recordatorios pendientes: ${pending.length}');
      return pending;
    } catch (e) {
      print('[AppointmentReminderService] ERROR al obtener recordatorios pendientes: $e');
      return [];
    }
  }

  /// Verificar si un recordatorio ya está programado
  Future<bool> isReminderScheduled(String appointmentId) async {
    try {
      final pending = await getPendingReminders();
      return pending.any((p) => p.id == appointmentId.hashCode);
    } catch (e) {
      print('[AppointmentReminderService] ERROR al verificar recordatorio: $e');
      return false;
    }
  }

  /// Formatos de fecha/hora
  static String _formatDate(DateTime dt) {
    const monthNames = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    return '${dt.day} de ${monthNames[dt.month - 1]} de ${dt.year}';
  }

  static String _formatTime(DateTime dt) {
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  /// Verificar y reprogramar recordatorios de citas próximas
  /// Llamar esto periódicamente o al iniciar la app
  Future<void> refreshReminders(List<Map<String, dynamic>> appointments) async {
    try {
      print('[AppointmentReminderService] Actualizando recordatorios de citas...');
      
      // Para cada cita, reprogramar recordatorio
      for (final appointment in appointments) {
        final name = appointment['name'] as String?;
        final dateStr = appointment['date'] as String?;
        final timeStr = appointment['time'] as String? ?? '00:00';
        final alertMinutes = appointment['alertMinutes'] as int? ?? 1440;

        if (name == null || dateStr == null || dateStr.isEmpty) continue;

        try {
          final appointmentId = 'cita_${name}_$dateStr';
          
          // Parsear fecha (formato: "DD/MM/YYYY") y hora ("HH:MM")
          final dateParts = dateStr.split('/');
          final timeParts = timeStr.split(':');
          
          if (dateParts.length == 3 && timeParts.length == 2) {
            final day = int.tryParse(dateParts[0]) ?? 1;
            final month = int.tryParse(dateParts[1]) ?? 1;
            final year = int.tryParse(dateParts[2]) ?? 2025;
            final hour = int.tryParse(timeParts[0]) ?? 0;
            final minute = int.tryParse(timeParts[1]) ?? 0;
            
            final appointmentDateTime = DateTime(year, month, day, hour, minute);

            // Programar recordatorio
            await scheduleAppointmentReminder(
              appointmentId: appointmentId,
              appointmentDateTime: appointmentDateTime,
              doctorName: name,
              appointmentDate: dateStr,
              appointmentTime: timeStr,
              minutesBeforeReminder: alertMinutes,
            );
          }
        } catch (e) {
          print('[AppointmentReminderService] Error procesando cita: $e');
        }
      }
      
      print('[AppointmentReminderService] Recordatorios actualizados');
    } catch (e) {
      print('[AppointmentReminderService] ERROR actualizando recordatorios: $e');
    }
  }
}
