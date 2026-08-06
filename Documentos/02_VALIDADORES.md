# M�dulo de Validadores - Documentaci�n Completa
**�ltima actualizaci�n:** 21 de julio de 2026  
**Versi�n:** 1.4.60  
**Estado:** Desarrollo
---
## �ndice
1. [Descripci�n General](#descripci�n-general)
2. [Ubicaci�n y Estructura](#ubicaci�n-y-estructura)
3. [Validadores Disponibles](#validadores-disponibles)
4. [Ejemplos de Uso](#ejemplos-de-uso)
5. [Casos de Uso Ecuador](#casos-de-uso-ecuador)
6. [Testing](#testing)
7. [Integraci�n](#integraci�n)
---
## Descripci�n General
El m�dulo de validadores proporciona funciones centralizadas para validar datos de usuario. Est� espec�ficamente configurado para **Ecuador** con validaci�n de tel�fonos, c�dulas y formatos locales.
**Ubicaci�n:** `lib/validators/validators.dart`
**L�neas de c�digo:** 180+
**Funciones:** 8 principales
**Estado:** Completo y testeado
### Caracter�sticas Principales
- Validaci�n espec�fica para Ecuador
- Manejo de m�ltiples formatos
- Normalizaci�n autom�tica de datos
- Mensajes de error en espa�ol
- 35+ tests unitarios
- Sin dependencias externas (solo dart:core)
---
## Ubicaci�n y Estructura
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
 // M�todos est�ticos (sin necesidad de instanciar)
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
#### Funci�n
```dart
static bool isValidEmail(String email)
```
#### Descripci�n
Valida direcciones de correo electr�nico con formato est�ndar internacional.
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
// V�lido
Validators.isValidEmail('juan@gmail.com'); // true
Validators.isValidEmail('maria.garcia@hotmail.com'); // true
// Inv�lido
Validators.isValidEmail('juangmail.com'); // false
Validators.isValidEmail('juan@'); // false
```
#### Regex Usado
```regex
^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$
```
---
### 2. Name Validation
#### Funci�n
```dart
static bool isValidName(String name)
```
#### Descripci�n
Valida nombres que solo contengan letras (incluyendo acentos) y espacios.
#### Caracteres Permitidos
```
 A-Z, a-z
 Acentos: �, �, �, �, �, �, �, �, �, �
 E�es: �, �
 Espacios simples
 Caracteres especiales alemanes: �, �
```
#### Caracteres Rechazados
```
 N�meros (0-9)
 Guiones
 Puntos
 S�mbolos especiales (@, #, $, etc)
```
#### Ejemplo
```dart
// V�lido
Validators.isValidName('Juan Garc�a'); // true
Validators.isValidName('Mar�a Jos� L�pez'); // true
Validators.isValidName('Jos� Mar�a'); // true
Validators.isValidName('�and�'); // true
// Inv�lido
Validators.isValidName('Juan123'); // false
Validators.isValidName('Juan-Pablo'); // false
Validators.isValidName('Mar�a.Garc�a'); // false
Validators.isValidName('123'); // false
```
#### Regex Usado
```regex
^[A-Za-z��������������\s]+$
```
---
### 3. Age Validation
#### Funci�n
```dart
static bool isValidAge(String age)
```
#### Descripci�n
Valida edad como n�mero entre 1 y 120 a�os.
#### Rango V�lido
```
1 - 120 a�os
```
#### Ejemplo
```dart
// V�lido
Validators.isValidAge('25'); // true
Validators.isValidAge('1'); // true (reci�n nacido)
Validators.isValidAge('120'); // true (m�ximo permitido)
// Inv�lido
Validators.isValidAge('0'); // false (menor que 1)
Validators.isValidAge('121'); // false (mayor que 120)
Validators.isValidAge('-5'); // false (negativo)
Validators.isValidAge('abc'); // false (no es n�mero)
```
---
### 4. Phone Validation (Ecuador Espec�fico)
#### Funci�n
```dart
static bool isValidPhone(String phone)
```
#### Descripci�n
**Valida tel�fonos m�viles de Ecuador �nicamente.** Este es el validador m�s importante para el proyecto.
#### Caracter�sticas de Ecuador
Los n�meros m�viles en Ecuador tienen 10 d�gitos:
- **Formato local:** Comienzan con `09`
- **Formato internacional:** C�digo `+593` o `593`
- **Rango v�lido:** 0960000000 - 0999999999
#### Formatos Aceptados
```dart
// Formato local (10 d�gitos)
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
// Otros pa�ses
Validators.isValidPhone('+11234567890'); // false (USA)
Validators.isValidPhone('+573105555555'); // false (Colombia)
Validators.isValidPhone('+51987654321'); // false (Per�)
// Formato incorrecto para Ecuador
Validators.isValidPhone('08XXXXXXXX'); // false (comienza con 08)
Validators.isValidPhone('07XXXXXXXX'); // false (comienza con 07)
Validators.isValidPhone('963522505'); // false (9 d�gitos)
Validators.isValidPhone('09635225051'); // false (11 d�gitos)
// Formato local inv�lido
Validators.isValidPhone('0263522505'); // false (no es m�vil)
Validators.isValidPhone('0563522505'); // false (no es m�vil)
```
#### Ejemplo Completo
```dart
// Validar tel�fono ingresado por usuario
String phone = '09 6352 2505';
if (Validators.isValidPhone(phone)) {
 // Proceder a guardar
 print('Tel�fono Ecuador v�lido');
} else {
 // Mostrar error
 print('El tel�fono debe ser un n�mero m�vil de Ecuador');
}
```
---
### 5. Password Validation
#### Funci�n
```dart
static bool isValidPassword(String password)
```
#### Descripci�n
Valida contrase�as con requisitos de seguridad m�nimos.
#### Requisitos
| Requisito | Descripci�n |
|-----------|-------------|
| **Longitud** | M�nimo 8 caracteres |
| **May�scula** | Al menos 1 letra may�scula (A-Z) |
| **Min�scula** | Al menos 1 letra min�scula (a-z) |
| **N�mero** | Al menos 1 d�gito (0-9) |
| **Especial** | Al menos 1 car�cter especial (!@#$%^&*) |
#### Ejemplo
```dart
// V�lido
Validators.isValidPassword('MyPass123!'); // true
Validators.isValidPassword('Secure@2025Pass'); // true
Validators.isValidPassword('Complex#Pass99'); // true
// Inv�lido
Validators.isValidPassword('mypass123'); // false (sin may�scula)
Validators.isValidPassword('MYPASS123'); // false (sin min�scula)
Validators.isValidPassword('MyPassword'); // false (sin n�mero)
Validators.isValidPassword('MyPass123'); // false (sin especial)
Validators.isValidPassword('Short@1'); // false (menos de 8)
```
---
### 6. Phone Normalization
#### Funci�n
```dart
static String normalizePhoneNumber(String phone)
```
#### Descripci�n
Convierte cualquier formato de tel�fono Ecuador a formato local est�ndar (09XXXXXXXX).
#### Ejemplo
```dart
// Todos estos retornan: "0963522505"
Validators.normalizePhoneNumber('09 6352 2505'); // "0963522505"
Validators.normalizePhoneNumber('09-6352-2505'); // "0963522505"
Validators.normalizePhoneNumber('+593963522505'); // "0963522505"
Validators.normalizePhoneNumber('593963522505'); // "0963522505"
Validators.normalizePhoneNumber('0963522505'); // "0963522505"
```
#### Uso Pr�ctico
```dart
// Guardar tel�fono normalizado en base de datos
String userPhone = '+593 963 522 505';
String normalized = Validators.normalizePhoneNumber(userPhone);
// normalized = "0963522505"
await SecureStorageService.saveEmergencyContact(normalized);
```
---
### 7. International Format
#### Funci�n
```dart
static String getInternationalFormat(String phone)
```
#### Descripci�n
Convierte tel�fono Ecuador a formato internacional con c�digo de pa�s.
#### Ejemplo
```dart
// Todas estas retornan: "+593963522505"
Validators.getInternationalFormat('09 6352 2505'); // "+593963522505"
Validators.getInternationalFormat('0963522505'); // "+593963522505"
Validators.getInternationalFormat('593963522505'); // "+593963522505"
```
#### Uso Pr�ctico
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
#### Funci�n
```dart
static String getLocalFormat(String phone)
```
#### Descripci�n
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
 setState(() => errorMessage = 'El tel�fono es obligatorio');
 return;
 }
 if (!Validators.isValidPhone(phone)) {
 setState(() => errorMessage =
 'Ingrese un tel�fono m�vil v�lido de Ecuador (Ej: 0963522505)');
 return;
 }
 // Tel�fono v�lido, proceder
 setState(() => errorMessage = null);
 String normalized = Validators.normalizePhoneNumber(phone);
 _savePhoneSecurely(normalized);
 }
 @override
 Widget build(BuildContext context) {
 return TextField(
 controller: phoneController,
 decoration: InputDecoration(
 labelText: 'Tel�fono',
 errorText: errorMessage,
 hintText: 'Ej: 09 6352 2505',
 ),
 onChanged: (_) => _validatePhone(),
 );
 }
}
```
### Caso 2: Validar M�ltiples Campos
```dart
bool validateAllFields(
 String name,
 String email,
 String age,
 String phone,
) {
 List<String> errors = [];
 if (!Validators.isValidName(name)) {
 errors.add('Nombre inv�lido');
 }
 if (!Validators.isValidEmail(email)) {
 errors.add('Email inv�lido');
 }
 if (!Validators.isValidAge(age)) {
 errors.add('Edad debe estar entre 1 y 120');
 }
 if (!Validators.isValidPhone(phone)) {
 errors.add('Tel�fono Ecuador inv�lido');
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
// Guardar tel�fono en diferentes formatos seg�n necesidad
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
### Escenario 1: Usuario Ingresa Tel�fono en Senttings
```dart
// Usuario ingresa: "09 6352 2505"
String userInput = "09 6352 2505";
// Paso 1: Validar
if (!Validators.isValidPhone(userInput)) {
 showError('Tel�fono Ecuador inv�lido');
 return;
}
// Paso 2: Normalizar
String normalized = Validators.normalizePhoneNumber(userInput);
// normalized = "0963522505"
// Paso 3: Guardar
await SecureStorageService.saveEmergencyContact(normalized);
```
### Escenario 2: Mostrar Tel�fono Guardado
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
### Escenario 3: Validaci�n en Formulario
```dart
class RegistrationForm extends StatefulWidget {
 @override
 State<RegistrationForm> createState() => _RegistrationFormState();
}
class _RegistrationFormState extends State<RegistrationForm> {
 final _formKey = GlobalKey<FormState>();
 String? validatePhone(String? value) {
 if (value == null || value.isEmpty) {
 return 'Tel�fono requerido';
 }
 if (!Validators.isValidPhone(value)) {
 return 'Tel�fono m�vil de Ecuador inv�lido';
 }
 return null; // V�lido
 }
 String? validateEmail(String? value) {
 if (value == null || value.isEmpty) {
 return 'Email requerido';
 }
 if (!Validators.isValidEmail(value)) {
 return 'Email inv�lido';
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
 decoration: InputDecoration(labelText: 'Tel�fono'),
 validator: validatePhone,
 ),
 TextFormField(
 decoration: InputDecoration(labelText: 'Email'),
 validator: validateEmail,
 ),
 ElevatedButton(
 onPressed: () {
 if (_formKey.currentState!.validate()) {
 print('Formulario v�lido');
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
Ubicaci�n: `test/validators_ecuador_test.dart`
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
 test('Rechaza otros pa�ses', () {
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
## Integraci�n
### Integraci�n en main.dart
```dart
import 'validators/validators.dart';
// En InicioPage
void _setupUser() {
 // Validar tel�fono antes de guardar
 String userPhone = '09 6352 2505';
 if (Validators.isValidPhone(userPhone)) {
 String normalized = Validators.normalizePhoneNumber(userPhone);
 _savePhoneLocally(normalized);
 }
}
```
### Integraci�n en senttings.dart
```dart
import 'validators/validators.dart';
import 'services/secure_storage_service.dart';
// En el di�logo de guardar contacto
Future<void> _saveEmergencyContact() async {
 String phone = phoneController.text;
 // Validar
 if (!Validators.isValidPhone(phone)) {
 _showError('Tel�fono Ecuador inv�lido');
 return;
 }
 // Normalizar
 String normalized = Validators.normalizePhoneNumber(phone);
 // Guardar de forma segura
 await SecureStorageService.saveEmergencyContact(normalized);
 _showSuccess('Contacto guardado');
}
```
### Integraci�n en options.dart
```dart
// Para validar datos m�dicos
if (!Validators.isValidName(doctorName)) {
 _showError('Nombre inv�lido');
 return;
}
if (!Validators.isValidEmail(doctorEmail)) {
 _showError('Email inv�lido');
 return;
}
```
---
## Referencia R�pida
| Funci�n | Entrada | Salida | Ecuador |
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
## Tecnolog�as Relacionadas
### Firebase
- No requiere Firebase directamente
- Validadores se usan antes de enviar a Firebase
### Flutter
- Usa solo `dart:core` y expresiones regulares
- Compatible con todos los widgets
### Android
- Compatible con n�meros m�viles Android de Ecuador
- Validaci�n de permisos de tel�fono
### iOS
- Compatible con n�meros m�viles iOS de Ecuador
### Dependencias
- **phone_numbers_parser** - Para an�lisis avanzado de tel�fonos
- No requiere otras dependencias
---
## Checklist de Implementaci�n
- Clase Validators creada
- 8 m�todos implementados
- Espec�fico para Ecuador
- Comentarios en espa�ol
- 35 tests unitarios
- Documentaci�n completa
- Integrado en main.dart
- Integrado en senttings.dart
- Ejemplos de uso incluidos
---
## Pr�ximos Pasos
1. Para integraci�n con servicios: Ver `04_ARCHIVOS_SERVICIOS.md`
2. Para archivos principales: Ver `01_ARCHIVOS_PRINCIPALES.md`
3. Para permisos requeridos: Ver `05_PERMISOS_REQUERIDOS.md`
4. Para ver ejemplos vivos: Abrir `lib/EJEMPLOS_FASE_1.dart`
---
**�ltima actualizaci�n:** 21 de julio de 2026  
**Versi�n:** 1.4.60  
**Estado:** Desarrollo

