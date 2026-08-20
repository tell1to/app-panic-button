# Modulo de Validadores - Documentacion Completa

**Ultima actualizacion:** 20 de agosto de 2026  
**Version:** 1.4.67  
**Estado:** Desarrollo

---

## Indice

1. [Descripcion General](#descripcion-general)
2. [Ubicacion y Estructura](#ubicacion-y-estructura)
3. [Validadores Disponibles](#validadores-disponibles)
4. [Ejemplos de Uso](#ejemplos-de-uso)
5. [Casos de Uso Ecuador](#casos-de-uso-ecuador)
6. [Testing](#testing)
7. [Integracion](#integracion)

---

## Descripcion General

El modulo de validadores proporciona funciones centralizadas para validar datos de usuario. Esta especificamente configurado para **Ecuador** con validacion de telefonos, cedulas y formatos locales.

**Ubicacion:** `lib/utils/validators/validators.dart`  
**Lineas de codigo:** 180+  
**Funciones:** 8 principales  
**Estado:** Completo y testeado

### Caracteristicas Principales

- Validacion especifica para Ecuador
- Manejo de multiples formatos
- Normalizacion automatica de datos
- Mensajes de error en espanol
- 35+ tests unitarios
- Sin dependencias externas (solo dart:core)

---

## Ubicacion y Estructura

### Ruta de Archivo

```
lib/
 utils/
   validators/
     validators.dart
```

### Clase Principal

```dart
class Validators {
  // Constantes
  static const String ecuadorCountryCode = '+593';
  static const String ecuadorCountryPrefix = '593';
  
  // Metodos estaticos (sin necesidad de instanciar)
  static bool isValidEmail(String email)
  static bool isValidName(String name)
  static bool isValidAge(String age)
  static bool isValidPhone(String phone)
  static bool isValidPassword(String password)
  static String normalizePhoneNumber(String phone)
  static String getInternationalFormat(String phone)
  static String getLocalFormat(String phone)
}
```

---

## Validadores Disponibles

### 1. Email Validation

#### Funcion

```dart
static bool isValidEmail(String email)
```

#### Descripcion

Valida direcciones de correo electronico con formato estandar internacional.

#### Formato Aceptado

```
ejemplo@dominio.com
usuario.nombre@empresa.co.uk
nombre+etiqueta@servidor.org
```

#### Formato Rechazado

```
sin-arroba.com
usuario@
@dominio.com
usuario @dominio.com
```

#### Ejemplo

```dart
// Valido
Validators.isValidEmail('juan@gmail.com'); // true
Validators.isValidEmail('maria.garcia@hotmail.com'); // true

// Invalido
Validators.isValidEmail('juangmail.com'); // false
Validators.isValidEmail('juan@'); // false
```

#### Regex Usado

```
^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$
```

---

### 2. Name Validation

#### Funcion

```dart
static bool isValidName(String name)
```

#### Descripcion

Valida nombres que solo contengan letras (incluyendo acentos) y espacios.

#### Caracteres Permitidos

```
A-Z, a-z
Acentos estandar (a, e, i, o, u con tilde)
Caracteres especiales alemanes
Espacios simples
```

#### Caracteres Rechazados

```
Numeros (0-9)
Guiones
Puntos
Simbolos especiales (@, #, $, etc)
```

#### Ejemplo

```dart
// Valido
Validators.isValidName('Juan Garcia'); // true
Validators.isValidName('Maria Jose Lopez'); // true
Validators.isValidName('Jose Maria'); // true

// Invalido
Validators.isValidName('Juan123'); // false
Validators.isValidName('Juan-Pablo'); // false
Validators.isValidName('123'); // false
```

---

### 3. Age Validation

#### Funcion

```dart
static bool isValidAge(String age)
```

#### Descripcion

Valida edad como numero entre 1 y 120 anos.

#### Rango Valido

```
1 - 120 anos
```

#### Ejemplo

```dart
// Valido
Validators.isValidAge('25'); // true
Validators.isValidAge('1'); // true (recien nacido)
Validators.isValidAge('120'); // true (maximo permitido)

// Invalido
Validators.isValidAge('0'); // false (menor que 1)
Validators.isValidAge('121'); // false (mayor que 120)
Validators.isValidAge('-5'); // false (negativo)
Validators.isValidAge('abc'); // false (no es numero)
```

---

### 4. Phone Validation (CRITICA - Ecuador)

#### Funcion

```dart
static bool isValidPhone(String phone)
static String normalizePhoneNumber(String phone)
```

#### Descripcion

Valida numeros de telefono ecuatorianos en dos formatos principales.

#### Formatos Aceptados

```
Formato Local: 09XXXXXXXX (10 digitos)
  Ejemplo: 0963522505

Formato Internacional: +593XXXXXXXXX (14 caracteres con +)
  Ejemplo: +593963522505

Formato sin +: 593XXXXXXXXX (12 digitos)
  Ejemplo: 593963522505
```

#### Formato Rechazado

```
Otros paises (USA, Colombia, Peru, etc)
Formato incorrecto (menos de 10 digitos)
Telefono fijo ecuatoriano (no es movil)
```

#### Normalizacion

```dart
// La funcion normalizePhoneNumber convierte todo a formato local
Validators.normalizePhoneNumber('+593963522505') 
  // Retorna: '0963522505'

Validators.normalizePhoneNumber('593963522505') 
  // Retorna: '0963522505'

Validators.normalizePhoneNumber('0963522505') 
  // Retorna: '0963522505'
```

#### Ejemplo

```dart
// Valido
Validators.isValidPhone('0963522505'); // true
Validators.isValidPhone('+593963522505'); // true
Validators.isValidPhone('593963522505'); // true
Validators.isValidPhone('09 6352 2505'); // true (con espacios)

// Invalido
Validators.isValidPhone('+1963522505'); // false (USA)
Validators.isValidPhone('0943522505'); // false (comienza con 094)
Validators.isValidPhone('963522505'); // false (falta el 0)
Validators.isValidPhone(''); // false (vacio)
```

#### Casos Especiales

En `tutorial_screen.dart` y `settings_page.dart` hay validacion adicional:

```dart
// Validar si teléfono es vacio (permitido en algunos campos)
// Validar si telefono ya existe en lista de contactos
// Detectar duplicados aunque use formato diferente
```

---

### 5. Password Validation

#### Funcion

```dart
static bool isValidPassword(String password)
```

#### Descripcion

Valida contrasenas con criterios de seguridad basico.

#### Criterios

```
Minimo 8 caracteres
Al menos una mayuscula (A-Z)
Al menos una minuscula (a-z)
Al menos un numero (0-9)
Al menos un caracter especial (!@#$%^&*)
```

#### Ejemplo

```dart
// Valido
Validators.isValidPassword('Segura123!'); // true
Validators.isValidPassword('MyPass@2024'); // true

// Invalido
Validators.isValidPassword('corta'); // false (muy corta)
Validators.isValidPassword('sinmayuscula123!'); // false
Validators.isValidPassword('SINNUMERO!'); // false
```

---

## Ejemplos de Uso

### Uso en Formularios

```dart
// En settings_page.dart
bool _esNombreValido(String nombre) {
  return Validators.isValidName(nombre);
}

bool _esTelefonoValido(String telefono) {
  return Validators.isValidPhone(telefono);
}

bool _esEdadValida(String edad) {
  return Validators.isValidAge(edad);
}

// En Widget
TextField(
  onChanged: (value) {
    if (!_esTelefonoValido(value)) {
      setState(() => _telefonoError = 'Telefono invalido');
    }
  },
)
```

### Uso en Tutorial

```dart
// En tutorial_screen.dart
String _getCiErrorMessage(String ci) {
  if (ci.isEmpty) return '';
  if (!RegExp(r'^\d+$').hasMatch(ci)) return 'Solo numeros';
  if (ci.length != 10) return 'Debe tener 10 digitos';
  return '';
}
```

### Normalizacion de Telefonos

```dart
// En options_page.dart
String _normalizePhone(String phone) {
  return Validators.normalizePhoneNumber(phone);
}

// Uso
String phoneNormalized = Validators.normalizePhoneNumber('+593963522505');
// phoneNormalized = '0963522505'
```

---

## Casos de Uso Ecuador

### Cedula Ecuatoriana (CI)

```dart
// Validacion basica: 10 digitos numericos
bool _isValidCI(String ci) {
  if (ci.isEmpty) return false;
  if (!RegExp(r'^\d{10}$').hasMatch(ci)) return false;
  return true;
}
```

### Tipo de Sangre

```dart
final List<String> tiposSangre = [
  'O+', 'O-', 'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-'
];

bool _isValidBloodType(String bloodType) {
  return tiposSangre.contains(bloodType);
}
```

### Contacto de Emergencia

```dart
// Debe ser un numero de telefono valido
bool _isValidEmergencyContact(String phone) {
  return Validators.isValidPhone(phone);
}
```

---

## Testing

### Tests Unitarios

**Archivo:** `test/validators_ecuador_test.dart`

**Cobertura:** 35 tests

```
Pruebas de Email: 3 tests
Pruebas de Name: 4 tests
Pruebas de Age: 3 tests
Pruebas de Phone Ecuador: 10 tests (CRITICAS)
Pruebas de Password: 3 tests
Pruebas de Formatos: 3 tests
Pruebas de Normalizacion: 6 tests
```

### Ejecutar Tests

```bash
flutter test test/validators_ecuador_test.dart
```

### Resultado Esperado

```
Validadores Ecuador Test
 Email Validation
  + Valid emails
  + Invalid emails
  + Edge cases
 Name Validation
  + Valid names
  + Names with accents
  + Invalid names
 Age Validation
  + Valid ages
  + Invalid ages
  + Edge cases
 Phone Validation
  + Local format
  + International format
  + Normalization
  + Duplicate detection
  + Invalid formats
 Password Validation
  + Strong passwords
  + Weak passwords

Total: 35 tests PASSED
```

---

## Integracion

### Donde se Usan

| Archivo | Uso |
|---------|-----|
| **tutorial_screen.dart** | Validar datos del tutorial |
| **settings_page.dart** | Validar perfil y contactos |
| **options_page.dart** | Validar informacion medica |
| **rate_limiter_test.dart** | Testing de rate limiter |
| **validators_ecuador_test.dart** | Tests unitarios |

### Importacion

```dart
import '../utils/validators/validators.dart';

// Uso
bool esValido = Validators.isValidPhone('0963522505');
```

---

**Ultimo cambio:** 20 de agosto de 2026 - Agregado validacion de telefono duplicado y normalizacion mejorada.
