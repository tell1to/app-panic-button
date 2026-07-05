import 'package:encrypt/encrypt.dart' as encryptLib;

/// Servicio de encriptación para datos sensibles
/// Encripta: latitude, longitude, numberCalled
class EncryptionService {
  static final EncryptionService _instance = EncryptionService._internal();
  
  static EncryptionService get instance => _instance;
  
  late encryptLib.Key _key;
  late encryptLib.IV _iv;
  late encryptLib.Encrypter _encrypter;
  
  EncryptionService._internal();
  
  /// Inicializar el servicio con una clave predeterminada
  /// En producción, esta clave debería venir de un servidor seguro
  void initialize() {
    // CLAVE: Exactamente 32 bytes (256 bits) para AES-256
    // Cadena de 32 caracteres ASCII = 32 bytes UTF-8
    _key = encryptLib.Key.fromUtf8('12345678901234567890123456789012'); // 32 bytes
    _iv = encryptLib.IV.fromUtf8('1234567890123456'); // 16 bytes (128 bits)
    _encrypter = encryptLib.Encrypter(encryptLib.AES(_key));
    
    print('[EncryptionService.initialize] ✓ Clave: 256 bits (32 bytes)');
    print('[EncryptionService.initialize] ✓ IV: 128 bits (16 bytes)');
    print('[EncryptionService.initialize] ✓ Algoritmo: AES-256');
  }
  
  /// Encriptar un valor sensible
  /// Retorna: "base64_encrypted_string"
  String encrypt(String value) {
    try {
      if (value.isEmpty) return '';
      print('[EncryptionService.encrypt] Encriptando: $value');
      final encrypted = _encrypter.encrypt(value, iv: _iv);
      final base64Result = encrypted.base64;
      print('[EncryptionService.encrypt] ✓ Encriptado: $base64Result');
      return base64Result;
    } catch (e) {
      print('[EncryptionService.encrypt] ✗ ERROR CRÍTICO: $e');
      rethrow; // Lanza excepción en lugar de retornar sin encriptar
    }
  }
  
  /// Desencriptar un valor
  String decrypt(String encryptedValue) {
    try {
      if (encryptedValue.isEmpty) return '';
      print('[EncryptionService.decrypt] Desencriptando: $encryptedValue');
      final decrypted = _encrypter.decrypt64(encryptedValue, iv: _iv);
      print('[EncryptionService.decrypt] ✓ Desencriptado: $decrypted');
      return decrypted;
    } catch (e) {
      print('[EncryptionService.decrypt] ✗ ERROR: $e');
      rethrow;
    }
  }
  
  /// Encriptar ubicación (lat, lon)
  Map<String, String> encryptLocation(double? latitude, double? longitude) {
    return {
      'latitude_encrypted': latitude != null ? encrypt(latitude.toString()) : '',
      'longitude_encrypted': longitude != null ? encrypt(longitude.toString()) : '',
    };
  }
  
  /// Desencriptar ubicación
  Map<String, double?> decryptLocation(String? latEncrypted, String? lonEncrypted) {
    try {
      final lat = latEncrypted != null && latEncrypted.isNotEmpty 
        ? double.tryParse(decrypt(latEncrypted))
        : null;
      final lon = lonEncrypted != null && lonEncrypted.isNotEmpty 
        ? double.tryParse(decrypt(lonEncrypted))
        : null;
      
      return {
        'latitude': lat,
        'longitude': lon,
      };
    } catch (e) {
      print('[EncryptionService.decryptLocation] ERROR: $e');
      return {'latitude': null, 'longitude': null};
    }
  }
}
