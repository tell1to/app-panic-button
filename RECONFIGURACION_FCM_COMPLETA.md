# 🔧 Reconfigurando Firebase Cloud Messaging (FCM) - Guía Completa

**Fecha:** 30 de Julio de 2026  
**Estado:** Configuración desde cero  
**Versión:** firebase_messaging 16.1.0

---

## ❌ Problema

Las reglas de Firebase están dando error. Necesitamos reconfigurar Firebase Messaging desde cero.

---

## ✅ Solución - 6 Pasos

### **PASO 1: Verificar google-services.json**

Las notificaciones necesitan el archivo `google-services.json` correcto.

**Ubicación esperada:**
```
android/app/google-services.json
```

**Cómo verificar:**
1. Abre Firebase Console: https://console.firebase.google.com
2. Selecciona proyecto: `flutter_application_1`
3. ⚙️ (esquina arriba a la izquierda) → Project Settings
4. Tab: **Google Play (Android)**
5. Botón: **Descargar google-services.json**
6. Reemplaza el archivo en `android/app/google-services.json`

**✅ Verificar que el archivo tiene:**
```json
{
  "type": "service_account",
  "project_id": "tu-proyecto",
  "private_key_id": "...",
  "private_key": "...",
  "client_email": "...",
  "client_id": "...",
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://oauth2.googleapis.com/token"
}
```

---

### **PASO 2: Configurar Android (Nivel de Proyecto)**

Abre `android/build.gradle.kts` (nivel de proyecto, NO el del app):

```kotlin
plugins {
    id("com.android.application") version "8.1.0" apply false
    id("org.jetbrains.kotlin.android") version "1.9.0" apply false
    
    // ✅ Google Services (para FCM)
    id("com.google.gms.google-services") version "4.4.0" apply false
}
```

Verifica que EXISTE la línea:
```
id("com.google.gms.google-services") version "4.4.0" apply false
```

---

### **PASO 3: Configurar Android (Nivel de App)**

Abre `android/app/build.gradle.kts`:

**Verifica que esté al inicio del archivo:**
```kotlin
plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    
    // ✅ Google Services (debe estar después de Android y Kotlin plugins)
    id("com.google.gms.google-services")
}
```

---

### **PASO 4: Verificar Dependencias**

Abre `pubspec.yaml` y verifica que tienes:

```yaml
dependencies:
  firebase_core: ^4.3.0      # ✅ Obligatorio
  firebase_messaging: ^16.1.0 # ✅ FCM
  flutter_local_notifications: ^19.5.0 # ✅ Para mostrar en foreground
```

Ejecuta:
```bash
flutter pub get
```

---

### **PASO 5: Actualizar Reglas de Firebase (SIN ERRORES)**

Las reglas anteriores pueden tener errores de JSON. Aquí está la versión CORRECTA para desarrollo:

1. Firebase Console: https://console.firebase.google.com
2. Proyecto: `flutter_application_1`
3. Build → Realtime Database → **Reglas**
4. **BORRA TODO** y copia esto exactamente:

```json
{
  "rules": {
    ".read": false,
    ".write": false,
    "users": {
      "$uid": {
        ".read": true,
        ".write": true,
        "alerts": {
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

**⚠️ IMPORTANTE:**
- Verifica que NO hay comas faltantes
- Verifica que NO hay comillas sin cerrar
- Click en **Publicar** (no Guardar borradores)
- Espera: "✅ Reglas publicadas exitosamente"

---

### **PASO 6: Limpiar y Recompilar**

Ejecuta ESTOS comandos en orden:

```bash
# 1. Limpiar todo
flutter clean

# 2. Descargar dependencias nuevamente
flutter pub get

# 3. Para Android específicamente
cd android
./gradlew clean
cd ..

# 4. Ejecutar la app
flutter run -v
```

**En los logs deberías ver:**
```
✅ FCM Token obtenido: ...
✅ Handlers configurados
✅ Notificaciones locales configuradas
✅ Canal Android creado
```

---

## 🧪 Testing

### **Verificar que FCM está funcionando:**

```bash
# 1. Ejecuta la app
flutter run

