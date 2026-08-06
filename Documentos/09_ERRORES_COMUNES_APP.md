# Posibles Errores de la App
**Última actualización:** 21 de julio de 2026  
**Versión:** 1.4.60  
**Estado:** Documentación de referencia
---

## Índice
1. [Errores de Firebase](#errores-de-firebase)
2. [Errores de Ubicación](#errores-de-ubicación)
3. [Errores de Notificaciones FCM](#errores-de-notificaciones-fcm)
4. [Errores de Permisos](#errores-de-permisos)
5. [Errores de Conectividad](#errores-de-conectividad)
6. [Errores de Sincronización](#errores-de-sincronización)
7. [Errores de UI/Pantalla](#errores-de-uipantalla)
8. [Errores de Rate Limiting](#errores-de-rate-limiting)

---

## Errores de Firebase

### [ERROR] Error: "Permission Denied"
```
E/flutter (11111): Firebase error: permission denied
E/firebase-database (11111): permission_denied: Custom claim "admin" is missing
```

**Causas:**
- Reglas de Firebase mal configuradas
- Usuario no autenticado
- Token expirado

**Soluciones:**
1. Ve a [Firebase Console](https://console.firebase.google.com/)
2. Selecciona tu proyecto → **Realtime Database → Rules**
3. Asegúrate que tengas:
```json
{
  "rules": {
    ".read": true,
    ".write": true
  }
}
```
4. Click **"Publish"**
5. Reinicia la app: `flutter run`

---

### [ERROR] Error: "Firebase Not Initialized"
```
E/flutter (11111): PlatformException(error, Firebase has not been initialized, null)
```

**Causas:**
- Firebase no se inicializó correctamente
- Archivo google-services.json falta o corrupto

**Soluciones:**
```bash
# Limpiar cache de Flutter
flutter clean

# Obtener dependencias nuevas
flutter pub get

# Reconstruir
flutter run
```

---

### [ERROR] Error: "Reference Child Null"
```
E/flutter (11111): NoSuchMethodError: The getter 'child' was called on null
```

**Causas:**
- Referencia a nodo Firebase que no existe
- Ruta de datos incorrecta

**Soluciones:**
1. Verifica la ruta en Firebase:
   - Ve a Firebase Console → Realtime Database
   - Confirma que el nodo existe

2. En el código, verifica:
```dart
DatabaseReference ref = _database.child('alerts').child('emerg_${timestamp}');
// Asegúrate de que 'alerts' existe
```

---

### [ERROR] Error: "Database Connection Lost"
```
E/firebase-database (11111): Connection lost: Network error
```

**Causas:**
- Sin conexión a internet
- Firebase servidor no responde
- Problema de firewall

**Soluciones:**
1. Verifica tu conexión a internet
2. Cambia a otra red WiFi o datos móviles
3. Reinicia el emulador o dispositivo
4. Verifica estado de Firebase en https://status.firebase.google.com/

---

## Errores de Ubicación

### [ERROR] Error: "Location Services Disabled"
```
E/geolocator (11111): Location services are disabled
E/flutter (11111): Failed to get location: LOCATION_SERVICES_DISABLED
```

**Causas:**
- GPS desactivado en el dispositivo
- Ubicación no está habilitada

**Soluciones:**
1. Abre **Configuración → Ubicación**
2. Activa **"Ubicación"** o **"Location"**
3. Asegúrate que esté en modo **"Alta precisión"** o **"GPS"**
4. Reinicia la app

---

### [ERROR] Error: "Permission Denied - Location"
```
E/geolocator (11111): Permission denied when querying the platforms geolocation
E/flutter (11111): Failed to get location: permission denied
```

**Causas:**
- Permiso de ubicación no otorgado
- Permiso revocado en configuración

**Soluciones:**
1. La app debería pedir permiso la primera vez
2. Si ya fue rechazado:
   - Abre **Configuración → Aplicaciones → [TU APP]**
   - En **"Permisos" → "Ubicación"**, selecciona **"Permitir solo esta vez"** o **"Permitir"**
3. Reinicia la app
4. Intenta de nuevo

---

### [ERROR] Error: "Geocoding Failed"
```
E/geocoding (11111): Unable to geocode coordinates
E/flutter (11111): PlatformException: GEOCODER_ERROR
```

**Causas:**
- Coordenadas inválidas
- Sin conexión a internet (geocoding requiere internet)
- Límite de requests excedido

**Soluciones:**
1. Verifica que tengas conexión a internet
2. Los logs deberían mostrar:
```
I/flutter (11111): Location obtained: lat=0.2340, lon=-78.5091
```
3. Si las coordenadas son válidas, intenta de nuevo más tarde
4. Alternativamente, puedes mostrar solo coordenadas:
```dart
double latitude = position.latitude;
double longitude = position.longitude;
String message = "$latitude, $longitude";
```

---

### [ERROR] Error: "Timeout Getting Location"
```
E/geolocator (11111): TimeoutException: Failed to get location within 30 seconds
```

**Causas:**
- GPS tarda mucho en obtener señal
- Estás en interiores o sin línea de vista al cielo

**Soluciones:**
1. Ve a un lugar abierto con vista al cielo
2. Espera más tiempo a que el GPS se estabilice
3. Incrementa el timeout en el código:
```dart
Position position = await Geolocator.getCurrentPosition(
  timeLimit: Duration(seconds: 60), // Incrementa de 30 a 60
);
```

---

## Errores de Notificaciones FCM

### [ERROR] Error: "FCM Token Refresh Failed"
```
E/FirebaseMessaging (11111): Failed to refresh FCM token
E/flutter (11111): FCM token error: Token refresh failed
```

**Causas:**
- Firebase no está inicializado
- Problemas de conexión
- google-services.json corrupto

**Soluciones:**
```bash
# Opción 1: Limpiar y reconstruir
flutter clean
flutter pub get
flutter run

# Opción 2: Verificar google-services.json
# - Ve a Firebase Console
# - Descarga google-services.json nuevamente
# - Coloca en android/app/
```

---

### [ERROR] Error: "Notifications Not Received"
```
# No hay mensaje de error, pero no llegan notificaciones
```

**Causas:**
- FCM token no registrado
- App fue desinstalada sin guardar token
- Notificaciones deshabilitadas en configuración
- Servidor no envía correctamente

**Soluciones:**
1. Verifica que FCM está inicializado:
```dart
I/flutter (11111): FCM token obtained: eZ1T8K...
```

2. Otorga permiso de notificaciones:
   - **Configuración → Notificaciones → [TU APP]** → Habilitar

3. Prueba una notificación manualmente desde Firebase Console:
   - Ir a **Cloud Messaging**
   - Crear nueva campaña
   - Seleccionar dispositivo específico

---

### [ERROR] Error: "BadTokenForSender"
```
E/Firebase-Messaging (11111): Error: InvalidRegistration: Invalid registration token provided
```

**Causas:**
- Token FCM inválido o expirado
- google-services.json de diferente proyecto
- Token de diferente app

**Soluciones:**
1. Desinstala la app completamente
2. Limpia datos:
```bash
flutter clean
```
3. Reinstala:
```bash
flutter pub get
flutter run
```

---

## Errores de Permisos

### [ERROR] Error: "Permission Handler Exception"
```
E/PermissionHandler (11111): PermissionException: Permission denied
E/flutter (11111): PermissionHandler error: Failed to request permission
```

**Causas:**
- Permisos no declarados en AndroidManifest.xml
- Permisos no declarados en Info.plist (iOS)
- Usuario rechazó permiso

**Soluciones:**
1. Verifica [05_PERMISOS_REQUERIDOS.md](05_PERMISOS_REQUERIDOS.md)
2. Asegúrate que todos los permisos están declarados:
   - Para Android: `android/app/src/main/AndroidManifest.xml`
   - Para iOS: `ios/Runner/Info.plist`

---

### [ERROR] Error: "Permission Permanently Denied"
```
W/flutter (11111): Permission permanently denied
W/flutter (11111): Need to open app settings
```

**Causas:**
- Usuario seleccionó "No preguntar de nuevo"

**Soluciones:**
1. El usuario debe abrir configuración manualmente:
   - **Configuración → Aplicaciones → [TU APP] → Permisos**
   - Habilitar permisos requeridos

---

## Errores de Conectividad

### [ERROR] Error: "No Internet Connection"
```
E/flutter (11111): SocketException: Connection refused
E/flutter (11111): Failed to connect to network
```

**Causas:**
- Sin WiFi ni datos móviles
- Dispositivo en modo avión
- Problema de red

**Soluciones:**
1. Verifica WiFi/datos móviles
2. Desactiva modo avión
3. Reinicia el dispositivo
4. Prueba con otra red

---

### [ERROR] Error: "Timeout - Connection"
```
E/flutter (11111): TimeoutException: Connection timeout after 30 seconds
```

**Causas:**
- Servidor no responde
- Red muy lenta
- Firewall bloqueando

**Soluciones:**
1. Verifica que Firebase está disponible
2. Prueba con internet más rápida
3. Incrementa timeout:
```dart
final httpClient = HttpClient();
httpClient.connectionTimeout = Duration(seconds: 60);
```

---

## Errores de Sincronización

### [ERROR] Error: "Sync Queue Full"
```
E/flutter (11111): Sync queue full: Maximum items reached
```

**Causas:**
- Demasiados items pendientes de sincronizar
- Servidor no procesa rápido

**Soluciones:**
1. Conecta a internet para sincronizar
2. Espera a que se sincronicen automáticamente
3. O limpia la cola manualmente:
```dart
// En AlertService
_syncQueue.clear();
```

---

### [ERROR] Error: "Sync Conflict - Duplicate Data"
```
W/flutter (11111): Sync conflict detected: Item already exists
```

**Causas:**
- Item se sincronizó dos veces
- Timestamp duplicado

**Soluciones:**
1. Usa timestamp único:
```dart
String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
```
2. Verifica en Firebase Console si hay duplicados
3. Elimina manualmente si es necesario

---

## Errores de UI/Pantalla

### [ERROR] Error: "RenderFlex Overflow"
```
E/flutter (11111): RenderFlex children have non-zero flex but incoming height constraints are unbounded
```

**Causas:**
- Widget sin tamaño definido
- Demasiados widgets en Column/Row

**Soluciones:**
Envuelve con Expanded o SingleChildScrollView:
```dart
SingleChildScrollView(
  child: Column(
    children: [...],
  ),
)
```

---

### [ERROR] Error: "Widget Build Exceeded"
```
E/flutter (11111): The following assertion was thrown during build: 'package:flutter/src/widgets/text.dart'
```

**Causas:**
- Texto muy largo sin límite
- Widget llamando setState infinitamente

**Soluciones:**
1. Limita texto:
```dart
Text(
  longText,
  maxLines: 2,
  overflow: TextOverflow.ellipsis,
)
```

2. Usa SizedBox para tamaño fijo:
```dart
SizedBox(
  height: 100,
  child: Text(...),
)
```

---

## Errores de Rate Limiting

### [ERROR] Error: "Rate Limit Exceeded"
```
E/flutter (11111): Rate limit exceeded: Max 3 emergencies per 3 hours
W/flutter (11111): Alertas restantes: 0/3
```

**Causas:**
- Ya activaste 3 alertas en las últimas 3 horas
- Rate limiter funcionando correctamente

**Soluciones:**
1. Espera 3 horas desde la primer alerta
2. Verifica el contador en la pantalla: "X/3"
3. Colores:
   - Verde (3/3): Tienes intentos
   - Amarillo (1-2/3): Pocos intentos
   - Rojo (0/3): Sin intentos

---

### [ERROR] Error: "Inconsistent Rate Limit State"
```
E/flutter (11111): Rate limiter state mismatch
```

**Causas:**
- Datos locales corruptos
- Sincronización offline fallida

**Soluciones:**
1. Limpia datos locales:
```bash
adb shell pm clear com.example.flutter_application_1
```
2. O desde configuración: **Aplicaciones → Almacenamiento → Borrar datos**
3. Reinstala la app

---

## Tabla de Referencia Rápida

| Error | Causa Probable | Solución Rápida |
|-------|----------------|-----------------|
| Permission Denied | Reglas Firebase | Verifica Firebase Console Rules |
| No Location | GPS desactivado | Activar ubicación en Configuración |
| No Notifications | FCM token inválido | `flutter clean && flutter run` |
| Connection Timeout | Sin internet | Verifica WiFi/datos |
| Sync Failed | Servidor no responde | Espera e intenta de nuevo |
| Rate Limit | 3 intentos agotados | Espera 3 horas |
| Overflow | Widget sin tamaño | Usa Expanded o SingleChildScrollView |
| Token Error | google-services.json corrupto | Descarga nuevamente de Firebase |

---

## Recursos Relacionados

- [08_MENSAJES_TERMINAL.md](08_MENSAJES_TERMINAL.md) - Mensajes que verás en la consola
- [05_PERMISOS_REQUERIDOS.md](05_PERMISOS_REQUERIDOS.md) - Permisos necesarios
- [TESTING_FCM_RESUMEN.md](../TESTING_FCM_RESUMEN.md) - Pruebas de notificaciones
- [TESTING_SINCRONIZACION_OFFLINE.md](../TESTING_SINCRONIZACION_OFFLINE.md) - Sincronización offline
- [FIREBASE_SETUP_2026.md](../FIREBASE_SETUP_2026.md) - Configuración de Firebase

---

## Si Nada Funciona

1. **Intenta lo básico:**
```bash
flutter clean
flutter pub get
flutter run
```

2. **Reinicia todo:**
   - Cierra Android Studio
   - Detén emulador/dispositivo
   - Abre terminal nuevamente
   - Ejecuta `flutter run`

3. **Revisa logs completos:**
```bash
flutter run > logs.txt 2>&1
```

4. **Consulta:**
   - [TESTING_GUIA.md](../TESTING_GUIA.md)
   - [INDICE_DOCUMENTACION.md](../INDICE_DOCUMENTACION.md)
