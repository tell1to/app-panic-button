# 🔔 Integración Pushwoosh con Citas Médicas

**Estado:** ✅ **Integración Local Completa** (Esperando Backend)  
**Rama:** `Integracion-pushwoosh`  
**Fecha Última Actualización:** 2025-01-21

---

## 📋 Resumen

Pushwoosh está completamente integrado con el sistema de citas médicas. Cuando un usuario crea, modifica o elimina una cita, el sistema automáticamente:

1. **Guarda** la cita en SharedPreferences
2. **Programa recordatorio local** (flutter_local_notifications)
3. **Notifica a Pushwoosh** para enviar notificación push remota

---

## 🏗️ Arquitectura de Integración

### Flujo de Creación de Cita

```
[usuario crea cita en _showAppointmentsDialog]
            ↓
[_saveAppointment() es llamado]
            ↓
[Guardar en SharedPreferences] ✅
            ↓
[AppointmentReminderService.scheduleAppointmentReminder()] ✅
│   ├─ Convierte fecha/hora a DateTime
│   ├─ Calcula tiempo de recordatorio
│   └─ Programa notificación local
            ↓
[PushwooshService.scheduleAppointmentReminder()] ✅
│   ├─ Extrae datos de cita
│   ├─ Registra en logs
│   └─ Envía info al backend (PENDIENTE)
            ↓
[Recordatorio confirmado ✅]
```

---

## 📝 Cambios Implementados

### 1. **options.dart**

#### Agregar Métodos de Control de Citas

```dart
/// Guardar cita y programar recordatorios (local + Pushwoosh)
Future<void> _saveAppointment(Map<String, dynamic> appointment) async {
  // 1. Guardar en lista local
  // 2. Persistir en SharedPreferences
  // 3. Programar recordatorio local (flutter_local_notifications)
  // 4. Programar recordatorio Pushwoosh (backend)
}

/// Eliminar cita y cancelar recordatorios
Future<void> _deleteAppointment(String appointmentId) async {
  // 1. Eliminar de lista local
  // 2. Eliminar de SharedPreferences
  // 3. Cancelar recordatorio Pushwoosh (backend)
}
```

**Ubicación:** `lib/options.dart` (líneas ~690-760)

#### Agregar Import de PushwooshService

```dart
import 'services/pushwoosh_service.dart';
```

### 2. **pushwoosh_service.dart**

#### Método: scheduleAppointmentReminder()

Cuando se crea una cita, se llama automáticamente:

```dart
Future<void> scheduleAppointmentReminder({
  required String appointmentId,
  required String doctorName,
  required String appointmentDate,  // Formato: "23/12/2025"
  required String appointmentTime,  // Formato: "14:30"
  required String specialty,
}) async {
  // 1. Log de información de cita
  // 2. TODO: Enviar a backend con token de usuario
  // 3. Backend envía a Pushwoosh API
  // 4. Pushwoosh programa notificación
}
```

#### Método: cancelAppointmentReminder()

Cuando se elimina una cita:

```dart
Future<void> cancelAppointmentReminder(String appointmentId) async {
  // 1. Log de cancelación
  // 2. TODO: Notificar backend para cancelar recordatorio
}
```

---

## 🔌 Flujo de Datos

### Datos que Fluyen de App → Backend

```json
{
  "appointmentId": "cita_cardiologo_2025",
  "doctorName": "Dr. García",
  "appointmentDate": "23/12/2025",
  "appointmentTime": "14:30",
  "specialty": "Cardiología",
  "userId": "<obtenido de Pushwoosh>",
  "deviceId": "<obtenido de Pushwoosh>"
}
```

### Datos que Fluyen de Backend → Pushwoosh API

```json
{
  "request": {
    "application": "uoc4hxfPwguY42PNHlvblSP6mkH6TCbap8d66CB185",
    "auth": "<YOUR_PUSHWOOSH_AUTH_TOKEN>",
    "notifications": [
      {
        "send_date": "2025-12-23 14:00",  // X minutos antes
        "content": "Recordatorio: Cita con Dr. García",
        "data": {
          "appointmentId": "cita_cardiologo_2025",
          "type": "appointment_reminder",
          "doctorName": "Dr. García",
          "specialty": "Cardiología"
        },
        "devices": ["DEVICE_ID_AQUI"]
      }
    ]
  }
}
```

