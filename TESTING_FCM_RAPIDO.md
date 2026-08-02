# 🔍 GUÍA RÁPIDA: Comprobar Notificaciones en 5 Minutos

## PASO 1️⃣: Obtener tu Token FCM (2 minutos)

### Opción más rápida: Ver los logs

1. **Conecta tu dispositivo o abre un emulador**
   ```bash
   # Si usas emulador, primero inicia Flutter
   flutter run
   ```

2. **Abre una terminal en VS Code** y ejecuta:
   ```bash
   flutter logs
   ```

3. **Verás algo como esto:**
   ```
   [main] Firebase inicializado correctamente
   [main] NotificationService inicializado correctamente
   🔔 FCM Token: aeB_c2Wh8vk_AaBbCcDdEeFfGgHhIi...
   ```

4. **Copia el token** (desde "aeB_" hasta el final)

---

## PASO 2️⃣: Ir a Firebase Console (1 minuto)

1. Abre tu navegador: https://console.firebase.google.com/
2. Selecciona tu proyecto (flutter_application_1)
3. En el menú de la izquierda, busca **"Cloud Messaging"** 
4. Haz clic en **"Enviar tu primer mensaje"** o **"Nuevo mensaje"**

```
Firebase Console:
┌─────────────────────────────────────────┐
│ flutter_application_1 project           │
├─────────────────────────────────────────┤
│ Build                                   │
│ Release                                 │
│ Engage                                  │
│ ├─ Cloud Messaging ◄─ AQUÍ              │
│ Analytics                               │
│ Crash Reporting                         │
│ ...                                     │
└─────────────────────────────────────────┘
```

---

## PASO 3️⃣: Crear Notificación de Prueba (1 minuto)

### Llenar el formulario:

```
TÍTULO (Title):
🚨 ALERTA DE PRUEBA

CUERPO (Body):
Esta es una notificación de prueba desde Firebase

IMAGEN (Image):
[DEJAR EN BLANCO]
```

**Haz clic en "Siguiente" →**

---

## PASO 4️⃣: Seleccionar Destino (1 minuto)

### Selecciona:
1. **"Dispositivos específicos"**
2. En el campo de Token, **pega el token FCM que copiaste en PASO 1**
3. Haz clic en **"Revisar"**

```
┌──────────────────────────────────────┐
│ Selecciona destino                   │
├──────────────────────────────────────┤
│ ☐ Aplicación específica              │
│ ◉ Dispositivos específicos           │ ◄─ SELECCIONA ESTO
│ ☐ Tópico                            │
│                                      │
│ Token del dispositivo:               │
│ ┌────────────────────────────────┐   │
│ │ aeB_c2Wh8vk_AaBbCcDd...       │   │ ◄─ PEGA AQUÍ
│ └────────────────────────────────┘   │
│                                      │
│           [Revisar]                  │
└──────────────────────────────────────┘
```

---

## PASO 5️⃣: Enviar Notificación (30 segundos)

Haz clic en **"Publicar"** y espera confirmación.

---

## 📱 ¿QUÉ DEBERÍAS VER?

### Si la app está ABIERTA:
```
╔════════════════════════════════════════╗
║                                        ║
║  ┌──────────────────────────────────┐  ║
║  │ 🚨 ALERTA DE PRUEBA              │  ║
║  │ Esta es una notificación...       │  ║
║  │              [Ver]               │  ║
║  └──────────────────────────────────┘  ║
║                                        ║
║  (SnackBar flotante rojo)              ║
║                                        ║
╚════════════════════════════════════════╝
```

### Si la app está MINIMIZADA:
```
📲 Barra de notificaciones del sistema:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🚨 ALERTA DE PRUEBA
Esta es una notificación de prueba...
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Si la app está CERRADA:
```
Igual que arriba. Al tocar la notificación,
la app se abre automáticamente.
```

---

## ✅ VERIFICAR EN LOGS

Ejecuta en terminal:
```bash
flutter logs | grep -i "fcm\|notification"
```

Deberías ver:
```
[I] 🔔 FCM Token: aeB_c2Wh8vk_...
[I] 📬 Notificación en foreground recibida:
[I] Título: 🚨 ALERTA DE PRUEBA
[I] Body: Esta es una notificación de prueba...
```

---

## ❌ SOLUCIONES RÁPIDAS

### "No veo el token FCM"
```
✓ Ejecuta: flutter run
✓ Ejecuta: flutter logs
✓ Busca: "FCM Token"
✓ Si no aparece, reinicia la app
```

### "Envío la notificación pero no la recibo"
```
✓ ¿Copiaste el token correctamente? (sin espacios)
✓ ¿La app está cerrada completamente? (en background al menos)
✓ ¿Tienes permisos de notificaciones activados?
  → Android: Configuración → Apps → Tu app → Permisos → Notificaciones ON
```

### "Veo la notificación en background pero no en foreground"
```
✓ Verifica que NotificationService.navigatorKey está en main.dart
✓ Reinicia la app: flutter run
✓ Revisa los logs para errores
```

---

## 📋 RESUMEN FINAL

| Paso | Acción | Resultado |
|------|--------|-----------|
| 1 | Ejecutar `flutter run` + `flutter logs` | Ver token FCM |
| 2 | Ir a Firebase Console | Acceder a Cloud Messaging |
| 3 | Llenar formulario de notificación | Crear mensaje |
| 4 | Pegar token + seleccionar dispositivo | Configurar destino |
| 5 | Hacer clic en "Publicar" | Enviar notificación |
| 6 | Revisar en la app | ✅ Notificación recibida |

---

## 🎯 PRÓXIMOS PASOS CUANDO FUNCIONE

Una vez que veas la notificación en la app:

1. ✅ **Foreground funciona** → SnackBar rojo aparece
2. ✅ **Background funciona** → Notificación del sistema
3. ✅ **Terminada funciona** → Se abre automáticamente

Luego puedes:
- Ir a **Fase 5: Optimización**
- Ir a **Fase 4: Testing**
- Implementar **integración real con contactos**

---

## 🚀 ¡LISTO! Ahora prueba las notificaciones.

¿Consigues ver la notificación? ✨
