import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

/// Servicio para manejar notificaciones push (FCM)
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  late FirebaseMessaging _firebaseMessaging;
  static const String _channelId = 'emergency_alerts';
  static const String _channelName = 'Alertas de Emergencia';

  NotificationService._internal();

  factory NotificationService.instance() {
    return _instance;
  }

  // Para mostrar snackbars globales
  static GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  /// Inicializar FCM
  Future<void> initialize() async {
    _firebaseMessaging = FirebaseMessaging.instance;

    // Solicitar permisos en iOS
    await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: true,
      badge: true,
      criticalAlert: true,
      provisional: false,
      sound: true,
    );

    // Obtener token del dispositivo
    String? token = await _firebaseMessaging.getToken();
    print('🔔 FCM Token: $token');

    // Guardar el token para asociarlo con este dispositivo
    // (útil para enviar notificaciones específicas a un dispositivo)

    // Escuchar notificaciones en foreground
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Escuchar cuando el usuario toca la notificación (app en background/terminated)
    FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);

    // Manejar cuando la app se abre desde una notificación (terminated)
    RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      _handleBackgroundMessage(initialMessage);
    }
  }

  /// Manejo de notificaciones en foreground
  void _handleForegroundMessage(RemoteMessage message) {
    print('📬 Notificación en foreground recibida:');
    print('Título: ${message.notification?.title}');
    print('Body: ${message.notification?.body}');
    print('Data: ${message.data}');

    // Mostrar snackbar con la notificación
    _showNotificationSnackBar(
      title: message.notification?.title ?? 'Nueva Alerta',
      body: message.notification?.body ?? '',
      data: message.data,
    );

    // Opcionalmente, reproducir sonido o vibración
    _playNotificationSound();
  }

  /// Manejo de notificaciones en background/terminated
  void _handleBackgroundMessage(RemoteMessage message) {
    print('📭 Notificación desde background/terminated:');
    print('Título: ${message.notification?.title}');
    print('Body: ${message.notification?.body}');

    // Aquí puedes navegar a una pantalla específica
    // por ejemplo, mostrar detalles de la alerta
    _navigateToAlert(message.data);
  }

  /// Mostrar snackbar con la notificación
  void _showNotificationSnackBar({
    required String title,
    required String body,
    required Map<String, dynamic> data,
  }) {
    final context = navigatorKey.currentContext;
    if (context != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(body),
            ],
          ),
          duration: const Duration(seconds: 5),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red[700],
          margin: const EdgeInsets.all(10),
          action: SnackBarAction(
            label: 'Ver',
            textColor: Colors.white,
            onPressed: () => _navigateToAlert(data),
          ),
        ),
      );
    }
  }

  /// Reproducir sonido de notificación
  void _playNotificationSound() {
    // Implementar con plugin de audio si es necesario
    // Por ahora solo es un placeholder
    print('🔊 Reproduciendo sonido de notificación...');
  }

  /// Navegar a la pantalla de alertas cuando se toca la notificación
  void _navigateToAlert(Map<String, dynamic> data) {
    final context = navigatorKey.currentContext;
    if (context != null) {
      // Extraer datos de la notificación
      final String? alertId = data['alert_id'];
      final String? userId = data['user_id'];

      print('📍 Navegando a alerta: $alertId de usuario: $userId');

      // Navegar a la pantalla de opciones (historial de alertas)
      // Navigator.of(context).pushNamed('/options');
      // O mostrar un dialog con detalles
    }
  }

  /// Obtener el token FCM del dispositivo actual
  Future<String?> getFCMToken() async {
    return await _firebaseMessaging.getToken();
  }

  /// Suscribirse a un tópico (útil para enviar a múltiples usuarios)
  Future<void> subscribeToTopic(String topic) async {
    await _firebaseMessaging.subscribeToTopic(topic);
    print('✅ Suscrito al tópico: $topic');
  }

  /// Desuscribirse de un tópico
  Future<void> unsubscribeFromTopic(String topic) async {
    await _firebaseMessaging.unsubscribeFromTopic(topic);
    print('❌ Desuscrito del tópico: $topic');
  }

  /// Enviar notificación de prueba (solo en desarrollo)
  Future<void> sendTestNotification({
    required String title,
    required String body,
    required String recipientToken,
  }) async {
    print('📧 Enviando notificación de prueba a: $recipientToken');
    // Nota: Para enviar real, necesitas backend con credenciales de Firebase
    // Este método es solo para demostración
  }
}
