import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Modelo de alerta sincronizado
/// Guarda estado de sincronización offline
class SyncAlert {
  final String id;
  final String userId;
  final DateTime timestamp;
  final double? latitude;
  final double? longitude;
  final String status;
  final List<String> contactsNotified;
  final String description;
  final String? numberCalled;
  final bool synced; // true = sincronizado con Firebase

  SyncAlert({
    required this.id,
    required this.userId,
    required this.timestamp,
    this.latitude,
    this.longitude,
    required this.status,
    required this.contactsNotified,
    required this.description,
    this.numberCalled,
    this.synced = false,
  });

  /// Convertir a JSON para guardar localmente
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
      'synced': synced,
    };
  }

  /// Crear desde JSON
  factory SyncAlert.fromJson(Map<String, dynamic> json) {
    return SyncAlert(
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
      synced: json['synced'] as bool? ?? false,
    );
  }
}

/// Servicio para sincronización offline
class SyncService {
  static final SyncService _instance = SyncService._internal();

  static SyncService get instance => _instance;

  static const String _localAlertsKey = 'sync_alerts_queue';
  late SharedPreferences _prefs;
  bool _isInitialized = false;

  SyncService._internal();

  /// Inicializar el servicio
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _prefs = await SharedPreferences.getInstance();
      _isInitialized = true;
      print('[SyncService.initialize] Inicializado');
    } catch (e) {
      print('[SyncService.initialize] ERROR: $e');
      rethrow;
    }
  }

  /// Guardar alerta localmente (para sincronizar después)
  Future<void> saveAlertLocally(SyncAlert alert) async {
    try {
      final alerts = await getUnsyncedAlerts();
      
      // Si el alert ya existe, actualizar
      alerts.removeWhere((a) => a.id == alert.id);
      alerts.add(alert);

      final jsonList = alerts.map((a) => jsonEncode(a.toJson())).toList();
      await _prefs.setStringList(_localAlertsKey, jsonList);

      print('[SyncService.saveAlertLocally] Alerta guardada localmente: ${alert.id}');
    } catch (e) {
      print('[SyncService.saveAlertLocally] ERROR: $e');
      rethrow;
    }
  }

  /// Obtener todas las alertas no sincronizadas
  Future<List<SyncAlert>> getUnsyncedAlerts() async {
    try {
      final jsonList = _prefs.getStringList(_localAlertsKey) ?? [];
      
      return jsonList
          .map((jsonStr) {
            try {
              final json = jsonDecode(jsonStr) as Map<String, dynamic>;
              return SyncAlert.fromJson(json);
            } catch (e) {
              print('[SyncService.getUnsyncedAlerts] Error deserializando: $e');
              return null;
            }
          })
          .whereType<SyncAlert>()
          .where((alert) => !alert.synced) // Solo no sincronizadas
          .toList();
    } catch (e) {
      print('[SyncService.getUnsyncedAlerts] ERROR: $e');
      return [];
    }
  }

  /// Marcar alerta como sincronizada
  Future<void> markAsSynced(String alertId) async {
    try {
      // Buscar en TODAS las alertas, no solo las no sincronizadas
      final allAlerts = await _getAllAlerts();
      final alertIndex = allAlerts.indexWhere((a) => a.id == alertId);

      if (alertIndex != -1) {
        final syncedAlert = SyncAlert(
          id: allAlerts[alertIndex].id,
          userId: allAlerts[alertIndex].userId,
          timestamp: allAlerts[alertIndex].timestamp,
          latitude: allAlerts[alertIndex].latitude,
          longitude: allAlerts[alertIndex].longitude,
          status: allAlerts[alertIndex].status,
          contactsNotified: allAlerts[alertIndex].contactsNotified,
          description: allAlerts[alertIndex].description,
          numberCalled: allAlerts[alertIndex].numberCalled,
          synced: true, // ✓ Marcar como sincronizada
        );

        allAlerts.removeWhere((a) => a.id == alertId);
        allAlerts.add(syncedAlert);

        final jsonList = allAlerts.map((a) => jsonEncode(a.toJson())).toList();
        await _prefs.setStringList(_localAlertsKey, jsonList);

        print('[SyncService.markAsSynced] ✓ Alerta marcada como sincronizada: $alertId');
      } else {
        print('[SyncService.markAsSynced] ⚠️ Alerta no encontrada: $alertId');
      }
    } catch (e) {
      print('[SyncService.markAsSynced] ERROR: $e');
    }
  }

  /// Obtener todas las alertas (sincronizadas y no)
  Future<List<SyncAlert>> _getAllAlerts() async {
    try {
      final jsonList = _prefs.getStringList(_localAlertsKey) ?? [];

      return jsonList
          .map((jsonStr) {
            try {
              final json = jsonDecode(jsonStr) as Map<String, dynamic>;
              return SyncAlert.fromJson(json);
            } catch (e) {
              return null;
            }
          })
          .whereType<SyncAlert>()
          .toList();
    } catch (e) {
      print('[SyncService._getAllAlerts] ERROR: $e');
      return [];
    }
  }

  /// Limpiar alertas sincronizadas (mantener último mes)
  Future<void> cleanupOldSyncedAlerts() async {
    try {
      final alerts = await _getAllAlerts();
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));

      final filtered = alerts
          .where((a) => a.synced && a.timestamp.isAfter(thirtyDaysAgo))
          .toList();

      final jsonList = filtered.map((a) => jsonEncode(a.toJson())).toList();
      await _prefs.setStringList(_localAlertsKey, jsonList);

      print('[SyncService.cleanupOldSyncedAlerts] Limpieza completada');
    } catch (e) {
      print('[SyncService.cleanupOldSyncedAlerts] ERROR: $e');
    }
  }

  /// Obtener estadísticas de sincronización
  Future<Map<String, int>> getSyncStats() async {
    try {
      final unsyncedAlerts = await getUnsyncedAlerts();
      final allAlerts = await _getAllAlerts();

      return {
        'unsynced': unsyncedAlerts.length,
        'total': allAlerts.length,
      };
    } catch (e) {
      print('[SyncService.getSyncStats] ERROR: $e');
      return {'unsynced': 0, 'total': 0};
    }
  }
}
