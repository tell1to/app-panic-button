import 'package:shared_preferences/shared_preferences.dart';

/// Servicio de Rate Limiting para proteger acciones contra activaciones excesivas
/// Permite un número máximo de activaciones dentro de un período de tiempo especificado
class RateLimiter {
  // Claves para almacenamiento persistente
  static const String _timestampsKey = 'rate_limit_timestamps';

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
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final windowDuration = Duration(minutes: windowMinutes);

    // Obtener timestamps previos del almacenamiento
    final storedTimestamps = prefs.getStringList('${_timestampsKey}_$action') ?? [];

    // Convertir strings a DateTime y filtrar los que están dentro de la ventana
    final validTimestamps = storedTimestamps
        .map((ts) {
          try {
            return DateTime.parse(ts);
          } catch (_) {
            return null;
          }
        })
        .whereType<DateTime>()
        .where((ts) => now.difference(ts) < windowDuration)
        .toList();

    // Si aún hay intentos disponibles, registrar este nuevo intento
    if (validTimestamps.length < maxAttempts) {
      // Agregar el timestamp actual
      validTimestamps.add(now);

      // Guardar los timestamps actualizados
      final updatedTimestamps = validTimestamps
          .map((ts) => ts.toIso8601String())
          .toList();

      await prefs.setStringList(
        '${_timestampsKey}_$action',
        updatedTimestamps,
      );

      return true;
    }

    return false;
  }

  /// Obtener información sobre el estado del rate limit
  /// Retorna un mapa con información de intentos realizados y tiempo restante
  static Future<RateLimitInfo> getInfo({
    required String action,
    int maxAttempts = defaultMaxActivations,
    int windowMinutes = defaultWindowMinutes,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final windowDuration = Duration(minutes: windowMinutes);

    // Obtener timestamps previos
    final storedTimestamps = prefs.getStringList('${_timestampsKey}_$action') ?? [];

    // Convertir y filtrar
    final validTimestamps = storedTimestamps
        .map((ts) {
          try {
            return DateTime.parse(ts);
          } catch (_) {
            return null;
          }
        })
        .whereType<DateTime>()
        .where((ts) => now.difference(ts) < windowDuration)
        .toList();

    // Calcular tiempo hasta el siguiente intento disponible
    Duration? timeUntilNext;
    if (validTimestamps.length >= maxAttempts) {
      // Si se alcanzó el límite, el siguiente intento será cuando expire el más antiguo
      final oldestTimestamp = validTimestamps.first;
      final expiryTime = oldestTimestamp.add(windowDuration);
      timeUntilNext = expiryTime.difference(now);
    }

    return RateLimitInfo(
      attemptsUsed: validTimestamps.length,
      maxAttempts: maxAttempts,
      windowMinutes: windowMinutes,
      isLimited: validTimestamps.length >= maxAttempts,
      timeUntilNextAttempt: timeUntilNext,
      nextAvailableTime: timeUntilNext != null 
          ? now.add(timeUntilNext)
          : null,
    );
  }

  /// Resetear completamente el contador de rate limit para una acción
  /// Útil para testing o para dar una "segunda oportunidad"
  static Future<void> reset({required String action}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('${_timestampsKey}_$action');
  }

  /// Resetear todos los rate limiters
  static Future<void> resetAll() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    final rateLimitKeys = keys
        .where((key) => key.startsWith(_timestampsKey))
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
