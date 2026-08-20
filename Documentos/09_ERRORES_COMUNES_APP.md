# Errores Comunes de la Aplicacion

**Version:** 1.4.67  
**Fecha:** 20 de agosto de 2026  
**Estado:** Produccion

---

## Indice

1. [Errores de Firebase](#errores-de-firebase)
2. [Errores de Ubicacion](#errores-de-ubicacion)
3. [Errores de Notificaciones FCM](#errores-de-notificaciones-fcm)
4. [Errores de Permisos](#errores-de-permisos)
5. [Errores de Conectividad](#errores-de-conectividad)
6. [Errores de Sincronizacion](#errores-de-sincronizacion)
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
3. Asegúrate que tengas reglas de lectura/escritura correctas
4. Click **"Publish"**
5. Reinicia la app: `flutter run`

---

### [ERROR] Error: "Firebase Not Initialized"

```
E/flutter (11111): PlatformException(error, Firebase has not been initialized, null)
```

**Causas:**
- Firebase no se inicializo correctamente
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

2. En el codigo, verifica que la ruta sea correcta:
```dart
DatabaseReference ref = _database.child('alerts');
```

---

### [ERROR] Error: "Database Connection Lost"

```
E/firebase-database (11111): Connection lost: Network error
```

**Causas:**
- Sin conexion a internet
- Firebase servidor no responde
- Problema de firewall

**Soluciones:**
1. Verifica tu conexion a internet
2. Cambia a otra red WiFi o datos moviles
3. Reinicia el emulador o dispositivo
4. Verifica estado de Firebase en https://status.firebase.google.com/

---

## Errores de Ubicacion

### [ERROR] Error: "Location Services Disabled"

```
E/geolocator (11111): Location services are disabled
E/flutter (11111): Failed to get location: LOCATION_SERVICES_DISABLED
```

**Causas:**
- GPS desactivado en el dispositivo
- Ubicacion no esta habilitada

**Soluciones:**
1. Abre **Configuracion → Ubicacion**
2. Activa **"Ubicacion"** o **"Location"**
3. Asegurate que este en modo **"Alta precision"** o **"GPS"**
4. Reinicia la app

---

### [ERROR] Error: "Permission Denied - Location"

```
E/geolocator (11111): Permission denied when querying the platforms geolocation
E/flutter (11111): Failed to get location: permission denied
```

**Causas:**
- Permiso de ubicacion no otorgado
- Permiso revocado en configuracion

**Soluciones:**
1. La app deberia pedir permiso la primera vez
2. Si ya fue rechazado:
   - Abre **Configuracion → Aplicaciones → [TU APP]**
   - En **"Permisos" → "Ubicacion"**, selecciona **"Permitir solo esta vez"** o **"Permitir"**
3. Reinicia la app
4. Intenta de nuevo

---

### [ERROR] Error: "Geocoding Failed"

```
E/geocoding (11111): Unable to geocode coordinates
E/flutter (11111): PlatformException: GEOCODER_ERROR
```

**Causas:**
- Coordenadas invalidas
- Sin conexion a internet (geocoding requiere internet)
- Limite de requests excedido

**Soluciones:**
1. Verifica que tengas conexion a internet
2. Los logs deberan mostrar coordenadas validas
3. Si las coordenadas son validas, intenta de nuevo mas tarde
4. Alternativamente, puedes mostrar solo coordenadas sin geocoding

---

### [ERROR] Error: "Timeout Getting Location"

```
E/geolocator (11111): TimeoutException: Failed to get location within 30 seconds
```

**Causas:**
- GPS tarda mucho en obtener senal
- Estas en interiores o sin linea de vista al cielo

**Soluciones:**
1. Ve a un lugar abierto con vista al cielo
2. Espera mas tiempo a que el GPS se estabilice
3. Incrementa el timeout en el codigo si es necesario

---

## Errores de Notificaciones FCM

### [ERROR] Error: "FCM Token Refresh Failed"

```
E/FirebaseMessaging (11111): Failed to refresh FCM token
E/flutter (11111): FCM token error: Token refresh failed
```

**Causas:**
- Firebase no esta inicializado
- Problemas de conexion
- google-services.json corrupto

**Soluciones:**
```bash
# Opcion 1: Limpiar y reconstruir
flutter clean
flutter pub get
flutter run

# Opcion 2: Verificar google-services.json
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
- Notificaciones deshabilitadas en configuracion
- Servidor no envia correctamente

**Soluciones:**
1. Verifica que FCM esta inicializado
2. Otorga permiso de notificaciones:
   - **Configuracion → Notificaciones → [TU APP]** → Habilitar
3. Prueba una notificacion manualmente desde Firebase Console

---

### [ERROR] Error: "BadTokenForSender"

```
E/Firebase-Messaging (11111): Error: InvalidRegistration: Invalid registration token provided
```

**Causas:**
- Token FCM invalido o expirado
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
- Usuario rechazo permiso

**Soluciones:**
1. Verifica [05_PERMISOS_REQUERIDOS.md](05_PERMISOS_REQUERIDOS.md)
2. Asegurate que todos los permisos estan declarados:
   - Para Android: `android/app/src/main/AndroidManifest.xml`
   - Para iOS: `ios/Runner/Info.plist`

---

### [ERROR] Error: "Permission Permanently Denied"

```
W/flutter (11111): Permission permanently denied
W/flutter (11111): Need to open app settings
```

**Causas:**
- Usuario selecciono "No preguntar de nuevo"

**Soluciones:**
1. El usuario debe abrir configuracion manualmente:
   - **Configuracion → Aplicaciones → [TU APP] → Permisos**
   - Habilitar permisos requeridos

---

## Errores de Conectividad

### [ERROR] Error: "No Internet Connection"

```
E/flutter (11111): SocketException: Connection refused
E/flutter (11111): Failed to connect to network
```

**Causas:**
- Sin WiFi ni datos moviles
- Dispositivo en modo avion
- Problema de red

**Soluciones:**
1. Verifica WiFi/datos moviles
2. Desactiva modo avion
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
1. Verifica que Firebase esta disponible
2. Prueba con internet mas rapida
3. Incrementa timeout si es necesario

---

## Errores de Sincronizacion

### [ERROR] Error: "Sync Queue Full"

```
E/flutter (11111): Sync queue full: Maximum items reached
```

**Causas:**
- Demasiados items pendientes de sincronizar
- Servidor no procesa rapido

**Soluciones:**
1. Conecta a internet para sincronizar
2. Espera a que se sincronicen automaticamente
3. O limpia la cola si es necesario

---

### [ERROR] Error: "Sync Conflict - Duplicate Data"

```
W/flutter (11111): Sync conflict detected: Item already exists
```

**Causas:**
- Item se sincronizo dos veces
- Timestamp duplicado

**Soluciones:**
1. Usa timestamp unico
2. Verifica en Firebase Console si hay duplicados
3. Elimina manualmente si es necesario

---

## Errores de UI/Pantalla

### [ERROR] Error: "RenderFlex Overflow"

```
E/flutter (11111): RenderFlex overflowed by XXX pixels on the bottom
```

**Causas:**
- Widget es mas grande que el espacio disponible
- Contenido no cabe en la pantalla

**Soluciones:**
1. Usa `SingleChildScrollView` para hacer scrolleable
2. Ajusta tamaño de fuentes
3. Reduce espaciado entre widgets

---

### [ERROR] Error: "Widget Not Found"

```
E/flutter (11111): Could not find a generator for route "/settings"
```

**Causas:**
- Ruta no esta definida en navigation
- Nombre de ruta incorrecto

**Soluciones:**
1. Verifica que la ruta este definida en main.dart
2. Revisa la ortografia de la ruta
3. Asegurate de usar `Navigator.push()` correctamente

---

## Errores de Rate Limiting

### [ERROR] Error: "Too Many Requests"

```
E/flutter (11111): Rate limit exceeded: 4 attempts in 2 minutes
```

**Causas:**
- Usuario intento activar emergencia demasiadas veces
- Limite de rate limiting alcanzado

**Soluciones:**
1. Espera a que se restablezca la ventana (2 minutos por defecto)
2. Los logs mostraran el tiempo de espera restante
3. El usuario puede ver el indicador en la UI

---

**Nota:** Consulta [08_MENSAJES_TERMINAL.md](08_MENSAJES_TERMINAL.md) para ver los mensajes en la terminal que corresponden con estos errores.

**Ultimo cambio:** 20 de agosto de 2026 - Estructura y contenido actualizado.
