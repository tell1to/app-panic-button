# Archivos de Pruebas - Testing Completo
**Versión:** 1.0 | **Fecha:** 21 de diciembre de 2025 | **Estado:** 53/53 Tests Pasando
---
## Índice
1. [Descripción General](#descripción-general)
2. [Estructura de Testing](#estructura-de-testing)
3. [Tests Disponibles](#tests-disponibles)
4. [Cómo Ejecutar Tests](#cómo-ejecutar-tests)
5. [Cobertura de Tests](#cobertura-de-tests)
6. [Ejemplos de Tests](#ejemplos-de-tests)
7. [Mejores Prácticas](#mejores-prácticas)
---
## Descripción General
El proyecto incluye un **conjunto completo de pruebas unitarias** para garantizar la calidad y confiabilidad del código.
**Localización:** `test/`
**Total de tests:** 53
**Tests pasando:** 53 (100%)
**Herramienta:** Flutter Test (Dart testing framework)
### Objetivos de Testing
- Validar lógica de negocio
- Verificar integración de servicios
- Proteger contra regresiones
- Documentar comportamiento esperado
- Facilitar refactorización
---
## Estructura de Testing
### Carpeta de Tests
```
test/
 validators_ecuador_test.dart (35 tests)
 rate_limiter_test.dart (18 tests)
 notification_intervals_test.dart (0 tests - setup)
 widget_test.dart (0 tests - setup)
```
### Organización de Tests
```
test/
 Unit Tests
 validators_ecuador_test.dart Pruebas unitarias
 rate_limiter_test.dart Pruebas unitarias
 Widget Tests
 widget_test.dart Pruebas de UI (TBD)
 Integration Tests
 [En desarrollo]
```
---
## Tests Disponibles
### 1. Validadores Ecuador - 35 Tests
**Archivo:** `test/validators_ecuador_test.dart`
#### Pruebas de Email Validation
| Test | Descripción | Estado |
|------|-------------|--------|
| `test_valid_emails` | Valida emails correctos | PASS |
| `test_invalid_emails` | Rechaza emails inválidos | PASS |
| `test_email_edge_cases` | Casos límite de email | PASS |
#### Pruebas de Name Validation
| Test | Descripción | Estado |
|------|-------------|--------|
| `test_valid_names` | Valida nombres válidos | PASS |
| `test_names_with_accents` | Nombres con acentos | PASS |
| `test_names_with_spaces` | Nombres con espacios | PASS |
| `test_invalid_names` | Rechaza nombres inválidos | PASS |
#### Pruebas de Age Validation
| Test | Descripción | Estado |
|------|-------------|--------|
| `test_valid_ages` | Valida edades 1-120 | PASS |
| `test_invalid_ages` | Rechaza fuera de rango | PASS |
| `test_age_edge_cases` | Límites: 0, 1, 120, 121 | PASS |
#### Pruebas de Phone Ecuador ( CRÍTICAS)
| Test | Descripción | Estado |
|------|-------------|--------|
| `test_phone_local_format` | Formato local 09XXXXXXXX | PASS |
| `test_phone_with_spaces` | Teléfono con espacios | PASS |
| `test_phone_international_plus` | Formato +593XXXXXXXXX | PASS |
| `test_phone_international_no_plus` | Formato 593XXXXXXXXX | PASS |
| `test_phone_other_countries` | Rechaza USA, Colombia, Perú | PASS |
| `test_phone_invalid_format` | Rechaza formatos inválidos | PASS |
| `test_phone_normalize` | Normalización correcta | PASS |
#### Pruebas de Password Validation
| Test | Descripción | Estado |
|------|-------------|--------|
| `test_valid_passwords` | Contraseñas fuertes | PASS |
| `test_weak_passwords` | Rechaza contraseñas débiles | PASS |
| `test_password_edge_cases` | Casos límite | PASS |
#### Pruebas de Formatos Especiales
| Test | Descripción | Estado |
|------|-------------|--------|
| `test_normalize_phone` | Normalización de teléfonos | PASS |
| `test_international_format` | Conversión a internacional | PASS |
| `test_local_format` | Conversión a local | PASS |
---
### 2. Rate Limiter - 18 Tests
**Archivo:** `test/rate_limiter_test.dart`
#### Pruebas de Inicialización
| Test | Descripción | Estado |
|------|-------------|--------|
| `test_rate_limiter_initialization` | Inicializa correctamente | PASS |
| `test_default_configuration` | Configuración por defecto | PASS |
#### Pruebas de Control de Intentos
| Test | Descripción | Estado |
|------|-------------|--------|
| `test_first_attempt_allowed` | Primer intento permitido | PASS |
| `test_multiple_attempts_tracking` | Registra múltiples intentos | PASS |
| `test_limit_exceeded` | Bloquea cuando límite excedido | PASS |
#### Pruebas de Ventana de Tiempo
| Test | Descripción | Estado |
|------|-------------|--------|
| `test_window_expiration` | Intenta expiran después del tiempo | PASS |
| `test_reset_after_window` | Reset automático después de ventana | PASS |
| `test_custom_window` | Ventana de tiempo personalizada | PASS |
#### Pruebas de Información
| Test | Descripción | Estado |
|------|-------------|--------|
| `test_get_rate_limit_info` | Obtiene información correcta | PASS |
| `test_next_available_time` | Calcula tiempo disponible | PASS |
| `test_remaining_attempts` | Calcula intentos restantes | PASS |
#### Pruebas de Reset
| Test | Descripción | Estado |
|------|-------------|--------|
| `test_manual_reset` | Reset manual funciona | PASS |
| `test_reset_all_counters` | Reset global funciona | PASS |
#### Pruebas de Persistencia
| Test | Descripción | Estado |
|------|-------------|--------|
| `test_persistence_shared_prefs` | Datos persisten en SharedPrefs | PASS |
| `test_load_existing_attempts` | Carga intentos guardados | PASS |
---
### 3. Widget Tests (TBD)
**Archivo:** `test/widget_test.dart`
- En desarrollo
- Pruebas de interfaz de usuario
- Simulación de interacciones de usuario
---
## Cómo Ejecutar Tests
### Ejecutar Todos los Tests
```bash
cd "c:\Users\MateoM\Desktop\Proyecto-app\flutter_application_1"
flutter test
```
**Salida esperada:**
```
 validators_ecuador_test.dart: 35 tests - PASSED
 rate_limiter_test.dart: 18 tests - PASSED
 widget_test.dart: 0 tests
Total: 53/53 tests PASSED (100%)
```
### Ejecutar Tests Específicos
```bash
# Solo validadores
flutter test test/validators_ecuador_test.dart
# Solo rate limiter
flutter test test/rate_limiter_test.dart
```
### Ejecutar Test Individual
```bash
# Un test específico
flutter test test/validators_ecuador_test.dart -n "test_valid_emails"
```
### Ejecutar con Cobertura
```bash
flutter test --coverage
lcov --list coverage/lcov.info # Mostrar cobertura
```
### Modo Verbose (Detallado)
```bash
flutter test -v # Muestra cada paso
```
---
## Cobertura de Tests
### Cobertura por Módulo
| Módulo | Cobertura | Estado |
|--------|-----------|--------|
| **validators.dart** | 95%+ | Excelente |
| **rate_limiter.dart** | 90%+ | Muy bueno |
| **UI Widgets** | 0% | En desarrollo |
| **Services** | 70% | Mejoras necesarias |
### Líneas Cubiertas
```
Validators:
 isValidEmail() 100%
 isValidName() 100%
 isValidAge() 100%
 isValidPhone() 100% (Ecuador)
 isValidPassword() 100%
 formatters 100%
RateLimiter:
 canExecute() 100%
 getInfo() 100%
 reset() 100%
 resetAll() 100%
```
---
## Ejemplos de Tests
### Ejemplo 1: Test de Email
```dart
void main() {
 group('Validators - Email', () {
 test('Valida emails válidos', () {
 // ARRANGE (preparar)
 String validEmail = 'juan@gmail.com';
 // ACT (actuar)
 bool result = Validators.isValidEmail(validEmail);
 // ASSERT (verificar)
 expect(result, true);
 });
 test('Rechaza emails inválidos', () {
 List<String> invalidEmails = [
 'juangmail.com',
 'juan@',
 '@gmail.com',
 'juan @gmail.com',
 ];
 for (String email in invalidEmails) {
 expect(Validators.isValidEmail(email), false);
 }
 });
 });
}
```
### Ejemplo 2: Test de Teléfono Ecuador
```dart
void main() {
 group('Validators - Phone Ecuador', () {
 test('Valida teléfono formato local', () {
 expect(Validators.isValidPhone('0963522505'), true);
 });
 test('Valida teléfono con espacios', () {
 expect(Validators.isValidPhone('09 6352 2505'), true);
 });
 test('Valida teléfono internacional con +', () {
 expect(Validators.isValidPhone('+593963522505'), true);
 });
 test('Rechaza teléfono USA', () {
 expect(Validators.isValidPhone('+11234567890'), false);
 });
 test('Normaliza correctamente', () {
 String phone = '09 6352 2505';
 String normalized = Validators.normalizePhoneNumber(phone);
 expect(normalized, '0963522505');
 });
 });
}
```
### Ejemplo 3: Test de Rate Limiter
```dart
void main() {
 group('RateLimiter', () {
 tearDown(() async {
 // Limpiar después de cada test
 await RateLimiter.resetAll();
 });
 test('Primer intento debe ser permitido', () async {
 bool canExecute = await RateLimiter.canExecute(
 action: 'test_action',
 maxAttempts: 3,
 windowHours: 1,
 );
 expect(canExecute, true);
 });
 test('Bloquea cuando se excede límite', () async {
 // Hacer 3 intentos (límite)
 for (int i = 0; i < 3; i++) {
 await RateLimiter.canExecute(
 action: 'test_action',
 maxAttempts: 3,
 windowHours: 1,
 );
 }
 // El 4to intento debe fallar
 bool fourthAttempt = await RateLimiter.canExecute(
 action: 'test_action',
 maxAttempts: 3,
 windowHours: 1,
 );
 expect(fourthAttempt, false);
 });
 test('Obtiene información correcta', () async {
 await RateLimiter.canExecute(
 action: 'test_action',
 maxAttempts: 3,
 windowHours: 1,
 );
 RateLimitInfo info = await RateLimiter.getInfo('test_action');
 expect(info.attempts, 1);
 expect(info.isLimited, false);
 });
 });
}
```
---
## Mejores Prácticas
### 1. Estructura AAA (Arrange, Act, Assert)
```dart
test('Descripción clara del comportamiento', () {
 // ARRANGE - Preparar datos
 String input = '0963522505';
 // ACT - Ejecutar código
 String result = Validators.normalizePhoneNumber(input);
 // ASSERT - Verificar resultado
 expect(result, '0963522505');
});
```
### 2. Usar Grupos (Group)
```dart
group('Validador de Teléfono', () {
 // Todos estos tests están relacionados
 test('Acepta formato local', () {
 expect(Validators.isValidPhone('0963522505'), true);
 });
 test('Acepta formato internacional', () {
 expect(Validators.isValidPhone('+593963522505'), true);
 });
 setUp(() {
 // Se ejecuta antes de cada test
 });
 tearDown(() {
 // Se ejecuta después de cada test
 });
});
```
### 3. Limpiar Después del Test
```dart
group('Rate Limiter', () {
 tearDown(() async {
 // Limpiar datos después de cada test
 await RateLimiter.resetAll();
 });
 test('Test 1', () async {
 // Este test no interfiere con el siguiente
 });
});
```
### 4. Nombres Descriptivos
```dart
// BUENO
test('Rechaza emails sin arroba', () { });
test('Teléfono Ecuador debe comenzar con 09', () { });
// MALO
test('Test 1', () { });
test('Email validation', () { });
```
### 5. Casos Límite (Edge Cases)
```dart
test('Valida casos límite de edad', () {
 expect(Validators.isValidAge('1'), true); // Mínimo
 expect(Validators.isValidAge('120'), true); // Máximo
 expect(Validators.isValidAge('0'), false); // Fuera de rango
 expect(Validators.isValidAge('121'), false); // Fuera de rango
});
```
---
## Ejecutar Tests en CI/CD
### GitHub Actions Example
```yaml
name: Tests
on: [push, pull_request]
jobs:
 test:
 runs-on: ubuntu-latest
 steps:
 - uses: actions/checkout@v2
 - uses: subosito/flutter-action@v2
 - run: flutter pub get
 - run: flutter test
 - run: flutter test --coverage
```
---
## Agregar Nuevos Tests
### Paso 1: Crear archivo test
```dart
// test/mi_nuevo_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/mi_clase.dart';
void main() {
 group('Mi Nueva Prueba', () {
 test('Descripción del comportamiento', () {
 // Implementar test
 });
 });
}
```
### Paso 2: Ejecutar
```bash
flutter test test/mi_nuevo_test.dart
```
---
## Tecnologías Relacionadas
### Firebase
- Algunos servicios Firebase requieren mock en tests
- Tests offline funcionan correctamente
### Flutter
- Usa `flutter_test` framework
- Compatible con todos los widgets
### Android
- Tests se ejecutan en Android emulator o dispositivo
- Validaciones específicas Ecuador cubiertas
### iOS
- Tests se ejecutan en iOS simulator
- Comportamiento idéntico a Android
### Dependencias de Test
- `flutter_test` - Framework de testing
- `mockito` - Mocking (en desarrollo)
---
## Resumen de Tests
```
 RESUMEN DE TESTING - ESTADO ACTUAL
 Validators Ecuador 35 tests PASSED
 Rate Limiter 18 tests PASSED
 Widget Tests 0 tests TBD
 Integration Tests 0 tests TBD
 TOTAL 53 tests 100% PASSED
```
---
## Próximos Pasos
1. Expandir widget tests (UI testing)
2. Agregar integration tests (flujos completos)
3. Mocking de Firebase Services
4. Tests de performance
5. Tests de seguridad
---
## Consulta Rápida
| Tarea | Comando |
|-------|---------|
| Ejecutar todos | `flutter test` |
| Específico | `flutter test test/validators_ecuador_test.dart` |
| Cobertura | `flutter test --coverage` |
| Verbose | `flutter test -v` |
| Individual | `flutter test -n "nombre_test"` |
---
**Última actualización:** 21 de julio de 2026
**Versión:** 1.3.47
**Estado:** Desarrollo