---

## 🎯 Tareas Pendientes (Backend)

### 🔴 PRIORITARIO 1: Endpoint para Programar Recordatorio

```
POST /api/appointments/schedule-reminder

Request Body:
{
  "appointmentId": "string",
  "doctorName": "string",
  "appointmentDate": "string (DD/MM/YYYY)",
  "appointmentTime": "string (HH:MM)",
  "specialty": "string",
  "userId": "string",
  "deviceId": "string"
}

Response:
{
  "success": true,
  "reminderId": "pushwoosh_reminder_123",
  "scheduledTime": "2025-12-23T14:00:00Z"
}
```

**Implementación esperada:**
1. Recibir datos de cita
2. Autenticar con Pushwoosh API usando `PUSHWOOSH_AUTH_TOKEN`
3. Hacer request a `https://api.pushwoosh.com/1/createMessage`
4. Guardar `reminderId` para poder cancelar después
5. Retornar confirmación

### 🔴 PRIORITARIO 2: Endpoint para Cancelar Recordatorio

```
DELETE /api/appointments/{appointmentId}/cancel-reminder

Response:
{
  "success": true,
  "message": "Recordatorio cancelado"
}
```

**Implementación esperada:**
1. Buscar recordatorio por appointmentId
2. Obtener `reminderId` de Pushwoosh
3. Usar Pushwoosh API para cancelar (DELETE)
4. Confirmar cancelación

### 🔴 PRIORITARIO 3: Obtener Device Token de Usuario

Cuando usuario inicia sesión, guardar:

```dart
// En main.dart o login screen
final deviceId = await PushwooshService.instance().getDeviceId();
final userId = await AuthService.instance().getCurrentUserId();

// Enviar al backend:
POST /api/users/{userId}/device-token
{
  "deviceId": deviceId,
  "platform": "android",
  "appVersion": "1.0.0"
}
```

---

## 📲 Cómo Funciona en la App

### Flujo Completo de Usuario

1. **Usuario abre "Citas Médicas"** → `options.dart` → `_showAppointmentsDialog()`

2. **Usuario llena el formulario:**
   - Nombre/Médico
   - Fecha (DD/MM/YYYY)
   - Hora (HH:MM)
   - Especialidad
   - Minutos para recordatorio (default: 30)

3. **Usuario toca "Guardar":**
   ```dart
   await _saveAppointment({
     'id': 'cita_cardiologo_2025',
     'doctor': 'Dr. García',
     'date': '23/12/2025',
     'time': '14:30',
     'specialty': 'Cardiología',
     'reminderMinutes': 30
   });
   ```

4. **App realiza 3 acciones en paralelo:**

   **A) Guardar localmente:**
   ```dart
   await _saveAppointments();  // SharedPreferences
   ```

   **B) Programar recordatorio local:**
   ```dart
   await AppointmentReminderService.instance().scheduleAppointmentReminder(
     appointmentId: 'cita_cardiologo_2025',
     appointmentDateTime: DateTime(2025, 12, 23, 14, 30),
     doctorName: 'Dr. García',
     appointmentDate: '23/12/2025',
     appointmentTime: '14:30',
     minutesBeforeReminder: 30,  // Se dispara a las 14:00
   );
   ```

   **C) Notificar Pushwoosh:**
   ```dart
   await PushwooshService.instance().scheduleAppointmentReminder(
     appointmentId: 'cita_cardiologo_2025',
     doctorName: 'Dr. García',
     appointmentDate: '23/12/2025',
     appointmentTime: '14:30',
     specialty: 'Cardiología',
   );
   ```

5. **Recordatorio Local (Funciona YA):**
   - App programó notificación 30 minutos antes
   - Cuando llega la hora → notificación local
   - Usuario toca notificación → abre pantalla de citas

