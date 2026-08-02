# Firebase Setup & Configuration - 2026

## � CONFIGURACIÓN RÁPIDA (5 minutos)

### PASO 1: Crear/Verificar Realtime Database

1. Ve a: https://console.firebase.google.com/
2. Selecciona tu proyecto
3. En el menú izquierdo → **Build > Realtime Database**
4. Si NO existe una base de datos:
   - Click **"Create Database"**
   - Región: **Sudamérica (South America)** 
   - Seguridad: **Test mode** (por ahora)
   - Click **Create**

### PASO 2: Configurar Reglas (⚡ MÁS IMPORTANTE)

1. En **Realtime Database** → pestaña **"Rules"**
2. **BORRA TODO LO QUE HAYA**
3. Copia y pega EXACTAMENTE esto:

```json
{
  "rules": {
    ".read": true,
    ".write": true
  }
}
```

4. Click **"Publish"** (IMPORTANTE: está abajo a la derecha)
5. Espera 1-2 segundos. Verás: **"Rules updated"**

✅ **Hecho.** Firebase ya debería funcionar.

---

## 🧪 Verificación en la App

1. En terminal:
```bash
cd c:\Users\MateoM\Desktop\Proyecto-app\flutter_application_1
flutter clean
flutter pub get
flutter run
```

2. Activa una emergencia en la app

3. Revisa los LOGS - deberías ver:
```
========================================
GUARDANDO ALERTA DE EMERGENCIA
UserId: user_default
AlertId: -Nu12345xyz
========================================
✓ ÉXITO: Alerta guardada en Firebase
✓ Alerta guardada en almacenamiento local
========================================
ALERTA COMPLETADA
```

Si ves esto → **¡Firebase está funcionando!** 🎉

---

## ⚠️ Troubleshooting

### Error: "Permission denied"
→ Verifica que publicaste las reglas (Publish button)
→ Espera 2 segundos después de publicar
→ Recarga la app (`flutter run` nuevamente)

### Error: "Cannot reach Firebase" o Timeout
→ Verifica tu conexión a internet
→ En Firebase Console > Realtime Database, verifica que la URL existe
→ La URL debe ser: `https://[TU-PROYECTO]-default-rtdb.firebaseio.com`

### La app funciona pero sin Firebase
→ Las alertas SE GUARDAN LOCALMENTE automáticamente
→ Están en: `/storage/emulated/0/Documents/alerts/`
→ Y en SharedPreferences

---

## 🔐 Para PRODUCCIÓN (Después)

Las reglas actuales permiten que cualquiera lea/escriba. Para seguridad real:

```json
{
  "rules": {
    "alerts": {
      "$uid": {
        ".read": "$uid === auth.uid",
        ".write": "$uid === auth.uid",
        "$alertId": {
          ".validate": "newData.hasChildren(['id', 'userId', 'timestamp', 'status'])"
        }
      }
    }
  }
}
```

Y necesitarías habilitar "Anonymous Auth" en Firebase Console.

---

## 📱 Cómo Verificar que Funciona

### Opción 1: Revisar Logs en la App
```
[AlertService.createAlert] ========================================
[AlertService.createAlert] GUARDANDO ALERTA DE EMERGENCIA
[AlertService.createAlert] UserId: user_default
[AlertService.createAlert] AlertId: -Nu12345xyz
[AlertService.createAlert] ✓ ÉXITO: Alerta guardada en Firebase
```

### Opción 2: Revisar en Firebase Console
1. Va a **Realtime Database**
2. Deberías ver la estructura:
```
alerts/
  └── user_default/
      └── -Nu12345xyz/
          ├── id: "-Nu12345xyz"
          ├── userId: "user_default"
          ├── timestamp: 1782245553451
          ├── status: "active"
          └── ...
```

---

## 📚 Archivos Modificados

| Archivo | Cambio |
|---------|--------|
| `alert_service.dart` | Reintentos automáticos, mejor diagnóstico |
| `firebase_service.dart` | Logs más claros en la inicialización |
| Este archivo | Instrucciones simplificadas |

---

## ✅ Checklist Final

- [ ] Realtime Database creada en Firebase Console
- [ ] Reglas publicadas ({"read": true, "write": true})
- [ ] Ejecutado `flutter clean && flutter pub get`
- [ ] App compilada con `flutter run`
- [ ] Activada una emergencia en la app
- [ ] Verificado los logs: "✓ ÉXITO: Alerta guardada"
- [ ] (Opcional) Verificado en Firebase Console > Realtime Database

---

## 🆘 ¿Necesitas Ayuda?

Si no ves los logs de éxito, revisa en ESTE ORDEN:
1. ¿Las reglas se publicaron? (Actualiza la página si no estás seguro)
2. ¿La Realtime Database existe? (Crea una si no la ves)
3. ¿Hay conexión a internet en el emulador/dispositivo?
4. Revisa los logs exactos en la consola de Flutter
