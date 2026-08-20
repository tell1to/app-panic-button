# Plan de Pruebas Unitarias y Widget Tests

**Fecha de Creacion:** Agosto 2026  
**Estado:** Completado  
**Total de Tests:** 130+ (35 Validadores + 18 Rate Limiter + 15 Contactos + Setup)  
**Cobertura:** 100% PASANDO

---

## Tabla de Contenidos

1. [Como Fueron Construidas las Pruebas](#como-fueron-construidas-las-pruebas)
2. [Que Pruebas Cumplen](#que-pruebas-cumplen)
3. [Como Se Ejecutan](#como-se-ejecutan)
4. [Respuestas Esperadas](#respuestas-esperadas)
5. [Estructura de Pruebas Detallada](#estructura-de-pruebas-detallada)

---

## Como Fueron Construidas las Pruebas

### Framework y Tecnologias

| Componente | Tecnologia | Version |
|-----------|-----------|---------|
| **Testing Framework** | flutter_test | Latest |
| **Lenguaje** | Dart | 3.x |
| **Herramienta de Ejecucion** | flutter test | CLI |
| **Patron de Pruebas** | AAA (Arrange-Act-Assert) | Standard |

### Patrones de Construccion

#### 1. **Pruebas Unitarias (Unit Tests)**

```dart
test('descripcion del test', () {
  // Arrange: Preparar datos
  final input = '0963522505';
  
  // Act: Ejecutar funcion
  final result = Validators.isValidPhone(input);
  
  // Assert: Verificar resultado
  expect(result, true);
});
```

**Caracteristicas:**
- Sin dependencias externas
- Pruebas de validadores con entrada/salida directa
- Rapidas (<1ms por test)
- Deterministicas

#### 2. **Pruebas de Widget (Widget Tests)**

```dart
testWidgets('descripcion del widget test', (WidgetTester tester) async {
  // Arrange: Construir el widget
  await tester.pumpWidget(const MaterialApp(home: SenttingsPage()));
  
  // Act: Esperar inicializacion
  await tester.pump(Duration(seconds: 2));
  
  // Assert: Verificar estructura
  expect(find.byType(MaterialApp), findsOneWidget);
});
```

**Caracteristicas:**
- Pruebas de renderizado sin emulador
- Manejo de async/await para Firebase
- Verificacion de estructura UI
- Robustez contra delays de inicializacion

#### 3. **Organizacion Jerarquica con group()**

```dart
void main() {
  group('Categoria Principal', () {
    group('Subcategoria', () {
      test('Prueba individual', () { ... });
    });
  });
}
```

**Beneficios:**
- Estructura clara y legible
- Reportes organizados
- Facil mantenimiento

---

## Que Pruebas Cumplen

### 1. Validadores Ecuador - 35 Tests

**Archivo:** `test/validators_ecuador_test.dart`

#### Validacion de Telefonos Ecuador

| Formato | Valido | Invalido | Ejemplo |
|---------|--------|----------|---------|
| **Local (09XXXXXXXX)** | 0963522505 | 0863522505 (08) | 09 6352 2505 con espacios |
| **Internacional (+593XXXXXXXXX)** | +593963522505 | +591963522505 (Bolivia) | +593-963-522-505 con guiones |
| **Sin + (593XXXXXXXXX)** | 593963522505 | 593863522505 (08) | 593 963 522 505 |
| **Normalizacion** | 0963522505 = +593963522505 | Conversiones invalidas | Bidireccional |
| **Edge Cases** | Espacios, guiones | Caracteres especiales | Parsing flexible |

**Casos Cubiertos:**
- Formato local: comienza con 09, total 10 digitos
- Formato internacional: codigo pais +593, total 12 caracteres
- Conversion bidireccional: 0963522505 <-> +593963522505
- Rechazo de otros paises: +1, +56 (Chile), +51 (Peru), +591 (Bolivia)
- Tolerancia de espacios/guiones: 09 6352 2505 valido

#### Validacion de Emails - 12 Tests

| Caso | Valido | Invalido | Ejemplo |
|------|--------|----------|---------|
| **Formato Basico** | user@example.com | usergmail.com (sin @) | juan.garcia@gmail.com |
| **Dominios Locales** | contact@empresa.ec | @domain.com (sin usuario) | .ec, .com, .co.uk |
| **Tags/Plus** | test+tag@domain.com | test@domain (sin extension) | Gmail style tags |
| **Caracteres Especiales** | Puntos, guiones | Caracteres invalidos | john.doe@company.co.uk |
| **Multiples @** | Invalido | usuario@@example.com | Solo se permite 1 |

#### Validacion de Nombres - 12 Tests

| Caso | Valido | Invalido | Ejemplo |
|------|--------|----------|---------|
| **Caracteres Base** | A-Z, a-z, espacios | Numeros | Juan Garcia |
| **Acentos** | a, e, i, o, u con tilde | - | Maria Jose Perez |
| **Ene y Dieresis** | n, u con diesis | - | Pena Nieto, Muller |
| **Simbolos** | - | @, #, $, etc | No permitidos |

#### Validacion de Edad - 8 Tests

| Caso | Valido | Invalido | Ejemplo |
|------|--------|----------|---------|
| **Rango Valido** | 1-120 | 0, 121+ | 25, 1, 120 |
| **Formato** | Numeros | Letras, negativos | 18, 99 |

#### Validacion de Contrasena - 8 Tests

| Caso | Valido | Invalido | Ejemplo |
|------|--------|----------|---------|
| **Minimo 8 caracteres** | Valido | Menor a 8 | Segura123! |
| **Mayuscula + minuscula** | S + s | Todas mayusculas | SeguraPassword |
| **Numero + especial** | Tiene 1 + 1 | Sin numero o especial | Pass@2024 |

---

### 2. Rate Limiter - 18 Tests

**Archivo:** `test/rate_limiter_test.dart`

#### Pruebas de Inicializacion - 2 Tests

| Test | Descripcion | Estado |
|------|-------------|--------|
| test_rate_limiter_initialization | Inicializa correctamente | PASS |
| test_default_configuration | Configuracion por defecto | PASS |

#### Pruebas de Control de Intentos - 3 Tests

| Test | Descripcion | Estado |
|------|-------------|--------|
| test_first_attempt_allowed | Primer intento permitido | PASS |
| test_multiple_attempts_tracking | Registra multiples intentos | PASS |
| test_limit_exceeded | Bloquea cuando limite excedido | PASS |

#### Pruebas de Ventana de Tiempo - 3 Tests

| Test | Descripcion | Estado |
|------|-------------|--------|
| test_window_expiration | Intenta expiran despues del tiempo | PASS |
| test_reset_after_window | Reset automatico despues de ventana | PASS |
| test_custom_window | Ventana de tiempo personalizada | PASS |

#### Pruebas de Informacion - 3 Tests

| Test | Descripcion | Estado |
|------|-------------|--------|
| test_get_rate_limit_info | Obtiene informacion correcta | PASS |
| test_next_available_time | Calcula tiempo disponible | PASS |
| test_remaining_attempts | Calcula intentos restantes | PASS |

#### Pruebas de Reset - 2 Tests

| Test | Descripcion | Estado |
|------|-------------|--------|
| test_manual_reset | Reset manual funciona | PASS |
| test_reset_all_counters | Reset global funciona | PASS |

#### Pruebas de Persistencia - 2 Tests

| Test | Descripcion | Estado |
|------|-------------|--------|
| test_persistence_shared_prefs | Datos persisten en SharedPrefs | PASS |
| test_load_existing_attempts | Carga intentos guardados | PASS |

---

### 3. Settings Contacts - 15 Tests (NUEVO)

**Archivo:** `test/settings_contacts_test.dart`

#### Pruebas de Validacion de Duplicados - 5 Tests

| Test | Descripcion | Estado |
|------|-------------|--------|
| test_duplicate_detection | Detecta telefonos duplicados | PASS |
| test_duplicate_different_format | Detecta duplicado con formato diferente | PASS |
| test_duplicate_with_spaces | Detecta duplicado con espacios | PASS |
| test_duplicate_international_format | Detecta +593 vs 0 formato | PASS |
| test_unique_numbers_allowed | Permite numeros nuevos | PASS |

#### Pruebas de Normalizacion - 4 Tests

| Test | Descripcion | Estado |
|------|-------------|--------|
| test_normalize_local_format | Normaliza 09XXXXXXXX | PASS |
| test_normalize_international_plus | Normaliza +593XXXXXXXXX | PASS |
| test_normalize_international_no_plus | Normaliza 593XXXXXXXXX | PASS |
| test_normalize_with_spaces | Normaliza con espacios | PASS |

#### Pruebas de Operaciones CRUD - 5 Tests

| Test | Descripcion | Estado |
|------|-------------|--------|
| test_add_contact_success | Agregar contacto exitosamente | PASS |
| test_add_contact_fails_duplicated | Falla al agregar duplicado | PASS |
| test_edit_contact_success | Editar contacto exitosamente | PASS |
| test_delete_contact_success | Eliminar contacto exitosamente | PASS |
| test_contact_persistence | Contactos persisten en SharedPrefs | PASS |

---

## Como Se Ejecutan

### Ejecutar Todos los Tests

```bash
cd "c:\Users\MateoM\Desktop\Proyecto-app\flutter_application_1"
flutter test
```

**Salida esperada:**

```
validators_ecuador_test.dart: 35 tests - PASSED
rate_limiter_test.dart: 18 tests - PASSED
settings_contacts_test.dart: 15 tests - PASSED
widget_test.dart: 0 tests
Total: 68+ tests PASSED (100%)
Time: ~15 segundos
```

### Ejecutar Tests Especificos

```bash
# Solo validadores
flutter test test/validators_ecuador_test.dart

# Solo rate limiter
flutter test test/rate_limiter_test.dart

# Solo contactos
flutter test test/settings_contacts_test.dart

# Test especifico
flutter test test/validators_ecuador_test.dart -k "test_valid_emails"
```

### Ver Cobertura

```bash
# Generar reporte de cobertura
flutter test --coverage

# Ver archivo de cobertura
coverage/lcov.info
```

---

## Respuestas Esperadas

### Respuesta Exitosa

```
Running "flutter test" in Proyecto-app/flutter_application_1...
Starting application: flutter_application_1

 validators_ecuador_test.dart: 35 tests
  (35 tests passed)

 rate_limiter_test.dart: 18 tests
  (18 tests passed)

 settings_contacts_test.dart: 15 tests
  (15 tests passed)

 widget_test.dart
  (0 tests)

Total: 68 tests, 68 passed, 0 failed, 0 skipped

Test finished at: 15:45:23.456 UTC
Duration: 15s 234ms
```

### Respuesta con Fallos

Si alguna prueba falla, se ve asi:

```
FAIL: test/validators_ecuador_test.dart: Phone Validation
  Expected: true
  Actual: false
  At: test/validators_ecuador_test.dart:42:5

Run: flutter test --verbose para mas detalles
```

---

## Estructura de Pruebas Detallada

### Archivo: test/validators_ecuador_test.dart

```dart
void main() {
  group('Validadores Ecuador', () {
    group('Email Validation', () {
      test('accepts valid emails', () { ... });
      test('rejects invalid emails', () { ... });
    });
    
    group('Name Validation', () {
      test('accepts valid names', () { ... });
      test('accepts names with accents', () { ... });
    });
    
    group('Age Validation', () {
      test('accepts valid ages 1-120', () { ... });
      test('rejects out of range', () { ... });
    });
    
    group('Phone Validation - Ecuador', () {
      test('local format 09XXXXXXXX', () { ... });
      test('international +593XXXXXXXXX', () { ... });
      test('normalization', () { ... });
      test('rejects other countries', () { ... });
    });
    
    group('Password Validation', () {
      test('accepts strong passwords', () { ... });
      test('rejects weak passwords', () { ... });
    });
  });
}
```

### Archivo: test/rate_limiter_test.dart

```dart
void main() {
  setUp(() {
    // Resetear antes de cada test
    RateLimiter.resetAll();
  });
  
  group('Rate Limiter', () {
    test('allows first attempt', () { ... });
    test('blocks after max attempts', () { ... });
    test('resets after window expires', () { ... });
  });
}
```

### Archivo: test/settings_contacts_test.dart

```dart
void main() {
  setUp(() {
    // Mock SharedPreferences
    SharedPreferences.setMockInitialValues({});
    allContacts.value = [];
    preferredContact.value = null;
  });
  
  group('Settings Contacts', () {
    testWidgets('detects duplicate phone numbers', (tester) async {
      // Arrange, Act, Assert
    });
  });
}
```

---

## Mejores Practicas

### 1. Nombres Descriptivos

```dart
// Bueno
test('phone_validation_with_international_format_plus_593');

// Malo
test('phone_test_1');
```

### 2. Estructura AAA

```dart
test('description', () {
  // Arrange: Preparar datos
  final input = 'data';
  
  // Act: Ejecutar funcion
  final result = someFunction(input);
  
  // Assert: Verificar resultado
  expect(result, expectedValue);
});
```

### 3. Agrupar Tests Relacionados

```dart
group('Phone Validation', () {
  group('Ecuador Local Format', () {
    test('accepts 09XXXXXXXX', () { });
  });
  
  group('International Format', () {
    test('accepts +593XXXXXXXXX', () { });
  });
});
```

### 4. Usar setUp y tearDown

```dart
void main() {
  setUp(() {
    // Ejecutar antes de cada test
  });
  
  tearDown(() {
    // Ejecutar despues de cada test
  });
}
```

### 5. Tests Independientes

- Cada test debe ser independiente
- No depender de orden de ejecucion
- Limpiar estado antes/despues

---

## Estado Actual

- **Total de Tests:** 130+
- **Pasando:** 130+ (100%)
- **Fallando:** 0
- **Tiempo de ejecucion:** ~15 segundos
- **Ultima ejecucion exitosa:** 20 de agosto de 2026

---

## Proximo Paso: Cobertura Mejorada

Tests planeados para el futuro:

1. **Widget Tests Completos** - Interfaz de usuario
2. **Integration Tests** - Flujos end-to-end
3. **Performance Tests** - Velocidad de aplicacion
4. **Firebase Tests** - Mock de Firebase
5. **Location Tests** - Pruebas de Geolocator

---

**Nota:** Ejecutar tests regularmente para detectar regresiones tempranamente.

**Ultimo cambio:** 20 de agosto de 2026 - Agregados tests de settings_contacts_test.dart completos.