6. **Recordatorio Pushwoosh (Necesita Backend):**
   - Backend recibe la solicitud vía API
   - Backend calcula hora: 14:30 - 30 min = 14:00
   - Backend usa Pushwoosh API para programar notificación
   - A las 14:00 → Pushwoosh envía notificación push
   - Usuario recibe notificación del servidor

---

## 🧪 Testing Manual

### Verificar Recordatorio Local

```dart
// En main.dart o console
final reminders = await AppointmentReminderService.instance().getPendingReminders();
print('Recordatorios programados: ${reminders.length}');
for (var r in reminders) {
  print('- ID: ${r.id}, Próximo: ${r.nextTriggerTime}');
}
```

### Verificar Logs de Pushwoosh

En Android Studio, buscar:

```
[PushwooshService.scheduleAppointmentReminder] Programando recordatorio:
[PushwooshService.scheduleAppointmentReminder] ID: cita_cardiologo_2025
[PushwooshService.scheduleAppointmentReminder] Doctor: Dr. García
```

---

## 🔐 Seguridad

### Datos Sensibles

- **Device Token:** Almacenado por Pushwoosh, no expuesto a app
- **User ID:** Enviado solo al backend autenticado
- **API Token:** Guardado solo en backend (NUNCA en app cliente)

### Permisos Requeridos

✅ Ya configurados en `AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />
```

---

## 📊 Estado de Implementación

| Componente | Estado | Descripción |
|-----------|--------|------------|
| **Local Notification** | ✅ Funcionando | `flutter_local_notifications` programando recordatorios |
| **PushwooshService** | ✅ Listo | Métodos `scheduleAppointmentReminder()` y `cancelAppointmentReminder()` |
| **Options Integration** | ✅ Listo | `_saveAppointment()` y `_deleteAppointment()` llamando servicios |
| **Pushwoosh Listeners** | ✅ Listo | `onPushReceived` y `onPushAccepted` configurados |
| **Backend Endpoint** | ⏳ PENDIENTE | POST `/api/appointments/schedule-reminder` |
| **Backend Cancellation** | ⏳ PENDIENTE | DELETE `/api/appointments/{id}/cancel-reminder` |
| **Device Token Management** | ⏳ PENDIENTE | Extraer y enviar device token a backend |
| **Navigation on Tap** | ⏳ PENDIENTE | `_handleNotificationNavigation()` implementar navegación |

---

## 🚀 Próximos Pasos

### Fase 1 (Backend Ready)
1. ✅ App está lista - no requiere cambios
2. Implementar endpoints en backend
3. Obtener/guardar device tokens de usuario

### Fase 2 (End-to-End Testing)
1. Usuario crea cita → Backend recibe → Pushwoosh programa
2. Cuando llega la hora → Notificación llega al dispositivo
3. Usuario toca notificación → Abre app en pantalla de citas

### Fase 3 (Production)
1. Configurar alertas en backend si recordatorio falla
2. Implementar retry automático
3. Testing en múltiples dispositivos/zonas horarias

---

## 📚 Referencias

- **Pushwoosh Flutter Plugin:** [Pub.dev](https://pub.dev/packages/pushwoosh_flutter)
- **Pushwoosh API Docs:** [Documentación Oficial](https://docs.pushwoosh.com/platform-specific-docs/android/push-notifications/create-send-api)
- **Flutter Local Notifications:** [Pub.dev](https://pub.dev/packages/flutter_local_notifications)

---

## 💡 Notas Técnicas

### Por qué dos sistemas de notificaciones?

1. **Local Notifications:** Funciona sin internet, ideal para recordatorios de citas pasadas guardadas localmente
2. **Pushwoosh:** Funciona desde backend, ideal para notificaciones en tiempo real desde servidor

### Integración Redundante

Si el backend falla, el usuario aún recibe recordatorio local. Si local falla, backend lo cubre. Máxima confiabilidad.

### Formato de Datos

- **Fecha:** Siempre DD/MM/YYYY (compatible con input UI y parsing)
- **Hora:** Siempre HH:MM en formato 24h
- **Zona Horaria:** Usa zona local del dispositivo automáticamente

---

**¿Preguntas o problemas?** Ver logs en Android Studio y buscar `[PushwooshService]` o `[AppointmentReminderService]`
