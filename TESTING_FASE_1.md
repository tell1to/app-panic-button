# 🧪 Testing Manual - Fase 1

## Pruebas que puedes realizar para verificar la implementación

---

## 1️⃣ Prueba: Validación de Teléfonos

### Escenarios a probar:

```dart
// Abre lib/EJEMPLOS_FASE_1.dart y ejecuta:

ejemploValidarTelefono();

// Esperado: ✅ todos estos teléfonos válidos:
// ✅ 9123456789
// ✅ +1 (912) 345-6789
// ✅ (912) 345-6789
// ✅ 912-345-6789
// ✅ +52 1234567890
// ❌ abc123 (inválido)
// ❌ 123 (inválido)
```

### Prueba manual en la app:

1. Ir a **Ajustes** → **Contactos**
2. Hacer clic en **Agregar contacto**
3. Probar estos formatos:
   - `9123456789` ✅ Debe aceptar
   - `(912) 345-6789` ✅ Debe aceptar
   - `+1-912-345-6789` ✅ Debe aceptar
   - `123` ❌ Debe rechazar
   - `abc` ❌ Debe rechazar

---

## 2️⃣ Prueba: Almacenamiento Seguro

### Verificar que se guarda en secure_storage:

```dart
// En lib/main.dart o donde quieras, agrega:

import 'services/secure_storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Prueba de almacenamiento seguro
  await testSecureStorage();
  
  runApp(const MyApp());
}

Future<void> testSecureStorage() async {
  // 1. Guardar
  await SecureStorageService.savePreferredPhone('+19123456789');
  print('1️⃣ Guardado: +19123456789');
  
  // 2. Recuperar
  final phone = await SecureStorageService.getPreferredPhone();
  print('2️⃣ Recuperado: $phone');
  
  // 3. Verificar
  if (phone == '+19123456789') {
    print('✅ ¡Almacenamiento seguro funciona!');
  } else {
    print('❌ Error: Los datos no coinciden');
  }
}
```

**Resultado esperado:**
```
1️⃣ Guardado: +19123456789
2️⃣ Recuperado: +19123456789
✅ ¡Almacenamiento seguro funciona!
```

---

## 3️⃣ Prueba: Agregar y recuperar contacto de emergencia

### En Ajustes:

1. Ir a **Ajustes** → **Contactos**
2. Hacer clic en **Agregar contacto**
3. Llenar:
   - Nombre: `Juan García`
   - Teléfono: `(912) 345-6789`
4. Hacer clic en **Guardar**
5. **Resultado esperado**:
   - ✅ Contacto aparece en la lista
   - ✅ El teléfono se normaliza a `+19123456789`
   - ✅ Se guarda en almacenamiento seguro (no lo ves, pero está encriptado)

### Verificar persistencia:

1. Cerrar la app completamente
2. Reabrirla
3. Ir a **Ajustes** → **Contactos**
4. **Resultado esperado**: El contacto sigue ahí (guardado en secure_storage)

---

## 4️⃣ Prueba: Botón de pánico usa contacto guardado

### Configuración:

1. Ir a **Ajustes** → **Contactos**
2. Agregar contacto de emergencia (ej: `Juan García`, `+1234567890`)
3. Ir a **Opciones** → **Información de seguro** (opcional, para verificar la app funciona)
4. Ir a **Inicio**

### Prueba:

1. Presionar uno de los botones pequeños en la parte inferior
2. Hacer clic en el segundo botón (debería ser el contacto de emergencia)
3. **Resultado esperado**: 
   - ✅ Se activa el botón rojo
   - ✅ Se selecciona el contacto guardado
   - ✅ Cuando se completa el hold, intenta llamar al número guardado

---

## 5️⃣ Prueba: Normalización de teléfono

### Casos a probar:

```
Entrada                    → Salida Esperada
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
9123456789                → +19123456789
(912) 345-6789            → +19123456789
912-345-6789              → +19123456789
+1 912 345 6789           → +19123456789
+1-912-345-6789           → +19123456789
1234567890                → +11234567890
+521234567890             → +521234567890
```

### Cómo verificar:

1. Ir a **Ajustes** → **Contactos**
2. Agregar contacto con: `(912) 345-6789`
3. Ver en la lista: debe mostrar `+19123456789`

---

## 6️⃣ Prueba: Validaciones de otros campos

### En Ajustes → Editar perfil:

| Campo | Caso Válido | Caso Inválido | Resultado |
|-------|------------|---------------|-----------|
| **Nombre** | `Juan Pérez` | `123abc` | ✅ Rechaza números |
| **Apellido** | `García López` | `García@123` | ✅ Rechaza símbolos |
| **Edad** | `25` | `200` | ✅ Rechaza > 120 |
| **Edad** | `1` | `0` | ✅ Rechaza < 1 |

