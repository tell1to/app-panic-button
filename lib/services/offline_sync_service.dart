import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_database/firebase_database.dart';

/// Modelo mejorado de alerta para sincronización offline
class OfflineAlert {
  final String id;
  final String userId;
  final DateTime timestamp;
  final double? latitude;
  final double? longitude;
  final String status;
  final List<String> contactsNotified;
  final String description;
  final String? numberCalled;
  
  // Datos encriptados
  final String? latitudeEncrypted;
  final String? longitudeEncrypted;
  final String? numberCalledEncrypted;
  
  // Metadata de sincronización
  final bool synced;
  final DateTime createdAt;
  final DateTime? syncedAt;

  OfflineAlert({
    required this.id,
    required this.userId,
    required this.timestamp,
    this.latitude,
    this.longitude,
    required this.status,
    required this.contactsNotified,
    required this.description,
    this.numberCalled,
    this.latitudeEncrypted,
    this.longitudeEncrypted,
    this.numberCalledEncrypted,
    this.synced = false,
    DateTime? createdAt,
    this.syncedAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Convertir a JSON para guardar en archivo
  /// Incluye todos los campos: date, time, timestamp, etc.
  Map<String, dynamic> toJson({bool encryptSensitiveData = true}) {
    final date = timestamp;
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final ampm = date.hour >= 12 ? 'pm' : 'am';
    final timeStr = '${hour.toString().padLeft(2, '0')}:$minute $ampm';
    final dateStr = _formatDate(date);

    return {
      'id': id,
      'userId': userId,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'date': dateStr,
      'time': timeStr,
      'status': status,
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
      'numberCalled': numberCalled,
      'contactsNotified': contactsNotified,
      // Datos encriptados
      'latitude_encrypted': encryptSensitiveData ? (latitudeEncrypted ?? '') : '',
      'longitude_encrypted': encryptSensitiveData ? (longitudeEncrypted ?? '') : '',
      'numberCalled_encrypted': encryptSensitiveData ? (numberCalledEncrypted ?? '') : '',
      // Metadata
      'synced': synced,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'syncedAt': syncedAt?.millisecondsSinceEpoch,
    };
  }

  /// Crear desde JSON
  factory OfflineAlert.fromJson(Map<String, dynamic> json) {
    return OfflineAlert(
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
      latitudeEncrypted: json['latitude_encrypted'] as String?,
      longitudeEncrypted: json['longitude_encrypted'] as String?,
      numberCalledEncrypted: json['numberCalled_encrypted'] as String?,
      synced: json['synced'] as bool? ?? false,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        (json['createdAt'] as int?) ?? DateTime.now().millisecondsSinceEpoch,
      ),
      syncedAt: json['syncedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['syncedAt'] as int)
          : null,
    );
  }

  static String _formatDate(DateTime dt) {
    const months = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    return '${months[dt.month - 1]} ${dt.day} del ${dt.year}';
  }
}

/// Servicio avanzado de sincronización offline con archivos JSON
/// Características:
/// - Detecta automáticamente cambios de conectividad
/// - Guarda alertas localmente cuando no hay internet
/// - Sincroniza automáticamente cuando se recupera conexión
/// - Escala bien para integración con APIs externas (WhatsApp)
class OfflineSyncService {
  static final OfflineSyncService _instance = OfflineSyncService._internal();

  static OfflineSyncService get instance => _instance;

  final _database = FirebaseDatabase.instance.ref();
  final _connectivity = Connectivity();
  
  late Directory _alertsDirectory;
  bool _isInitialized = false;
  bool _isOnline = true;
  
  // Callbacks para notificar cambios de estado
  final List<Function(bool isOnline)> _onlineStatusListeners = [];
  final List<Function(OfflineAlert alert)> _syncListeners = [];

  OfflineSyncService._internal();

  /// Inicializar el servicio
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      print('[OfflineSyncService.initialize] Inicializando...');
      
      // Obtener directorio de alertas
      await _setupAlertsDirectory();
      
      // Detectar estado inicial de conectividad
      await _updateOnlineStatus();
      
      // Monitorear cambios de conectividad
      _startConnectivityMonitor();
      
      _isInitialized = true;
      print('[OfflineSyncService.initialize] ✓ Inicializado - Online: $_isOnline');
    } catch (e) {
      print('[OfflineSyncService.initialize] ✗ ERROR: $e');
      rethrow;
    }
  }

