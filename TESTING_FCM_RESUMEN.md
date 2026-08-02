# 📱 RESUMEN: Cómo Comprobar Notificaciones FCM

## En 30 Segundos 🚀

```
1. flutter run          → App inicia
2. flutter logs         → Ver token FCM
3. Copiar token         → aeB_c2Wh8vk_...
4. Firebase Console     → Cloud Messaging
5. Enviar notificación  → Con tu token
6. ✅ Ver en la app     → SnackBar o notificación
```

---

## Diagrama del Flujo

```
┌──────────────────┐
│  flutter run     │  ← Inicia tu app
└────────┬─────────┘
         │
         ↓
┌──────────────────────────────────┐
│   flutter logs (otra terminal)   │  ← Ve los logs
└────────┬─────────────────────────┘
         │
         ↓
    🔔 FCM Token: aeB_c2Wh8vk_...  ← COPIA ESTO
         │
         ↓
┌──────────────────────────────────┐
│  https://console.firebase.google │  ← Abre navegador
└────────┬─────────────────────────┘
         │
         ↓
┌──────────────────────────────────┐
│  Cloud Messaging → New Message   │  ← Cloud Messaging
└────────┬─────────────────────────┘
         │
         ↓
    ┌─────────────────────┐
    │ Título: 🚨 PRUEBA   │
    │ Body: Test          │
    │ Token: [PEGA AQUÍ]  │  ← PEGA TU TOKEN
    └─────────────────────┘
         │
         ↓
    [Publish/Publicar]  ← CLICK
         │
         ↓
    ┌────────────────────────────────┐
    │  ✅ NOTIFICACIÓN RECIBIDA      │
    │                                │
    │  Si app ABIERTA:               │
    │  → SnackBar rojo               │
    │                                │
    │  Si app CERRADA:               │
    │  → Notificación del sistema    │
    └────────────────────────────────┘
```

---

## Los 3 Pasos Clave

### ✅ PASO 1: Obtener Token
```bash
Terminal 1: flutter run
Terminal 2: flutter logs | grep "FCM Token"

Resultado:
🔔 FCM Token: aeB_c2Wh8vk_AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoP

ACTION: Copiar este token
```

### ✅ PASO 2: Enviar desde Firebase
```
1. https://console.firebase.google.com/
2. Tu proyecto
3. Cloud Messaging → Nuevo Mensaje
4. Llenar:
   - Título: Cualquier cosa
   - Body: Tu mensaje
5. Dispositivos específicos → Pegar token
6. Publicar
```

### ✅ PASO 3: Verificar en la App
```
Resultado esperado:

SI APP ABIERTA:
┌──────────────────────┐
│ 🚨 Título            │
│ Tu mensaje...        │
│         [Ver]        │
└──────────────────────┘
(SnackBar rojo)

SI APP MINIMIZADA/CERRADA:
Notificación en la barra del sistema
```

---

## Comparativa Rápida

| Aspecto | Foreground | Background | Terminada |
|---------|-----------|-----------|-----------|
| **App Estado** | 🟢 Abierta | 🟡 Minimizada | 🔴 Cerrada |
| **Qué ves** | SnackBar | Notificación | Notificación |
| **Dónde** | En pantalla | Barra del sistema | Barra del sistema |
| **Automático** | No | Sí | Sí |
| **Al tocar** | Botón "Ver" | Se abre app | Se abre app |

---

## Verificación Rápida en Logs

```bash
# Ver solo notificaciones
flutter logs | grep -E "FCM|notification|📬|📭"

# Resultado esperado:
🔔 FCM Token: aeB_c2Wh8vk_...
📬 Notificación en foreground recibida
Título: Tu Título
Body: Tu cuerpo
```

---

## Soluciones Si NO Funciona

### No veo el token
```
flutter clean && flutter pub get && flutter run
```

### No recibo notificación
```
1. ¿Token copiado correctamente? (sin espacios)
2. ¿Es el mismo dispositivo?
3. ¿Permisos de notificaciones activados?
   Android: Configuración → Apps → Tu app → Permisos
```

### Veo notificación pero no en foreground
```
main.dart debe tener:
  MaterialApp(
    navigatorKey: NotificationService.navigatorKey,
    ...
  )
```

---

## Archivos de Ayuda en el Proyecto

| Archivo | Propósito | Detalle |
|---------|-----------|--------|
| `TESTING_FCM_RAPIDO.md` | Guía rápida visual | 5 minutos |
| `TESTING_NOTIFICACIONES_FCM.md` | Guía completa | Todos los detalles |
| `TESTING_FCM_METODOS.md` | Comparativa de métodos | Elige tu método |
| `ASISTENTE_NOTIFICACIONES.md` | Asistente interactivo | Preguntas y respuestas |
| `CODIGO_TEMPORAL_OBTENER_TOKEN.dart` | Código para copiar | Copiar y pegar |

---

## Estado Actual

```
✅ FCM Instalado y Configurado
✅ NotificationService Creado
✅ ContactService Creado
✅ AlertService.notifyContacts() Integrado
✅ Permisos Agregados (Android)
✅ APK Compilando Exitosamente

⏳ Próximo: Pruebas de Notificaciones
```

---

## Resumen Final

```
ANTES DE CONTINUAR CON FASE 5 (OPTIMIZACIÓN):

☐ Verificar que el token FCM aparece en logs
☐ Enviar notificación de prueba desde Firebase
☐ Confirmar que se recibe en foreground
☐ Confirmar que se recibe en background
☐ Confirmar que se recibe con app cerrada

Si TODO ✅ FUNCIONA:
   → Continuar con Fase 5: Optimización

Si ALGO ❌ FALLA:
   → Usar guías de solución de problemas
   → Preguntar en el chat
```

---

## 🎯 ¿ESTÁS LISTO?

**Ejecuta esto AHORA:**

```bash
# Terminal 1
flutter run

# Terminal 2 (después de 5 segundos)
flutter logs | grep "FCM Token"
```

**Si ves el token → ¡Perfecto! Ya puedes probar.**

¿Lo conseguiste? 🚀
