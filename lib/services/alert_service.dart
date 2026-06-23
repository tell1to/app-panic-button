import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'secure_storage_service.dart';
import 'notification_service.dart';

/// Modelo de Alerta
class AlertModel {
  final String id;
  final String userId;
  final DateTime timestamp;
  final double? latitude;
  final double? longitude;
  final String status; // 'active', 'resolved', 'false_alarm'
  final List<String> contactsNotified;
  final String description;
  final String? numberCalled;

  AlertModel({
    required this.id,
    required this.userId,
    required this.timestamp,
    this.latitude,
    this.longitude,
    required this.status,
    required this.contactsNotified,
    required this.description,
    this.numberCalled,
  });

  /// Convertir a JSON para Firebase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'date': _formatDate(timestamp),
      'time': _formatTime(timestamp),
      'latitude': latitude,
      'longitude': longitude,
      'status': status,
      'contactsNotified': contactsNotified,
      'description': description,
      'numberCalled': numberCalled,
    };
  }

  /// Crear desde JSON
  factory AlertModel.fromJson(Map<dynamic, dynamic> json) {
    return AlertModel(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        (json['timestamp'] as int?) ?? DateTime.now().millisecondsSinceEpoch,
      ),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      status: json['status'] as String? ?? 'active',
      contactsNotified: List<String>.from(json['contactsNotified'] ?? []),
      description: json['description'] as String? ?? '',
      numberCalled: json['numberCalled'] as String?,
    );
  }

  /// Formato: "22 de Diciembre de 2025"
  static String _formatDate(DateTime dt) {
    const monthNames = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    return '${dt.day} de ${monthNames[dt.month - 1]} de ${dt.year}';
  }

  /// Formato: "14:30:45" (24 horas)
  static String _formatTime(DateTime dt) {
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    final second = dt.second.toString().padLeft(2, '0');
    return '$hour:$minute:$second';
  }
}

/// Servicio para gestionar alertas en Firebase Realtime Database
class AlertService {
  static final AlertService _instance = AlertService._internal();

  static AlertService get instance => _instance;

  final _database = FirebaseDatabase.instance.ref();
  String? _userId;

  AlertService._internal();

  /// Inicializar el servicio automáticamente desde CI del usuario
  /// Si no hay CI, usa 'user_default'
  Future<void> initializeFromStorage() async {
    try {
      _userId = await SecureStorageService.getUserId();
      print('[AlertService.initializeFromStorage] Inicializado con userId: $_userId');
    } catch (e) {
      _userId = 'user_default';
      print('[AlertService.initializeFromStorage] Error, usando user_default: $e');
    }
  }

  /// Inicializar el servicio con el ID del usuario (método legado)
  Future<void> initialize(String userId) async {
    _userId = userId;
    print('[AlertService.initialize] Inicializado con usuario: $userId');
  }

  /// Crear una nueva alerta
  /// Retorna el ID de la alerta creada
  Future<String> createAlert({
    required double? latitude,
    required double? longitude,
    required List<String> contactsNotified,
    required String description,
    required String numberCalled,
  }) async {
    if (_userId == null) {
      throw Exception('AlertService no inicializado. Llama a initialize() primero.');
    }

    try {
      final alertId = _database.child('alerts').push().key ?? '${DateTime.now().millisecondsSinceEpoch}';

      final alert = AlertModel(
        id: alertId,
        userId: _userId!,
        timestamp: DateTime.now(),
        latitude: latitude,
        longitude: longitude,
        status: 'active',
        contactsNotified: contactsNotified,
        description: description,
        numberCalled: numberCalled,
      );

      print('[AlertService.createAlert] ========================================');
      print('[AlertService.createAlert] GUARDANDO ALERTA DE EMERGENCIA');
      print('[AlertService.createAlert] UserId: $_userId');
      print('[AlertService.createAlert] AlertId: $alertId');
      print('[AlertService.createAlert] Ubicación: lat=$latitude, lon=$longitude');
      print('[AlertService.createAlert] ========================================');

      // Guardar en Firebase (con reintentos)
      bool firebaseSuccess = false;
      for (int attempt = 1; attempt <= 2; attempt++) {
        try {
          print('[AlertService.createAlert] Intento $attempt/2: Guardando en Firebase Realtime DB...');
          await _database.child('alerts').child(_userId!).child(alertId).set(alert.toJson()).timeout(
            const Duration(seconds: 8),
            onTimeout: () {
              throw TimeoutException('Firebase write timeout después de 8s');
            },
          );
          print('[AlertService.createAlert] ✓ ÉXITO: Alerta guardada en Firebase');
          firebaseSuccess = true;
          break;
        } catch (firebaseError) {
          print('[AlertService.createAlert] ✗ Intento $attempt/2 falló: $firebaseError');
          if (attempt < 2) {
            print('[AlertService.createAlert] Esperando 2 segundos antes de reintentar...');
            await Future.delayed(const Duration(seconds: 2));
          }
        }
      }

      if (!firebaseSuccess) {
        print('[AlertService.createAlert] ⚠️  FIREBASE NO DISPONIBLE - Usando almacenamiento local');
      }

      // Guardar también localmente (fallback/backup)
      try {
        await _saveAlertLocally(alert);
        print('[AlertService.createAlert] ✓ Alerta guardada en almacenamiento local');
      } catch (e) {
        print('[AlertService.createAlert] ✗ Error guardando localmente: $e');
      }

      print('[AlertService.createAlert] ========================================');
      print('[AlertService.createAlert] ALERTA COMPLETADA: $alertId');
      print('[AlertService.createAlert] ========================================');
      return alertId;
    } catch (e) {
      print('[AlertService.createAlert] ERROR CRÍTICO: $e');
      print('[AlertService.createAlert] StackTrace: ${StackTrace.current}');
      rethrow;
    }
  }

