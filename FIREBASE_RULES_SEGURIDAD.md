# Reglas de Seguridad - Firebase Realtime Database
**Fecha:** 21 de julio de 2026  
**Versión:** 1.0  
**Estado:** Desarrollo (Prueba)

## Problema Actual
```
W/RepoOperation: setValue at /users/1756278550/alerts/-Oy71uzGaKQrR_FMwNa- failed: DatabaseError: Permission denied
```

Las reglas actuales de Firebase Realtime Database están bloqueando la escritura en `/users/{CI}/alerts/`.

---

## Solución: Actualizar Reglas en Firebase Console

### Paso 1: Acceder a Firebase Console
1. Ir a [Firebase Console](https://console.firebase.google.com)
2. Seleccionar tu proyecto: **flutter_application_1**
3. Ir a **Realtime Database** → **Reglas**

### Paso 2: Reemplazar Reglas Actuales

#### Para DESARROLLO (permitir acceso público):
```json
{
  "rules": {
    "users": {
      "$uid": {
        "alerts": {
          "$alertId": {
            ".read": true,
            ".write": true,
            ".validate": "newData.hasChildren(['userId', 'timestamp', 'status'])"
          }
        },
        ".read": true,
        ".write": true
      }
    }
  }
}
```

#### Para PRODUCCIÓN (requiere autenticación):
```json
{
  "rules": {
    "users": {
      "$uid": {
        "alerts": {
          "$alertId": {
            ".read": "$uid === auth.uid",
            ".write": "$uid === auth.uid && newData.hasChildren(['userId', 'timestamp', 'status'])",
            ".validate": "newData.hasChildren(['userId', 'timestamp', 'status'])"
          }
        }
      }
    }
  }
}
```

### Paso 3: Publicar Reglas
1. Click en **Publicar**
2. Esperar confirmación

---

## Estructura de Datos Esperada

```
firebase-database-root/
└── users/
    └── {CI}/ (ej: 1756278550)
        ├── alerts/
        │   ├── -Oy71uzGaKQrR_FMwNa-/
        │   │   ├── id: string
        │   │   ├── userId: string (CI)
        │   │   ├── timestamp: number (milliseconds)
        │   │   ├── status: string ('active', 'resolved', 'false_alarm')
        │   │   ├── latitude: number
        │   │   ├── longitude: number
        │   │   ├── latitude_encrypted: string
        │   │   ├── longitude_encrypted: string
        │   │   ├── numberCalled_encrypted: string
        │   │   ├── contactsNotified: array
        │   │   ├── description: string
        │   │   └── paciente: object
        │   │       ├── nombres: string
        │   │       ├── apellidos: string
        │   │       ├── edad: string
        │   │       ├── tipoSangre: string
        │   │       ├── patologiasCatastróficas: array
        │   │       ├── condicionesMedicas: array
        │   │       ├── medicamentosHabitales: array
        │   │       ├── alergias: array
        │   │       ├── sintomas: array
        │   │       └── aseguramiento: object
```

---

## Alternativa: Autenticación Anónima

Si prefieres seguridad sin requerir login, puedes habilitar **Autenticación Anónima**:

1. Firebase Console → **Authentication** → **Sign-in method**
2. Habilitar **Autenticación anónima**
3. Usar estas reglas:

```json
{
  "rules": {
    "users": {
      "$uid": {
        "alerts": {
          ".write": "$uid === auth.uid",
          ".read": "$uid === auth.uid"
        }
      }
    }
  }
}
```

Y en el código:
```dart
try {
  await FirebaseAuth.instance.signInAnonymously();
} catch (e) {
  print('Error en autenticación anónima: $e');
}
```

---

## Verificación

Después de publicar las reglas:

```bash
flutter run -d "sdk gphone64 x86 64"
```

Si funciona, verás:
```
I/flutter (18194): [AlertService.createAlert] ✓ Guardada en Firebase
```

---

## Campos Requeridos para Cada Alerta

- ✅ `id`: Identificador único de la alerta
- ✅ `userId`: CI del usuario (número)
- ✅ `timestamp`: Timestamp en milliseconds
- ✅ `status`: Estado de la alerta
- ✅ `latitude_encrypted`: Ubicación encriptada
- ✅ `longitude_encrypted`: Ubicación encriptada
- ✅ `numberCalled_encrypted`: Teléfono encriptado
- ✅ `paciente`: Objeto con datos médicos del paciente

---

**Nota de Seguridad:** Estas reglas públicas son solo para desarrollo. En producción, usa autenticación Firebase Auth con reglas restrictivas.
