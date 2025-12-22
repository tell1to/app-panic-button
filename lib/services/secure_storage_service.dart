import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Servicio centralizado para almacenamiento seguro de datos sensibles
/// Usa AndroidKeyStore en Android e Keychain en iOS
class SecureStorageService {
  static const _secureStorage = FlutterSecureStorage();

  // Claves de almacenamiento
  static const String _preferredPhoneKey = 'preferred_phone';
  static const String _emergencyContactKey = 'emergency_contact';
  static const String _medicalInfoKey = 'medical_info';
  static const String _allergiesKey = 'allergies';
  static const String _medicationsKey = 'medications';
  static const String _ciKey = 'user_ci'; // ← NUEVA: Cédula de identidad
  static const String _firstNameKey = 'user_first_name'; // ← NUEVA
  static const String _lastNameKey = 'user_last_name'; // ← NUEVA
  static const String _ageKey = 'user_age'; // ← NUEVA
  static const String _diseasesKey = 'user_diseases'; // ← NUEVA: JSON string

  /// Guardar número de teléfono preferido de forma segura
  static Future<void> savePreferredPhone(String phone) async {
    try {
      await _secureStorage.write(
        key: _preferredPhoneKey,
        value: phone,
      );
    } catch (e) {
      print('[SecureStorage] Error guardando teléfono preferido: $e');
      rethrow;
    }
  }

  /// Recuperar número de teléfono preferido
  static Future<String?> getPreferredPhone() async {
    try {
      return await _secureStorage.read(key: _preferredPhoneKey);
    } catch (e) {
      print('[SecureStorage] Error recuperando teléfono preferido: $e');
      return null;
    }
  }

  /// Guardar contacto de emergencia de forma segura
  static Future<void> saveEmergencyContact(String name, String phone) async {
    try {
      await _secureStorage.write(
        key: _emergencyContactKey,
        value: '$name|$phone', // Formato: nombre|teléfono
      );
    } catch (e) {
      print('[SecureStorage] Error guardando contacto de emergencia: $e');
      rethrow;
    }
  }

  /// Recuperar contacto de emergencia
  static Future<Map<String, String>?> getEmergencyContact() async {
    try {
      final data = await _secureStorage.read(key: _emergencyContactKey);
      if (data != null) {
        final parts = data.split('|');
        if (parts.length == 2) {
          return {'nombre': parts[0], 'telefono': parts[1]};
        }
      }
      return null;
    } catch (e) {
      print('[SecureStorage] Error recuperando contacto de emergencia: $e');
      return null;
    }
  }

  /// Guardar información médica de forma segura
  static Future<void> saveMedicalInfo(String info) async {
    try {
      await _secureStorage.write(
        key: _medicalInfoKey,
        value: info,
      );
    } catch (e) {
      print('[SecureStorage] Error guardando información médica: $e');
      rethrow;
    }
  }

  /// Recuperar información médica
  static Future<String?> getMedicalInfo() async {
    try {
      return await _secureStorage.read(key: _medicalInfoKey);
    } catch (e) {
      print('[SecureStorage] Error recuperando información médica: $e');
      return null;
    }
  }

  /// Guardar alergias de forma segura
  static Future<void> saveAllergies(String allergies) async {
    try {
      await _secureStorage.write(
        key: _allergiesKey,
        value: allergies,
      );
    } catch (e) {
      print('[SecureStorage] Error guardando alergias: $e');
      rethrow;
    }
  }

  /// Recuperar alergias
  static Future<String?> getAllergies() async {
    try {
      return await _secureStorage.read(key: _allergiesKey);
    } catch (e) {
      print('[SecureStorage] Error recuperando alergias: $e');
      return null;
    }
  }

  /// Guardar medicamentos de forma segura
  static Future<void> saveMedications(String medications) async {
    try {
      await _secureStorage.write(
        key: _medicationsKey,
        value: medications,
      );
    } catch (e) {
      print('[SecureStorage] Error guardando medicamentos: $e');
      rethrow;
    }
  }

  /// Recuperar medicamentos
  static Future<String?> getMedications() async {
    try {
      return await _secureStorage.read(key: _medicationsKey);
    } catch (e) {
      print('[SecureStorage] Error recuperando medicamentos: $e');
      return null;
    }
  }

  /// Eliminar un dato seguro por clave
  static Future<void> delete(String key) async {
    try {
      await _secureStorage.delete(key: key);
    } catch (e) {
      print('[SecureStorage] Error eliminando dato: $e');
      rethrow;
    }
  }

  /// Eliminar todos los datos seguros
  static Future<void> deleteAll() async {
    try {
      await _secureStorage.deleteAll();
    } catch (e) {
      print('[SecureStorage] Error eliminando todos los datos: $e');
      rethrow;
    }
  }

  // ============================================================================
  // NUEVOS MÉTODOS PARA DATOS DEL USUARIO (Fase 3 - Identificación Única)
  // ============================================================================

  /// Guardar Cédula de Identidad (CI) - Será el ID único del usuario
  static Future<void> saveCI(String ci) async {
    try {
      await _secureStorage.write(
        key: _ciKey,
        value: ci,
      );
      print('[SecureStorage] CI guardada: $ci');
    } catch (e) {
      print('[SecureStorage] Error guardando CI: $e');
      rethrow;
    }
  }

  /// Obtener Cédula de Identidad
  static Future<String?> getCI() async {
    try {
      return await _secureStorage.read(key: _ciKey);
    } catch (e) {
      print('[SecureStorage] Error recuperando CI: $e');
      return null;
    }
  }

  /// Guardar datos completos del usuario
  static Future<void> saveUserProfile({
    required String ci,
    required String firstName,
    required String lastName,
    required String age,
    required String diseases, // JSON string de enfermedades
  }) async {
    try {
      await _secureStorage.write(key: _ciKey, value: ci);
      await _secureStorage.write(key: _firstNameKey, value: firstName);
      await _secureStorage.write(key: _lastNameKey, value: lastName);
      await _secureStorage.write(key: _ageKey, value: age);
      await _secureStorage.write(key: _diseasesKey, value: diseases);
      print('[SecureStorage] Perfil de usuario guardado: $ci');
    } catch (e) {
      print('[SecureStorage] Error guardando perfil de usuario: $e');
      rethrow;
    }
  }

  /// Obtener datos completos del usuario
  static Future<Map<String, String?>> getUserProfile() async {
    try {
      return {
        'ci': await _secureStorage.read(key: _ciKey),
        'firstName': await _secureStorage.read(key: _firstNameKey),
        'lastName': await _secureStorage.read(key: _lastNameKey),
        'age': await _secureStorage.read(key: _ageKey),
        'diseases': await _secureStorage.read(key: _diseasesKey),
      };
    } catch (e) {
      print('[SecureStorage] Error recuperando perfil de usuario: $e');
      return {};
    }
  }

  /// Verificar si el usuario tiene perfil completo
  static Future<bool> hasCompleteProfile() async {
    try {
      final ci = await _secureStorage.read(key: _ciKey);
      return ci != null && ci.isNotEmpty;
    } catch (e) {
      print('[SecureStorage] Error verificando perfil: $e');
      return false;
    }
  }

  /// Obtener solo CI (para usar como userId en Firebase)
  static Future<String> getUserId() async {
    try {
      final ci = await _secureStorage.read(key: _ciKey);
      if (ci != null && ci.isNotEmpty) {
        return ci;
      }
      // Fallback a user_default si no hay CI configurado
      return 'user_default';
    } catch (e) {
      print('[SecureStorage] Error obteniendo userId: $e');
      return 'user_default';
    }
  }
}
