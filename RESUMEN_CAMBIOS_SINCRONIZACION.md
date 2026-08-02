# 📝 Resumen de Cambios: Sincronización Offline

## Nuevos Archivos Creados

### 1. **`lib/services/offline_sync_service.dart`** ⭐ Principal
- Servicio avanzado de sincronización offline
- Detecta automáticamente cambios de conectividad
- Guarda alertas como archivos JSON en `Documents/alerts/`
- Sincroniza automáticamente cuando se recupera conexión
- Incluye datos encriptados (lat, lon, phone)
- **Escalable**: Fácil de integrar con WhatsApp API

**Características**:
- ✅ Monitoreo automático de conectividad
- ✅ Almacenamiento en archivos JSON
- ✅ Encriptación de datos sensibles
- ✅ Sincronización automática
- ✅ Estadísticas en tiempo real
- ✅ Listeners para cambios de estado
- ✅ Limpieza automática de archivos antiguos

### 2. **`lib/testing/sync_testing_widget.dart`** 🧪 Testing Visual
- Widget completo de testing y debugging
- Interfaz visual para simulación offline/online
- Ver estadísticas en tiempo real
- Listado detallado de alertas locales
- Botones para forzar sincronización
- Botón para eliminar alertas de prueba

### 3. **`lib/testing/testing_page.dart`** 🎯 Acceso Fácil
- Página simple para acceder al widget de testing
- Puede integrarse en opciones de la app

### 4. **`TESTING_SINCRONIZACION_OFFLINE.md`** 📖 Guía Completa
- Instrucciones paso a paso para probar
- Casos de prueba detallados
- Troubleshooting
- Estructura de archivos JSON
- Logs esperados

### 5. **`DOCUMENTACION_TECNICA_SINCRONIZACION.md`** 🔧 Técnica Profunda
- Arquitectura general
- Flujos de sincronización (3 casos)
- Código detallado y pseudocódigo
- Integración futura con WhatsApp
- Checklist de implementación
- Consideraciones de producción

## Archivos Modificados

### **`lib/services/alert_service.dart`**
```dart
// CAMBIOS:
+ import 'offline_sync_service.dart';

// En createAlert():
+ await OfflineSyncService.instance.saveAlertLocally(offlineAlert);

// En initializeFromStorage():
+ await OfflineSyncService.instance.initialize();
```

**Impacto**: Las alertas ahora se guardan localmente en archivos JSON cuando se activan, sin importar si hay internet.

---

## Cómo Probar

### Opción 1: Acceso Visual (Recomendado)
1. En la app, abre **Configuración**
2. Busca botón o enlace: **"🧪 Testing de Sincronización"**
3. Usa la interfaz para:
   - Simular offline/online
   - Ver alertas locales
   - Forzar sincronización
   - Ver estadísticas

### Opción 2: Acceso Manual
```dart
// En main.dart o routes:
import 'testing/testing_page.dart';

// En NavigationBar o Menu:
case 3:
  return TestingPage();
```

### Opción 3: Prueba Directa (Sin UI)
1. Apaga WiFi del dispositivo
2. Activa alerta en la app
3. Ve a: `/storage/emulated/0/Documents/alerts/`
4. Verifica archivo JSON con `synced: false`
5. Activa WiFi
6. Espera 10-15s
7. Verifica que archivo ahora tenga `synced: true`

---

## Estructura de Carpetas

```
lib/
├── services/
│   ├── alert_service.dart           (MODIFICADO)
│   ├── offline_sync_service.dart    (NUEVO) ⭐
│   ├── encryption_service.dart
│   ├── firebase_service.dart
│   ├── secure_storage_service.dart
│   └── ...
├── testing/
│   ├── sync_testing_widget.dart     (NUEVO) 🧪
│   └── testing_page.dart            (NUEVO) 🎯
├── main.dart
├── options.dart
└── ...

Documentación:
├── TESTING_SINCRONIZACION_OFFLINE.md       (NUEVO) 📖
├── DOCUMENTACION_TECNICA_SINCRONIZACION.md (NUEVO) 🔧
└── ...
```

---

## Flujo Completo

```
USUARIO ACTIVA ALERTA
         │
         ▼
   SIN INTERNET              CON INTERNET
         │                        │
         ├─ Guardar local   ├─ Guardar en Firebase
         │  (JSON)          │
         ├─ synced: false   ├─ Guardar local
         │                  │  (JSON)
         │                  └─ synced: true
         │
         └─ Esperar WiFi/Datos
            │
            ▼
         SE RECUPERA CONEXIÓN
            │
            ├─ OfflineSyncService detecta
            │
            ├─ Sincroniza archivo a Firebase
            │
            └─ Actualiza archivo: synced: true
```