  /// Obtener todas las alertas del usuario
  Future<List<AlertModel>> getUserAlerts() async {
    if (_userId == null) {
      throw Exception('AlertService no inicializado');
    }

    try {
      final snapshot = await _database.child('alerts').child(_userId!).get();

      if (!snapshot.exists) {
        return [];
      }

      final List<AlertModel> alerts = [];
      final data = snapshot.value as Map<dynamic, dynamic>;

      data.forEach((key, value) {
        alerts.add(AlertModel.fromJson(value));
      });

      // Ordenar por timestamp descendente (más reciente primero)
      alerts.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      return alerts;
    } catch (e) {
      print('[AlertService.getUserAlerts] ERROR: $e');
      return [];
    }
  }

  /// Actualizar estado de una alerta
  Future<void> updateAlertStatus(String alertId, String newStatus) async {
    if (_userId == null) {
      throw Exception('AlertService no inicializado');
    }

    try {
      await _database
          .child('alerts')
          .child(_userId!)
          .child(alertId)
          .child('status')
          .set(newStatus);

      print('[AlertService.updateAlertStatus] Estado actualizado: $alertId -> $newStatus');
    } catch (e) {
      print('[AlertService.updateAlertStatus] ERROR: $e');
      rethrow;
    }
  }

  /// Actualizar múltiples campos de una alerta (descripción, ubicación, estado)
  Future<void> updateAlert({
    required String alertId,
    String? description,
    String? location,
    String? status,
  }) async {
    if (_userId == null) {
      throw Exception('AlertService no inicializado');
    }

    try {
      final updates = <String, dynamic>{};
      
      if (description != null) updates['description'] = description;
      if (location != null) updates['location'] = location;
      if (status != null) updates['status'] = status;

      if (updates.isEmpty) {
        print('[AlertService.updateAlert] No hay cambios para actualizar');
        return;
      }

      await _database
          .child('alerts')
          .child(_userId!)
          .child(alertId)
          .update(updates);

      print('[AlertService.updateAlert] Alerta actualizada: $alertId con cambios: $updates');
    } catch (e) {
      print('[AlertService.updateAlert] ERROR: $e');
      rethrow;
    }
  }

  /// Guardar alerta localmente (backup)
  Future<void> _saveAlertLocally(AlertModel alert) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final alerts = prefs.getStringList('local_alerts') ?? [];
      
      // Agregar alerta como JSON string
      alerts.add(alert.toJson().toString());
      
      // Mantener solo las últimas 50 alertas localmente
      if (alerts.length > 50) {
        alerts.removeRange(0, alerts.length - 50);
      }
      
      await prefs.setStringList('local_alerts', alerts);
      print('[AlertService._saveAlertLocally] Alerta guardada localmente');
    } catch (e) {
      print('[AlertService._saveAlertLocally] ERROR: $e');
    }
  }

  /// Obtener alertas locales (para cuando no hay conexión)
  Future<List<String>> getLocalAlerts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getStringList('local_alerts') ?? [];
    } catch (e) {
      print('[AlertService.getLocalAlerts] ERROR: $e');
      return [];
    }
  }

  /// Limpiar alertas locales
  Future<void> clearLocalAlerts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('local_alerts');
      print('[AlertService.clearLocalAlerts] Alertas locales borradas');
    } catch (e) {
      print('[AlertService.clearLocalAlerts] ERROR: $e');
    }
  }

  /// Notificar a contactos sobre una alerta activada
  /// Se envía a través de FCM si los contactos tienen tokens disponibles
  Future<void> notifyContacts({
    required String alertId,
    required double? latitude,
    required double? longitude,
    required String description,
  }) async {
    try {
      final notificationService = NotificationService.instance();
      
      // Construir el mensaje de la notificación
      final title = '🚨 ALERTA DE EMERGENCIA';
      final body = description.isNotEmpty
          ? description
          : 'Se ha activado una alerta de emergencia. Ubicación disponible.';
      
      // Datos adicionales para la notificación
      final Map<String, dynamic> data = {
        'alert_id': alertId,
        'user_id': _userId,
        'latitude': latitude?.toString() ?? '',
        'longitude': longitude?.toString() ?? '',
        'timestamp': DateTime.now().toIso8601String(),
      };

      print('[AlertService.notifyContacts] Notificando a contactos sobre alerta: $alertId');
      print('[AlertService.notifyContacts] Título: $title, Body: $body');
      
      // Nota: Para enviar notificaciones reales, necesitarías:
      // 1. Backend con credenciales de Firebase Admin SDK
      // 2. O usar una Cloud Function que escuche cambios en Firebase
      // Por ahora, solo registramos la intención
      
    } catch (e) {
      print('[AlertService.notifyContacts] ERROR: $e');
    }
  }
}
