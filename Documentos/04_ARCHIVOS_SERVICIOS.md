# Archivos de Servicios - Arquitectura Tecnica

**Version:** 1.4.67  
**Fecha:** 20 de agosto de 2026  
**Estado:** Completo

---

## Indice

1. [Descripcion General](#descripcion-general)
2. [Servicios Disponibles](#servicios-disponibles)
3. [Firebase Service](#firebase-service)
4. [Alert Service](#alert-service)
5. [Rate Limiter](#rate-limiter)
6. [Appointment Reminder Service](#appointment-reminder-service)
7. [Encryption Service](#encryption-service)
8. [Secure Storage Service](#secure-storage-service)
9. [Servicios Adicionales](#servicios-adicionales)

---

## Descripcion General

Los **Servicios** son clases que manejan la **logica de negocio** y la **comunicacion con sistemas externos**. Actuan como intermediarios entre la interfaz de usuario (UI) y las fuentes de datos (Firebase, almacenamiento local, APIs).

**Localizacion:** `lib/services/`  
**Patrones Usados:** Singleton (instancia unica)  
**Estado:** Completo y produccion-ready

### Principios de Diseño

- **Centralizacion** - Un unico punto de acceso por servicio
- **Separacion** - Cada servicio tiene responsabilidad unica
- **Reutilizacion** - Servicios usados por multiples paginas
- **Testing** - Faciles de mockear para tests

---

## Servicios Disponibles

```
lib/services/
 firebase_service.dart (250+ lineas) CRITICO
 alert_service.dart (230+ lineas) CRITICO
 rate_limiter.dart (180+ lineas) IMPORTANTE
 appointment_reminder_service.dart (200+ lineas) NUEVO
 encryption_service.dart (120+ lineas) SEGURIDAD
 secure_storage_service.dart (155+ lineas) SEGURIDAD
 notification_service.dart (110+ lineas)
 contact_service.dart (120+ lineas)
 offline_sync_service.dart (650+ lineas) SINCRONIZACION
 sync_service.dart (80+ lineas)
```

---

## Firebase Service (CRITICO)

### Informacion General

| Atributo | Valor |
|----------|-------|
| **Ubicacion** | `lib/services/firebase_service.dart` |
| **Lineas de codigo** | 250+ |
| **Patron** | Singleton |
| **Estado** | Produccion |

### Responsabilidades

#### 1. Inicializacion de Firebase

```dart
Future<void> initialize()
// Inicializa:
// - Firebase Core
// - Firebase Analytics
// - Firebase Crashlytics
// - Firebase Cloud Messaging
// - Firebase Realtime Database
```

#### 2. Analytics (Rastreo de Eventos)

```dart
// Registra eventos de usuario
logEvent(name: 'emergency_activated', parameters: {
  'timestamp': DateTime.now(),
  'location': 'Quito',
});
```

#### 3. Crash Reporting

```dart
// Reporta errores automaticamente a Crashlytics
recordError(error, stackTrace);
```

#### 4. Notificaciones Push (FCM)

```dart
// Obtener token para notificaciones push
Future<String> getFCMToken()

// Subscribir a topicos
Future<void> subscribeTopic(String topic)

// Desuscribir de topicos
Future<void> unsubscribeTopic(String topic)
```

### Dependencias

| Tecnologia | Version | Uso |
|-----------|---------|-----|
| **firebase_core** | ^4.3.0 | Core de Firebase |
| **firebase_analytics** | ^12.1.0 | Eventos de usuario |
| **firebase_crashlytics** | ^5.0.6 | Reporte de errores |
| **firebase_messaging** | ^16.1.0 | Notificaciones push |
| **firebase_database** | ^12.1.1 | Base de datos en tiempo real |

### Tecnologias Firebase

- **Firebase Core** - Inicializacion
- **Firebase Analytics** - Eventos y metricas
- **Firebase Crashlytics** - Error reporting
- **Firebase Cloud Messaging** - Push notifications
- **Firebase Realtime Database** - Almacenamiento

### Ejemplo de Uso

```dart
// En main.dart
await FirebaseService.instance.initialize();

// Registrar evento
FirebaseService.instance.logEvent(
  name: 'emergency_activated',
  parameters: {'location': 'Quito, Ecuador'},
);

// Reportar error
try {
  // codigo que puede fallar
} catch (e, st) {
  FirebaseService.instance.recordError(e, st);
}

// Obtener token FCM
String token = await FirebaseService.instance.getFCMToken();

// Subscribir a topico
await FirebaseService.instance.subscribeTopic('emergencies');
```

---

## Alert Service (CRITICO)

### Informacion General

| Atributo | Valor |
|----------|-------|
| **Ubicacion** | `lib/services/alert_service.dart` |
| **Lineas de codigo** | 230+ |
| **Patron** | Singleton |
| **Estado** | Produccion |

### Responsabilidades

#### 1. Crear Alertas de Emergencia

```dart
Future<String> createAlert({
  required double latitude,
  required double longitude,
  required String description,
  String? location,
  List<String>? emergencyContacts,
})
```

#### 2. Recuperar Historial

```dart
Future<List<Alert>> getUserAlerts()
// Obtiene todas las alertas del usuario desde Firebase
```

#### 3. Actualizar Estado de Alerta

```dart
Future<void> updateAlertStatus(
  String alertId,
  AlertStatus newStatus, // 'active', 'resolved', 'false_alarm'
)
```

#### 4. Sincronizacion Offline

```dart
// Integracion con OfflineSyncService
// Guarda alertas locales si no hay conexion
// Sincroniza automaticamente al recuperar conexion
```

### Estructura de Datos

```dart
class Alert {
  String id; // ID unico
  DateTime timestamp; // Cuando se activo
  double latitude; // Latitud GPS
  double longitude; // Longitud GPS
  String? location; // Direccion legible
  String description; // Descripcion de emergencia
  List<String>? emergencyContacts; // Contactos notificados
  AlertStatus status; // Estado actual
  String userId; // ID del usuario
}

enum AlertStatus {
  active, // En progreso
  resolved, // Resuelta
  false_alarm, // Falsa alarma
}
```

### Integracion Firebase

- **Realtime Database** - Guardado de alertas
- **Cloud Functions** - Procesamiento en backend (futuro)
- **Storage** - Imagenes de evidencia (futuro)

### Ejemplo de Uso

```dart
// Crear alerta cuando usuario presiona boton de panico
try {
  String alertId = await AlertService.instance.createAlert(
    latitude: 0.3522,
    longitude: -78.5249,
    description: 'Dolor severo en el pecho',
    location: 'Calle 10 y Amazonas, Quito',
    emergencyContacts: ['0963522505', '0987654321'],
  );
  print('Alerta creada: $alertId');
} catch (e) {
  print('Error creando alerta: $e');
}

// Obtener historial de alertas
List<Alert> alerts = await AlertService.instance.getUserAlerts();
for (var alert in alerts) {
  print('${alert.timestamp}: ${alert.description}');
}

// Actualizar estado
await AlertService.instance.updateAlertStatus(
  alertId,
  AlertStatus.resolved,
);
```

---

## Rate Limiter (IMPORTANTE)

### Informacion General

| Atributo | Valor |
|----------|-------|
| **Ubicacion** | `lib/services/rate_limiter.dart` |
| **Lineas de codigo** | 180+ |
| **Patron** | Utilidad estatica |
| **Estado** | Produccion |
| **Ultima actualizacion** | 20 de agosto de 2026 |

### Responsabilidades

#### 1. Control de Intentos

```dart
Future<bool> canExecute({
  required String action,
  int maxAttempts = 4,
  int windowMinutes = 2,
})
// Verifica si se puede ejecutar una accion
// Usa ventana fija: contador se reinicia cuando expira
```

#### 2. Obtener Informacion

```dart
Future<RateLimitInfo> getInfo(String action)
// Retorna: intentos realizados, limites, tiempo disponible, etc
```

#### 3. Reset Manual

```dart
Future<void> reset(String action)
Future<void> resetAll()
// Para testing y debugging
```

### Modo Desarrollo

```dart
// En el archivo rate_limiter.dart
static const bool enableRateLimit = true; // Cambiar a false para deshabilitar

// Util para testing sin limites de intentos
// SIEMPRE true en produccion
```

### Estructura de Datos

```dart
class RateLimitInfo {
  int attemptsUsed; // Intentos realizados
  int maxAttempts; // Limite maximo
  int windowMinutes; // Duracion de la ventana
  bool isLimited; // Esta limitado?
  Duration? timeUntilNextAttempt; // Tiempo a esperar
  DateTime? nextAvailableTime; // Cuando esta disponible
  
  int get attemptsRemaining; // Intentos restantes calculados
  String get readableInfo; // Texto legible para UI
}
```

### Almacenamiento

- **SharedPreferences** - Persistencia local
- **Autolimpieza** - Intentos se expiran despues del tiempo
- **Ventana Fija** - Contador se reinicia con cada nueva ventana

### Configuracion Actual

```
Boton de Panico:
 - Maximo 4 intentos
 - En 2 minutos
 - Después de 2 minutos, el contador se reinicia a 0
```

### Ejemplo de Uso

```dart
// En main.dart - Verificar antes de activar emergencia
bool canActivate = await RateLimiter.canExecute(
  action: 'panic_button_main',
  maxAttempts: 4,
  windowMinutes: 2,
);

if (!canActivate) {
  // Mostrar mensaje: "Demasiados intentos, espere X minutos"
  RateLimitInfo info = await RateLimiter.getInfo(
    action: 'panic_button_main',
  );
  print('Reintentar en: ${info.timeUntilNextAttempt}');
} else {
  // Proceder con emergencia
  await activateEmergency();
}
```

---

## Appointment Reminder Service (NUEVO)

### Informacion General

| Atributo | Valor |
|----------|-------|
| **Ubicacion** | `lib/services/appointment_reminder_service.dart` |
| **Lineas de codigo** | 200+ |
| **Patron** | Singleton |
| **Estado** | Nuevo - 20 de agosto de 2026 |

### Responsabilidades

#### 1. Programar Recordatorios de Citas

```dart
Future<void> scheduleAppointmentReminder({
  required String appointmentId,
  required DateTime appointmentDateTime,
  required String doctorName,
  required String appointmentDate, // "23/12/2025"
  required String appointmentTime, // "14:30"
  int minutesBeforeReminder = 1440, // 24 horas (default)
})
```

#### 2. Cancelar Recordatorios

```dart
Future<void> cancelAppointmentReminder(String appointmentId)
Future<void> cancelAllReminders()
```

#### 3. Verificar Recordatorios Programados

```dart
Future<List<PendingNotificationRequest>> getPendingReminders()
Future<bool> isReminderScheduled(String appointmentId)
```

#### 4. Refrescar Recordatorios

```dart
Future<void> refreshReminders(List<Map<String, dynamic>> appointments)
// Reprograma automaticamente recordatorios basados en lista de citas
```

### Caracteristicas

- **Notificaciones Locales** - flutter_local_notifications
- **Programacion Automatica** - 24 horas antes de cita
- **Ajuste Inteligente** - Si la cita es en menos de 24h, programa en 5 minutos
- **Persistencia** - Los recordatorios se mantienen incluso al reiniciar app
- **Payload** - Lleva ID de cita para navegacion

### Ejemplo de Uso

```dart
// En options_page.dart - Cuando se agrega una cita
await AppointmentReminderService.instance.scheduleAppointmentReminder(
  appointmentId: 'cita_cardiologo_2026',
  appointmentDateTime: DateTime(2026, 12, 23, 14, 30),
  doctorName: 'Dr. Carlos Lopez',
  appointmentDate: '23/12/2026',
  appointmentTime: '14:30',
  minutesBeforeReminder: 1440, // 24 horas
);

// Cuando se elimina una cita
await AppointmentReminderService.instance
  .cancelAppointmentReminder('cita_cardiologo_2026');
```

### Integracion en main.dart

```dart
// En main() - Inicializar al arrancar la app
try {
  await AppointmentReminderService.instance.initialize();
  print('[AppointmentReminderService] Inicializado correctamente');
} catch (e) {
  print('[AppointmentReminderService] Error: $e');
}
```

### Permisos Requeridos

```xml
<!-- Android 13+: Requerido para notificaciones -->
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />

<!-- iOS: Agregado automaticamente por Flutter -->
```

---

## Encryption Service (SEGURIDAD)

### Informacion General

| Atributo | Valor |
|----------|-------|
| **Ubicacion** | `lib/services/encryption_service.dart` |
| **Lineas de codigo** | 120+ |
| **Patron** | Singleton |
| **Estado** | Produccion |

### Caracteristicas

- **Algoritmo:** AES-256 (estandar militar)
- **IV:** 128 bits (vector de inicializacion)
- **Formato:** Base64 (facil de almacenar)
- **Sin dependencias externas:** Solo 'encrypt' package

### Metodos Principales

```dart
void initialize()
// Inicializar con claves predefinidas

String encrypt(String value)
// Encripta un string
// Retorna: base64_encrypted_string

String decrypt(String encryptedValue)
// Desencripta un string

Map<String, String> encryptLocation(double? latitude, double? longitude)
// Encripta coordenadas GPS
// Retorna: {latitude_encrypted, longitude_encrypted}

Map<String, double?> decryptLocation(String? latEncrypted, String? lonEncrypted)
// Desencripta coordenadas
// Retorna: {latitude, longitude}
```

### Ejemplo de Uso

```dart
// En main.dart - Inicializar
EncryptionService.instance.initialize();

// Encriptar datos sensibles
String encryptedLat = EncryptionService.instance.encrypt('0.3522');
String encryptedLon = EncryptionService.instance.encrypt('-78.5249');

// Desencriptar
String lat = EncryptionService.instance.decrypt(encryptedLat);
String lon = EncryptionService.instance.decrypt(encryptedLon);

// Encriptar ubicacion completa
Map<String, String> encrypted = EncryptionService.instance
  .encryptLocation(0.3522, -78.5249);
// Retorna: {
//   latitude_encrypted: "base64...",
//   longitude_encrypted: "base64..."
// }
```

### Datos Encriptados

En `offline_sync_service.dart`, se encriptan:
- latitude
- longitude
- numberCalled

Esto protege la privacidad del usuario en alertas guardadas localmente.

---

## Secure Storage Service (SEGURIDAD)

### Informacion General

| Atributo | Valor |
|----------|-------|
| **Ubicacion** | `lib/services/secure_storage_service.dart` |
| **Lineas de codigo** | 155+ |
| **Patron** | Singleton |
| **Estado** | Produccion |

### Caracteristicas

- **Hardware Keystore:** Android KeyStore
- **Keychain:** iOS Keychain
- **Encriptacion a nivel SO:** Soportado por plataforma
- **Sin exposicion en memoria:** Datos seguros

### Metodos

```dart
Future<void> saveSecureData(String key, String value)
Future<String?> getSecureData(String key)
Future<void> deleteSecureData(String key)
Future<void> deleteAllSecureData()
```

### Datos Almacenados

- Cedula (CI) del usuario
- Nombre completo
- Numeros de contacto (si es necesario)
- Token de autenticacion (futuro)
- Claves de encriptacion

### Ejemplo de Uso

```dart
// Guardar datos sensibles
await SecureStorageService.instance.saveSecureData('user_ci', '1725632105');
await SecureStorageService.instance.saveSecureData('user_name', 'Juan Garcia');

// Recuperar datos
String? ci = await SecureStorageService.instance.getSecureData('user_ci');

// Eliminar datos
await SecureStorageService.instance.deleteSecureData('user_ci');

// Limpiar todo
await SecureStorageService.instance.deleteAllSecureData();
```

---

## Servicios Adicionales

### NotificationService

- Manejo de notificaciones push (FCM)
- Subscripcion a topicos
- Notificaciones locales
- Manejo de callbacks

### ContactService

- Manejo de contactos de emergencia
- Validacion de numeros
- Normalizacion de formatos
- Persistencia de contactos

### OfflineSyncService

- Sincronizacion automatica de alertas
- Deteccion de conectividad
- Almacenamiento local en JSON
- Encriptacion de datos locales
- Recuperacion automatica de conexion

### SyncService

- Sincronizacion general de datos
- Coordinacion entre servicios
- Manejo de conflictos de datos

---

## Diagrama de Integracion

```
main.dart (Inicializar servicios)
   |
   +-- FirebaseService (Analytics, Crashlytics)
   |
   +-- AppointmentReminderService (Recordatorios)
   |
   +-- NotificationService (FCM)
   |
   +-- EncryptionService (Encriptacion)
   |
+-- AlertService (Gestion de alertas)
   |
   +-- OfflineSyncService (Sincronizacion)
   +-- SecureStorageService (Almacenamiento)
   +-- Validators (Validaciones)
   +-- RateLimiter (Control de intentos)
```

---

**Nota:** Todos los servicios son thread-safe y pueden ser accedidos desde multiples widgets simultaneamente.

**Ultimo cambio:** 20 de agosto de 2026 - Agregado AppointmentReminderService completo.
