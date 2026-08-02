# Test Automatizado de Notificaciones 🔔

Este proyecto incluye un test automatizado que simula el envío de notificaciones a intervalos específicos.

## Intervalos de Prueba

Las notificaciones se envían en los siguientes intervalos:
- **30 segundos** - Notificación #1
- **1 minuto** - Notificación #2  
- **2 minutos** - Notificación #3

**Tiempo total: 3.5 minutos**

## Cómo Ejecutar el Test

### 1. Test Unitario Automatizado (Recomendado)

Ejecuta el test desde la terminal:

```bash
# Desde la carpeta raíz del proyecto
flutter test test/notification_intervals_test.dart

# O para ver más detalles
flutter test test/notification_intervals_test.dart -v

# O para ejecutar todos los tests
flutter test
```

### 2. Usar el Servicio de Prueba en la App (Testing Manual)

El proyecto también incluye `NotificationTestService` para enviar notificaciones reales durante el desarrollo.

#### En tu página de ajustes o desarrollo, agrega:

```dart
import 'services/notification_test_service.dart';

// En un botón o método
Future<void> _startTestNotifications() async {
  final testService = NotificationTestService.instance();
  await testService.initialize();
  await testService.startTestNotifications();
  
  print('Test iniciado. Notificaciones se enviarán en intervalos.');
}
```

## Archivos Relacionados

### Test
- `test/notification_intervals_test.dart` - Test automatizado unitario

### Servicios
- `lib/services/notification_service.dart` - Servicio principal de notificaciones (FCM)
- `lib/services/notification_test_service.dart` - Servicio para testing
- `lib/services/alert_service.dart` - Gestión de alertas

## Resultado Esperado del Test

```
🚀 Iniciando test de notificaciones (30s, 1m, 2m)...

📋 Notificaciones programadas:

1. Demora: 30s
   Título: 🔔 Notificación 1
   Contenido: Primera notificación enviada después de 30 segundos

2. Demora: 1m
   Título: 🔔 Notificación 2
   Contenido: Segunda notificación enviada después de 1 minuto

3. Demora: 2m
   Título: 🔔 Notificación 3
   Contenido: Tercera notificación enviada después de 2 minutos

⏳ Simulando envío de notificaciones...

[HH:MM:SS] 📤 Notificación #1 enviada
             Título: 🔔 Notificación 1
             Intervalo: 30s

[HH:MM:SS] 📤 Notificación #2 enviada
             Título: 🔔 Notificación 2
             Intervalo: 1m

[HH:MM:SS] 📤 Notificación #3 enviada
             Título: 🔔 Notificación 3
             Intervalo: 2m

✅ Todas las notificaciones fueron "enviadas" correctamente
✅ Test completado exitosamente
```

## Modificar los Intervalos

Para cambiar los intervalos de prueba, edita `test/notification_intervals_test.dart`:

```dart
NotificationSchedule(
  delay: const Duration(seconds: 30),  // ← Cambiar este valor
  title: '🔔 Notificación 1',
  body: 'Primera notificación...',
),
```

O en `lib/services/notification_test_service.dart`:

```dart
_scheduleNotification(
  delay: const Duration(seconds: 30),  // ← Cambiar este valor
  title: '🔔 Notificación #1',
  body: '...',
  index: 1,
);
```

## Notas Importantes

- El test **no requiere un dispositivo físico** ni emulador corriendo
- Es puramente automatizado y se ejecuta en segundos (simulación)
- Los intervalos reales de FCM pueden variar en dispositivos reales
- Para enviar notificaciones **reales** en producción, necesitarás un backend con Firebase Admin SDK

## Dependencias Necesarias

Asegúrate de tener estas dependencias en `pubspec.yaml`:

```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  mockito: ^5.4.0
  build_runner: ^2.4.0

dependencies:
  firebase_messaging: ^14.0.0
```

Para instalar las dependencias:

```bash
flutter pub get
```

## Troubleshooting

### Error: "flutter test not found"
Asegúrate de tener Flutter en el PATH. Ejecuta:
```bash
flutter --version
```

### Error: "Archivo de test no encontrado"
Verifica que el archivo esté en `test/notification_intervals_test.dart` (nota la carpeta `test/`)

### Las notificaciones no se envían
El test es una simulación. Para notificaciones reales, usa `NotificationTestService` en la app.

---

**Creado:** 2026-06-22  
**Última actualización:** 2026-06-22
