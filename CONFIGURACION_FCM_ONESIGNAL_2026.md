# ✅ Checklist de Configuración FCM + OneSignal

## 📋 PARTE 1: FIREBASE CLOUD MESSAGING (FCM)

### ✅ En Firebase Console:
1. Ve a [Firebase Console](https://console.firebase.google.com)
2. Selecciona proyecto `flutter_application_1`
3. Ve a **Cloud Messaging** (en el menú izquierdo)
4. Verifica que esté habilitado ✅

### ✅ En Android Studio:
1. ✅ `android/app/google-services.json` existe (YA PRESENTE)
   - Contiene: `project_id`, `api_key`, `sender_id`, etc.
2. ✅ `android/build.gradle.kts` tiene plugin:
   ```gradle
   id("com.google.gms.google-services")
   ```
3. ✅ `android/app/build.gradle.kts` tiene:
   ```gradle
   implementation("com.google.firebase:firebase-messaging:...")
   ```

### ✅ En pubspec.yaml:
```yaml
firebase_messaging: ^16.1.0  ✅ YA PRESENTE
```

---

## 📋 PARTE 2: ONESIGNAL

### ✅ En OneSignal Dashboard:

#### 1. **App ID Configurado**
- ✅ App ID: `ea14f407-6f2d-4be0-b326-a93c029c8add`
- Ubicación: Settings → Keys & IDs

#### 2. **Android Configuration**
- Ve a **Settings** → **Keys & IDs**
- Sección **Android**:
  - ✅ Google Server API Key: **DEBE ESTAR CARGADO** (subiste el JSON)
  - ✅ Firebase Credentials: Verificar que muestre status "✅ Configured"

#### 3. **Verificar JSON fue procesado**
- En OneSignal Dashboard
- Settings → Keys & IDs → Android
- Debe mostrar: "Google Cloud Project ID: ..." ✅

### ✅ En pubspec.yaml:
```yaml
onesignal_flutter: ^5.6.7  ✅ YA PRESENTE
```

### ✅ En código (lib/services/onesignal_service.dart):
```dart
static const String oneSignalAppId = 'ea14f407-6f2d-4be0-b326-a93c029c8add';  ✅ CONFIGURADO
```

---

## 🔧 PARTE 3: VERIFICACIÓN ANTES DE COMPILAR

### En Firebase Console - Cloud Messaging:

```
Cloud Messaging
├─ Android Configuration
│  ├─ Sender ID: (debe existir)
│  └─ API Key: (debe existir)
└─ Status: ✅ Enabled
```

### En OneSignal Dashboard - Settings → Keys & IDs:

```
Android
├─ Google Cloud Project ID: (debe mostrar tu proyecto)
├─ Firebase Credentials: ✅ Configured
├─ Authorized Platforms: ✅ Android
└─ Status: ✅ Ready
```

---

## 📱 PARTE 4: PERMISOS EN ANDROID

### ✅ AndroidManifest.xml debe tener:

```xml
<!-- Notificaciones -->
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />

<!-- OneSignal - obligatorio -->
<uses-permission android:name="com.google.android.c2dm.permission.RECEIVE" />

<!-- Firebase -->
<service android:name="com.google.firebase.messaging.FirebaseMessagingService">
    <intent-filter>
        <action android:name="com.google.firebase.MESSAGING_EVENT" />
    </intent-filter>
</service>
```

*(Generalmente Flutter lo configura automáticamente con los plugins)*

---

## 🚀 PARTE 5: PASOS ANTES DE EJECUTAR

### ✅ Antes de `flutter run`:

1. **Limpiar y reinstalar dependencias:**
   ```bash
   cd c:\Users\MateoM\Desktop\Proyecto-app\flutter_application_1
   flutter clean
   flutter pub get
   ```

2. **Verificar análisis:**
   ```bash
   flutter analyze
   ```
   Debe pasar sin errores críticos ✅

3. **Compilar debug:**
   ```bash
   flutter run
   ```

---

## 🔍 PARTE 6: VERIFICACIÓN EN TIEMPO DE EJECUCIÓN

### Cuando la app inicie, deberías ver en logcat:

```
[OneSignalService.initialize] ========================================
[OneSignalService.initialize] INICIALIZANDO ONESIGNAL
[OneSignalService.initialize] ========================================
[OneSignalService.initialize] Player ID: (un UUID)
[OneSignalService.initialize] ✓ ONESIGNAL INICIALIZADO EXITOSAMENTE
```

Si ves esto: ✅ **OneSignal funcionando**

```
[FirebaseService.initialize] Firebase inicializado correctamente
```

Si ves esto: ✅ **Firebase funcionando**

---

## ❌ PROBLEMAS COMUNES

### Problema: "OneSignal App ID not found"
- ❌ La constante `oneSignalAppId` está vacía o mal configurada
- ✅ Solución: Reemplaza en onesignal_service.dart con tu App ID real

### Problema: "FCM Token not generated"
- ❌ Firebase credentials no están bien configuradas
- ✅ Solución: Verifica google-services.json en android/app/

### Problema: "OneSignal initialization failed"
- ❌ OneSignal Dashboard no tiene Firebase configurado
- ✅ Solución: Ve a OneSignal Settings → Keys & IDs y carga el JSON

### Problema: "Permission denied for POST_NOTIFICATIONS"
- ❌ Permisos de Android no solicitados
- ✅ Solución: Permission Handler pide permisos en runtime

---

## ✅ CHECKLIST FINAL ANTES DE EJECUTAR

- [ ] google-services.json existe en `android/app/`
- [ ] OneSignal App ID está configurado en onesignal_service.dart
- [ ] OneSignal Dashboard muestra Firebase como "Configured"
- [ ] Firebase Console muestra Cloud Messaging habilitado
- [ ] flutter pub get completó sin errores
- [ ] flutter analyze pasa sin errores críticos
- [ ] Emulador Android Studio está corriendo
- [ ] Permiso POST_NOTIFICATIONS para Android 13+

**Si todo está ✅, procede con: `flutter run`**

---

## 📞 PARA PROBAR EN EMULADOR

### Opción 1: Enviar notificación de prueba desde OneSignal

1. OneSignal Dashboard
2. **Campaigns** → **New Campaign** → **Push Notification**
3. Título: "Test OneSignal"
4. Contenido: "¡Funciona!"
5. Send to: **Subscribers** (selecciona tu app)
6. Schedule: **Send now**
7. Click **"Send Campaign"**

Deberías ver la notificación en tu emulador 📲

---

## 🔗 REFERENCIAS

- [Firebase Setup for Flutter](https://firebase.google.com/docs/flutter/setup)
- [OneSignal Flutter Setup](https://documentation.onesignal.com/docs/flutter-sdk-setup)
- [Firebase Cloud Messaging](https://firebase.google.com/docs/cloud-messaging)
