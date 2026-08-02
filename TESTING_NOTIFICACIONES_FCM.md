# 📱 Guía: Cómo Comprobar Notificaciones Push (FCM)

## Paso 1: Obtener el Token FCM del Dispositivo

### Opción A: Desde Logs (Recomendado)
1. Conecta tu dispositivo Android o emulador
2. Abre la app
3. Revisa los logs en VS Code:
   ```bash
   flutter logs
   ```
4. Busca esta línea:
   ```
   🔔 FCM Token: aeB_c2Wh8vk_AaBbCcDd...
   ```

### Opción B: Desde DevTools
1. En VS Code, abre **Run and Debug**
2. Ejecuta: `flutter run`
3. Cuando la app esté corriendo, presiona `d` (DevTools)
4. Ve a **Console** y ejecuta:
   ```dart
   import 'package:flutter_application_1/services/notification_service.dart';
   
   void main() async {
     String? token = await NotificationService.instance().getFCMToken();
     print('Mi FCM Token: $token');
   }
   ```

### Opción C: Agregar Código Temporal en main.dart
Edita `lib/main.dart` y agrega en la función `main()`:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  print('[main] iniciando app...');
  
  // Inicializar Firebase
  try {
    await FirebaseService.instance.initialize();
    print('[main] Firebase inicializado correctamente');
  } catch (e) {
    print('[main] ERROR al inicializar Firebase: $e');
  }
  
  // Inicializar FCM
  try {
    await NotificationService.instance().initialize();
    print('[main] NotificationService inicializado correctamente');
  } catch (e) {
    print('[main] ERROR al inicializar NotificationService: $e');
  }
  
  // 🔥 AGREGAR ESTO PARA OBTENER EL TOKEN
  try {
    String? token = await NotificationService.instance().getFCMToken();
    print('═══════════════════════════════════════════════');
    print('🎯 MI TOKEN FCM:');
    print(token);
    print('═══════════════════════════════════════════════');
  } catch (e) {
    print('Error al obtener token: $e');
  }
  
  runApp(const MyApp());
}
```

Luego ejecuta:
```bash
flutter run
```

Y busca en los logs:
```
═══════════════════════════════════════════════
🎯 MI TOKEN FCM:
aeB_c2Wh8vk_AaBbCcDdEeFfGgHhIiJjKkLlMmNnOo
═══════════════════════════════════════════════
```

**⚠️ IMPORTANTE:** Después de copiar el token, remueve este código de main.dart

---

## Paso 2: Enviar Notificación de Prueba desde Firebase Console

### Acceder a Firebase Console

1. Ve a: https://console.firebase.google.com/
2. Selecciona tu proyecto `flutter_application_1`
3. En el menú izquierdo: **Cloud Messaging**
4. Click en **"Enviar tu primer mensaje"** o **"Nuevo mensaje"**

### Configurar Notificación de Prueba

```
┌─────────────────────────────────────────┐
│ CREAR NOTIFICACIÓN DE PRUEBA            │
├─────────────────────────────────────────┤
│                                         │
│ Título: 🚨 ALERTA DE PRUEBA             │
│                                         │
│ Cuerpo: Esta es una notificación de     │
│         prueba desde Firebase Console   │
│                                         │
│ Imagen: (dejar en blanco)               │
│                                         │
│ Datos (opcional):                       │
│   alert_id: "test_123"                  │
│   user_id: "prueba"                     │
│   latitude: "0.2206"                    │
│   longitude: "-78.4872"                 │
│                                         │
└─────────────────────────────────────────┘
```

### Seleccionar Destino

1. **Selecciona:** "Dispositivos específicos"
2. Pega el token que obtuviste en Paso 1
3. Click en **"Revisar"**

### Enviar

1. Click en **"Publicar"**
2. Espera confirmación

---

## Paso 3: Comprobar Notificaciones en Foreground

**Estado de la app:** ✅ ABIERTA

### Qué deberías ver:

```
┌─────────────────────────────────────────────┐
│                                             │
│  ┌───────────────────────────────────────┐  │
│  │ 🚨 ALERTA DE PRUEBA                   │  │
│  │ Esta es una notificación de prueba... │  │
│  │              [Ver]                    │  │
│  └───────────────────────────────────────┘  │
│                                             │
│  (SnackBar flotante rojo que desaparece    │
│   en 5 segundos)                           │
│                                             │
└─────────────────────────────────────────────┘
```

### Verificar en Logs:

Deberías ver:
```
[I] 📬 Notificación en foreground recibida:
[I] Título: 🚨 ALERTA DE PRUEBA
[I] Body: Esta es una notificación de prueba...
[I] Data: {alert_id: test_123, user_id: prueba, ...}
```

### Si NO ves nada:

1. Verifica que NotificationService se inicializó:
   ```
   [main] NotificationService inicializado correctamente
   ```

2. Verifica los permisos:
   - Android 13+: Ve a Configuración → Apps → Tu app → Permisos → Notificaciones (debe estar ON)

3. Verifica el token en Firebase Console:
   - El token que pegaste ¿es correcto?
   - ¿Pertenece a la misma app que estás usando?

---

## Paso 4: Comprobar Notificaciones en Background

**Estado de la app:** 📲 MINIMIZADA

### Pasos:

1. La app está abierta
2. Envía otra notificación de prueba desde Firebase Console
3. **Antes de recibirla, presiona el botón "Home" del dispositivo**
4. La app se minimiza

### Qué deberías ver:

En la barra de notificaciones del sistema:
```
═══════════════════════════════════════════════
🚨 ALERTA DE PRUEBA
Esta es una notificación de prueba...
═══════════════════════════════════════════════
```

### Verificar:

1. Desliza desde la parte superior → Podrás ver la notificación
2. Toca la notificación → Debería abrir la app
3. Verifica los logs:
   ```
   [I] 📭 Notificación desde background/terminated:
   [I] Título: 🚨 ALERTA DE PRUEBA
   ```

---

## Paso 5: Comprobar Notificaciones con App Terminada

**Estado de la app:** ❌ CERRADA

### Pasos:

1. La app está abierta
2. **Cierra completamente la app:**
   - Android: Desliza la app hacia arriba en "Recent apps"
   - Emulador: Presiona botón Back hasta salir

3. Envía notificación desde Firebase Console
4. Espera 3-5 segundos

### Qué deberías ver:

Notificación en la barra del sistema (igual que en background)

### Al tocarla:

La app se abre automáticamente y debería navegar a **OptionPage** (historial de alertas)

---

## Paso 6: Prueba Completa de Flujo

### Simular una Alerta Real

Si quieres probar el flujo completo SIN necesidad de backend:

1. **Abre la app**
2. **Presiona el botón de pánico** (mantén 1.2 segundos)
3. Verifica en Firebase Console → Realtime Database:
   ```json
   {
     "alerts": {
       "1756278550": {
         "1756278550_mod1": {
           "id": "1756278550_mod1",
           "timestamp": 1703276645000,
           "description": "Alerta de pánico activada",
           ...
         }
       }
     }
   }
   ```

4. Verifica en los logs que se llamó a `notifyContacts()`:
   ```
   [AlertService.notifyContacts] Notificando a contactos...
   [AlertService.notifyContacts] Título: 🚨 ALERTA DE EMERGENCIA
   ```

---

## Checklist de Pruebas

```
Verificación Básica:
  ☐ Token FCM obtenido correctamente
  ☐ Token visible en Firebase Console
  ☐ Notificación enviada sin errores

