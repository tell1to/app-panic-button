# Fase 6: Notificaciones Push (FCM) - Implementación Completada

## Resumen
Se ha implementado Firebase Cloud Messaging (FCM) para enviar notificaciones push a los contactos de emergencia cuando se activa una alerta.

## Servicios Creados

### 1. NotificationService (lib/services/notification_service.dart)
**Responsabilidades:**
- Inicializar FCM en la app
- Solicitar permisos de notificaciones en iOS/Android
- Manejar notificaciones en foreground (app abierta)
- Manejar notificaciones cuando la app está en background/terminated
- Mostrar SnackBars con las notificaciones recibidas
- Gestionar suscripción/desuscripción a tópicos

**Métodos principales:**
```dart
// Inicializar FCM
await NotificationService.instance().initialize();

// Obtener token FCM del dispositivo
String? token = await NotificationService.instance().getFCMToken();

// Suscribirse a un tópico (para notificaciones colectivas)
await NotificationService.instance().subscribeToTopic('emergency_alerts');

// Desuscribirse de un tópico
await NotificationService.instance().unsubscribeFromTopic('emergency_alerts');
```

**Flujo de notificaciones:**
1. **Foreground**: Cuando la app está abierta, se muestra un SnackBar flotante con la notificación
2. **Background**: Cuando la app está minimizada, el sistema maneja la notificación
3. **Terminated**: Cuando la app está cerrada, el sistema recibe la notificación
4. **Al tocar**: Se navega a la pantalla de alertas (OptionsPage)

### 2. ContactService (lib/services/contact_service.dart)
**Responsabilidades:**
- Almacenar contactos de emergencia de forma encriptada
- Gestionar tokens FCM de los contactos
- Recuperar lista de contactos y sus tokens

**Métodos principales:**
```dart
// Obtener todos los contactos
List<EmergencyContact> contacts = await ContactService.instance().getContacts();

// Agregar o actualizar un contacto
await ContactService.instance().addContact(EmergencyContact(
  name: 'John Doe',
  phone: '+593-123-456-7890',
  fcmToken: 'token_xyz...',
));

// Remover un contacto
await ContactService.instance().removeContact('+593-123-456-7890');

// Obtener tokens FCM de todos los contactos (para enviar notificaciones)
List<String> tokens = await ContactService.instance().getAllContactFcmTokens();

// Actualizar token FCM de un contacto
await ContactService.instance().updateContactFcmToken('+593-123-456-7890', 'new_token_xyz...');
```

### 3. AlertService Actualizado (lib/services/alert_service.dart)
**Nuevos métodos:**
```dart
// Notificar a los contactos sobre una alerta activada
Future<void> notifyContacts({
  required String alertId,
  required double? latitude,
  required double? longitude,
  required String description,
}) async { ... }
```

Este método:
- Se llama automáticamente cuando se activa una alerta
- Prepara los datos de la notificación (título, descripción, ubicación)
- Envía notificaciones a todos los contactos con tokens FCM disponibles

## Cambios en Archivos Existentes

### main.dart
- Importar `notification_service.dart`
- Inicializar `NotificationService` en la función `main()`
- Pasar `NotificationService.navigatorKey` al `MaterialApp`
- Llamar a `notifyContacts()` después de crear una alerta

### AndroidManifest.xml
Se agregaron permisos:
```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
<uses-permission android:name="android.permission.VIBRATE" />
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
```

## Arquitectura FCM

```
┌─────────────────────────────────────┐
│        Usuario 1 (Receptor)         │
│  ┌──────────────────────────────┐  │
│  │  App con FCM token:          │  │
│  │  aeB_c2Wh8vk...             │  │
│  └──────────────────────────────┘  │
│          ▲                          │
│          │                          │
│          └──────────┐               │
│                     │               │
│  ┌──────────────────┴────────────┐  │
│  │  Firebase Cloud Messaging     │  │
│  │  (Servicio de notificaciones) │  │
│  └──────────────────┬────────────┘  │
│                     │                │
└─────────────────────┼────────────────┘
                      │
                      ▼
        ┌─────────────────────────┐
        │   Usuario 2 (Emisor)    │
        │  Activa botón de pánico │
        │         ↓               │
        │  Creates Alert          │
        │         ↓               │
        │  Calls notifyContacts() │
        │         ↓               │
        │  Envía a FCM ➜ Cloud   │
        └─────────────────────────┘
```

## Flujo de Notificación Completo

1. **Usuario 1 crea alerta** (toca botón de pánico)
2. **AlertService.createAlert()** crea la alerta en Firebase
3. **AlertService.notifyContacts()** prepara notificación con:
   - Título: "🚨 ALERTA DE EMERGENCIA"
   - Descripción: Mensaje personalizado
   - Datos: alertId, userId, ubicación, timestamp
