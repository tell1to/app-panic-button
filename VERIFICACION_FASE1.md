# ✅ Verificación de Fase 1 - Seguridad

## 📋 QUÉ HAY EN LAS REGLAS (Explicación detallada)

Las reglas de Firebase definen **quién puede leer/escribir** y **qué datos son válidos**.

### 🔐 **Validación del CI (Cédula)**
```json
".validate": "$ci.matches(/^[0-9]+$/) && $ci.length >= 7",
```
- `$ci.matches(/^[0-9]+$/)` = El CI debe ser SOLO números (ej: 1756278550)
- `$ci.length >= 7` = Mínimo 7 dígitos
- **Si falla:** No se puede crear un usuario con CI "ABC" o "123"

### 👁️ **Permiso de lectura**
```json
".read": true,
```
- Cualquiera puede LEER cualquier dato en `users/`
- ⚠️ **Importante:** Esto es abierto (lo cambiaremos en Fase 2)

### ✍️ **Permiso de escritura**
```json
".write": "!root.child('users').child($ci).exists() || root.child('users').child($ci).child('profile').child('ci').val() === $ci"
```

**Traducido:**
- Permite escribir SI:
  - `!root.child('users').child($ci).exists()` = Usuario NO existe aún (primera vez, puede crear su CI)
  - **O**
  - `root.child('users').child($ci).child('profile').child('ci').val() === $ci` = Ya existe y el CI coincide (puede actualizar sus propios datos)

**En otras palabras:** Solo el usuario con su CI puede escribir en `users/{SU_CI}/`

### 👤 **Validación del profile**
```json
"profile": {
  ".validate": "newData.hasChildren(['ci'])",
  "ci": { ".validate": "newData.isString() && newData.val() === $ci" }
}
```

- `newData.hasChildren(['ci'])` = El profile DEBE tener un campo `ci`
- `newData.isString() && newData.val() === $ci` = El `ci` debe ser string y coincidir con el usuario

### 🚨 **Validación de alertas**
```json
"alerts": {
  "$alertId": {
    ".validate": "newData.hasChildren(['timestamp', 'status', 'description', 'userId'])"
```

**Campos obligatorios:**
- ✅ `timestamp` - Momento de la alerta (número)
- ✅ `status` - Estado: "active", "resolved", o "false_alarm"
- ✅ `description` - Descripción de la alerta (string)
- ✅ `userId` - Debe coincidir con el CI del usuario

### 🔢 **Tipos de datos validados**

| Campo | Validación | Ejemplo |
|-------|-----------|---------|
| `id` | String | "-QwqRwT11M6d7Uq..." |
| `userId` | Debe = $ci | "1756278550" |
| `timestamp` | Número > 0 | 1782251243411 |
| `date` | String | "23 de Junio de 2026" |
| `time` | String | "16:47:23" |
| `latitude_encrypted` | String base64 | "ZW5jcnlwdGVkX2Jhc2U2NCE=" |
| `longitude_encrypted` | String base64 | "ZW5jcnlwdGVkX2Jhc2U2NCE=" |
| `numberCalled_encrypted` | String base64 | "ZW5jcnlwdGVkX2Jhc2U2NCE=" |
| `status` | Una de: active/resolved/false_alarm | "active" |
| `contactsNotified` | Array (vacío o con datos) | [] |
| `description` | String | "Alerta..." |

---

## ✅ CÓMO COMPROBAR QUE FUNCIONA

### **TEST 1: Verificar que se escriben correctamente**

1. **Abre la app:**
   ```powershell
   flutter run
   ```

2. **Activa una emergencia** (presiona botón de pánico)

3. **Ve a Firebase Console:**
   - https://console.firebase.google.com/
   - Tu proyecto → Realtime Database
   - Deberías ver:
   ```
   users/
   └── {TU_CI}/
       └── alerts/
           └── {alertId}/
               ├── latitude_encrypted: "..."
               ├── longitude_encrypted: "..."
               ├── numberCalled_encrypted: "..."
               ├── timestamp: 1782251243411
               └── status: "active"
   ```

### **TEST 2: Verificar que la encriptación funciona**

1. **En Firebase Console:**
   - Haz clic en `latitude_encrypted`
   - **Debe ser un string base64** (ej: `ZW5jcnlwdGVkX2Jhc2U2NCE=`)
   - **NO debe verse una ubicación legible** (ej: `-23.891783`)

2. **En los logs de la app:**
   ```
   [AlertService.createAlert] ✓ Guardada en Firebase
   [EncryptionService.encrypt] Encriptado: -23.891783
   ```

### **TEST 3: Verificar que la validación funciona**

**Intenta hacer esto desde Firebase Console (Data tab):**

1. **Crea un alert SIN el campo "timestamp":**
   - Click derecho en `/users/{TU_CI}/alerts/`
   - Añadir hijo (child) 
   - Nombre: `test_alert`
   - Valor: `{"status": "active", "description": "test"}`
   - **Debe RECHAZARSE** ❌ Error: "No se pudieron escribir los datos"

2. **Crea un alert CON todos los campos:**
   - Valor: 
   ```json
   {
     "timestamp": 1782251243411,
     "status": "active", 
     "description": "test",
     "userId": "{TU_CI}"
   }
   ```
   - **Debe ACEPTARSE** ✅ Se guarda correctamente

### **TEST 4: Verificar sincronización offline**

1. **Con internet conectada:**
   - Activa una emergencia
   - Verifica que se guarde en Firebase ✅

2. **Sin internet:**
   - Desactiva WiFi + datos móviles
   - Activa otra emergencia
   - Verifica que se guarde **localmente** ✅
   - Logs deberían mostrar: `⚠️  FIREBASE NO DISPONIBLE - Usando almacenamiento local`

3. **Reactiva internet:**
   - Logs deberían mostrar: `[AlertService.syncLocalAlerts] Sincronización completada`
   - Verifica en Firebase que ahora están ambas alertas ✅

### **TEST 5: Verificar que otros usuarios no pueden ver tus datos**

1. **Desde la consola de Firebase (Rules tab):**
   - Haz clic en "Simulate" (ícono de play)
   - Authentication: Dejar vacío
   - Location: `users/1756278550/alerts`
   - Operation: Read
   - Click "Run"
   - **Resultado esperado:** ✅ Permitido (porque `.read": true`)

2. **Intenta leer datos de otro usuario:**
   - Location: `users/9999999999/alerts`
   - **Resultado esperado:** ✅ Permitido (porque `.read": true`)
   - 🟠 **Nota:** En Fase 2 esto cambiará a "solo tu CI puede leer"

---

## 📊 CHECKLIST DE VERIFICACIÓN

- [ ] Las alertas se guardan en `users/{CI}/alerts/`
- [ ] `latitude_encrypted` y `longitude_encrypted` son strings base64
- [ ] Las alertas se guardan localmente cuando no hay internet
- [ ] Se sincronizan automáticamente cuando recuperas conexión
- [ ] No puedes crear alertas sin `timestamp`, `status`, `description`, `userId`
- [ ] Solo números en el CI
- [ ] Minimum 7 dígitos en el CI

---

## 📌 PRÓXIMOS PASOS

Una vez que todos los tests pasen:

1. **FASE 2:** Mejorar sincronización offline
   - Reintentos exponenciales
   - Rate limiting

2. **FASE 3:** Restricción de lectura por CI
   - Solo tu CI puede leer tus alertas
   - Otros usuarios NO pueden ver tus datos

3. **FASE 4:** Optimización de performance
   - Batch writes
   - Caching local
