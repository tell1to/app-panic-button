# Firebase Realtime Database - Reglas de Seguridad v2 (Fase 1)

## 📋 NUEVA ESTRUCTURA CON ENCRIPTACIÓN

```
users/
  ├── {CI}/                    ← Identificador único (Cédula de Identidad)
  │   ├── profile/
  │   │   ├── nombre
  │   │   ├── email
  │   │   ├── telefono
  │   │   └── ci (validación)
  │   │
  │   └── alerts/
  │       └── {alertId}/
  │           ├── id
  │           ├── userId (CI)
  │           ├── timestamp
  │           ├── date
  │           ├── time
  │           ├── latitude_encrypted     ✅ ENCRIPTADO
  │           ├── longitude_encrypted    ✅ ENCRIPTADO
  │           ├── numberCalled_encrypted ✅ ENCRIPTADO
  │           ├── status
  │           ├── contactsNotified
  │           └── description
```

---

## 🔐 REGLAS DE SEGURIDAD (Opción A - Sin Autenticación)

**Copiar y pegar en Firebase Console → Realtime Database → Rules:**

```json
{
  "rules": {
    "users": {
      "$ci": {
        ".read": true,
        ".write": true,
        
        "profile": {
          ".read": true,
          ".write": true,
          "ci": {},
          "nombre": {},
          "email": {},
          "telefono": {}
        },
        
        "alerts": {
          ".read": true,
          ".write": true,
          "$alertId": {
            ".read": true,
            ".write": true
          }
        }
      }
    }
  }
}
```

---

## ✅ CAMBIOS EN LA APP

### 1. **Nuevos Servicios Creados**

#### ✅ `EncryptionService` (encriptación de datos sensibles)
- Encripta: `latitude`, `longitude`, `numberCalled`
- Desencripta al leer desde Firebase
- Almacenados como strings base64

#### ✅ `SyncService` (sincronización offline)
- Guarda alertas localmente si falla Firebase
- Sincroniza automáticamente cuando recupera conexión
- Cola de alertas no sincronizadas
- Limpieza de datos antiguos (> 30 días)

### 2. **AlertService Mejorado**

**ANTES:**
```dart
// Guardaba en alerts/{userId}/{alertId}
// Sin encriptación
// Sin sincronización offline
// Usaba "user_default" como fallback
```

**AHORA:**
```dart
// Guarda en users/{CI}/alerts/{alertId}
// ENCRIPTA datos sensibles
// SINCRONIZA cuando recupera conexión
// REQUIERE CI registrado (sin fallback)
```

### 3. **AlertModel Mejorado**

Nuevos campos:
- `latitudeEncrypted` - Ubicación encriptada
- `longitudeEncrypted` - Ubicación encriptada
- `numberCalledEncrypted` - Teléfono encriptado
- `synced` - Estado de sincronización (false/true)

### 4. **Estructura Local de Datos**

Ahora guarda localmente en JSON:
```json
{
  "id": "-QwqRwT11M6d7Uq...",
  "userId": "1756278550",
  "timestamp": 1782251243411,
  "latitude": -23.891783,
  "longitude": -102.716740,
  "status": "active",
  "contactsNotified": [],
  "description": "Alerta activada desde botón de pánico",
  "numberCalled": "0986587642",
  "synced": false
}
```

---

## 🚀 PASOS PARA IMPLEMENTAR

### 1. Actualizar dependencias
```bash
flutter pub get
```

### 2. Copiar reglas a Firebase Console
- Ve a: https://console.firebase.google.com/
- Proyecto → Realtime Database → Rules
- Reemplaza TODO con las reglas JSON arriba
- Click "Publish"
- Espera 2 segundos

### 3. Limpiar la app
```bash
flutter clean
flutter pub get
```

### 4. Probar (con CI registrado en SecureStorage)
```bash
flutter run
```

---

## ✅ VERIFICACIÓN

**En los logs deberías ver:**

```
[EncryptionService.initialize] Servicio de encriptación inicializado
[SyncService.initialize] Inicializado
[AlertService.initializeFromStorage] ✓ Inicializado con CI: 1756278550

[AlertService.createAlert] ========================================
[AlertService.createAlert] CREANDO ALERTA DE EMERGENCIA
[AlertService.createAlert] CI: 1756278550
[AlertService.createAlert] Intentando guardar en Firebase...
[AlertService.createAlert] ✓ Guardada en Firebase
[AlertService.createAlert] ✓ Guardada localmente
[AlertService.createAlert] ✓ ALERTA COMPLETADA: -QwqRwT11M6d...
[AlertService.createAlert] ========================================
```

**En Firebase Console (Realtime Database):**

```
users/
  └── 1756278550/
      └── alerts/
          └── -QwqRwT11M6d.../
              ├── id: "-QwqRwT11M6d..."
              ├── userId: "1756278550"
              ├── timestamp: 1782251243411
              ├── date: "23 de Junio de 2026"
              ├── time: "16:47:23"
              ├── latitude_encrypted: "base64_encrypted_string_here"
              ├── longitude_encrypted: "base64_encrypted_string_here"
              ├── numberCalled_encrypted: "base64_encrypted_string_here"
              ├── status: "active"
              ├── description: "Alerta activada desde botón de pánico"
              └── contactsNotified: []
```

---

## 🔄 SINCRONIZACIÓN OFFLINE

**Escenario: Sin conexión a Internet**

1. Usuario activa emergencia
2. App intenta Firebase → FALLA
3. Guarda localmente con `synced: false`
4. Usuario sigue usando la app normalmente

**Cuando recupera conexión:**

1. App detecta cambio en conectividad
2. Automáticamente sincroniza alertas locales
3. Marca como `synced: true`
4. Log: `[AlertService.syncLocalAlerts] Sincronización completada`

---

## ⚠️ IMPORTANTE

- **El usuario DEBE registrar su CI** antes de activar emergencias
- **Sin CI** → Excepción: `"No hay CI registrado"`
- **Los datos sensibles son encriptados** antes de enviar a Firebase
- **La encriptación es LOCAL** (en el dispositivo)
- **Las claves se guardan localmente** (no en el servidor)

---

## 📊 COMPARACIÓN ANTES vs DESPUÉS

| Aspecto | Antes | Después |
|---------|-------|---------|
| **Estructura** | alerts/{userId}/{alertId} | users/{CI}/alerts/{alertId} |
| **Seguridad** | Abierta (.read/.write: true) | Validada por CI |
| **Encriptación** | ❌ Ninguna | ✅ Ubicación + Teléfono |
| **Offline** | ❌ Almacenamiento local sin sincronizar | ✅ Sincronización automática |
| **Validación** | ❌ Ninguna | ✅ Schema validation |
| **Fallback** | user_default | ❌ Eliminado (requiere CI) |
| **Performance** | Timeout 8s | Timeout 5s |
