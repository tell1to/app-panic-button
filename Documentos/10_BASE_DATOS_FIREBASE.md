# Base de Datos Firebase - Estructura y Configuración
**Última actualización:** 2 de agosto de 2026  
**Versión:** 2.0  
**Estado:** Producción
---

## Índice
1. [Descripción General](#descripción-general)
2. [Estructura de Colecciones](#estructura-de-colecciones)
3. [Esquema de Datos Detallado](#esquema-de-datos-detallado)
4. [Reglas de Seguridad Firebase](#reglas-de-seguridad-firebase)
5. [Ejemplo Real de Datos](#ejemplo-real-de-datos)
6. [Encriptación de Datos](#encriptación-de-datos)
7. [Operaciones de Base de Datos](#operaciones-de-base-de-datos)
8. [Consideraciones de Rendimiento](#consideraciones-de-rendimiento)

---

## Descripción General

### ¿Qué es Firebase Realtime Database?
Firebase Realtime Database es una base de datos NoSQL hospedada en la nube que sincroniza datos en tiempo real. La aplicación utiliza esta plataforma para:

- **Almacenar alertas de emergencia** con ubicación y datos del paciente
- **Persistir información médica** del usuario (perfil, medicamentos, alergias, condiciones)
- **Mantener historial de eventos** de emergencia
- **Sincronización offline** con posterior sincronización cuando hay conexión

### Características Principales
- ✅ Sincronización en tiempo real
- ✅ Almacenamiento jerárquico de datos
- ✅ Acceso mediante reglas de seguridad personalizables
- ✅ Integración con autenticación Firebase
- ✅ Respaldo automático de datos
- ✅ Encriptación en tránsito (HTTPS)

---

## Estructura de Colecciones

### Arquitectura General

```
Firebase Realtime Database
└── users/                                [Raíz de usuarios]
    └── {userId}/                         [Documento del usuario: 1756278551]
        └── alerts/                       [Subcollección de alertas]
            ├── -Oyp2d-w1Onhh8FpqG5L/    [Alert ID 1 (generado por Firebase)]
            │   ├── date: "30 de Julio de 2026"
            │   ├── descripcion: "Alerta de pánico activada"
            │   ├── id: "-Oyp-DwRWNWRxqjk0Y6J"
            │   ├── latitude_encrypted: "4hFmM5ncw8iUb5Zth3hnUw=="
            │   ├── longitude_encrypted: "4hZwLJ3cyMGSb5Zth3hnUw=="
            │   ├── numberCalled_encrypted: "9hB5D6Tn/PWsZZxnjXJtWQ=="
            │   └── paciente/             [Datos médicos en el momento de la alerta]
            │       ├── status: "active"
            │       ├── time: "16:49:25"
            │       ├── timestamp: 1785448165149
            │       └── userId: "1756278551"
            │
            ├── -Oyoqy4YpICuihDwzCrI/    [Alert ID 2]
            │   ├── date: "..."
            │   ├── paciente/
            │   └── ...
            │
            └── -OypBTV8poboYOP4x0_0/    [Alert ID N]
                ├── date: "..."
                └── ...
```

### Desglose de Colecciones

#### 1. **Colección: `users`**
- **Tipo:** Raíz de la estructura
- **Documentos:** Uno por usuario registrado
- **Clave:** ID único del usuario (número como string: "1756278551")
- **Contenido:** Subcollección de alertas con datos embebidos

#### 2. **Subcollección: `users/{userId}/alerts`**
- **Tipo:** Array de alertas de emergencia
- **Documentos:** Uno por cada alerta activada
- **Clave:** ID único generado automáticamente por Firebase (ej: "-Oyp2d-w1Onhh8FpqG5L")
- **Contenido:** Datos de la alerta + subdocumento `paciente` con contexto médico del momento

#### 3. **Subdocumento: `users/{userId}/alerts/{alertId}/paciente`**
- **Tipo:** Documento anidado dentro de cada alerta
- **Contenido:** Snapshot de datos médicos del paciente al momento de la alerta
- **Campos:** status, time, timestamp, userId (mínimo requerido)

---

## Esquema de Datos Detallado

### 1. Estructura del Usuario (root level)

```javascript
users/{userId} {
  alerts: {}        // Subcollección con alertas históricas
}
```

---

### 2. Estructura de Alertas: `users/{userId}/alerts/{alertId}`

| Campo | Tipo | Requerido | Descripción |
|-------|------|-----------|-------------|
| `id` | String | ✅ | Identificador único de la alerta (generado por Firebase) |
| `date` | String | ✅ | Fecha formateada (ej: "30 de Julio de 2026") |
| `descripcion` | String | ✅ | Descripción de la alerta (ej: "Alerta de pánico activada") |
| `latitude_encrypted` | String | ✅ | Latitud encriptada en Base64 |
| `longitude_encrypted` | String | ✅ | Longitud encriptada en Base64 |
| `numberCalled_encrypted` | String | ✅ | Teléfono llamado encriptado en Base64 |
| `paciente` | Object | ✅ | Subdocumento con datos médicos en el momento |
| `city_encrypted` | String | ❌ | Ciudad encriptada (opcional) |
| `country_encrypted` | String | ❌ | País encriptado (opcional) |

#### Ejemplo de Alerta Completa
```json
{
  "date": "30 de Julio de 2026",
  "descripcion": "Alerta de pánico activada",
  "id": "-Oyp-DwRWNWRxqjk0Y6J",
  "latitude_encrypted": "4hFmM5ncw8iUb5Zth3hnUw==",
  "longitude_encrypted": "4hZwLJ3cyMGSb5Zth3hnUw==",
  "numberCalled_encrypted": "9hB5D6Tn/PWsZZxnjXJtWQ==",
  "paciente": {
    "status": "active",
    "time": "16:49:25",
    "timestamp": 1785448165149,
    "userId": "1756278551"
  }
}
```

---

### 3. Subdocumento: `users/{userId}/alerts/{alertId}/paciente`

Este es un **snapshot de datos médicos** guardado en el momento de la alerta. Contiene:

| Campo | Tipo | Descripción |
|-------|------|-------------|
| `userId` | String | ID del usuario (referencia) |
| `status` | String | Estado del perfil ("active", "inactive", "suspended") |
| `time` | String | Hora formateada de cuando ocurrió la alerta |
| `timestamp` | Integer | Millisegundos desde epoch (1970) |

#### Nota Importante
El subdocumento `paciente` dentro de cada alerta es **diferente** del perfil completo guardado en el cliente. Contiene solo información esencial para registrar el contexto de emergencia.

---

### 4. Perfil Médico Completo (guardado en el cliente)

Aunque no está como documento raíz en Firebase visible en la estructura, la aplicación mantiene el perfil completo sincronizado:

#### Estructura Completa del Paciente

```json
{
  "userId": "1756278551",
  "nombres": "Hugo",
  "apellidos": "Murillo Doce",
  "edad": 21,
  "tipoSangre": "O+",
  "status": "active",
  "timestamp": 1785448165149,
  "time": "16:49:25",
  "patologiasCatastróficas": [
    "Cáncer",
    "Epilepsia"
  ],
  "alergias": [
    "Panadería",
    "Nuez",
    "Trabajo"
  ],
  "condicionesMedicas": [
    {
      "diagnosis": "Hoiladsldd kdksskksdm...",
      "since": "16/07/2026"
    },
    {
      "diagnosis": "Rodilla Rota",
      "since": "29/07/2026"
    }
  ],
  "medicamentosHabitales": [
    {
      "name": "Ibuprofeno",
      "dose": "500mg",
      "frequency": "Cada 8 horas"
    },
    {
      "name": "Paracetamol",
      "dose": "500mg",
      "frequency": "Cada 6 horas"
    }
  ],
  "sintomas": [
    {
      "date": "2026-07-30T16:48:45.009028",
      "id": 1,
      "severity": 6,
      "symptoms": "Dolor intenso rodilla derecha a la altura de la unión con el muslo"
    }
  ]
}
```

---

### 3.1 Arreglo: `patologiasCatastróficas`
```json
"patologiasCatastróficas": [
  "Cáncer",
  "Epilepsia",
  "Insuficiencia Cardíaca"
]
```
**Descripción:** Lista de enfermedades crónicas graves del paciente.

#### 3.2 Arreglo: `alergias`
```json
"alergias": [
  "Panadería",
  "Nuez",
  "Penicilina"
]
```
**Descripción:** Alergias conocidas del paciente (alimentos, medicinas, etc.).

#### 3.3 Arreglo: `condicionesMedicas`
```json
"condicionesMedicas": [
  {
    "diagnosis": "Hoiladsldd kdksskksdm kssk sksk kkkk qqq msdowee...",
    "since": "16/07/2026"
  },
  {
    "diagnosis": "Rodilla Rota",
    "since": "29/07/2026"
  }
]
```
**Campos:**
- `diagnosis` (String): Descripción de la condición médica
- `since` (String): Fecha de diagnóstico (formato DD/MM/YYYY)

#### 3.4 Arreglo: `medicamentosHabitales`
```json
"medicamentosHabitales": [
  {
    "name": "Ibuprofeno",
    "dose": "500mg",
    "frequency": "Cada 8 horas"
  },
  {
    "name": "Paracetamol",
    "dose": "500mg",
    "frequency": "Cada 6 horas"
  }
]
```
**Campos:**
- `name` (String): Nombre del medicamento
- `dose` (String): Dosis recomendada
- `frequency` (String): Frecuencia de administración

#### 3.5 Arreglo: `sintomas`
```json
"sintomas": [
  {
    "date": "2026-07-30T16:48:45.009028",
    "id": 1,
    "severity": 6,
    "symptoms": "Dolor intenso rodilla derecha a la altura de la unión con el muslo"
  }
]
```
**Campos:**
- `date` (String ISO-8601): Fecha y hora del síntoma
- `id` (Integer): Identificador único del síntoma
- `severity` (Integer): Gravedad de 1-10
- `symptoms` (String): Descripción del síntoma

#### Ejemplo Completo de Paciente
```json
{
  "alergias": ["Panadería", "Nuez", "Trabajo"],
  "apellidos": "Murillo Doce",
  "condicionesMedicas": [
    {
      "diagnosis": "Hoiladsldd kdksskksdm kssk sksk kkkk qqq msdowee, heueuucn msmsmjmsÑ jjewjejkejÑ.s jsjjsjsjs",
      "since": "16/07/2026"
    },
    {
      "diagnosis": "Rodilla Rota",
      "since": "29/07/2026"
    }
  ],
  "edad": 21,
  "medicamentosHabitales": [
    {"name": "Ibuprofeno", "dose": "500mg", "frequency": "Cada 8 horas"},
    {"name": "Paracetamol", "dose": "500mg", "frequency": "Cada 6 horas"}
  ],
  "nombres": "Hugo",
  "patologiasCatastróficas": ["Cáncer", "Epilepsia"],
  "sintomas": [
    {
      "date": "2026-07-30T16:48:45.009028",
      "id": 1,
      "severity": 6,
      "symptoms": "Dolor intenso rodilla derecha a la altura de la unión con el muslo"
    }
  ],
  "userId": "1756278551",
  "tipoSangre": "O+",
  "status": "active",
  "time": "16:49:25",
  "timestamp": 1785448165149
}
```

---

## Reglas de Seguridad Firebase

### Archivo: `firebase-rules.json`

Las reglas de Firebase Realtime Database controlan quién puede leer y escribir datos. 

```json
{
  "rules": {
    "users": {
      "$uid": {
        ".read": "auth.uid === $uid",
        ".write": "auth.uid === $uid",
        
        "alerts": {
          ".read": "auth.uid === $uid",
          ".write": "auth.uid === $uid",
          "$alertId": {
            ".validate": "newData.hasChildren(['date', 'descripcion', 'id', 'latitude_encrypted', 'longitude_encrypted', 'numberCalled_encrypted', 'timestamp'])",
            "date": {
              ".validate": "newData.isString()"
            },
            "descripcion": {
              ".validate": "newData.isString()"
            },
            "id": {
              ".validate": "newData.isString()"
            },
            "latitude_encrypted": {
              ".validate": "newData.isString()"
            },
            "longitude_encrypted": {
              ".validate": "newData.isString()"
            },
            "numberCalled_encrypted": {
              ".validate": "newData.isString()"
            },
            "timestamp": {
              ".validate": "newData.isNumber()"
            }
          }
        },
        
        "paciente": {
          ".read": "auth.uid === $uid",
          ".write": "auth.uid === $uid",
          ".validate": "newData.hasChildren(['userId', 'nombres', 'apellidos', 'edad', 'tipoSangre', 'status'])"
        }
      }
    }
  }
}
```

### Explicación de Reglas

#### 1. **Lectura Autenticada** (`.read`)
```javascript
".read": "auth.uid === $uid"
```
- Solo el propietario puede leer sus datos
- `auth.uid`: ID del usuario autenticado
- `$uid`: Variable que captura el ID del usuario en la ruta
- Compara que coincidan para permitir lectura

#### 2. **Escritura Autenticada** (`.write`)
```javascript
".write": "auth.uid === $uid"
```
- Solo el propietario puede modificar sus datos
- Previene que otros usuarios accedan o modifiquen información

#### 3. **Validación de Datos** (`.validate`)
```javascript
"$alertId": {
  ".validate": "newData.hasChildren(['date', 'descripcion', 'id', ...])"
}
```
- Asegura que los campos requeridos estén presentes
- Valida tipos de datos antes de guardar

### Consideraciones de Seguridad

✅ **Implementado:**
- Autenticación requerida
- Acceso restringido por usuario
- Validación de estructura de datos
- Encriptación de datos sensibles (ubicación, teléfono)

⚠️ **Recomendaciones:**
- Implementar auditoría de cambios
- Limitar frecuencia de escritura (rate limiting)
- Encriptar más campos (nombres, medicamentos sensibles)
- Usar timestamps de servidor en lugar de cliente

---

## Ejemplo Real de Datos

### JSON Completo Guardado en Firebase

```json
{
  "users": {
    "1756278551": {
      "alerts": {
        "-Oyp2d-w1Onhh8FpqG5L": {
          "date": "30 de Julio de 2026",
          "descripcion": "Alerta de pánico activada",
          "id": "-Oyp2d-w1Onhh8FpqG5L",
          "latitude_encrypted": "4hFmM5ncw8iUb5Zth3hnUw==",
          "longitude_encrypted": "4hZwLJ3cyMGSb5Zth3hnUw==",
          "numberCalled_encrypted": "9hB5D6Tn/PWsZZxnjXJtWQ==",
          "paciente": {
            "status": "active",
            "time": "16:49:25",
            "timestamp": 1785448165149,
            "userId": "1756278551"
          }
        },
        "-Oyoqy4YpICuihDwzCrI": {
          "date": "29 de Julio de 2026",
          "descripcion": "Alerta de pánico activada",
          "id": "-Oyoqy4YpICuihDwzCrI",
          "latitude_encrypted": "...",
          "longitude_encrypted": "...",
          "numberCalled_encrypted": "...",
          "paciente": {
            "status": "active",
            "time": "14:23:10",
            "timestamp": 1785364990000,
            "userId": "1756278551"
          }
        },
        "-Oyoz-W2S9KVuk-r0_32-": {
          "date": "28 de Julio de 2026",
          "descripcion": "Alerta de pánico activada",
          "id": "-Oyoz-W2S9KVuk-r0_32-",
          "latitude_encrypted": "...",
          "longitude_encrypted": "...",
          "numberCalled_encrypted": "...",
          "paciente": {
            "status": "active",
            "time": "11:15:45",
            "timestamp": 1785281745000,
            "userId": "1756278551"
          }
        }
      }
    }
  }
}
```

### Datos del Perfil Médico Completo

El perfil médico completo se mantiene sincronizado en el cliente (SharedPreferences) y se envía como parte del payload cuando se crea una alerta. Su estructura es:

```json
{
  "alergias": ["Panadería", "Nuez", "Trabajo"],
  "apellidos": "Murillo Doce",
  "condicionesMedicas": [
    {
      "diagnosis": "Hoiladsldd kdksskksdm kssk sksk kkkk qqq msdowee, heueuucn msmsmjmsÑ jjewjejkejÑ.s jsjjsjsjs",
      "since": "16/07/2026"
    },
    {
      "diagnosis": "Rodilla Rota",
      "since": "29/07/2026"
    }
  ],
  "edad": 21,
  "medicamentosHabitales": [
    {"name": "Ibuprofeno", "dose": "500mg", "frequency": "Cada 8 horas"},
    {"name": "Paracetamol", "dose": "500mg", "frequency": "Cada 6 horas"}
  ],
  "nombres": "Hugo",
  "patologiasCatastróficas": ["Cáncer", "Epilepsia"],
  "sintomas": [
    {
      "date": "2026-07-30T16:48:45.009028",
      "id": 1,
      "severity": 6,
      "symptoms": "Dolor intenso rodilla derecha a la altura de la unión con el muslo"
    }
  ],
  "userId": "1756278551",
  "tipoSangre": "O+",
  "status": "active",
  "time": "16:49:25",
  "timestamp": 1785448165149
}
```

```
Usuario presiona botón de pánico
         ↓
Aplicación obtiene:
  - Ubicación GPS (latitud, longitud)
  - Teléfono a llamar
  - Datos del paciente
         ↓
Encripta datos sensibles
  - latitude → latitude_encrypted
  - longitude → longitude_encrypted
  - numberCalled → numberCalled_encrypted
         ↓
Envía a Firebase:
  POST /users/{userId}/alerts/{newAlertId}
  {
    date: "30 de Julio de 2026",
    descripcion: "Alerta de pánico activada",
    latitude_encrypted: "...",
    longitude_encrypted: "...",
    numberCalled_encrypted: "...",
    timestamp: 1785448165149
  }
         ↓
Firebase guarda
         ↓
Triggers (Cloud Functions) pueden:
  - Notificar a servicios de emergencia
  - Enviar notificación a contactos
  - Registrar en análisis
```

---

## Encriptación de Datos

### Campos Encriptados

| Campo Original | Campo Encriptado | Razón |
|---|---|---|
| Latitud (número) | `latitude_encrypted` | Privacidad de ubicación |
| Longitud (número) | `longitude_encrypted` | Privacidad de ubicación |
| Teléfono llamado | `numberCalled_encrypted` | Privacidad del contacto |

### Método de Encriptación

La aplicación usa **AES (Advanced Encryption Standard)** con:
- **Algoritmo:** AES-128-CBC o AES-256-CBC
- **Codificación salida:** Base64
- **Ubicación clave:** Almacenamiento seguro (Secure Storage)

#### Ejemplo de Encriptación

```dart
// Ubicación: lib/services/encryption_service.dart

// Antes de encriptar:
latitude = 0.218123
longitude = -78.514653
numberCalled = "0963522505"

// Después de encriptar (Base64):
latitude_encrypted = "4hFmM5ncw8iUb5Zth3hnUw=="
longitude_encrypted = "4hZwLJ3cyMGSb5Zth3hnUw=="
numberCalled_encrypted = "9hB5D6Tn/PWsZZxnjXJtWQ=="
```

### Por qué se Encriptan Datos

1. **Privacidad:** Ubicación en tiempo real es información sensible
2. **Cumplimiento:** Leyes de protección de datos (GDPR, CCPA)
3. **Seguridad:** Los servidores de Firebase no guarden datos en claro
4. **Control:** Solo la app autorizada puede desencriptar

---

## Operaciones de Base de Datos

### 1. Crear Alerta

```dart
// Ubicación: lib/services/alert_service.dart

Future<String> createAlert({
  required String userId,
  required Map<String, dynamic> patientData,
  required double latitude,
  required double longitude,
  required String numberCalled,
  String? city,
  String? country,
}) async {
  final alertData = {
    'date': _formatDate(DateTime.now()),
    'descripcion': 'Alerta de pánico activada',
    'latitude_encrypted': await _encryptLocation(latitude),
    'longitude_encrypted': await _encryptLocation(longitude),
    'numberCalled_encrypted': await _encryptPhone(numberCalled),
    'timestamp': DateTime.now().millisecondsSinceEpoch,
    'city_encrypted': city != null ? await _encryptText(city) : null,
    'country_encrypted': country != null ? await _encryptText(country) : null,
  };
  
  // Enviar a Firebase
  final ref = FirebaseDatabase.instance.ref('users/$userId/alerts').push();
  await ref.set(alertData);
  return ref.key!; // Retorna el ID de la alerta
}
```

### 2. Actualizar Datos del Paciente

```dart
Future<void> updatePatientData({
  required String userId,
  required Map<String, dynamic> patientData,
}) async {
  final ref = FirebaseDatabase.instance.ref('users/$userId/paciente');
  await ref.update({
    'nombres': patientData['nombres'],
    'apellidos': patientData['apellidos'],
    'edad': patientData['edad'],
    'tipoSangre': patientData['tipoSangre'],
    'medicamentosHabitales': patientData['medicamentosHabitales'],
    'alergias': patientData['alergias'],
    'patologiasCatastróficas': patientData['patologiasCatastróficas'],
    'condicionesMedicas': patientData['condicionesMedicas'],
    'sintomas': patientData['sintomas'],
    'timestamp': DateTime.now().millisecondsSinceEpoch,
  });
}
```

### 3. Leer Historial de Alertas

```dart
Future<List<Map<String, dynamic>>> getAlertHistory(String userId) async {
  final ref = FirebaseDatabase.instance.ref('users/$userId/alerts');
  final snapshot = await ref.get();
  
  if (!snapshot.exists) return [];
  
  final alerts = <Map<String, dynamic>>[];
  for (var child in snapshot.children) {
    alerts.add(Map<String, dynamic>.from(child.value as Map));
  }
  return alerts;
}
```

### 4. Escuchar Cambios en Tiempo Real

```dart
void listenToPatientData(String userId) {
  final ref = FirebaseDatabase.instance.ref('users/$userId/paciente');
  
  ref.onValue.listen((event) {
    if (event.snapshot.exists) {
      final data = Map<String, dynamic>.from(event.snapshot.value as Map);
      print('Datos actualizados: $data');
      // Actualizar UI
      setState(() {
        _patientData = data;
      });
    }
  });
}
```

### 5. Eliminar Alerta

```dart
Future<void> deleteAlert(String userId, String alertId) async {
  final ref = FirebaseDatabase.instance.ref('users/$userId/alerts/$alertId');
  await ref.remove();
}
```

---

## Consideraciones de Rendimiento

### 1. **Limitaciones de Firebase Realtime Database**

| Aspecto | Límite | Impacto |
|--------|--------|--------|
| Tamaño máximo de documento | 16 MB | Alertas limitadas en historial |
| Profundidad de nesting | Sin límite teórico | Mantener estructura plana |
| Velocidad de lectura | ~100,000 ops/seg | Suficiente para esta app |
| Velocidad de escritura | ~50,000 ops/seg | Suficiente para alertas |

### 2. **Índices Recomendados**

Para optimizar queries frecuentes:

```json
{
  "rules": {
    "users": {
      "$uid": {
        "alerts": {
          ".indexOn": ["timestamp", "date"]
        }
      }
    }
  }
}
```

Esto permite:
- Ordenar alertas por fecha
- Filtrar alertas por rango de tiempo

### 3. **Estrategia de Caché Local**

La aplicación implementa:

```dart
// Guardar datos localmente con SharedPreferences
final prefs = await SharedPreferences.getInstance();
prefs.setString('last_known_location', jsonEncode({
  'lat': position.latitude,
  'lon': position.longitude,
  'city': city,
  'country': country,
  'timestamp': DateTime.now().millisecondsSinceEpoch,
}));

// Usar caché si no hay conexión
if (!isConnected) {
  final cached = prefs.getString('patient_data');
  if (cached != null) {
    _patientData = jsonDecode(cached);
  }
}
```

### 4. **Compresión de Datos**

- Encriptación Base64 aumenta tamaño ~33%
- Considerar compresión GZIP para historial extenso
- Archivar alertas antiguas en Cloud Storage

---

## Resumen de Estructura

```
┌─────────────────────────────────────┐
│   Firebase Realtime Database        │
└─────────────────────────────────────┘
              │
              └── users/
                    └── 1756278551/                    ← Documento usuario
                          └── alerts/                  ← Subcollección
                                ├── -Oyp2d-w1Onhh8FpqG5L/
                                │   ├── date: "30 de Julio de 2026" ✅
                                │   ├── descripcion: "Alerta de pánico activada" ✅
                                │   ├── latitude_encrypted: "4hFmM5ncw8iUb5Zth3hnUw==" 🔒
                                │   ├── longitude_encrypted: "4hZwLJ3cyMGSb5Zth3hnUw==" 🔒
                                │   ├── numberCalled_encrypted: "9hB5D6Tn/PWsZZxnjXJtWQ==" 🔒
                                │   └── paciente/                              📋
                                │       ├── status: "active" ✅
                                │       ├── time: "16:49:25" ⏰
                                │       ├── timestamp: 1785448165149 ✅
                                │       └── userId: "1756278551" ✅
                                │
                                ├── -Oyoqy4YpICuihDwzCrI/
                                │   ├── date: "29 de Julio de 2026"
                                │   ├── latitude_encrypted: "..."
                                │   ├── longitude_encrypted: "..."
                                │   ├── numberCalled_encrypted: "..."
                                │   └── paciente/
                                │       ├── status: "active"
                                │       ├── time: "14:23:10"
                                │       ├── timestamp: 1785364990000
                                │       └── userId: "1756278551"
                                │
                                └── -OypBTV8poboYOP4x0_0/
                                    ├── date: "27 de Julio de 2026"
                                    └── ...

LEYENDA:
✅ = Campo almacenado en Firebase
🔒 = Encriptado en Base64 (AES)
📋 = Subdocumento (datos en momento de alerta)
⏰ = Timestamp formateado como string
```

---

## Checklist de Verificación

- ✅ Firebase inicializado en `main.dart`
- ✅ Reglas de seguridad configuradas
- ✅ Encriptación implementada para datos sensibles
- ✅ Rate limiting en botón de pánico
- ✅ Sincronización offline funcional
- ✅ Validación de datos en cliente y servidor
- ✅ Timestamps sincronizados
- ✅ Historial de alertas persistente
- ⚠️ Auditoría de acceso (pendiente)
- ⚠️ Backup automático (verificar)

---

**Autor:** Documentación Técnica  
**Última revisión:** 2 de agosto de 2026  
**Próxima revisión:** 30 de agosto de 2026