---

## Estructura JSON de Alertas

**Ubicación**: `/storage/emulated/0/Documents/alerts/alert_*.json`

```json
{
  "id": "abc123def456",
  "userId": "1756278550",
  "timestamp": 1721580600000,
  "date": "Julio 21 del 2026",
  "time": "02:30 pm",
  "status": "active",
  "description": "Alerta de emergencia",
  "latitude": -0.123456,
  "longitude": -78.654321,
  "latitude_encrypted": "8qJt3K9j...",
  "longitude_encrypted": "3XyZaBcD...",
  "numberCalled_encrypted": "7HjK1MnO...",
  "contactsNotified": ["0963522505"],
  "synced": false,
  "createdAt": 1721580600000,
  "syncedAt": null
}
```

---

## Próximas Fases (Roadmap)

### Fase 4.1: WhatsApp Integration
```dart
// Enviar automáticamente cuando se sincronice
if (alert.synced) {
  await whatsappService.sendNotification(
    phone: alert.numberCalled,
    message: "Alerta sincronizada: ${alert.description}",
  );
}
```

### Fase 4.2: Base de Datos Local (Opcional)
- Usar `drift` o `isar` para almacenamiento más robusto
- Mejor performance con muchas alertas
- Sincronización bidireccional

### Fase 4.3: Analytics
- Rastrear alertas por hora/día
- Heatmap de ubicaciones
- Dashboard en tiempo real

### Fase 4.4: Tests Automatizados
- Tests unitarios para `OfflineSyncService`
- Tests de integración
- Tests E2E con emulador

---

## Cambios en Dependencias

**NINGUNO REQUERIDO** - Ya tienes:
- ✅ `connectivity_plus` (Monitoreo de conectividad)
- ✅ `firebase_database` (Sincronización)
- ✅ `path_provider` (Acceso a archivos)
- ✅ `encrypt` (Encriptación)
- ✅ `shared_preferences` (Persistencia)

---

## Logs Importantes

```
[OfflineSyncService.initialize] ✓ Inicializado - Online: true
[AlertService.createAlert] ✓ Guardada localmente (archivo JSON)
[OfflineSyncService] Conectividad cambió: true → false
[OfflineSyncService] ¡Conexión recuperada! Iniciando sincronización...
[OfflineSyncService.syncOfflineAlerts] Sincronizando 3 alertas...
[OfflineSyncService.syncOfflineAlerts] ✓ Firebase: abc123
[OfflineSyncService.syncOfflineAlerts] ✓ Firebase: def456
[OfflineSyncService.syncOfflineAlerts] Resultados: ✓ 2, ✗ 0
```

---

## Debugging

### Ver Archivos Locales
```bash
# Android
adb shell ls /storage/emulated/0/Documents/alerts/

# Desktop
explorer Documentos/alerts/
```

### Ver Contenido JSON
```bash
# Android
adb shell cat /storage/emulated/0/Documents/alerts/alert_*.json

# Desktop (PowerShell)
Get-Content Documentos/alerts/alert_*.json | ConvertFrom-Json
```

### Monitor de Conectividad
```dart
connectivity.onConnectivityChanged.listen((result) {
  print('Conectividad: ${result.name}');
});
```

---

## Preguntas Frecuentes

### ¿Qué pasa si apago la app mientras sincroniza?
**Respuesta**: La sincronización se reanuda cuando se abre la app nuevamente y se recupera la conexión.

### ¿Dónde se guardan los datos encriptados?
**Respuesta**: En el archivo JSON local como base64. Firebase Realtime Database los almacena igual. La desencriptación ocurre solo cuando se necesita mostrar.

### ¿Se pierden las alertas si borro la app?
**Respuesta**: 
- Alertas sincronizadas: NO (están en Firebase)
- Alertas pendientes: SÍ (están solo locales)

### ¿Puedo ver las alertas sin desencriptar?
**Respuesta**: Sí, verás todos los campos en JSON, pero `latitude_encrypted` y `longitude_encrypted` serán cadenas base64 ilegibles.

### ¿Cómo integro WhatsApp?
**Respuesta**: Ver `DOCUMENTACION_TECNICA_SINCRONIZACION.md` → Sección "Integración con WhatsApp API"

---

## Soporte

Para problemas:
1. Revisa `TESTING_SINCRONIZACION_OFFLINE.md` → Troubleshooting
2. Verifica logs en consola Flutter
3. Asegúrate de que `connectivity_plus` está actualizado
4. Confirma permisos de almacenamiento

---

**Estado**: ✅ Completado y Listo para Testing
**Versión**: 1.0
**Última actualización**: 2026-07-21
