# Integración OneSignal - Guía de Configuración

## 📋 Descripción General

Esta guía detalla cómo configurar OneSignal para enviar notificaciones push programadas de recordatorios de citas médicas en Life Alert.

OneSignal se integra junto con FCM (Firebase Cloud Messaging) para proporcionar:
- ✅ Notificaciones locales (sin internet, usando flutter_local_notifications)
- ✅ Notificaciones push (con internet, usando OneSignal + FCM)
- ✅ Programación de recordatorios en tiempos específicos
- ✅ Múltiples recordatorios por usuario

---

## 🔐 Paso 1: Crear Cuenta en OneSignal

1. Ve a [OneSignal.com](https://onesignal.com)
2. Crea una cuenta (Gratis hasta 30,000 notificaciones/mes)
3. Inicia sesión en tu dashboard

---

## 🆔 Paso 2: Crear Aplicación en OneSignal

1. En el dashboard, haz clic en **"Create Application"**
2. Nombre: `Life Alert` (o el que prefieras)
3. Plataforma: Selecciona **Android** y **iOS**
4. Haz clic en **"Create"**

Después de crear:
- Te darán un **App ID** (ej: `12345678-1234-1234-1234-123456789012`)
- Guárdalo, lo necesitarás

---

## 📱 Paso 3: Configurar Firebase en OneSignal (Android)

### 3.1 Obtener credenciales de Firebase

1. Ve a [Firebase Console](https://console.firebase.google.com)
2. Selecciona tu proyecto `flutter_application_1`
3. Ve a **Configuración del proyecto** (rueda engranaje)
4. Tab: **Cuentas de servicio**
5. Haz clic en **Generar nueva clave privada**
6. Se descargará un archivo JSON (guárdalo temporalmente)

### 3.2 Cargar en OneSignal

1. Ve a OneSignal Dashboard
2. Selecciona tu app
3. Ve a **Settings** → **Keys & IDs**
4. En la sección **Android**, busca **Google Server API Key**
5. Haz clic en **Upload Service Account JSON**
6. Carga el archivo JSON descargado

---

## 🍎 Paso 4: Configurar para iOS (Opcional)

Si planeas compilar para iOS:

1. En OneSignal: **Settings** → **Keys & IDs**
2. Sección **Apple**
3. Necesitarás un **Apple Push Notifications (APNs) Certificate**
4. Sigue la guía en OneSignal para obtenerlo desde Apple Developer

*(No es obligatorio para Android)*

---

## 🔧 Paso 5: Configurar el Código

### 5.1 Añadir el App ID a OneSignalService

Abre: `lib/services/onesignal_service.dart`

Busca esta línea:
```dart
static const String oneSignalAppId = 'YOUR_ONESIGNAL_APP_ID';
```

Reemplaza `YOUR_ONESIGNAL_APP_ID` con tu App ID de OneSignal.

**Ejemplo:**
```dart
static const String oneSignalAppId = '12345678-1234-1234-1234-123456789012';
```

### 5.2 Instalar dependencias

En la terminal, ejecuta:
```bash
cd c:\Users\MateoM\Desktop\Proyecto-app\flutter_application_1
flutter pub get
```

---

## ✅ Paso 6: Verificar Configuración

### 6.1 Compilar la app

```bash
flutter clean
flutter pub get
flutter run
```

### 6.2 Ver logs de inicialización

En el terminal o logcat, deberías ver:
```
[OneSignalService.initialize] ========================================
[OneSignalService.initialize] INICIALIZANDO ONESIGNAL
[OneSignalService.initialize] ========================================
[OneSignalService.initialize] Player ID: player_12345...
[OneSignalService.initialize] Vínculo creado: 1756278550 -> player_12345...
[OneSignalService.initialize] ========================================
[OneSignalService.initialize] ✓ ONESIGNAL INICIALIZADO EXITOSAMENTE
```

Si ves errores, verifica:
- ✅ App ID correcto en `onesignal_service.dart`
- ✅ Credenciales de Firebase en OneSignal
- ✅ Permisos de notificaciones en el dispositivo

---

## 🧪 Paso 7: Probar Notificaciones

### 7.1 Desde OneSignal Dashboard

1. Abre tu app en OneSignal
2. Ve a **Audience** → **Send Notification**
3. Selecciona **Test Sending**
4. Elige tu dispositivo
5. Escribe un mensaje de prueba
6. Envía

Si todo está bien, deberías recibir la notificación en tu dispositivo.

### 7.2 Desde el Código

En `options.dart`, cuando el usuario agrega una cita:

```dart
// Ejemplo: Programar recordatorio para mañana a las 2 PM
final appointmentTime = DateTime.now().add(Duration(days: 1, hours: 2));

await AppointmentReminderService.instance().scheduleAppointmentReminder(
  appointmentId: 'cita_cardiologo_15082026',
  appointmentDateTime: appointmentTime,
  doctorName: 'Dr. Cardiólogo',
  appointmentDate: '15/08/2026',
  appointmentTime: '14:00',
  minutesBeforeReminder: 60, // Recordatorio 1 hora antes
);
```

---

## 📊 Características de OneSignal

### Dashboard

En OneSignal Dashboard puedes:
- ✅ Ver número de notificaciones enviadas
- ✅ Ver tasa de entrega
- ✅ Ver clicks en notificaciones
- ✅ Segmentar usuarios
- ✅ Programar notificaciones futuras manualmente

### API

OneSignal ofrece API REST para:
- Enviar notificaciones programadas
- Crear segmentos de usuarios
- Actualizar información de usuario

*(Configuración avanzada - no necesaria para el MVP)*

---

## 🐛 Troubleshooting

### Problema: "Your OneSignal Account Requires User Authentication"

**Solución:**
1. Verifica tu email en OneSignal
2. Completa la verificación de email
3. Reinicia la app

### Problema: Firebase Service Account JSON no carga

**Solución:**
1. Verifica que sea el archivo JSON correcto de Firebase
2. Elimina espacios en blanco en el email del servicio
3. Intenta descargar nuevamente en Firebase Console

### Problema: Notificaciones no se reciben

**Solución:**
1. Verifica que AppID de OneSignal sea correcto
2. Verifica que Firebase Credentials estén configuradas
3. Verifica permisos de notificación en el dispositivo (Android 13+)
4. Verifica los logs de la app en OneSignal Dashboard

### Problema: "Player ID: null"

**Solución:**
1. OneSignal aún se está inicializando
2. Espera 2-3 segundos después de iniciar la app
3. Recarga la app

---

## 🎯 Flujo de Recordatorios (Cómo Funciona)

```
1. Usuario registra cita médica
   ↓
2. Usuario selecciona fecha, hora y recordatorio (ej: 1 hora antes)
   ↓
3. App llama a AppointmentReminderService.scheduleAppointmentReminder()
   ↓
4. Se programan 2 recordatorios:
   ├─ Notificación LOCAL (flutter_local_notifications)
   │  └─ Funciona incluso sin internet
   └─ Notificación PUSH (OneSignal + FCM)
      └─ Se entrega por internet cuando está disponible
   ↓
5. En la hora programada:
   ├─ Dispositivo recibe notificación LOCAL
   └─ Servidor OneSignal envía notificación PUSH (si hay internet)
   ↓
6. Usuario ve notificación
   ↓
7. Usuario toca notificación (opcional)
   └─ App se abre o trae a foreground
```

---

## 📚 Documentación Adicional

- [OneSignal Docs](https://documentation.onesignal.com)
- [OneSignal Flutter SDK](https://github.com/OneSignal/OneSignal-Flutter-SDK)
- [Firebase + OneSignal Integration](https://documentation.onesignal.com/docs/firebase-setup)

---

## 📝 Notas Importantes

1. **Gratis**: OneSignal es gratis hasta 30,000 notificaciones/mes
2. **Sin costo de servidor**: OneSignal maneja todo el backend
3. **Analytics**: Puedes ver estadísticas de entrega en OneSignal Dashboard
4. **Persistencia**: Los recordatorios se guardan en SharedPreferences y se cargan al abrir la app
5. **Sin conexión**: Las notificaciones locales funcionan incluso sin internet

---

## 🚀 Próximos Pasos

1. ✅ Implementación completada
2. ⏭️ Pruebas en dispositivo real
3. ⏭️ Compilación para producción
4. ⏭️ Publicación en Play Store

---

## 📞 Soporte

Si tienes problemas:
1. Revisa los logs en `flutter run`
2. Verifica OneSignal Dashboard → Logs
3. Consulta Troubleshooting arriba
