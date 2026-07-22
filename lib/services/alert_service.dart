import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'secure_storage_service.dart';
import 'encryption_service.dart';
import 'sync_service.dart';
import 'offline_sync_service.dart';

/// Modelo de Alerta mejorado con encriptación y sincronización
class AlertModel {
  final String id;
  final String userId; // CI del usuario
  final DateTime timestamp;
  final double? latitude;
  final double? longitude;
  final String status; // 'active', 'resolved', 'false_alarm'
  final List<String> contactsNotified;
  final String description;
  final String? numberCalled;
  
  // Datos encriptados
  final String? latitudeEncrypted;
  final String? longitudeEncrypted;
  final String? numberCalledEncrypted;
  
  // Datos del paciente
  final String? nombres;
  final String? apellidos;
  final String? edad;
  final String? tipoSangre;
  final List<String>? patologiasCatastroficas;
  final List<Map<String, String>>? condicionesMedicas;
  final List<String>? medicamentosHabitales;
  final List<String>? alergias;
  final List<Map<String, dynamic>>? sintomas;
  final Map<String, dynamic>? aseguramiento;
  
  // Estado de sincronización
  final bool synced;

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
    this.latitudeEncrypted,
    this.longitudeEncrypted,
    this.numberCalledEncrypted,
    this.nombres,
    this.apellidos,
    this.edad,
    this.tipoSangre,
    this.patologiasCatastroficas,
    this.condicionesMedicas,
    this.medicamentosHabitales,
    this.alergias,
    this.sintomas,
    this.aseguramiento,
    this.synced = false,
  });

  /// Convertir a JSON para Firebase (con datos encriptados)
  Map<String, dynamic> toJson({bool encryptSensitiveData = true}) {
    if (encryptSensitiveData) {
      return {
        'id': id,
        'userId': userId,
        'timestamp': timestamp.millisecondsSinceEpoch,
        'date': _formatDate(timestamp),
        'time': _formatTime(timestamp),
        'latitude_encrypted': latitudeEncrypted ?? '',
        'longitude_encrypted': longitudeEncrypted ?? '',
        'status': status,
        'contactsNotified': contactsNotified,
        'descripción': description,
        'numberCalled_encrypted': numberCalledEncrypted ?? '',
        // Datos del paciente
        'paciente': {
          'nombres': nombres ?? '',
          'apellidos': apellidos ?? '',
          'edad': edad ?? '',
          'tipoSangre': tipoSangre ?? '',
          'patologiasCatastróficas': patologiasCatastroficas ?? [],
          'condicionesMedicas': condicionesMedicas ?? [],
          'medicamentosHabitales': medicamentosHabitales ?? [],
          'alergias': alergias ?? [],
          'sintomas': sintomas ?? [],
          'aseguramiento': aseguramiento ?? {},
        }
      };
    } else {
      // Para local storage sin encriptación
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
        'synced': synced,
        // Datos del paciente
        'paciente': {
          'nombres': nombres ?? '',
          'apellidos': apellidos ?? '',
          'edad': edad ?? '',
          'tipoSangre': tipoSangre ?? '',
          'patologiasCatastróficas': patologiasCatastroficas ?? [],
          'condicionesMedicas': condicionesMedicas ?? [],
          'medicamentosHabitales': medicamentosHabitales ?? [],
          'alergias': alergias ?? [],
          'sintomas': sintomas ?? [],
          'aseguramiento': aseguramiento ?? {},
        }
      };
    }
  }

  /// Crear desde JSON (desencriptar si es necesario)
  factory AlertModel.fromJson(Map<dynamic, dynamic> json, {bool decrypt = false}) {
    double? lat;
    double? lon;
    String? numberCalled;

    if (decrypt) {
      final encService = EncryptionService.instance;
      final latStr = json['latitude_encrypted'] as String? ?? '';
      final lonStr = json['longitude_encrypted'] as String? ?? '';

      if (latStr.isNotEmpty) {
        lat = double.tryParse(encService.decrypt(latStr));
      }
      if (lonStr.isNotEmpty) {
        lon = double.tryParse(encService.decrypt(lonStr));
      }
      // numberCalled ahora está en paciente.contactoEmergenciaSeleccionado
    } else {
      lat = (json['latitude'] as num?)?.toDouble();
      lon = (json['longitude'] as num?)?.toDouble();
      numberCalled = json['numberCalled'] as String?;
    }

    // Parsear datos del paciente
    final pacienteData = json['paciente'] as Map<dynamic, dynamic>? ?? {};
    
    List<String>? patologiasCatastroficas;
    if (pacienteData['patologiasCatastróficas'] != null) {
      patologiasCatastroficas = List<String>.from(pacienteData['patologiasCatastróficas'] ?? []);
    }
    
    List<Map<String, String>>? condicionesMedicas;
    if (pacienteData['condicionesMedicas'] != null) {
      condicionesMedicas = (pacienteData['condicionesMedicas'] as List?)
          ?.map((e) => Map<String, String>.from(e as Map))
          .toList();
    }
    
    List<String>? medicamentosHabitales;
    if (pacienteData['medicamentosHabitales'] != null) {
      medicamentosHabitales = List<String>.from(pacienteData['medicamentosHabitales'] ?? []);
    }
    
    List<String>? alergias;
    if (pacienteData['alergias'] != null) {
      alergias = List<String>.from(pacienteData['alergias'] ?? []);
    }
    
    List<Map<String, dynamic>>? sintomas;
    if (pacienteData['sintomas'] != null) {
      sintomas = (pacienteData['sintomas'] as List?)
          ?.map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    }

    return AlertModel(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        (json['timestamp'] as int?) ?? DateTime.now().millisecondsSinceEpoch,
      ),
      latitude: lat,
      longitude: lon,
      status: json['status'] as String? ?? 'active',
      contactsNotified: List<String>.from(json['contactsNotified'] ?? []),
      description: json['description'] as String? ?? '',
      numberCalled: numberCalled ?? '', // Fallback, se obtiene de paciente.contactoEmergenciaSeleccionado
      synced: json['synced'] as bool? ?? false,
      // Datos del paciente
      nombres: pacienteData['nombres'] as String?,
      apellidos: pacienteData['apellidos'] as String?,
      edad: pacienteData['edad'] as String?,
      tipoSangre: pacienteData['tipoSangre'] as String?,
      patologiasCatastroficas: patologiasCatastroficas,
      condicionesMedicas: condicionesMedicas,
      medicamentosHabitales: medicamentosHabitales,
      alergias: alergias,
      sintomas: sintomas,
      aseguramiento: pacienteData['aseguramiento'] as Map<String, dynamic>?,
    );
  }

  /// Formato: "23 de Junio de 2026"
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

