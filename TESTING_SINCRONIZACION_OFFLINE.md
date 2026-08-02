# 📡 Guía de Testing: Sincronización Offline de Alertas

## Objetivo
Probar que las alertas se guardan localmente cuando no hay internet y se sincronizan automáticamente cuando se recupera la conexión.

## Requisitos Previos
- ✅ Dispositivo Android con Flutter instalado
- ✅ WiFi y datos móviles disponibles
- ✅ Firebase configurado correctamente
- ✅ CI registrado en la app (ver Configuración)

## Estructura de Archivos
Las alertas se guardan localmente en:
- **Android**: `/storage/emulated/0/Documents/alerts/`
- **Desktop**: `Documentos/alerts/`
- **iOS**: `App Documents/alerts/`

Cada alerta es un archivo JSON con la estructura:
```json
{
  "id": "alert_id_123",
  "userId": "1756278550",
  "timestamp": 1234567890,
  "date": "Julio 21 del 2026",
  "time": "02:30 pm",
  "status": "active",
  "description": "Alerta de prueba",
  "latitude": -0.123456,
  "longitude": -78.654321,
  "latitude_encrypted": "base64_encrypted_data",
  "longitude_encrypted": "base64_encrypted_data",
  "numberCalled_encrypted": "base64_encrypted_data",
  "synced": false,
  "createdAt": 1234567890,
  "syncedAt": null
}
```

---

## Prueba Paso a Paso

### Paso 1: Verificar Configuración
1. Abre la app
2. Ve a **Configuración** → Perfil
3. Verifica que tu **CI** esté registrado
4. Si no está, regístralo ahora

### Paso 2: Preparar el Dispositivo (OFFLINE)
1. **Apaga WiFi**: Desliza desde arriba → Desactiva WiFi
2. **Apaga Datos Móviles**: Desliza desde arriba → Desactiva Datos Móviles
3. **Verifica que esté offline**: Abre cualquier app que use internet (debería fallar)

### Paso 3: Activar Alerta en Offline
1. Vuelve a la app (debe mostrar "sin conexión" si tienes un indicador)
2. **En la pantalla Inicio**: Mantén presionado el botón rojo (botón de pánico) ~1.2 segundos
3. Deberías escuchar un sonido y/o ver una confirmación
4. **Importante**: Se hará un intento de llamada (puedes cancelar o esperar)

### Paso 4: Verificar Guardado Local
1. Ve a **Configuración** → Más opciones → (si existe)
2. **O**: Accede directamente a la carpeta del dispositivo:
   - Abre el **File Manager**
   - Ve a `Storage/Documents/alerts/`
   - Deberías ver un archivo `.json` recién creado
   - **Abre el archivo** y verifica que tenga:
     - ✅ `id`, `userId`, `timestamp`, `date`, `time`
     - ✅ `latitude_encrypted`, `longitude_encrypted`, `numberCalled_encrypted`
     - ✅ `"synced": false` (no sincronizado)

### Paso 5: Activar Conexión
1. **Activa WiFi**: Desliza desde arriba → Activa WiFi
2. **O Datos Móviles**: Desliza desde arriba → Activa Datos Móviles
3. Espera 5-10 segundos para que se estabilice la conexión

### Paso 6: Verificar Sincronización
1. **Opción A** (Automática):
   - Espera 10-15 segundos
   - El archivo JSON debería actualizarse: `"synced": true`, `"syncedAt": timestamp`

2. **Opción B** (Manual - Herramienta de Testing):
   - En la app, ve a **Configuración** (o una sección de Testing si existe)
   - Busca botón **"🧪 Testing"** o similar
   - Pulsa **"Sincronizar"**
   - Verifica el estado en la pantalla