# 2. En los LOGS, busca estas líneas (copia y pega):
[FCM.initialize] ✅ FCM INICIALIZADO CORRECTAMENTE
[FCM.initialize] 🔑 FCM Token: ...
[FCM.initialize] ✅ Notificaciones locales configuradas
[FCM.initialize] ✅ Canal Android creado
```

### **Enviar notificación de prueba:**

1. Firebase Console → Cloud Messaging → **Crear primera campaña**
2. **Notifications**:
   - Título: `Prueba de FCM`
   - Texto del cuerpo: `¿Ves esta notificación?`
3. **Target**:
   - Selecciona tu aplicación: `flutter_application_1`
   - Versión: `Production` (o la que corresponda)
4. **Envío**:
   - Click en **Enviar campaña**

3. **Resultado esperado:**
   - ✅ La app mostrará una notificación (aunque esté en foreground)
   - ✅ Si está en background, mostrará notificación del sistema
   - ✅ Si está terminada, mostrará notificación del sistema

---

## 🆘 Si Persisten los Errores

### **Error: "Permission denied" en Firebase**

**Causa:** Las reglas NO se guardaron correctamente.

**Solución:**
1. Abre Firebase Console
2. Ve a Realtime Database → Reglas
3. Verifica que ves exactamente las reglas que pegaste
4. Si ves las reglas antiguas, pegalas de nuevo
5. Click **Publicar** y espera confirmación

### **Error: FCM Token no se obtiene**

**Causa:** google-services.json no es válido O no se descargó el proyecto en Firebase Console.

**Solución:**
1. Abre Android Studio: `android/`
2. Sync Now (dejando que descargue dependencias)
3. Verifica que `google-services.json` existe en `android/app/`
4. Si no existe, descárgalo nuevamente desde Firebase Console
5. Ejecuta: `flutter pub get` y `flutter run`

### **Error: Plugin FCM no se inicializa**

**Causa:** AndroidManifest.xml no tiene permisos.

**Solución - Verificar `android/app/src/main/AndroidManifest.xml`:**
```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
```

Si NO están, agrega estas líneas antes de `<application>`.

---

## 📋 Checklist Final

- [ ] Descargué google-services.json desde Firebase Console
- [ ] Reemplacé `android/app/google-services.json`
- [ ] Verifiqué que `android/build.gradle.kts` tiene `com.google.gms.google-services`
- [ ] Verifiqué que `android/app/build.gradle.kts` tiene `id("com.google.gms.google-services")`
- [ ] Ejecuté `flutter clean && flutter pub get`
- [ ] Actualicé reglas de Firebase (CORRECTAS)
- [ ] Ejecuté `flutter run -v` y ví el token en logs
- [ ] Envié notificación de prueba desde Firebase Console
- [ ] La notificación llegó a la app

---

## 📞 Archivos Modificados

| Archivo | Acción |
|---------|--------|
| `lib/services/firebase_messaging_config.dart` | ✅ Creado (nuevo servicio FCM) |
| `lib/main.dart` | ✅ Actualizado (usar nuevo servicio) |
| `pubspec.yaml` | ✅ Verificar dependencias |
| `android/app/build.gradle.kts` | ✅ Verificar Google Services plugin |
| `android/build.gradle.kts` | ✅ Verificar Google Services plugin |
| `android/app/google-services.json` | ✅ Descargar nuevamente |
| `android/app/src/main/AndroidManifest.xml` | ✅ Verificar permisos |

---

## 🚀 Resumen

```
1. ✅ Descarga google-services.json
2. ✅ Verifica build.gradle.kts
3. ✅ Actualiza reglas de Firebase
4. ✅ Ejecuta: flutter clean && flutter pub get
5. ✅ Ejecuta: flutter run
6. ✅ Busca token en logs
7. ✅ Envía notificación de prueba
8. ✅ Done!
```

---

## 📌 Preguntas Frecuentes

**P: ¿Necesito hacer algo en iOS?**  
R: SÍ. En iOS va automático si tienes firebase_messaging. Pero requiere que Apple te lo permita (necesita developer account).

**P: ¿Funciona en emulador?**  
R: Parcialmente. El token se obtiene, pero puede que no recibas notificaciones. En dispositivo real SÍ funciona.

**P: ¿Qué es el "FCM Token"?**  
R: Es el identificador único del dispositivo. Se usa para enviar notificaciones solo a ese dispositivo.

**P: ¿Puedo ver los tokens en Firebase Console?**  
R: NO. Los tokens se administran en tu backend. Solo tú puedes verlos en logs.

**P: ¿Cuánto tiempo dura un token?**  
R: Indefinido, hasta que cambien las credenciales de la app o el usuario desinstale.

---

## ✅ Status

✅ Firebase Messaging reconfigurado  
✅ Nuevo servicio `firebase_messaging_config.dart` creado  
✅ main.dart actualizado  
✅ Documentación completa

**Próximo paso:** Sigue los 6 pasos de arriba.