/// Servicio para gestionar alertas con sincronización offline
class AlertService {
  static final AlertService _instance = AlertService._internal();

  static AlertService get instance => _instance;

  final _database = FirebaseDatabase.instance.ref();
  final _connectivity = Connectivity();
  
  String? _userId; // CI del usuario
  bool _isInitialized = false;

  AlertService._internal();

  /// Inicializar el servicio
  /// REQUIERE: CI registrado en SecureStorage
  Future<void> initializeFromStorage() async {
    if (_isInitialized) return;

    try {
      print('[AlertService.initializeFromStorage] Inicializando...');
      
      // Obtener CI del usuario (SIN fallback)
      final ci = await SecureStorageService.getCI();
      
      if (ci == null || ci.isEmpty) {
        print('[AlertService.initializeFromStorage] ⚠️ ADVERTENCIA: No hay CI registrado');
        // Usar CI temporal para desarrollo/testing
        _userId = 'user_test_${DateTime.now().millisecondsSinceEpoch}';
        print('[AlertService.initializeFromStorage] Usando CI temporal: $_userId');
      } else {
        _userId = ci;
        print('[AlertService.initializeFromStorage] ✓ CI registrado: $_userId');
      }

      // Inicializar servicios de encriptación y sincronización
      EncryptionService.instance.initialize();
      await SyncService.instance.initialize();
      await OfflineSyncService.instance.initialize();

      _isInitialized = true;
      print('[AlertService.initializeFromStorage] ✓ Inicializado con usuario: $_userId');
      print('[AlertService.initializeFromStorage] ✓ OfflineSyncService inicializado');
      
      // Iniciar sincronización de alertas no sincronizadas
      _startSyncWatcher();
    } catch (e) {
      print('[AlertService.initializeFromStorage] ✗ ERROR: $e');
      rethrow;
    }
  }

