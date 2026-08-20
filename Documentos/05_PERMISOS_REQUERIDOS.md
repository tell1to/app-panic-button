# Permisos Requeridos - Documentacion Completa

**Version:** 1.4.67  
**Fecha:** 20 de agosto de 2026  
**Estado:** Configurado

---

## Indice

1. [Descripcion General](#descripcion-general)
2. [Permisos Android](#permisos-android)
3. [Permisos iOS](#permisos-ios)
4. [Permisos Web](#permisos-web)
5. [Manejo de Permisos en Codigo](#manejo-de-permisos-en-codigo)
6. [Testing de Permisos](#testing-de-permisos)
7. [Troubleshooting](#troubleshooting)

---

## Descripcion General

Los **permisos** son autorizaciones que el usuario debe conceder a la aplicacion para acceder a recursos del dispositivo o realizar ciertas acciones.

**Tipo de app:** Aplicacion movil de emergencia  
**Plataformas:** Android, iOS, Web  
**Permisos criticos:** Ubicacion, Telefono, Almacenamiento, Notificaciones

### Niveles de Permisos

```
1. RUNTIME PERMISSIONS (Android 6+, iOS 10+)
   El usuario aprueba en tiempo de ejecucion

2. INSTALLATION PERMISSIONS (Android)
   Se aprueban al instalar

3. CAPABILITY REQUIREMENTS (iOS)
   Capacidades requeridas en Xcode
```

---

## Permisos Android

### Configuracion en AndroidManifest.xml

**Ubicacion:** `android/app/src/main/AndroidManifest.xml`

#### Permisos CRITICOS Requeridos

```xml
<!-- Ubicacion GPS - REQUERIDO para emergencias -->
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />

<!-- Telefono - REQUERIDO para llamadas de emergencia -->
<uses-permission android:name="android.permission.CALL_PHONE" />
<uses-permission android:name="android.permission.READ_PHONE_STATE" />

<!-- Notificaciones - REQUERIDO en Android 13+ -->
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />

<!-- Internet - REQUERIDO para Firebase -->
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
```

#### Permisos OPCIONALES (Almacenamiento y Multimedia)

```xml
<!-- Almacenamiento - Para documentos medicos -->
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" 
  android:maxSdkVersion="32" />
<uses-permission android:name="android.permission.MANAGE_EXTERNAL_STORAGE" />

<!-- Camara - Para fotografiar documentos -->
<uses-permission android:name="android.permission.CAMERA" />

<!-- Audio - Para alertas y llamadas -->
<uses-permission android:name="android.permission.MODIFY_AUDIO_SETTINGS" />
<uses-permission android:name="android.permission.VIBRATE" />
```

### Uso de Cada Permiso

| Permiso | Uso | Requerido | Tipo | Android |
|---------|-----|----------|------|---------|
| **ACCESS_FINE_LOCATION** | Ubicacion GPS precisa | SI | Runtime | 6+ |
| **ACCESS_COARSE_LOCATION** | Ubicacion aproximada (WiFi) | SI | Runtime | 6+ |
| **CALL_PHONE** | Realizar llamadas emergencia | SI | Runtime | 6+ |
| **POST_NOTIFICATIONS** | Recordatorios de citas | Importante | Runtime | 13+ |
| **READ_PHONE_STATE** | Detectar si esta en llamada | Opcional | Runtime | 6+ |
| **READ_EXTERNAL_STORAGE** | Leer documentos medicos | Opcional | Runtime | 6+ |
| **WRITE_EXTERNAL_STORAGE** | Guardar documentos/alertas | Opcional | Runtime | 6+ |
| **CAMERA** | Fotografiar documentos | Opcional | Runtime | 6+ |
| **INTERNET** | Conectar con Firebase | SI | Installation | - |
| **ACCESS_NETWORK_STATE** | Detectar conexion | SI | Installation | - |
| **MODIFY_AUDIO_SETTINGS** | Volumen de alarma | Opcional | Installation | - |

### Configuracion en build.gradle

**Ubicacion:** `android/app/build.gradle.kts`

```kotlin
android {
  compileSdk 34 // API level actual
  
  defaultConfig {
    targetSdk 34 // Android 14
    minSdk 21 // Soporta Android 5.0+
    
    // Propiedades para permisos
    targetSdkVersion 34
  }
}

dependencies {
  // Para manejo de permisos runtime
  implementation 'com.google.android.gms:play-services-location:21.1.0'
}
```

### Permisos por API Level

```
API 21-22 (Android 5-5.1):
  Permisos en instalacion (simplemente se otorgan)

API 23+ (Android 6+):
  Permisos en instalacion (declarados)
  Solicitud Runtime (solicitados en tiempo de ejecucion)
  permission_handler package maneja esto

API 31+ (Android 12+):
  Permisos previos (background location)
  Approximate vs Fine location separados
  Photo/Video/Audio separados

API 33+ (Android 13+):
  POST_NOTIFICATIONS requiere solicitud runtime
  Obligatorio solicitar al usuario en tiempo de ejecucion
```

---

## Permisos iOS

### Configuracion en Info.plist

**Ubicacion:** `ios/Runner/Info.plist`

#### Permisos Requeridos - Descripciones Obligatorias

```xml
<!-- UBICACION EN FOREGROUND -->
<key>NSLocationWhenInUseUsageDescription</key>
<string>Se necesita tu ubicacion para alertas de emergencia</string>

<!-- UBICACION EN BACKGROUND -->
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>Se necesita tu ubicacion en background para emergencias</string>

<!-- CAMARA - Para documentos -->
<key>NSCameraUsageDescription</key>
<string>Se necesita camara para fotografiar documentos medicos</string>

<!-- ACCESO A FOTOS -->
<key>NSPhotoLibraryUsageDescription</key>
<string>Se necesita acceso a fotos para documentos medicos</string>

<!-- CONTACTOS - Para emergencias -->
<key>NSContactsUsageDescription</key>
<string>Se necesita acceso a contactos para contactos de emergencia</string>

<!-- MICROFONO - Para llamadas -->
<key>NSMicrophoneUsageDescription</key>
<string>Se necesita microfono para llamadas de emergencia</string>

<!-- CALENDARIO - Para citas medicas -->
<key>NSCalendarsUsageDescription</key>
<string>Se necesita acceso a calendario para citas medicas</string>

<!-- NOTIFICACIONES - Para recordatorios -->
<key>NSUserNotificationsUsageDescription</key>
<string>Se necesita enviar notificaciones de recordatorios</string>
```

### Configuracion en Xcode

**Ubicacion:** `ios/Runner.xcodeproj`

#### Capabilities Requeridas

1. Abre Xcode
2. Selecciona Runner -> Signing & Capabilities
3. Click "+ Capability" y agrega:

```
Background Modes:
  - Background fetch
  - Remote notifications
  - Location updates

Notifications:
  - Push Notifications
  - Remote Notifications

Maps
  (Opcional para features de mapas futuros)
```

#### Configuracion de Build Settings

```
IPHONEOS_DEPLOYMENT_TARGET: 12.0 (minimo soportado)
TARGETED_DEVICE_FAMILY: 1,2 (iPhone y iPad)
ENABLE_BITCODE: NO (compatibilidad)
```

---

## Permisos Web

### Politica de Seguridad de Contenido

**Ubicacion:** `web/index.html`

```html
<!-- Geolocation API -->
<meta name="geolocation" content="allow" />

<!-- Notificaciones Push -->
<meta name="notifications" content="allow" />

<!-- Politica de permisos generalizada -->
<meta name="permissions-policy" content="
  geolocation=(),
  microphone=(),
  camera=()
" />
```

### Notas Web

- La app no esta optimizada para web actualmente
- Los permisos web son mas limitados que en moviles
- Web no soporta llamadas telefonicas automaticas

---

## Manejo de Permisos en Codigo

### Solicitar Permisos

**Package:** `permission_handler: ^12.0.1`

```dart
import 'package:permission_handler/permission_handler.dart';

// Solicitar permiso de ubicacion
Future<bool> requestLocationPermission() async {
  final status = await Permission.location.request();
  
  if (status.isDenied) {
    // Permiso denegado
    return false;
  } else if (status.isPermanentlyDenied) {
    // Permiso denegado permanentemente
    // Abrir configuracion del dispositivo
    openAppSettings();
    return false;
  }
  
  // Permiso otorgado
  return true;
}

// Solicitar permiso de camara
Future<bool> requestCameraPermission() async {
  final status = await Permission.camera.request();
  return status.isGranted;
}

// Solicitar multiples permisos
Future<bool> requestEmergencyPermissions() async {
  final statuses = await [
    Permission.location,
    Permission.phone,
  ].request();
  
  return statuses[Permission.location]!.isGranted &&
         statuses[Permission.phone]!.isGranted;
}
```

### Verificar Permisos

```dart
// Verificar si permiso ya fue otorgado
Future<bool> isLocationPermissionGranted() async {
  final status = await Permission.location.status;
  return status.isGranted;
}

// Verificar estado detallado
Future<void> checkPermissionStatus() async {
  final status = await Permission.location.status;
  
  if (status.isDenied) {
    print('Permiso denegado');
  } else if (status.isGranted) {
    print('Permiso otorgado');
  } else if (status.isPermanentlyDenied) {
    print('Permiso denegado permanentemente');
  } else if (status.isRestricted) {
    print('Permiso restringido (iOS)');
  }
}
```

### Uso en main.dart

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Solicitar permisos criticos temprano
  print('[main] Solicitando permisos...');
  try {
    await requestLocationPermission();
    await requestCameraPermission();
  } catch (e) {
    print('[main] Error solicitando permisos: $e');
  }
  
  // Continuar con inicializacion
  await FirebaseService.instance.initialize();
  
  runApp(const MyApp());
}
```

---

## Testing de Permisos

### Simular Permisos en Tests

```dart
testWidgets('app requests location permission on startup', 
  (WidgetTester tester) async {
  
  // Mock de permisos
  when(mockPermissionHandler.requestLocationPermission())
    .thenAnswer((_) async => true);
  
  // Construir app
  await tester.pumpWidget(const MyApp());
  await tester.pumpAndSettle(Duration(seconds: 2));
  
  // Verificar que se solicito
  verify(mockPermissionHandler.requestLocationPermission()).called(1);
});
```

### Verificar en Dispositivo Real

```
1. Desinstalar la app
2. Instalar nuevamente
3. Verificar que aparecen los dialogos de permisos
4. Otorgar y denegar permisos
5. Verificar comportamiento en ambos casos
```

---

## Troubleshooting

### Problema: Permisos no se solicitan en Android 12+

**Causa:** minSdk es menor a 21 o targetSdk incorrecto

**Solucion:**

```gradle
android {
  compileSdk 34
  defaultConfig {
    targetSdk 34 // Debe ser 34 o superior
    minSdk 21
  }
}
```

### Problema: Ubicacion no funciona

**Causas posibles:**

1. Permiso no fue otorgado
2. GPS del dispositivo esta deshabilitado
3. No hay conexion a internet
4. Timeout en obtencion de ubicacion

**Solucion:**

```dart
Future<Position?> getLocationWithFallback() async {
  try {
    // Verificar permiso
    bool hasPermission = await isLocationPermissionGranted();
    if (!hasPermission) {
      bool granted = await requestLocationPermission();
      if (!granted) return null;
    }
    
    // Obtener ubicacion con timeout
    try {
      Position position = await Geolocator.getCurrentPosition(
        timeoutDuration: Duration(seconds: 10),
        forceAndroidLocationManager: true,
      );
      return position;
    } catch (e) {
      // Usar ultima ubicacion conocida
      return await Geolocator.getLastKnownPosition();
    }
  } catch (e) {
    print('Error obteniendo ubicacion: $e');
    return null;
  }
}
```

### Problema: Notificaciones no se muestran en Android 13+

**Causa:** Permiso POST_NOTIFICATIONS no fue otorgado

**Solucion:**

```dart
Future<void> requestNotificationPermission() async {
  if (await Permission.notification.isDenied) {
    await Permission.notification.request();
  }
}
```

### Problema: iOS - Ubicacion en background no funciona

**Causa:** Info.plist no tiene descripcion o app no requiere background location

**Solucion:**

```xml
<!-- En ios/Runner/Info.plist -->
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>Se necesita tu ubicacion en background</string>

<!-- En Xcode: Runner > Capabilities > Background Modes >
     Marcar "Location Updates" -->
```

---

## Checklist Final

- [x] AndroidManifest.xml configurado
- [x] build.gradle.kts actualizado
- [x] Info.plist de iOS configurado
- [x] Xcode capabilities habilitadas
- [x] permission_handler importado
- [x] Permisos solicitados en main.dart
- [x] Manejo de errores implementado
- [x] Tests de permisos creados
- [x] Documentacion actualizada
- [x] Probado en dispositivo real

---

**Nota:** Los permisos deben ser solicitados de manera transparente y respetuosa. La app debe funcionar degradadamente si algunos permisos opcionales no se otorgan.

**Ultimo cambio:** 20 de agosto de 2026 - Actualizado a version 1.4.67 con POST_NOTIFICATIONS requerido.
