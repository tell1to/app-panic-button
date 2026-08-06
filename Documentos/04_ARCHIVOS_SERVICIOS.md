# Archivos de Servicios - Arquitectura Técnica
**Versión:** 1.0 | **Fecha:** 21 de diciembre de 2025 | **Estado:** Completo
---
## Índice
1. [Descripción General](#descripción-general)
2. [Servicios Disponibles](#servicios-disponibles)
3. [Firebase Service](#firebase-service)
4. [Alert Service](#alert-service)
5. [Rate Limiter](#rate-limiter)
6. [Secure Storage Service](#secure-storage-service)
7. [Servicios Adicionales](#servicios-adicionales)
8. [Diagrama de Integración](#diagrama-de-integración)
---
## Descripción General
Los **Servicios** son clases que manejan la **lógica de negocio** y la **comunicación con sistemas externos**. Actúan como intermediarios entre la interfaz de usuario (UI) y las fuentes de datos (Firebase, almacenamiento local, APIs).
**Localización:** `lib/services/`
**Patrones Usados:** Singleton (instancia única)
**Estado:** Completo y producción-ready
### Principios de Diseño
- **Centralización** - Un único punto de acceso por servicio
- **Separación** - Cada servicio tiene responsabilidad única
- **Reutilización** - Servicios usados por múltiples páginas
- **Testing** - Fáciles de mockear para tests
---
## Servicios Disponibles
```
lib/services/
 firebase_service.dart (250+ líneas) CRÍTICO
 alert_service.dart (230+ líneas) CRÍTICO
 rate_limiter.dart (180+ líneas) IMPORTANTE
 secure_storage_service.dart (155+ líneas) SEGURIDAD
 appointment_reminder_service.dart (140+ líneas)
 contact_service.dart (120+ líneas)
 encryption_service.dart (100+ líneas)
 notification_service.dart (110+ líneas)
 notification_test_service.dart (90+ líneas)
 offline_sync_service.dart (650+ líneas) SINCRONIZACIÓN
 sync_service.dart (80+ líneas)
```
---
## Firebase Service CRÍTICO
### Información General
| Atributo | Valor |
|----------|-------|
| **Ubicación** | `lib/services/firebase_service.dart` |
| **Líneas de código** | 250+ |
| **Patrón** | Singleton |
| **Estado** | Producción |
### Responsabilidades
#### 1. Inicialización de Firebase
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
// Reporta errores automáticamente a Crashlytics
recordError(error, stackTrace);
```
#### 4. Notificaciones Push (FCM)
```dart
// Obtener token para notificaciones push
Future<String> getFCMToken()
// Subscribir a tópicos
Future<void> subscribeTopic(String topic)
// Desuscribir de tópicos
Future<void> unsubscribeTopic(String topic)
```
### Dependencias
| Tecnología | Versión | Uso |
|-----------|---------|-----|
| **firebase_core** | ^4.3.0 | Core de Firebase |
| **firebase_analytics** | ^12.1.0 | Eventos de usuario |
| **firebase_crashlytics** | ^5.0.6 | Reporte de errores |
| **firebase_messaging** | ^16.1.0 | Notificaciones push |
| **firebase_database** | ^12.1.1 | Base de datos en tiempo real |
### Tecnologías Firebase
- **Firebase Core** - Inicialización
- **Firebase Analytics** - Eventos y métricas
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
 // código que puede fallar
} catch (e, st) {
 FirebaseService.instance.recordError(e, st);
}
// Obtener token FCM
String token = await FirebaseService.instance.getFCMToken();
// Subscribir a tópico
await FirebaseService.instance.subscribeTopic('emergencies');
```
---
## Alert Service CRÍTICO
### Información General
| Atributo | Valor |
|----------|-------|
| **Ubicación** | `lib/services/alert_service.dart` |
| **Líneas de código** | 230+ |
| **Patrón** | Singleton |
| **Estado** | Producción |
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
#### 4. Sincronización Offline
```dart
// Integración con OfflineSyncService
// Guarda alertas locales si no hay conexión
```
### Estructura de Datos
```dart
class Alert {
 String id; // ID único
 DateTime timestamp; // Cuándo se activó
 double latitude; // Latitud GPS
 double longitude; // Longitud GPS
 String? location; // Dirección legible
 String description; // Descripción de emergencia
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
### Integración Firebase
- **Realtime Database** - Guardado de alertas
- **Cloud Functions** - Procesamiento en backend (futuro)
- **Storage** - Imágenes de evidencia (futuro)
### Ejemplo de Uso
```dart
// Crear alerta cuando usuario presiona botón de pánico
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
## Rate Limiter IMPORTANTE
### Información General
| Atributo | Valor |
|----------|-------|
| **Ubicación** | `lib/services/rate_limiter.dart` |
| **Líneas de código** | 180+ |
| **Patrón** | Utilidad estática |
| **Estado** | Producción |
### Responsabilidades
#### 1. Control de Intentos
```dart
Future<bool> canExecute({
 required String action,
 required int maxAttempts,
 required int windowHours,
})
// Verifica si se puede ejecutar una acción
```
#### 2. Obtener Información
```dart
Future<RateLimitInfo> getInfo(String action)
// Retorna: intentos restantes, tiempo disponible, etc
```
#### 3. Reset Manual
```dart
Future<void> reset(String action)
Future<void> resetAll()
// Para testing y debugging
```
### Estructura de Datos
```dart
class RateLimitInfo {
 int attempts; // Intentos realizados
 int maxAttempts; // Límite máximo
 bool isLimited; // Está limitado?
 DateTime? nextAvailableTime; // Cuándo está disponible
 Duration? waitTime; // Tiempo a esperar
}
```
### Almacenamiento
- **SharedPreferences** - Persistencia local
- **Autolimpieza** - Intenta se expiran después del tiempo
### Ejemplo de Uso
```dart
// En main.dart - Verificar antes de activar emergencia
bool canActivate = await RateLimiter.canExecute(
 action: 'panic_button_main',
 maxAttempts: 3,
 windowHours: 3,
);
if (!canActivate) {
 RateLimitInfo info = await RateLimiter.getInfo('panic_button_main');
 print('Intenta en: ${info.waitTime}');
 return;
}
// Proceder con alerta
```
---
## Secure Storage Service SEGURIDAD
### Información General
| Atributo | Valor |
|----------|-------|
| **Ubicación** | `lib/services/secure_storage_service.dart` |
| **Líneas de código** | 155+ |
| **Patrón** | Utilidad estática |
| **Estado** | Producción |
### Responsabilidades
#### 1. Guardar Datos Sensibles Encriptados
```dart
Future<void> saveEmergencyContact(String phone)
Future<void> saveMedicalInfo(String medicalInfo)
Future<void> saveAllergies(String allergies)
Future<void> saveUserProfile(ci, firstName, lastName)
```
#### 2. Recuperar Datos
```dart
Future<String?> getEmergencyContact()
Future<String?> getMedicalInfo()
Future<String?> getAllergies()
Future<Map<String, String?>> getUserProfile()
```
#### 3. Eliminar Datos
```dart
Future<void> deleteEmergencyContact()
Future<void> deleteMedicalInfo()
Future<void> clearAll()
```
### Encriptación
| Plataforma | Método | Seguridad |
|-----------|--------|----------|
| **Android** | AndroidKeyStore | Hardware KeyStore (si disponible) |
| **iOS** | Keychain | Secure Enclave |
| **Windows/macOS** | Almacenamiento OS | Encriptación del SO |
### Ejemplo de Uso
```dart
// Guardar contacto de emergencia de forma segura
String phone = Validators.normalizePhoneNumber(userInput);
await SecureStorageService.saveEmergencyContact(phone);
// Recuperar
String? savedPhone = await SecureStorageService.getEmergencyContact();
print('Contacto: $savedPhone');
// Guardar información médica
await SecureStorageService.saveMedicalInfo('Alérgico a Penicilina');
// Limpiar todo
await SecureStorageService.clearAll();
```
---
## Servicios Adicionales
### Appointment Reminder Service
| Función | Descripción |
|---------|-------------|
| `scheduleReminder()` | Programar recordatorio de cita |
| `cancelReminder()` | Cancelar recordatorio |
| `getAllReminders()` | Obtener todas las citas |
**Ubicación:** `lib/services/appointment_reminder_service.dart`
**Líneas:** 140+
**Dependencia:** `flutter_local_notifications`
---
### Contact Service
| Función | Descripción |
|---------|-------------|
| `saveContact()` | Guardar contacto de emergencia |
| `getContact()` | Recuperar contacto |
| `deleteContact()` | Eliminar contacto |
**Ubicación:** `lib/services/contact_service.dart`
**Líneas:** 120+
**Dependencia:** `contacts_service`
---
### Encryption Service
| Función | Descripción |
|---------|-------------|
| `encrypt()` | Encriptar string |
| `decrypt()` | Desencriptar string |
**Ubicación:** `lib/services/encryption_service.dart`
**Líneas:** 100+
**Encriptación:** AES-256
---
### Notification Service
| Función | Descripción |
|---------|-------------|
| `showNotification()` | Mostrar notificación local |
| `showAlert()` | Mostrar alerta visual |
**Ubicación:** `lib/services/notification_service.dart`
**Líneas:** 110+
**Dependencia:** `flutter_local_notifications`
---
### Offline Sync Service NUEVO
| Función | Descripción |
|---------|-------------|
| `saveOfflineAlert()` | Guardar alerta localmente |
| `syncOnlineAlerts()` | Sincronizar cuando hay conexión |
| `getOfflineAlerts()` | Obtener alertas offline |
**Ubicación:** `lib/services/offline_sync_service.dart`
**Líneas:** 650+
**Encriptación:** AES-256 para datos locales
**Almacenamiento:** Archivos JSON en `Documentos/offline_alerts/`
---
## Diagrama de Integración
```
 INTERFAZ DE USUARIO
 main.dart senttings.dart options.dart documents.dart
 Firebase Alert Rate Limiter
 Service Service
 CAPA DE ALMACENAMIENTO
 Firebase SharedPrefs Secure
 Database Storage
 Offline Sync Encryption Local
 Service Service JSON Files
```
---
## Flujo de Datos: Emergencia Activada
```
1. Usuario presiona botón (main.dart)
2. Verifica Rate Limiter
3. Obtiene ubicación GPS
4. Crea Alerta en AlertService
5. AlertService guarda en Firebase Database
6. FirebaseService registra evento en Analytics
7. Contactos se notifican (via Cloud Functions - futuro)
8. Historial se muestra en options.dart
```
---
## Inicialización en main.dart
```dart
void main() async {
 WidgetsFlutterBinding.ensureInitialized();
 // 1. Solicitar permisos de ubicación
 await Geolocator.requestPermission();
 // 2. Inicializar Firebase
 await FirebaseService.instance.initialize();
 // 3. Inicializar servicios de notificaciones
 await NotificationService.instance.initialize();
 // 4. Cargar preferencias
 await Preferences.loadPreferences();
 // Iniciar app
 runApp(const MyApp());
}
```
---
## Patrones de Diseño Usados
### 1. Singleton Pattern
```dart
class FirebaseService {
 static final FirebaseService _instance = FirebaseService._internal();
 static FirebaseService get instance => _instance;
 FirebaseService._internal();
}
// Uso: FirebaseService.instance.initialize();
```
### 2. Async/Await Pattern
```dart
Future<void> createAlert(...) async {
 // Operaciones asincrónicas
 await Firebase.database().ref().set(...);
}
```
### 3. Error Handling Pattern
```dart
try {
 await AlertService.instance.createAlert(...);
} catch (e, stackTrace) {
 FirebaseService.instance.recordError(e, stackTrace);
}
```
---
## Tecnologías Relacionadas
### Firebase (Crítico)
- **Realtime Database** - AlertService
- **Cloud Messaging** - FirebaseService
- **Analytics** - Todos los servicios
- **Crashlytics** - Reportes de error
### Flutter
- Todos los servicios usan APIs Flutter
- Async/await para operaciones no-bloqueantes
- Stream para datos en tiempo real
### Android
- **AndroidKeyStore** - SecureStorageService
- **Geolocation** - AlertService
- **Notifications** - NotificationService
### iOS
- **Keychain** - SecureStorageService (equivalente)
- **CoreLocation** - Geolocation
- **UserNotifications** - Notificaciones
### Dependencias Externas
- `firebase_core`, `firebase_analytics`, `firebase_crashlytics`
- `firebase_database`, `firebase_messaging`
- `flutter_secure_storage`
- `geolocator`, `geocoding`
- `flutter_local_notifications`
---
## Resumen de Servicios
| Servicio | Líneas | Firebase | Crítico | Estado |
|----------|--------|----------|---------|--------|
| **FirebaseService** | 250+ | | | Prod |
| **AlertService** | 230+ | | | Prod |
| **RateLimiter** | 180+ | | | Prod |
| **SecureStorageService** | 155+ | | | Prod |
| **AppointmentReminderService** | 140+ | | | Prod |
| **ContactService** | 120+ | | | Prod |
| **EncryptionService** | 100+ | | | Prod |
| **NotificationService** | 110+ | | | Prod |
| **OfflineSyncService** | 650+ | | | Prod |
---
## Próximos Pasos
1. **Para Cloud Functions:** Implementar procesamiento backend
2. **Para autenticación:** Integrar Firebase Auth
3. **Para storage:** Usar Firebase Cloud Storage para imágenes
4. **Para webhooks:** Integrar WhatsApp API
---
**Última actualización:** 21 de julio de 2026
**Versión:** 1.4.60
**Estado:** Desarrollo
