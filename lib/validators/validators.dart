import 'package:phone_numbers_parser/phone_numbers_parser.dart';

/// Módulo centralizado de validadores para la aplicación
/// Configurado específicamente para Ecuador
class Validators {
  // Código de país: Ecuador = +593
  static const String ecuadorCountryCode = '+593';
  static const String ecuadorCountryPrefix = '593';

  /// Validar email con formato estándar
  static bool isValidEmail(String email) {
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
        .hasMatch(email);
  }

  /// Validar nombre (solo letras y espacios, incluyendo caracteres acentuados)
  static bool isValidName(String name) {
    return RegExp(r'^[A-Za-záéíóúÁÉÍÓÚüÜñÑ\s]+$').hasMatch(name) &&
        name.trim().isNotEmpty;
  }

  /// Validar edad (entre 1 y 120 años)
  static bool isValidAge(String age) {
    final ageInt = int.tryParse(age);
    return ageInt != null && ageInt >= 1 && ageInt <= 120;
  }

  /// Validar teléfono celular de Ecuador
  /// Acepta formatos:
  /// - 0963522505 (formato local de 10 dígitos)
  /// - 593963522505 (formato internacional sin +)
  /// - +593963522505 (formato internacional con +)
  /// - 09 6352 2505 (con espacios)
  static bool isValidPhone(String phone) {
    return _hasValidEcuadorPhoneFormat(phone);
  }

  /// Validar formato específico para teléfonos de Ecuador
  /// Los números de celular en Ecuador tienen 10 dígitos
  /// Comienzan con 09 (formato local) o 593 9 (formato internacional)
  static bool _hasValidEcuadorPhoneFormat(String phone) {
    final cleaned = phone.replaceAll(' ', '').replaceAll('-', '').replaceAll('.', '');

    // Formato local: 0963522505 (exactamente 10 dígitos, comienza con 09)
    if (RegExp(r'^09\d{8}$').hasMatch(cleaned)) {
      return true;
    }

    // Formato internacional sin +: 593963522505 (12 dígitos, comienza con 593)
    if (RegExp(r'^593\d{9}$').hasMatch(cleaned)) {
      return true;
    }

    // Formato internacional con +: +593963522505
    if (RegExp(r'^\+593\d{9}$').hasMatch(cleaned)) {
      return true;
    }

    return false;
  }

  /// Validar contraseña (al menos 8 caracteres, 1 mayúscula, 1 número, 1 símbolo)
  static bool isValidPassword(String password) {
    return RegExp(r'^(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$')
        .hasMatch(password);
  }

  /// Normalizar teléfono a formato local de Ecuador
  /// Convierte cualquier formato válido a: 0963522505
  /// O a formato internacional si se especifica: +593963522505
  static String normalizePhoneNumber(String phone, {bool international = false}) {
    final cleaned = phone.replaceAll(' ', '').replaceAll('-', '').replaceAll('.', '');

    // Si ya está en formato local (0963522505)
    if (RegExp(r'^09\d{8}$').hasMatch(cleaned)) {
      if (international) {
        // Convertir a +593963522505
        return '+593${cleaned.substring(1)}';
      }
      return cleaned;
    }

    // Si está en formato internacional sin + (593963522505)
    if (RegExp(r'^593\d{9}$').hasMatch(cleaned)) {
      if (international) {
        // Convertir a +593963522505
        return '+$cleaned';
      }
      // Convertir a 0963522505
      return '0${cleaned.substring(3)}';
    }

    // Si está en formato internacional con + (+593963522505)
    if (RegExp(r'^\+593\d{9}$').hasMatch(cleaned)) {
      if (international) {
        return cleaned;
      }
      // Convertir a 0963522505
      return '0${cleaned.substring(4)}';
    }

    // Si no es válido, retornar el original
    return phone;
  }

  /// Obtener la versión internacional del teléfono
  /// Ejemplo: 0963522505 → +593963522505
  static String getInternationalFormat(String phone) {
    return normalizePhoneNumber(phone, international: true);
  }

  /// Obtener la versión local del teléfono
  /// Ejemplo: +593963522505 → 0963522505
  static String getLocalFormat(String phone) {
    return normalizePhoneNumber(phone, international: false);
  }

  /// Validar que un campo no esté vacío y tenga contenido
  static bool isNotEmpty(String value) {
    return value.trim().isNotEmpty;
  }

  /// Validar longitud mínima
  static bool hasMinLength(String value, int minLength) {
    return value.length >= minLength;
  }

  /// Validar longitud máxima
  static bool hasMaxLength(String value, int maxLength) {
    return value.length <= maxLength;
  }

  /// Validar que esté dentro de un rango de longitud
  static bool hasValidLength(String value, int minLength, int maxLength) {
    return hasMinLength(value, minLength) && hasMaxLength(value, maxLength);
  }
}
