# Testing Pushwoosh Integration

## Estado Actual
✅ **Compilación exitosa**: APK 53.6MB generado sin errores
✅ **API correcta**: Usando `Pushwoosh.getInstance.onPushReceived/onPushAccepted`
✅ **Inicialización**: Configurada en `main.dart` después de Firebase

## 1. Instalación en Dispositivo

### Opción A: Emulador Android
```bash
# Generar APK signed si no existe
flutter build apk --release

# Instalar en emulador
adb install build/app/outputs/flutter-apk/app-release.apk

# Ver logs en tiempo real
adb logcat -s flutter
```

### Opción B: Dispositivo Real
```bash
# Conectar dispositivo USB con debug activado
adb devices

# Instalar
adb install build/app/outputs/flutter-apk/app-release.apk

# Ver logs
adb logcat | grep -i "pushwoosh\|flutter"
```

## 2. Verificar Inicialización

Cuando la app inicia, buscar en logs:
```
[main] PushwooshService inicializado correctamente
✓ PUSHWOOSH INICIALIZADO EXITOSAMENTE
✓ Registrado para notificaciones push
```

**Si hay error:**
```
✗ ERROR AL INICIALIZAR PUSHWOOSH
```
→ Revisar AndroidManifest token

## 3. Enviar Notificación de Prueba

### Desde Pushwoosh Console
1. Ir a https://app.pushwoosh.com/login
2. Seleccionar app (usa token: `uoc4hxfPwguY42PNHlvblSP6mkH6TCbap8d66CB185`)
3. Create Campaign → Test Push
4. Enviar a device actual

### Verificar Recepción
En logs debe aparecer:
```
[Pushwoosh.onPushReceived] Notificación recibida en foreground
```

## 4. Verificar Tap en Notificación

Tocar la notificación debe mostrar en logs:
```
[Pushwoosh.onPushAccepted] Notificación tocada
[PushwooshService] Procesando notificación tocada
```

## 5. Problemas Comunes

### Error: "Token not found"
- **Causa**: Token en AndroidManifest no configu rado
- **Solución**: Verificar `android/app/src/main/AndroidManifest.xml`
```xml
<meta-data
    android:name="com.pushwoosh.apitoken"
    android:value="uoc4hxfPwguY42PNHlvblSP6mkH6TCbap8d66CB185" />
```

### Error: "Firebase not initialized"
- **Causa**: PushwooshService se ejecuta antes que Firebase
- **Solución**: main.dart inicializa en orden correcto

### Notificación no llega
- **Causa 1**: Emulador puede no soportar FCM bien
- **Solución 1**: Usar dispositivo real
- **Causa 2**: App no tiene permiso POST_NOTIFICATIONS
- **Solución 2**: Revisar AndroidManifest permisos

## 6. Próximos Pasos

### Integración con Citas
En `lib/options.dart` cuando se crea cita:
```dart
// Después de guardar cita a SharedPreferences
try {
  await AppointmentReminderService.instance().scheduleReminder(appointment);
  await PushwooshService.instance().sendAppointmentReminder(
    doctorName: appointment.doctorName,
    appointmentDate: appointment.date,
    appointmentTime: appointment.time,
    appointmentId: appointment.id,
  );
} catch (e) {
  print('Error al programar recordatorio: $e');
}
```

### Backend API
Crear endpoint para enviar Pushwoosh:
```
POST /api/appointments/{appointmentId}/notify

Body:
{
  "patientDeviceId": "...",
  "title": "Recordatorio de Cita",
  "message": "Tienes cita con Dr. García el 15 de Febrero 2:00 PM",
  "customData": {
    "appointmentId": "cita_123",
    "doctorName": "Dr. García"
  }
}

Autenticación con Pushwoosh API:
POST https://api.pushwoosh.com/json/1.3/sendMessage
Authorization: Pushwoosh-REST-API-Version: 0.1
X-Pushwoosh-Auth-Token: uoc4hxfPwguY42PNHlvblSP6mkH6TCbap8d66CB185
```

## 7. Archivo de Configuración

**Localización**: `android/app/src/main/AndroidManifest.xml`

```xml
<application>
    <!-- Pushwoosh Token -->
    <meta-data
        android:name="com.pushwoosh.apitoken"
        android:value="uoc4hxfPwguY42PNHlvblSP6mkH6TCbap8d66CB185" />
    
    <activity
        android:name=".MainActivity"
        ...
    />
</application>
```

## 8. Changelog

### 2026-02-08 - Integración Pushwoosh v2.3.22
- ✅ Agregado pushwoosh_flutter: ^2.3.22
- ✅ Creado PushwooshService singleton
- ✅ Inicialización en main.dart
- ✅ API corregida: getInstance.onPushReceived/onPushAccepted
- ✅ Compilación verificada
- ⏳ Pendiente: Testing en dispositivo real