  /// Crear una nueva alerta con encriptación
  /// Retorna el ID de la alerta creada
  Future<String> createAlert({
    required double? latitude,
    required double? longitude,
    required List<String> contactsNotified,
    required String description,
    required String numberCalled,
    // Datos del paciente
    String? nombres,
    String? apellidos,
    String? edad,
    String? tipoSangre,
    List<String>? patologiasCatastroficas,
    List<Map<String, String>>? condicionesMedicas,
    List<String>? medicamentosHabitales,
    List<String>? alergias,
    List<Map<String, dynamic>>? sintomas,
    Map<String, dynamic>? aseguramiento,
  }) async {
    if (_userId == null) {
      throw Exception('AlertService no inicializado. Llama a initializeFromStorage()');
    }

    try {
      // Leer CI actual de SecureStorage (por si el usuario cambió el CI)
      final currentCI = await SecureStorageService.getCI();
      final ciToUse = (currentCI != null && currentCI.isNotEmpty) ? currentCI : _userId!;

      print('[AlertService.createAlert] ========================================');
      print('[AlertService.createAlert] CREANDO ALERTA DE EMERGENCIA');
      print('[AlertService.createAlert] CI: $ciToUse');

      final alertId = _database.child('users').push().key ?? 
        '${DateTime.now().millisecondsSinceEpoch}';

      // Encriptar datos de ubicación y teléfono
      final encService = EncryptionService.instance;
      final latEncrypted = latitude != null ? encService.encrypt(latitude.toString()) : '';
      final lonEncrypted = longitude != null ? encService.encrypt(longitude.toString()) : '';
      final numEncrypted = encService.encrypt(numberCalled);

      final alert = AlertModel(
        id: alertId,
        userId: ciToUse,
        timestamp: DateTime.now(),
        latitude: latitude,
        longitude: longitude,
        status: 'active',
        contactsNotified: contactsNotified,
        description: description,
        numberCalled: numberCalled,
        latitudeEncrypted: latEncrypted,
        longitudeEncrypted: lonEncrypted,
        numberCalledEncrypted: numEncrypted,
        synced: false,
        // Datos del paciente
        nombres: nombres,
        apellidos: apellidos,
        edad: edad,
        tipoSangre: tipoSangre,
        patologiasCatastroficas: patologiasCatastroficas,
        condicionesMedicas: condicionesMedicas,
        medicamentosHabitales: medicamentosHabitales,
        alergias: alergias,
        sintomas: sintomas,
        aseguramiento: aseguramiento,
      );

      // 1. Intentar guardar en Firebase
      bool firebaseSuccess = false;
      try {
        print('[AlertService.createAlert] Intentando guardar en Firebase...');
        await _database
            .child('users')
            .child(ciToUse)
            .child('alerts')
            .child(alertId)
            .set(alert.toJson(encryptSensitiveData: true))
            .timeout(
              const Duration(seconds: 5),
              onTimeout: () => throw TimeoutException('Firebase timeout'),
            );

        firebaseSuccess = true;
        print('[AlertService.createAlert] ✓ Guardada en Firebase');
      } catch (e) {
        print('[AlertService.createAlert] ✗ Firebase falló: $e');
      }

      // 2. Guardar localmente (siempre con synced: false inicialmente)
      try {
        final offlineAlert = OfflineAlert(
          id: alertId,
          userId: ciToUse,
          timestamp: alert.timestamp,
          latitude: latitude,
          longitude: longitude,
          status: 'active',
          contactsNotified: contactsNotified,
          description: description,
          numberCalled: numberCalled,
          latitudeEncrypted: latEncrypted,
          longitudeEncrypted: lonEncrypted,
          synced: false, // Siempre guardamos como false primero
        );
        
        await OfflineSyncService.instance.saveAlertLocally(offlineAlert);
        print('[AlertService.createAlert] ✓ Guardada localmente (archivo JSON)');
      } catch (e) {
        print('[AlertService.createAlert] ✗ Error guardando localmente: $e');
      }

      // Marcar como sincronizada en Firebase SI fue exitoso
      if (firebaseSuccess) {
        try {
          await SyncService.instance.markAsSynced(alertId);
          await OfflineSyncService.instance.markAlertAsSynced(alertId);
          print('[AlertService.createAlert] ✓ Marcada como sincronizada');
        } catch (e) {
          print('[AlertService.createAlert] ✗ Error marcando como sincronizada: $e');
        }
      }

      print('[AlertService.createAlert] ========================================');
      print('[AlertService.createAlert] ✓ ALERTA COMPLETADA: $alertId');
      print('[AlertService.createAlert] ========================================');
      
      return alertId;
    } catch (e) {
      print('[AlertService.createAlert] ✗ ERROR CRÍTICO: $e');
      rethrow;
    }
  }

