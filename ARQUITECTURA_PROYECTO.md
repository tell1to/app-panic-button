# 📐 Arquitectura del Proyecto - App de Emergencia Ecuador

## 🎯 Visión General del Proyecto

**App de Emergencia Ecuador** es una aplicación Flutter para **dispositivos móviles** que permite a usuarios ecuatorianos activar alertas de emergencia con un botón de pánico, notificar contactos, registrar ubicación y mantener un historial de alertas médicas.

**Versión:** 1.1.1  
**Estado:** ✅ Completo y en Producción  
**Plataforma:** Android, iOS, Web  

---

## 🏗️ Arquitectura General: **Capas + MVC Adaptado**

El proyecto implementa una **Arquitectura en Capas (Layered Architecture)** combinada con patrones **MVC/MVVM**, que es estándar en Flutter:

```
┌─────────────────────────────────────────────────────────────┐
│                    CAPA DE PRESENTACIÓN (UI)                │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  • main.dart              (HomeScreen, InicioPage)   │   │
│  │  • senttings.dart        (SenttingsPage)            │   │
│  │  • options.dart          (OptionsPage)              │   │
│  │  • documents.dart        (DocumentsPage)            │   │
│  │  • symptoms.dart         (SymptomsPage)             │   │
│  │  • preferences.dart      (Preferences global)       │   │
│  └──────────────────────────────────────────────────────┘   │
│                           ▼                                   │
├─────────────────────────────────────────────────────────────┤
│              CAPA DE LÓGICA DE NEGOCIO (Services)            │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  • FirebaseService         (Análisis y errores)      │   │
│  │  • AlertService            (Gestión de alertas)      │   │
│  │  • NotificationService     (Notificaciones FCM)      │   │
│  │  • RateLimiter             (Control de intentos)     │   │
│  │  • AppointmentReminderService (Recordatorios)        │   │
│  │  • EncryptionService       (Encriptación)            │   │
│  │  • SyncService             (Sincronización)          │   │
│  │  • SecureStorageService    (Almacenamiento seguro)   │   │
│  │  • ContactService          (Gestión de contactos)    │   │
│  │  • Validators              (Validaciones)            │   │
│  └──────────────────────────────────────────────────────┘   │
│                           ▼                                   │
├─────────────────────────────────────────────────────────────┤
│            CAPA DE PERSISTENCIA Y DATOS (Storage)            │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  • Firebase Realtime Database    (Alertas en nube)   │   │
│  │  • SharedPreferences             (Datos locales)     │   │
│  │  • Flutter Secure Storage        (Datos sensibles)   │   │
│  │  • Archivos JSON                 (Historial local)   │   │
│  └──────────────────────────────────────────────────────┘   │
│                           ▼                                   │
├─────────────────────────────────────────────────────────────┤
│          CAPA DE INTEGRACIONES EXTERNAS (APIs)               │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  • Firebase Core           (Backend base)            │   │
│  │  • Firebase Analytics      (Eventos de usuario)      │   │
│  │  • Firebase Crashlytics    (Reporte de errores)      │   │
│  │  • Firebase Cloud Messaging (Notificaciones push)    │   │
│  │  • Geolocator             (Ubicación GPS)            │   │
│  │  • Geocoding              (Dirección a coordenadas)  │   │
│  │  • URL Launcher           (Llamadas telefónicas)     │   │
│  └──────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

---

## 📊 Tipo de Arquitectura: **Arquitectura en Capas + MVC**

### 🎨 1. **Capa de Presentación (UI - Presentation Layer)**

**Archivos:**
- `lib/main.dart` - Punto de entrada, HomeScreen con navegación
- `lib/senttings.dart` - Página de configuración y perfil
- `lib/options.dart` - Historial de alertas e información médica
- `lib/documents.dart` - Gestión de documentos médicos
- `lib/symptoms.dart` - Registro de síntomas
- `lib/preferences.dart` - Estados globales (ValueNotifier)

**Patrones usados:**
- **StatefulWidget** - Widgets con estado (InicioPage, OptionsPage)
- **StatelessWidget** - Widgets sin estado (HomeScreen)
- **ValueNotifier** - Estados globales reactivos
- **GlobalKey** - Acceso desde otros widgets
- **MediaQuery** - Responsive design

**Responsabilidad:**
- Mostrar la interfaz de usuario
- Captar interacciones del usuario
- Llamar a servicios de negocio
- Mostrar feedback visual

**Ejemplo de patrón:**
```dart
class InicioPage extends StatefulWidget {
  @override
  State<InicioPage> createState() => _InicioPageState();
}

