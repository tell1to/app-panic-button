# 📊 COMPARATIVA: 3 Formas de Comprobar Notificaciones

## Tabla Comparativa

| Método | Tiempo | Dificultad | Resultado |
|--------|--------|-----------|-----------|
| **A: Firebase Console** | 5 min | ⭐ Fácil | Prueba real, visual |
| **B: Flutter Logs** | 3 min | ⭐ Fácil | Token + logs en tiempo real |
| **C: DevTools** | 10 min | ⭐⭐⭐ Difícil | Acceso directo al código |

---

## 🥇 MÉTODO A: Firebase Console (RECOMENDADO)

### Para verificar que FCM realmente funciona

**Tiempo:** 5 minutos  
**Nivel:** Fácil

### Proceso:

```bash
1️⃣ flutter run
   ↓
2️⃣ flutter logs (en otra terminal)
   ↓
3️⃣ Buscar: "🔔 FCM Token: ..."
   ↓
4️⃣ Copiar token
   ↓
5️⃣ https://console.firebase.google.com/
   ↓
6️⃣ Cloud Messaging → Nuevo mensaje
   ↓
7️⃣ Llenar formulario:
   - Título: 🚨 PRUEBA
   - Cuerpo: Hola mundo
   ↓
8️⃣ Seleccionar "Dispositivos específicos"
   ↓
9️⃣ Pegar token
   ↓
🔟 Publicar
   ↓
✅ Ver notificación en la app
```

### Ventajas:
✅ No necesitas código adicional
✅ Prueba la infraestructura completa
✅ Simula un envío real
✅ Visible en Firebase Console

### Desventajas:
❌ Requiere acceso a Firebase Console
❌ No es programático

---

## 🥈 MÉTODO B: Flutter Logs (MÁS RÁPIDO)

### Para verificar que la app recibe notificaciones

**Tiempo:** 3 minutos  
**Nivel:** Fácil

### Proceso:

```bash
Terminal 1:
flutter run

Terminal 2:
flutter logs

# Buscar estas líneas:
🔔 FCM Token: aeB_c2Wh8vk_...
📬 Notificación en foreground recibida:
Título: 🚨 ALERTA DE PRUEBA
Body: Esta es una notificación...
```

### Ventajas:
✅ Rápido
✅ Ve logs en tiempo real
✅ Muestra exactamente qué está pasando
✅ No necesita Firebase Console

### Desventajas:
❌ Solo funciona mientras estés observando
❌ Necesitas otra terminal

---

## 🥉 MÉTODO C: DevTools (MÁS TÉCNICO)

### Para acceso directo al código

**Tiempo:** 10 minutos  
**Nivel:** Avanzado

### Proceso:

```bash
1️⃣ flutter run
   ↓
2️⃣ Presionar 'd' en VS Code para DevTools
   ↓
3️⃣ Console → Ejecutar:
   
   import 'package:flutter_application_1/services/notification_service.dart';
   
   NotificationService.instance().getFCMToken()
     .then((token) => print('Token: $token'));
```

### Ventajas:
✅ Acceso interactivo
✅ Puedes inspeccionar objetos
✅ Debugging avanzado

### Desventajas:
❌ Más complejidad
❌ Más pasos
❌ Requiere conocer DevTools

---

## 🎯 RECOMENDACIÓN

### Primero (para verificar que funciona):
**→ Usa MÉTODO B (Flutter Logs)** - 3 minutos

```bash
flutter run
flutter logs | grep -i "fcm\|notification"
```

### Luego (para hacer una prueba real):
**→ Usa MÉTODO A (Firebase Console)** - 5 minutos

- Obtén el token de MÉTODO B
- Envía desde Firebase Console
- Verifica que la notificación aparece

### Finalmente (si quieres debugging avanzado):
**→ Usa MÉTODO C (DevTools)** - 10 minutos

---

## 📝 LISTA DE VERIFICACIÓN

```
🔍 VERIFICAR QUE FCM FUNCIONA:

Paso 1: Obtener Token
  ☐ flutter run
  ☐ flutter logs
  ☐ Ver línea: "🔔 FCM Token: ..."
  ☐ Copiar token

Paso 2: Enviar Notificación
  ☐ https://console.firebase.google.com/
  ☐ Cloud Messaging → Nuevo mensaje
  ☐ Título: "🚨 PRUEBA"
  ☐ Cuerpo: "Hola mundo"
  ☐ Seleccionar "Dispositivos específicos"
  ☐ Pegar token
  ☐ Publicar

Paso 3: Verificar Recepción
  ☐ App abierta → Ver SnackBar rojo
  ☐ App minimizada → Ver notificación en barra
  ☐ App cerrada → Notificación persiste
  ☐ Logs: "📬 Notificación recibida"

✅ TODO FUNCIONA
```

---

## 🆘 SI ALGO FALLA

### No veo el token FCM
```
Solución:
1. Verifica main.dart tiene NotificationService.instance().initialize()
2. Revisa que firebase_messaging está en pubspec.yaml
3. Ejecuta: flutter pub get
4. Limpia caché: flutter clean
5. Recompila: flutter run
```

### Envío notificación pero NO la recibo
```
Solución:
1. ¿Copiaste el token correctamente? (sin espacios en blanco)
2. ¿Es el mismo dispositivo/emulador?
3. ¿Tienes permisos de notificaciones? (Android 13+)
   → Configuración → Apps → Tu app → Permisos → Notificaciones: ON
4. Reinicia la app: flutter run
```

### Veo notificación en background pero NO en foreground
```
Solución:
1. Verifica main.dart:
   return MaterialApp(
     navigatorKey: NotificationService.navigatorKey,  // ✅ DEBE ESTAR
     ...
   );
2. Reinicia: flutter run
3. Revisa logs para errores
```

### La notificación NO navega a OptionPage
```
Solución:
1. Verifica que _navigateToAlert está en NotificationService
2. Verifica que navigatorKey está asignado
3. Agrega prints en _navigateToAlert para debugging
4. Revisa logs
```

---

## 📊 MATRIZ DE PRUEBAS

| Escenario | Qué hacer | Resultado esperado | Verificar |
|-----------|-----------|-------------------|-----------|
| **App ABIERTA** | Enviar notificación | SnackBar rojo | Logs: "📬 Notificación en foreground" |
| **App MINIMIZADA** | Enviar notificación | Notificación en barra | Logs: "📭 Notificación en background" |
| **App CERRADA** | Enviar notificación | Notificación en barra | Toca → app se abre |
| **Click notificación (abierta)** | Hacer clic "Ver" | Navega a OptionPage | Ver pantalla de alertas |
| **Click notificación (cerrada)** | Hacer clic notificación | App se abre + navega | Ver OptionPage automáticamente |

---

## 🚀 PRÓXIMO PASO

Una vez que confirmes que las notificaciones funcionan:

**¿Continuamos con Fase 5 (Optimización)?**