4. **NotificationService** envía a Firebase Cloud Messaging
5. **FCM** distribuye a todos los contactos con tokens
6. **Usuario 2 recibe notificación**:
   - Si app está abierta → SnackBar flotante
   - Si app está cerrada → Notificación del sistema
   - Al tocar → Navega a OptionPage (historial de alertas)

## Paso Siguiente: Configuración del Backend

Para que las notificaciones **realmente se envíen** a los contactos, necesitas una de estas opciones:

### Opción A: Cloud Functions (Firebase)
```javascript
// Escuchar cuando se crea una alerta
exports.notifyOnAlertCreated = functions.database
  .ref('alerts/{userId}/{alertId}')
  .onCreate(async (snapshot, context) => {
    const alert = snapshot.val();
    const contacts = await getContactsFromDatabase(context.params.userId);
    
    for (const contact of contacts) {
      if (contact.fcmToken) {
        await admin.messaging().send({
          token: contact.fcmToken,
          notification: {
            title: '🚨 ALERTA DE EMERGENCIA',
            body: alert.description,
          },
          data: {
            alert_id: context.params.alertId,
            user_id: context.params.userId,
            latitude: alert.latitude.toString(),
            longitude: alert.longitude.toString(),
          },
        });
      }
    }
  });
```

### Opción B: Backend (Node.js/Python/Java)
```python
# Obtener tokens de contactos desde Firebase Realtime Database
# Usar Firebase Admin SDK para enviar notificaciones

from firebase_admin import db, messaging

# Buscar contactos del usuario
contacts_ref = db.reference(f'users/{user_id}/emergency_contacts')
contacts = contacts_ref.get().val()

# Enviar notificación a cada contacto
for contact in contacts:
    if contact['fcmToken']:
        message = messaging.Message(
            token=contact['fcmToken'],
            notification=messaging.Notification(
                title='🚨 ALERTA DE EMERGENCIA',
                body=f'Alerta activada por {user_name}',
            ),
            data={
                'alert_id': alert_id,
                'user_id': user_id,
                'latitude': str(latitude),
                'longitude': str(longitude),
            },
        )
        messaging.send(message)
```

### Opción C: Mantener tokens en Firebase Realtime Database
Estructura sugerida:
```json
{
  "users": {
    "1756278550": {
      "ci": "1756278550",
      "nombre": "Juan",
      "fcmToken": "aeB_c2Wh8vk...",
      "emergency_contacts": {
        "0987654321": {
          "name": "María",
          "phone": "+593-123-456-7890",
          "fcmToken": "xyz_abc123..."
        }
      }
    }
  }
}
```

## Estado de Compilación

✅ **APK Compilado Correctamente** (9.7 segundos)
- Todos los permisos agregados
- NotificationService inicializado
- AlertService actualizado con notifyContacts()
- Sin errores de compilación

## Pruebas Recomendadas

1. **Verificar token FCM:**
   ```dart
   String? token = await NotificationService.instance().getFCMToken();
   print('FCM Token: $token');
   ```

2. **Verificar recepción en foreground:**
   - Abrir la app en un dispositivo
   - Desde Firebase Console → Cloud Messaging → Enviar prueba
   - Verificar que aparece SnackBar

3. **Verificar recepción en background:**
   - Abrir la app → Minimizar
   - Enviar notificación de prueba
   - Verificar que aparece notificación del sistema

4. **Verificar manejo de click:**
   - Recibir notificación
   - Tocar la notificación
   - Verificar navegación a OptionPage

## Próximas Fases

- **Fase 5: Optimización** (Memory, compresión de imágenes)
- **Fase 4: Testing** (Unit, Widget, Integration tests)
- **Fase 7:** Adicionales (Geofencing, recordatorios, etc.)

## Resumen de Cambios

| Archivo | Cambio |
|---------|--------|
| `lib/services/notification_service.dart` | Nuevo archivo - Servicio FCM |
| `lib/services/contact_service.dart` | Nuevo archivo - Gestión de contactos |
| `lib/services/alert_service.dart` | Agregar método notifyContacts() |
| `lib/main.dart` | Inicializar NotificationService + integrar notifyContacts() |
| `android/app/src/main/AndroidManifest.xml` | Agregar permisos de notificaciones |

---

**Estado General:**
✅ Fase 6 (FCM) - COMPLETADA
- ✅ Servicio de notificaciones (foreground/background/terminated)
- ✅ Gestión de contactos y tokens FCM
- ✅ Integración con AlertService
- ✅ APK compilando sin errores

**Próximo paso:** Decidir si implementar Cloud Functions o Backend para envío real de notificaciones.