class _InicioPageState extends State<InicioPage> {
  // UI state
  double _holdProgress = 0.0;
  Position? _lastLocation;
  
  // Llamar a servicio
  void _activateEmergency() async {
    // Usar RateLimiter
    final canActivate = await RateLimiter.canExecute(...);
    
    // Usar AlertService
    await AlertService.instance.createAlert(...);
  }
}
```

---

### 🔧 2. **Capa de Lógica de Negocio (Business Logic - Services Layer)**

**Servicios implementados:**

#### a) **FirebaseService** - Centraliza toda interacción con Firebase
```dart
class FirebaseService {
  static final _instance = FirebaseService._internal();
  
  // Singleton pattern
  static FirebaseService get instance => _instance;
  
  // Responsabilidades:
  Future<void> initialize()              // Iniciar Firebase
  void logEvent(String name, Map data)   // Analytics
  void recordError(e, stack, reason)     // Crashlytics
  Future<String> getFCMToken()           // Notificaciones
}
```

**Métodos:**
- `initialize()` - Inicializa Firebase Core, Analytics, Crashlytics, FCM
- `logEvent()` - Registra eventos de usuario
- `recordError()` - Reporta errores a Crashlytics
- `getFCMToken()` - Obtiene token para notificaciones
- `subscribeTopic()` / `unsubscribeTopic()` - Gestión de tópicos FCM

#### b) **AlertService** - Gestión de alertas de emergencia
```dart
class AlertService {
  static final _instance = AlertService._internal();
  static AlertService get instance => _instance;
  
  // Responsabilidades:
  Future<void> initializeFromStorage()   // Cargar CI del usuario
  Future<String> createAlert(...)        // Crear alerta
  Future<List<AlertModel>> getUserAlerts() // Obtener historial
  Future<void> updateAlertStatus(...)    // Actualizar estado
}
```

**Métodos:**
- `createAlert()` - Crea una alerta con ubicación, contactos, descripción
- `getUserAlerts()` - Obtiene historial del usuario desde Firebase
- `updateAlertStatus()` - Cambia estado (active → resolved → false_alarm)
- `initializeFromStorage()` - Carga CI para generar IDs únicos

#### c) **RateLimiter** - Control de intentos
```dart
class RateLimiter {
  static Future<bool> canExecute(
    String action, 
    int maxAttempts, 
    int windowMinutes
  )
  
  static Future<RateLimitInfo> getInfo(...)
}
```

**Lógica:**
- Guarda intentos en SharedPreferences
- Auto-expira intentos antiguos
- Configurable por acción (ej: panic_button_main)
- Límite actual: 4 intentos en 2 minutos

#### d) **SecureStorageService** - Almacenamiento seguro de datos sensibles
```dart
class SecureStorageService {
  static Future<void> saveUserProfile(ci, firstName, ...) // Guardar perfil
  static Future<String?> getCI()                          // Obtener CI
  static Future<Map<String, String?>> getUserProfile()   // Obtener perfil
}
```

**Usa:**
- AndroidKeyStore en Android
- Keychain en iOS
- Encriptación a nivel de OS

#### e) **NotificationService** - Notificaciones locales y FCM
```dart
class NotificationService {
  static NotificationService instance() // Singleton
  
