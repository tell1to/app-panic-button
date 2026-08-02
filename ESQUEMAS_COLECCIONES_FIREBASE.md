# 📊 Esquemas de Colecciones Firebase

**Fecha:** 28 de julio de 2026  
**Estado:** ✅ Documentación Corregida y Validada  
**Versión:** 3.0 (sync_metadata removida - no existe en Firebase)

---

## 🎯 Contenido

1. [Visión General](#visión-general)
2. [Estructura Real en Firebase](#estructura-real-en-firebase)
3. [Colecciones Implementadas](#colecciones-implementadas)
4. [Datos Que Envía la App a Firebase](#datos-que-envía-la-app-a-firebase)
5. [Ejemplos JSON](#ejemplos-json)
6. [Datos Almacenados Localmente](#datos-almacenados-localmente)
7. [Reglas de Seguridad](#reglas-de-seguridad)
8. [Consideraciones de Sincronización](#consideraciones-de-sincronización)

---

## 🌍 Visión General

La aplicación utiliza **Firebase Realtime Database** para almacenar **UN SOLO tipo de dato**:

1. **Alertas** (`users/{userId}/alerts`) - Historial de emergencias con snapshot de datos médicos

**IMPORTANTE:** 
- La mayoría de datos del usuario (perfil, contactos, información médica) se mantienen en **almacenamiento local** (SharedPreferences, SecureStorage, JSON files)
- La sincronización se controla **localmente** en el dispositivo, NO en Firebase
- Cada alerta tiene un campo `synced: true/false` que indica si fue guardada en Firebase

### Base de Datos Utilizada
- **Tipo:** Realtime Database (JSON)
- **Región:** Sudamérica (South America)
- **Almacenamiento en Firebase:** Mínimo (solo alertas de emergencia)
- **Almacenamiento Local:** Máximo (datos sensibles, perfil médico, sincronización offline)

---

## 🏗️ Estructura Real en Firebase

```
Firebase Realtime Database
│
└── users/
    └── {userId}                          # CI del usuario
        └── alerts/
            └── {alertId}/
                ├── id
                ├── userId
                ├── timestamp
                ├── status
                ├── ubicacion/
                ├── contactos/
                ├── paciente/
                ├── eventos/
                └── sincronizacion/
                    └── synced (boolean)
```

**Analytics y Crashlytics** se guardan directamente en Firebase Cloud (no en Realtime DB).

**NOTA IMPORTANTE:** 
- **NO existe** `users/{userId}/sync_metadata` en Firebase
- La sincronización se controla **localmente** con archivos JSON y SharedPreferences
- Cada alerta tiene un campo `synced: true/false` para indicar su estado

---

## 📋 Colecciones Implementadas

### **La Única Colección Real en Firebase es: `users/{userId}/alerts`**

**Identificador:** `userId` = Cédula de Identidad (CI)  
**Propósito:** Guardar historial de alertas de emergencia  
**Encriptación:** SÍ (ubicación, números telefónicos)  
**Persistencia:** Firebase + SQLite local (sincronización offline)  
**Índices:** Recomendado por `timestamp` y `status`

#### Estructura JSON (Alerta Individual):

```json
{
  "alert_1722158045234": {
    "id": "alert_1722158045234",
    "userId": "1234567890",
    "timestamp": 1722158045234,
    "date": "28 de Julio de 2026",
    "time": "14:34:05",
    "status": "active",
    "description": "Alerta de pánico activada desde botón principal",
    
    "ubicacion": {
      "latitude_encrypted": "AES:base64_encoded_latitude",
      "longitude_encrypted": "AES:base64_encoded_longitude",
      "ciudad": "Quito",
      "pais": "Ecuador",
      "precision_metros": 15.5
    },
    
    "contactos": {
      "llamadas_realizadas": [
        {
          "numero": "0963522505",
          "nombre": "María Pérez",
          "relacion": "Esposa",
          "timestamp_llamada": 1722158047000,
          "duracion_segundos": 45,
          "estado": "conectada"
        },
        {
          "numero": "911",
          "nombre": "Línea de Emergencia",
          "timestamp_llamada": 1722158048000,
          "duracion_segundos": 120,
          "estado": "conectada"
        }
      ],
      "contactos_notificados": ["0963522505", "911"]
    },
    
    "paciente": {
      "nombres": "Juan",
      "apellidos": "Pérez García",
      "edad": "45",
      "tipoSangre": "O+",
      "patologiasCatastróficas": ["Diabetes Tipo 2", "Hipertensión"],
      "condicionesMedicas": [
        {
          "condicion": "Diabetes",
          "diagnostico_fecha": "2010-05-20",
          "estado": "controlada"
        }
      ],
      "medicamentosHabitales": [
        {
          "nombre": "Metformina",
          "dosis": "500mg",
          "frecuencia": "2 veces al día"
        }
      ],
      "alergias": ["Penicilina", "Pólenes"],
      "sintomas": [
        {
          "sintoma": "Dolor de pecho",
          "intensidad": 8,
          "duracion_minutos": 5,
          "fecha": "2026-07-28T14:30:00Z"
        }
      ],
      "aseguramiento": {
        "aseguradora": "Seguros Pichincha",
        "numero_poliza": "POL-2024-123456",
        "telefono": "1800-SEGUROS",
        "cobertura": "Premium"
      }
    },
    "sincronizacion": {
      "synced": true,
      "fecha_sincronizacion": 1722158050000,
      "intentos_sincronizacion": 1,
      "ultimas_fallos": []
    },
      {
        "tipo": "alerta_iniciada",
        "timestamp": 1722158045234,
        "descripcion": "Botón de pánico activado",
        "fuente": "usuario"
      },
      {
        "tipo": "ubicacion_obtenida",
        "timestamp": 1722158046100,
        "descripcion": "Ubicación GPS adquirida",
        "precision": 15.5
      },
      {
        "tipo": "contacto_llamado",
        "timestamp": 1722158047000,
        "numero": "0963522505",
        "resultado": "exitoso"
      }
    ],
    
    "sincronizacion": {
      "synced": true,
      "fecha_sincronizacion": 1722158050000,
      "intentos_sincronizacion": 1,
      "ultimas_fallos": []
    },
    
    "metadata": {
      "dispositivo": "Samsung Galaxy S21",
      "version_app": "1.0.5",
      "idioma": "es",
      "tipo_red": "4G LTE"
    }
  }
}
```

#### Campos Principales:

| Campo | Tipo | Descripción | Encriptado |
|-------|------|-------------|-----------|
| `id` | String | Identificador único de alerta | No |
| `userId` | String | CI del usuario (referencia) | No |
| `timestamp` | Number | Timestamp en milisegundos | No |
| `status` | String | Estado: `active`, `resolved`, `false_alarm` | No |
| `latitude_encrypted` | String | Latitud encriptada AES-256 | **SÍ** |
| `longitude_encrypted` | String | Longitud encriptada AES-256 | **SÍ** |
| `ciudad` | String | Ciudad obtenida del GPS | No |
| `contactos_notificados` | Array | Números llamados | No |
| `paciente.*` | Object | Snapshot de datos médicos al momento | No |
| `synced` | Boolean | ¿Sincronizado con Firebase? | No |

---

## 📤 Datos Que Envía la App a Firebase

### Cuando se Activa una Alerta

La app envía a Firebase **un snapshot completo** con:

```
✅ DATOS DE LA ALERTA:
   • ID único
   • Timestamp
   • CI del usuario
   • Estado (active/resolved)
   • Descripción
   
✅ UBICACIÓN (encriptada):
   • Latitud y Longitud (AES-256)
   • Ciudad y País (sin encriptar)
   • Precisión GPS
   
✅ CONTACTOS LLAMADOS:
   • Número telefónico
   • Nombre del contacto
   • Duración de la llamada
   • Estado de la conexión
   
✅ SNAPSHOT DEL PACIENTE (en ese momento):
   • Nombres, apellidos, edad
   • Tipo de sangre
   • Alergias
   • Patologías catastróficas
   • Medicamentos habituales
   • Condiciones médicas
   • Síntomas recientes
   • Información de aseguramiento
   
✅ EVENTOS CRONOLÓGICOS:
   • Alerta iniciada
   • Ubicación obtenida
   • Contacto llamado
   • Resolutivo realizado
   
✅ METADATA:
   • Dispositivo usado
   • Versión de app
   • Tipo de red
   • Idioma
```

---

## 📝 Ejemplos JSON Completos

### Ejemplo 1: Alerta Completa Guardada en Firebase

```json
{
  "id": "alert_1722158045234",
  "userId": "1234567890",
  "timestamp": 1722158045234,
  "date": "28 de Julio de 2026",
  "time": "14:34:05",
  "status": "active",
  "description": "Alerta de pánico - Botón presionado",
  
  "ubicacion": {
    "latitude_encrypted": "AES:SGVsbG8gV29ybGQ=",
    "longitude_encrypted": "AES:VGhpcyBpcyBhIHNlY3JldA==",
    "ciudad": "Quito",
    "pais": "Ecuador",
    "precision_metros": 15.5
  },
  
  "contactos": {
    "llamadas_realizadas": [
      {
        "numero": "0963522505",
        "nombre": "María Pérez",
        "relacion": "Esposa",
        "timestamp_llamada": 1722158047000,
        "duracion_segundos": 45,
        "estado": "conectada"
      },
      {
        "numero": "911",
        "nombre": "Línea de Emergencia",
        "timestamp_llamada": 1722158048000,
        "duracion_segundos": 120,
        "estado": "conectada"
      }
    ],
    "contactos_notificados": ["0963522505", "911"]
  },
  
  "paciente": {
    "nombres": "Juan",
    "apellidos": "Pérez García",
    "edad": "45",
    "tipoSangre": "O+",
    "patologiasCatastróficas": ["Diabetes Tipo 2", "Hipertensión"],
    "medicamentosHabitales": [
      {
        "nombre": "Metformina",
        "dosis": "500mg",
        "frecuencia": "2 veces al día"
      }
    ],
    "alergias": ["Penicilina"],
    "aseguramiento": {
      "aseguradora": "Seguros Pichincha",
      "numero_poliza": "POL-2024-123456",
      "telefono": "1800-SEGUROS"
    }
  },
  
  "eventos": [
    {
      "tipo": "alerta_iniciada",
      "timestamp": 1722158045234,
      "descripcion": "Botón de pánico activado",
      "fuente": "usuario"
    },
    {
      "tipo": "ubicacion_obtenida",
      "timestamp": 1722158046100,
      "precision": 15.5
    },
    {
      "tipo": "contacto_llamado",
      "timestamp": 1722158047000,
      "numero": "0963522505",
      "resultado": "exitoso"
    }
  ],
  
  "sincronizacion": {
    "synced": true,
    "fecha_sincronizacion": 1722158050000,
    "intentos_sincronizacion": 1
  }
}
```

---

## 💾 Datos Almacenados Localmente (NO en Firebase)

### En SharedPreferences

```
✅ PERFIL DEL USUARIO:
   • Nombres y apellidos
   • Edad y fecha de nacimiento
   • Tipo de sangre
   • CI
   
✅ ALERGIAS:
   • Lista de alergias (JSON array)
   
✅ PATOLOGÍAS:
   • Lista de patologías catastróficas
   
✅ MEDICAMENTOS:
   • Nombre, dosis, frecuencia
   
✅ CONDICIONES MÉDICAS:
   • Diagnóstico y estado
   
✅ ASEGURAMIENTO:
   • Compañía de seguros
   • Número de póliza
   • Teléfono de emergencia
   
✅ CONTACTOS:
   • Nombre, teléfono, relación
   • Contacto preferido
   
✅ CONFIGURACIÓN:
   • Idioma
   • Preferencias de notificaciones
   • Última ubicación conocida
```

### En SecureStorage

```
🔐 DATOS SENSIBLES:
   • CI del usuario (clave maestra)
   • FCM Token (para notificaciones)
   • Otros datos críticos
```

### En Archivos JSON Locales

```
📄 ALMACENAMIENTO OFFLINE:
   • Alertas locales (cuando no hay conexión)
   • Cache de ubicación
   • Datos de sincronización pendientes
```

---

## 🔗 Relaciones entre Entidades

### Diagrama Simplificado

```
┌─────────────────────────────────────────┐
│       USUARIO (CI: 1234567890)          │
│    (Almacenado en Memoria Local)        │
│  • Nombres, apellidos, edad             │
│  • Alergias, medicamentos               │
│  • Condiciones médicas                  │
│  • Datos de aseguramiento               │
│  • Contactos de emergencia              │
└────────────────┬────────────────────────┘
                 │
        (Envía datos en cada alerta)
                 │
                 ▼
┌─────────────────────────────────────────┐
│  FIREBASE: users/{userId}/alerts        │
│  (Múltiples alertas por usuario)        │
│  • alert_1722158045234                  │
│  • alert_1722158145234                  │
│  • alert_1722158245234                  │
│  └─ Contiene snapshot del paciente      │
│  └─ Ubicación encriptada                │
│  └─ Historial de eventos                │
└─────────────────────────────────────────┘
```

### Relación N:1

- **Un usuario (CI)** → **Múltiples alertas** (N)
- **Clave de relación:** `alerts.userId` = `users.{userId}`
- **Cardinalidad:** 1:N

```
users/
└── 1234567890/
    └── alerts/
        ├── alert_1722158045234
        ├── alert_1722158145234
        ├── alert_1722158245234
        └── ...
```

---

## 🔐 Reglas de Seguridad Recomendadas

### Reglas Básicas (Producción)

```json
{
  "rules": {
    "users": {
      "$uid": {
        // Solo el usuario puede leer sus alertas
        ".read": "auth != null && auth.uid == $uid",
        
        // Solo el usuario puede escribir alertas
        ".write": "auth != null && auth.uid == $uid",
        
        "alerts": {
          "$alertId": {
            ".read": "auth.uid == $uid",
            ".write": "auth.uid == $uid",
            ".validate": "newData.hasChildren(['id', 'userId', 'timestamp', 'status'])"
          }
        }
      }
    }
  }
}
```

---

## 🔄 Consideraciones de Sincronización

### Flujo de Sincronización Offline

```
┌─────────────────────────────────────────────┐
│       CICLO DE SINCRONIZACIÓN OFFLINE       │
└─────────────────────────────────────────────┘

1. APP EN LÍNEA
   ├─ Crear alerta en Firebase
   ├─ Guardar en SQLite local
   └─ Marcar como synced=true

2. APP PIERDE CONEXIÓN
   ├─ Detectar offline (Connectivity plugin)
   ├─ Guardar datos pendientes en SQLite
   └─ Mostrar indicador "Modo Offline"

3. APP EN OFFLINE
   ├─ Permitir crear alertas locales
   ├─ Almacenar en caché local
   ├─ Encriptar datos sensibles
   └─ Marcar synced=false

4. APP RECUPERA CONEXIÓN
   ├─ Detectar cambio a online
   ├─ Iniciar sincronización
   ├─ Enviar alertas pendientes a Firebase
   ├─ Validar encriptación
   ├─ Resolver conflictos (última escritura gana)
   └─ Marcar como synced=true

5. SINCRONIZACIÓN COMPLETADA
   ├─ Actualizar timestamp local de sincronización
   ├─ Marcar `synced=true` en la alerta (Firebase)
   └─ Notificar al usuario
```

---

## 📊 Estadísticas de Almacenamiento

### Estimación de Tamaño

| Tipo | Tamaño Promedio |
|------|-----------------|
| Alerta completa | ~5 KB |
| Evento individual | ~0.5 KB |

### Cálculo Ejemplo

Para **1,000 usuarios** con **2 alertas/día** durante **30 días**:

```
Alertas:       1,000 × 2 × 30 × 5 KB = 300 MB
────────────────────────────────────────────
TOTAL:         ~300 MB (en Firebase)

LOCAL STORAGE: ~2-5 GB por dispositivo
```

---

## 📚 Servicios Que Interactúan con Firebase

### AlertService
- **Crear alertas** → `users/{userId}/alerts/{alertId}`
- **Actualizar estado** → `users/{userId}/alerts/{alertId}/status`
- Controla sincronización localmente (SyncService)

### OfflineSyncService
- Guardar alertas pendientes **localmente** (archivos JSON)
- Sincronizar cuando hay conexión
- Resolver conflictos de datos

### SyncService
- Marcar alertas como sincronizadas **localmente** (SharedPreferences)
- Registrar intentos fallidos
- Controlar estado de sincronización en el dispositivo

### NotificationService
- Obtener FCM token (**NO lo guarda en Firebase**)
- Manejar notificaciones push

### FirebaseService
- Log de eventos con Analytics
- Reporte de errores con Crashlytics

---

## ✅ Checklist: Lo Que Está Implementado

- [x] Crear alertas en Firebase
- [x] Almacenar ubicación encriptada
- [x] Guardar datos médicos del paciente
- [x] Sincronización offline **local** (archivos JSON)
- [x] Rate limiting en alertas
- [x] Analytics (eventos)
- [x] Crashlytics (errores)
- [ ] ~~Colección de dispositivos~~ ❌ NO EXISTE
- [ ] ~~FCM tokens guardados en Firebase~~ ❌ NO SE IMPLEMENTÓ
- [ ] ~~Perfil del usuario en Firebase~~ ❌ Está solo en local

---

## ⚠️ Notas Importantes

1. **NO hay autenticación Firebase:** El identificador es solo la CI, no hay auth.uid
2. **NO hay colección devices:** Los FCM tokens se obtienen pero no se guardan en Firebase
3. **NO hay sync_metadata en Firebase:** La sincronización se controla **localmente** en el dispositivo
4. **NO hay profile en Firebase:** Se almacena todo localmente en SharedPreferences/SecureStorage
5. **Datos sensibles locales:** La mayoría del perfil médico nunca sale del dispositivo
6. **Solo alertas en Firebase:** Es la única colección que persiste en la base de datos
7. **Firebase usado principalmente para:** 
   - Almacenar alertas de emergencia
   - Registros históricos de incidentes
   - Analytics y monitoreo de errores (Crashlytics)

---

**Última Actualización:** 28 de julio de 2026  
**Estado:** ✅ Corregida según código real  
**Versión App:** 1.0.5
