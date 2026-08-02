# Integración de Firebase en la Aplicación
**Última actualización:** 28 de julio de 2026  
**Versión:** 1.3.47  
**Estado:** Documentación de referencia
---

## Índice
1. [¿Qué es Firebase?](#qué-es-firebase)
2. [Servicios Firebase Utilizados](#servicios-firebase-utilizados)
3. [Cómo se Conecta a Firebase](#cómo-se-conecta-a-firebase)
4. [Cómo se Integra al Proyecto](#cómo-se-integra-al-proyecto)
5. [Para Qué se Integra](#para-qué-se-integra)
6. [Flujo de Datos en Firebase](#flujo-de-datos-en-firebase)
7. [Estructura de Datos en Firebase](#estructura-de-datos-en-firebase)
8. [Troubleshooting](#troubleshooting)

---

## ¿Qué es Firebase?

Firebase es una plataforma de Google que proporciona servicios backend para aplicaciones sin necesidad de gestionar servidores. En este proyecto utilizamos:

- **Realtime Database:** Base de datos en tiempo real para guardar alertas
- **Cloud Messaging (FCM):** Sistema de notificaciones push
- **Analytics:** Registro de eventos y comportamiento del usuario
- **Crashlytics:** Reporte automático de errores

---

## Servicios Firebase Utilizados

### 1. Realtime Database
```
Propósito: Almacenar alertas de emergencia
Ubicación: https://<tu-proyecto>.firebaseio.com/
Estructura: alerts/{timestamp}/
```

**Datos guardados:**
- Ubicación del usuario (latitud, longitud)
- Información médica del paciente
- Contactos notificados
- Timestamp de la alerta
- Número que se llamó

### 2. Cloud Messaging (FCM)
```
Propósito: Enviar notificaciones push al dispositivo
Token único por dispositivo
Permite notificaciones incluso con la app cerrada
```

**Casos de uso:**
- Recordatorios de citas médicas
- Notificaciones de alertas recibidas
- Mensajes de sincronización

### 3. Analytics
```
Propósito: Registrar eventos y analizar uso
Eventos capturados:
- emergency_activated: Cuando se activa botón de pánico
- app_opened: Cuando se abre la app
```

### 4. Crashlytics
```
Propósito: Registrar errores automáticamente
Ayuda a identificar problemas en producción
```

---

## Cómo se Conecta a Firebase

### Paso 1: Crear Proyecto en Firebase Console

1. Ve a [https://console.firebase.google.com/](https://console.firebase.google.com/)
2. Haz clic en "Crear un nuevo proyecto"
3. Nombre del proyecto: `flutter-app-emergencia`
4. Selecciona ubicación: Sudamérica o tu región

### Paso 2: Descargar Configuración

#### Para Android:
1. En Firebase Console → Configuración del proyecto
2. Pestaña: "Tus apps"
3. Selecciona tu app Android
4. Descarga `google-services.json`
5. Coloca en: `android/app/`

#### Para iOS:
1. En Firebase Console → Configuración del proyecto
2. Pestaña: "Tus apps"
3. Selecciona tu app iOS
4. Descarga `GoogleService-Info.plist`
5. Coloca en: `ios/Runner/`

### Paso 3: Configurar Dependencias

En el proyecto Flutter (`pubspec.yaml` ya está configurado):

```yaml
firebase_core: ^2.24.0           # Core de Firebase
firebase_database: ^10.1.0       # Realtime Database
firebase_messaging: ^14.6.0      # Cloud Messaging
firebase_analytics: ^10.5.0      # Analytics
firebase_crashlytics: ^3.3.0     # Crashlytics
```

Instalar:
```bash
flutter pub get
```

### Paso 4: Habilitar Servicios en Firebase Console

1. **Realtime Database:**
   - Firebase Console → Build → Realtime Database
   - Click "Create Database"
   - Región: Sudamérica
   - Modo: Test Mode (por ahora)

2. **Cloud Messaging:**
   - Firebase Console → Engage → Cloud Messaging
   - Debe estar habilitado automáticamente

3. **Analytics:**
   - Firebase Console → Analytics
   - Debe estar habilitado automáticamente

4. **Crashlytics:**
   - Firebase Console → Crashlytics
   - Click "Enable"

---

## Cómo se Integra al Proyecto

### 1. Inicialización en main.dart

```dart
// En main() antes de runApp()
try {
  await FirebaseService.instance.initialize();
  print('[main] Firebase inicializado correctamente');
} catch (e) {
  print('[main] ERROR al inicializar Firebase: $e');
}
```

### 2. Archivo Principal: FirebaseService

**Ubicación:** `lib/services/firebase_service.dart`

**Responsabilidades:**
- Inicializar Firebase Core
- Registrar eventos en Analytics
- Reportar errores a Crashlytics

```dart
class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();

  factory FirebaseService.instance {
    return _instance;
  }

  FirebaseService._internal();

  Future<void> initialize() async {
    await Firebase.initializeApp();
  }

  // Registrar evento
  Future<void> logEvent(String name, Map<String, String>? params) async {
    try {
      await FirebaseAnalytics.instance.logEvent(
        name: name,
        parameters: params,
      );
    } catch (e) {
      print('[FirebaseService] Error registrando evento: $e');
    }
  }

  // Reportar error
  Future<void> recordError(Object e, StackTrace st, {String? reason}) async {
    try {
      await FirebaseCrashlytics.instance.recordError(e, st, reason: reason);
    } catch (_) {}
  }
}
```

### 3. Integración con AlertService

**Ubicación:** `lib/services/alert_service.dart`

Se utiliza Firebase Realtime Database para guardar alertas:

```dart
class AlertService {
  final DatabaseReference _database = 
    FirebaseDatabase.instance.ref();

  Future<String> createAlert({
    required double? latitude,
    required double? longitude,
    List<String>? contactsNotified,
    String? description,
    String? numberCalled,
    // ... más campos
  }) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final alertData = {
      'timestamp': timestamp,
      'latitude': latitude,
      'longitude': longitude,
      'contactos_notificados': contactsNotified ?? [],
      'descripcion': description,
      'numero_llamado': numberCalled,
      // ... más campos
    };
    
    // Guardar en Firebase
    await _database.child('alerts').child(timestamp).set(alertData);
    return timestamp;
  }
}
```

### 4. Integración con NotificationService

**Ubicación:** `lib/services/notification_service.dart`

```dart
class NotificationService {
  Future<void> initialize() async {
    // Inicializar FCM
    await FirebaseMessaging.instance.requestPermission();
    
    // Obtener token del dispositivo
    String? token = await FirebaseMessaging.instance.getToken();
    print('[NotificationService] FCM Token: $token');
    
    // Escuchar mensajes
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('[NotificationService] Mensaje recibido: ${message.notification?.title}');
      // Mostrar notificación en foreground
    });
  }
}
```

### 5. Integración con AppointmentReminderService

**Ubicación:** `lib/services/appointment_reminder_service.dart`

Utiliza FCM para enviar recordatorios de citas médicas:

```dart
class AppointmentReminderService {
  Future<void> sendReminder(String appointmentId) async {
    // Enviar notificación push vía FCM
    // El servidor backend recibe esto y lo procesa
  }
}
```

---

## Para Qué se Integra

### 1. Guardar Alertas de Emergencia

**Problema:** Cuando se activa el botón de pánico, es necesario guardar la alerta en un servidor.

**Solución:** Firebase Realtime Database almacena:
- Ubicación GPS del usuario
- Información médica completa
- Timestamp exacto del evento
- Datos de los contactos notificados

**Flujo:**
```
Usuario presiona botón pánico
     ↓
InicioPage._activateEmergency() se ejecuta
     ↓
AlertService.createAlert() es llamado
     ↓
Datos se envían a Firebase Realtime Database
     ↓
Alert guardada en: /alerts/{timestamp}/
     ↓
Disponible para consulta posterior y análisis
```

### 2. Registrar Eventos y Analítica

**Problema:** Necesitamos entender cómo usan los usuarios la app.

**Solución:** Firebase Analytics registra:
- Cuándo se activan alertas
- Cuándo se abre la app
- Comportamiento general del usuario

**Código:**
```dart
await FirebaseService.instance.logEvent('emergency_activated', {
  'timestamp': DateTime.now().toIso8601String(),
  'has_location': _lastLocation != null ? '1' : '0',
});
```

**Consulta:** Ve a Firebase Console → Analytics para ver reportes.

### 3. Enviar Notificaciones Push

**Problema:** Los recordatorios de citas deben llegar incluso con la app cerrada.

**Solución:** Firebase Cloud Messaging (FCM):
- Cada dispositivo tiene un token único
- El servidor puede enviar mensajes a dispositivos específicos
- Las notificaciones se muestran automáticamente

**Casos de uso:**
- Recordatorio de cita médica 1 hora antes
- Notificación de alerta recibida
- Mensajes del sistema

### 4. Reportar Errores Automáticamente

**Problema:** Es difícil diagnosticar errores que ocurren en dispositivos de usuarios.

**Solución:** Firebase Crashlytics captura automáticamente:
- Excepciones no manejadas
- Stack traces completos
- Información del dispositivo

**Código:**
```dart
try {
  // Código que puede fallar
} catch (e) {
  FirebaseService.instance.recordError(
    e,
    StackTrace.current,
    reason: 'Error al guardar alerta en Firebase'
  );
}
```

**Consulta:** Ve a Firebase Console → Crashlytics para ver errores.

---

## Flujo de Datos en Firebase

### Flujo de una Alerta de Emergencia

```
[1] Usuario activa botón pánico en InicioPage
    ├─ Se obtiene ubicación GPS
    ├─ Se cargan datos médicos del usuario
    └─ Se obtiene contacto a llamar (911 o favorito)

[2] main._activateEmergency() valida rate limiting
    └─ ¿Ya activó 3 alertas en 2 minutos?

[3] Se registra evento en Analytics
    └─ FirebaseService.logEvent('emergency_activated', {...})

[4] Se crea alerta en Realtime Database
    ├─ AlertService.createAlert() prepara datos
    ├─ _database.child('alerts').child(timestamp).set(alertData)
    └─ Alert guardada en Firebase

[5] Se añade entrada en OptionsPage (historial local)
    └─ optionsPageKey.currentState.addAlert(...)

[6] Se realiza llamada telefónica
    └─ url_launcher inicia llamada a número elegido

[7] Se espera respuesta del usuario
    └─ Actualizar estado de rate limiting UI
```

### Flujo de Notificación de Cita

```
[1] AppointmentReminderService verifica citas próximas
    └─ Cada 15 minutos ejecuta verificación

[2] Si hay cita en 1 hora:
    ├─ Se obtiene el FCM token del dispositivo
    └─ Se prepara mensaje de notificación

[3] Se envía notificación vía FCM
    ├─ Firebase Cloud Messaging la entrega
    ├─ Si app está abierta: se muestra en foreground
    └─ Si app está cerrada: se muestra en bandeja del sistema

[4] Usuario toca la notificación
    └─ App se abre y muestra detalles de la cita
```

---

## Estructura de Datos en Firebase

### Nodo: /alerts/

```json
{
  "alerts": {
    "1721761200000": {
      "timestamp": "1721761200000",
      "latitude": -0.2234,
      "longitude": -78.5091,
      "ciudad": "Quito",
      "pais": "Ecuador",
      "nombres": "Juan",
      "apellidos": "Pérez",
      "edad": "45",
      "tipo_sangre": "O+",
      "patologias_catastroficas": ["Hipertensión", "Diabetes"],
      "condiciones_medicas": [
        {
          "tipo": "Diabetes",
          "descripcion": "Tipo 2"
        }
      ],
      "medicamentos": ["Metformina", "Lisinopril"],
      "alergias": ["Penicilina"],
      "sintomas": [
        {
          "sintoma": "Dolor de pecho",
          "duracion": "30 minutos"
        }
      ],
      "numero_llamado": "0963522505",
      "descripcion": "Alerta de pánico activada",
      "contactos_notificados": ["Contact1", "Contact2"]
    },
    "1721761300000": {
      // Otro registro de alerta...
    }
  }
}
```

### Permisos Recomendados (Firebase Rules)

```json
{
  "rules": {
    ".read": false,
    ".write": false,
    "alerts": {
      ".read": true,
      ".write": true
    },
    "user_data": {
      ".read": "auth != null",
      ".write": "auth != null && auth.uid == $uid"
    }
  }
}
```

---

## Configuración de Reglas de Seguridad

### Paso 1: Acceder a Firebase Console

1. Ve a [https://console.firebase.google.com/](https://console.firebase.google.com/)
2. Selecciona tu proyecto
3. Ve a **Build → Realtime Database**
4. Selecciona la pestaña **Rules**

### Paso 2: Copiar Reglas Seguras

Para desarrollo/testing:
```json
{
  "rules": {
    ".read": true,
    ".write": true
  }
}
```

Para producción (requiere autenticación):
```json
{
  "rules": {
    ".read": false,
    ".write": false,
    "alerts": {
      ".read": true,
      ".write": true
    }
  }
}
```

### Paso 3: Publicar

Click en botón **Publish** en la esquina inferior derecha.

---

## Troubleshooting

### Error: "Permission Denied"

**Síntoma:**
```
E/firebase-database: permission_denied: Custom claim "admin" is missing
```

**Causa:** Las reglas de Firebase no permiten lectura/escritura

**Solución:**
1. Ve a Firebase Console → Rules
2. Asegúrate que tengas:
```json
{
  "rules": {
    ".read": true,
    ".write": true
  }
}
```
3. Click Publish

---

### Error: "Firebase Not Initialized"

**Síntoma:**
```
E/flutter: PlatformException(error, Firebase has not been initialized, null)
```

**Causa:** FirebaseService no se inicializó en main()

**Solución:**
1. Verifica que main.dart tiene:
```dart
await FirebaseService.instance.initialize();
```
2. Ejecuta:
```bash
flutter clean
flutter pub get
flutter run
```

---

### Error: "google-services.json Not Found"

**Síntoma:**
```
E/flutter: google-services.json not found
```

**Causa:** El archivo de configuración no está en el lugar correcto

**Solución:**
1. Descarga google-services.json de Firebase Console
2. Coloca en: `android/app/google-services.json`
3. No en `android/google-services.json`

---

### Error: "FCM Token Empty"

**Síntoma:**
```
I/flutter: FCM token: null
```

**Causa:** FCM no se inicializó correctamente

**Solución:**
```bash
flutter clean
flutter pub get
flutter run
```

---

## Recursos Relacionados

- [FIREBASE_SETUP_2026.md](../FIREBASE_SETUP_2026.md) - Configuración rápida
- [TESTING_FCM_RESUMEN.md](../TESTING_FCM_RESUMEN.md) - Pruebas de notificaciones
- [TESTING_SINCRONIZACION_OFFLINE.md](../TESTING_SINCRONIZACION_OFFLINE.md) - Datos offline
- [09_ERRORES_COMUNES_APP.md](09_ERRORES_COMUNES_APP.md) - Errores de Firebase

---

## Próximos Pasos

1. [OK] Firebase está inicializado en main.dart
2. [OK] AlertService guarda alertas en Firebase
3. [OK] NotificationService maneja FCM
4. [TODO] Crear backend (Node.js o similar) para:
   - Procesar alertas
   - Enviar notificaciones a otros usuarios
   - Validar datos médicos
   - Implementar autenticación segura

---

## Resumen

**Firebase es el corazón backend de la aplicación:**

- **Realtime Database:** Almacena todas las alertas de emergencia
- **Cloud Messaging:** Envía notificaciones y recordatorios
- **Analytics:** Analiza uso y comportamiento
- **Crashlytics:** Reporta errores automáticamente

**Integración:** Se conecta automáticamente al inicializar la app en main.dart

**Propósito:** Garantizar que las alertas de emergencia se guarden, se analicen y se proporcionen recordatorios a los usuarios