  Future<void> initialize()              // Iniciar listener
  Future<void> showNotification(...)     // Mostrar local
}
```

#### f) **EncryptionService** - Cifrado de datos sensibles
```dart
class EncryptionService {
  String encrypt(String plaintext)       // Cifrar
  String decrypt(String encrypted)       // Descifrar
}
```

**Cifra:**
- Latitud/Longitud
- Número llamado
- Usa AES-256

#### g) **AppointmentReminderService** - Recordatorios de citas
```dart
class AppointmentReminderService {
  static AppointmentReminderService instance()
  
  Future<void> initialize()              // Iniciar servicio
  Future<void> scheduleReminder(...)    // Programar recordatorio
}
```

#### h) **SyncService** - Sincronización offline/online
```dart
class SyncService {
  Future<void> syncAlerts()              // Sincronizar alertas pendientes
  Future<List<AlertModel>> getOfflineAlerts() // Alertas sin sincronizar
}
```

#### i) **Validators** - Validaciones centralizadas
```dart
class Validators {
  static bool isValidPhone(String phone)
  static bool isValidEmail(String email)
  static bool isValidName(String name)
  static bool isValidAge(String age)
  static String normalizePhoneNumber(String phone)
}
```

**Validaciones para Ecuador:**
- Teléfono: Formatos 0963522505, +593963522505, etc.
- Email: RFC 5322 completo
- Nombre: Solo letras y espacios

---

### 💾 3. **Capa de Persistencia (Data Layer)**

**Tipos de almacenamiento:**

| Storage | Uso | Ubicación |
|---------|-----|-----------|
| **Firebase Realtime Database** | Alertas en la nube, sincronización | Backend remoto |
| **SharedPreferences** | Preferencias, configuración | Local (SQLite) |
| **Flutter Secure Storage** | CI, datos médicos, contactos | AndroidKeyStore / Keychain |
| **Archivos JSON** | Historial de alertas | `/storage/emulated/0/Documents/alerts` |

**Flujo de datos:**

```
┌─────────────┐
│   UI Input  │
└──────┬──────┘
       ▼
┌──────────────────────────┐
│   Service (LogicaApp)    │
└──────┬───────────────────┘
       ▼
┌──────────────────────────┐    ┌──────────────┐
│  Local Storage (Caché)   │───▶│  Firebase    │
│  SharedPreferences       │    │  Realtime DB │
│  Secure Storage          │    └──────────────┘
│  JSON Files              │
└──────────────────────────┘
```

---

### 🔗 4. **Capa de Integraciones Externas (External APIs)**

**Firebase:**
- `firebase_core` - Inicialización
- `firebase_analytics` - Tracking de eventos
- `firebase_crashlytics` - Reporte de errores
- `firebase_messaging` - Notificaciones push

**Ubicación:**
- `geolocator` - GPS
- `geocoding` - Dirección ↔ Coordenadas

**Sistema:**
- `url_launcher` - Llamadas telefónicas
- `file_selector` - Seleccionar archivos
- `path_provider` - Rutas del sistema
- `permission_handler` - Permisos

---

## 🔄 Flujo de Datos: Ejemplo Práctico

### Escenario: Usuario presiona botón de pánico

```
1. InicioPage._activateEmergency() [UI]
   ↓
2. RateLimiter.canExecute() [Service]
   └─ Verifica intentos en SharedPreferences
   └─ Si excede límite → muestra error → FIN
   ↓
3. FirebaseService.logEvent('emergency_activated') [Service]
   ├─ Envía evento a Analytics
   └─ Guarda en Firebase
   ↓
4. AlertService.createAlert() [Service]
   ├─ Obtiene ubicación actual (Geolocator)
   ├─ Convierte a dirección (Geocoding)
   ├─ Encripta datos sensibles (EncryptionService)
   ├─ Guarda en Firebase Realtime DB
   └─ Guarda copia local (JSON + SharedPreferences)
   ↓
5. NotificationService.showNotification() [Service]
   └─ Muestra notificación local
   ↓
