# Arquitectura Aplicada del Proyecto
**Versión:** 1.0 | **Fecha:** 21 de diciembre de 2025 | **Estado:** Producción
---
## Índice
1. [Introducción](#introducción)
2. [Arquitectura en Capas](#arquitectura-en-capas)
3. [Capa de Presentación](#capa-de-presentación)
4. [Capa de Servicios](#capa-de-servicios)
5. [Capa de Persistencia](#capa-de-persistencia)
6. [Capa de Integraciones](#capa-de-integraciones)
7. [Flujos de Datos](#flujos-de-datos)
8. [Diagrama Completo](#diagrama-completo)
---
## Introducción
La arquitectura del proyecto implementa un **modelo de capas (Layered Architecture)** que separa la aplicación en 4 niveles independientes, cada uno con responsabilidades claras.
### Principios Arquitectónicos
- **Separación de Responsabilidades** - Cada capa tiene una única razón para cambiar
- **Independencia de Capas** - Las capas superiores no conocen detalles de las inferiores
- **Testabilidad** - Cada capa puede testearse de forma aislada
- **Escalabilidad** - Fácil agregar nuevas funcionalidades sin afectar la estructura
- **Mantenibilidad** - Cambios en una capa no afectan a las demás
### Diagrama General
```
 CAPA 1: PRESENTACIÓN (UI)
 Widgets Flutter, interacción con usuario
 Comunica con
 CAPA 2: SERVICIOS (BUSINESS LOGIC)
 Reglas de negocio, orquestación
 Usa
 CAPA 3: PERSISTENCIA (DATA)
 Almacenamiento, recuperación de datos
 Se conecta con
 CAPA 4: INTEGRACIONES (EXTERNAL APIs)
 Firebase, GPS, Geocoding, etc
```
---
## Arquitectura en Capas
### Características Principales
| Característica | Descripción |
|---|---|
| **Total de Capas** | 4 (UI, Servicios, Datos, APIs) |
| **Dirección de Dependencias** | Hacia abajo () |
| **Comunicación** | Hacia arriba y abajo |
| **Flujo de Datos** | Descendente (request) y ascendente (response) |
### Dependencias
```
Capa 1 (UI) depende de Capa 2 (Servicios)
Capa 2 (Servicios) depende de Capa 3 (Persistencia)
Capa 3 (Persistencia) depende de Capa 4 (APIs)
Pero:
Capa 4 (APIs) NO depende de ninguna (nivel más bajo)
Capa 3 NO depende directamente de Capa 1 o 2
Capa 1 NO depende directamente de Capa 3 o 4
```
---
## Capa de Presentación
### Responsabilidad
Mostrar interfaz de usuario e interactuar con el usuario. **No contiene lógica de negocio**.
### Archivos
```
lib/
 main.dart (pantalla principal)
 senttings.dart (configuración)
 options.dart (historial y médico)
 documents.dart (documentos)
 symptoms.dart (síntomas)
 preferences.dart (configuración global)
```
### Componentes
| Componente | Tipo | Responsabilidad |
|-----------|------|-----------------|
| **Widgets** | StatefulWidget, StatelessWidget | Renderizar UI |
| **State** | Estado local | Gestionar estado de página |
| **ValueNotifier** | Observable | Reactividad global |
| **GlobalKey** | Acceso a widgets | Comunicación entre widgets |
### Ejemplo de Estructura
```dart
class InicioPage extends StatefulWidget {
 // Widget sin estado
 @override
 State<InicioPage> createState() => _InicioPageState();
}
class _InicioPageState extends State<InicioPage> {
 // Estado local de la página
 double _holdProgress = 0.0;
 Position? _lastLocation;
 String? _errorMessage;
 // Métodos que comunican con servicios
 void _activateEmergency() async {
 try {
 // Llamar a servicio (no contiene lógica)
 await AlertService.instance.createAlert(...);
 // Actualizar UI
 setState(() {
 _holdProgress = 0.0;
 });
 } catch (e) {
 setState(() {
 _errorMessage = e.toString();
 });
 }
 }
 @override
 Widget build(BuildContext context) {
 // Construir UI
 return Scaffold(
 appBar: AppBar(title: Text('Emergencia')),
 body: Center(
 child: GestureDetector(
 onLongPress: _activateEmergency,
 child: _buildPanicButton(),
 ),
 ),
 );
 }
}
```
### Qué SÍ hace esta capa?
 Renderizar widgets
 Captar interacciones (tap, swipe, long press)
 Mostrar diálogos y snackbars
 Navegar entre pantallas
 Mostrar/ocultar elementos
### Qué NO hace esta capa?
 Conectar a bases de datos
 Hacer llamadas HTTP
 Validar datos complejos
 Procesar o transformar datos
 Encriptar datos
---
## Capa de Servicios
### Responsabilidad
Implementar **reglas de negocio** y **orquestar operaciones** complejas. Actúa como mediador entre UI y datos.
### Ubicación
```
lib/services/
 firebase_service.dart (Firebase)
 alert_service.dart (Alertas)
 rate_limiter.dart (Control intentos)
 secure_storage_service.dart (Almacenamiento seguro)
 validators/validators.dart (Validadores)
 notification_service.dart (Notificaciones)
 appointment_reminder_service.dart (Citas)
 contact_service.dart (Contactos)
 encryption_service.dart (Encriptación)
 offline_sync_service.dart (Sincronización)
 sync_service.dart (Sincronización)
```
### Servicios Principales
#### 1. **FirebaseService**
```
Responsabilidades:
 Inicializar Firebase Core
 Gestionar Firebase Analytics
 Reportar errores a Crashlytics
 Manejar Cloud Messaging (FCM)
 Gestionar Realtime Database
```
#### 2. **AlertService**
```
Responsabilidades:
 Crear alertas de emergencia
 Guardar en Firebase DB
 Recuperar historial
 Actualizar estados de alertas
 Sincronizar con almacenamiento local
```
#### 3. **RateLimiter**
```
Responsabilidades:
 Verificar límite de intentos
 Gestionar ventana de tiempo
 Persistir contador de intentos
 Bloquear acciones excesivas
```
#### 4. **SecureStorageService**
```
Responsabilidades:
 Guardar datos encriptados
 Recuperar datos encriptados
 Limpiar datos sensibles
 Usar AndroidKeyStore/Keychain
```
#### 5. **Validators**
```
Responsabilidades:
 Validar emails
 Validar nombres
 Validar teléfonos Ecuador
 Normalizar números
 Validar edades
```
### Ejemplo de Servicio
```dart
class AlertService {
 // Singleton
 static final AlertService _instance = AlertService._internal();
 static AlertService get instance => _instance;
 AlertService._internal();
 // Métodos de negocio
 Future<String> createAlert({
 required double latitude,
 required double longitude,
 required String description,
 }) async {
 // 1. Validar datos
 if (description.isEmpty) {
 throw Exception('Descripción requerida');
 }
 // 2. Generar ID
 final alertId = _generateId();
 // 3. Encriptar datos sensibles
 final encrypted = EncryptionService.encrypt(description);
 // 4. Guardar en Firebase
 await FirebaseDatabase.instance.ref()
 .child('alerts')
 .child(alertId)
 .set({
 'id': alertId,
 'timestamp': DateTime.now().toIso8601String(),
 'location': {'lat': latitude, 'lon': longitude},
 'description': encrypted,
 'status': 'active',
 });
 // 5. Guardar backup local
 await _saveLocalBackup(alertId, {...});
 // 6. Registrar evento
 FirebaseService.instance.logEvent('alert_created', {
 'alert_id': alertId,
 'timestamp': DateTime.now().toIso8601String(),
 });
 return alertId;
 }
 Future<List<Alert>> getUserAlerts() async {
 // Obtener de Firebase + local
 // Sincronizar si hay conexión
 // Retornar lista consolidada
 }
 Future<void> updateAlertStatus(String alertId, AlertStatus status) async {
 // Actualizar en Firebase
 // Actualizar local
 // Sincronizar
 }
}
```
### Qué SÍ hace esta capa?
 Ejecutar lógica de negocio
 Orquestar operaciones complejas
 Validar datos
 Encriptar/desencriptar
 Comunicar con múltiples fuentes de datos
 Registrar eventos
 Manejar errores
### Qué NO hace esta capa?
 Renderizar UI
 Captar eventos del usuario
 Acceder directo a widgets
 Hacer llamadas HTTP directas sin abstracción
 Almacenar datos directamente
---
## Capa de Persistencia
### Responsabilidad
**Almacenar y recuperar datos** de distintas fuentes. Proporciona una interfaz consistente.
### Tipos de Almacenamiento
```
lib/ (implicit, via services)
 Firebase Realtime Database (Datos en la nube)
 SharedPreferences (Configuración local)
 SecureStorage (Datos sensibles encriptados)
 Archivos JSON (Historial offline)
```
### 1. Firebase Realtime Database
**Ubicación:** Cloud
**Contenido:** Alertas de emergencia
**Estructura:**
```json
{
 "alerts": {
 "alert_1": {
 "id": "alert_1",
 "timestamp": "2025-12-21T10:30:00Z",
 "location": {
 "lat": -0.3522,
 "lon": -78.5249
 },
 "description": "Dolor en el pecho",
 "status": "active"
 }
 }
}
```
### 2. SharedPreferences
**Ubicación:** Local (SQLite)
**Contenido:** Configuración y preferencias
**Ejemplos:**
```dart
// Guardar
final prefs = await SharedPreferences.getInstance();
prefs.setInt('rate_limit_attempts', 2);
prefs.setString('theme', 'dark');
prefs.setStringList('alerts_ids', ['alert_1', 'alert_2']);
// Recuperar
final attempts = prefs.getInt('rate_limit_attempts') ?? 0;
final theme = prefs.getString('theme') ?? 'light';
final alertIds = prefs.getStringList('alerts_ids') ?? [];
```
### 3. Flutter Secure Storage
**Ubicación:** Local (encriptado por OS)
**Contenido:** Datos sensibles
**Encriptación:**
- Android: AndroidKeyStore
- iOS: Keychain
**Ejemplo:**
```dart
final storage = FlutterSecureStorage();
// Guardar
await storage.write(
 key: 'emergency_contact',
 value: '0963522505', // Encriptado automáticamente
);
// Recuperar
final phone = await storage.read(key: 'emergency_contact');
// Desencriptado automáticamente
// Eliminar
await storage.delete(key: 'emergency_contact');
```
### 4. Archivos JSON
**Ubicación:** `/storage/emulated/0/Documents/alerts/`
**Contenido:** Historial de alertas (backup local)
**Ejemplo:**
```json
[
 {
 "id": "alert_1",
 "timestamp": "2025-12-21T10:30:00Z",
 "location": "Calle 10 y Amazonas, Quito",
 "description": "Emergencia médica",
 "status": "resolved"
 }
]
```
### Flujo de Persistencia
```
 Datos del User
SharedPrefs SecureStore JSON Firebase
(config) (sensible) (backup) (cloud)
```
---
## Capa de Integraciones
### Responsabilidad
Comunicar con **servicios externos** y **librerías de terceros**. Proporciona las APIs base.
### Librerías Integradas
#### 1. Firebase Suite
```dart
// Inicializar
await Firebase.initializeApp();
// Analytics
FirebaseAnalytics.instance.logEvent(
 name: 'emergency_activated',
 parameters: {...},
);
// Crashlytics
FirebaseCrashlytics.instance.recordError(error, stackTrace);
// Messaging (FCM)
String token = await FirebaseMessaging.instance.getToken();
// Database
await FirebaseDatabase.instance.ref('alerts').set({...});
```
#### 2. Geolocator (GPS)
```dart
// Solicitar permiso
LocationPermission permission = await Geolocator.requestPermission();
// Obtener ubicación
Position position = await Geolocator.getCurrentPosition(
 desiredAccuracy: LocationAccuracy.best,
);
```
#### 3. Geocoding (Dirección Coordenadas)
```dart
// Coordenadas a dirección
List<Placemark> placemarks = await placemarkFromCoordinates(
 -0.3522,
 -78.5249,
);
// Dirección a coordenadas
List<Location> locations = await locationFromAddress('Quito, Ecuador');
```
#### 4. URL Launcher (Llamadas)
```dart
// Realizar llamada
await launchUrl(Uri.parse('tel:911'));
// Abrir URL
await launchUrl(Uri.parse('https://example.com'));
// Enviar email
await launchUrl(Uri.parse('mailto:email@example.com'));
```
#### 5. Permission Handler (Permisos)
```dart
// Solicitar permiso
final status = await Permission.location.request();
if (status.isDenied) {
 print('Permiso denegado');
} else if (status.isPermanentlyDenied) {
 openAppSettings();
}
```
---
## Flujos de Datos
### Flujo 1: Activar Emergencia
```
Usuario presiona botón de pánico
 CAPA 1: UI (main.dart)
 Captura evento onLongPress
 Llama _activateEmergency()
 Verificar
 Rate Limit CAPA 2: SERVICIOS
 RateLimiter.canExecute()
 Geolocator.getCurrentPosition()
 Geocoding.placemarkFromCoordinates()
 AlertService.createAlert()
 FirebaseService.logEvent()
 Obtener
 ubicación CAPA 3: DATOS CAPA 4: APIs
 Guardar en BD Firebase DB
 Guardar local Geolocator
 Encriptar datos Geocoding
 Analytics
 Crashlytics
 Hacer llamada (911)
 Mostrar éxito en UI
```
### Flujo 2: Ver Historial de Alertas
```
Usuario abre OptionsPage
 CAPA 1: UI (options.dart)
 initState() llama _loadAlerts()
 CAPA 2: SERVICIOS
 AlertService.getUserAlerts()
 Sincronizar offline online
 CAPA 3: DATOS CAPA 4: APIs
 Leer SharedPref Firebase DB
 Leer JSON files Descargar alertas
 Desencriptar
 Consolidar datos
 CAPA 1: UI
 setState()
 Mostrar ListView
```
### Flujo 3: Guardar Configuración
```
Usuario ingresa teléfono en senttings.dart
 CAPA 1: UI (senttings.dart)
 Captura texto del TextField
 Llama _saveEmergencyContact()
 CAPA 2: SERVICIOS
 Validators.isValidPhone()
 Validators.normalizePhoneNumber()
 SecureStorageService.save...()
 CAPA 3: DATOS CAPA 4: APIs
 Encriptar datos (Sin acceso directo)
 Guardar seguro
 Mostrar "Guardado" en UI
```
---
## Diagrama Completo
### Arquitectura General
```
 APLICACIÓN FLUTTER
 CAPA 1: PRESENTACIÓN (UI Layer)
 main.dart (InicioPage)
 senttings.dart (SenttingsPage)
 options.dart (OptionsPage)
 documents.dart (DocumentsPage)
 symptoms.dart (SymptomsPage)
 preferences.dart (Configuración global)
 Llama métodos
 CAPA 2: SERVICIOS (Business Logic Layer)
 FirebaseService
 AlertService
 RateLimiter
 SecureStorageService
 Validators
 NotificationService
 [+ 5 servicios más]
 Lee/escribe datos
 CAPA 3: PERSISTENCIA (Data Layer)
 Firebase Realtime Database (cloud)
 SharedPreferences (local config)
 SecureStorage (datos sensibles)
 Archivos JSON (backup offline)
 Accede
 CAPA 4: INTEGRACIONES (External APIs Layer)
 Firebase Core
 Firebase Analytics
 Firebase Crashlytics
 Firebase Cloud Messaging (FCM)
 Firebase Database
 Geolocator (GPS)
 Geocoding
 URL Launcher
 Permission Handler
```
### Comunicación Entre Capas
```
CAPA 1 (UI)
 (request/método)
 CAPA 2 (Servicios)
 (request)
 CAPA 3 (Persistencia)
 (request)
 CAPA 4 (APIs)
 (response)
 CAPA 3 (Persistencia)
 (response)
 CAPA 2 (Servicios)
 (response/actualizar)
CAPA 1 (UI)
```
### Independencia de Capas
```
 Capa 1 no conoce:
 Detalles de Capa 2
 Detalles de Capa 3
 Detalles de Capa 4
 Capa 2 no conoce:
 Detalles de Capa 1
 Detalles de Capa 4
 Detalles de Capa 3
 Capa 3 no conoce:
 Detalles de Capa 1
 Detalles de Capa 2
 Detalles de Capa 4
 Capa 4:
 No conoce nada (es base)
```
---
## Decisiones Arquitectónicas
### 1. Por qué 4 capas?
**Análisis:**
- 2 capas: Muy simple, acoplamiento alto
- 3 capas: Estándar, pero mezclaba servicios con datos
- 4 capas: Separación clara, flexibilidad máxima
- 5+ capas: Demasiado complejo para este proyecto
**Decisión:** 4 capas
---
### 2. Singleton vs Inyección de Dependencias?
**Opciones:**
```dart
// Opción 1: Singleton (elegida)
await AlertService.instance.createAlert(...);
// Opción 2: Inyección explícita
class InicioPage {
 final AlertService alertService;
 InicioPage({required this.alertService});
}
// Opción 3: GetIt (Service Locator avanzado)
GetIt.I<AlertService>().createAlert(...);
```
**Razón:** Singleton es simple, accesible desde cualquier parte, y suficiente para el proyecto.
---
### 3. Firebase vs Otro Backend?
**Opciones:**
- Firebase (Elegida)
- Backend personalizado
- Supabase
- Parse
**Razones:**
- No requiere backend propio
- Escalable
- Seguro
- Integración fácil con Flutter
- Múltiples servicios integrados
---
### 4. Multiple Storages vs Uno Solo?
**Opciones:**
- Múltiples (elegida)
 - Firebase para cloud
 - SharedPreferences para config
 - SecureStorage para sensibles
 - JSON para offline
- Una sola solución
 - Más simple pero menos flexible
**Razón:** Múltiples storages permiten casos de uso específicos.
---
## Beneficios de Esta Arquitectura
### Separación de Responsabilidades
```
Cambio en Firebase
Solo afecta Capa 2 y 4
No afecta UI (Capa 1)
```
### Testabilidad
```dart
// Fácil testear cada capa
test('Validar teléfono Ecuador', () {
 expect(Validators.isValidPhone('0963522505'), true);
});
// Sin necesidad de Firebase
// Sin necesidad de widgets
```
### Reusabilidad
```dart
// AlertService usado por:
// - main.dart (crear alertas)
// - options.dart (ver historial)
// - appointment_reminder_service.dart
```
### Mantenibilidad
```
Nuevo requisito: "Sincronizar con WhatsApp"
Agregar nuevo servicio en Capa 2
Sin cambiar Capa 1, 3 o 4
```
### Escalabilidad
```
Agregar notificaciones por SMS:
 1. Nuevo servicio en Capa 2
 2. Usar en Capa 1
 3. Almacenar en Capa 3
 4. Integrar provider en Capa 4
```
---
## Comparación: Con vs Sin Arquitectura
### Sin Arquitectura (Monolítico)
```dart
class InicioPage extends StatefulWidget {
 @override
 State<InicioPage> createState() => _InicioPageState();
}
class _InicioPageState extends State<InicioPage> {
 void _activateEmergency() async {
 // TODO: Validar
 if (phone.isEmpty) return;
 // TODO: Obtener ubicación
 Position position = await Geolocator.getCurrentPosition();
 // TODO: Convertir a dirección
 List<Placemark> placemarks = await placemarkFromCoordinates(
 position.latitude,
 position.longitude,
 );
 // TODO: Guardar en Firebase
 await FirebaseDatabase.instance.ref()
 .child('alerts')
 .set({...});
 // TODO: Guardar local
 final prefs = await SharedPreferences.getInstance();
 prefs.setString('last_alert', jsonEncode({...}));
 // TODO: Registrar evento
 await FirebaseAnalytics.instance.logEvent(...);
 // TODO: Hacer llamada
 await launchUrl(Uri.parse('tel:911'));
 // TODO: Mostrar resultado
 setState(() {
 _showSuccess = true;
 });
 }
}
```
**Problemas:**
 100+ líneas en un solo método
 Imposible de testear
 Código repetido en otros widgets
 Difícil de mantener
 No reutilizable
### Con Arquitectura (Layered)
```dart
// CAPA 1: UI (simple y limpia)
class InicioPage extends StatefulWidget {
 @override
 State<InicioPage> createState() => _InicioPageState();
}
class _InicioPageState extends State<InicioPage> {
 void _activateEmergency() async {
 try {
 // Una sola línea: delegar a servicio
 await AlertService.instance.createAlert(...);
 setState(() {
 _showSuccess = true;
 });
 } catch (e) {
 setState(() {
 _errorMessage = e.toString();
 });
 }
 }
 @override
 Widget build(BuildContext context) {
 return Scaffold(...);
 }
}
```
**Ventajas:**
 Código UI limpio (solo 20 líneas)
 Lógica reutilizable (AlertService)
 Fácil testear cada componente
 Fácil mantener
 Fácil escalar
---
## Conclusión
La arquitectura en 4 capas proporciona:
 **Claridad** - Cada capa tiene una función clara
 **Flexibilidad** - Fácil cambiar implementaciones
 **Testabilidad** - Cada componente testeable
 **Mantenibilidad** - Cambios aislados por capa
 **Escalabilidad** - Crece sin complejidad exponencial
 **Reutilización** - Servicios usados múltiples veces
El proyecto está **listo para crecer** manteniendo la calidad del código.
---
**Última actualización:** 21 de julio de 2026
**Versión:** 1.4.60
**Estado:** Desarrollo
