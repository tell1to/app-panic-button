# 🤖 Asistente Interactivo: ¿Cómo Comprobar Notificaciones?

## 📋 FLUJO RÁPIDO PASO A PASO

### START
```
┌─────────────────────────────────────┐
│  ¿Quieres comprobar notificaciones? │
│             SÍ / NO                 │
└─────────────────────────────────────┘
```

---

## OPCIÓN 1: Verificación Rápida (3 min)

### Pregunta 1: ¿Tienes una terminal abierta?
```
SÍ → Ve a paso 2
NO → Abre VS Code Terminal (Ctrl + `) → Ve a paso 2
```

### Paso 2: Ejecutar la app
```bash
flutter run
```

**Espera a ver:**
```
[main] Firebase inicializado correctamente
[main] NotificationService inicializado correctamente
🔔 FCM Token: aeB_c2Wh8vk_...
```

**✅ Hecho:** Ya tienes el token FCM

---

## OPCIÓN 2: Prueba Real (5 min)

### Tienes el token → Ir a Firebase Console

**Paso 1: Abrir Firebase**
```
https://console.firebase.google.com/
```

**Paso 2: Encontrar Cloud Messaging**
```
Tu Proyecto → Cloud Messaging → Enviar Mensaje
```

**Paso 3: Llenar Formulario**
```
Título:       🚨 PRUEBA
Descripción:  Test de notificaciones FCM
Imagen:       (dejar en blanco)
```

**Paso 4: Seleccionar Dispositivo**
```
☐ Aplicación específica
☐ Tópico
✅ Dispositivos específicos

Token: [PEGA TU TOKEN AQUÍ]
```

**Paso 5: Publicar**
```
Click "Publicar" y espera 3 segundos
```

### Resultado Esperado:

**Si la app está ABIERTA:**
```
┌─────────────────────────────────────┐
│  SnackBar flotante rojo con el      │
│  título "🚨 PRUEBA"                 │
│          [Ver]                      │
└─────────────────────────────────────┘
```

**Si la app está MINIMIZADA o CERRADA:**
```
Notificación en la barra del sistema
```

---

## 🔍 VERIFICACIÓN EN LOGS

Abre una **NUEVA TERMINAL** y ejecuta:

```bash
flutter logs
```

Busca estas líneas:

```
✅ Al iniciar:
[I] 🔔 FCM Token: aeB_c2Wh8vk_AaBbCcDd...

✅ Al recibir notificación (app abierta):
[I] 📬 Notificación en foreground recibida:
[I] Título: 🚨 PRUEBA
[I] Body: Test de notificaciones FCM

✅ Al recibir notificación (app cerrada):
[I] 📭 Notificación desde background/terminated:
[I] Título: 🚨 PRUEBA
```

---

## ❓ PREGUNTAS FRECUENTES

### P: ¿Dónde veo mi token FCM?
**R:** Ejecuta `flutter run` y luego `flutter logs`. Busca "FCM Token".

### P: ¿Puedo enviar notificaciones sin Firebase Console?
**R:** Sí, necesitarías un backend con Firebase Admin SDK, pero para pruebas Firebase Console es lo más fácil.

### P: ¿El token cambia cada vez que ejecuto la app?
**R:** No, generalmente es el mismo. Si cambia, es porque reiniciaste Firebase.

### P: ¿Qué significa que no vea notificación en foreground?
**R:** Probablemente navigatorKey no está asignado en MaterialApp.

### P: ¿Mi dispositivo puede recibir notificaciones desde otro dispositivo?
**R:** Sí, si tienes su token FCM y usas Firebase Admin SDK o Cloud Functions.

### P: ¿Las notificaciones llegan si cierro la app?
**R:** Sí, Firebase las almacena y las entrega cuando el dispositivo se conecta.

---

## 🎯 CHECKLIST DE ÉXITO

```
Verificación Básica:
  ☐ Veo el token FCM en los logs
  ☐ Puedo copiar el token sin espacios en blanco

Prueba Foreground:
  ☐ Abro Firebase Console
  ☐ Envío notificación con mi token
  ☐ La app está abierta
  ☐ Veo SnackBar rojo con la notificación
  ☐ El SnackBar desaparece en 5 segundos
  ☐ En los logs veo: "📬 Notificación en foreground recibida"

Prueba Background:
  ☐ Minimizo la app (botón Home)
  ☐ Envío otra notificación desde Firebase
  ☐ Veo notificación en la barra del sistema
  ☐ En los logs veo: "📭 Notificación desde background/terminated"

Prueba Terminada:
  ☐ Cierro la app completamente
  ☐ Envío notificación desde Firebase
  ☐ Veo notificación en barra
  ☐ Hago clic en la notificación
  ☐ La app se abre automáticamente
  ☐ Se abre en OptionPage (pantalla de alertas)

✅ TODAS LAS PRUEBAS PASAN
```

---

## 🚨 SOLUCIONES RÁPIDAS

### ❌ "No veo el token FCM"
```
1. Ejecuta: flutter clean
2. Ejecuta: flutter pub get
3. Ejecuta: flutter run
4. Abre logs: flutter logs
5. Busca: "FCM Token"
```

### ❌ "Envío notificación pero no aparece"
```
1. Verifica que copiaste el token CORRECTAMENTE
   (sin espacios, caracteres especiales, etc)
2. Verifica que el token está en Firebase Console
3. Verifica que la app tiene permisos de notificaciones
4. Reinicia la app
5. Intenta de nuevo
```

### ❌ "Veo notificación en background pero NO en foreground"
```
1. Abre main.dart
2. Busca: MaterialApp(
3. Verifica que tiene: navigatorKey: NotificationService.navigatorKey,
4. Si no está, agrégalo
5. Ejecuta: flutter run
```

### ❌ "La notificación no navega a OptionPage"
```
1. Toca la notificación cuando la app está CERRADA
2. La app debería abrirse
3. Debería ir a OptionPage automáticamente
4. Si no va, revisa los logs para errores
```

---

## 📞 PRÓXIMOS PASOS

### ✅ Si las notificaciones funcionan:
1. **Fase 5: Optimización** - Mejorar rendimiento
2. **Fase 4: Testing** - Agregar tests
3. Implementar envío de notificaciones REALES a contactos

### ❌ Si las notificaciones NO funcionan:
1. Revisa los logs cuidadosamente
2. Usa esta guía para solucionar problemas
3. Si persiste el error, documenta el problema y avísame

---

## 🎓 RECURSOS ADICIONALES

Ver estos archivos en el proyecto:

- `TESTING_NOTIFICACIONES_FCM.md` - Guía detallada (⭐⭐⭐)
- `TESTING_FCM_RAPIDO.md` - Guía corta (⭐⭐)
- `TESTING_FCM_METODOS.md` - Comparativa de métodos (⭐⭐⭐)
- `CODIGO_TEMPORAL_OBTENER_TOKEN.dart` - Código para copiar

---

## ✨ ¡AHORA SÍ!

**Estás listo para probar notificaciones. ¿Necesitas ayuda con algo específico?**

Escribe en el chat:
- "No veo el token"
- "No me llega la notificación"
- "La notificación aparece pero..."
- Cualquier otra pregunta
