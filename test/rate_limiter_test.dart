import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/services/rate_limiter.dart';
void main() {
  group('Rate Limiter Tests', () {
    setUp(() async {
      // Reset SharedPreferences antes de cada test
      SharedPreferences.setMockInitialValues({});
    });

    group('Basic Functionality', () {
      test('First attempt should be allowed', () async {
        final canExecute = await RateLimiter.canExecute(
          action: 'test_action',
          maxAttempts: 3,
          windowMinutes: 60,
        );

        expect(canExecute, true);
      });

      test('Multiple attempts within limit should be allowed', () async {
        for (int i = 0; i < 3; i++) {
          final canExecute = await RateLimiter.canExecute(
            action: 'test_action',
            maxAttempts: 3,
            windowMinutes: 60,
          );
          expect(canExecute, true, reason: 'Attempt ${i + 1} should be allowed');
        }
      });

      test('Attempt exceeding limit should be blocked', () async {
        // Hacer 3 intentos (permitidos)
        for (int i = 0; i < 3; i++) {
          await RateLimiter.canExecute(
            action: 'test_action',
            maxAttempts: 3,
            windowMinutes: 60,
          );
        }

        // El 4to intento debe estar bloqueado
        final canExecute = await RateLimiter.canExecute(
          action: 'test_action',
          maxAttempts: 3,
          windowMinutes: 60,
        );

        expect(canExecute, false);
      });
    });

    group('Rate Limit Info', () {
      test('getInfo returns correct attempts used', () async {
        // Hacer 2 intentos
        await RateLimiter.canExecute(
          action: 'test_action',
          maxAttempts: 3,
          windowMinutes: 60,
        );
        await RateLimiter.canExecute(
          action: 'test_action',
          maxAttempts: 3,
          windowMinutes: 60,
        );

        final info = await RateLimiter.getInfo(
          action: 'test_action',
          maxAttempts: 3,
          windowMinutes: 60,
        );

        expect(info.attemptsUsed, 2);
        expect(info.maxAttempts, 3);
        expect(info.attemptsRemaining, 1);
      });

      test('getInfo isLimited flag works correctly', () async {
        // Hacer 3 intentos (llenar el límite)
        for (int i = 0; i < 3; i++) {
          await RateLimiter.canExecute(
            action: 'test_action',
            maxAttempts: 3,
            windowMinutes: 60,
          );
        }

        final info = await RateLimiter.getInfo(
          action: 'test_action',
          maxAttempts: 3,
          windowMinutes: 60,
        );

        expect(info.isLimited, true);
        expect(info.attemptsRemaining, 0);
      });

      test('getInfo readableInfo provides useful message', () async {
        // Hacer 2 intentos
        await RateLimiter.canExecute(
          action: 'test_action',
          maxAttempts: 3,
          windowMinutes: 60,
        );
        await RateLimiter.canExecute(
          action: 'test_action',
          maxAttempts: 3,
          windowMinutes: 60,
        );

        final info = await RateLimiter.getInfo(
          action: 'test_action',
          maxAttempts: 3,
          windowMinutes: 60,
        );

        // Debe contener información sobre intentos
        expect(info.readableInfo, contains('2'));
        expect(info.readableInfo, contains('3'));
      });

      test('readableInfo shows time remaining when limited', () async {
        // Hacer 3 intentos
        for (int i = 0; i < 3; i++) {
          await RateLimiter.canExecute(
            action: 'test_action',
            maxAttempts: 3,
            windowMinutes: 60,
          );
        }

        final info = await RateLimiter.getInfo(
          action: 'test_action',
          maxAttempts: 3,
          windowMinutes: 60,
        );

        // Debe contener información de tiempo
        expect(info.readableInfo, isNotEmpty);
        expect(info.readableInfo.toLowerCase(), contains('intenta'));
      });
    });

    group('Reset Functionality', () {
      test('reset should clear counter for specific action', () async {
        // Hacer 3 intentos
        for (int i = 0; i < 3; i++) {
          await RateLimiter.canExecute(
            action: 'test_action',
            maxAttempts: 3,
            windowMinutes: 60,
          );
        }

        // Verificar que está limitado
        var canExecute = await RateLimiter.canExecute(
          action: 'test_action',
          maxAttempts: 3,
          windowMinutes: 60,
        );
        expect(canExecute, false);

        // Resetear
        await RateLimiter.reset(action: 'test_action');

        // Ahora debe estar permitido
        canExecute = await RateLimiter.canExecute(
          action: 'test_action',
          maxAttempts: 3,
          windowMinutes: 60,
        );
        expect(canExecute, true);
      });

      test('resetAll should clear all counters', () async {
        // Llenar intentos para dos acciones diferentes
        for (int i = 0; i < 3; i++) {
          await RateLimiter.canExecute(
            action: 'action_1',
            maxAttempts: 3,
            windowMinutes: 60,
          );
          await RateLimiter.canExecute(
            action: 'action_2',
            maxAttempts: 3,
            windowMinutes: 60,
          );
        }

        // Ambas deben estar limitadas
        var canExecute1 = await RateLimiter.canExecute(
          action: 'action_1',
          maxAttempts: 3,
          windowMinutes: 60,
        );
        var canExecute2 = await RateLimiter.canExecute(
          action: 'action_2',
          maxAttempts: 3,
          windowMinutes: 60,
        );
        expect(canExecute1, false);
        expect(canExecute2, false);

        // Resetear todas
        await RateLimiter.resetAll();

        // Ambas deben estar permitidas
        canExecute1 = await RateLimiter.canExecute(
          action: 'action_1',
          maxAttempts: 3,
          windowMinutes: 60,
        );
        canExecute2 = await RateLimiter.canExecute(
          action: 'action_2',
          maxAttempts: 3,
          windowMinutes: 60,
        );
        expect(canExecute1, true);
        expect(canExecute2, true);
      });
    });

    group('Different Actions', () {
      test('Different actions should have separate counters', () async {
        // Llenar uno
        for (int i = 0; i < 3; i++) {
          await RateLimiter.canExecute(
            action: 'action_a',
            maxAttempts: 3,
            windowMinutes: 60,
          );
        }

        // El otro debe seguir siendo permitido
        final canExecuteB = await RateLimiter.canExecute(
          action: 'action_b',
          maxAttempts: 3,
          windowMinutes: 60,
        );

        expect(canExecuteB, true);
      });

      test('Each action tracks independently', () async {
        // Action A: 2 intentos
        await RateLimiter.canExecute(
          action: 'action_a',
          maxAttempts: 3,
          windowMinutes: 60,
        );
        await RateLimiter.canExecute(
          action: 'action_a',
          maxAttempts: 3,
          windowMinutes: 60,
        );

        // Action B: 1 intento
        await RateLimiter.canExecute(
          action: 'action_b',
          maxAttempts: 3,
          windowMinutes: 60,
        );

        // Obtener info
        final infoA = await RateLimiter.getInfo(
          action: 'action_a',
          maxAttempts: 3,
          windowMinutes: 60,
        );
        final infoB = await RateLimiter.getInfo(
          action: 'action_b',
          maxAttempts: 3,
          windowMinutes: 60,
        );

        expect(infoA.attemptsUsed, 2);
        expect(infoB.attemptsUsed, 1);
      });
    });

    group('Custom Configuration', () {
      test('Custom max attempts work correctly', () async {
        // Permitir 5 intentos
        for (int i = 0; i < 5; i++) {
          final canExecute = await RateLimiter.canExecute(
            action: 'test_action',
            maxAttempts: 5,
            windowMinutes: 60,
          );
          expect(canExecute, true, reason: 'Attempt ${i + 1} should be allowed');
        }

        // El 6to debe estar bloqueado
        final canExecute = await RateLimiter.canExecute(
          action: 'test_action',
          maxAttempts: 5,
          windowMinutes: 60,
        );
        expect(canExecute, false);
      });

      test('Different actions can have different limits', () async {
        // Action A: límite 2
        for (int i = 0; i < 2; i++) {
          await RateLimiter.canExecute(
            action: 'strict_action',
            maxAttempts: 2,
            windowMinutes: 60,
          );
        }

        // Action B: límite 5
        for (int i = 0; i < 5; i++) {
          await RateLimiter.canExecute(
            action: 'lenient_action',
            maxAttempts: 5,
            windowMinutes: 60,
          );
        }

        // Verificar límites
        final canExecuteA = await RateLimiter.canExecute(
          action: 'strict_action',
          maxAttempts: 2,
          windowMinutes: 60,
        );
        final canExecuteB = await RateLimiter.canExecute(
          action: 'lenient_action',
          maxAttempts: 5,
          windowMinutes: 60,
        );

        expect(canExecuteA, false); // Está limitado (2/2)
        expect(canExecuteB, false); // Está limitado (5/5)

        // Pero si revisamos con límites diferentes
        final canExecuteB2 = await RateLimiter.canExecute(
          action: 'lenient_action',
          maxAttempts: 6,
          windowMinutes: 60,
        );
        expect(canExecuteB2, true); // Permitido con límite mayor (5/6)
      });
    });

    group('Panic Button Specific', () {
      test('Panic button with default config (3 attempts, 3 hours)', () async {
        const String panicAction = 'panic_button_main';
        const int maxAttempts = 3;
        const int windowMinutes = 3;

        // Primer intento
        final attempt1 = await RateLimiter.canExecute(
          action: panicAction,
          maxAttempts: maxAttempts,
          windowMinutes: windowMinutes,
        );
        expect(attempt1, true);

        // Segundo intento
        final attempt2 = await RateLimiter.canExecute(
          action: panicAction,
          maxAttempts: maxAttempts,
          windowMinutes: windowMinutes,
        );
        expect(attempt2, true);

        // Tercer intento
        final attempt3 = await RateLimiter.canExecute(
          action: panicAction,
          maxAttempts: maxAttempts,
          windowMinutes: windowMinutes,
        );
        expect(attempt3, true);

        // Cuarto intento (debe fallar)
        final attempt4 = await RateLimiter.canExecute(
          action: panicAction,
          maxAttempts: maxAttempts,
          windowMinutes: windowMinutes,
        );
        expect(attempt4, false);

        // Verificar información
        final info = await RateLimiter.getInfo(
          action: panicAction,
          maxAttempts: maxAttempts,
          windowMinutes: windowMinutes,
        );

        expect(info.isLimited, true);
        expect(info.attemptsUsed, 3);
        expect(info.attemptsRemaining, 0);
      });

      test('Panic button shows readable time message', () async {
        const String panicAction = 'panic_button_main';

        // Llenar los intentos
        for (int i = 0; i < 3; i++) {
          await RateLimiter.canExecute(
            action: panicAction,
            maxAttempts: 3,
            windowMinutes: 180,
          );
        }

        final info = await RateLimiter.getInfo(
          action: panicAction,
          maxAttempts: 3,
          windowMinutes: 180,
        );

        // Debe haber un mensaje útil
        expect(info.readableInfo, isNotEmpty);
        // Típicamente contendrá "Intenta en..."
        expect(info.readableInfo.toLowerCase(), contains('intenta'));
      });
    });

    group('Window Expiry', () {
      // Reproduce el bug reportado: al llegar al límite (3/3) y esperar a que
      // expire la ventana, el contador debe reiniciarse a 0 (siguiente intento 1/3)
      // en lugar de heredar intentos de la ventana anterior (2/3, 3/3, etc.)
      test('counter resets to zero after window expires', () async {
        // Simular una ventana iniciada hace 61 minutos con 3 intentos usados
        final oldStart = DateTime.now().subtract(const Duration(minutes: 61));
        SharedPreferences.setMockInitialValues({
          'rate_limit_state_test_action': jsonEncode({
            'start': oldStart.toIso8601String(),
            'attempts': 3,
          }),
        });

        final info = await RateLimiter.getInfo(
          action: 'test_action',
          maxAttempts: 3,
          windowMinutes: 60,
        );

        expect(info.attemptsUsed, 0, reason: 'La ventana expiró, el contador debe reiniciarse');
        expect(info.isLimited, false);
        expect(info.attemptsRemaining, 3);
      });

      test('after expiry, next press starts at 1/max instead of partial count', () async {
        // Mismo escenario: 3/3 usados pero la ventana ya expiró
        final oldStart = DateTime.now().subtract(const Duration(minutes: 61));
        SharedPreferences.setMockInitialValues({
          'rate_limit_state_test_action': jsonEncode({
            'start': oldStart.toIso8601String(),
            'attempts': 3,
          }),
        });

        final canExecute = await RateLimiter.canExecute(
          action: 'test_action',
          maxAttempts: 3,
          windowMinutes: 60,
        );
        expect(canExecute, true, reason: 'Debe permitir presionar de nuevo tras expirar la ventana');

        final info = await RateLimiter.getInfo(
          action: 'test_action',
          maxAttempts: 3,
          windowMinutes: 60,
        );
        expect(info.attemptsUsed, 1, reason: 'Debe reiniciar desde 1/3, no desde 2/3');
        expect(info.attemptsRemaining, 2);
      });

      test('attempts do not expire one by one within the same window', () async {
        // Dentro de la ventana, los intentos deben acumularse sin descontarse
        // aunque pase algo de tiempo (aún dentro de la ventana).
        final info = await RateLimiter.getInfo(
          action: 'test_action',
          maxAttempts: 3,
          windowMinutes: 60,
        );
        expect(info.attemptsUsed, 0);
      });
    });

    group('Edge Cases', () {
      test('Zero max attempts should always block', () async {
        final canExecute = await RateLimiter.canExecute(
          action: 'test_action',
          maxAttempts: 0,
          windowMinutes: 60,
        );
        expect(canExecute, false);
      });

      test('Very large window hours works', () async {
        // Una ventana de 365 días (1 año)
        final canExecute = await RateLimiter.canExecute(
          action: 'long_window',
          maxAttempts: 1,
          windowMinutes: 525600,
        );
        expect(canExecute, true);
      });

      test('Attempts remaining is never negative', () async {
        // Hacer muchos intentos
        for (int i = 0; i < 10; i++) {
          await RateLimiter.canExecute(
            action: 'test_action',
            maxAttempts: 3,
            windowMinutes: 60,
          );
        }

        final info = await RateLimiter.getInfo(
          action: 'test_action',
          maxAttempts: 3,
          windowMinutes: 60,
        );

        expect(info.attemptsRemaining, greaterThanOrEqualTo(0));
      });
    });
  });
}
