import 'package:flutter/material.dart';

/// Servicio para gestionar navegación global y notificaciones
/// NOTA: Firebase Cloud Messaging (FCM) ha sido eliminado según políticas de Firebase
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  NotificationService._internal();

  factory NotificationService.instance() {
    return _instance;
  }

  // Para mostrar snackbars y navegar globalmente
  static GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  /// Inicializar el servicio (ahora es un no-op después de eliminar FCM)
  Future<void> initialize() async {
    print('[NotificationService.initialize] Servicio de notificaciones inicializado (FCM eliminado)');
  }
}
