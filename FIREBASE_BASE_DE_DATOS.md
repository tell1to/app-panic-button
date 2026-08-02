# Firebase - Base de Datos y Servicios

**Fecha de Actualización:** 28 de julio de 2026  
**Estado:** ✅ Configurado y Funcional

---

## 📋 Tabla de Contenidos
1. [¿Cómo se Conecta a Firebase?](#cómo-se-conecta-a-firebase)
2. [¿Cómo se Integra al Proyecto?](#cómo-se-integra-al-proyecto)
3. [¿Para Qué se Integra?](#para-qué-se-integra)

---

## ¿Cómo se Conecta a Firebase?

### 1. **Crear un Proyecto en Firebase Console**

1. Accede a [Firebase Console](https://console.firebase.google.com/)
2. Haz clic en **"Crear proyecto"**
3. Ingresa el nombre del proyecto: `app-panic-button-c2a60`
4. Acepta los términos y crea el proyecto

### 2. **Descargar las Credenciales de Configuración**

#### Para Android:
1. En Firebase Console → **Configuración del proyecto** → pestaña **"Integraciones de Google Play"**
2. Haz clic en **"Agregar aplicación"** → **Android**
3. Ingresa:
   - **Nombre del paquete:** `com.example.flutter_application_1`
   - **Alias de la aplicación:** `flutter_application_1`
4. Descarga el archivo `google-services.json`
5. Coloca el archivo en: `android/app/google-services.json`

#### Para iOS:
1. En Firebase Console → **Configuración del proyecto** → pestaña **"Integraciones de Google Play"**
2. Haz clic en **"Agregar aplicación"** → **iOS**
3. Ingresa el **Bundle ID** de tu aplicación
4. Descarga `GoogleService-Info.plist`
5. Arrastra el archivo a Xcode en: `ios/Runner`

### 3. **Crear la Base de Datos Realtime**

1. En Firebase Console → **Build** → **Realtime Database**
2. Haz clic en **"Create Database"**
3. Selecciona la región: **Sudamérica (South America)**
4. Modo de seguridad: **Test mode** (para desarrollo)
5. Haz clic en **"Create"**

### 4. **Configurar Reglas de Seguridad**

1. Ve a **Realtime Database** → pestaña **"Rules"**
2. Reemplaza todo el contenido con:

```json
{
  "rules": {
    ".read": true,
    ".write": true
  }
}
```

3. Haz clic en **"Publish"**

> **Nota:** Estas reglas son para desarrollo. En producción, debes implementar autenticación y reglas más restrictivas.

### 5. **Habilitar Cloud Messaging (FCM)**

1. En Firebase Console → **Grow** → **Messaging**
2. Haz clic en **"Create Campaign"** (esto habilita FCM)
3. Obtén la **Server Key** en: **Configuración del proyecto** → pestaña **"Cloud Messaging"**

---

## ¿Cómo se Integra al Proyecto?

### 1. **Agregar Dependencias en pubspec.yaml**

```yaml
dependencies:
  firebase_core: ^4.3.0           # Núcleo de Firebase
  firebase_analytics: ^12.1.0     # Análisis y seguimiento
  firebase_crashlytics: ^5.0.6    # Reporte de errores
  firebase_messaging: ^16.1.0     # Notificaciones push
  firebase_database: ^12.1.1      # Realtime Database
```

Para instalar:
```bash
flutter pub get
```

### 2. **Inicializar Firebase en main.dart**

```dart
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'services/firebase_service.dart';

void main() async {
  // Permitir que Flutter acceda a servicios nativos
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar Firebase
  await FirebaseService.instance.initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Panic Button App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const HomePage(),
    );
  }
}
```

### 3. **Crear el Servicio Firebase Centralizado**

Archivo: `lib/services/firebase_service.dart`

```dart
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();

  static FirebaseService get instance => _instance;

  late FirebaseAnalytics _analytics;
  late FirebaseMessaging _messaging;
  bool _isInitialized = false;

  FirebaseService._internal();

  /// Inicializar todos los servicios de Firebase
  Future<void> initialize() async {
    if (_isInitialized) {
      print('✓ Firebase ya fue inicializado');
      return;
    }

    try {
      print('Inicializando Firebase...');

      // Inicializar Firebase Core
      await Firebase.initializeApp();
      print('✓ Firebase Core inicializado');

      // Configurar Analytics
      _analytics = FirebaseAnalytics.instance;
      await _analytics.logAppOpen();
      print('✓ Analytics inicializado');

      // Configurar Crashlytics
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
      FlutterError.onError = (errorDetails) {
        FirebaseCrashlytics.instance.recordFlutterError(errorDetails);
      };
      print('✓ Crashlytics inicializado');

      // Configurar Cloud Messaging
      _messaging = FirebaseMessaging.instance;
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('✓ Permisos de notificaciones otorgados');
      }

      _isInitialized = true;
      print('✓ Firebase completamente inicializado');

    } catch (e) {
      print('✗ Error al inicializar Firebase: $e');
    }
  }

  /// Obtener la instancia de Analytics
  FirebaseAnalytics get analytics => _analytics;

  /// Obtener la instancia de Messaging
  FirebaseMessaging get messaging => _messaging;

  /// Verificar si Firebase está inicializado
  bool get isInitialized => _isInitialized;
}
```

### 4. **Crear el Servicio de Alertas (Ejemplo de Uso)**

Archivo: `lib/services/alert_service.dart`

```dart
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AlertService {
  static final AlertService _instance = AlertService._internal();
  static AlertService get instance => _instance;

  late DatabaseReference _alertsRef;
  late SharedPreferences _prefs;

  AlertService._internal();

  /// Inicializar el servicio de alertas
  Future<void> initialize() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      _alertsRef = FirebaseDatabase.instance.ref('alerts');
      print('✓ AlertService inicializado');
    } catch (e) {
      print('✗ Error al inicializar AlertService: $e');
    }
  }

  /// Crear una nueva alerta de emergencia
  Future<void> createAlert({
    required String userId,
    required String title,
    required String description,
    required double latitude,
    required double longitude,
  }) async {
    try {
      final alertId = _alertsRef.push().key;
      final timestamp = DateTime.now().toIso8601String();

      // Guardar en Firebase Realtime Database
      await _alertsRef.child(alertId!).set({
        'userId': userId,
        'title': title,
        'description': description,
        'latitude': latitude,
        'longitude': longitude,
        'timestamp': timestamp,
        'status': 'active',
      });

      // Guardar también en almacenamiento local (backup)
      await _prefs.setString('last_alert_$alertId', timestamp);

      print('✓ Alerta guardada en Firebase: $alertId');
    } catch (e) {
      print('✗ Error al guardar alerta: $e');
    }
  }

  /// Obtener alertas del usuario
  Future<List<Map<String, dynamic>>> getUserAlerts(String userId) async {
    try {
      final snapshot = await _alertsRef
          .orderByChild('userId')
          .equalTo(userId)
          .get();

      final alerts = <Map<String, dynamic>>[];
      if (snapshot.exists) {
        for (var child in snapshot.children) {
          alerts.add(Map<String, dynamic>.from(child.value as Map));
        }
      }

      return alerts;
    } catch (e) {
      print('✗ Error al obtener alertas: $e');
      return [];
    }
  }
}
```

---

## ¿Para Qué se Integra?

### 1. **Realtime Database**
- **Propósito:** Almacenar y sincronizar datos de emergencias en tiempo real
- **Casos de Uso:**
  - Guardar alertas de emergencia activadas
  - Sincronizar ubicación en tiempo real con el servidor
  - Compartir información entre múltiples dispositivos
  - Recuperar historial de alertas

### 2. **Analytics**
- **Propósito:** Rastrear el comportamiento de los usuarios y eventos importantes
- **Casos de Uso:**
  - Contar cuántas alertas se activan por día/semana/mes
  - Identificar horas pico de emergencias
  - Medir retención de usuarios
  - Detectar patrones de uso

### 3. **Crashlytics**
- **Propósito:** Reportar y diagnosticar errores en tiempo real
- **Casos de Uso:**
  - Detectar crashes de la aplicación automáticamente
  - Recibir alertas cuando algo falla
  - Analizar stack traces para identificar problemas
  - Monitorear la salud de la aplicación

### 4. **Cloud Messaging (FCM)**
- **Propósito:** Enviar notificaciones push a los usuarios
- **Casos de Uso:**
  - Notificar a los usuarios sobre alertas activas
  - Enviar mensajes de confirmación de emergencia
  - Alertar sobre actualizaciones importantes
  - Mantener contacto con respuestas de emergencia

### 5. **Authentication (Opcional)**
- **Propósito:** Autenticar y autorizar usuarios
- **Casos de Uso:**
  - Validar identidad de usuarios
  - Implementar login seguro
  - Proteger datos sensibles por usuario

---

## 📊 Estructura de Datos en Firebase

### Base de Datos Realtime (JSON)
```json
{
  "alerts": {
    "-Nu12345xyz": {
      "userId": "user_001",
      "title": "Emergencia - Robo",
      "description": "Robo en progreso",
      "latitude": -0.22985,
      "longitude": -78.52495,
      "timestamp": "2026-07-28T10:30:00Z",
      "status": "active"
    },
    "-Nu67890abc": {
      "userId": "user_002",
      "title": "Emergencia Médica",
      "description": "Accidente de tránsito",
      "latitude": -0.21245,
      "longitude": -78.51895,
      "timestamp": "2026-07-28T11:15:00Z",
      "status": "resolved"
    }
  }
}
```

---

## 🔐 Checklist de Configuración

- [ ] Proyecto Firebase creado en Console
- [ ] `google-services.json` descargado y colocado en `android/app/`
- [ ] `GoogleService-Info.plist` descargado (iOS)
- [ ] Realtime Database creada en región Sudamérica
- [ ] Reglas de Realtime Database publicadas
- [ ] Dependencias de Firebase en `pubspec.yaml`
- [ ] `FirebaseService` inicializado en `main.dart`
- [ ] Permisos de notificaciones configurados en `AndroidManifest.xml`
- [ ] Permisos de notificaciones configurados en `Info.plist` (iOS)
- [ ] Aplicación compilada y ejecutada sin errores

---

## 🚀 Comandos Útiles

### Limpiar y Reinstalar
```bash
flutter clean
flutter pub get
flutter run
```

### Ver Logs de Firebase
```bash
flutter logs
```

### Verificar Dependencias
```bash
flutter pub outdated
```

### Actualizar Firebase (Opcional)
```bash
flutter pub upgrade firebase_core firebase_database
```

---

## 📚 Archivos Relacionados

- [FIREBASE_CONFIGURADO.md](FIREBASE_CONFIGURADO.md) - Configuración actual
- [FIREBASE_SETUP_2026.md](FIREBASE_SETUP_2026.md) - Guía rápida de setup
- [FIREBASE_RULES_SEGURIDAD.md](FIREBASE_RULES_SEGURIDAD.md) - Reglas de seguridad avanzadas
- [VERIFICACION_FIREBASE_2026.md](VERIFICACION_FIREBASE_2026.md) - Verificación de integraciones
- [FCM_IMPLEMENTATION.md](FCM_IMPLEMENTATION.md) - Implementación de notificaciones push

---

## ✅ Estado Actual

**Fecha de Verificación:** 21 de julio de 2026

| Servicio | Estado | Versión |
|----------|--------|---------|
| Firebase Core | ✅ Funcional | 4.3.0 |
| Analytics | ✅ Funcional | 12.1.0 |
| Crashlytics | ✅ Funcional | 5.0.6 |
| Cloud Messaging | ✅ Funcional | 16.1.0 |
| Realtime Database | ✅ Funcional | 12.1.1 |

---

## 📞 Soporte

Si encuentras problemas:

1. Revisa el archivo [FIREBASE_SETUP_2026.md](FIREBASE_SETUP_2026.md)
2. Verifica que el archivo `google-services.json` esté en el lugar correcto
3. Limpia y reinstala el proyecto: `flutter clean && flutter pub get`
4. Revisa los logs: `flutter logs`
5. Consulta la [documentación oficial de Firebase](https://firebase.flutter.dev/)

---

**Última actualización:** 28 de julio de 2026  
**Desarrollador:** Sistema de Alerta de Emergencia (SAES)
