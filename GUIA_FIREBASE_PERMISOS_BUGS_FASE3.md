# 🔒 Guía - Resolver "Permission denied" en Firebase (Fase 3 - Testing)

**Fecha:** 30 de julio de 2026  
**Estado:** Crítico - Bloquea actualización de alertas  
**Error:** `DatabaseError: Permission denied`

---

## ❌ Problema

Cuando intentas actualizar campos en **Options** o **Settings** (Perfil del paciente), obtienes:

```
W/RepoOperation(20264): updateChildren at /users/1756278551/alerts/1756278551_mod13 failed: 
DatabaseError: Permission denied

I/flutter: [AlertService.updateAlert] ERROR: [firebase_database/unknown] 
Firebase Database error: Permission denied
```

### Causa
Las **Reglas de Seguridad de Firebase Realtime Database** están bloqueando la escritura en `/users/{CI}/alerts/`.

Necesitas actualizar las reglas en **Firebase Console**.

---

## ✅ Solución - 5 Pasos

### **PASO 1: Acceder a Firebase Console**

1. Abre: https://console.firebase.google.com
2. **Selecciona tu proyecto:** `flutter_application_1`
3. En el menú lateral, ve a: **Build** → **Realtime Database**
4. Haz clic en la pestaña: **Reglas** (junto a Datos)

---

### **PASO 2: Reemplazar Reglas Actuales**

Verás algo como esto:

```json
{
  "rules": {
    ".read": false,
    ".write": false
  }
}
```

**Borra TODO** y reemplaza con estas reglas **PARA DESARROLLO** (permiten acceso público):

```json
{
  "rules": {
    "users": {
      "$uid": {
        "alerts": {
          "$alertId": {
            ".read": true,
            ".write": true,
            ".validate": "newData.hasChildren(['userId', 'timestamp', 'status'])"
          }
        },
        ".read": true,
        ".write": true
      }
    }
  }
}
```

---

### **PASO 3: Publicar Reglas**

1. Haz clic en el botón **Publicar** (esquina inferior derecha)
2. Confirma en el popup que aparece
3. Espera a que aparezca: ✓ **Reglas publicadas exitosamente**

---

### **PASO 4: Verificar en la App**

Vuelve a tu app Flutter y prueba:

1. Abre la página de **Ajustes** (Perfil)
2. Edita cualquier campo (nombre, edad, etc.)
3. Guarda los cambios

Debería funcionar sin errores de permisos.

---

### **PASO 5: Para PRODUCCIÓN (Opcional - Más Adelante)**

Cuando vayas a producción, cambia las reglas para requerir autenticación:

```json
{
  "rules": {
    "users": {
      "$uid": {
        "alerts": {
          "$alertId": {
            ".read": "$uid === auth.uid",
            ".write": "$uid === auth.uid && newData.hasChildren(['userId', 'timestamp', 'status'])",
            ".validate": "newData.hasChildren(['userId', 'timestamp', 'status'])"
          }
        },
        ".read": "$uid === auth.uid",
        ".write": "$uid === auth.uid"
      }
    }
  }
}
```

---

## 🔍 Estructura de Datos Esperada

Las alertas se guardan en:

```
firebase-database-root/
└── users/
    └── {CI}/ (ejemplo: 1756278550)
        └── alerts/
            ├── 1756278550_mod1/
            │   ├── id: string
            │   ├── userId: string
            │   ├── timestamp: number
            │   ├── status: string
            │   ├── latitude_encrypted: string
            │   └── paciente: object { nombres, apellidos, edad, etc. }
            │
            ├── 1756278550_mod2/
            └── 1756278550_mod3/
```

---

## 🧪 Testing

Después de actualizar las reglas, prueba:

### ✓ Debe funcionar:
- [x] Crear nueva alerta desde botón de pánico
- [x] Actualizar campos en Ajustes (perfil)
- [x] Ver historial de alertas en Opciones
- [x] Editar condiciones médicas
- [x] Editar medicamentos
- [x] Editar citas médicas

### ✗ No debe funcionar (de momento):
- Eliminar alertas (sin implementar todavía)
- Acceso desde otro dispositivo (sin autenticación)

---

## 📋 Checklist Rápido

- [ ] Accedí a Firebase Console
- [ ] Seleccioné el proyecto `flutter_application_1`
- [ ] Fui a Realtime Database → Reglas
- [ ] Reemplacé todas las reglas con las nuevas
- [ ] Publiqué las reglas
- [ ] Espéré confirmación: "✓ Reglas publicadas exitosamente"
- [ ] Probé la app y los errores de permisos desaparecieron

---

## 🐛 Si Persisten los Errores

1. **Limpia caché de Firebase Console:**
   - Presiona `F5` o recarga la página
   
2. **Verifica que las reglas se guardaron:**
   - Abre Firebase Console nuevamente
   - Ve a Realtime Database → Reglas
   - Confirma que ves las reglas nuevas

3. **Reinicia la app Flutter:**
   - Cierra completamente la app
   - Ejecuta: `flutter clean`
   - Ejecuta: `flutter run`

4. **Verifica el estructura de datos:**
   - En Firebase Console, ve a **Realtime Database → Datos**
   - Confirma que existe: `/users/{tu_CI}/alerts/{alertId}`
   - Si no existe, crea una alerta manualmente desde la app

---

## 📞 Contacto / Soporte

Si sigue sin funcionar:
1. Verifica que el `CI` guardado en la app coincida con la estructura en Firebase
2. Abre la consola de Firebase y busca en Realtime Database
3. Revisa los logs de Flutter: `flutter logs`

**Documento relacionado:** `FIREBASE_RULES_SEGURIDAD.md`
