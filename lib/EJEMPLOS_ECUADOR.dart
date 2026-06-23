// EJEMPLOS DE USO - ECUADOR
// Copiar y adaptar estos ejemplos en tu código

import 'package:flutter/material.dart';
import 'validators/validators.dart';
import 'services/secure_storage_service.dart';

// ============================================================================
// 1. VALIDAR NÚMEROS TELEFÓNICOS DE ECUADOR
// ============================================================================

void ejemploValidarTelefonoEcuador() {
  final telefonosEcuador = [
    // ✅ Válidos - Formato Local
    '0963522505',           // ✅ Formato local estándar
    '0961234567',           // ✅ Otro formato local
    '0987654321',           // ✅ Otro formato local
    
    // ✅ Válidos - Formato Internacional
    '+593963522505',        // ✅ Con + y código 593
    '593963522505',         // ✅ Sin +
    
    // ✅ Válidos - Con espacios
    '09 6352 2505',         // ✅ Con espacios
    '09-6352-2505',         // ✅ Con guiones
    '+593 9 6352 2505',     // ✅ Internacional con espacios
    
    // ❌ Inválidos
    '9963522505',           // ❌ Falta el 0 inicial
    '963522505',            // ❌ Menos de 10 dígitos
    '+11234567890',         // ❌ No es de Ecuador
    'abc123',               // ❌ No es número
  ];

  for (final phone in telefonosEcuador) {
    if (Validators.isValidPhone(phone)) {
      print('✅ $phone es válido (Ecuador)');
      
      // Mostrar normalización
      final normalized = Validators.normalizePhoneNumber(phone);
      print('   → Local: $normalized');
      
      final intl = Validators.getInternationalFormat(phone);
      print('   → Internacional: $intl');
    } else {
      print('❌ $phone es inválido');
    }
  }
}

// ============================================================================
// 2. NORMALIZACIÓN DE TELÉFONOS - EJEMPLOS PRÁCTICOS
// ============================================================================

void ejemploNormalizacionEcuador() {
  print('\n=== NORMALIZACIÓN A FORMATO LOCAL ===');
  
  // Todos estos se normalizan a: 0963522505
  final ejemplos = [
    '0963522505',           // Ya está normalizado
    '09 6352 2505',         // Con espacios
    '09-6352-2505',         // Con guiones
    '+593963522505',        // Internacional con +
    '593963522505',         // Internacional sin +
  ];

  for (final phone in ejemplos) {
    final local = Validators.normalizePhoneNumber(phone);
    print('$phone → $local');
  }

  print('\n=== CONVERTIR A FORMATO INTERNACIONAL ===');
  
  // Todos se convierten a: +593963522505
  for (final phone in ejemplos) {
    final intl = Validators.getInternationalFormat(phone);
    print('$phone → $intl');
  }
}

// ============================================================================
// 3. GUARDAR CONTACTO DE EMERGENCIA (ECUADOR)
// ============================================================================

Future<void> ejemploGuardarContactoEcuador() async {
  const nombre = 'Ambulancia';
  const telefonoRaw = '09 6352 2505';  // Como lo escribe el usuario

  print('1️⃣ Teléfono ingresado: $telefonoRaw');

  // 1. Validar
  if (!Validators.isValidPhone(telefonoRaw)) {
    print('❌ Teléfono inválido');
    return;
  }
  print('✅ Teléfono válido');

  // 2. Normalizar al formato local (0963522505)
  final telefonoNormalizado = Validators.normalizePhoneNumber(telefonoRaw);
  print('2️⃣ Normalizado (local): $telefonoNormalizado');

  // 3. Guardar de forma segura
  try {
    await SecureStorageService.saveEmergencyContact(nombre, telefonoNormalizado);
    print('✅ Contacto guardado de forma segura');
  } catch (e) {
    print('❌ Error: $e');
  }
}

// ============================================================================
// 4. RECUPERAR Y USAR CONTACTO
// ============================================================================

Future<void> ejemploRecuperarContactoEcuador() async {
  try {
    final contact = await SecureStorageService.getEmergencyContact();
    
    if (contact != null) {
      print('👤 Nombre: ${contact['nombre']}');
      print('📞 Teléfono (local): ${contact['telefono']}');
      
      // Si necesitas formato internacional
      final intl = Validators.getInternationalFormat(contact['telefono']!);
      print('📞 Teléfono (internacional): $intl');
    } else {
      print('ℹ️ No hay contacto de emergencia guardado');
    }
  } catch (e) {
    print('❌ Error: $e');
  }
}

// ============================================================================
// 5. CASO DE USO COMPLETO - AGREGAR CONTACTO EN AJUSTES
// ============================================================================

Future<void> ejemploCasoCompletoAjustes() async {
  // Simulamos entrada del usuario
  const nombreIngresado = 'Hospital Metropolitano';
  const telefonoIngresado = '09 3845 6200';  // Con espacios (típico en UI)

  print('📋 Agregando contacto...');
  print('  Nombre: $nombreIngresado');
  print('  Teléfono: $telefonoIngresado');

  // 1. Validar nombre
  if (!Validators.isValidName(nombreIngresado)) {
    print('❌ Nombre inválido');
    return;
  }

  // 2. Validar teléfono
  if (!Validators.isValidPhone(telefonoIngresado)) {
    print('❌ Teléfono inválido. Use formato Ecuador: 0963522505');
    return;
  }

  // 3. Normalizar
  final telefonoNormalizado = Validators.normalizePhoneNumber(telefonoIngresado);
  print('✅ Normalizado: $telefonoNormalizado');

  // 4. Guardar
  try {
    // En memoria
    final contacto = {
      'nombre': nombreIngresado,
      'telefono': telefonoNormalizado,
    };
    
    // En almacenamiento seguro (solo el primero o cuando es favorito)
    await SecureStorageService.saveEmergencyContact(
      nombreIngresado,
      telefonoNormalizado,
    );
    
    print('✅ Contacto guardado: $nombreIngresado ($telefonoNormalizado)');
  } catch (e) {
    print('❌ Error al guardar: $e');
  }
}

