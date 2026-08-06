# Posibles Mensajes en la Terminal
**Última actualización:** 21 de julio de 2026  
**Versión:** 1.4.60  
**Estado:** Documentación de referencia
---

## Índice
1. [Mensajes de Inicio](#mensajes-de-inicio)
2. [Mensajes de Compilación](#mensajes-de-compilación)
3. [Mensajes de Firebase](#mensajes-de-firebase)
4. [Mensajes de Ubicación y Sensores](#mensajes-de-ubicación-y-sensores)
5. [Mensajes de Notificaciones FCM](#mensajes-de-notificaciones-fcm)
6. [Mensajes de Sincronización](#mensajes-de-sincronización)
7. [Mensajes de Permisos](#mensajes-de-permisos)
8. [Mensajes de Rendimiento](#mensajes-de-rendimiento)

---

## Mensajes de Inicio

### [OK] Inicio Exitoso
```
Flutter run key commands.
r Hot reload. (presiona para recargar código)
R Hot restart.
h Repeat this help message.
d Detach (terminate "flutter run" but leave application running).
c Clear the screen
q Quit (terminate the application on the device).
```
**Significado:** La aplicación se inició correctamente y está lista para recibir comandos.

### [WAIT] Esperando Dispositivo
```
Launching lib/main.dart on <device> in debug mode...
Building for <device>...
```
**Significado:** Flutter está compilando y desplegando en el dispositivo. Espera a que termine.

---

## Mensajes de Compilación

### [OK] Compilación Exitosa
```
Syncing files to device <device_id>...
```
**Significado:** Los cambios se están sincronizando con el dispositivo.

### [INFO] Hot Reload
```
Hot reload time: XXXms
```
**Significado:** El código se recargó en caliente. Los cambios se aplicaron sin reiniciar.

### [INFO] Hot Restart
```
Restarted application in XXXms.
```
**Significado:** La aplicación se reinició por completo.

---

## Mensajes de Firebase

### [OK] Firebase Inicializado
```
[firebase_core] Firebase has been initialized successfully
I/flutter (11111): Firebase initialized successfully
```
**Significado:** La conexión con Firebase fue exitosa.

### [INFO] Conectando a Realtime Database
```
I/firebase-database (11111): Realtime Database connected
Connection established to: https://<project>.firebaseio.com
```
**Significado:** La conexión a la base de datos en tiempo real está activa.

### [INFO] Registrando Evento Analytics
```
I/flutter (11111): Event logged: emergency_activated
I/flutter (11111): Event logged: app_opened
```
**Significado:** Los eventos se registran en Firebase Analytics correctamente.

### [ERROR] Error de Conexión Firebase
```
E/firebase-database (11111): Connection failed: Network error
E/flutter (11111): Firebase error: permission denied
```
**Significado:** Problema de conexión a Firebase o permisos insuficientes.

---

## Mensajes de Ubicación y Sensores

### [OK] Ubicación Obtenida
```
I/flutter (11111): Location obtained: lat=0.2340, lon=-78.5091
I/flutter (11111): Geocoding address: Calle Principal, Ecuador
```
**Significado:** Se obtuvo la ubicación GPS correctamente y se convirtió a dirección.

### [INFO] Buscando Ubicación
```
I/Fused Location (11111): requestLocationUpdates() called
I/geolocator (11111): Getting location...
```
**Significado:** La app está obteniendo la ubicación GPS del dispositivo.

### [ERROR] Error de Ubicación
```
E/geolocator (11111): Location services are disabled
E/flutter (11111): Failed to get location: permission denied
E/geocoding (11111): Unable to geocode coordinates
```
**Significado:** Problemas obteniendo ubicación GPS o convirtiendo coordenadas.

---

## Mensajes de Notificaciones FCM

### [OK] FCM Inicializado
```
I/FirebaseMessaging (11111): FirebaseMessaging initialized
I/flutter (11111): FCM token obtained: eZ1T8K...
```
**Significado:** Las notificaciones push están configuradas correctamente.

### [OK] Notificación Recibida
```
I/flutter (11111): Foreground notification received: [Title]
I/FirebaseMessaging (11111): Message received while app is in foreground
```
**Significado:** La app recibió una notificación mientras está en primer plano.

### [INFO] Notificación en Background
```
I/FirebaseMessaging (11111): Message received in background
[Notification will appear en la bandeja del sistema]
```
**Significado:** Notificación recibida cuando la app está en background.

### [ERROR] Error FCM
```
E/FirebaseMessaging (11111): Failed to register FCM token
E/flutter (11111): FCM error: Token refresh failed
```
**Significado:** Problema registrando el dispositivo en FCM.

---

## Mensajes de Sincronización

### [OK] Sincronización Exitosa
```
I/flutter (11111): Sync started: 5 items pending
I/flutter (11111): Sync completed successfully: 5/5 items synced
```
**Significado:** Los datos offline se sincronizaron correctamente con el servidor.

### [INFO] En Sincronización
```
I/flutter (11111): Syncing data...
I/flutter (11111): Queue contains: 3 items
```
**Significado:** La app está sincronizando datos pendientes.

### [INFO] Sin Conexión (Offline)
```
I/flutter (11111): No internet connection detected
I/flutter (11111): Offline mode: queuing data
```
**Significado:** No hay conexión a internet, los datos se guardan localmente.

### [ERROR] Error de Sincronización
```
E/flutter (11111): Sync failed: Network error
E/flutter (11111): Failed to sync item ID: xyz123
```
**Significado:** Falló la sincronización de datos con el servidor.

---

## Mensajes de Permisos

### [OK] Permisos Otorgados
```
I/flutter (11111): Location permission granted
I/flutter (11111): Camera permission granted
I/flutter (11111): Storage permission granted
```
**Significado:** Los permisos requeridos fueron otorgados por el usuario.

### [INFO] Solicitando Permisos
```
I/PermissionHandler (11111): Requesting: location
I/ActivityCompat (11111): Requesting permission...
```
**Significado:** La app está solicitando permisos al usuario.

### [ERROR] Permisos Denegados
```
E/flutter (11111): Location permission denied
E/flutter (11111): Permission denied by user: camera
```
**Significado:** El usuario rechazó los permisos solicitados.

### [WARNING] Permisos Nunca Más
```
W/flutter (11111): Permission permanently denied
W/flutter (11111): User selected "Don't ask again"
```
**Significado:** El usuario rechazó permanentemente los permisos. Necesita cambiarlos en configuración.

---

## Mensajes de Rendimiento

### [WARNING] Frame Drop
```
I/flutter (11111): Frame drop detected: 120ms frame
W/flutter (11111): Jank detected (frame time exceeded 16.67ms)
```
**Significado:** La app tuvo una caída en el rendimiento en ese frame.

### [WARNING] Memory Warning
```
W/dalvikvm (11111): GC_FOR_ALLOC freed 50K, 45% free
I/flutter (11111): Memory pressure: 85% of 512MB used
```
**Significado:** El dispositivo está usando mucha memoria.

### [OK] Debug Mode
```
I/flutter (11111): Running in DEBUG mode
I/flutter (11111): Debug logging enabled
```
**Significado:** La app se ejecuta en modo debug.

### [OK] Release Mode
```
I/flutter (11111): Running in RELEASE mode
```
**Significado:** La app se ejecuta en modo release (optimizado).

---

## Consejos para Leer Logs

### Filtrar por Etiqueta
```bash
flutter run | grep "flutter"
```

### Ver solo Errores
```bash
flutter run | grep -E "ERROR|FATAL|Exception"
```

### Guardar Logs en Archivo
```bash
flutter run > app_logs.txt 2>&1
```

### Ver Logs del Dispositivo Específico
```bash
adb logcat -s flutter
```

---

## Relación con Errores

| Mensaje en Terminal | Error Común | Solución |
|-------------------|------------|----------|
| `Firebase error: permission denied` | Firebase Auth Error | Verificar reglas en Firebase Console |
| `Location permission denied` | Ubicación no funciona | Otorgar permisos en configuración |
| `No internet connection detected` | App offline | Verificar conexión WiFi/datos |
| `FCM token failed` | Notificaciones no llegan | Revisar google-services.json |
| `Sync failed: Network error` | No sincroniza | Verificar reglas de Firebase |

---

## Próximos Pasos
- Consulta [09_ERRORES_COMUNES_APP.md](09_ERRORES_COMUNES_APP.md) para solucionar problemas específicos
- Revisa [TESTING_FCM_RESUMEN.md](../TESTING_FCM_RESUMEN.md) para pruebas de mensajes
- Consulta [TESTING_SINCRONIZACION_OFFLINE.md](../TESTING_SINCRONIZACION_OFFLINE.md) para temas de sincronización
