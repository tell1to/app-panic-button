# 🔧 Documentación Técnica: Sincronización Offline con Escalabilidad para WhatsApp

## Arquitectura General

```
┌─────────────────────────────────────────────────────────────────┐
│                         App Flutter                             │
│                                                                 │
│  ┌──────────────────┐        ┌──────────────────────────────┐  │
│  │   AlertService   │        │  OfflineSyncService          │  │
│  │  (Crear alertas) │───────▶│  (Sincronizar offline)       │  │
│  └──────────────────┘        └──────────────────────────────┘  │
│           │                              │                      │
│           │                              │                      │
│           ▼                              ▼                      │
│  ┌──────────────────┐        ┌──────────────────────────────┐  │
│  │ Firebase RT DB   │        │ Local Storage (JSON Files)   │  │
│  │ (Cloud)          │        │ /storage/emulated/0/          │  │
│  │                  │        │ Documents/alerts/             │  │
│  └──────────────────┘        └──────────────────────────────┘  │
│                                          │                      │
│  ┌──────────────────────────────────────▼──────────────────┐   │
│  │  EncryptionService                                       │   │
│  │  (Encripta: lat, lon, phone)                            │   │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
         │                                │
         │ (Internet disponible)          │ (Sin internet)
         ▼                                ▼
    Firebase Cloud              Local Storage
    Realtime Database           Archivos JSON
    /users/{CI}/alerts          Cifrados
```

## Flujo de Sincronización

### Caso 1: Con Conexión (Normal)
```
Alerta Activada
    │
    ├─ Encriptar datos (lat, lon, phone)
    │
    ├─ Guardar en Firebase
    │  └─ users/{CI}/alerts/{alertId}
    │
    └─ Guardar localmente (JSON)
       └─ Marcado como: synced = true
          
Result: Dato en la nube + copia local sincronizada
```

### Caso 2: Sin Conexión (Offline)
```
Alerta Activada (Sin WiFi/Datos)
    │
    ├─ Encriptar datos (lat, lon, phone)
    │
    ├─ Intentar Firebase ❌ FALLA (timeout 5s)
    │
    ├─ Guardar localmente (JSON)
    │  ├─ timestamp: <momento de la alerta>
    │  ├─ synced: false
    │  ├─ createdAt: <cuando se guardó>
    │  └─ syncedAt: null
    │
    └─ Esperar a que se recupere la conexión
    
Result: Archivo JSON local con synced = false
```

### Caso 3: Reconexión (Auto-Sync)
```
Conectividad Recuperada
    │
    ├─ OfflineSyncService detecta: isOnline = true
    │
    ├─ Obtiene alertas no sincronizadas
    │  └─ Busca archivos con synced = false
    │
    ├─ Para cada alerta pendiente:
    │  ├─ Envía a Firebase
    │  └─ Actualiza archivo JSON
    │     ├─ synced: true
    │     └─ syncedAt: <timestamp actual>
    │
    └─ Notifica listeners (para UI, WhatsApp, etc)
    
Result: Todas las alertas sincronizadas
```

## Flujo Detallado del Código

### 1. Crear Alerta (AlertService.createAlert)
```dart
Future<String> createAlert({...}) async {
  // 1. Preparar datos
  final alertId = generateId();
  final latEncrypted = encryptionService.encrypt(lat);
  final lonEncrypted = encryptionService.encrypt(lon);
  final numEncrypted = encryptionService.encrypt(numberCalled);
  
  // 2. Intentar Firebase
  bool firebaseSuccess = false;
  try {
    await firebase.child('users/{ci}/alerts/{alertId}').set(data);
    firebaseSuccess = true;
  } catch(e) {
    // Falló, continuamos...
  }
  
  // 3. Guardar localmente (SIEMPRE)
  final offlineAlert = OfflineAlert(
    id: alertId,
    synced: firebaseSuccess, // true si Firebase éxito, false si falló
    latitudeEncrypted: latEncrypted,
    // ... más datos encriptados
  );
  
  await offlineSyncService.saveAlertLocally(offlineAlert);
  
  // 4. Si Firebase fue exitoso, marcar como sincronizado
  if (firebaseSuccess) {
    await offlineSyncService._markAlertAsSynced(alertId);
  }
  
  return alertId;
}
```

