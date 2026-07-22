# 📄 Archivos Principales de la Aplicación

**Versión:** 1.0 | **Fecha:** 21 de diciembre de 2025 | **Estado:** ✅ Completo

---

## 📋 Índice

1. [Descripción General](#descripción-general)
2. [Archivo main.dart](#archivo-maindart)
3. [Archivo senttings.dart](#archivo-senttingsdart)
4. [Archivo options.dart](#archivo-optionsdart)
5. [Archivo documents.dart](#archivo-documentsdart)
6. [Archivo symptoms.dart](#archivo-symptomsdart)
7. [Archivo preferences.dart](#archivo-preferencesdart)
8. [Tabla Comparativa](#tabla-comparativa)

---

## Descripción General

Los archivos principales son las **páginas/pantallas** de la aplicación Flutter. Cada uno corresponde a una sección específica de la interfaz de usuario y maneja:

- Lógica de presentación (UI)
- Interacción con el usuario
- Comunicación con servicios
- Gestión de estado local

**Localización:** `lib/`

---

## Archivo: main.dart

### 📌 Información General

| Atributo | Valor |
|----------|-------|
| **Ubicación** | `lib/main.dart` |
| **Líneas de código** | ~800 |
| **Responsabilidad** | Página principal, punto de entrada, botón de pánico |
| **Tipo de Widget** | StatefulWidget |

### 🎯 Funcionalidades Principales

#### 1. **Botón de Pánico**
```dart
// Mantener presionado por 1.2 segundos para activar
// - Verifica rate limiting (máximo 3 intentos en 3 horas)
// - Obtiene ubicación GPS actual
// - Crea alerta en Firebase Database
// - Realiza llamada telefónica
// - Muestra indicador visual de intentos restantes
```

#### 2. **Obtención de Ubicación**
```dart
// Solicita permisos de ubicación
// Obtiene coordenadas GPS (latitud, longitud)
// Convierte coordenadas a dirección legible
// Usa: geolocator + geocoding
```

#### 3. **Indicador de Intentos**
```dart
// Muestra intentos restantes: X/3
// Se actualiza en tiempo real
// Colores según disponibilidad (verde/amarillo/rojo)
```

#### 4. **Integración Firebase**
```dart
// - Registra evento "emergency_activated"
// - Crea documento en Realtime Database
// - Reporta errores a Crashlytics
```

### 🔧 Dependencias Técnicas

| Tecnología | Uso |
|-----------|-----|
| **Flutter** | Framework UI |
| **Material Design** | Componentes visuales |
| **geolocator** | Obtención de ubicación GPS |
| **geocoding** | Conversión de coordenadas a dirección |
| **url_launcher** | Realizar llamadas telefónicas |
| **FirebaseService** | Integración Firebase Analytics |
| **AlertService** | Gestión de alertas |
| **RateLimiter** | Control de intentos |

### 📱 Pantallas/Widgets

```
InicioPage (StatefulWidget)
├── AppBar (título + navegación)
├── GestureDetector (botón pánico)
├── Text (indicador intentos)
├── Container (mapa visual)
└── FloatingActionButton (menu contactos)
```

### 🔐 Permisos Requeridos

- ✅ `INTERNET` - Para conectar con Firebase
- ✅ `ACCESS_FINE_LOCATION` - Para obtener ubicación GPS
- ✅ `ACCESS_COARSE_LOCATION` - Para ubicación aproximada
- ✅ `CALL_PHONE` - Para realizar llamadas

### 💾 Almacenamiento Usado

- **SharedPreferences** - Contador de intentos
- **Firebase Database** - Guardado de alertas
- **Firebase Analytics** - Eventos de emergencia

### 📊 Flujo de Ejecución

```
1. Usuario abre la app
   ↓
2. Se solicita permiso de ubicación
   ↓
3. Se verifica si Firebase está inicializado
   ↓
4. Se carga el contador de intentos
   ↓
5. Se muestra la interfaz principal
   ↓
6. Usuario mantiene presionado el botón por 1.2s
   ↓
7. Se verifica rate limit
   ↓
8. Se obtiene ubicación GPS
   ↓
9. Se registra en Firebase
   ↓
10. Se realiza llamada de emergencia
```

---

## Archivo: senttings.dart

### 📌 Información General

| Atributo | Valor |
|----------|-------|
| **Ubicación** | `lib/senttings.dart` |
| **Líneas de código** | ~250 |
| **Responsabilidad** | Configuración de perfil y contacto de emergencia |
| **Tipo de Widget** | StatefulWidget |

### 🎯 Funcionalidades Principales

#### 1. **Datos de Perfil del Usuario**
```dart
// - Nombre
// - Cédula/ID (CI)
// - Edad
// - Contacto de emergencia (teléfono)
// - Información médica relevante
```

#### 2. **Validación de Datos**
```dart
// - Validación de email
// - Validación de nombre
// - Validación de edad
// - Validación de teléfono Ecuador
// - Normalización de números telefónicos
```

#### 3. **Almacenamiento Seguro**
```dart
// - Encriptación de datos sensibles
// - Uso de flutter_secure_storage
// - Hardware KeyStore (Android) / Keychain (iOS)
```

#### 4. **Interfaz de Configuración**
```dart
// - Campos de entrada para datos
// - Botones guardar/borrar
// - Validación en tiempo real
// - Mensajes de error en español
```

### 🔧 Dependencias Técnicas

| Tecnología | Uso |
|-----------|-----|
| **Flutter** | Framework UI |
| **Validators** | Validación de datos Ecuador |
| **SecureStorageService** | Almacenamiento encriptado |
| **SharedPreferences** | Datos no sensibles |

### 📱 Widgets Principales

```
SenttingsPage (StatefulWidget)
├── TextField (nombre)
├── TextField (email)
├── TextField (teléfono)
├── TextField (contacto emergencia)
├── RaisedButton (guardar)
└── RaisedButton (borrar datos)
```

### 🔐 Permisos Requeridos

- ❌ Ninguno adicional (usa datos locales)

### 💾 Almacenamiento Usado

- **SecureStorageService** - Datos encriptados (contacto, información médica)
- **SharedPreferences** - Preferencias de usuario

---

## Archivo: options.dart

### 📌 Información General

| Atributo | Valor |
|----------|-------|
| **Ubicación** | `lib/options.dart` |
| **Líneas de código** | ~1900 |
| **Responsabilidad** | Historial de alertas e información médica |
| **Tipo de Widget** | StatefulWidget |

### 🎯 Funcionalidades Principales

#### 1. **Historial de Alertas**
```dart
// - Lista de todas las alertas activadas
// - Información: fecha, hora, ubicación, estado
// - Editar estado (activa → resuelta → falsa alarma)
// - Eliminar alertas antiguas
```

#### 2. **Información Médica**
```dart
// - Condiciones médicas crónicas
// - Medicamentos que toma
// - Alergias conocidas
// - Citas médicas próximas
// - Información del seguro médico
```

#### 3. **Gestión de Contactos de Emergencia**
```dart
// - Agregar/editar/eliminar contactos
// - Teléfonos de contacto
// - Relación con el usuario
```

#### 4. **Diálogos de Configuración**
```dart
// - Diálogo de condiciones médicas
// - Diálogo de medicamentos
// - Diálogo de alergias
// - Diálogo de citas médicas
// - Diálogo de seguros
```

### 🔧 Dependencias Técnicas

| Tecnología | Uso |
|-----------|-----|
| **Flutter** | Framework UI |
| **SharedPreferences** | Persistencia de datos locales |
| **path_provider** | Acceso a directorios de documentos |
| **dart:io** | Manejo de archivos JSON |
| **AlertService** | Gestión de alertas |

### 📱 Widgets Principales

```
OptionsPage (StatefulWidget)
├── AlertHistory Dialog
│   ├── Lista de alertas
│   └── Botones editar/eliminar
├── Medical Conditions Dialog
├── Medications Dialog
├── Appointments Dialog
├── Allergies Dialog
└── Insurance Dialog
```

### 🔐 Permisos Requeridos

- ✅ `WRITE_EXTERNAL_STORAGE` - Para guardar archivos JSON
- ✅ `READ_EXTERNAL_STORAGE` - Para leer archivos guardados

### 💾 Almacenamiento Usado

- **SharedPreferences** - Datos estructurados (JSON string)
- **Archivos JSON** - Historial de alertas en carpeta `Documentos/alerts/`
- **Firebase Database** - Sincronización de alertas en la nube

### 📊 Estructura de Datos

```dart
// Alerta
{
  'id': 'CI_mod1',
  'datetime': '2025-12-21T10:30:00Z',
  'location': 'Calle 10 y Amazonas, Quito',
  'description': 'Dolor en el pecho',
  'status': 'active' | 'resolved' | 'false_alarm'
}

// Condición médica
{
  'diagnosis': 'Hipertensión',
  'since': '2020-01-15'
}

// Medicamento
{
  'name': 'Lisinopril 10mg',
  'frequency': 'Una vez al día'
}

// Cita médica
{
  'date': '2025-12-25T14:00',
  'doctor': 'Dr. Juan Pérez',
  'specialty': 'Cardiología'
}

// Alergia
{
  'substance': 'Penicilina',
  'severity': 'Grave'
}
```

---

## Archivo: documents.dart

### 📌 Información General

| Atributo | Valor |
|----------|-------|
| **Ubicación** | `lib/documents.dart` |
| **Líneas de código** | ~300 |
| **Responsabilidad** | Gestión de documentos médicos digitales |
| **Tipo de Widget** | StatefulWidget |

### 🎯 Funcionalidades Principales

#### 1. **Subida de Documentos**
```dart
// - Recetas médicas
// - Análisis de laboratorio
// - Radiografías (imágenes)
// - Reportes médicos
// - Carné de vacunación
```

#### 2. **Visualización de Documentos**
```dart
// - Vista previa de imágenes
// - Lista de todos los documentos
// - Información: nombre, fecha, tipo
```

#### 3. **Gestión de Archivos**
```dart
// - Descargar documentos
// - Eliminar documentos
// - Compartir con profesionales
```

### 🔧 Dependencias Técnicas

| Tecnología | Uso |
|-----------|-----|
| **Flutter** | Framework UI |
| **file_picker** | Seleccionar archivos |
| **path_provider** | Acceso a directorios |
| **image_picker** | Capturar fotos con cámara |

### 📱 Widgets Principales

```
DocumentsPage (StatefulWidget)
├── FloatingActionButton (añadir documento)
├── ListView (lista de documentos)
│   └── DocumentCard
│       ├── Miniatura
│       ├── Nombre
│       ├── Fecha
│       └── Botones (ver/eliminar)
└── PhotoViewGallery (vista ampliada)
```

### 🔐 Permisos Requeridos

- ✅ `READ_EXTERNAL_STORAGE` - Para leer documentos
- ✅ `WRITE_EXTERNAL_STORAGE` - Para guardar documentos
- ✅ `CAMERA` - Para capturar fotos de documentos
- ✅ `INTERNET` - Para cargar a la nube

### 💾 Almacenamiento Usado

- **Archivos locales** - En carpeta Documentos del dispositivo
- **Firebase Storage** - Sincronización en la nube

---

## Archivo: symptoms.dart

### 📌 Información General

| Atributo | Valor |
|----------|-------|
| **Ubicación** | `lib/symptoms.dart` |
| **Líneas de código** | ~400 |
| **Responsabilidad** | Registro y seguimiento de síntomas |
| **Tipo de Widget** | StatefulWidget |

### 🎯 Funcionalidades Principales

#### 1. **Registro de Síntomas**
```dart
// - Seleccionar síntomas comunes
// - Describir síntomas en detalle
// - Nivel de severidad (leve/moderado/grave)
// - Hora de inicio
// - Duración estimada
```

#### 2. **Historial de Síntomas**
```dart
// - Ver síntomas registrados
// - Fecha y hora de cada registro
// - Identificar patrones
// - Exportar para médico
```

#### 3. **Alertas Inteligentes**
```dart
// - Notificar si síntomas son graves
// - Sugerir llamar médico
// - Opción de crear alerta de emergencia
```

### 🔧 Dependencias Técnicas

| Tecnología | Uso |
|-----------|-----|
| **Flutter** | Framework UI |
| **SharedPreferences** | Guardado local de síntomas |
| **NotificationService** | Alertas de síntomas graves |

### 📱 Widgets Principales

```
SymptomsPage (StatefulWidget)
├── SymptomSelector (checkboxes)
├── TextArea (descripción)
├── Slider (severidad)
├── TimePicker (hora de inicio)
├── Button (guardar)
└── ListView (historial)
```

### 🔐 Permisos Requeridos

- ❌ Ninguno adicional (datos locales)

### 💾 Almacenamiento Usado

- **SharedPreferences** - Historial de síntomas
- **Firebase Database** - Sincronización en la nube

---

## Archivo: preferences.dart

### 📌 Información General

| Atributo | Valor |
|----------|-------|
| **Ubicación** | `lib/preferences.dart` |
| **Líneas de código** | ~150 |
| **Responsabilidad** | Estados globales y preferencias de aplicación |
| **Tipo** | Singleton (clase estática) |

### 🎯 Funcionalidades Principales

#### 1. **Preferencias Globales**
```dart
// - Tema (claro/oscuro)
// - Idioma de la aplicación
// - Notificaciones activadas/desactivadas
// - Volumen de sonido
// - Vibración activada/desactivada
```

#### 2. **Estados Reactivos**
```dart
// Uso de ValueNotifier para reactividad
// - Cambio de tema en tiempo real
// - Actualización de idioma
// - Notificaciones
```

#### 3. **Configuración de Seguridad**
```dart
// - Biometría activada
// - Código PIN activado
// - Sesión timeout
```

### 🔧 Dependencias Técnicas

| Tecnología | Uso |
|-----------|-----|
| **Flutter** | ValueNotifier, ChangeNotifier |
| **SharedPreferences** | Persistencia de preferencias |

### 📝 Estructura

```dart
class Preferences {
  // ValueNotifiers para reactivos
  static final isDarkMode = ValueNotifier<bool>(false);
  static final isNotificationsEnabled = ValueNotifier<bool>(true);
  static final selectedLanguage = ValueNotifier<String>('es');
  
  // Métodos estáticos
  static Future<void> loadPreferences()
  static Future<void> savePreferences()
  static void resetToDefaults()
}
```

### 🔐 Permisos Requeridos

- ❌ Ninguno (solo configuración local)

### 💾 Almacenamiento Usado

- **SharedPreferences** - Todas las preferencias

---

## Tabla Comparativa

| Archivo | Tipo | Líneas | Responsabilidad | Firebase | Permisos |
|---------|------|--------|-----------------|----------|----------|
| **main.dart** | StatefulWidget | ~800 | Botón pánico, ubicación | ✅ Analytics, DB | 🔒 4 |
| **senttings.dart** | StatefulWidget | ~250 | Perfil usuario | ❌ No | 🔓 0 |
| **options.dart** | StatefulWidget | ~1900 | Historial, info médica | ✅ Database | 🔒 2 |
| **documents.dart** | StatefulWidget | ~300 | Documentos médicos | ✅ Storage | 🔒 4 |
| **symptoms.dart** | StatefulWidget | ~400 | Síntomas | ✅ Database | 🔓 0 |
| **preferences.dart** | Singleton | ~150 | Configuración global | ❌ No | 🔓 0 |

---

## Tecnologías Relacionadas

### 🔥 Firebase
- ✅ **main.dart** - Analytics, Realtime Database
- ✅ **options.dart** - Realtime Database
- ✅ **documents.dart** - Cloud Storage
- ✅ **symptoms.dart** - Realtime Database

### 📱 Flutter
- ✅ Todos los archivos usan widgets Flutter
- ✅ Material Design para interfaz
- ✅ ValueNotifier para estados reactivos

### 🤖 Android
- ✅ **main.dart** - Permisos de ubicación, llamadas
- ✅ **options.dart** - Almacenamiento externo
- ✅ **documents.dart** - Cámara, almacenamiento

### 🍎 iOS
- ✅ Similares a Android pero con Keychain en lugar de KeyStore
- ✅ Restricciones de privacidad más estrictas

### 📦 Dependencias Externas
- `geolocator` - Ubicación GPS
- `geocoding` - Conversión de coordenadas
- `url_launcher` - Llamadas telefónicas
- `shared_preferences` - Almacenamiento local
- `flutter_secure_storage` - Encriptación

---

## Próximos Pasos

1. **Para entender validadores:** Ver archivo `02_VALIDADORES.md`
2. **Para entender servicios:** Ver archivo `04_ARCHIVOS_SERVICIOS.md`
3. **Para entender permisos:** Ver archivo `05_PERMISOS_REQUERIDOS.md`
4. **Para ver ejemplos de código:** Consultar `lib/EJEMPLOS_FASE_1.dart`

---

## 📞 Resumen de Contactos

- **Para preguntas sobre UI:** Ver código de cada archivo
- **Para integración Firebase:** Ver `FirebaseService` en servicios
- **Para validación de datos:** Ver módulo Validators