// ============================================================================
// 6. WIDGET DE EJEMPLO - DIÁLOGO PARA AGREGAR CONTACTO
// ============================================================================

class AgregarContactoDialogEcuador extends StatefulWidget {
  @override
  State<AgregarContactoDialogEcuador> createState() =>
      _AgregarContactoDialogEcuadorState();
}

class _AgregarContactoDialogEcuadorState
    extends State<AgregarContactoDialogEcuador> {
  final nombreController = TextEditingController();
  final telefonoController = TextEditingController();

  @override
  void dispose() {
    nombreController.dispose();
    telefonoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Agregar contacto de emergencia'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: nombreController,
            decoration: const InputDecoration(
              labelText: 'Nombre',
              hintText: 'Ej: Hospital Metropolitano',
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: telefonoController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Teléfono (Ecuador)',
              hintText: 'Ej: 0963522505 o 09 6352 2505',
              helperText: 'Formato local: 09XXXXXXXX',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () async {
            final nombre = nombreController.text.trim();
            final telefono = telefonoController.text.trim();

            // Validar nombre
            if (!Validators.isValidName(nombre)) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Nombre inválido')),
              );
              return;
            }

            // Validar teléfono
            if (!Validators.isValidPhone(telefono)) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Teléfono inválido. Use formato Ecuador: 0963522505 o 09 6352 2505',
                  ),
                ),
              );
              return;
            }

            // Normalizar
            final telefonoNormalizado = Validators.normalizePhoneNumber(telefono);
            
            // Guardar de forma segura
            await SecureStorageService.saveEmergencyContact(
              nombre,
              telefonoNormalizado,
            );

            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('✅ Contacto guardado: $nombre ($telefonoNormalizado)'),
              ),
            );
            Navigator.pop(context);
          },
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}

// ============================================================================
// 7. PRUEBAS UNITARIAS
// ============================================================================

void pruebasValidacion() {
  print('🧪 Ejecutando pruebas de validación...\n');

  // Pruebas de validación - Formato local
  assert(Validators.isValidPhone('0963522505') == true, 'Falla: 0963522505');
  assert(Validators.isValidPhone('0961234567') == true, 'Falla: 0961234567');
  assert(Validators.isValidPhone('09 6352 2505') == true, 'Falla: 09 6352 2505');
  print('✅ Validación formato local: OK');

  // Pruebas de validación - Formato internacional
  assert(Validators.isValidPhone('+593963522505') == true, 'Falla: +593963522505');
  assert(Validators.isValidPhone('593963522505') == true, 'Falla: 593963522505');
  assert(Validators.isValidPhone('+593 9 6352 2505') == true, 'Falla: +593 9 6352 2505');
  print('✅ Validación formato internacional: OK');

  // Pruebas de validación - Inválidos
  assert(Validators.isValidPhone('123') == false, 'Falla: 123 debería ser inválido');
  assert(Validators.isValidPhone('9963522505') == false, 'Falla: falta 0');
  assert(Validators.isValidPhone('+11234567890') == false, 'Falla: no es Ecuador');
  print('✅ Validación rechazos: OK');

  // Pruebas de normalización - Local
  assert(Validators.normalizePhoneNumber('0963522505') == '0963522505');
  assert(Validators.normalizePhoneNumber('09 6352 2505') == '0963522505');
  assert(Validators.normalizePhoneNumber('+593963522505') == '0963522505');
  assert(Validators.normalizePhoneNumber('593963522505') == '0963522505');
  print('✅ Normalización local: OK');

  // Pruebas de normalización - Internacional
  assert(
    Validators.normalizePhoneNumber('0963522505', international: true) ==
        '+593963522505',
  );
  assert(
    Validators.normalizePhoneNumber('+593963522505', international: true) ==
        '+593963522505',
  );
  print('✅ Normalización internacional: OK');

  // Pruebas de funciones helper
  assert(
    Validators.getInternationalFormat('0963522505') == '+593963522505',
  );
  assert(
    Validators.getLocalFormat('+593963522505') == '0963522505',
  );
  print('✅ Funciones helper: OK');

  print('\n🎉 ¡Todas las pruebas pasaron!');
}

// ============================================================================
// RESUMEN - Uso Recomendado en Formularios Ecuador
// ============================================================================

/*
1. VALIDAR ENTRADA DEL USUARIO:
   if (Validators.isValidPhone(inputPhone)) { ... }

2. NORMALIZAR (automáticamente a formato local):
   final normalized = Validators.normalizePhoneNumber(inputPhone);
   // "09 6352 2505" → "0963522505"

3. GUARDAR DE FORMA SEGURA:
   await SecureStorageService.saveEmergencyContact(name, normalized);

4. RECUPERAR CUANDO SEA NECESARIO:
   final contact = await SecureStorageService.getEmergencyContact();
   // contact['telefono'] = "0963522505"

5. CONVERTIR A INTERNACIONAL SI ES NECESARIO:
   final intl = Validators.getInternationalFormat(phoneLocal);
   // "0963522505" → "+593963522505"

6. LIMPIAR AL LOGOUT:
   await SecureStorageService.deleteAll();

NOTAS:
- El formato por defecto es LOCAL (0963522505)
- Todas las operaciones son síncronas excepto SecureStorageService
- Los validadores no dependen de librerías externas
- Funciona 100% offline
*/