6. _callNumber() [UI]
   └─ Inicia llamada telefónica (URL Launcher)
   ↓
7. OptionsPage.addAlert() [UI]
   └─ Añade entrada al historial visual
```

---

## 🧩 Patrones de Diseño Utilizados

### 1. **Singleton Pattern** (Servicios)
```dart
class FirebaseService {
  static final _instance = FirebaseService._internal();
  static FirebaseService get instance => _instance;
  FirebaseService._internal();
}
```

**Por qué:** Una única instancia de cada servicio en toda la app.

---

### 2. **Repository Pattern** (AlertService)
```dart
class AlertService {
  final _database = FirebaseDatabase.instance.ref();
  
  Future<String> createAlert(...) {
    // Abstrae la lógica de Firebase
  }
}
```

**Por qué:** Aísla la lógica de acceso a datos.

---

### 3. **Service Locator Pattern** (Inyección de dependencias)
```dart
// Acceso global
FirebaseService.instance
AlertService.instance
NotificationService.instance()
```

**Por qué:** Fácil acceso desde cualquier widget.

---

### 4. **Observer Pattern** (ValueNotifier)
```dart
final ValueNotifier<Map?> preferredContact = ValueNotifier(null);

// Escuchar cambios
preferredContact.addListener(() {
  // Reaccionar a cambios
});
```

**Por qué:** Actualización reactiva de UI cuando cambian datos.

---

### 5. **State Management Pattern** (StatefulWidget)
```dart
class InicioPage extends StatefulWidget {
  @override
  State<InicioPage> createState() => _InicioPageState();
}
```

**Por qué:** Gestión de estado local de cada página.

---

## 📦 Estructura de Carpetas

```
lib/
├── main.dart                          # Punto de entrada
├── senttings.dart                     # Configuración/Perfil
├── options.dart                       # Alertas/Médico
├── documents.dart                     # Documentos
├── symptoms.dart                      # Síntomas
├── preferences.dart                   # Estados globales
│
├── services/                          # Capa de negocio
│   ├── firebase_service.dart
│   ├── alert_service.dart
│   ├── notification_service.dart
│   ├── rate_limiter.dart
│   ├── appointment_reminder_service.dart
│   ├── encryption_service.dart
│   ├── secure_storage_service.dart
│   ├── sync_service.dart
│   ├── contact_service.dart
│   └── notification_test_service.dart
│
├── validators/                        # Reglas de negocio
│   └── validators.dart
│
└── test/                              # Tests automatizados
    ├── validators_ecuador_test.dart
    ├── rate_limiter_test.dart
    ├── notification_intervals_test.dart
    └── widget_test.dart
```

---

## 🌐 Integración con Firebase

```
┌─────────────────────────────────────────┐
│   Firebase Console (Backend)             │
├─────────────────────────────────────────┤
│                                          │
│  ┌──────────────────────────────────┐   │
│  │  Realtime Database (RTD)         │   │
│  │  └─ /users/{userId}/alerts/      │   │
│  │     └─ {alertId}                 │   │
│  └──────────────────────────────────┘   │
│                                          │
│  ┌──────────────────────────────────┐   │
│  │  Analytics                       │   │
│  │  └─ Events: emergency_activated  │   │
│  │              contact_added       │   │
│  │              app_opened          │   │
│  └──────────────────────────────────┘   │
│                                          │
│  ┌──────────────────────────────────┐   │
│  │  Crashlytics                     │   │
│  │  └─ Error tracking                │   │
│  │     Auto-reporting                │   │
│  └──────────────────────────────────┘   │
│                                          │
│  ┌──────────────────────────────────┐   │
│  │  Cloud Messaging (FCM)           │   │
│  │  └─ Notificaciones push          │   │
│  │     Topics: alerts_ecuador       │   │
│  └──────────────────────────────────┘   │
│                                          │
└─────────────────────────────────────────┘
           ▲           ▼
           │           │
    ┌──────┴───────────┴──────┐
    │  App Flutter (Cliente)   │
    └──────────────────────────┘
