# Módulo de Validadores - Documentación Completa
**Última actualización:** 21 de julio de 2026  
**Versión:** 1.3.47  
**Estado:** Desarrollo
---
## Índice
1. [Descripción General](#descripción-general)
2. [Ubicación y Estructura](#ubicación-y-estructura)
3. [Validadores Disponibles](#validadores-disponibles)
4. [Ejemplos de Uso](#ejemplos-de-uso)
5. [Casos de Uso Ecuador](#casos-de-uso-ecuador)
6. [Testing](#testing)
7. [Integración](#integración)
---
## Descripción General
El módulo de validadores proporciona funciones centralizadas para validar datos de usuario. Está específicamente configurado para **Ecuador** con validación de teléfonos, cédulas y formatos locales.
**Ubicación:** `lib/validators/validators.dart`
**Líneas de código:** 180+
**Funciones:** 8 principales
**Estado:** Completo y testeado
### Características Principales
- Validación específica para Ecuador
- Manejo de múltiples formatos
- Normalización automática de datos
- Mensajes de error en español
- 35+ tests unitarios
- Sin dependencias externas (solo dart:core)
---
## Ubicación y Estructura
### Ruta de Archivo
```
lib/
 validators/
 validators.dart
```
### Clase Principal
```dart
class Validators {
 // Constantes
 static const String ecuadorCountryCode = '+593';
 static const String ecuadorCountryPrefix = '593';
 // Métodos estáticos (sin necesidad de instanciar)
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
#### Función
```dart
static bool isValidEmail(String email)
```
#### Descripción
Valida direcciones de correo electrónico con formato estándar internacional.
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
// Válido
Validators.isValidEmail('juan@gmail.com'); // true
Validators.isValidEmail('maria.garcia@hotmail.com'); // true
// Inválido
Validators.isValidEmail('juangmail.com'); // false
Validators.isValidEmail('juan@'); // false
```
#### Regex Usado
```regex
^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$
```
---
### 2. Name Validation
#### Función
```dart
static bool isValidName(String name)
```
#### Descripción
Valida nombres que solo contengan letras (incluyendo acentos) y espacios.
#### Caracteres Permitidos
```
 A-Z, a-z
 Acentos: á, é, í, ó, ú, Á, É, Í, Ó, Ú
 Eñes: ñ, Ñ
 Espacios simples
 Caracteres especiales alemanes: ü, Ü
```
#### Caracteres Rechazados
```
 Números (0-9)
 Guiones
 Puntos
 Símbolos especiales (@, #, $, etc)
```
#### Ejemplo
```dart
// Válido
Validators.isValidName('Juan García'); // true
Validators.isValidName('María José López'); // true
Validators.isValidName('José María'); // true
Validators.isValidName('Ñandú'); // true
// Inválido
Validators.isValidName('Juan123'); // false
Validators.isValidName('Juan-Pablo'); // false
Validators.isValidName('María.García'); // false
Validators.isValidName('123'); // false
```
#### Regex Usado
```regex
^[A-Za-záéíóúÁÉÍÓÚüÜñÑ\s]+$
```
---
### 3. Age Validation
#### Función
```dart
static bool isValidAge(String age)
```
#### Descripción
Valida edad como número entre 1 y 120 años.
#### Rango Válido
```
1 - 120 años
```
#### Ejemplo
```dart
// Válido
Validators.isValidAge('25'); // true
Validators.isValidAge('1'); // true (recién nacido)
Validators.isValidAge('120'); // true (máximo permitido)
// Inválido
Validators.isValidAge('0'); // false (menor que 1)
Validators.isValidAge('121'); // false (mayor que 120)
Validators.isValidAge('-5'); // false (negativo)
Validators.isValidAge('abc'); // false (no es número)
```
---
### 4. Phone Validation (Ecuador Específico)
#### Función
```dart
static bool isValidPhone(String phone)
```
#### Descripción
**Valida teléfonos móviles de Ecuador únicamente.** Este es el validador más importante para el proyecto.
#### Características de Ecuador
Los números móviles en Ecuador tienen 10 dígitos:
- **Formato local:** Comienzan con `09`
- **Formato internacional:** Código `+593` o `593`
- **Rango válido:** 0960000000 - 0999999999
#### Formatos Aceptados
```dart
// Formato local (10 dígitos)
Validators.isValidPhone('0963522505'); // true
// Formato local con espacios
Validators.isValidPhone('09 6352 2505'); // true
Validators.isValidPhone('09-6352-2505'); // true
Validators.isValidPhone('09.6352.2505'); // true
// Formato internacional SIN +
Validators.isValidPhone('593963522505'); // true
Validators.isValidPhone('593 963 522 505'); // true
// Formato internacional CON +
Validators.isValidPhone('+593963522505'); // true
Validators.isValidPhone('+593 963 522 505'); // true
```
#### Formatos Rechazados
```dart
// Otros países
Validators.isValidPhone('+11234567890'); // false (USA)
Validators.isValidPhone('+573105555555'); // false (Colombia)
Validators.isValidPhone('+51987654321'); // false (Perú)
// Formato incorrecto para Ecuador
Validators.isValidPhone('08XXXXXXXX'); // false (comienza con 08)
Validators.isValidPhone('07XXXXXXXX'); // false (comienza con 07)
Validators.isValidPhone('963522505'); // false (9 dígitos)
Validators.isValidPhone('09635225051'); // false (11 dígitos)
// Formato local inválido
Validators.isValidPhone('0263522505'); // false (no es móvil)
Validators.isValidPhone('0563522505'); // false (no es móvil)
```
#### Ejemplo Completo
```dart
// Validar teléfono ingresado por usuario
String phone = '09 6352 2505';
if (Validators.isValidPhone(phone)) {
 // Proceder a guardar
 print('Teléfono Ecuador válido');
} else {
 // Mostrar error
 print('El teléfono debe ser un número móvil de Ecuador');
}
```
---
### 5. Password Validation
#### Función
```dart
static bool isValidPassword(String password)
```
#### Descripción
Valida contraseñas con requisitos de seguridad mínimos.
#### Requisitos
| Requisito | Descripción |
|-----------|-------------|
| **Longitud** | Mínimo 8 caracteres |
| **Mayúscula** | Al menos 1 letra mayúscula (A-Z) |
| **Minúscula** | Al menos 1 letra minúscula (a-z) |
| **Número** | Al menos 1 dígito (0-9) |
| **Especial** | Al menos 1 carácter especial (!@#$%^&*) |
#### Ejemplo
```dart
// Válido
Validators.isValidPassword('MyPass123!'); // true
Validators.isValidPassword('Secure@2025Pass'); // true
Validators.isValidPassword('Complex#Pass99'); // true
// Inválido
Validators.isValidPassword('mypass123'); // false (sin mayúscula)
Validators.isValidPassword('MYPASS123'); // false (sin minúscula)
Validators.isValidPassword('MyPassword'); // false (sin número)
Validators.isValidPassword('MyPass123'); // false (sin especial)
Validators.isValidPassword('Short@1'); // false (menos de 8)
```
---
### 6. Phone Normalization
#### Función
```dart
static String normalizePhoneNumber(String phone)
```
#### Descripción
Convierte cualquier formato de teléfono Ecuador a formato local estándar (09XXXXXXXX).
#### Ejemplo
```dart
// Todos estos retornan: "0963522505"
Validators.normalizePhoneNumber('09 6352 2505'); // "0963522505"
Validators.normalizePhoneNumber('09-6352-2505'); // "0963522505"
Validators.normalizePhoneNumber('+593963522505'); // "0963522505"
Validators.normalizePhoneNumber('593963522505'); // "0963522505"
Validators.normalizePhoneNumber('0963522505'); // "0963522505"
```
#### Uso Práctico
```dart
// Guardar teléfono normalizado en base de datos
String userPhone = '+593 963 522 505';
String normalized = Validators.normalizePhoneNumber(userPhone);
// normalized = "0963522505"
await SecureStorageService.saveEmergencyContact(normalized);
```
---
### 7. International Format
#### Función
```dart
static String getInternationalFormat(String phone)
```
#### Descripción
Convierte teléfono Ecuador a formato internacional con código de país.
#### Ejemplo
```dart
// Todas estas retornan: "+593963522505"
Validators.getInternationalFormat('09 6352 2505'); // "+593963522505"
Validators.getInternationalFormat('0963522505'); // "+593963522505"
Validators.getInternationalFormat('593963522505'); // "+593963522505"
```
#### Uso Práctico
```dart
// Para llamadas internacionales o WhatsApp
String phone = '0963522505';
String international = Validators.getInternationalFormat(phone);
// international = "+593963522505"
// Realizar llamada internacional
String url = 'tel:$international';
await launchUrl(Uri.parse(url));
```
---
### 8. Local Format
#### Función
```dart
static String getLocalFormat(String phone)
```
#### Descripción
Convierte cualquier formato a formato local de Ecuador (09XXXXXXXX).
#### Ejemplo
```dart
// Todas retornan: "0963522505"
Validators.getLocalFormat('+593963522505'); // "0963522505"
Validators.getLocalFormat('593963522505'); // "0963522505"
Validators.getLocalFormat('09 6352 2505'); // "0963522505"
```
---
## Ejemplos de Uso
### Caso 1: Validar en Campo de Entrada
```dart
class SenttingsPage extends StatefulWidget {
 @override
 State<SenttingsPage> createState() => _SenttingsPageState();
}
class _SenttingsPageState extends State<SenttingsPage> {
 final TextEditingController phoneController = TextEditingController();
 String? errorMessage;
 void _validatePhone() {
 String phone = phoneController.text;
 if (phone.isEmpty) {
 setState(() => errorMessage = 'El teléfono es obligatorio');
 return;
 }
 if (!Validators.isValidPhone(phone)) {
 setState(() => errorMessage =
 'Ingrese un teléfono móvil válido de Ecuador (Ej: 0963522505)');
 return;
 }
 // Teléfono válido, proceder
 setState(() => errorMessage = null);
 String normalized = Validators.normalizePhoneNumber(phone);
 _savePhoneSecurely(normalized);
 }
 @override
 Widget build(BuildContext context) {
 return TextField(
 controller: phoneController,
 decoration: InputDecoration(
 labelText: 'Teléfono',
 errorText: errorMessage,
 hintText: 'Ej: 09 6352 2505',
 ),
 onChanged: (_) => _validatePhone(),
 );
 }
}
```
### Caso 2: Validar Múltiples Campos
```dart
bool validateAllFields(
 String name,
 String email,
 String age,
 String phone,
) {
 List<String> errors = [];
 if (!Validators.isValidName(name)) {
 errors.add('Nombre inválido');
 }
 if (!Validators.isValidEmail(email)) {
 errors.add('Email inválido');
 }
 if (!Validators.isValidAge(age)) {
 errors.add('Edad debe estar entre 1 y 120');
 }
 if (!Validators.isValidPhone(phone)) {
 errors.add('Teléfono Ecuador inválido');
 }
 if (errors.isNotEmpty) {
 print('Errores encontrados: ${errors.join(", ")}');
 return false;
 }
 return true;
}
```
### Caso 3: Transformar Datos
```dart
// Guardar teléfono en diferentes formatos según necesidad
String phone = '+593 963 522 505';
String local = Validators.getLocalFormat(phone);
// local = "0963522505" (para guardado)
String international = Validators.getInternationalFormat(phone);
// international = "+593963522505" (para llamadas)
// Guardar formato local
await SecureStorageService.saveEmergencyContact(local);
// Usar formato internacional para llamada
await launchUrl(Uri.parse('tel:$international'));
```
---
## Casos de Uso Ecuador
### Escenario 1: Usuario Ingresa Teléfono en Senttings
```dart
// Usuario ingresa: "09 6352 2505"
String userInput = "09 6352 2505";
// Paso 1: Validar
if (!Validators.isValidPhone(userInput)) {
 showError('Teléfono Ecuador inválido');
 return;
}
// Paso 2: Normalizar
String normalized = Validators.normalizePhoneNumber(userInput);
// normalized = "0963522505"
// Paso 3: Guardar
await SecureStorageService.saveEmergencyContact(normalized);
```
### Escenario 2: Mostrar Teléfono Guardado
```dart
// Recuperar del storage
String? phone = await SecureStorageService.getEmergencyContact();
// phone = "0963522505"
// Para mostrar en UI (formato legible)
String display = "${phone?.substring(0, 2)} ${phone?.substring(2, 5)} "
 "${phone?.substring(5, 8)} ${phone?.substring(8)}";
// display = "09 635 225 05"
// Para llamar (formato internacional)
String callFormat = Validators.getInternationalFormat(phone);
// callFormat = "+593963522505"
```
### Escenario 3: Validación en Formulario
```dart
class RegistrationForm extends StatefulWidget {
 @override
 State<RegistrationForm> createState() => _RegistrationFormState();
}
class _RegistrationFormState extends State<RegistrationForm> {
 final _formKey = GlobalKey<FormState>();
 String? validatePhone(String? value) {
 if (value == null || value.isEmpty) {
 return 'Teléfono requerido';
 }
 if (!Validators.isValidPhone(value)) {
 return 'Teléfono móvil de Ecuador inválido';
 }
 return null; // Válido
 }
 String? validateEmail(String? value) {
 if (value == null || value.isEmpty) {
 return 'Email requerido';
 }
 if (!Validators.isValidEmail(value)) {
 return 'Email inválido';
 }
 return null;
 }
 @override
 Widget build(BuildContext context) {
 return Form(
 key: _formKey,
 child: Column(
 children: [
 TextFormField(
 decoration: InputDecoration(labelText: 'Teléfono'),
 validator: validatePhone,
 ),
 TextFormField(
 decoration: InputDecoration(labelText: 'Email'),
 validator: validateEmail,
 ),
 ElevatedButton(
 onPressed: () {
 if (_formKey.currentState!.validate()) {
 print('Formulario válido');
 }
 },
 child: Text('Enviar'),
 ),
 ],
 ),
 );
 }
}
```
---
## Testing
### Tests Unitarios
Ubicación: `test/validators_ecuador_test.dart`
**Total de tests:** 35 **TODOS PASANDO**
### Ejemplos de Tests
```dart
void main() {
 group('Validators - Email', () {
 test('Valida emails correctos', () {
 expect(Validators.isValidEmail('juan@gmail.com'), true);
 expect(Validators.isValidEmail('maria.garcia@hotmail.com'), true);
 });
 test('Rechaza emails incorrectos', () {
 expect(Validators.isValidEmail('juangmail.com'), false);
 expect(Validators.isValidEmail('juan@'), false);
 });
 });
 group('Validators - Phone Ecuador', () {
 test('Valida formato local', () {
 expect(Validators.isValidPhone('0963522505'), true);
 });
 test('Valida formato con espacios', () {
 expect(Validators.isValidPhone('09 6352 2505'), true);
 });
 test('Valida formato internacional', () {
 expect(Validators.isValidPhone('+593963522505'), true);
 });
 test('Rechaza otros países', () {
 expect(Validators.isValidPhone('+11234567890'), false);
 });
 });
}
```
### Ejecutar Tests
```bash
cd "c:\Users\MateoM\Desktop\Proyecto-app\flutter_application_1"
flutter test test/validators_ecuador_test.dart
```
---
## Integración
### Integración en main.dart
```dart
import 'validators/validators.dart';
// En InicioPage
void _setupUser() {
 // Validar teléfono antes de guardar
 String userPhone = '09 6352 2505';
 if (Validators.isValidPhone(userPhone)) {
 String normalized = Validators.normalizePhoneNumber(userPhone);
 _savePhoneLocally(normalized);
 }
}
```
### Integración en senttings.dart
```dart
import 'validators/validators.dart';
import 'services/secure_storage_service.dart';
// En el diálogo de guardar contacto
Future<void> _saveEmergencyContact() async {
 String phone = phoneController.text;
 // Validar
 if (!Validators.isValidPhone(phone)) {
 _showError('Teléfono Ecuador inválido');
 return;
 }
 // Normalizar
 String normalized = Validators.normalizePhoneNumber(phone);
 // Guardar de forma segura
 await SecureStorageService.saveEmergencyContact(normalized);
 _showSuccess('Contacto guardado');
}
```
### Integración en options.dart
```dart
// Para validar datos médicos
if (!Validators.isValidName(doctorName)) {
 _showError('Nombre inválido');
 return;
}
if (!Validators.isValidEmail(doctorEmail)) {
 _showError('Email inválido');
 return;
}
```
---
## Referencia Rápida
| Función | Entrada | Salida | Ecuador |
|---------|---------|--------|---------|
| `isValidEmail(e)` | string | bool | |
| `isValidName(n)` | string | bool | |
| `isValidAge(a)` | string | bool | |
| `isValidPhone(p)` | string | bool | |
| `isValidPassword(pw)` | string | bool | |
| `normalizePhoneNumber(p)` | string | string | |
| `getInternationalFormat(p)` | string | string | |
| `getLocalFormat(p)` | string | string | |
---
## Tecnologías Relacionadas
### Firebase
- No requiere Firebase directamente
- Validadores se usan antes de enviar a Firebase
### Flutter
- Usa solo `dart:core` y expresiones regulares
- Compatible con todos los widgets
### Android
- Compatible con números móviles Android de Ecuador
- Validación de permisos de teléfono
### iOS
- Compatible con números móviles iOS de Ecuador
### Dependencias
- **phone_numbers_parser** - Para análisis avanzado de teléfonos
- No requiere otras dependencias
---
## Checklist de Implementación
- Clase Validators creada
- 8 métodos implementados
- Específico para Ecuador
- Comentarios en español
- 35 tests unitarios
- Documentación completa
- Integrado en main.dart
- Integrado en senttings.dart
- Ejemplos de uso incluidos
---
## Próximos Pasos
1. Para integración con servicios: Ver `04_ARCHIVOS_SERVICIOS.md`
2. Para archivos principales: Ver `01_ARCHIVOS_PRINCIPALES.md`
3. Para permisos requeridos: Ver `05_PERMISOS_REQUERIDOS.md`
4. Para ver ejemplos vivos: Abrir `lib/EJEMPLOS_FASE_1.dart`
---
**Última actualización:** 21 de julio de 2026  
**Versión:** 1.3.47  
**Estado:** Desarrollo
