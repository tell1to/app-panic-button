# Arquitectura Aplicada del Proyecto

**Version:** 1.4.67  
**Fecha:** 20 de agosto de 2026  
**Estado:** Produccion

---

## Indice

1. [Introduccion](#introduccion)
2. [Arquitectura en Capas](#arquitectura-en-capas)
3. [Capa de Presentacion](#capa-de-presentacion)
4. [Capa de Servicios](#capa-de-servicios)
5. [Capa de Persistencia](#capa-de-persistencia)
6. [Capa de Integraciones](#capa-de-integraciones)
7. [Flujos de Datos](#flujos-de-datos)
8. [Diagrama Completo](#diagrama-completo)

---

## Introduccion

La arquitectura del proyecto implementa un **modelo de capas (Layered Architecture)** que separa la aplicacion en 4 niveles independientes, cada uno con responsabilidades claras.

### Principios Arquitectonicos

- **Separacion de Responsabilidades** - Cada capa tiene una unica razon para cambiar
- **Independencia de Capas** - Las capas superiores no conocen detalles de las inferiores
- **Testabilidad** - Cada capa puede testearse de forma aislada
- **Escalabilidad** - Facil agregar nuevas funcionalidades sin afectar la estructura
- **Mantenibilidad** - Cambios en una capa no afectan a las demas

### Diagrama General

```
CAPA 1: PRESENTACION (UI)
  Widgets Flutter, interaccion con usuario
       |
       v (comunica con)
CAPA 2: SERVICIOS (BUSINESS LOGIC)
  Reglas de negocio, orquestacion
       |
       v (usa)
CAPA 3: PERSISTENCIA (DATA)
  Almacenamiento, recuperacion de datos
       |
       v (se conecta con)
CAPA 4: INTEGRACIONES (EXTERNAL APIs)
  Firebase, GPS, Geocoding, etc
```

---

## Arquitectura en Capas

### Caracteristicas Principales

| Caracteristica | Descripcion |
|---|---|
| **Total de Capas** | 4 (UI, Servicios, Datos, APIs) |
| **Direccion de Dependencias** | Hacia abajo (uni-direccional) |
| **Comunicacion** | Hacia arriba y abajo (bidireccional) |
| **Flujo de Datos** | Descendente (request) y ascendente (response) |

### Dependencias

```
Capa 1 (UI) depende de Capa 2 (Servicios)
Capa 2 (Servicios) depende de Capa 3 (Persistencia)
Capa 3 (Persistencia) depende de Capa 4 (APIs)

PERO:
Capa 4 (APIs) NO depende de ninguna (nivel mas bajo)
Capa 3 NO depende directamente de Capa 1 o 2
Capa 1 NO depende directamente de Capa 3 o 4
```

---

## Capa de Presentacion

### Responsabilidad

Mostrar interfaz de usuario e interactuar con el usuario. **No contiene logica de negocio**.

### Archivos

```
lib/
 main.dart (pantalla principal)
 screens/
   settings_page.dart (configuracion de perfil)
   options_page.dart (informacion medica)
   documents_page.dart (documentos)
   symptoms_page.dart (sintomas)
   tutorial_screen.dart (tutorial de bienvenida)
 utils/
   preferences.dart (configuracion global)
```

### Componentes

| Componente | Tipo | Responsabilidad |
|-----------|------|-----------------|
| **Widgets** | StatefulWidget, StatelessWidget | Renderizar UI |
| **State** | Estado local | Gestionar estado de pagina |
| **ValueNotifier** | Observable | Reactividad global |
| **GlobalKey** | Acceso a widgets | Comunicacion entre widgets |

### Ejemplo de Estructura

```dart
class InicioPage extends StatefulWidget {
  @override
  State<InicioPage> createState() => _InicioPageState();
}

class _InicioPageState extends State<InicioPage> {
  // Estado local de la pagina
  double _holdProgress = 0.0;
  Position? _lastLocation;
  String? _errorMessage;
  
  // Metodos que comunican con servicios
  void _activateEmergency() async {
    try {
      // Llamar a servicio (no contiene logica)
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

### Que SI hace esta capa

- Renderizar widgets
- Captar interacciones (tap, swipe, long press)
- Mostrar dialogos y snackbars
- Navegar entre pantallas
- Mostrar/ocultar elementos
- Actualizar UI reactivamente

### Que NO hace esta capa

- Conectar a bases de datos
- Hacer llamadas HTTP
- Validar datos complejos
- Procesar o transformar datos
- Encriptar datos
- Almacenar datos persistentemente

---

## Capa de Servicios

### Responsabilidad

Implementar **reglas de negocio** y **orquestar operaciones** complejas. Actua como mediador entre UI y datos.

### Ubicacion

```
lib/services/
 firebase_service.dart (Firebase)
 alert_service.dart (Alertas)
 rate_limiter.dart (Control intentos)
 appointment_reminder_service.dart (Citas)
 secure_storage_service.dart (Almacenamiento seguro)
 encryption_service.dart (Encriptacion)
 notification_service.dart (Notificaciones)
 offline_sync_service.dart (Sincronizacion)
 contact_service.dart (Contactos)
 sync_service.dart (Sincronizacion)
 utils/
   validators/validators.dart (Validadores)
```

### Servicios Principales

#### 1. **FirebaseService**

```
Responsabilidades:
 - Inicializar Firebase Core
 - Gestionar Firebase Analytics
 - Reportar errores a Crashlytics
 - Manejar Cloud Messaging (FCM)
 - Gestionar Realtime Database
```

#### 2. **AlertService**

```
Responsabilidades:
 - Crear alertas de emergencia
 - Guardar en Firebase DB
 - Recuperar historial
 - Actualizar estados de alertas
 - Sincronizar con almacenamiento local
```

#### 3. **RateLimiter**

```
Responsabilidades:
 - Verificar limite de intentos
 - Gestionar ventana de tiempo
 - Persistir contador de intentos
 - Bloquear acciones excesivas
```

#### 4. **AppointmentReminderService**

```
Responsabilidades:
 - Programar recordatorios de citas
 - Cancelar recordatorios
 - Verificar recordatorios pendientes
 - Usar notificaciones locales
```

#### 5. **SecureStorageService**

```
Responsabilidades:
 - Guardar datos encriptados
 - Recuperar datos encriptados
 - Limpiar datos sensibles
 - Usar AndroidKeyStore/Keychain
```

#### 6. **EncryptionService**

```
Responsabilidades:
 - Encriptar datos con AES-256
 - Desencriptar datos
 - Encriptar ubicacion (lat/lon)
 - Usar Base64 para almacenamiento
```

#### 7. **Validators**

```
Responsabilidades:
 - Validar emails
 - Validar nombres
 - Validar telefonos Ecuador
 - Normalizar numeros
 - Validar edades y cedulas
```

### Ejemplo de Servicio

```dart
class AlertService {
  // Singleton
  static final AlertService _instance = AlertService._internal();
  static AlertService get instance => _instance;
  AlertService._internal();
  
  // Metodos de negocio
  Future<String> createAlert({
    required double latitude,
    required double longitude,
    required String description,
    String? location,
    List<String>? emergencyContacts,
  }) async {
    // 1. Validar datos
    if (description.isEmpty) {
      throw Exception('Descripcion requerida');
    }
    
    // 2. Encriptar datos sensibles
    final encryptedLat = EncryptionService.instance
      .encrypt(latitude.toString());
    final encryptedLon = EncryptionService.instance
      .encrypt(longitude.toString());
    
    // 3. Guardar en Firebase
    final alertId = await _saveToFirebase({
      'latitude_encrypted': encryptedLat,
      'longitude_encrypted': encryptedLon,
      'description': description,
      'timestamp': DateTime.now().toIso8601String(),
    });
    
    // 4. Registrar evento
    FirebaseService.instance.logEvent(
      'emergency_created',
      {'alertId': alertId},
    );
    
    // 5. Sincronizar localmente
    await OfflineSyncService.instance.syncAlert(alertId);
    
    return alertId;
  }
}
```

---

## Capa de Persistencia

### Responsabilidad

Almacenar y recuperar datos de diferentes fuentes.

### Tecnologias

| Tecnologia | Uso | Datos |
|-----------|-----|-------|
| **Firebase Realtime DB** | Base de datos en nube | Alertas, historial |
| **SharedPreferences** | Almacenamiento local simple | Preferencias, configuracion |
| **Flutter Secure Storage** | Almacenamiento encriptado | CI, nombres, tokens |
| **JSON Files** | Almacenamiento local persistente | Alertas offline, historial |

### Ubicacion Datos

```
SharedPreferences:
 - profile_nombres (string)
 - profile_apellidos (string)
 - profile_edad (string)
 - user_contacts (JSON array)
 - main_favorite_index (int)
 - symptoms (JSON)
 
SecureStorage:
 - user_ci (string)
 - user_token (string)
 
Firebase RTDB:
 - /alerts/{alertId}
 - /users/{userId}
 
JSON Files (device storage):
 - Documents/alerts/alert_*.json
 - Documents/symptoms/*.json
```

---

## Capa de Integraciones

### Responsabilidad

Conectar con APIs y servicios externos.

### Servicios Externos

| Servicio | Proposito | Metodos |
|----------|----------|---------|
| **Firebase** | Backend, BD, analytics | Core, DB, Analytics, Messaging |
| **Geolocator** | Obtener ubicacion GPS | getCurrentPosition() |
| **Geocoding** | Convertir coords a direccion | placemarkFromCoordinates() |
| **URL Launcher** | Realizar llamadas | launchUrl() |
| **Permission Handler** | Solicitar permisos | request(), status |
| **Notification Handler** | Notificaciones locales | show(), schedule() |

---

## Flujos de Datos

### Flujo 1: Activar Emergencia

```
Usuario presiona boton panico (InicioPage)
    |
    v
_activateEmergency() solicita ubicacion (Capa UI)
    |
    v
Geolocator obtiene GPS (Capa Integraciones)
    |
    v
AlertService.createAlert() (Capa Servicios)
    |
    +-> EncryptionService.encrypt() (Capa Servicios)
    |
    +-> FirebaseService.logEvent() (Capa Servicios)
    |
    +-> Firebase RTD guarda alerta (Capa Persistencia)
    |
    v
RateLimiter.canExecute() valida limite (Capa Servicios)
    |
    v
URL Launcher realiza llamada (Capa Integraciones)
    |
    v
UI se actualiza (Capa UI)
```

### Flujo 2: Sincronizacion Offline

```
Usuario activa emergencia sin internet (InicioPage)
    |
    v
AlertService.createAlert() (Capa Servicios)
    |
    v
OfflineSyncService detecta sin conexion (Capa Servicios)
    |
    v
EncryptionService.encrypt() datos (Capa Servicios)
    |
    v
Guarda en JSON local (Capa Persistencia)
    |
    v
Se recupera conexion (Connectivity detecta)
    |
    v
OfflineSyncService.syncOfflineAlerts() (Capa Servicios)
    |
    v
Firebase RTD sincroniza (Capa Persistencia)
    |
    v
Archivo local marca como synced (Capa Persistencia)
```

### Flujo 3: Recordatorio de Cita

```
Usuario agrega cita en OptionsPage (Capa UI)
    |
    v
OptionsPage guarda cita en SharedPreferences (Capa Persistencia)
    |
    v
AppointmentReminderService.scheduleReminder() (Capa Servicios)
    |
    v
flutter_local_notifications programa notificacion (Capa Integraciones)
    |
    v
Sistema operativo programma notificacion (Sistema)
    |
    v (al llegar la hora)
Notificacion aparece en pantalla
    |
    v
Usuario toca notificacion
    |
    v
App navega a OptionsPage mostrando detalles
```

---

## Diagrama Completo

```
CAPA 1: PRESENTACION
┌─────────────────────────────────────┐
│ main.dart                           │
│ ├─ InicioPage (boton panico)       │
│ ├─ SettingsPage (perfil)           │
│ ├─ OptionsPage (medico)            │
│ ├─ SymptomsPage (sintomas)         │
│ ├─ TutorialScreen (bienvenida)     │
│ └─ preferences.dart (estado global)│
└─────────────────────────────────────┘
           |
           v (depende de)
┌─────────────────────────────────────┐
│ CAPA 2: SERVICIOS                   │
│ ├─ FirebaseService                 │
│ ├─ AlertService                    │
│ ├─ RateLimiter                     │
│ ├─ AppointmentReminderService      │
│ ├─ EncryptionService               │
│ ├─ SecureStorageService            │
│ ├─ NotificationService             │
│ ├─ OfflineSyncService              │
│ └─ Validators                      │
└─────────────────────────────────────┘
           |
           v (usa)
┌─────────────────────────────────────┐
│ CAPA 3: PERSISTENCIA                │
│ ├─ Firebase RTDB                   │
│ ├─ SharedPreferences               │
│ ├─ Secure Storage                  │
│ └─ JSON Files (local)              │
└─────────────────────────────────────┘
           |
           v (conecta con)
┌─────────────────────────────────────┐
│ CAPA 4: INTEGRACIONES               │
│ ├─ Firebase (Analytics, FCM)       │
│ ├─ Geolocator (GPS)                │
│ ├─ Geocoding                       │
│ ├─ URL Launcher (llamadas)         │
│ ├─ Permission Handler              │
│ └─ flutter_local_notifications     │
└─────────────────────────────────────┘
```

---

## Beneficios de esta Arquitectura

### 1. Separacion de Responsabilidades

- Cada capa tiene un proposito claro
- Cambios en una capa no afectan a otras
- Codigo mas comprensible y mantenible

### 2. Testabilidad

- Cada servicio puede mockearse
- Tests unitarios sin dependencias externas
- Tests de integracion sin emulador

### 3. Escalabilidad

- Facil agregar nuevas funcionalidades
- Nuevos servicios se integran rapidamente
- Estructura soporta crecimiento

### 4. Mantenibilidad

- Codigo organizado y predecible
- Bugs se localizan mas facilmente
- Refactoring es mas seguro

---

**Nota:** Esta arquitectura permite que el proyecto crezca de manera ordenada y sostenible.

**Ultimo cambio:** 20 de agosto de 2026 - Agregado AppointmentReminderService y flujos actualizados.
