import 'package:flutter/material.dart';
import 'services/rate_limiter.dart';

/// Ejemplos de uso del Rate Limiter en la aplicación
class RateLimiterExamples {
  /// Ejemplo 1: Verificar si una acción está permitida
  static Future<void> example1_CheckIfAllowed() async {
    const String action = 'panic_button_main';
    const int maxAttempts = 3;
    const int windowHours = 3;

    // Verificar si está permitida la acción
    final canExecute = await RateLimiter.canExecute(
      action: action,
      maxAttempts: maxAttempts,
      windowHours: windowHours,
    );

    if (canExecute) {
      print('✅ Acción permitida - proceder');
    } else {
      print('❌ Límite alcanzado - esperar');
    }
  }

  /// Ejemplo 2: Obtener información detallada del rate limit
  static Future<void> example2_GetDetailedInfo() async {
    const String action = 'panic_button_main';

    final info = await RateLimiter.getInfo(
      action: action,
      maxAttempts: 3,
      windowHours: 3,
    );

    print('Intentos usados: ${info.attemptsUsed}/${info.maxAttempts}');
    print('Intentos restantes: ${info.attemptsRemaining}');
    print('¿Limitado?: ${info.isLimited}');
    print('Información legible: ${info.readableInfo}');
    
    if (info.nextAvailableTime != null) {
      print('Próximo intento disponible: ${info.nextAvailableTime}');
    }
  }

  /// Ejemplo 3: Mostrar mensaje de UI cuando está limitado
  static Future<void> example3_ShowLimitMessageUI(BuildContext context) async {
    const String action = 'panic_button_main';

    // Verificar si está permitido
    final canExecute = await RateLimiter.canExecute(
      action: action,
      maxAttempts: 3,
      windowHours: 3,
    );

    if (!canExecute) {
      // Obtener información para mostrar
      final info = await RateLimiter.getInfo(
        action: action,
        maxAttempts: 3,
        windowHours: 3,
      );

      // Mostrar snackbar con información
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('⏱️ ${info.readableInfo}'),
          duration: const Duration(seconds: 4),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  /// Ejemplo 4: Resetear el contador (útil para testing o admin)
  static Future<void> example4_ResetCounter() async {
    const String action = 'panic_button_main';

    // Resetear solo este contador
    await RateLimiter.reset(action: action);
    print('✅ Contador reseteado para: $action');
  }

  /// Ejemplo 5: Resetear todos los contadores
  static Future<void> example5_ResetAllCounters() async {
    // Resetear TODOS los rate limiters
    await RateLimiter.resetAll();
    print('✅ Todos los contadores reseteados');
  }

  /// Ejemplo 6: Implementación completa en un botón
  static Widget example6_ButtonWithRateLimit(BuildContext context) {
    return ElevatedButton(
      onPressed: () async {
        final canExecute = await RateLimiter.canExecute(
          action: 'panic_button_main',
          maxAttempts: 3,
          windowHours: 3,
        );

        if (!canExecute) {
          final info = await RateLimiter.getInfo(
            action: 'panic_button_main',
            maxAttempts: 3,
            windowHours: 3,
          );

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(info.readableInfo)),
          );
          return;
        }

        // Proceder con la acción
        print('🚨 Ejecutando acción de pánico');
      },
      child: const Text('Botón de Pánico'),
    );
  }

  /// Ejemplo 7: Usar variables configurables
  static Future<void> example7_CustomConfiguration() async {
    const String action = 'custom_action';
    const int maxAttempts = 5; // 5 intentos
    const int windowHours = 12; // En 12 horas

    final canExecute = await RateLimiter.canExecute(
      action: action,
      maxAttempts: maxAttempts,
      windowHours: windowHours,
    );

    print('Acción personalizada permitida: $canExecute');
  }

  /// Ejemplo 8: Mostrar información en tiempo real durante cada intento
  static Future<void> example8_TrackAllAttempts() async {
    const String action = 'track_all_attempts';

    // Simular 5 intentos
    for (int i = 1; i <= 5; i++) {
      print('\n--- Intento $i ---');

      final canExecute = await RateLimiter.canExecute(
        action: action,
        maxAttempts: 3,
        windowHours: 1,
      );

      final info = await RateLimiter.getInfo(
        action: action,
        maxAttempts: 3,
        windowHours: 1,
      );

      print('¿Permitido?: $canExecute');
      print('Estado: ${info.readableInfo}');

      // Pequeña pausa para simular
      await Future.delayed(const Duration(milliseconds: 500));
    }
  }
}

/// Widget de demostración del Rate Limiter
class RateLimiterDemoPage extends StatefulWidget {
  const RateLimiterDemoPage({super.key});

  @override
  State<RateLimiterDemoPage> createState() => _RateLimiterDemoPageState();
}

class _RateLimiterDemoPageState extends State<RateLimiterDemoPage> {
  String _statusMessage = 'Presiona un botón para empezar';
  RateLimitInfo? _currentInfo;

  Future<void> _checkStatus() async {
    final info = await RateLimiter.getInfo(
      action: 'panic_button_main',
      maxAttempts: 3,
      windowHours: 3,
    );

    setState(() {
      _currentInfo = info;
      _statusMessage = info.readableInfo;
    });
  }

  Future<void> _attemptAction() async {
    final canExecute = await RateLimiter.canExecute(
      action: 'panic_button_main',
      maxAttempts: 3,
      windowHours: 3,
    );

    if (canExecute) {
      setState(() {
        _statusMessage = '✅ Acción ejecutada exitosamente';
      });
    } else {
      final info = await RateLimiter.getInfo(
        action: 'panic_button_main',
        maxAttempts: 3,
        windowHours: 3,
      );
      setState(() {
        _statusMessage = '❌ Límite alcanzado: ${info.readableInfo}';
      });
    }

    await _checkStatus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rate Limiter Demo')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Card(
              margin: const EdgeInsets.all(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      _statusMessage,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 18),
                    ),
                    if (_currentInfo != null) ...[
                      const SizedBox(height: 12),
                      Text('Intentos: ${_currentInfo!.attemptsUsed}/${_currentInfo!.maxAttempts}'),
                      Text('Restantes: ${_currentInfo!.attemptsRemaining}'),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _attemptAction,
              child: const Text('Intentar Acción'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _checkStatus,
              child: const Text('Ver Estado'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () async {
                await RateLimiter.reset(action: 'panic_button_main');
                await _checkStatus();
                setState(() => _statusMessage = '✅ Contador reseteado');
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              child: const Text('Resetear'),
            ),
          ],
        ),
      ),
    );
  }
}