```

---

## 🔐 Seguridad en Capas

```
┌────────────────────────────────────┐
│  1. CAPA UI                        │
│  - Validación de entrada           │
│  - Rate limiting (pánico)          │
└──────────┬───────────────────────┘
           ▼
┌────────────────────────────────────┐
│  2. CAPA DE NEGOCIO (Services)     │
│  - Validaciones adicionales        │
│  - Encriptación de datos sensibles │
│  - Control de acceso               │
└──────────┬───────────────────────┘
           ▼
┌────────────────────────────────────┐
│  3. CAPA DE ALMACENAMIENTO         │
│  - SecureStorage (AndroidKeyStore) │
│  - SharedPreferences (encriptada)  │
│  - Firebase Rules (backend)        │
└──────────┬───────────────────────┘
           ▼
┌────────────────────────────────────┐
│  4. CAPA DE COMUNICACIÓN           │
│  - HTTPS/TLS (Firebase)            │
│  - Tokens FCM                      │
└────────────────────────────────────┘
```

---

## 📱 Responsabilidades por Capa

| Capa | Responsabilidad | No responsable de |
|------|-----------------|------------------|
| **UI** | Mostrar datos, captar input | Lógica de negocio, persistencia |
| **Servicios** | Lógica de negocio, validación | Renderizado, acceso directo a BD |
| **Persistencia** | Almacenar/recuperar datos | Decisiones de negocio |
| **APIs Externas** | Comunicación con servidores | Lógica local de la app |

---

## 🚀 Ventajas de Esta Arquitectura

✅ **Separación de responsabilidades** - Cada capa hace una cosa bien  
✅ **Testabilidad** - Cada servicio puede testearse independientemente  
✅ **Reusabilidad** - Los servicios se usan desde cualquier widget  
✅ **Mantenibilidad** - Cambios en una capa no afectan otras  
✅ **Escalabilidad** - Fácil agregar nuevos servicios  
✅ **Seguridad** - Control centralizado de datos sensibles  

---

## 🧪 Testing

```
test/
├── validators_ecuador_test.dart       # 35 tests
├── rate_limiter_test.dart            # 18 tests
├── notification_intervals_test.dart  # Tests de notificaciones
└── widget_test.dart                  # Tests de UI

✅ Total: 62 tests pasando
```

---

## 📊 Resumen de Arquitectura

| Aspecto | Implementación |
|--------|----------------|
| **Tipo de Arquitectura** | Layered + MVC |
| **Patrón Principal** | Singleton Services |
| **Estado Global** | ValueNotifier |
| **Inyección de Dependencias** | Service Locator |
| **Persistencia** | Multi-storage (Firebase + Local) |
| **Seguridad** | Encriptación + SecureStorage |
| **Testing** | 62+ tests automatizados |

---

## 📚 Documentación Relacionada

- [FIREBASE_SETUP_2026.md](FIREBASE_SETUP_2026.md) - Configuración de Firebase
- [RATE_LIMITER_DOCUMENTACION.md](RATE_LIMITER_DOCUMENTACION.md) - Rate Limiter
- [README_PROYECTO.md](README_PROYECTO.md) - Resumen general
- [PLAN_PRODUCCION.md](PLAN_PRODUCCION.md) - Plan de producción

---

## 🎓 Conclusión

La arquitectura del proyecto sigue **mejores prácticas de desarrollo móvil** con:

1. **Separación clara de capas** - Presentación, Negocio, Datos
2. **Patrones de diseño bien aplicados** - Singleton, Repository, Observer
3. **Seguridad en múltiples niveles** - Del UI al backend
4. **Escalabilidad** - Fácil de agregar nuevas funcionalidades
5. **Testing completo** - 62+ tests automatizados

Esto hace que la app sea **mantenible, segura y lista para producción**. ✅

---

**Última actualización:** 2026-07-06  
**Estado:** ✅ Completado y Documentado  
**Autor:** Equipo de Desarrollo
