# 🚀 Guía de Inicio Rápido: Sincronización Offline

## ¿Qué Se Implementó?

Sistema completo de **sincronización automática de alertas offline** con:
- ✅ Detección automática de conectividad
- ✅ Guardado local en archivos JSON
- ✅ Encriptación de datos sensibles (ubicación, teléfono)
- ✅ Sincronización automática cuando se recupera conexión
- ✅ Widget visual de testing
- ✅ Escalable para integración con WhatsApp

---

## Archivos Creados

```
lib/
├── services/
│   └── offline_sync_service.dart     ⭐ Servicio principal de sincronización
├── testing/
│   ├── sync_testing_widget.dart      🧪 UI para testing
│   └── testing_page.dart             🎯 Página de acceso

Documentación:
├── TESTING_SINCRONIZACION_OFFLINE.md       📖 Guía paso a paso
├── DOCUMENTACION_TECNICA_SINCRONIZACION.md 🔧 Arquitectura profunda
└── RESUMEN_CAMBIOS_SINCRONIZACION.md      📝 Resumen de cambios
```

---

## Prueba Rápida (5 minutos)

### Paso 1: Preparar dispositivo
```bash
# En el dispositivo/emulador:
1. Apaga WiFi
2. Apaga Datos Móviles
3. Verifica que esté completamente offline
```

### Paso 2: Activar alerta
```dart
// En la app
1. Ve a Inicio
2. Mantén presionado el botón rojo (~1.2 segundos)
3. Sonido/vibración indicará alerta
```

### Paso 3: Verificar guardado local
```bash
# Ver archivos guardados
Android: /storage/emulated/0/Documents/alerts/
Desktop: Documentos/alerts/

# Contenido de archivo JSON
{
  "id": "...",
  "synced": false,        # ← Importante: aún no sincronizado
  "latitude_encrypted": "...",
  "timestamp": 1721580600000,
  ...
}
```

### Paso 4: Activar WiFi
```bash
# En el dispositivo
Activa WiFi o Datos Móviles
Espera 10-15 segundos
```

### Paso 5: Verificar sincronización
```bash
# Archivo JSON debería tener:
{
  "synced": true,        # ← Sincronizado!
  "syncedAt": 1721580610000,
  ...
}

# También estará en Firebase:
Firebase → Realtime Database → users/{CI}/alerts/
```

---

## Flujo Completo

```
USUARIO PULSA BOTÓN ROJO
    ↓
¿HAY INTERNET?
    ├─ SÍ → Guardar en Firebase + Local (synced: true)
    └─ NO → Guardar solo Local (synced: false)
    ↓
SE RECUPERA CONEXIÓN
    ↓
OfflineSyncService.syncOfflineAlerts()
    ├─ Busca archivos con synced: false
    ├─ Envía cada uno a Firebase
    └─ Actualiza archivo a synced: true
```

---

## Acceso al Widget de Testing

Opción 1: Desde código (agregar a Home o Navigation):
```dart
import 'lib/testing/testing_page.dart';

// En NavigationBar o Menu:
case 3:
  return TestingPage();
```

Opción 2: Acceso directo en main.dart:
```dart
import 'testing/testing_page.dart';

// En routes:
'/testing': (context) => const TestingPage(),
```

---

## Estructura de Archivos JSON

Ubicación: `/storage/emulated/0/Documents/alerts/alert_*.json`

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

## Logs Importantes

En la consola Flutter, deberías ver:

```
// Inicialización
[OfflineSyncService.initialize] ✓ Inicializado - Online: true

// Alerta activada SIN internet
[AlertService.createAlert] ✓ Guardada localmente (archivo JSON)
[OfflineSyncService] Conectividad cambió: true → false

// Se recupera conexión
[OfflineSyncService] ¡Conexión recuperada! Iniciando sincronización...
[OfflineSyncService.syncOfflineAlerts] Sincronizando 3 alertas...
[OfflineSyncService.syncOfflineAlerts] ✓ Firebase: abc123
[OfflineSyncService.syncOfflineAlerts] ✓ Firebase: def456
[OfflineSyncService.syncOfflineAlerts] Resultados: ✓ 2, ✗ 0
```

---

## Checklist de Verificación

- [ ] ✅ Dispositivo apagado WiFi/datos
- [ ] ✅ Alerta activada mientras offline
- [ ] ✅ Archivo JSON creado en Documents/alerts/
- [ ] ✅ JSON tiene `synced: false`
- [ ] ✅ WiFi/datos activados
- [ ] ✅ Esperó 10-15 segundos
- [ ] ✅ Archivo actualizado a `synced: true`
- [ ] ✅ Firebase tiene el dato en `/users/{CI}/alerts/`

---

## Próximas Fases

### ✅ Fase 4.1: WhatsApp Integration (Lista para implementar)
```dart
// Pseudocódigo en OfflineSyncService.syncOfflineAlerts()
if (alert.synced) {
  await whatsappService.sendNotification(
    phoneNumber: alert.numberCalled,
    message: "Alerta sincronizada: ${alert.description}",
  );
}
```

Ver: `DOCUMENTACION_TECNICA_SINCRONIZACION.md` → Sección "Integración con WhatsApp API"

### Fase 4.2: Base de Datos Local (Opcional)
- Usar `drift` o `isar` para almacenamiento más robusto
- Mejor performance con 100+ alertas
- Sincronización bidireccional

### Fase 4.3: Analytics
- Rastrear alertas por hora/día
- Heatmap de ubicaciones

---

## Troubleshooting

### ❌ "No veo el archivo JSON"
**Solución**: Verifica permisos de almacenamiento
```
Configuración → Aplicaciones → [App] → Permisos → Almacenamiento
```

### ❌ "El archivo no se actualiza a `synced: true`"
**Solución**: 
1. Verifica que Firebase esté configurado
2. Verifica que el CI esté correcto
3. Revisa los logs de la consola

### ❌ "¿Cómo integro WhatsApp?"
**Solución**: Ver `DOCUMENTACION_TECNICA_SINCRONIZACION.md`

---

## Contactos y Recursos

- **Documentación Completa**: `TESTING_SINCRONIZACION_OFFLINE.md`
- **Documentación Técnica**: `DOCUMENTACION_TECNICA_SINCRONIZACION.md`
- **Resumen de Cambios**: `RESUMEN_CAMBIOS_SINCRONIZACION.md`

---

## Estado del Proyecto

✅ **Fase Completada: Sincronización Offline**
- Servicio principal: `OfflineSyncService` → **LISTO**
- Testing visual: `SyncTestingWidget` → **LISTO**
- Documentación: Completa y detallada → **LISTA**
- Compilación: Sin errores críticos → **✓**

📦 **Listo para Testing y Producción**

---

**¿Listo para probar?**

1. Abre la app
2. Apaga WiFi
3. Activa alerta
4. Enciende WiFi
5. ¡Vuela! 🚀

¡Éxito!
