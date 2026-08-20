# Base de Datos Firebase - Estructura y Configuracion

**Version:** 1.4.67  
**Fecha:** 20 de agosto de 2026  
**Estado:** Produccion

---

## Indice

1. [Descripcion General](#descripcion-general)
2. [Estructura de Colecciones](#estructura-de-colecciones)
3. [Esquema de Datos Detallado](#esquema-de-datos-detallado)
4. [Reglas de Seguridad Firebase](#reglas-de-seguridad-firebase)
5. [Ejemplo Real de Datos](#ejemplo-real-de-datos)
6. [Encriptacion de Datos](#encriptacion-de-datos)
7. [Operaciones de Base de Datos](#operaciones-de-base-de-datos)
8. [Consideraciones de Rendimiento](#consideraciones-de-rendimiento)

---

## Descripcion General

### Que es Firebase Realtime Database

Firebase Realtime Database es una base de datos NoSQL hospedada en la nube que sincroniza datos en tiempo real. La aplicacion utiliza esta plataforma para:

- **Almacenar alertas de emergencia** con ubicacion y datos del paciente
- **Persistir informacion medica** del usuario (perfil, medicamentos, alergias, condiciones)
- **Mantener historial de eventos** de emergencia
- **Sincronizacion offline** con posterior sincronizacion cuando hay conexion

### Caracteristicas Principales

- ✅ Sincronizacion en tiempo real
- ✅ Almacenamiento jerarquico de datos
- ✅ Acceso mediante reglas de seguridad personalizables
- ✅ Integracion con autenticacion Firebase
- ✅ Respaldo automatico de datos
- ✅ Encriptacion en transito (HTTPS)

---

## Estructura de Colecciones

### Arquitectura General

```
Firebase Realtime Database
└── users/                                [Raiz de usuarios]
    └── {userId}/                         [Documento del usuario]
        └── alerts/                       [Coleccion de alertas]
            └── {alertId}/                [Documento de alerta]
                └── paciente/             [Subdocumento medico]
```

### Desglose de Colecciones

#### 1. Coleccion: `users`

- **Tipo:** Raiz de la estructura
- **Documentos:** Uno por usuario registrado
- **Clave:** ID unico del usuario
- **Contenido:** Subcolleccion de alertas

#### 2. Subcolleccion: `users/{userId}/alerts`

- **Tipo:** Array de alertas de emergencia
- **Documentos:** Uno por cada alerta activada
- **Clave:** ID unico generado por Firebase
- **Contenido:** Datos de la alerta + subdocumento paciente

#### 3. Subdocumento: `users/{userId}/alerts/{alertId}/paciente`

- **Tipo:** Documento anidado dentro de cada alerta
- **Contenido:** Snapshot de datos medicos del paciente
- **Campos:** status, time, timestamp, userId

---

## Esquema de Datos Detallado

### 1. Estructura del Usuario (root level)

```javascript
users/{userId} {
  alerts: {}        // Subcolleccion con alertas historicas
}
```

---

### 2. Estructura de Alertas: `users/{userId}/alerts/{alertId}`

| Campo | Tipo | Requerido | Descripcion |
|-------|------|-----------|-------------|
| `id` | String | ✅ | Identificador unico de la alerta |
| `date` | String | ✅ | Fecha formateada (ej: "30 de Julio de 2026") |
| `descripcion` | String | ✅ | Descripcion de la alerta |
| `latitude_encrypted` | String | ✅ | Latitud encriptada en Base64 |
| `longitude_encrypted` | String | ✅ | Longitud encriptada en Base64 |
| `numberCalled_encrypted` | String | ✅ | Telefono llamado encriptado |
| `paciente` | Object | ✅ | Subdocumento con datos medicos |
| `city_encrypted` | String | ❌ | Ciudad encriptada (opcional) |
| `country_encrypted` | String | ❌ | Pais encriptado (opcional) |

#### Ejemplo de Alerta Completa

```json
{
  "id": "-Oyp2d-w1Onhh8FpqG5L",
  "date": "30 de Julio de 2026",
  "descripcion": "Alerta de panico activada",
  "latitude_encrypted": "4hFmM5ncw8iUb5Zth3hnUw==",
  "longitude_encrypted": "pL8kQ9mX2RfGh4Tg6Uj5Kp==",
  "numberCalled_encrypted": "7vN3sM2wE1qI9oU8lK0pP==",
  "paciente": {
    "userId": "1756278551",
    "status": "active",
    "time": "14:30:45",
    "timestamp": 1685448165149
  }
}
```

---

### 3. Perfil Medico Completo (guardado en el cliente)

La aplicacion mantiene el perfil completo sincronizado localmente:

#### Estructura Completa del Paciente

```json
{
  "userId": "1756278551",
  "nombres": "Juan Carlos",
  "apellidos": "Garcia Martinez",
  "cedula": "1234567890",
  "edad": 35,
  "tipoSangre": "O+",
  "numeroTelefonico": "0963522505",
  "alergias": ["Penicilina", "Panaderia"],
  "condicionesMedicas": [
    {
      "diagnosis": "Hipertension",
      "since": "15/03/2020"
    }
  ],
  "medicamentosHabitales": [
    {
      "name": "Losartan",
      "dose": "50mg",
      "frequency": "Diaria"
    }
  ],
  "patologiasCatastróficas": ["Diabetes", "Asma"],
  "sintomas": [
    {
      "date": "2026-07-30T14:30:45Z",
      "id": 1,
      "severity": 7,
      "symptoms": "Dolor en el pecho"
    }
  ],
  "timestamp": 1785448165149
}
```

---

### 3.1 Arreglo: `patologiasCatastróficas`

```json
"patologiasCatastróficas": [
  "Cancer",
  "Diabetes",
  "Asma",
  "Insuficiencia Cardiaca"
]
```

**Descripcion:** Lista de enfermedades cronicas graves del paciente.

#### 3.2 Arreglo: `alergias`

```json
"alergias": [
  "Panaderia",
  "Nuez",
  "Penicilina"
]
```

**Descripcion:** Alergias conocidas del paciente (alimentos, medicinas, etc.).

#### 3.3 Arreglo: `condicionesMedicas`

```json
"condicionesMedicas": [
  {
    "diagnosis": "Hipertension",
    "since": "15/03/2020"
  }
]
```

**Campos:**
- `diagnosis` (String): Descripcion de la condicion medica
- `since` (String): Fecha de diagnostico (formato DD/MM/YYYY)

#### 3.4 Arreglo: `medicamentosHabitales`

```json
"medicamentosHabitales": [
  {
    "name": "Losartan",
    "dose": "50mg",
    "frequency": "Diaria"
  }
]
```

**Campos:**
- `name` (String): Nombre del medicamento
- `dose` (String): Dosis recomendada
- `frequency` (String): Frecuencia de administracion

#### 3.5 Arreglo: `sintomas`

```json
"sintomas": [
  {
    "date": "2026-07-30T14:30:45Z",
    "id": 1,
    "severity": 7,
    "symptoms": "Dolor en el pecho"
  }
]
```

**Campos:**
- `date` (String ISO-8601): Fecha y hora del sintoma
- `id` (Integer): Identificador unico del sintoma
- `severity` (Integer): Gravedad de 1-10
- `symptoms` (String): Descripcion del sintoma

---

## Reglas de Seguridad Firebase

### Archivo: `firebase-rules.json`

Las reglas de Firebase Realtime Database controlan quien puede leer y escribir datos.

```json
{
  "rules": {
    "users": {
      "$uid": {
        ".read": "auth.uid === $uid",
        ".write": "auth.uid === $uid",
        "alerts": {
          "$alertId": {
            ".validate": "newData.hasChildren(['date', 'descripcion', 'id', 'latitude_encrypted', 'longitude_encrypted', 'numberCalled_encrypted', 'paciente'])"
          }
        }
      }
    }
  }
}
```

### Explicacion de Reglas

#### 1. Lectura Autenticada (`.read`)

```javascript
".read": "auth.uid === $uid"
```

- Solo el propietario puede leer sus datos
- `auth.uid`: ID del usuario autenticado
- `$uid`: Variable que captura el ID del usuario
- Compara que coincidan para permitir lectura

#### 2. Escritura Autenticada (`.write`)

```javascript
".write": "auth.uid === $uid"
```

- Solo el propietario puede modificar sus datos
- Previene que otros usuarios accedan o modifiquen informacion

#### 3. Validacion de Datos (`.validate`)

```javascript
"$alertId": {
  ".validate": "newData.hasChildren(['date', 'descripcion', 'id', ...])"
}
```

- Asegura que los campos requeridos esten presentes
- Valida tipos de datos antes de guardar

### Consideraciones de Seguridad

✅ **Implementado:**
- Autenticacion requerida
- Acceso restringido por usuario
- Validacion de estructura de datos
- Encriptacion de datos sensibles (ubicacion, telefono)

⚠️ **Recomendaciones:**
- Implementar auditoria de cambios
- Limitar frecuencia de escritura (rate limiting)
- Encriptar mas campos (nombres, medicamentos sensibles)
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
          "id": "-Oyp2d-w1Onhh8FpqG5L",
          "date": "30 de Julio de 2026",
          "descripcion": "Alerta de panico activada",
          "latitude_encrypted": "4hFmM5ncw8iUb5Zth3hnUw==",
          "longitude_encrypted": "pL8kQ9mX2RfGh4Tg6Uj5Kp==",
          "numberCalled_encrypted": "7vN3sM2wE1qI9oU8lK0pP==",
          "paciente": {
            "userId": "1756278551",
            "status": "active",
            "time": "14:30:45",
            "timestamp": 1685448165149
          }
        }
      }
    }
  }
}
```

---

## Encriptacion de Datos

### Campos Encriptados

| Campo Original | Campo Encriptado | Razon |
|---|---|---|
| Latitud (numero) | `latitude_encrypted` | Privacidad de ubicacion |
| Longitud (numero) | `longitude_encrypted` | Privacidad de ubicacion |
| Telefono llamado | `numberCalled_encrypted` | Privacidad del contacto |

### Metodo de Encriptacion

La aplicacion usa **AES (Advanced Encryption Standard)** con:
- **Algoritmo:** AES-256-CBC
- **Codificacion salida:** Base64
- **Ubicacion clave:** Almacenamiento seguro (Secure Storage)

#### Ejemplo de Encriptacion

```dart
// Ubicacion: lib/services/encryption_service.dart

// Antes de encriptar:
latitude = 0.218123
longitude = -78.514653
numberCalled = "0963522505"

// Despues de encriptar (Base64):
latitude_encrypted = "4hFmM5ncw8iUb5Zth3hnUw=="
longitude_encrypted = "pL8kQ9mX2RfGh4Tg6Uj5Kp=="
numberCalled_encrypted = "7vN3sM2wE1qI9oU8lK0pP=="
```

---

## Operaciones de Base de Datos

### Crear Alerta

```dart
Future<String> createAlert({
  required double latitude,
  required double longitude,
  required String description,
  required String numberCalled,
}) async {
  String alertId = DateTime.now().millisecondsSinceEpoch.toString();
  
  await _database
    .child('users')
    .child(userId)
    .child('alerts')
    .child(alertId)
    .set({
      'id': alertId,
      'date': DateFormat('dd de MMMM de yyyy').format(DateTime.now()),
      'descripcion': description,
      'latitude_encrypted': EncryptionService.instance.encrypt(latitude.toString()),
      'longitude_encrypted': EncryptionService.instance.encrypt(longitude.toString()),
      'numberCalled_encrypted': EncryptionService.instance.encrypt(numberCalled),
      'paciente': pacientData,
    });
  
  return alertId;
}
```

### Recuperar Alertas

```dart
Future<List<Map<String, dynamic>>> getUserAlerts() async {
  final snapshot = await _database
    .child('users')
    .child(userId)
    .child('alerts')
    .get();
  
  if (snapshot.exists) {
    List<Map<String, dynamic>> alerts = [];
    snapshot.children.forEach((child) {
      alerts.add(Map<String, dynamic>.from(child.value as Map));
    });
    return alerts;
  }
  return [];
}
```

### Actualizar Estado de Alerta

```dart
Future<void> updateAlertStatus(String alertId, String newStatus) async {
  await _database
    .child('users')
    .child(userId)
    .child('alerts')
    .child(alertId)
    .child('paciente')
    .child('status')
    .set(newStatus);
}
```

---

## Consideraciones de Rendimiento

### Optimizaciones

1. **Indexacion:** Define indices en Firebase Console para queries frecuentes
2. **Paginacion:** Carga alertas en grupos (primeras 10, luego mas)
3. **Cache Local:** Mantiene copia en dispositivo via SharedPreferences
4. **Sincronizacion Offline:** Guarda datos localmente si no hay conexion

### Limites de Firebase

- Maximo 16 MB por documento
- Maximo 25 operaciones de escritura por segundo por cliente
- Maximo 100 conexiones simultaneas por proyecto

### Monitoreo

Verifica el uso en [Firebase Console](https://console.firebase.google.com/):
- **Realtime Database → Data**
- **Realtime Database → Rules**
- **Storage → Usage**

---

**Nota:** Consulta [05_PERMISOS_REQUERIDOS.md](05_PERMISOS_REQUERIDOS.md) para ver como configurar permisos relacionados con Firebase.

**Ultimo cambio:** 20 de agosto de 2026 - Estructura y contenido actualizado.