### Paso 7: Verificar Firebase
1. Abre [Firebase Console](https://console.firebase.google.com/)
2. Ve a tu proyecto
3. **Realtime Database** → `users/[TU_CI]/alerts/`
4. Deberías ver una nueva alerta con los datos

---

## Widget de Testing (Herramienta Visual)

Si accedes a la página de testing, verás:

### 🎮 Controles Disponibles
- **ONLINE/OFFLINE**: Simula cambios de conectividad
- **Sincronizar**: Fuerza sincronización manual
- **Eliminar Todas**: Borra archivos de prueba
- **Actualizar**: Recarga estadísticas

### 📊 Estadísticas Mostradas
```
Total alertas: 5
Sincronizadas: 3
Pendientes: 2
Estado: ONLINE
```

### 📋 Alertas Listadas
- Click en expandir para ver detalles completos
- Verifica campos encriptados
- Confirma `synced: true/false`

---

## Casos de Prueba

### ✅ Test 1: Guardado Básico
- **Pasos**: 2-4
- **Resultado Esperado**: Archivo JSON en `Documents/alerts/` con `synced: false`

### ✅ Test 2: Sincronización Automática
- **Pasos**: 2-7 (Todo el flujo)
- **Resultado Esperado**: Archivo actualizado a `synced: true` + Dato en Firebase

### ✅ Test 3: Múltiples Alertas
- **Pasos**: 
  1. Apagar WiFi
  2. Activar 3-4 alertas
  3. Activar WiFi
  4. Verifica que todas se sincronicen
- **Resultado Esperado**: 3-4 archivos con `synced: true`

### ✅ Test 4: Datos Encriptados
- **Pasos**: 
  1. Activa una alerta en offline
  2. Abre el archivo JSON
- **Resultado Esperado**: 
  - `latitude_encrypted`, `longitude_encrypted`, `numberCalled_encrypted` tienen valores base64
  - No puedes leerlos directamente (están encriptados)

---

## Troubleshooting

### ❌ "No se guardó el archivo"
- **Causa**: Permiso de acceso a almacenamiento
- **Solución**: 
  1. Abre Configuración del dispositivo
  2. Permisos → Archivos
  3. Dale permiso a la app

### ❌ "El archivo no se actualiza a `synced: true`"
- **Causa**: Firebase no sincronizó
- **Solución**:
  1. Verifica que FirebaseAuth esté configurado
  2. Verifica que el CI esté correcto
  3. Fuerza sincronización desde Testing widget

### ❌ "Firebase no tiene los datos"
- **Causa**: Reglas de seguridad en Firebase
- **Solución**:
  1. Ve a Firebase Console → Database → Reglas
  2. Verifica que permita escribir en `users/{userId}/alerts/`
  ```json
  {
    "rules": {
      "users": {
        "{uid}": {
          "alerts": {
            ".write": true,
            ".read": true
          }
        }
      }
    }
  }
  ```

### ❌ "La app se crashea con OfflineSyncService"
- **Causa**: Directorio no existe o permisos insuficientes
- **Solución**:
  1. Verifica que tienes `path_provider` en pubspec.yaml
  2. Asegúrate de que `connectivity_plus` está actualizado
  3. Revisa el log de errores en la consola

---

## Escalabilidad: Integración con WhatsApp API

El diseño actual permite fácilmente agregar:

1. **Servicio de Notificaciones**: 
   ```dart
   // Pseudocódigo
   for (var alert in unsyncedAlerts) {
     await whatsappService.sendNotification(
       phoneNumber: alert.numberCalled,
       message: alert.description,
     );
   }
   ```

2. **Sincronización a Backend Personalizado**:
   ```dart
   // En OfflineSyncService.syncOfflineAlerts()
   // Además de Firebase, envía a tu API:
   await customApi.postAlert(alert.toJson());
   ```

3. **Base de Datos Local (Drift/Isar)**:
   - Almacena alertas de manera más persistente
   - Mejor rendimiento con muchas alertas
   - Fácil sincronización bidireccional

---

## Checklist de Testing Completo

- [ ] ✅ CI registrado en la app
- [ ] ✅ WiFi apagado
- [ ] ✅ Alerta activada en offline
- [ ] ✅ Archivo JSON creado en `Documents/alerts/`
- [ ] ✅ JSON tiene `synced: false`
- [ ] ✅ WiFi activado
- [ ] ✅ Archivo actualizado a `synced: true`
- [ ] ✅ Firebase tiene el dato
- [ ] ✅ Datos de ubicación encriptados
- [ ] ✅ `userId` correcto

---

## Logs Importantes

Para debugging, mira los logs en la consola:

```
[OfflineSyncService.initialize] Inicializando...
[OfflineSyncService] Conectividad cambió: true → false
[AlertService.createAlert] ✓ Guardada localmente (archivo JSON)
[OfflineSyncService] ¡Conexión recuperada! Iniciando sincronización...
[OfflineSyncService.syncOfflineAlerts] Sincronizando 1 alertas...
[OfflineSyncService.syncOfflineAlerts] ✓ Firebase: alert_123
```

---

## Próximos Pasos

Después de validar que la sincronización funciona:

1. **Integrar WhatsApp API**:
   - Usar `whatsapp_business_api` o `twilio`
   - Llamar en `syncOfflineAlerts()` cuando se sincronice

2. **Agregar Base de Datos Local**:
   - Usar `drift` o `isar`
   - Guardar alertas localmente de forma más robusta

3. **Metricas y Analytics**:
   - Firebase Analytics: Rastrear alertas por hora/día
   - Dashboard para ver patrones

4. **Testing Automatizado**:
   - Tests unitarios para `OfflineSyncService`
   - Tests de integración con Firebase

---

## Contacto / Preguntas

Si encuentras problemas:
1. Verifica que todas las dependencias en `pubspec.yaml` estén actualizadas
2. Ejecuta `flutter clean && flutter pub get`
3. Revisa los logs de la consola
4. Intenta en un dispositivo/emulador diferente
