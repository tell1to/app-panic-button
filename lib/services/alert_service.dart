import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
}

/// Servicio para gestionar alertas en Firebase Realtime Database
class AlertService {
  static final AlertService _instance = AlertService._internal();

  static AlertService get instance => _instance;

  final _database = FirebaseDatabase.instance.ref();
  String? _userId;

  AlertService._internal();

  /// Inicializar el servicio con el ID del usuario
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

      // Guardar en Firebase
      await _database.child('alerts').child(_userId!).child(alertId).set(alert.toJson());

      // Guardar también localmente
      await _saveAlertLocally(alert);

      print('[AlertService.createAlert] Alerta creada: $alertId');
      return alertId;
    } catch (e) {
      print('[AlertService.createAlert] ERROR: $e');
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
}
