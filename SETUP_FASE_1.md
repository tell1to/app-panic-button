# 🚀 SETUP SCRIPT - Fase 1

Este archivo contiene los comandos necesarios para completar la configuración de Fase 1.

## ⚡ Instalación Rápida (Copy-Paste)

```powershell
# 1. Navegar al proyecto
cd "c:\Users\MateoM\Desktop\Proyecto-app\flutter_application_1"

# 2. Limpiar estado anterior
flutter clean

# 3. Descargar dependencias (incluyendo las nuevas)
flutter pub get

# 4. Analizar código (debe completarse sin errores críticos)
flutter analyze

# 5. Ejecutar la app
flutter run
```

---

## 📝 Instalación Paso a Paso

### Paso 1: Preparar el entorno
```powershell
cd "c:\Users\MateoM\Desktop\Proyecto-app\flutter_application_1"
```

### Paso 2: Limpiar
```powershell
flutter clean
```

### Paso 3: Instalar dependencias
```powershell
flutter pub get
```

**Esperado**: Se descargan:
- `flutter_secure_storage: 9.2.4`
- `phone_numbers_parser: 8.3.0`

### Paso 4: Verificar análisis
```powershell
flutter analyze
```

**Esperado**: ~108 issues (pero solo INFO, no errores)

### Paso 5: Ejecutar
```powershell
flutter run
```

**Esperado**: La app se compila y ejecuta sin errores

---

## ✅ Verificación Post-Instalación

Ejecuta este script para verificar que todo está funcionando:

```powershell
# Verificar que las dependencias están instaladas
flutter pub list

# Buscar las nuevas dependencias
flutter pub list | findstr "flutter_secure_storage"
flutter pub list | findstr "phone_numbers_parser"

# Ambos comandos deben mostrar las librerías
```

---

## 🧪 Prueba Rápida

```powershell
# Crear un test simple
$testCode = @"
import 'package:flutter/foundation.dart';
import 'lib/validators/validators.dart';

void main() {
  print('Testing Validators...');
  
  final validPhone = Validators.isValidPhone('(912) 345-6789');
  final normalized = Validators.normalizePhoneNumber('(912) 345-6789');
  
  print('✅ isValidPhone: \$validPhone');
  print('✅ normalizePhoneNumber: \$normalized');
  
  if (validPhone && normalized == '+19123456789') {
    print('✅ ¡Todo funciona!');
  }
}
"@

# Guardar en archivo temporal
$testCode | Out-File -FilePath "test_fase1.dart" -Encoding UTF8

# Compilar (esto solo verifica la compilación)
flutter analyze lib/validators/validators.dart

# Limpiar
Remove-Item "test_fase1.dart" -Force
```

---

## 🔄 Troubleshooting del Setup

### Error: "flutter command not found"
```powershell
# Verificar que Flutter está en PATH
flutter --version

# Si no funciona, agregar Flutter a PATH:
$env:PATH += ";C:\src\flutter\bin"
```

### Error: "pubspec.yaml not found"
```powershell
# Asegurar estar en el directorio correcto
Get-Location

# Debe mostrar:
# C:\Users\MateoM\Desktop\Proyecto-app\flutter_application_1
```

### Error: "gradle build failed"
```powershell
# Limpiar Gradle
flutter clean
flutter pub get

# Para Android específicamente:
cd android
./gradlew clean
cd ..
flutter run
```

### Error: "ios build failed"
```powershell
# Limpiar Pod
cd ios
pod repo update
pod install
cd ..
flutter clean
flutter run
```

---

## 📱 Setup por Plataforma

### Android

```powershell
# 1. Verificar mínimo SDK
# Editar android/app/build.gradle
# Debe tener: minSdkVersion 18

# 2. Compilar para Android
flutter run -d android

# 3. Verificar en Logcat que no hay errores de secure_storage
flutter logs | findstr "secure_storage"
```

### iOS

```powershell
# 1. Verificar deployment target
# Editar ios/Podfile
# Debe tener: platform :ios, '11.0'

# 2. Compilar para iOS
flutter run -d ios

# 3. Verificar que no hay errores de Keychain
flutter logs | findstr "keychain"
```

### Windows/Linux/macOS

```powershell
# En Windows
flutter run -d windows

# En Linux
flutter run -d linux

# En macOS
flutter run -d macos
```

---

## 🔍 Verificación de Archivos

Después del setup, verifica que estos archivos existen:

```powershell
# Verificar estructura
Get-ChildItem -Path "lib/validators/" -Recurse
Get-ChildItem -Path "lib/services/" -Recurse

# Debe mostrar:
# lib/validators/validators.dart
# lib/services/secure_storage_service.dart

# Verificar que pubspec.yaml tiene las dependencias
Select-String -Path "pubspec.yaml" -Pattern "flutter_secure_storage|phone_numbers_parser"

# Debe mostrar ambas líneas
```

---

## 📊 Checklist de Setup Completo

- [ ] `flutter clean` ejecutado
- [ ] `flutter pub get` completado sin errores
- [ ] `flutter analyze` sin errores críticos
- [ ] `flutter run` ejecuta exitosamente
- [ ] App inicia sin crashes
- [ ] Validadores disponibles en código
- [ ] Almacenamiento seguro disponible
- [ ] Contactos se guardan correctamente
- [ ] Teléfonos se normalizan correctamente
- [ ] Datos persisten después de cerrar app

---

## 🎯 Próximo Paso

Una vez completado el setup:

1. Lee `INDICE.md`
2. Lee `RESUMEN_FASE_1.md`
3. Prueba los ejemplos en `lib/EJEMPLOS_FASE_1.dart`
4. Sigue `TESTING_FASE_1.md` para pruebas manuales

---

## 💾 Backup del Setup

Si necesitas revertir a un estado conocido:

```powershell
# Revertir pubspec.yaml a versión guardada
git checkout pubspec.yaml

# Revertir Podfile
git checkout ios/Podfile

# Revertir build.gradle
git checkout android/app/build.gradle

# Limpiar y reinstalar
flutter clean
flutter pub get
```

---

## 📈 Setup Success Indicators

### ✅ Setup Exitoso Si:
- App compila sin errores
- Los archivos nuevos existen en lib/
- Las dependencias aparecen en `flutter pub list`
- Las pruebas en `TESTING_FASE_1.md` pasan

### ❌ Setup Fallido Si:
- Error: "flutter_secure_storage: 'flutter/services' not found"
- Error: "phone_numbers_parser: command not found"
- Error de compilación de Gradle/Pod
- La app se abre pero crashea al acceder a Validadores

---

## 🆘 Contacto de Soporte

Si encuentras problemas:

1. Revisa `CONFIGURACION_SECURE_STORAGE.md`
2. Ejecuta `flutter doctor` para verificar entorno
3. Revisa logs: `flutter logs`
4. Limpiar y reinstalar: `flutter clean && flutter pub get`

---

## ⏱️ Tiempo Estimado

| Tarea | Tiempo |
|-------|--------|
| flutter clean | 30 seg |
| flutter pub get | 1-2 min |
| flutter analyze | 1 min |
| flutter run (primera vez) | 3-5 min |
| flutter run (subsecuentes) | 30 seg |
| **Total** | **~8 min** |

---

## 🚀 ¡Listo!

Una vez completado este script:

✅ Fase 1 está instalada y funcionando
✅ Puedes usar validadores
✅ Puedes guardar datos de forma segura
✅ Listo para Fase 2

---

**Script creado**: 21 de diciembre de 2025  
**Versión**: 1.0.0  
**Estado**: ✅ LISTO
