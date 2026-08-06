# Archivos Principales de la Aplicaci�n
**�ltima actualizaci�n:** 6 de agosto de 2026  
**Versi�n:** 1.4.60  
**Estado:** Desarrollo (Estructura Reorganizada)

IMPORTANTE: A partir del 6 de agosto de 2026, la estructura del directorio `lib/` ha sido reorganizada. Ver [11_ESTRUCTURA_DIRECTORIO.md](11_ESTRUCTURA_DIRECTORIO.md) para detalles.

---
## �ndice
1. [Descripci�n General](#descripci�n-general)
2. [Cambios de Estructura](#cambios-de-estructura)
3. [Archivo main.dart](#archivo-maindart)
4. [Archivo settings_page.dart](#archivo-settings_pagedart-anteriormente-senttingsdart)
5. [Archivo options_page.dart](#archivo-options_pagedart)
6. [Archivo documents_page.dart](#archivo-documents_pagedart)
7. [Archivo symptoms_page.dart](#archivo-symptoms_pagedart)
8. [Archivo preferences.dart](#archivo-preferencesdart)
9. [Tabla Comparativa](#tabla-comparativa)
---
## Descripci�n General
Los archivos principales son las **p�ginas/pantallas** de la aplicaci�n Flutter. Cada uno corresponde a una secci�n espec�fica de la interfaz de usuario y maneja:
- L�gica de presentaci�n (UI)
- Interacci�n con el usuario
- Comunicaci�n con servicios
- Gesti�n de estado local

**Localizaci�n:** `lib/screens/` (tras reorganizaci�n del 6 de agosto)

---
## Cambios de Estructura

### Reorganizaci�n Realizada (6 de Agosto de 2026)

La carpeta `lib/` ha sido reorganizada en subcarpetas tem�ticas para mejorar la mantenibilidad:

| Archivo Anterior | Nueva Ubicaci�n | Nuevo Nombre |
|------------------|-----------------|--------------|
| `lib/main.dart` | `lib/` | `main.dart` (sin cambios) |
| `lib/senttings.dart` | `lib/screens/` | `settings_page.dart` |
| `lib/options.dart` | `lib/screens/` | `options_page.dart` |
| `lib/documents.dart` | `lib/screens/` | `documents_page.dart` |
| `lib/symptoms.dart` | `lib/screens/` | `symptoms_page.dart` |
| `lib/tutorial_screen.dart` | `lib/screens/` | `tutorial_screen.dart` |
| `lib/preferences.dart` | `lib/utils/` | `preferences.dart` |
| `lib/validators/` | `lib/utils/` | `validators/` |

###  Nueva Estructura de Directorios

```
lib/
+-- main.dart
+-- screens/              ? Todas las pantallas UI
�   +-- settings_page.dart
�   +-- options_page.dart
�   +-- documents_page.dart
�   +-- symptoms_page.dart
�   +-- tutorial_screen.dart
+-- services/            ? L�gica de negocio (ya exist�a)
�   +-- firebase_service.dart
�   +-- alert_service.dart
�   +-- ...
+-- utils/               ? Utilidades
�   +-- preferences.dart
�   +-- validators/
�       +-- validators.dart
+-- examples/            ? Ejemplos de c�digo
�   +-- ejemplos_ecuador.dart
�   +-- ejemplos_fase_1.dart
�   +-- ejemplos_fase_3.dart
+-- testing/             ? Pruebas (ya exist�a)
�   +-- ...
+-- models/              ? Reservado para modelos
```

### Beneficios

- [OK] **Mejor organizaci�n:** Cada tipo de archivo tiene su lugar
- [OK] **Escalabilidad:** F�cil agregar nuevas pantallas
- [OK] **Mantenibilidad:** Estructura clara y predecible
- [OK] **Importaciones claras:** Rutas relativas indican la relaci�n entre archivos

### ?? Documentaci�n Completa

Para ver la estructura completa y detallada, consulta: [11_ESTRUCTURA_DIRECTORIO.md](11_ESTRUCTURA_DIRECTORIO.md)

---
## Archivo: main.dart
### Informaci�n General
| Atributo | Valor |
|----------|-------|
| **Ubicaci�n** | `lib/main.dart` |
| **L�neas de c�digo** | ~800 |
| **Responsabilidad** | P�gina principal, punto de entrada, bot�n de p�nico |
| **Tipo de Widget** | StatefulWidget |
### Funcionalidades Principales
#### 1. **Bot�n de P�nico**
```dart
// Mantener presionado por 1.2 segundos para activar
// - Verifica rate limiting (m�ximo 3 intentos en 3 horas)
// - Obtiene ubicaci�n GPS actual
// - Crea alerta en Firebase Database
// - Realiza llamada telef�nica
// - Muestra indicador visual de intentos restantes
```
#### 2. **Obtenci�n de Ubicaci�n**
```dart
// Solicita permisos de ubicaci�n
// Obtiene coordenadas GPS (latitud, longitud)
// Convierte coordenadas a direcci�n legible
// Usa: geolocator + geocoding
```
#### 3. **Indicador de Intentos**
```dart
// Muestra intentos restantes: X/3
// Se actualiza en tiempo real
// Colores seg�n disponibilidad (verde/amarillo/rojo)
```
#### 4. **Integraci�n Firebase**
```dart
// - Registra evento "emergency_activated"
// - Crea documento en Realtime Database
// - Reporta errores a Crashlytics
```
### Dependencias T�cnicas
| Tecnolog�a | Uso |
|-----------|-----|
| **Flutter** | Framework UI |
| **Material Design** | Componentes visuales |
| **geolocator** | Obtenci�n de ubicaci�n GPS |
| **geocoding** | Conversi�n de coordenadas a direcci�n |
| **url_launcher** | Realizar llamadas telef�nicas |
| **FirebaseService** | Integraci�n Firebase Analytics |
| **AlertService** | Gesti�n de alertas |
| **RateLimiter** | Control de intentos |
### Pantallas/Widgets
```
InicioPage (StatefulWidget)
 AppBar (t�tulo + navegaci�n)
 GestureDetector (bot�n p�nico)
 Text (indicador intentos)
 Container (mapa visual)
 FloatingActionButton (menu contactos)
```
### Permisos Requeridos
- `INTERNET` - Para conectar con Firebase
- `ACCESS_FINE_LOCATION` - Para obtener ubicaci�n GPS
- `ACCESS_COARSE_LOCATION` - Para ubicaci�n aproximada
- `CALL_PHONE` - Para realizar llamadas
### Almacenamiento Usado
- **SharedPreferences** - Contador de intentos
- **Firebase Database** - Guardado de alertas
- **Firebase Analytics** - Eventos de emergencia
### Flujo de Ejecuci�n
```
1. Usuario abre la app
2. Se solicita permiso de ubicaci�n
3. Se verifica si Firebase est� inicializado
4. Se carga el contador de intentos
5. Se muestra la interfaz principal
6. Usuario mantiene presionado el bot�n por 1.2s
7. Se verifica rate limit
8. Se obtiene ubicaci�n GPS
9. Se registra en Firebase
10. Se realiza llamada de emergencia
```
---
## Archivo: settings_page.dart (Anteriormente: senttings.dart)
### Informaci�n General
| Atributo | Valor |
|----------|-------|
| **Ubicaci�n anterior** | `lib/senttings.dart` |
| **Ubicaci�n actual** | `lib/screens/settings_page.dart` |
| **L�neas de c�digo** | ~250 |
| **Responsabilidad** | Configuraci�n de perfil y contacto de emergencia |
| **Tipo de Widget** | StatefulWidget |
### Funcionalidades Principales
#### 1. **Datos de Perfil del Usuario**
```dart
// - Nombre
// - C�dula/ID (CI)
// - Edad
// - Contacto de emergencia (tel�fono)
// - Informaci�n m�dica relevante
```
#### 2. **Validaci�n de Datos**
```dart
// - Validaci�n de email
// - Validaci�n de nombre
// - Validaci�n de edad
// - Validaci�n de tel�fono Ecuador
// - Normalizaci�n de n�meros telef�nicos
```
#### 3. **Almacenamiento Seguro**
```dart
// - Encriptaci�n de datos sensibles
// - Uso de flutter_secure_storage
// - Hardware KeyStore (Android) / Keychain (iOS)
```
#### 4. **Interfaz de Configuraci�n**
```dart
// - Campos de entrada para datos
// - Botones guardar/borrar
// - Validaci�n en tiempo real
// - Mensajes de error en espa�ol
```
### Dependencias T�cnicas
| Tecnolog�a | Uso |
|-----------|-----|
| **Flutter** | Framework UI |
| **Validators** | Validaci�n de datos Ecuador |
| **SecureStorageService** | Almacenamiento encriptado |
| **SharedPreferences** | Datos no sensibles |
### Widgets Principales
```
SenttingsPage (StatefulWidget)
 TextField (nombre)
 TextField (email)
 TextField (tel�fono)
 TextField (contacto emergencia)
 RaisedButton (guardar)
 RaisedButton (borrar datos)
```
### Permisos Requeridos
- Ninguno adicional (usa datos locales)
### Almacenamiento Usado
- **SecureStorageService** - Datos encriptados (contacto, informaci�n m�dica)
- **SharedPreferences** - Preferencias de usuario
---
## Archivo: options_page.dart (Anteriormente: options.dart)
### Informaci�n General
| Atributo | Valor |
|----------|-------|
| **Ubicaci�n anterior** | `lib/options.dart` |
| **Ubicaci�n actual** | `lib/screens/options_page.dart` |
| **L�neas de c�digo** | ~1900 |
| **Responsabilidad** | Historial de alertas e informaci�n m�dica |
| **Tipo de Widget** | StatefulWidget |
### Funcionalidades Principales
#### 1. **Historial de Alertas**
```dart
// - Lista de todas las alertas activadas
// - Informaci�n: fecha, hora, ubicaci�n, estado
// - Editar estado (activa resuelta falsa alarma)
// - Eliminar alertas antiguas
```
#### 2. **Informaci�n M�dica**
```dart
// - Condiciones m�dicas cr�nicas
// - Medicamentos que toma
// - Alergias conocidas
// - Citas m�dicas pr�ximas
// - Informaci�n del seguro m�dico
```
#### 3. **Gesti�n de Contactos de Emergencia**
```dart
// - Agregar/editar/eliminar contactos
// - Tel�fonos de contacto
// - Relaci�n con el usuario
```
#### 4. **Di�logos de Configuraci�n**
```dart
// - Di�logo de condiciones m�dicas
// - Di�logo de medicamentos
// - Di�logo de alergias
// - Di�logo de citas m�dicas
// - Di�logo de seguros
```
### Dependencias T�cnicas
| Tecnolog�a | Uso |
|-----------|-----|
| **Flutter** | Framework UI |
| **SharedPreferences** | Persistencia de datos locales |
| **path_provider** | Acceso a directorios de documentos |
| **dart:io** | Manejo de archivos JSON |
| **AlertService** | Gesti�n de alertas |
### Widgets Principales
```
OptionsPage (StatefulWidget)
 AlertHistory Dialog
 Lista de alertas
 Botones editar/eliminar
 Medical Conditions Dialog
 Medications Dialog
 Appointments Dialog
 Allergies Dialog
 Insurance Dialog
```
### Permisos Requeridos
- `WRITE_EXTERNAL_STORAGE` - Para guardar archivos JSON
- `READ_EXTERNAL_STORAGE` - Para leer archivos guardados
### Almacenamiento Usado
- **SharedPreferences** - Datos estructurados (JSON string)
- **Archivos JSON** - Historial de alertas en carpeta `Documentos/alerts/`
- **Firebase Database** - Sincronizaci�n de alertas en la nube
### Estructura de Datos
```dart
// Alerta
{
 'id': 'CI_mod1',
 'datetime': '2025-12-21T10:30:00Z',
 'location': 'Calle 10 y Amazonas, Quito',
 'description': 'Dolor en el pecho',
 'status': 'active' | 'resolved' | 'false_alarm'
}
// Condici�n m�dica
{
 'diagnosis': 'Hipertensi�n',
 'since': '2020-01-15'
}
// Medicamento
{
 'name': 'Lisinopril 10mg',
 'frequency': 'Una vez al d�a'
}
// Cita m�dica
{
 'date': '2025-12-25T14:00',
 'doctor': 'Dr. Juan P�rez',
 'specialty': 'Cardiolog�a'
}
// Alergia
{
 'substance': 'Penicilina',
 'severity': 'Grave'
}
```
---
## Archivo: documents_page.dart (Anteriormente: documents.dart)
### Informaci�n General
| Atributo | Valor |
|----------|-------|
| **Ubicaci�n anterior** | `lib/documents.dart` |
| **Ubicaci�n actual** | `lib/screens/documents_page.dart` |
| **L�neas de c�digo** | ~300 |
| **Responsabilidad** | Gesti�n de documentos m�dicos digitales |
| **Tipo de Widget** | StatefulWidget |
### Funcionalidades Principales
#### 1. **Subida de Documentos**
```dart
// - Recetas m�dicas
// - An�lisis de laboratorio
// - Radiograf�as (im�genes)
// - Reportes m�dicos
// - Carn� de vacunaci�n
```
#### 2. **Visualizaci�n de Documentos**
```dart
// - Vista previa de im�genes
// - Lista de todos los documentos
// - Informaci�n: nombre, fecha, tipo
```
#### 3. **Gesti�n de Archivos**
```dart
// - Descargar documentos
// - Eliminar documentos
// - Compartir con profesionales
```
### Dependencias T�cnicas
| Tecnolog�a | Uso |
|-----------|-----|
| **Flutter** | Framework UI |
| **file_picker** | Seleccionar archivos |
| **path_provider** | Acceso a directorios |
| **image_picker** | Capturar fotos con c�mara |
### Widgets Principales
```
DocumentsPage (StatefulWidget)
 FloatingActionButton (a�adir documento)
 ListView (lista de documentos)
 DocumentCard
 Miniatura
 Nombre
 Fecha
 Botones (ver/eliminar)
 PhotoViewGallery (vista ampliada)
```
### Permisos Requeridos
- `READ_EXTERNAL_STORAGE` - Para leer documentos
- `WRITE_EXTERNAL_STORAGE` - Para guardar documentos
- `CAMERA` - Para capturar fotos de documentos
- `INTERNET` - Para cargar a la nube
### Almacenamiento Usado
- **Archivos locales** - En carpeta Documentos del dispositivo
- **Firebase Storage** - Sincronizaci�n en la nube
---
## Archivo: symptoms_page.dart (Anteriormente: symptoms.dart)
### Informaci�n General
| Atributo | Valor |
|----------|-------|
| **Ubicaci�n anterior** | `lib/symptoms.dart` |
| **Ubicaci�n actual** | `lib/screens/symptoms_page.dart` |
| **L�neas de c�digo** | ~400 |
| **Responsabilidad** | Registro y seguimiento de s�ntomas |
| **Tipo de Widget** | StatefulWidget |
### Funcionalidades Principales
#### 1. **Registro de S�ntomas**
```dart
// - Seleccionar s�ntomas comunes
// - Describir s�ntomas en detalle
// - Nivel de severidad (leve/moderado/grave)
// - Hora de inicio
// - Duraci�n estimada
```
#### 2. **Historial de S�ntomas**
```dart
// - Ver s�ntomas registrados
// - Fecha y hora de cada registro
// - Identificar patrones
// - Exportar para m�dico
```
#### 3. **Alertas Inteligentes**
```dart
// - Notificar si s�ntomas son graves
// - Sugerir llamar m�dico
// - Opci�n de crear alerta de emergencia
```
### Dependencias T�cnicas
| Tecnolog�a | Uso |
|-----------|-----|
| **Flutter** | Framework UI |
| **SharedPreferences** | Guardado local de s�ntomas |
| **NotificationService** | Alertas de s�ntomas graves |
### Widgets Principales
```
SymptomsPage (StatefulWidget)
 SymptomSelector (checkboxes)
 TextArea (descripci�n)
 Slider (severidad)
 TimePicker (hora de inicio)
 Button (guardar)
 ListView (historial)
```
### Permisos Requeridos
- Ninguno adicional (datos locales)
### Almacenamiento Usado
- **SharedPreferences** - Historial de s�ntomas
- **Firebase Database** - Sincronizaci�n en la nube
---
## Archivo: preferences.dart
### Informaci�n General
| Atributo | Valor |
|----------|-------|
| **Ubicaci�n anterior** | `lib/preferences.dart` |
| **Ubicaci�n actual** | `lib/utils/preferences.dart` |
| **L�neas de c�digo** | ~150 |
| **Responsabilidad** | Estados globales y preferencias de aplicaci�n |
| **Tipo** | Singleton (clase est�tica) |
### Funcionalidades Principales
#### 1. **Preferencias Globales**
```dart
// - Tema (claro/oscuro)
// - Idioma de la aplicaci�n
// - Notificaciones activadas/desactivadas
// - Volumen de sonido
// - Vibraci�n activada/desactivada
```
#### 2. **Estados Reactivos**
```dart
// Uso de ValueNotifier para reactividad
// - Cambio de tema en tiempo real
// - Actualizaci�n de idioma
// - Notificaciones
```
#### 3. **Configuraci�n de Seguridad**
```dart
// - Biometr�a activada
// - C�digo PIN activado
// - Sesi�n timeout
```
### Dependencias T�cnicas
| Tecnolog�a | Uso |
|-----------|-----|
| **Flutter** | ValueNotifier, ChangeNotifier |
| **SharedPreferences** | Persistencia de preferencias |
### Estructura
```dart
class Preferences {
 // ValueNotifiers para reactivos
 static final isDarkMode = ValueNotifier<bool>(false);
 static final isNotificationsEnabled = ValueNotifier<bool>(true);
 static final selectedLanguage = ValueNotifier<String>('es');
 // M�todos est�ticos
 static Future<void> loadPreferences()
 static Future<void> savePreferences()
 static void resetToDefaults()
}
```
### Permisos Requeridos
- Ninguno (solo configuraci�n local)
### Almacenamiento Usado
- **SharedPreferences** - Todas las preferencias
---
## Tabla Comparativa

| Archivo | Ubicaci�n | Tipo | L�neas | Responsabilidad | Firebase | Permisos |
|---------|-----------|------|--------|-----------------|----------|----------|
| **main.dart** | `lib/` | StatefulWidget | ~800 | Bot�n p�nico, ubicaci�n | Analytics, DB | 4 |
| **settings_page.dart** | `lib/screens/` | StatefulWidget | ~250 | Perfil usuario | No | 0 |
| **options_page.dart** | `lib/screens/` | StatefulWidget | ~1900 | Historial, info m�dica | Database | 2 |
| **documents_page.dart** | `lib/screens/` | StatefulWidget | ~300 | Documentos m�dicos | Storage | 4 |
| **symptoms_page.dart** | `lib/screens/` | StatefulWidget | ~400 | S�ntomas | Database | 0 |
| **preferences.dart** | `lib/utils/` | Singleton | ~150 | Configuraci�n global | No | 0 |
| **validators.dart** | `lib/utils/validators/` | Funciones | ~500+ | Validaci�n de datos | No | 0 |

---
## Tecnolog�as Relacionadas

### Firebase
- **main.dart** - Analytics, Realtime Database
- **options_page.dart** - Realtime Database
- **documents_page.dart** - Cloud Storage
- **symptoms_page.dart** - Realtime Database

### Flutter
- Todos los archivos usan widgets Flutter
- Material Design para interfaz
- ValueNotifier para estados reactivos

### Android
- **main.dart** - Permisos de ubicaci�n, llamadas
- **options_page.dart** - Almacenamiento externo
- **documents_page.dart** - C�mara, almacenamiento

### iOS
- Similares a Android pero con Keychain en lugar de KeyStore
- Restricciones de privacidad m�s estrictas

### Dependencias Externas
- `geolocator` - Ubicaci�n GPS
- `geocoding` - Conversi�n de coordenadas
- `url_launcher` - Llamadas telef�nicas
- `shared_preferences` - Almacenamiento local
- `flutter_secure_storage` - Encriptaci�n
---
## Pr�ximos Pasos
1. **Para entender validadores:** Ver archivo `02_VALIDADORES.md`
2. **Para entender servicios:** Ver archivo `04_ARCHIVOS_SERVICIOS.md`
3. **Para entender permisos:** Ver archivo `05_PERMISOS_REQUERIDOS.md`
4. **Para ver ejemplos de c�digo:** Consultar `lib/EJEMPLOS_FASE_1.dart`
---
## Resumen de Contactos
- **Para preguntas sobre UI:** Ver c�digo de cada archivo
- **Para integraci�n Firebase:** Ver `FirebaseService` en servicios
- **Para validaci�n de datos:** Ver m�dulo Validators
---
**�ltima actualizaci�n:** 21 de julio de 2026  
**Versi�n:** 1.4.60  
**Estado:** Desarrollo

