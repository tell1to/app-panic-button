# Rate Limiter - Fase 2: Control de Intentos

## Resumen

El **Rate Limiter** es un sistema de control de acceso que limita el número de veces que se puede activar una acción (como el botón de pánico) dentro de un período de tiempo específico. Esto previene:

- ✅ Activaciones accidentales repetidas
- ✅ Abuso del sistema
- ✅ Llamadas no deseadas
- ✅ Consumo excesivo de recursos

## Configuración por Defecto

```dart
// Para el botón de pánico en main.dart
static const int _maxPanicAttempts = 3;        // 3 intentos máximo
static const int _panicLimitWindowHours = 3;   // En un período de 3 horas
```

**Ejemplo:**
- Usuario puede activar el botón máximo 3 veces
- Después del 3er intento, debe esperar hasta que pasen 3 horas desde el 1er intento
- El contador se reinicia automáticamente

## Flujo de Funcionamiento

### 1. Usuario intenta activar el botón de pánico

```
Usuario sostiene el botón → Se verifica Rate Limit
```

### 2. El sistema verifica

```dart
final canActivate = await RateLimiter.canExecute(
  action: _panicButtonAction,           // 'panic_button_main'
  maxAttempts: _maxPanicAttempts,       // 3
  windowHours: _panicLimitWindowHours,  // 3
);
```

### 3. Si está permitido ✅

```
Registra el intento en almacenamiento persistente
↓
Procede con la activación (llamada, alerta, etc.)
```

### 4. Si alcanzó el límite ❌

```
Obtiene información del siguiente intento disponible
↓
Muestra mensaje: "Intenta en 2h 45m" (ejemplo)
↓
Cancela la activación
```

## Ejemplos de Uso

### Verificación Básica

```dart
final canActivate = await RateLimiter.canExecute(
  action: 'panic_button_main',
  maxAttempts: 3,
  windowHours: 3,
);

if (canActivate) {
  // Proceder con activación
} else {
  // Mostrar error
}
```

### Obtener Información Detallada

```dart
final info = await RateLimiter.getInfo(
  action: 'panic_button_main',
  maxAttempts: 3,
  windowHours: 3,
);

print('Intentos usados: ${info.attemptsUsed}');     // 2
print('Intentos restantes: ${info.attemptsRemaining}'); // 1
print('¿Limitado?: ${info.isLimited}');              // false
print('Info legible: ${info.readableInfo}');        // "2/3 intentos usados"
```

### Usar con UI (SnackBar)

```dart
if (!canActivate) {
  final info = await RateLimiter.getInfo(
    action: 'panic_button_main',
    maxAttempts: 3,
    windowHours: 3,
  );

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('⏱️ ${info.readableInfo}'),
      backgroundColor: Colors.red,
    ),
  );
}
```

## Clase RateLimitInfo

Contiene información detallada sobre el estado del rate limit:

```dart
class RateLimitInfo {
  final int attemptsUsed;              // 2 (intentos realizados)
  final int maxAttempts;               // 3 (máximo permitido)
  final int windowHours;               // 3 (período en horas)
  final bool isLimited;                // false (si alcanzó el límite)
  final Duration? timeUntilNextAttempt; // Duration(hours: 2, minutes: 45)
  final DateTime? nextAvailableTime;    // 2025-12-22 15:30:00
  
  // Métodos útiles
  int get attemptsRemaining => 1;      // Intentos aún disponibles
  String get readableInfo => '2/3 intentos usados';
}
```

## Almacenamiento

El Rate Limiter utiliza **SharedPreferences** para almacenamiento persistente:

- Los timestamps se guardan en ISO8601 format
- Se filtran automáticamente los timestamps fuera de la ventana
- Persiste entre reinicios de la aplicación
- No requiere permisos especiales

**Clave de almacenamiento:**
```
'rate_limit_timestamps_panic_button_main'
```

## Mensajes al Usuario

### Intento Permitido ✅
```
"Alerta activada: notificando contactos y servicios"
```

### Límite Alcanzado ❌
```
"Límite de intentos alcanzado. Intenta en 2h 45m"
```

