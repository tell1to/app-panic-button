// EJEMPLOS DE USO - Fase 1 Implementada
// Copiar y adaptar estos ejemplos en tu código

import 'package:flutter/material.dart';
import 'validators/validators.dart';
import 'services/secure_storage_service.dart';

// ============================================================================
// 1. VALIDAR NÚMEROS TELEFÓNICOS
// ============================================================================

void ejemploValidarTelefono() {
  final telefonos = [
    '9123456789',           // ✅ Válido
    '+1 (912) 345-6789',    // ✅ Válido
    '(912) 345-6789',       // ✅ Válido
    '912-345-6789',         // ✅ Válido
    '+52 1234567890',       // ✅ Válido
    'abc123',               // ❌ Inválido
    '123',                  // ❌ Inválido
  ];

  for (final phone in telefonos) {
    if (Validators.isValidPhone(phone)) {
      print('✅ $phone es válido');
      
      // Normalizar a formato internacional
      final normalized = Validators.normalizePhoneNumber(phone);
      print('   Normalizado: $normalized');
    } else {
      print('❌ $phone es inválido');
    }
  }
}

// ============================================================================
// 2. VALIDAR OTRAS ENTRADAS
// ============================================================================

void ejemploValidarOtrosCampos() {
  // Email
  if (Validators.isValidEmail('usuario@ejemplo.com')) {
    print('✅ Email válido');
  }

  // Nombre
  if (Validators.isValidName('Juan Pérez')) {
    print('✅ Nombre válido');
  }

  // Edad
  if (Validators.isValidAge('25')) {
    print('✅ Edad válida');
  }

  // Contraseña
  if (Validators.isValidPassword('Secure@Pass123')) {
    print('✅ Contraseña válida (al menos 8 caracteres, 1 mayúscula, 1 número, 1 símbolo)');
  }
}

// ============================================================================
// 3. GUARDAR NÚMEROS DE TELÉFONO DE FORMA SEGURA
// ============================================================================

Future<void> ejemploGuardarTelefonoSeguro() async {
  const nombreContacto = 'Juan García';
  const telefonoRaw = '(912) 345-6789';

  // 1. Validar
  if (!Validators.isValidPhone(telefonoRaw)) {
    print('❌ Teléfono inválido');
    return;
  }

  // 2. Normalizar
  final telefonoNormalizado = Validators.normalizePhoneNumber(telefonoRaw);
  print('📞 Teléfono normalizado: $telefonoNormalizado');

  // 3. Guardar de forma segura
  try {
    await SecureStorageService.saveEmergencyContact(
      nombreContacto,
      telefonoNormalizado,
    );
    print('✅ Contacto de emergencia guardado de forma segura');
  } catch (e) {
    print('❌ Error: $e');
  }
}

// ============================================================================
// 4. RECUPERAR CONTACTO DE EMERGENCIA
// ============================================================================

Future<void> ejemploRecuperarContactoEmergencia() async {
  try {
    final contact = await SecureStorageService.getEmergencyContact();
    
    if (contact != null) {
      print('👤 Nombre: ${contact['nombre']}');
      print('📞 Teléfono: ${contact['telefono']}');
    } else {
      print('ℹ️ No hay contacto de emergencia guardado');
    }
  } catch (e) {
    print('❌ Error: $e');
  }
}

// ============================================================================
// 5. GUARDAR INFORMACIÓN MÉDICA SENSIBLE
// ============================================================================

Future<void> ejemploGuardarInfoMedica() async {
  const infoMedica = 'Alergia a la penicilina, Diabético tipo 2';
  
  try {
    await SecureStorageService.saveMedicalInfo(infoMedica);
    print('✅ Información médica guardada de forma segura');
  } catch (e) {
    print('❌ Error: $e');
  }
}

// ============================================================================
// 6. GUARDAR ALERGIAS
// ============================================================================

Future<void> ejemploGuardarAlergias() async {
  const alergias = 'Penicilina, Mariscos, Cacahuetes';
  
  try {
    await SecureStorageService.saveAllergies(alergias);
    print('✅ Alergias guardadas de forma segura');
  } catch (e) {
    print('❌ Error: $e');
  }
}

// ============================================================================
// 7. GUARDAR MEDICAMENTOS
// ============================================================================

Future<void> ejemploGuardarMedicamentos() async {
  const medicamentos = 'Metformina 500mg (2x día), Atorvastatina 20mg (1x noche)';
  
  try {
    await SecureStorageService.saveMedications(medicamentos);
    print('✅ Medicamentos guardados de forma segura');
  } catch (e) {
    print('❌ Error: $e');
  }
}

// ============================================================================
// 8. LIMPIAR TODO (LOGOUT)
// ============================================================================

Future<void> ejemploLimpiarDatos() async {
  try {
    await SecureStorageService.deleteAll();
    print('✅ Todos los datos seguros han sido eliminados');
  } catch (e) {
    print('❌ Error: $e');
  }
}

// ============================================================================
// 9. WIDGET DE EJEMPLO - Diálogo para agregar contacto
// ============================================================================

class AgregarContactoDialog extends StatefulWidget {
  @override
  State<AgregarContactoDialog> createState() => _AgregarContactoDialogState();
}

class _AgregarContactoDialogState extends State<AgregarContactoDialog> {
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
              hintText: 'Ej: Juan García',
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: telefonoController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Teléfono',
              hintText: 'Ej: (912) 345-6789 o +1 234 567 8900',
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
                    'Teléfono inválido. Use formato como: (912) 345-6789 o +1 234 567 8900',
                  ),
                ),
              );
              return;
            }

            // Normalizar y guardar de forma segura
            final telefonoNormalizado = Validators.normalizePhoneNumber(telefono);
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
// 10. USO EN MAIN.DART
// ============================================================================

/*
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Ejemplo: Cargar contacto de emergencia al iniciar
  final contact = await SecureStorageService.getEmergencyContact();
  if (contact != null) {
    print('Contacto de emergencia cargado: ${contact['nombre']}');
  }
  
  runApp(const MyApp());
}
*/

// ============================================================================
// RESUMEN - Uso común en formularios
// ============================================================================

/*
1. VALIDAR ENTRADA DEL USUARIO:
   if (Validators.isValidPhone(inputPhone)) { ... }

2. NORMALIZAR ANTES DE GUARDAR:
   final normalized = Validators.normalizePhoneNumber(inputPhone);

3. GUARDAR DE FORMA SEGURA:
   await SecureStorageService.saveEmergencyContact(name, normalized);

4. RECUPERAR CUANDO SEA NECESARIO:
   final contact = await SecureStorageService.getEmergencyContact();

5. LIMPIAR AL LOGOUT:
   await SecureStorageService.deleteAll();
*/
