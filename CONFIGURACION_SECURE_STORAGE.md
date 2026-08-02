# Configuración de flutter_secure_storage - Fase 1

## Verificación de Configuración por Plataforma

### ✅ Android (Configuración automática en la mayoría de casos)

#### 1. Requisitos Mínimos
- `minSdkVersion: 18` (generalmente ya lo tienes)
- Permiso de Internet (si necesitas sincronizar)

#### 2. Verificar `android/app/build.gradle`

```gradle
android {
    compileSdkVersion 34  // O tu versión actual

    defaultConfig {
        applicationId "com.example.flutter_application_1"
        minSdkVersion 18    // ✅ Importante: mínimo 18 para secure_storage
        targetSdkVersion 34 // O tu versión target
        versionCode 1
        versionName "1.0"
    }
}
```

#### 3. Características de Seguridad Android
- **API 18+**: Usa AndroidKeyStore de forma automática
- **API 23+**: Encriptación mejorada con biometría opcional
- **API 30+**: Soporte completo para scoped storage

✅ **Tu app está automáticamente protegida por el SO**

---

### ✅ iOS (Verificación recomendada)

#### 1. Requisitos Mínimos
- `minimum deployment target: 11.0`
- Xcode 13+

#### 2. Verificar `ios/Podfile`

```ruby
platform :ios, '11.0'

# El flutter_secure_storage usa Keychain automáticamente
```

#### 3. Características de Seguridad iOS
- **iOS 11+**: Keychain (Apple's secure storage)
- **Encriptación**: Automática a nivel de hardware
- **Sincronización iCloud**: Controlada por el SO

✅ **Tu app está automáticamente protegida por Keychain**

---

### 4. Verificación de Funcionamiento

#### Para Android:
```bash
# Conectar dispositivo o emulador
flutter devices

# Ejecutar la app
flutter run

# Revisar logs para confirmar secure_storage
flutter logs | grep -i secure
```

#### Para iOS:
```bash
# Ejecutar en simulador/dispositivo
flutter run -d <device-id>

# Revisar logs
flutter logs | grep -i keychain
```

---

### 5. Prueba de Encriptación

Ejecuta este código para verificar que todo está funcionando:

```dart
import 'services/secure_storage_service.dart';

void testSecureStorage() async {
  // Guardar
  await SecureStorageService.savePreferredPhone('+1234567890');
  
  // Recuperar
  final phone = await SecureStorageService.getPreferredPhone();
  
  if (phone == '+1234567890') {
    print('✅ Almacenamiento seguro funciona correctamente');
  } else {
    print('❌ Error: Los datos no se guardaron correctamente');
  }
}
```

---

### 6. Consideraciones de Privacidad

#### ✅ Datos encriptados en:
- Almacenamiento local del dispositivo
- Protegidos por el SO a nivel de hardware

#### ⚠️ NOT encriptados en:
- Datos en memoria durante ejecución (normal)
- Datos transmitidos por red (requiere HTTPS)
- Logs del sistema (no guardes datos sensibles ahí)

#### 🔒 Recomendación:
Para comunicación con servidor, adicional a este almacenamiento:
1. Usar HTTPS/TLS
2. Certificados de servidor
3. Validación de certificados
4. Tokens con expiración

---

### 7. Diferencias por Plataforma

| Aspecto | Android | iOS | Windows | macOS | Linux |
|--------|---------|-----|---------|-------|-------|
| Almacenamiento | AndroidKeyStore | Keychain | Windows Credential Manager | Keychain | pass/libsecret |
| Encriptación | Hardware (Strongbox) | Hardware (Secure Enclave) | Software | Software | Software |
| Biometría | Sí (API 23+) | Sí | Sí | Sí | Parcial |
| Acceso sin desbloqueo | Requiere permiso | Requiere permiso | Requiere permiso | Requiere permiso | Requiere permiso |

---

### 8. Troubleshooting

#### Problema: "flutter_secure_storage not found"
```bash
# Solución
flutter pub get
flutter clean
flutter pub get
```

#### Problema: "Keychain error" en iOS
```bash
# Solución
cd ios
pod repo update
pod install
cd ..
flutter clean
flutter run
```

#### Problema: "AndroidKeyStore not available"
```bash
# Solución: Asegurar que minSdkVersion >= 18
# Editar android/app/build.gradle
# Luego ejecutar: flutter clean && flutter run
```

---

### 9. Variables de Entorno (Opcional)

No se requieren variables de entorno especiales. La librería maneja todo automáticamente.

---

### 10. Verificación Final

Después de implementar, verifica:

✅ `flutter pub get` completa sin errores  
✅ `flutter analyze` no muestra errores críticos  
✅ `flutter run` ejecuta en device/emulator  
✅ Los datos se guardan y recuperan correctamente  

---

## ¿Qué sucede con los datos al hacer update?

| Escenario | Resultado |
|-----------|-----------|
| **Update de app** | ✅ Datos permanecen encriptados |
| **Desinstalación + Reinstalación** | ❌ Datos se pierden (por diseño de SO) |
| **Cambio de dispositivo** | ❌ Datos no se transfieren |
| **Backup del dispositivo** | Depende del SO (generalmente sí incluye) |

---

## Información de Depuración

Para ver qué se está guardando (solo en desarrollo):

```dart
// ⚠️ SOLO EN DESARROLLO - NUNCA EN PRODUCCIÓN
Future<void> debugSecureStorage() async {
  try {
    final phone = await SecureStorageService.getPreferredPhone();
    print('DEBUG - Teléfono guardado: $phone');
  } catch (e) {
    print('DEBUG - Error: $e');
  }
}
```

---

## Proximos Pasos

1. ✅ Verificar que la configuración es correcta (Este documento)
2. ⏭️ Implementar Fase 2: Rate Limiting
3. ⏭️ Implementar Fase 3: Firebase

---

**Configuración completada exitosamente** ✅