Foreground:
  ☐ SnackBar aparece al recibir notificación
  ☐ Título y descripción correctos
  ☐ Botón "Ver" es clickeable
  ☐ Desaparece después de 5 segundos

Background:
  ☐ Notificación aparece en barra del sistema
  ☐ Se puede expandir
  ☐ Se puede hacer clic
  ☐ Navega a OptionPage

Terminada:
  ☐ Notificación persiste en barra
  ☐ Al hacer clic se abre la app
  ☐ Navega a OptionPage correctamente

Logs:
  ☐ "[main] NotificationService inicializado correctamente"
  ☐ "🔔 FCM Token: ..." aparece al inicio
  ☐ Al recibir: "📬 Notificación en foreground recibida"
  ☐ Al recibir en background: "📭 Notificación desde background/terminated"
```

---

## Solución de Problemas

### ❌ No veo el token FCM

**Posibles causas:**
1. NotificationService no se inicializó → Verifica main.dart
2. Firebase no está inicializado → Verifica que google-services.json existe
3. El permiso de notificaciones fue rechazado → Ir a Configuración y permitir

**Solución:**
```dart
// En main.dart, revisa estos logs:
[main] Firebase inicializado correctamente
[main] NotificationService inicializado correctamente
🔔 FCM Token: [aquí debe aparecer el token]
```

### ❌ No recibo notificaciones en Firebase Console

**Posibles causas:**
1. Token incorrecto → Copia de nuevo
2. App cerrada completamente → Necesitas tenerla en background al menos
3. Permiso de notificaciones denegado → Android → Configuración → Permisos

**Solución:**
```bash
# Verifica los permisos
adb shell dumpsys package com.example.flutter_application_1 | grep NOTIFICATION
```

### ❌ Recibo notificación pero no aparece SnackBar

**Posibles causas:**
1. navigatorKey no está asignado → Verifica MyApp build()
2. NotificationService.navigatorKey es null → Verifica inicialización

**Solución:**
```dart
// En main.dart
@override
Widget build(BuildContext context) {
  return MaterialApp(
    navigatorKey: NotificationService.navigatorKey,  // ✅ Debe estar aquí
    home: const HomeScreen(),
  );
}
```

### ❌ El SnackBar no tiene el botón "Ver"

**Solución:**
Verificar que el SnackBar en notification_service.dart tiene la estructura correcta con `action: SnackBarAction(...)`.

---

## Resumen de Comandos Útiles

```bash
# Ver logs en tiempo real
flutter logs

# Ver solo notificaciones
flutter logs | grep -i notification

# Ver token
flutter logs | grep "FCM Token"

# Compilar y ver logs
flutter run --verbose 2>&1 | grep -E "FCM|notification|ERROR"

# En emulador, simular notificación (sin Firebase Console)
adb shell am startservice -n com.google.android.gms/.notification.NotificationService
```

---

## Próximos Pasos Después de Verificar

Una vez que confirmes que las notificaciones funcionan:

1. **Implementar ContactService** en la UI (agregar contactos con tokens)
2. **Configurar Cloud Function** para envíos reales (backend)
3. **Probar con múltiples dispositivos** (un dispositivo envía, otros reciben)

---

**¡Ahora estás listo para probar las notificaciones! 🚀**
