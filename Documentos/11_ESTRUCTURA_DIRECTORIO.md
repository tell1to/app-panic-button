# Estructura del Directorio de la Aplicacion

**Version:** 1.4.67  
**Fecha:** 20 de agosto de 2026  
**Estado:** Produccion

---

## Indice

1. [Descripcion General](#descripcion-general)
2. [Estructura de Carpetas](#estructura-de-carpetas)
3. [Descripcion Detallada de Carpetas](#descripcion-detallada-de-carpetas)
4. [Archivos en Raiz](#archivos-en-raiz)
5. [Convenciones de Nombres](#convenciones-de-nombres)
6. [Flujo de Importaciones](#flujo-de-importaciones)
7. [Beneficios de esta Estructura](#beneficios-de-esta-estructura)

---

## Descripcion General

La aplicacion utiliza una estructura **modular y escalable** basada en **separacion de responsabilidades**. Cada carpeta agrupa archivos relacionados por su funcion en la aplicacion.

**Principio:** La estructura sigue el patron **Layer-based**, donde:
- **screens/** = Interfaz de Usuario (UI/Presentation)
- **services/** = Logica de Negocio y Servicios
- **utils/** = Utilidades, validadores y configuraciones
- **testing/** = Pruebas y widgets de testing
- **examples/** = Ejemplos de uso y referencias

---

## Estructura de Carpetas

```
lib/
├── main.dart                 # Punto de entrada de la aplicacion
├── screens/                  # Pantallas/Paginas de UI
│   ├── documents_page.dart
│   ├── options_page.dart
│   ├── settings_page.dart
│   ├── symptoms_page.dart
│   └── tutorial_screen.dart
├── services/                 # Servicios y logica de negocio
│   ├── alert_service.dart
│   ├── appointment_reminder_service.dart
│   ├── contact_service.dart
│   ├── encryption_service.dart
│   ├── firebase_service.dart
│   ├── notification_service.dart
│   ├── offline_sync_service.dart
│   ├── rate_limiter.dart
│   ├── secure_storage_service.dart
│   └── sync_service.dart
├── utils/                    # Utilidades y configuraciones
│   ├── preferences.dart      # Gestion de preferencias locales
│   └── validators/           # Validadores de datos
│       └── validators.dart
├── models/                   # (Carpeta disponible para modelos)
├── examples/                 # Ejemplos de uso
│   ├── ejemplos_ecuador.dart
│   ├── ejemplos_fase_1.dart
│   └── ejemplos_fase_3.dart
└── testing/                  # Pruebas y widgets
    ├── testing_page.dart
    └── sync_testing_widget.dart

test/
├── validators_ecuador_test.dart
├── rate_limiter_test.dart
├── settings_contacts_test.dart
└── widget_test.dart
```

---

## Descripcion Detallada de Carpetas

### screens/ - Interfaz de Usuario

Contiene todas las pantallas/paginas de la aplicacion. Cada archivo es un `StatefulWidget` o `StatelessWidget` que representa una pantalla completa.

**Archivos:**
- **documents_page.dart** - Pantalla de gestion de documentos
- **options_page.dart** - Pantalla de opciones principales
- **settings_page.dart** - Pantalla de configuracion/ajustes
- **symptoms_page.dart** - Pantalla de sintomas
- **tutorial_screen.dart** - Pantalla de tutorial inicial

**Responsabilidades:**
- Renderizar la interfaz de usuario
- Manejar interacciones del usuario
- Comunicarse con servicios
- Mostrar datos del estado de la aplicacion

---

### services/ - Logica de Negocio y Servicios

Contiene la logica de negocio, integraciones externas y servicios reutilizables.

**Categorias de Servicios:**

#### Seguridad y Almacenamiento
- **secure_storage_service.dart** - Almacenamiento encriptado de datos sensibles
- **encryption_service.dart** - Funciones de encriptacion

#### Notificaciones y Recordatorios
- **notification_service.dart** - Gestion de notificaciones push (FCM)
- **appointment_reminder_service.dart** - Recordatorios de citas medicas

#### Sincronizacion y Base de Datos
- **firebase_service.dart** - Integracion con Firebase
- **sync_service.dart** - Sincronizacion de datos
- **offline_sync_service.dart** - Sincronizacion en modo offline

#### Alertas y Contactos
- **alert_service.dart** - Gestion de alertas de emergencia
- **contact_service.dart** - Gestion de contactos

#### Control y Utilidades
- **rate_limiter.dart** - Control de limite de velocidad

**Responsabilidades:**
- Implementar logica de negocio
- Interactuar con APIs externas
- Manejar datos persistentes
- Proveer interfaces limpias a las pantallas

---

### utils/ - Utilidades y Configuraciones

Contiene codigo reutilizable y funciones auxiliares.

**Archivos:**
- **preferences.dart** - Gestion de SharedPreferences
- **validators/** - Carpeta con validadores de datos
  - **validators.dart** - Funciones de validacion

**Responsabilidades:**
- Validar entrada del usuario
- Gestionar datos de preferencias locales
- Proveer utilidades genericas reutilizables

---

### examples/ - Ejemplos y Referencias

Contiene codigo de ejemplo que muestra como usar caracteristicas especificas.

**Archivos:**
- **ejemplos_ecuador.dart** - Ejemplos especificos para Ecuador
- **ejemplos_fase_1.dart** - Ejemplos de la Fase 1 implementada
- **ejemplos_fase_3.dart** - Ejemplos de integracion con Firebase

**Proposito:**
- Documentacion mediante codigo
- Referencias de implementacion
- Guias de uso de servicios

---

### testing/ - Pruebas y Widgets de Testing

Contiene widgets y codigo usado para pruebas y debugging durante el desarrollo.

**Archivos:**
- **testing_page.dart** - Pantalla de testing general
- **sync_testing_widget.dart** - Widget especifico para probar sincronizacion

---

### models/ - Modelos de Datos

Carpeta reservada para modelos de datos (DTOs, clases de dominio, etc.).

**Uso futuro:**
- Modelos de Firebase
- DTOs para API
- Clases de dominio

---

## Archivos en Raiz

- **main.dart** - Punto de entrada de la aplicacion
  - Inicializa Firebase
  - Configura servicios
  - Define rutas de navegacion
  - Maneja el flujo del tutorial

---

## Convenciones de Nombres

### Archivos

- **Pantallas:** `{nombre}_page.dart` o `{nombre}_screen.dart`
- **Servicios:** `{nombre}_service.dart`
- **Validadores:** `validators.dart`
- **Ejemplos:** `ejemplos_{fase}.dart`
- **Tests:** `{modulo}_test.dart`

### Carpetas

- Usar **snake_case** en minusculas: `services`, `screens`, `utils`

### Clases

- Usar **PascalCase**: `DocumentsPage`, `FirebaseService`, `Validators`

### Metodos y Variables

- Usar **camelCase**: `_checkTutorialStatus()`, `_selectedIndex`

---

## Flujo de Importaciones

### Importaciones Correctas

**Desde main.dart:**
```dart
import 'screens/options_page.dart';
import 'services/firebase_service.dart';
import 'utils/validators/validators.dart';
```

**Desde screens/ hacia services/**
```dart
import '../services/alert_service.dart';
import '../utils/preferences.dart';
```

**Desde services/ hacia utils/**
```dart
import '../utils/preferences.dart';
```

### Evitar

- Importaciones ciclicas (A → B → A)
- Importaciones cruzadas entre pantallas (screens → screens)
- Importaciones de detalles de implementacion

---

## Beneficios de esta Estructura

| Beneficio | Descripcion |
|-----------|-------------|
| **Modularidad** | Cada modulo es independiente y reutilizable |
| **Escalabilidad** | Facil agregar nuevas pantallas, servicios o utilidades |
| **Mantenibilidad** | Codigo organizado y facil de encontrar |
| **Testabilidad** | Servicios separados facilitan pruebas unitarias |
| **Separacion de responsabilidades** | Cada carpeta tiene un proposito claro |
| **Onboarding** | Nuevos desarrolladores entienden rapidamente la estructura |

---

## Relacion entre Capas

```
                    Punto de entrada
                    ┌─────────────┐
                    │ main.dart   │
                    └──────┬──────┘
                           │
                ┌──────────▼──────────┐
                │ screens/            │  (Presentacion)
                │ (Paginas, Widgets)  │
                └──────────┬──────────┘
                           │
                ┌──────────▼──────────┐
                │ services/           │  (Logica)
                │ (Firebase, Sync)    │
                └──────────┬──────────┘
                           │
                ┌──────────▼──────────┐
                │ utils/              │  (Utilidades)
                │ (Validators, Prefs) │
                └─────────────────────┘
```

**Direccion del flujo:**
- Las pantallas (screens) llaman a servicios
- Los servicios usan utilidades (utils)
- Las utilidades son independientes
- No debe haber flujo inverso

---

## Estadisticas

| Categoria | Cantidad |
|-----------|----------|
| Pantallas | 5 |
| Servicios | 10 |
| Validadores | 1 modulo |
| Archivos de ejemplo | 3 |
| Archivos de testing | 2 |
| Archivos de test | 4 |

---

## Notas Importantes

1. **Preferencias locales** - Usar `utils/preferences.dart`
2. **Validacion de datos** - Usar `utils/validators/validators.dart`
3. **Alertas de emergencia** - Usar `services/alert_service.dart`
4. **Firebase** - Usar `services/firebase_service.dart`
5. **Notificaciones** - Usar `services/notification_service.dart`
6. **Sincronizacion offline** - Usar `services/offline_sync_service.dart`

---

## Proximos Pasos Recomendados

1. Crear `models/` con DTOs especificas
2. Organizar ejemplos en carpeta separada
3. Implementar tests unitarios en `test/`
4. Crear archivo `constants.dart` en `utils/`
5. Documentar cada servicio con ejemplos

---

**Nota:** Esta estructura es flexible y puede adaptarse segun las necesidades del proyecto.

**Ultimo cambio:** 20 de agosto de 2026 - Estructura y contenido actualizado.