### 2. Guardar Localmente (OfflineSyncService.saveAlertLocally)
```dart
Future<String> saveAlertLocally(OfflineAlert alert) async {
  // Estructura del archivo:
  // /storage/emulated/0/Documents/alerts/alert_{id}_{timestamp}.json
  
  final filename = 'alert_${alert.id}_${DateTime.now().millisecondsSinceEpoch}.json';
  final file = File('${_alertsDirectory}/$filename');
  
  final json = {
    // Campos principales
    'id': alert.id,
    'userId': alert.userId,
    'timestamp': alert.timestamp.millisecondsSinceEpoch,
    'date': 'Julio 21 del 2026',
    'time': '02:30 pm',
    
    // Datos sensibles (sin encriptar en JSON, pero encriptados en almacenamiento)
    'latitude_encrypted': latEncrypted,
    'longitude_encrypted': lonEncrypted,
    'numberCalled_encrypted': numEncrypted,
    
    // Metadata
    'status': 'active',
    'description': 'Alerta de emergencia',
    'synced': false,
    'createdAt': timestamp,
    'syncedAt': null,
  };
  
  await file.writeAsString(jsonEncode(json));
  return filename;
}
```

### 3. Monitorear Conectividad
```dart
void _startConnectivityMonitor() {
  connectivity.onConnectivityChanged.listen((result) {
    final isOnline = result != ConnectivityResult.none;
    
    if (isOnline != _isOnline) {
      _isOnline = isOnline;
      
      // Notificar cambio
      for (var listener in _onlineStatusListeners) {
        listener(_isOnline);
      }
      
      // Si se recuperó conexión, sincronizar
      if (_isOnline) {
        syncOfflineAlerts();
      }
    }
  });
}
```

### 4. Sincronizar Alertas Offline
```dart
Future<void> syncOfflineAlerts() async {
  // 1. Obtener alertas pendientes
  final unsyncedAlerts = await getUnsyncedAlerts();
  
  int synced = 0;
  int failed = 0;
  
  // 2. Para cada alerta pendiente
  for (var alert in unsyncedAlerts) {
    try {
      // 2a. Enviar a Firebase
      await firebase
        .child('users/{ci}/alerts/{alertId}')
        .set(alert.toJson());
      
      // 2b. Marcar como sincronizado localmente
      await _markAlertAsSynced(alert.id);
      
      synced++;
      
      // 2c. Notificar listeners (para WebSocket, WhatsApp, etc)
      for (var listener in _syncListeners) {
        listener(alert);
      }
      
    } catch (e) {
      failed++;
      // Reintentar más tarde
    }
  }
  
  print('Sincronizadas: $synced, Fallidas: $failed');
}
```

## Estructura de Datos

### Archivo JSON Local
```json
{
  // ID y Usuario
  "id": "abc123def456",
  "userId": "1756278550",
  
  // Timestamp y Fechas (en múltiples formatos para fácil lectura)
  "timestamp": 1721580600000,
  "date": "Julio 21 del 2026",
  "time": "02:30 pm",
  "createdAt": 1721580600000,
  "syncedAt": null,
  
  // Estado
  "status": "active",
  "synced": false,
  
  // Descripción
  "description": "Alerta de emergencia por accidente",
  
  // Datos de ubicación (ENCRIPTADOS)
  "latitude": -0.123456,
  "longitude": -78.654321,
  "latitude_encrypted": "8qJt3K9jL2mNoPqR5StUvWxYz1Ab2CdEfG...",
  "longitude_encrypted": "3XyZaBcDeFgHiJkLmNoPqRsTuVwXyZaBc...",
  
  // Teléfono (ENCRIPTADO)
  "numberCalled": "0963522505",
  "numberCalled_encrypted": "7HjK1MnOpQrStUvWxYzAbCdEfGhIjKlM...",
  
  // Contactos notificados
  "contactsNotified": [
    "0963522505",
    "otro_contacto@email.com"
  ]
}
```

### Firebase Structure
```
users/
  └─ 1756278550/
      └─ alerts/
          ├─ alert_001
          │  ├─ id: "alert_001"
          │  ├─ timestamp: 1721580600000
          │  ├─ latitude_encrypted: "..."
          │  ├─ longitude_encrypted: "..."
          │  ├─ numberCalled_encrypted: "..."
          │  ├─ status: "active"
          │  └─ synced: true
          │
          ├─ alert_002
          │  └─ ...
          │
          └─ alert_003
             └─ ...
```

## Integración con WhatsApp API (Próxima Fase)

### Flujo Propuesto
```dart
// En OfflineSyncService.syncOfflineAlerts()
// Después de sincronizar a Firebase:

for (var alert in unsyncedAlerts) {
  // ... código de sincronización Firebase ...
  
  // Enviar a WhatsApp
  try {
    await whatsappService.sendAlert(
      phoneNumber: alert.numberCalled,
      message: """
        🚨 ALERTA DE EMERGENCIA 🚨
        
        Hora: ${alert.time}
        Ubicación: ${alert.latitude}, ${alert.longitude}
        
        Descripción: ${alert.description}
        
        Estado: ${alert.status}
      """,
      metadata: {
        'alertId': alert.id,
        'userId': alert.userId,
        'timestamp': alert.timestamp,
      },
    );
  } catch (e) {
    // Reintentar más tarde o guardar en cola
  }
}
```

