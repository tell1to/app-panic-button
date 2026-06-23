/// FASE 3: Firebase Integration - Ejemplos Prácticos
/// 
/// Este archivo contiene ejemplos de cómo usar Firebase en la app.
/// Incluye ejemplos de:
/// - Firebase Analytics (rastreo de eventos)
/// - Firebase Crashlytics (reporte de errores)
/// - Firebase Cloud Messaging (notificaciones push)
/// - Firebase Realtime Database (almacenamiento de alertas)

import 'package:firebase_analytics/firebase_analytics.dart';
import 'services/firebase_service.dart';
import 'services/alert_service.dart';

// ============================================================================
// EJEMPLO 1: Firebase Analytics - Rastrear eventos
// ============================================================================

void ejemploAnalytics() {
  // Registrar que el usuario abrió la app
  FirebaseService.instance.logEvent('app_opened', {
    'timestamp': DateTime.now().toIso8601String(),
    'version': '1.0.0',
  });

  // Registrar que el usuario agregó un contacto
  FirebaseService.instance.logEvent('contact_added', {
    'contact_type': 'emergency',
    'is_favorite': true,
  });

  // Registrar que el usuario actualizó su perfil médico
  FirebaseService.instance.logEvent('medical_info_updated', {
    'field': 'allergies',
    'value_changed': true,
  });

  // Registrar evento de pánico (esto se hace en main.dart)
  FirebaseService.instance.logEvent('emergency_activated', {
    'timestamp': DateTime.now().toIso8601String(),
    'has_location': true,
  });
}

// ============================================================================
// EJEMPLO 2: Firebase Crashlytics - Reportar errores
// ============================================================================

void ejemploCrashlytics() {
  try {
    // Código que podría fallar
    int result = int.parse('no_es_numero');
  } catch (e, stackTrace) {
    // Registrar error en Crashlytics
    FirebaseService.instance.recordError(
      e,
      stackTrace,
      reason: 'Error al parsear número de usuario',
    );

    print('Error registrado en Crashlytics: $e');
  }
}

// ============================================================================
// EJEMPLO 3: Firebase Cloud Messaging - Notificaciones Push
// ============================================================================

void ejemploCloudMessaging() {
  // Obtener FCM Token (enviable al servidor)
  FirebaseService.instance.getFCMToken().then((token) {
    print('FCM Token: $token');
    // Este token se enviaría al backend para enviar notificaciones personalizadas
  });

  // Suscribirse a topic para recibir notificaciones grupales
  FirebaseService.instance.subscribeTopic('alerts_ecuador').then((_) {
    print('Suscrito a: alerts_ecuador');
  });

  // Desuscribirse de un topic
  FirebaseService.instance.unsubscribeTopic('alerts_ecuador').then((_) {
    print('Desuscrito de: alerts_ecuador');
  });
}

// ============================================================================
// EJEMPLO 4: Firebase Realtime Database - Almacenar Alertas
// ============================================================================

Future<void> ejemploAlertService() async {
  // Inicializar el servicio con el ID del usuario
  await AlertService.instance.initialize('user_123');

  // Crear una nueva alerta
  try {
    final alertId = await AlertService.instance.createAlert(
      latitude: 0.2206,
      longitude: -78.4872,
      contactsNotified: ['contact_1', 'contact_2'],
      description: 'Alerta de pánico activada desde Quito',
      numberCalled: '911',
    );

    print('Alerta creada con ID: $alertId');

    // Obtener todas las alertas del usuario
    final alerts = await AlertService.instance.getUserAlerts();
    print('Total de alertas: ${alerts.length}');

    for (var alert in alerts) {
      print('Alerta: ${alert.id} - ${alert.description}');
      print('  Estado: ${alert.status}');
      print('  Ubicación: (${alert.latitude}, ${alert.longitude})');
      print('  Contactos notificados: ${alert.contactsNotified.length}');
    }

    // Actualizar estado de una alerta
    await AlertService.instance.updateAlertStatus(alertId, 'resolved');
    print('Alerta marcada como resuelta');

    // Obtener alertas locales (para cuando no hay conexión)
    final localAlerts = await AlertService.instance.getLocalAlerts();
    print('Alertas locales guardadas: ${localAlerts.length}');
  } catch (e) {
    print('Error al manejar alertas: $e');
  }
}

