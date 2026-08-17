import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Servicio de Rate Limiting para proteger acciones contra activaciones excesivas
/// Permite un número máximo de activaciones dentro de un período de tiempo especificado.
///
/// Usa una **ventana fija**: se almacena el inicio de la ventana y la cantidad de
/// intentos realizados dentro de ella. Cuando la ventana expira, el contador se
/// reinicia a cero, de modo que el usuario siempre parte desde 1/max en la ventana
/// siguiente (en lugar de heredar intentos de la ventana anterior).
class RateLimiter {
  // MODO DESARROLLO: Cambia a 'false' para deshabilitar el rate limiting
  // Útil para testing sin límite de intentos
  static const bool enableRateLimit = true; // ← CAMBIA AQUÍ: true = habilitado, false = deshabilitado
  
  // Claves para almacenamiento persistente
  static const String _stateKey = 'rate_limit_state';

  // Configuración por defecto: máximo 4 activaciones en 2 minutos (desarrollo)
  static const int defaultMaxActivations = 4;
  static const int defaultWindowMinutes = 2;

  /// Verificar si una acción está permitida según el rate limit
  /// Retorna true si la acción puede realizarse, false si ha alcanzado el límite
  /// 
  /// Parámetros:
  /// - [action]: identificador único de la acción (ej: 'panic_button')
  /// - [maxAttempts]: número máximo de intentos permitidos
  /// - [windowMinutes]: ventana de tiempo en minutos
  static Future<bool> canExecute({
    required String action,
    int maxAttempts = defaultMaxActivations,
    int windowMinutes = defaultWindowMinutes,
  }) async {
    // 🔧 Si el rate limit está deshabilitado en DESARROLLO, permitir siempre
    if (!enableRateLimit) {
      print('[RateLimiter.canExecute] ⚠️  MODO DEBUG: Rate limit DESHABILITADO - permitiendo ejecución');
      return true;
    }
    
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final windowDuration = Duration(minutes: windowMinutes);

    final (windowStart, attempts) = _loadState(prefs, action, now, windowDuration);

    // Si aún hay intentos disponibles dentro de la ventana, registrar este nuevo intento
    if (attempts < maxAttempts) {
      await _saveState(prefs, action, windowStart, attempts + 1);

      print('[RateLimiter.canExecute] ✓ Intento ${attempts + 1}/$maxAttempts permitido para "$action"');
      return true;
    }

    print('[RateLimiter.canExecute] ✗ Límite alcanzado ($maxAttempts) para "$action"');
    return false;
  }

  /// Obtener información sobre el estado del rate limit
  /// Retorna un mapa con información de intentos realizados y tiempo restante
  static Future<RateLimitInfo> getInfo({
    required String action,
    int maxAttempts = defaultMaxActivations,
    int windowMinutes = defaultWindowMinutes,
  }) async {
    // 🔧 Si el rate limit está deshabilitado en DESARROLLO
    if (!enableRateLimit) {
      return RateLimitInfo(
        attemptsUsed: 0,
        maxAttempts: maxAttempts,
        windowMinutes: windowMinutes,
        isLimited: false,
        timeUntilNextAttempt: null,
        nextAvailableTime: null,
      );
    }
    
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final windowDuration = Duration(minutes: windowMinutes);

    final (windowStart, attempts) = _loadState(prefs, action, now, windowDuration);

    // Calcular tiempo hasta el próximo reinicio de la ventana
    Duration? timeUntilNext;
    if (attempts >= maxAttempts) {
      // Si se alcanzó el límite, el siguiente intento será cuando expire la ventana
      timeUntilNext = windowStart.add(windowDuration).difference(now);
    }

    return RateLimitInfo(
      attemptsUsed: attempts,
      maxAttempts: maxAttempts,
      windowMinutes: windowMinutes,
      isLimited: attempts >= maxAttempts,
      timeUntilNextAttempt: timeUntilNext,
      nextAvailableTime: timeUntilNext != null 
          ? now.add(timeUntilNext)
          : null,
    );
  }

  /// Cargar el estado persistido de la acción.
  /// Si la ventana ya expiró (o no hay estado válido), devuelve una ventana nueva
  /// que inicia en [now] con 0 intentos.
  static (DateTime, int) _loadState(
    SharedPreferences prefs,
    String action,
    DateTime now,
    Duration windowDuration,
  ) {
    final raw = prefs.getString('${_stateKey}_$action');
    DateTime windowStart = now;
    int attempts = 0;

    if (raw != null) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) {
          final start = DateTime.tryParse(decoded['start']?.toString() ?? '');
          if (start != null) {
            windowStart = start;
            attempts = (decoded['attempts'] as num?)?.toInt() ?? 0;
          }
        }
      } catch (_) {
        // Datos corruptos o en formato antiguo: se tratan como ventana nueva
      }
    }

    // Si la ventana expiró, reiniciar el contador desde cero
    if (now.difference(windowStart) >= windowDuration) {
      return (now, 0);
    }

    return (windowStart, attempts);
  }

  /// Persistir el estado de la ventana para la acción
  static Future<void> _saveState(
    SharedPreferences prefs,
    String action,
    DateTime windowStart,
    int attempts,
  ) async {
    await prefs.setString('${_stateKey}_$action', jsonEncode({
      'start': windowStart.toIso8601String(),
      'attempts': attempts,
    }));
  }

  /// Resetear completamente el contador de rate limit para una acción
  /// Útil para testing o para dar una "segunda oportunidad"
  static Future<void> reset({required String action}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('${_stateKey}_$action');
  }

  /// Resetear todos los rate limiters
  static Future<void> resetAll() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    final rateLimitKeys = keys
        .where((key) => key.startsWith(_stateKey))
        .toList();

    for (final key in rateLimitKeys) {
      await prefs.remove(key);
    }
  }
}

/// Información sobre el estado del rate limit
class RateLimitInfo {
  final int attemptsUsed;
  final int maxAttempts;
  final int windowMinutes;
  final bool isLimited;
  final Duration? timeUntilNextAttempt;
  final DateTime? nextAvailableTime;

  RateLimitInfo({
    required this.attemptsUsed,
    required this.maxAttempts,
    required this.windowMinutes,
    required this.isLimited,
    this.timeUntilNextAttempt,
    this.nextAvailableTime,
  });

  /// Obtener el número de intentos restantes
  int get attemptsRemaining => (maxAttempts - attemptsUsed).clamp(0, maxAttempts);

  /// Obtener información en formato legible
  String get readableInfo {
    if (!isLimited) {
      return '$attemptsUsed/$maxAttempts intentos usados';
    }

    if (timeUntilNextAttempt == null) {
      return 'Límite alcanzado';
    }

    final hours = timeUntilNextAttempt!.inHours;
    final minutes = timeUntilNextAttempt!.inMinutes.remainder(60);

    if (hours > 0) {
      return 'Intenta en ${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return 'Intenta en ${minutes}m';
    } else {
      return 'Intenta en unos segundos';
    }
  }

  /// String para debugging
  @override
  String toString() => 'RateLimitInfo($readableInfo)';
}
