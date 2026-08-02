# 🇪🇨 Validadores Adaptados para Ecuador

## Cambios Realizados

Se han adaptado todos los validadores de teléfono para funcionar específicamente con **Ecuador**.

---

## 📱 Formatos Aceptados

### Formato Local (Recomendado)
```
0963522505     ✅ Aceptado (10 dígitos, comienza con 09)
0961234567     ✅ Aceptado
0987654321     ✅ Aceptado
```

### Formato Internacional
```
+593963522505  ✅ Aceptado (con + y código 593)
593963522505   ✅ Aceptado (sin +)
```

### Con Espacios o Guiones
```
09 6352 2505   ✅ Aceptado
09-6352-2505   ✅ Aceptado
+593 9 6352 2505  ✅ Aceptado
```

### Rechazados
```
9963522505     ❌ Rechazado (falta el 0 inicial)
963522505      ❌ Rechazado (menos de 10 dígitos)
+11234567890   ❌ Rechazado (no es formato Ecuador)
```

---

## 🔄 Normalización

### Entrada → Salida

| Entrada | Salida (Local) | Salida (Internacional) |
|---------|----------------|----------------------|
| 0963522505 | 0963522505 | +593963522505 |
| 09 6352 2505 | 0963522505 | +593963522505 |
| +593963522505 | 0963522505 | +593963522505 |
| 593963522505 | 0963522505 | +593963522505 |

**Nota**: Por defecto, se normaliza al formato local de Ecuador `0963522505`

---

## 💻 Funciones Disponibles

### Validación
```dart
import 'validators/validators.dart';

// Validar si es un teléfono de Ecuador válido
if (Validators.isValidPhone('0963522505')) {
  print('✅ Válido');
}

if (Validators.isValidPhone('+593963522505')) {
  print('✅ Válido');
}
```

### Normalización - Formato Local (Predeterminado)
```dart
// 0963522505 (formato local)
final local = Validators.normalizePhoneNumber('09 6352 2505');
// Resultado: "0963522505"

// También funciona con:
final local2 = Validators.normalizePhoneNumber('+593963522505');
// Resultado: "0963522505"
```

### Normalización - Formato Internacional
```dart
// +593963522505 (formato internacional)
final intl = Validators.normalizePhoneNumber('0963522505', international: true);
// Resultado: "+593963522505"
```

### Funciones de Ayuda
```dart
// Obtener formato internacional
final intl = Validators.getInternationalFormat('0963522505');
// "+593963522505"

// Obtener formato local
final local = Validators.getLocalFormat('+593963522505');
// "0963522505"
```

---

## 🔐 Almacenamiento Seguro

El teléfono se normaliza y guarda en formato local:

```dart
import 'services/secure_storage_service.dart';

final phone = '09 6352 2505';

// 1. Validar
if (Validators.isValidPhone(phone)) {
  // ✅ Válido
}

// 2. Normalizar (automáticamente en formato local: 0963522505)
final normalized = Validators.normalizePhoneNumber(phone);

// 3. Guardar de forma segura
await SecureStorageService.saveEmergencyContact('Juan García', normalized);

// 4. Recuperar
final contact = await SecureStorageService.getEmergencyContact();
// contact['telefono'] = '0963522505'
```

---

## ✅ Ejemplos de Uso en Ajustes

```dart
// En senttings.dart - agregar contacto

final nombre = 'María López';
final telefono = '09 6352 2505';  // Con espacios (normal en UI)

// 1. Validar
if (!Validators.isValidPhone(telefono)) {
  // Mostrar error
  return;
}

// 2. Normalizar (automáticamente a 0963522505)
final telefonoNormalizado = Validators.normalizePhoneNumber(telefono);

// 3. Guardar
_contactos.add({
  'nombre': nombre,
  'telefono': telefonoNormalizado  // "0963522505"
});

await SecureStorageService.saveEmergencyContact(nombre, telefonoNormalizado);
```

---

## 📝 Cambios en Archivos

### `lib/validators/validators.dart`
- ✅ Removida dependencia de `phone_numbers_parser` (no es necesaria para Ecuador)
- ✅ Agregar validación específica para Ecuador
- ✅ Agregar normalización a formato local por defecto
- ✅ Agregar funciones para formato internacional

### `lib/senttings.dart`
- ✅ Mensaje de error actualizado con formato Ecuador
- ✅ Usa normalización sin `countryCode`

### `lib/main.dart`
- ✅ Usa normalización por defecto (formato local Ecuador)

---

## 🧪 Pruebas

```dart
// Prueba validación
assert(Validators.isValidPhone('0963522505') == true);
assert(Validators.isValidPhone('+593963522505') == true);
assert(Validators.isValidPhone('593963522505') == true);
assert(Validators.isValidPhone('09 6352 2505') == true);
assert(Validators.isValidPhone('123') == false);
assert(Validators.isValidPhone('+11234567890') == false);

// Prueba normalización (local)
assert(Validators.normalizePhoneNumber('0963522505') == '0963522505');
assert(Validators.normalizePhoneNumber('+593963522505') == '0963522505');
assert(Validators.normalizePhoneNumber('593963522505') == '0963522505');
assert(Validators.normalizePhoneNumber('09 6352 2505') == '0963522505');

// Prueba normalización (internacional)
assert(Validators.normalizePhoneNumber('0963522505', international: true) == '+593963522505');
assert(Validators.normalizePhoneNumber('+593963522505', international: true) == '+593963522505');
assert(Validators.normalizePhoneNumber('593963522505', international: true) == '+593963522505');

// Prueba funciones de ayuda
assert(Validators.getInternationalFormat('0963522505') == '+593963522505');
assert(Validators.getLocalFormat('+593963522505') == '0963522505');
```

---

## 📱 Operadores Telefónicos en Ecuador

Los números celulares de Ecuador (+593 9) son asignados por:
- **Movistar** (Antes Porta)
- **Claro** (Antes Bellsouth)
- **CNT**
- **TUENTI**
- Otros operadores virtuales

Todos siguen el mismo formato: **09XXXXXXXX** (10 dígitos)

---

## 🔗 Referencias

- **Código de país**: +593 (Ecuador)
- **Formato local**: 09XXXXXXXX (10 dígitos)
- **Formato internacional**: +593 9XXXXXXXX (12 dígitos incluyendo +)
- **Tipo de números**: Celular (móvil)
- **Validación**: Exacta (sin flexibilidad innecesaria)

---

## ✨ Ventajas de esta Adaptación

✅ **Específico para Ecuador** - No acepta números de otros países  
✅ **Sin dependencias externas** - No necesita `phone_numbers_parser`  
✅ **Más rápido** - Validación local simple y eficiente  
✅ **Más seguro** - Solo acepta formatos conocidos de Ecuador  
✅ **Mejor UX** - Mensajes de error claros con formato Ecuador  
✅ **Fácil mantenimiento** - Lógica simple y entendible  

---

**Adaptación completada**: ✅ Ecuador  
**Fecha**: 21 de diciembre de 2025  
**Estado**: ✅ LISTO