// ============================================================================
// EJEMPLO 5: Flujo Completo - Activar Emergencia con Firebase
// ============================================================================

Future<void> ejemploFlujoCompletoEmergencia() async {
  const userId = 'user_123';
  const latitude = 0.2206;
  const longitude = -78.4872;

  try {
    print('[Flujo Completo] 1. Registrando evento en Analytics...');
    await FirebaseService.instance.logEvent('emergency_activated', {
      'timestamp': DateTime.now().toIso8601String(),
      'location_available': true,
    });

    print('[Flujo Completo] 2. Inicializando servicio de alertas...');
    await AlertService.instance.initialize(userId);

    print('[Flujo Completo] 3. Creando alerta en Firebase...');
    final alertId = await AlertService.instance.createAlert(
      latitude: latitude,
      longitude: longitude,
      contactsNotified: ['contact_911', 'contact_family'],
      description: 'Alerta de pánico activada',
      numberCalled: '911',
    );

    print('[Flujo Completo] 4. Alerta creada: $alertId');

    print('[Flujo Completo] 5. Notificando a contactos...');
    // Aquí se enviarían notificaciones push a los contactos
    // (Necesita configuración en Firebase Console)

    print('[Flujo Completo] 6. Suscribiendo a actualizaciones de alerta...');
    // En una app real, se subscribiría a cambios en la alerta
    // (para obtener respuestas de los contactos)

    print('[Flujo Completo] ✅ Emergencia procesada correctamente');
  } catch (e, stackTrace) {
    print('[Flujo Completo] ❌ Error: $e');
    FirebaseService.instance.recordError(
      e,
      stackTrace,
      reason: 'Error en flujo completo de emergencia',
    );
  }
}

// ============================================================================
// EJEMPLO 6: Configuración de Temas para Notificaciones Grupales
// ============================================================================

Future<void> ejemploTemasNotificaciones() async {
  // Crear temas por país
  await FirebaseService.instance.subscribeTopic('alerts_ecuador');
  await FirebaseService.instance.subscribeTopic('alerts_colombia');
  await FirebaseService.instance.subscribeTopic('alerts_peru');

  // Crear temas por tipo de alerta
  await FirebaseService.instance.subscribeTopic('medical_alerts');
  await FirebaseService.instance.subscribeTopic('security_alerts');

  // Crear temas por nivel de prioridad
  await FirebaseService.instance.subscribeTopic('critical_alerts');
  await FirebaseService.instance.subscribeTopic('standard_alerts');

  print('Suscrito a todos los temas');

  // Cuando el usuario quiera desuscribirse
  // await FirebaseService.instance.unsubscribeTopic('alerts_ecuador');
}

// ============================================================================
// EJEMPLO 7: Manejo de Errores y Logging Automático
// ============================================================================

void ejemploManejoErrores() {
  // Todos los errores no manejados se registran automáticamente en Crashlytics
  // Pero también puedes registrar errores específicos:

  try {
    // Código que falla
    throw Exception('Error personalizado de prueba');
  } on FormatException catch (e, stackTrace) {
    // Registrar error específico
    FirebaseService.instance.recordError(
      e,
      stackTrace,
      reason: 'Error de formato detectado',
    );
  } catch (e, stackTrace) {
    // Registrar cualquier otro error
    FirebaseService.instance.recordError(
      e,
      stackTrace,
      reason: 'Error no previsto',
    );
  }

  print('Errores registrados correctamente');
}

void main() {
  print('=== EJEMPLOS DE FASE 3: FIREBASE INTEGRATION ===\n');

  print('1. Analytics: ejemploAnalytics();');
  print('2. Crashlytics: ejemploCrashlytics();');
  print('3. Cloud Messaging: ejemploCloudMessaging();');
  print('4. Alert Service: await ejemploAlertService();');
  print('5. Flujo Completo: await ejemploFlujoCompletoEmergencia();');
  print('6. Temas: await ejemploTemasNotificaciones();');
  print('7. Manejo de Errores: ejemploManejoErrores();');
}
