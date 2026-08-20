# Archivos Principales de la Aplicacion

**Ultima actualizacion:** 20 de agosto de 2026  
**Version:** 1.4.67  
**Estado:** Desarrollo (Estructura Reorganizada)

IMPORTANTE: A partir del 6 de agosto de 2026, la estructura del directorio `lib/` ha sido reorganizada. Ver [11_ESTRUCTURA_DIRECTORIO.md](11_ESTRUCTURA_DIRECTORIO.md) para detalles.

---

## Indice

1. [Descripcion General](#descripcion-general)
2. [Cambios de Estructura](#cambios-de-estructura)
3. [Archivo main.dart](#archivo-maindart)
4. [Archivo settings_page.dart](#archivo-settings_pagedart)
5. [Archivo options_page.dart](#archivo-options_pagedart)
6. [Archivo documents_page.dart](#archivo-documents_pagedart)
7. [Archivo symptoms_page.dart](#archivo-symptoms_pagedart)
8. [Archivo tutorial_screen.dart](#archivo-tutorial_screendart)
9. [Archivo preferences.dart](#archivo-preferencesdart)

---

## Descripcion General

Los archivos principales son las **paginas/pantallas** de la aplicacion Flutter. Cada uno corresponde a una seccion especifica de la interfaz de usuario y maneja:

- Logica de presentacion (UI)
- Interaccion con el usuario
- Comunicacion con servicios
- Gestion de estado local

**Localizacion:** `lib/screens/` (tras reorganizacion del 6 de agosto)

---

## Cambios de Estructura

### Reorganizacion Realizada (6 de Agosto de 2026)

La carpeta `lib/` ha sido reorganizada en subcarpetas tematicas para mejorar la mantenibilidad:

| Archivo Anterior | Nueva Ubicacion | Nuevo Nombre |
|------------------|-----------------|--------------|
| `lib/main.dart` | `lib/` | `main.dart` (sin cambios) |
| `lib/senttings.dart` | `lib/screens/` | `settings_page.dart` |
| `lib/options.dart` | `lib/screens/` | `options_page.dart` |
| `lib/documents.dart` | `lib/screens/` | `documents_page.dart` |
| `lib/symptoms.dart` | `lib/screens/` | `symptoms_page.dart` |
| `lib/tutorial_screen.dart` | `lib/screens/` | `tutorial_screen.dart` |
| `lib/preferences.dart` | `lib/utils/` | `preferences.dart` |
| `lib/validators/` | `lib/utils/` | `validators/` |

### Nueva Estructura de Directorios

```
lib/
 main.dart
 screens/                 - Todas las pantallas UI
   settings_page.dart
   options_page.dart
   documents_page.dart
   symptoms_page.dart
   tutorial_screen.dart
 services/                - Logica de negocio
   firebase_service.dart
   alert_service.dart
   rate_limiter.dart
   appointment_reminder_service.dart
   encryption_service.dart
   ...
 utils/                   - Utilidades
   preferences.dart
   validators/
     validators.dart
 examples/                - Ejemplos de codigo
 testing/                 - Pruebas
 models/                  - Modelos de datos (reservado)
```

### Beneficios

- [OK] **Mejor organizacion:** Cada tipo de archivo tiene su lugar
- [OK] **Escalabilidad:** Facil agregar nuevas pantallas
- [OK] **Mantenibilidad:** Estructura clara y predecible
- [OK] **Importaciones claras:** Rutas relativas indican la relacion entre archivos

---

## Archivo: main.dart

### Informacion General

| Atributo | Valor |
|----------|-------|
| **Ubicacion** | `lib/main.dart` |
| **Lineas de codigo** | ~1200 |
| **Responsabilidad** | Pagina principal, punto de entrada, boton de panico |
| **Tipo de Widget** | StatefulWidget |

### Funcionalidades Principales

#### 1. **Boton de Panico**

```dart
// Mantener presionado por 1.2 segundos para activar
// - Verifica rate limiting (maximo 4 intentos en 2 minutos)
// - Obtiene ubicacion GPS actual
// - Crea alerta en Firebase Database
// - Realiza llamada telefonica
// - Muestra indicador visual de intentos restantes
```

#### 2. **Obtencion de Ubicacion**

```dart
// Solicita permisos de ubicacion
// Obtiene coordenadas GPS (latitud, longitud)
// Convierte coordenadas a direccion legible
// Guarda ultima ubicacion conocida para casos sin conexion
// Usa: geolocator + geocoding
```

#### 3. **Indicador de Intentos**

```dart
// Muestra intentos restantes: X/4
// Se actualiza en tiempo real
// Colores segun disponibilidad (verde/amarillo/rojo)
// Muestra contador regresivo cuando esta limitado
```

#### 4. **Integracion Firebase**

```dart
// - Registra evento "emergency_activated"
// - Crea documento en Realtime Database
// - Reporta errores a Crashlytics
// - Sincroniza con backend para notificaciones
```

### Dependencias Tecnicas

| Tecnologia | Uso |
|-----------|-----|
| **Flutter** | Framework UI |
| **Material Design** | Componentes visuales |
| **geolocator** | Obtencion de ubicacion GPS |
| **geocoding** | Conversion de coordenadas a direccion |
| **url_launcher** | Realizar llamadas telefonicas |
| **FirebaseService** | Integracion Firebase Analytics |
| **AlertService** | Gestion de alertas |
| **RateLimiter** | Control de intentos |

### Permisos Requeridos

- `INTERNET` - Para conectar con Firebase
- `ACCESS_FINE_LOCATION` - Para obtener ubicacion GPS
- `ACCESS_COARSE_LOCATION` - Para ubicacion aproximada
- `CALL_PHONE` - Para realizar llamadas
- `POST_NOTIFICATIONS` - Para notificaciones en Android 13+

### Almacenamiento Usado

- **SharedPreferences** - Contador de intentos, ultima ubicacion
- **Firebase Database** - Guardado de alertas
- **Firebase Analytics** - Eventos de emergencia
- **Secure Storage** - Datos sensibles

### Flujo de Ejecucion

```
1. Usuario abre la app
2. Se solicita permiso de ubicacion
3. Se verifica si Firebase esta inicializado
4. Se carga el contador de intentos (rate limiter)
5. Se muestra la interfaz principal
6. Usuario mantiene presionado el boton por 1.2s
7. Se verifica rate limit
8. Se obtiene ubicacion GPS (o ultima conocida si no hay)
9. Se registra en Firebase
10. Se realiza llamada de emergencia
```

---

## Archivo: settings_page.dart

### Informacion General

| Atributo | Valor |
|----------|-------|
| **Ubicacion** | `lib/screens/settings_page.dart` |
| **Ubicacion anterior** | `lib/senttings.dart` |
| **Lineas de codigo** | ~600 |
| **Responsabilidad** | Configuracion de perfil y contactos |
| **Tipo de Widget** | StatefulWidget |

### Funcionalidades Principales

#### 1. **Datos de Perfil del Usuario**

```dart
// - Nombre y apellidos
// - Cedula/ID (CI)
// - Edad
// - Tipo de sangre
// - Foto de perfil
// - Enfermedades catastroficas
```

#### 2. **Gestion de Contactos de Emergencia**

```dart
// - Agregar contactos (nombre + telefono)
// - Editar contactos existentes
// - Eliminar contactos
// - Validar telefonos duplicados (normalizados)
// - Normalizar formato de telefonos
```

#### 3. **Validacion de Datos**

```dart
// - Validacion de nombre (solo letras y espacios)
// - Validacion de edad (1-120)
// - Validacion de telefono Ecuador (09... o +593...)
// - Normalizacion de numeros telefonicos
// - Deteccion de duplicados aunque cambien formato
```

#### 4. **Almacenamiento Seguro**

```dart
// - Encriptacion de datos sensibles
// - Uso de flutter_secure_storage
// - Hardware KeyStore (Android) / Keychain (iOS)
// - SharedPreferences para datos no sensibles
```

### Validaciones Incluidas

- **Nombre:** Solo letras, espacios, y caracteres con acento
- **Edad:** Numeros entre 1 y 120
- **Telefono:** Formato local (09XXXXXXXX) o internacional (+593XXXXXXXXX)
- **CI:** 10 digitos numericos
- **Contactos duplicados:** Detecta el mismo numero aunque use formatos diferentes

---

## Archivo: options_page.dart

### Informacion General

| Atributo | Valor |
|----------|-------|
| **Ubicacion** | `lib/screens/options_page.dart` |
| **Ubicacion anterior** | `lib/options.dart` |
| **Lineas de codigo** | ~1500 |
| **Responsabilidad** | Informacion medica y alertas avanzadas |
| **Tipo de Widget** | StatefulWidget |

### Funcionalidades Principales

#### 1. **Informacion de Seguro**

```dart
// - Compania aseguradora
// - Numero de poliza
// - Telefono de contacto
// - Persistencia en SharedPreferences
```

#### 2. **Condiciones Medicas**

```dart
// - Diagnosticos
// - Desde cuando se tiene la condicion
// - Historial editable
// - Almacenamiento local
```

#### 3. **Medicamentos**

```dart
// - Nombre del medicamento
// - Dosis
// - Frecuencia
// - Lista editable
// - Sincronizacion offline
```

#### 4. **Citas Medicas**

```dart
// - Especialista/Doctor
// - Fecha y hora
// - Lugar
// - Recordatorios automaticos
// - Integracion con AppointmentReminderService
```

#### 5. **Alergias**

```dart
// - Tipo de alergia
// - Severidad
// - Historial editable
```

#### 6. **Historial de Alertas**

```dart
// - Visualizar alertas activadas
// - Ver detalles de cada alerta
// - Editar descripcion y estado
// - Exportar a archivos JSON
// - Almacenamiento persistente
```

### Servicios Utilizados

- **AppointmentReminderService** - Recordatorios de citas
- **AlertService** - Gestion de alertas
- **RateLimiter** - Control de intentos
- **SecureStorageService** - Almacenamiento seguro
- **Validators** - Validaciones
- **permission_handler** - Solicitud de permisos

---

## Archivo: symptoms_page.dart

### Informacion General

| Atributo | Valor |
|----------|-------|
| **Ubicacion** | `lib/screens/symptoms_page.dart` |
| **Lineas de codigo** | ~400 |
| **Responsabilidad** | Registro personal de sintomas |
| **Tipo de Widget** | StatefulWidget |

### Funcionalidades Principales

#### 1. **Registro de Sintomas**

```dart
// - Descripcion del sintoma
// - Fecha del registro
// - Severidad (1-10)
// - ID unico por entrada
// - Ordenamiento por fecha (mas reciente primero)
```

#### 2. **Persistencia Local**

```dart
// - Almacenamiento en SharedPreferences
// - Formato JSON
// - Contador secuencial de IDs
// - Carga y guardado automatico
```

#### 3. **Interfaz Intuitiva**

```dart
// - Slider para severidad (escala de colores)
// - Verde (leve) a Rojo (severo)
// - Dialogo para agregar nuevas entradas
// - Dialogo para editar entradas existentes
// - Boton para eliminar con confirmacion
```

#### 4. **Visualizacion**

```dart
// - Lista ordenada por fecha
// - Color del borde segun severidad
// - Fecha formateada legible
// - Texto del sintoma resumido
```

---

## Archivo: tutorial_screen.dart

### Informacion General

| Atributo | Valor |
|----------|-------|
| **Ubicacion** | `lib/screens/tutorial_screen.dart` |
| **Lineas de codigo** | ~1300 |
| **Responsabilidad** | Tutorial de bienvenida para nuevos usuarios |
| **Tipo de Widget** | StatefulWidget |

### Funcionalidades Principales

#### 1. **Flujo de Paginas (5 paginas)**

```
Pagina 0: Bienvenida
 - Titulo y descripcion
 - Boton "Siguiente"
 
Pagina 1: Navegacion
 - Explicacion de cada seccion
 - Tarjetas informativas
 
Pagina 2: Perfil Personal
 - Formulario para datos personales
 - Nombre, apellidos, CI, edad
 - Tipo de sangre
 - Foto de perfil
 
Pagina 3: Contacto de Emergencia
 - Nombre del contacto
 - Numero de telefono
 - Validacion de datos
 
Pagina 4: Modulo de Opciones
 - Explicacion de funcionalidades avanzadas
 - Informacion medica
 - Citas y medicamentos
 
Pagina 5: Inicio
 - Resumen y bienvenida final
 - Opcion para comenzar a usar la app
```

#### 2. **Validaciones Integradas**

```dart
// - Validacion de nombre (isValidName)
// - Validacion de CI (10 digitos)
// - Validacion de edad (1-120)
// - Validacion de telefono Ecuador
// - Validacion de tipo de sangre (lista predefinida)
```

#### 3. **Guardado de Datos**

```dart
// - Almacenamiento en SecureStorageService
// - Encriptacion de datos sensibles
// - Persistencia en SharedPreferences
// - Marca tutorial como completado
```

#### 4. **Control de Tutorial**

```dart
static Future<bool> isTutorialCompleted() 
static Future<void> markTutorialCompleted()

// Permite verificar si el usuario ya paso el tutorial
// Evita mostrar el tutorial en futuros lanzamientos
```

#### 5. **Interfaz Responsiva**

```dart
// - Adaptable a diferentes tamaños de pantalla
// - PageController para navegacion entre paginas
// - Botones Anterior/Siguiente/Saltar
// - Indicador de pagina actual
```

### Flujo de Datos

1. Usuario abre app por primera vez
2. `main.dart` verifica si tutorial fue completado
3. Si no, navega a `TutorialScreen`
4. Usuario completa 5 paginas del tutorial
5. Datos se guardan en SecureStorage
6. Tutorial se marca como completado
7. Siguiente lanzamiento muestra pantalla principal

---

## Archivo: preferences.dart

### Informacion General

| Atributo | Valor |
|----------|-------|
| **Ubicacion** | `lib/utils/preferences.dart` |
| **Lineas de codigo** | ~100 |
| **Responsabilidad** | Estado global y notificadores |
| **Tipo** | ValueNotifier, Variables globales |

### Contenido

```dart
// Contacto preferido para llamadas de emergencia
final ValueNotifier<Map<String, dynamic>?> preferredContact = 
  ValueNotifier(null);

// Lista de contactos de emergencia
final ValueNotifier<List<Map<String, String>>> allContacts = 
  ValueNotifier([]);

// Permite que la UI se actualice reactivamente cuando cambian
```

### Uso en la Aplicacion

- **main.dart** - Escucha cambios en preferredContact
- **settings_page.dart** - Actualiza allContacts cuando se agregan/editan/eliminan
- **options_page.dart** - Usa preferredContact para contacto principal

---

## Resumen

| Archivo | Proposito | Estado |
|---------|-----------|--------|
| main.dart | Pantalla principal y boton panico | Completo |
| settings_page.dart | Perfil y contactos | Completo |
| options_page.dart | Informacion medica avanzada | Completo |
| documents_page.dart | Documentos medicos | Completo |
| symptoms_page.dart | Registro de sintomas | Completo |
| tutorial_screen.dart | Tutorial de bienvenida | Completo |
| preferences.dart | Estado global | Completo |

---

**Nota:** Para cambios recientes y actualizaciones, consultar el archivo de PLAN_PRODUCCION.md