## Casos de Uso en la Aplicación

### 1. Botón de Pánico Principal (main.dart)

```dart
// En _activateEmergency()
final canActivate = await RateLimiter.canExecute(
  action: 'panic_button_main',
  maxAttempts: 3,
  windowHours: 3,
);

if (!canActivate) {
  // Mostrar mensaje y cancelar
  return;
}

// Proceder con llamada/alerta
```

### 2. Proteger Formularios (senttings.dart)

Puede aplicarse también a:
```dart
// Envío de formulario de contactos
RateLimiter.canExecute(
  action: 'submit_contacts_form',
  maxAttempts: 5,
  windowHours: 1,
)

// Cambio de información crítica
RateLimiter.canExecute(
  action: 'change_critical_info',
  maxAttempts: 10,
  windowHours: 24,
)
```

## Configuración Personalizada

### Cambiar Límites para el Botón de Pánico

```dart
// En main.dart, modificar constantes:
static const int _maxPanicAttempts = 5;      // 5 intentos
static const int _panicLimitWindowHours = 4; // En 4 horas
```

### Crear Nuevo Rate Limiter

```dart
// Para una acción diferente
final canExecute = await RateLimiter.canExecute(
  action: 'custom_action',
  maxAttempts: 10,
  windowHours: 24,
);
```

## Testing y Debugging

### Ver Estado Actual

```dart
final info = await RateLimiter.getInfo(
  action: 'panic_button_main',
  maxAttempts: 3,
  windowHours: 3,
);

print(info); // Imprime información completa
```

### Resetear Contador (Development)

```dart
// Resetear solo un contador
await RateLimiter.reset(action: 'panic_button_main');

// Resetear TODOS los contadores
await RateLimiter.resetAll();
```

### Simular Múltiples Intentos

Ver archivo `EJEMPLOS_RATE_LIMITER.dart` - método `example8_TrackAllAttempts()`

## Flujo Completo en main.dart

```
Usuario sostiene botón de pánico
    ↓
_startHold() inicia progreso visual
    ↓
1.2 segundos pasan
    ↓
_activateEmergency() es llamado
    ↓
RateLimiter.canExecute() verifica el límite
    ↓
    ├─ ✅ Si está permitido:
    │  ├─ Registra el intento
    │  ├─ Muestra "Alerta activada"
    │  └─ Realiza la llamada/alerta
    │
    └─ ❌ Si alcanzó el límite:
       ├─ Obtiene información
       ├─ Muestra mensaje de tiempo restante
       └─ Cancela la acción
```

## Ventajas

1. ✅ **Protección contra errores**: Evita activaciones accidentales
2. ✅ **Seguridad**: Previene abuso malicioso
3. ✅ **Persistencia**: Se mantiene entre reinicios
4. ✅ **Flexible**: Configurable por acción
5. ✅ **No afecta emergencias**: Mensaje claro y acciones bloqueadas solo cuando hay intento accidental
6. ✅ **Información útil**: Usuario sabe exactamente cuándo puede intentar de nuevo

## Próximas Mejoras

- [ ] Panel de administrador para ver/resetear rate limits
- [ ] Notificaciones cuando se alcanza el límite
- [ ] Estadísticas de intentos bloqueados
- [ ] Diferentes límites según tipo de usuario
- [ ] Integración con analytics

## Archivos Relacionados

- `lib/services/rate_limiter.dart` - Implementación del servicio
- `lib/main.dart` - Integración con botón de pánico
- `lib/EJEMPLOS_RATE_LIMITER.dart` - Ejemplos y demostración

## Resumen Técnico

| Aspecto | Detalle |
|---------|---------|
| **Almacenamiento** | SharedPreferences |
| **Persistencia** | Sí (entre reinicios) |
| **Thread-safe** | Sí (SharedPreferences maneja esto) |
| **Límite por defecto** | 3 intentos en 3 horas |
| **Identificación** | Por action string único |
| **Expiración automática** | Sí (timestamps fuera de ventana se ignoran) |