---

## 7️⃣ Prueba: Flujo completo de emergencia

### Pasos:

1. **Abrir app** → `Inicio`
2. **Agregar contacto** (Ajustes):
   - Nombre: `Emergencia Test`
   - Teléfono: `+15551234567`
3. **Activar alerta** (Inicio):
   - Presionar botón rojo
   - Mantener 1.2 segundos
   - Se inicia la llamada
4. **Verificar en Opciones** → **Historial de alertas**:
   - ✅ Se registró la alerta
   - ✅ Tiene timestamp
   - ✅ Tiene descripción

---

## 8️⃣ Prueba: Limpiar datos (Logout)

### Código de prueba:

```dart
import 'services/secure_storage_service.dart';

Future<void> testCleanup() async {
  // 1. Guardar datos
  await SecureStorageService.saveEmergencyContact('Juan', '+1234567890');
  print('✅ Datos guardados');
  
  // 2. Verificar que existen
  final contact = await SecureStorageService.getEmergencyContact();
  print('✅ Datos recuperados: ${contact?['nombre']}');
  
  // 3. Limpiar todo
  await SecureStorageService.deleteAll();
  print('✅ Datos limpiados');
  
  // 4. Verificar que están vacíos
  final empty = await SecureStorageService.getEmergencyContact();
  if (empty == null) {
    print('✅ Confirmado: no hay datos');
  }
}
```

---

## 9️⃣ Prueba: Compilación sin errores

```bash
# Terminal
cd c:\Users\MateoM\Desktop\Proyecto-app\flutter_application_1

# Análisis
flutter analyze

# Debe mostrar:
# "108 issues found" - PERO SOLO SON INFO (avoid_print, etc)
# NO DEBE haber "error -"

# Ejecutar
flutter run

# Debe compilar sin errores
```

---

## 🔟 Prueba: Verificar dependencias

```bash
flutter pub get

# Debe descargar sin errores:
# ✅ flutter_secure_storage: 9.2.4
# ✅ phone_numbers_parser: 8.3.0
```

---

## 📋 Checklist de Testing

- [ ] Teléfonos válidos son aceptados
- [ ] Teléfonos inválidos son rechazados
- [ ] El teléfono se normaliza correctamente
- [ ] Los contactos se guardan de forma segura
- [ ] Los contactos persisten después de cerrar la app
- [ ] El botón de pánico usa el contacto guardado
- [ ] Las validaciones de otros campos funcionan
- [ ] La app compila sin errores
- [ ] No hay errores críticos en `flutter analyze`
- [ ] Los datos se limpian correctamente

---

## 🐛 Troubleshooting

### Problema: "flutter_secure_storage not found"
```bash
flutter pub get
flutter clean
flutter pub get
flutter run
```

### Problema: Teléfono no se normaliza
- Verifica que importaste: `import 'validators/validators.dart';`
- Verifica que usas: `Validators.normalizePhoneNumber(phone)`

### Problema: Datos no persisten
- Verifica: ¿Usaste `SecureStorageService.saveEmergencyContact()`?
- Verifica: ¿La app no se desinstale entre tests?

### Problema: La app se bloquea al guardar
- Agrega try-catch:
```dart
try {
  await SecureStorageService.saveEmergencyContact(name, phone);
} catch (e) {
  print('Error: $e');
}
```

---

## ✅ Teste Completo (5-10 minutos)

```
1. flutter pub get               (1 min)
2. flutter run                   (1 min)
3. Agregar contacto              (1 min)
4. Cerrar y reabrir app          (1 min)
5. Verificar que contacto existe (1 min)
6. Probar botón de pánico        (1 min)
7. Ir a Opciones → Alertas       (1 min)
```

**Resultado esperado**: ✅ Todo funciona correctamente

---

## 📊 Reporte de Testing

Después de completar las pruebas, puedes crear un reporte:

```markdown
# Reporte de Testing - Fase 1

**Fecha**: [Hoy]
**Testador**: [Tu nombre]
**Dispositivo**: [Tipo y versión]

## Resultados

- [x] Validación de teléfonos
- [x] Almacenamiento seguro
- [x] Persistencia de datos
- [x] Normalización automática
- [x] Compilación sin errores

## Observaciones

[Nota cualquier comportamiento inesperado]

## Conclusión

✅ Fase 1 completada y validada
```

---

## 🎯 Próxima Fase

Una vez completes estas pruebas, estará listo para:
1. ✅ Implementar Fase 2: Rate Limiting
2. ✅ Implementar Fase 3: Firebase
3. ✅ Deployment a producción

---

**Happy Testing!** 🚀