  /// Obtener todas las alertas del usuario
  Future<List<AlertModel>> getUserAlerts() async {
    if (_userId == null) {
      throw Exception('AlertService no inicializado');
    }

    try {
      // Leer CI actual de SecureStorage
      final currentCI = await SecureStorageService.getCI();
      final ciToUse = (currentCI != null && currentCI.isNotEmpty) ? currentCI : _userId!;

      final snapshot = await _database
          .child('users')
          .child(ciToUse)
          .child('alerts')
          .get();

      if (!snapshot.exists) {
        return [];
      }

      final List<AlertModel> alerts = [];
      final data = snapshot.value as Map<dynamic, dynamic>;

      data.forEach((key, value) {
        alerts.add(AlertModel.fromJson(value, decrypt: true));
      });

      // Ordenar por timestamp descendente
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
      // Leer CI actual de SecureStorage
      final currentCI = await SecureStorageService.getCI();
      final ciToUse = (currentCI != null && currentCI.isNotEmpty) ? currentCI : _userId!;

      await _database
          .child('users')
          .child(ciToUse)
          .child('alerts')
          .child(alertId)
          .child('status')
          .set(newStatus);

      print('[AlertService.updateAlertStatus] ✓ Actualizado: $alertId → $newStatus');
    } catch (e) {
      print('[AlertService.updateAlertStatus] ERROR: $e');
      rethrow;
    }
  }

  /// Actualizar múltiples campos de una alerta
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
      // Leer CI actual de SecureStorage
      final currentCI = await SecureStorageService.getCI();
      final ciToUse = (currentCI != null && currentCI.isNotEmpty) ? currentCI : _userId!;

      final updates = <String, dynamic>{};
      
      if (description != null) updates['description'] = description;
      if (location != null) updates['location'] = location;
      if (status != null) updates['status'] = status;

      if (updates.isEmpty) {
        print('[AlertService.updateAlert] No hay cambios para actualizar');
        return;
      }

      await _database
          .child('users')
          .child(ciToUse)
          .child('alerts')
          .child(alertId)
          .update(updates);

      print('[AlertService.updateAlert] ✓ Actualizada: $alertId con cambios: $updates');
    } catch (e) {
      print('[AlertService.updateAlert] ERROR: $e');
      rethrow;
    }
  }

  /// Sincronizar alertas locales cuando se recupera conexión
  Future<void> syncLocalAlerts() async {
    try {
      final unsyncedAlerts = await SyncService.instance.getUnsyncedAlerts();

      if (unsyncedAlerts.isEmpty) {
        print('[AlertService.syncLocalAlerts] No hay alertas para sincronizar');
        return;
      }

      print('[AlertService.syncLocalAlerts] Sincronizando ${unsyncedAlerts.length} alertas...');

      for (final alert in unsyncedAlerts) {
        try {
          // Encriptar datos de ubicaci\u00f3n (numberCalled ya est\u00e1 en paciente.contactoEmergenciaSeleccionado)
          final encService = EncryptionService.instance;
          final latEncrypted = alert.latitude != null ? encService.encrypt(alert.latitude.toString()) : '';
          final lonEncrypted = alert.longitude != null ? encService.encrypt(alert.longitude.toString()) : '';

          // Construir el objeto de alerta con datos encriptados
          final alertData = {
            'id': alert.id,
            'userId': alert.userId,
            'timestamp': alert.timestamp.millisecondsSinceEpoch,
            'date': _formatDate(alert.timestamp),
            'time': _formatTime(alert.timestamp),
            'latitude_encrypted': latEncrypted,
            'longitude_encrypted': lonEncrypted,
            'status': alert.status,
            'contactsNotified': alert.contactsNotified,
            'description': alert.description,
          };

          // Enviar a Firebase usando el userId del alert (CI que tenía cuando se creó)
          await _database
              .child('users')
              .child(alert.userId)
              .child('alerts')
              .child(alert.id)
              .set(alertData)
              .timeout(
                const Duration(seconds: 5),
                onTimeout: () => throw TimeoutException('Firebase timeout'),
              );

          // Marcar como sincronizada
          await SyncService.instance.markAsSynced(alert.id);
          print('[AlertService.syncLocalAlerts] ✓ Sincronizada: ${alert.id}');
        } catch (e) {
          print('[AlertService.syncLocalAlerts] ✗ Error sincronizando ${alert.id}: $e');
        }
      }

      print('[AlertService.syncLocalAlerts] ✓ Sincronización completada');
    } catch (e) {
      print('[AlertService.syncLocalAlerts] ERROR: $e');
    }
  }

  /// Formatear fecha para Firebase
  static String _formatDate(DateTime dt) {
    const monthNames = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    return '${dt.day} de ${monthNames[dt.month - 1]} de ${dt.year}';
  }

  /// Formatear hora para Firebase
  static String _formatTime(DateTime dt) {
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    final second = dt.second.toString().padLeft(2, '0');
    return '$hour:$minute:$second';
  }

  /// Observador de conectividad para sincronización automática
  void _startSyncWatcher() {
    _connectivity.onConnectivityChanged.listen((result) {
      if (result != ConnectivityResult.none) {
        print('[AlertService._startSyncWatcher] Conectividad recuperada, sincronizando...');
        syncLocalAlerts();
      }
    });
  }
}
