# 🔒 Permisos Requeridos - Documentación Completa

**Versión:** 1.0 | **Fecha:** 21 de diciembre de 2025 | **Estado:** ✅ Configurado

---

## 📋 Índice

1. [Descripción General](#descripción-general)
2. [Permisos Android](#permisos-android)
3. [Permisos iOS](#permisos-ios)
4. [Permisos Web](#permisos-web)
5. [Manejo de Permisos en Código](#manejo-de-permisos-en-código)
6. [Testing de Permisos](#testing-de-permisos)
7. [Troubleshooting](#troubleshooting)

---

## Descripción General

Los **permisos** son autorizaciones que el usuario debe conceder a la aplicación para acceder a recursos del dispositivo o realizar ciertas acciones. 

**Tipo de app:** Aplicación móvil de emergencia  
**Plataformas:** Android, iOS, Web  
**Permisos críticos:** Ubicación, Teléfono, Almacenamiento  

### Niveles de Permisos

```
1. RUNTIME PERMISSIONS (Android 6+, iOS 10+)
   └─ El usuario aprueba cada vez
   
2. INSTALLATION PERMISSIONS (Android)
   └─ Se aprueban al instalar
   
3. CAPABILITY REQUIREMENTS (iOS)
   └─ Capacidades requeridas en Xcode
```

---

## Permisos Android

### 📝 Configuración en AndroidManifest.xml

**Ubicación:** `android/app/src/main/AndroidManifest.xml`

#### Permisos Requeridos

```xml
<!-- Ubicación GPS -->
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />

<!-- Teléfono (para realizar llamadas) -->
<uses-permission android:name="android.permission.CALL_PHONE" />
<uses-permission android:name="android.permission.READ_PHONE_STATE" />

<!-- Almacenamiento (para documentos médicos) -->
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />

<!-- Cámara (para fotografiar documentos) -->
<uses-permission android:name="android.permission.CAMERA" />

<!-- Internet (para Firebase) -->
<uses-permission android:name="android.permission.INTERNET" />

<!-- Red (estado de conexión) -->
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />

<!-- Notificaciones (FCM) -->
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />

<!-- Cambiar configuración de audio (alarmas) -->
<uses-permission android:name="android.permission.MODIFY_AUDIO_SETTINGS" />
```

### 🎯 Uso de Cada Permiso

| Permiso | Uso | Requerido | Tipo |
|---------|-----|----------|------|
| **ACCESS_FINE_LOCATION** | Obtener ubicación GPS precisa | ✅ SÍ | Runtime |
| **ACCESS_COARSE_LOCATION** | Ubicación aproximada (WiFi) | ✅ SÍ | Runtime |
| **CALL_PHONE** | Realizar llamadas de emergencia | ✅ SÍ | Runtime |
| **READ_PHONE_STATE** | Detectar si está en llamada | ⚠️ Opcional | Runtime |
| **READ_EXTERNAL_STORAGE** | Leer documentos médicos | ⚠️ Opcional | Runtime |
| **WRITE_EXTERNAL_STORAGE** | Guardar documentos | ⚠️ Opcional | Runtime |
| **CAMERA** | Fotografiar documentos | ⚠️ Opcional | Runtime |
| **INTERNET** | Conectar con Firebase | ✅ SÍ | Installation |
| **ACCESS_NETWORK_STATE** | Detectar conexión | ✅ SÍ | Installation |
| **POST_NOTIFICATIONS** | Enviar notificaciones | ⚠️ Importante | Runtime |
| **MODIFY_AUDIO_SETTINGS** | Alarma de emergencia | ⚠️ Opcional | Installation |

### 🔧 Configuración en build.gradle

**Ubicación:** `android/app/build.gradle.kts`

```kotlin
android {
    compileSdk 34  // API level actual
    
    defaultConfig {
        targetSdk 34
        minSdk 21    // Soporta Android 5.0+
        
        // Permisos en tiempo de compilación
    }
}

dependencies {
    // Para manejo de permisos runtime
    implementation 'com.google.android.gms:play-services-location:21.1.0'
}
```

### 📱 Permisos por API Level

```
API 21-22 (Android 5-5.1):
└─ Permisos en instalación

API 23+ (Android 6+):
├─ Permisos en instalación (declarados)
└─ Solicitud Runtime (solicitados en tiempo de ejecución)

API 31+ (Android 12+):
├─ Permisos previos (background location)
├─ Approximate vs Fine location
└─ Photo/Video/Audio separados

API 33+ (Android 13+):
└─ POST_NOTIFICATIONS requiere solicitud runtime
```

---

## Permisos iOS

### 📝 Configuración en Info.plist

**Ubicación:** `ios/Runner/Info.plist`

#### Permisos Requeridos

```xml
<!-- Ubicación en Foreground -->
<key>NSLocationWhenInUseUsageDescription</key>
<string>Se necesita ubicación para alertas de emergencia</string>

<!-- Ubicación en Background -->
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>Se necesita ubicación en background para emergencias</string>

<!-- Cámara (para documentos) -->
<key>NSCameraUsageDescription</key>
<string>Se necesita cámara para fotografiar documentos médicos</string>

<!-- Acceso a fotos -->
<key>NSPhotoLibraryUsageDescription</key>
<string>Se necesita acceso a fotos para documentos médicos</string>

<!-- Contactos (para contactos de emergencia) -->
<key>NSContactsUsageDescription</key>
<string>Se necesita acceso a contactos para emergencias</string>

<!-- Micrófono (para llamadas) -->
<key>NSMicrophoneUsageDescription</key>
<string>Se necesita micrófono para llamadas de emergencia</string>

<!-- Calendario (para citas médicas) -->
<key>NSCalendarsUsageDescription</key>
<string>Se necesita acceso a calendario para citas médicas</string>
```

### 🔧 Configuración en Xcode

**Ubicación:** `ios/Runner.xcodeproj`

#### Capability Requirements

```
En Xcode:
1. Runner → Signing & Capabilities
2. "+ Capability" → Agregar:
   ├─ Background Modes
   │   ├─ Location Updates
   │   └─ Remote Notifications
   ├─ Push Notifications
   ├─ Maps
   └─ HomeKit (opcional)
```

#### Configuración de Build Settings

```
IPHONEOS_DEPLOYMENT_TARGET: 11.0
TARGETED_DEVICE_FAMILY: 1,2  (iPhone y iPad)
```

---

## Permisos Web

### 🌐 Política de Seguridad de Contenido

**Ubicación:** `web/index.html`

```html
<!-- Geolocation API -->
<meta name="geolocation" content="allow-geolocation" />

<!-- Cámara (si se implementa web cam) -->
<meta name="camera" content="allow-camera" />

<!-- Notificaciones push -->
<meta name="notifications" content="allow-notifications" />
```

### 🔐 Permisos en JavaScript

```javascript
// Ubicación en web
navigator.geolocation.getCurrentPosition(
  (position) => {
    console.log(position.coords.latitude);
  },
  (error) => {
    console.log('Permiso denegado');
  }
);

// Notificaciones
Notification.requestPermission().then((permission) => {
  if (permission === 'granted') {
    new Notification('Alerta de emergencia');
  }
});
```

---

## Manejo de Permisos en Código

### 1. Solicitar Permisos de Ubicación

**Archivo:** `lib/main.dart`

```dart
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

Future<Position?> requestLocationPermission() async {
  try {
    // Verificar permiso actual
    LocationPermission permission = await Geolocator.checkPermission();
    
    if (permission == LocationPermission.denied) {
      // Solicitar permiso
      permission = await Geolocator.requestPermission();
    }
    
    if (permission == LocationPermission.deniedForever) {
      // Usuario denegó permanentemente
      print('Permiso de ubicación negado permanentemente');
      openAppSettings();
      return null;
    }
    
    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      // Permiso otorgado
      Position position = await Geolocator.getCurrentPosition();
      return position;
    }
    
    return null;
  } catch (e) {
    print('Error solicitando ubicación: $e');
    return null;
  }
}
```

### 2. Solicitar Permiso de Cámara

```dart
Future<bool> requestCameraPermission() async {
  final status = await Permission.camera.request();
  
  if (status.isDenied) {
    print('Permiso de cámara denegado');
    return false;
  } else if (status.isPermanentlyDenied) {
    print('Permiso denegado permanentemente, abrir ajustes');
    openAppSettings();
    return false;
  }
  
  return status.isGranted;
}
```

### 3. Solicitar Permiso de Almacenamiento

```dart
Future<bool> requestStoragePermission() async {
  final status = await Permission.storage.request();
  
  if (status.isDenied) {
    return false;
  } else if (status.isPermanentlyDenied) {
    openAppSettings();
    return false;
  }
  
  return status.isGranted;
}
```

### 4. Solicitar Permiso de Teléfono

```dart
Future<bool> requestPhonePermission() async {
  final status = await Permission.phone.request();
  return status.isGranted;
}
```

### 5. Solicitar Todos los Permisos

```dart
Future<Map<Permission, PermissionStatus>> requestAllPermissions() async {
  final List<Permission> permissions = [
    Permission.location,
    Permission.camera,
    Permission.storage,
    Permission.phone,
    Permission.notification,
  ];
  
  final Map<Permission, PermissionStatus> statuses = 
    await permissions.request();
  
  return statuses;
}
```

---

## Instalación de Dependencia de Permisos

### En pubspec.yaml

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # Manejo de permisos
  permission_handler: ^11.4.4
  geolocator: ^9.0.2
```

### Instalar

```bash
cd "c:\Users\MateoM\Desktop\Proyecto-app\flutter_application_1"
flutter pub get
```

---

## Testing de Permisos

### Test de Ubicación

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';

void main() {
  group('Location Permissions', () {
    test('Solicitar permiso de ubicación', () async {
      final permission = await Geolocator.requestPermission();
      
      expect(
        permission,
        anyOf(
          LocationPermission.whileInUse,
          LocationPermission.always,
          LocationPermission.denied,
        ),
      );
    });
  });
}
```

### Test de Múltiples Permisos

```dart
test('Solicitar múltiples permisos', () async {
  Map<Permission, PermissionStatus> statuses = 
    await requestAllPermissions();
  
  // Verificar que se solicitaron todos
  expect(statuses.keys.length, 5);
});
```

### Ejecución en Emulador

```bash
# Con permisos predefinidos
flutter test --device-id emulator-5554

# Con logs detallados
flutter test -v
```

---

## Troubleshooting

### ❌ Problema: "Permission denied: ACCESS_FINE_LOCATION"

**Causa:** Permiso no concedido en tiempo de ejecución

**Solución:**
```dart
// Verificar permisos actuales
LocationPermission permission = await Geolocator.checkPermission();
print('Permiso actual: $permission');

// Solicitar nuevamente
if (permission == LocationPermission.denied) {
  permission = await Geolocator.requestPermission();
}
```

---

### ❌ Problema: "App crashes when requesting camera"

**Causa:** Permiso no declarado en AndroidManifest.xml

**Solución:**
```xml
<!-- Agregar en AndroidManifest.xml -->
<uses-permission android:name="android.permission.CAMERA" />
```

---

### ❌ Problema: "iOS pide permiso múltiples veces"

**Causa:** Message en Info.plist no está claro

**Solución:**
```xml
<!-- En Info.plist, hacer mensaje más descriptivo -->
<key>NSLocationWhenInUseUsageDescription</key>
<string>La aplicación de emergencia necesita acceso a tu ubicación 
para poder enviárla a los servicios de rescate en caso de emergencia.</string>
```

---

### ❌ Problema: "Location returns null"

**Causa:** Ubicación aún se está obteniendo

**Solución:**
```dart
// Agregar timeout
Position? position = await Geolocator.getCurrentPosition(
  timeLimit: Duration(seconds: 10),
).timeout(
  Duration(seconds: 15),
  onTimeout: () => null,
);
```

---

## Flujo de Solicitud de Permisos en la App

### En Startup (main.dart)

```
App Inicia
    ↓
[1] Solicitar permiso de ubicación (crítico)
    ├─ Si denegado: mostrar alerta
    └─ Si aceptado: continuar
    ↓
[2] Inicializar Firebase
    ├─ Incluye notificaciones push
    └─ Solicita POST_NOTIFICATIONS en Android 13+
    ↓
[3] Verificar almacenamiento (opcional)
    ├─ Si denegado: usar directorio app
    └─ Si aceptado: guardar en Documentos
    ↓
App Ready
```

### Flujo de Emergencia (cuando usuario presiona botón)

```
Usuario presiona botón
    ↓
Verificar permiso de ubicación
    ├─ Si está disponible: obtener GPS
    └─ Si denegado: usar última ubicación conocida
    ↓
Solicitar permiso de teléfono (si no se ha hecho)
    ├─ Si permitido: hacer llamada
    └─ Si denegado: mostrar número para marcar
    ↓
Crear alerta en Firebase
    ↓
Notificar contactos (via FCM - notificaciones push)
```

---

## Permisos Requeridos por Pantalla

### main.dart (Página Principal)
- ✅ `ACCESS_FINE_LOCATION` - Para ubicación GPS
- ✅ `ACCESS_COARSE_LOCATION` - Para ubicación aproximada
- ✅ `CALL_PHONE` - Para hacer llamadas
- ✅ `INTERNET` - Para Firebase

### senttings.dart (Configuración)
- ❌ Sin permisos especiales (solo datos locales)

### options.dart (Historial)
- ⚠️ `READ_EXTERNAL_STORAGE` - Para leer documentos
- ⚠️ `WRITE_EXTERNAL_STORAGE` - Para guardar historial

### documents.dart (Documentos Médicos)
- ⚠️ `CAMERA` - Para fotografiar documentos
- ⚠️ `READ_EXTERNAL_STORAGE` - Para seleccionar documentos
- ⚠️ `WRITE_EXTERNAL_STORAGE` - Para guardar documentos

### symptoms.dart (Síntomas)
- ❌ Sin permisos especiales

---

## Tabla de Compatibilidad

| Permiso | Android | iOS | Web | Tipo |
|---------|---------|-----|-----|------|
| **Ubicación** | 6+ | 8+ | Sí | Runtime |
| **Cámara** | 6+ | 10+ | Sí | Runtime |
| **Almacenamiento** | 6+ | N/A | Sí | Runtime |
| **Teléfono** | 6+ | N/A | No | Runtime |
| **Notificaciones** | 13+ | 10+ | Sí | Runtime |
| **Contactos** | 6+ | 10+ | No | Runtime |
| **Calendario** | 6+ | 10+ | No | Runtime |

---

## Mejores Prácticas

### 1. Solicitar Permisos Gradualmente

```dart
// ✅ BUENO - Solicitar solo cuando sea necesario
if (userPressedEmergencyButton) {
  Position? position = await requestLocationPermission();
}

// ❌ MALO - Solicitar todos los permisos al inicio
void main() {
  requestAllPermissions();
}
```

### 2. Proporcionar Explicación Clara

```dart
// ✅ BUENO - Explicar por qué se necesita
showDialog(
  context: context,
  builder: (_) => AlertDialog(
    title: Text('Permiso de Ubicación'),
    content: Text(
      'Se necesita tu ubicación para poder enviarla '
      'a los servicios de emergencia en caso de necesidad.'
    ),
    actions: [
      TextButton(
        onPressed: () => requestLocationPermission(),
        child: Text('Permitir'),
      ),
    ],
  ),
);
```

### 3. Manejar Negación Permanente

```dart
// ✅ BUENO - Ofrecer abrir ajustes
if (status.isPermanentlyDenied) {
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: Text('Permiso Requerido'),
      content: Text('Por favor habilita permisos en Ajustes'),
      actions: [
        TextButton(
          onPressed: () => openAppSettings(),
          child: Text('Abrir Ajustes'),
        ),
      ],
    ),
  );
}
```

---

## Resumen de Permisos Críticos

| Permiso | Plataforma | Razón | Fallback |
|---------|-----------|-------|----------|
| **ACCESS_FINE_LOCATION** | Android/iOS | Ubicación GPS para emergencia | Usar última ubicación |
| **CALL_PHONE** | Android | Llamar al 911 | Mostrar número |
| **INTERNET** | Android/iOS | Conexión Firebase | Queue offline |
| **POST_NOTIFICATIONS** | Android 13+ | Notificaciones push | Mostrar in-app |

---

## Documentación Oficial

- **Flutter Location:** https://pub.dev/packages/geolocator
- **Android Permissions:** https://developer.android.com/guide/topics/permissions
- **iOS Permissions:** https://developer.apple.com/documentation/bundleresources/information_property_list
- **Permission Handler:** https://pub.dev/packages/permission_handler

---

## Checklist de Implementación

- ✅ Permisos declarados en AndroidManifest.xml
- ✅ Permisos declarados en Info.plist (iOS)
- ✅ Solicitud runtime de permisos
- ✅ Manejo de negación de permisos
- ✅ Manejo de negación permanente
- ✅ Fallback para operaciones sin permiso
- ✅ Mensajes claros en español para Ecuador

---

## Próximos Pasos

1. Para integración con servicios: Ver `04_ARCHIVOS_SERVICIOS.md`
2. Para archivos principales: Ver `01_ARCHIVOS_PRINCIPALES.md`
3. Para validadores: Ver `02_VALIDADORES.md`
4. Para tests: Ver `03_ARCHIVOS_PRUEBAS.md`

---

**Última actualización:** 21 de julio de 2026  
**Versión:** 1.3.47  
**Estado:** Desarrollo