  /// Configurar directorio de alertas
  Future<void> _setupAlertsDirectory() async {
    try {
      if (Platform.isAndroid) {
        final dir = Directory('/storage/emulated/0/Documents/alerts');
        if (!await dir.exists()) {
          await dir.create(recursive: true);
        }
        _alertsDirectory = dir;
      } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        final projDir = Directory(
          '${Directory.current.path}${Platform.pathSeparator}Documentos${Platform.pathSeparator}alerts'
        );
        if (!await projDir.exists()) {
          await projDir.create(recursive: true);
        }
        _alertsDirectory = projDir;
      } else {
        // iOS y otros
        final base = await getApplicationDocumentsDirectory();
        final dir = Directory(
          '${base.path}${Platform.pathSeparator}Documentos${Platform.pathSeparator}alerts'
        );
        if (!await dir.exists()) {
          await dir.create(recursive: true);
        }
        _alertsDirectory = dir;
      }
      
      print('[OfflineSyncService._setupAlertsDirectory] ✓ Directorio: ${_alertsDirectory.path}');
    } catch (e) {
      print('[OfflineSyncService._setupAlertsDirectory] ✗ ERROR: $e');
      rethrow;
    }
  }

  /// Monitorear cambios de conectividad
  void _startConnectivityMonitor() {
    _connectivity.onConnectivityChanged.listen((result) {
      final isOnline = result != ConnectivityResult.none;
      
      if (isOnline != _isOnline) {
        print('[OfflineSyncService] Conectividad cambió: $_isOnline → $isOnline');
        _isOnline = isOnline;
        
        // Notificar listeners
        for (var listener in _onlineStatusListeners) {
          listener(_isOnline);
        }
        
        // Si se recuperó conexión, sincronizar
        if (_isOnline) {
          print('[OfflineSyncService] ¡Conexión recuperada! Iniciando sincronización...');
          syncOfflineAlerts();
        }
      }
    });
  }

  /// Actualizar estado de conectividad
  Future<void> _updateOnlineStatus() async {
    try {
      final result = await _connectivity.checkConnectivity();
      _isOnline = result != ConnectivityResult.none;
      print('[OfflineSyncService._updateOnlineStatus] Estado: $_isOnline');
    } catch (e) {
      print('[OfflineSyncService._updateOnlineStatus] ERROR: $e');
    }
  }

  /// Obtener estado de conectividad actual
  bool get isOnline => _isOnline;

  /// Guardar alerta localmente (como archivo JSON)
  Future<String> saveAlertLocally(OfflineAlert alert) async {
    try {
      print('[OfflineSyncService.saveAlertLocally] Guardando alerta: ${alert.id}');
      
      final filename = 'alert_${alert.id}_${DateTime.now().millisecondsSinceEpoch}.json';
      final file = File('${_alertsDirectory.path}${Platform.pathSeparator}$filename');
      
      final json = alert.toJson(encryptSensitiveData: true);
      await file.writeAsString(jsonEncode(json), flush: true);
      
      print('[OfflineSyncService.saveAlertLocally] ✓ Guardada en: ${file.path}');
      return filename;
    } catch (e) {
      print('[OfflineSyncService.saveAlertLocally] ✗ ERROR: $e');
      rethrow;
    }
  }

  /// Obtener todas las alertas no sincronizadas desde archivos
  Future<List<OfflineAlert>> getUnsyncedAlerts() async {
    try {
      if (!_alertsDirectory.existsSync()) {
        return [];
      }

      final files = _alertsDirectory
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.json'))
          .toList();

      print('[OfflineSyncService.getUnsyncedAlerts] Archivos encontrados: ${files.length}');

      final alerts = <OfflineAlert>[];
      
      for (var file in files) {
        try {
          final content = await file.readAsString();
          final json = jsonDecode(content) as Map<String, dynamic>;
          final alert = OfflineAlert.fromJson(json);
          
          // Incluir solo si no está sincronizada
          if (!alert.synced) {
            alerts.add(alert);
          }
        } catch (e) {
          print('[OfflineSyncService.getUnsyncedAlerts] Error leyendo ${file.path}: $e');
        }
      }

      print('[OfflineSyncService.getUnsyncedAlerts] ✓ Total no sincronizadas: ${alerts.length}');
      return alerts;
    } catch (e) {
      print('[OfflineSyncService.getUnsyncedAlerts] ✗ ERROR: $e');
      return [];
    }
  }

  /// Sincronizar todas las alertas offline cuando se recupera conexión
  Future<void> syncOfflineAlerts() async {
    try {
      print('[OfflineSyncService.syncOfflineAlerts] ========================================');
      print('[OfflineSyncService.syncOfflineAlerts] Iniciando sincronización...');
      
      final unsyncedAlerts = await getUnsyncedAlerts();
      
      if (unsyncedAlerts.isEmpty) {
        print('[OfflineSyncService.syncOfflineAlerts] No hay alertas para sincronizar');
        return;
      }

      print('[OfflineSyncService.syncOfflineAlerts] Sincronizando ${unsyncedAlerts.length} alertas...');

      int synced = 0;
      int failed = 0;

      for (var alert in unsyncedAlerts) {
        try {
          print('[OfflineSyncService.syncOfflineAlerts] Sincronizando: ${alert.id}');
          
          // Guardar en Firebase
          await _database
              .child('users')
              .child(alert.userId)
              .child('alerts')
              .child(alert.id)
              .set(alert.toJson(encryptSensitiveData: true))
              .timeout(const Duration(seconds: 10));

          print('[OfflineSyncService.syncOfflineAlerts] ✓ Firebase: ${alert.id}');
          
          // Marcar como sincronizada en archivo local
          await markAlertAsSynced(alert.id);
          
          synced++;
          
          // Notificar listeners
          for (var listener in _syncListeners) {
            listener(alert);
          }
          
        } catch (e) {
          print('[OfflineSyncService.syncOfflineAlerts] ✗ Error sincronizando ${alert.id}: $e');
          failed++;
        }
      }

      print('[OfflineSyncService.syncOfflineAlerts] ========================================');
      print('[OfflineSyncService.syncOfflineAlerts] Resultados:');
      print('[OfflineSyncService.syncOfflineAlerts]   ✓ Sincronizadas: $synced');
      print('[OfflineSyncService.syncOfflineAlerts]   ✗ Fallidas: $failed');
      print('[OfflineSyncService.syncOfflineAlerts] ========================================');
      
    } catch (e) {
      print('[OfflineSyncService.syncOfflineAlerts] ✗ ERROR: $e');
    }
  }

  /// Marcar alerta como sincronizada en archivo local
  Future<void> markAlertAsSynced(String alertId) async {
    try {
      if (!_alertsDirectory.existsSync()) {
        return;
      }

      final files = _alertsDirectory
          .listSync()
          .whereType<File>()
          .where((f) => f.path.contains(alertId) && f.path.endsWith('.json'))
          .toList();

      for (var file in files) {
        try {
          final content = await file.readAsString();
          final json = jsonDecode(content) as Map<String, dynamic>;
          final alert = OfflineAlert.fromJson(json);
          
          if (alert.id == alertId) {
            final syncedAlert = OfflineAlert(
              id: alert.id,
              userId: alert.userId,
              timestamp: alert.timestamp,
              latitude: alert.latitude,
              longitude: alert.longitude,
              status: alert.status,
              contactsNotified: alert.contactsNotified,
              description: alert.description,
              numberCalled: alert.numberCalled,
              latitudeEncrypted: alert.latitudeEncrypted,
              longitudeEncrypted: alert.longitudeEncrypted,
              numberCalledEncrypted: alert.numberCalledEncrypted,
              synced: true, // ← Marcar como sincronizada
              createdAt: alert.createdAt,
              syncedAt: DateTime.now(),
            );

            final updatedJson = syncedAlert.toJson(encryptSensitiveData: true);
            await file.writeAsString(jsonEncode(updatedJson), flush: true);
            
            print('[OfflineSyncService.markAlertAsSynced] ✓ Marcada: $alertId');
          }
        } catch (e) {
          print('[OfflineSyncService.markAlertAsSynced] Error procesando ${file.path}: $e');
        }
      }
    } catch (e) {
      print('[OfflineSyncService.markAlertAsSynced] ✗ ERROR: $e');
    }
  }

  /// Obtener estadísticas de sincronización
  Future<Map<String, dynamic>> getSyncStats() async {
    try {
      final unsyncedAlerts = await getUnsyncedAlerts();
      final allAlerts = await _getAllAlerts();

      return {
        'total': allAlerts.length,
        'unsynced': unsyncedAlerts.length,
        'synced': allAlerts.length - unsyncedAlerts.length,
        'isOnline': _isOnline,
        'lastUpdate': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      print('[OfflineSyncService.getSyncStats] ERROR: $e');
      return {
        'total': 0,
        'unsynced': 0,
        'synced': 0,
        'isOnline': _isOnline,
        'error': e.toString(),
      };
    }
  }

  /// Obtener todas las alertas (sincronizadas y no)
  Future<List<OfflineAlert>> _getAllAlerts() async {
    try {
      if (!_alertsDirectory.existsSync()) {
        return [];
      }

      final files = _alertsDirectory
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.json'))
          .toList();

      final alerts = <OfflineAlert>[];

      for (var file in files) {
        try {
          final content = await file.readAsString();
          final json = jsonDecode(content) as Map<String, dynamic>;
          alerts.add(OfflineAlert.fromJson(json));
        } catch (e) {
          print('[OfflineSyncService._getAllAlerts] Error: ${file.path} - $e');
        }
      }

      return alerts;
    } catch (e) {
      print('[OfflineSyncService._getAllAlerts] ERROR: $e');
      return [];
    }
  }

  /// Registrar listener para cambios de estado online/offline
  void addOnlineStatusListener(Function(bool isOnline) listener) {
    _onlineStatusListeners.add(listener);
  }

  /// Registrar listener para alertas sincronizadas
  void addSyncListener(Function(OfflineAlert alert) listener) {
    _syncListeners.add(listener);
  }

  /// Limpiar archivos de alertas sincronizadas antiguas
  Future<void> cleanupOldSyncedAlerts({int daysToKeep = 30}) async {
    try {
      if (!_alertsDirectory.existsSync()) {
        return;
      }

      final files = _alertsDirectory
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.json'))
          .toList();

      final thirtyDaysAgo = DateTime.now().subtract(Duration(days: daysToKeep));
      int deletedCount = 0;

      for (var file in files) {
        try {
          final content = await file.readAsString();
          final json = jsonDecode(content) as Map<String, dynamic>;
          final alert = OfflineAlert.fromJson(json);

          if (alert.synced && alert.timestamp.isBefore(thirtyDaysAgo)) {
            await file.delete();
            deletedCount++;
          }
        } catch (e) {
          // Ignorar errores en limpieza
        }
      }

      if (deletedCount > 0) {
        print('[OfflineSyncService.cleanupOldSyncedAlerts] Eliminadas $deletedCount alertas antiguas');
      }
    } catch (e) {
      print('[OfflineSyncService.cleanupOldSyncedAlerts] ERROR: $e');
    }
  }

  /// Forzar sincronización manual (útil para testing)
  Future<void> forceSyncNow() async {
    print('[OfflineSyncService.forceSyncNow] Forzando sincronización...');
    await syncOfflineAlerts();
  }
}