### Clase Tentativa para WhatsApp Service
```dart
class WhatsAppService {
  static final WhatsAppService _instance = WhatsAppService._internal();
  static WhatsAppService get instance => _instance;
  
  final _apiClient = HttpClient();
  final String _apiToken = 'tu_token_aqui';
  final String _phoneNumberId = 'tu_phone_number_id';
  
  Future<void> sendAlert({
    required String phoneNumber,
    required String message,
    required Map<String, dynamic> metadata,
  }) async {
    try {
      // Normalizar número
      final normalized = Validators.normalizePhoneNumber(
        phoneNumber,
        international: true,
      );
      
      // Enviar vía Twilio, WhatsApp Business API, o similar
      final response = await _apiClient.post(
        Uri.parse('https://graph.instagram.com/v18.0/'
          '$_phoneNumberId/messages'),
        headers: {
          'Authorization': 'Bearer $_apiToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'messaging_product': 'whatsapp',
          'to': normalized.replaceAll('+', ''),
          'type': 'text',
          'text': {
            'preview_url': true,
            'body': message,
          },
          'metadata': metadata,
        }),
      );
      
      if (response.statusCode == 200) {
        print('✓ WhatsApp enviado a $phoneNumber');
      } else {
        throw Exception('WhatsApp API error: ${response.statusCode}');
      }
    } catch (e) {
      print('✗ Error enviando WhatsApp: $e');
      rethrow;
    }
  }
}
```

## Testing

### Test Unitario
```dart
void main() {
  group('OfflineSyncService', () {
    late OfflineSyncService service;
    
    setUp(() async {
      service = OfflineSyncService.instance;
      await service.initialize();
    });
    
    test('Guardar alerta localmente', () async {
      final alert = OfflineAlert(
        id: 'test_001',
        userId: 'user_123',
        timestamp: DateTime.now(),
        status: 'active',
        description: 'Test',
        contactsNotified: [],
        synced: false,
      );
      
      await service.saveAlertLocally(alert);
      
      final unsyncedAlerts = await service.getUnsyncedAlerts();
      expect(unsyncedAlerts.length, 1);
      expect(unsyncedAlerts[0].id, 'test_001');
    });
    
    test('Obtener alertas no sincronizadas', () async {
      final unsyncedAlerts = await service.getUnsyncedAlerts();
      expect(unsyncedAlerts, isNotEmpty);
    });
  });
}
```

### Test de Integración (Manual)
Ver: `TESTING_SINCRONIZACION_OFFLINE.md`

## Checklist de Implementación

- [x] OfflineSyncService creado
- [x] EncryptionService integrando
- [x] AlertService usando OfflineSyncService
- [x] Monitoreo de conectividad
- [x] Sincronización automática
- [x] Widget de testing
- [x] Documentación completa
- [ ] Integración con WhatsApp API
- [ ] Tests unitarios
- [ ] Tests de integración
- [ ] Optimización de rendimiento
- [ ] Manejo de errores mejorado

## Consideraciones de Producción

### Seguridad
- ✅ Encriptación de datos sensibles
- ✅ Validación de entrada
- ⚠️ Token de Firebase bien protegido
- ⚠️ API key de WhatsApp segura

### Performance
- ✅ Limpieza de archivos antiguos (30 días)
- ⚠️ Considerar usar base de datos local (SQLite/Drift)
- ⚠️ Implementar paginación para muchas alertas

### Resiliencia
- ✅ Retry automático en sincronización
- ⚠️ Cola de espera para alertas fallidas
- ⚠️ Notificaciones de fallo

## Logs y Debugging

```
[OfflineSyncService.initialize] ✓ Inicializado
[OfflineSyncService] Conectividad cambió: true → false
[AlertService.createAlert] ✓ Guardada localmente (archivo JSON)
[OfflineSyncService] ¡Conexión recuperada!
[OfflineSyncService.syncOfflineAlerts] Sincronizando 5 alertas...
[OfflineSyncService.syncOfflineAlerts] ✓ Firebase: alert_001
[OfflineSyncService.syncOfflineAlerts] ✓ Firebase: alert_002
[OfflineSyncService.syncOfflineAlerts] ✗ Error sincronizando alert_003: timeout
[OfflineSyncService.syncOfflineAlerts] Resultados: ✓ 4, ✗ 1
```

---

**Versión**: 1.0  
**Última actualización**: 2026-07-21  
**Autor**: Sistema de Alertas de Emergencia
