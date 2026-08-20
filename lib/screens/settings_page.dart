import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_selector/file_selector.dart';

// Importar validadores y servicio de almacenamiento seguro
import '../utils/validators/validators.dart';
import '../services/secure_storage_service.dart';
import '../utils/preferences.dart';

class SenttingsPage extends StatefulWidget {
  const SenttingsPage({super.key});

  @override
  State<SenttingsPage> createState() => _SenttingsPageState();
}

class _SenttingsPageState extends State<SenttingsPage> {
  // Profile photo bytes (persisted as base64)
  Uint8List? _profilePhoto;
  static const String _profilePhotoKey = 'profile_photo_base64';

  // Profile data keys
  static const String _profileNameKey = 'profile_nombres';
  static const String _profileLastKey = 'profile_apellidos';
  static const String _profileAgeKey = 'profile_edad';
  static const String _profileDiseasesKey = 'profile_enfermedades';
  static const String _profileBloodTypeKey = 'profile_blood_type';
  static const String _profileOtherDiseaseKey = 'profile_other_disease';
  static const String _ciSetKey = 'ci_already_set';

  // Variables del perfil
  String _ci = "";
  String _nombres = "";
  String _apellidos = "";
  String _edad = "";
  List<String> _enfermedades = [];
  String _tipoSangre = "";
  String _otraEnfermedad = "";
  bool _ciAlreadySet = false;

  final List<String> enfermedadesCatastroficas = [
    'Cáncer', 'Insuficiencia renal', 'Cardiopatía grave', 'Esclerosis múltiple', 'Trasplante de órganos'
  ];

  final List<String> tiposSangre = [
    'O+', 'O-', 'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-'
  ];

  // Contactos
  List<Map<String, String>> _contactos = [];

  static const String _contactsKey = 'user_contacts';

  @override
  void initState() {
    super.initState();
    _loadContacts();
    _loadProfilePhoto();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    try {
      final sp = await SharedPreferences.getInstance();
      final nombres = sp.getString(_profileNameKey) ?? '';
      final apellidos = sp.getString(_profileLastKey) ?? '';
      final edad = sp.getString(_profileAgeKey) ?? '';
      final enfermedades = sp.getStringList(_profileDiseasesKey) ?? [];
      final tipoSangre = sp.getString(_profileBloodTypeKey) ?? '';
      final otraEnfermedad = sp.getString(_profileOtherDiseaseKey) ?? '';
      var ci = await SecureStorageService.getCI() ?? '';
      var ciAlreadySet = sp.getBool(_ciSetKey) ?? false;
      
      // MIGRACIÓN: Si no hay CI en SecureStorage pero existe en SharedPreferences antiguo
      // y el flag no está establecido, es un usuario que completó el tutorial antes del cambio
      if (ci.isEmpty && !ciAlreadySet) {
        final oldProfileCI = sp.getString('profile_ci') ?? '';
        if (oldProfileCI.isNotEmpty) {
          print('[_loadProfileData] MIGRACIÓN DETECTADA: Encontrado CI en profile_ci (usuario antiguo)');
          try {
            // Guardar el CI antiguo en SecureStorage
            await SecureStorageService.saveCI(oldProfileCI);
            // Marcar que el CI ya fue establecido
            await sp.setBool(_ciSetKey, true);
            ci = oldProfileCI;
            ciAlreadySet = true;
            print('[_loadProfileData] MIGRACIÓN COMPLETADA: CI migrado a SecureStorage y flag establecido');
          } catch (e) {
            print('[_loadProfileData] ERROR EN MIGRACIÓN: $e');
          }
        }
      }
      
      if (!mounted) return;
      setState(() {
        _ci = ci;
        _nombres = nombres;
        _apellidos = apellidos;
        _edad = edad;
        _enfermedades = List<String>.from(enfermedades);
        _tipoSangre = tipoSangre;
        _otraEnfermedad = otraEnfermedad;
        _ciAlreadySet = ciAlreadySet;
      });
    } catch (_) {}
  }

  Future<void> _saveProfileData() async {
    try {
      final sp = await SharedPreferences.getInstance();
      
      // PROTECCIÓN MÁXIMA: Si el CI ya fue establecido, nunca permitir cambiarlo
      if (_ciAlreadySet) {
        final storedCI = await SecureStorageService.getCI() ?? '';
        // Si el CI actual es diferente al almacenado, rechazar el cambio
        if (_ci != storedCI && storedCI.isNotEmpty) {
          print('[_saveProfileData] INTENTO BLOQUEADO: CI no puede ser modificado después de ser establecido');
          throw Exception('CI_IMMUTABLE: No se puede modificar el CI después de ser establecido');
        }
      }
      
      await sp.setString(_profileNameKey, _nombres);
      await sp.setString(_profileLastKey, _apellidos);
      await sp.setString(_profileAgeKey, _edad);
      await sp.setStringList(_profileDiseasesKey, _enfermedades);
      await sp.setString(_profileBloodTypeKey, _tipoSangre);
      await sp.setString(_profileOtherDiseaseKey, _otraEnfermedad);
      
      // Marcar que el CI fue establecido si no lo había sido antes
      if (!_ciAlreadySet && _ci.isNotEmpty) {
        await sp.setBool(_ciSetKey, true);
        _ciAlreadySet = true;
      }
      
      await SecureStorageService.saveUserProfile(
        ci: _ci,
        firstName: _nombres,
        lastName: _apellidos,
        age: _edad,
        diseases: jsonEncode(_enfermedades),
      );
    } catch (e) {
      print('[_saveProfileData] ERROR: $e');
      rethrow;
    }
  }

  Future<void> _loadProfilePhoto() async {
    try {
      final sp = await SharedPreferences.getInstance();
      final String? b64 = sp.getString(_profilePhotoKey);
      if (b64 != null && mounted) {
        setState(() {
          _profilePhoto = base64Decode(b64);
        });
      }
    } catch (_) {}
  }

  Future<void> _saveProfilePhoto(Uint8List bytes) async {
    try {
      final sp = await SharedPreferences.getInstance();
      await sp.setString(_profilePhotoKey, base64Encode(bytes));
      if (mounted) setState(() { _profilePhoto = bytes; });
    } catch (_) {}
  }

  Future<void> _loadContacts() async {
    try {
      final sp = await SharedPreferences.getInstance();
      final raw = sp.getStringList(_contactsKey);
      if (raw != null) {
        final loaded = raw.map((s) {
          final Map<String, dynamic> m = jsonDecode(s) as Map<String, dynamic>;
          return m.map((k, v) => MapEntry(k, v.toString()));
        }).toList();
        if (!mounted) return;
        setState(() {
          _contactos = List<Map<String, String>>.from(loaded);
        });
        // Notify all listeners about the loaded contacts list
        allContacts.value = List<Map<String, String>>.from(loaded);
      }
    } catch (_) {}
  }

  Future<void> _saveContacts() async {
    try {
      final sp = await SharedPreferences.getInstance();
      final raw = _contactos.map((m) => jsonEncode(m)).toList();
      await sp.setStringList(_contactsKey, raw);
      // Notify all listeners about the updated contacts list
      allContacts.value = List<Map<String, String>>.from(_contactos);
    } catch (_) {}
  }

  // --- VALIDACIONES ---
  bool _esNombreValido(String nombre) {
    return Validators.isValidName(nombre);
  }

  bool _esTelefonoValido(String telefono) {
    return Validators.isValidPhone(telefono);
  }

  bool _esEdadValida(String edad) {
    return Validators.isValidAge(edad);
  }

  String _generarListaEnfermedades() {
    List<String> listaCompleta = List.from(_enfermedades);
    if (_otraEnfermedad.isNotEmpty) {
      listaCompleta.add(_otraEnfermedad);
    }
    return listaCompleta.isEmpty ? "Ninguna" : listaCompleta.join(", ");
  }

  // --- Contactos ---
  /// Verifica si el teléfono (ya normalizado) pertenece a otro contacto.
  /// Al editar, [index] indica el contacto que se está modificando para
  /// no compararse consigo mismo.
  bool _esTelefonoDuplicado(String telefonoNormalizado, {int? index}) {
    return _contactos.asMap().entries.any((entry) {
      if (entry.key == index) return false;
      final otroTelefono =
          Validators.normalizePhoneNumber(entry.value['telefono'] ?? '');
      return otroTelefono == telefonoNormalizado;
    });
  }

  void _showContactoDialog({int? index}) {
    final String initialNombre = index != null ? _contactos[index]['nombre'] ?? '' : '';
    final String initialTelefono = index != null ? _contactos[index]['telefono'] ?? '' : '';

    final nombreController = TextEditingController(text: initialNombre);
    final telefonoController = TextEditingController(text: initialTelefono);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(index == null ? 'Nuevo contacto' : 'Editar contacto'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  decoration: const InputDecoration(labelText: 'Nombre del responsable'),
                  controller: nombreController,
                  maxLength: 50,
                  maxLengthEnforcement: MaxLengthEnforcement.enforced,
                  inputFormatters: [LengthLimitingTextInputFormatter(50)],
                ),
                TextField(
                  decoration: const InputDecoration(labelText: 'Número de teléfono'),
                  keyboardType: TextInputType.phone,
                  controller: telefonoController,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Cerrar'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: const Text('Guardar'),
              onPressed: () async {
                final nombre = nombreController.text.trim();
                final telefono = telefonoController.text.trim();
                final navigator = Navigator.of(context);
                final messenger = ScaffoldMessenger.of(context);

                if (!_esNombreValido(nombre)) {
                  messenger.showSnackBar(const SnackBar(content: Text('El nombre no puede estar vacío y solo debe contener letras y espacios.')));
                  return;
                }
                if (nombre.length > 50) {
                  messenger.showSnackBar(const SnackBar(content: Text('El nombre no puede exceder 50 caracteres.')));
                  return;
                }
                if (!_esTelefonoValido(telefono)) {
                  messenger.showSnackBar(const SnackBar(content: Text('Teléfono inválido. Use formato de Ecuador: 0963522505 o +593963522505')));
                  return;
                }

                // Normalizar número de teléfono al formato local de Ecuador (0963522505)
                final telefonoNormalizado = Validators.normalizePhoneNumber(telefono);

                // Validación anti-duplicados: no permitir que dos contactos compartan el mismo número
                if (_esTelefonoDuplicado(telefonoNormalizado, index: index)) {
                  // Popup de número duplicado (el diálogo de contacto queda abierto para corregir)
                  showDialog(
                    context: context,
                    builder: (dialogContext) => AlertDialog(
                      title: const Text('Número duplicado'),
                      content: const Text('Número duplicado, no se puede colocar. Este teléfono ya está registrado en otro contacto.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(dialogContext).pop(),
                          child: const Text('Aceptar'),
                        ),
                      ],
                    ),
                  );
                  return;
                }

                if (index == null) {
                  _contactos.add({'nombre': nombre, 'telefono': telefonoNormalizado});
                } else {
                  _contactos[index] = {'nombre': nombre, 'telefono': telefonoNormalizado};
                }

                await _saveContacts();

                // Si editamos un contacto que era el preferido, actualizar los datos del contacto favorito
                if (index != null && preferredContact.value != null && preferredContact.value!['index'] == index) {
                  await setPreferredContact({'nombre': nombre, 'telefono': telefonoNormalizado, 'index': index});
                  await SecureStorageService.saveEmergencyContact(nombre, telefonoNormalizado);
                }

                if (!mounted) return;
                setState(() {});
                navigator.pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showDeleteConfirmDialog(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar contacto'),
        content: const Text('¿Seguro que deseas eliminar este contacto?'),
        actions: [
          TextButton(
            child: const Text('Cancelar'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          ElevatedButton(
            child: const Text('Eliminar'),
            onPressed: () async {
              final navigator = Navigator.of(context);
              _contactos.removeAt(index);
              await _saveContacts();
              // Si el contacto eliminado era el favorito, limpiar el favorito
              if (preferredContact.value != null && preferredContact.value!['index'] == index) {
                await setPreferredContact(null);
              }
              if (!mounted) return;
              setState(() {});
              navigator.pop();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _showEditProfileDialog() async {
    // Recargar el estado de _ciAlreadySet desde SharedPreferences para evitar vulnerabilidades
    try {
      final sp = await SharedPreferences.getInstance();
      var ciAlreadySet = sp.getBool(_ciSetKey) ?? false;
      
      // MIGRACIÓN ADICIONAL: Si aún no está establecido pero existe profile_ci antiguo
      if (!ciAlreadySet) {
        final oldProfileCI = sp.getString('profile_ci') ?? '';
        if (oldProfileCI.isNotEmpty && _ci.isEmpty) {
          print('[_showEditProfileDialog] MIGRACIÓN DETECTADA: CI antiguo encontrado en apertura de diálogo');
          try {
            await SecureStorageService.saveCI(oldProfileCI);
            await sp.setBool(_ciSetKey, true);
            ciAlreadySet = true;
            print('[_showEditProfileDialog] MIGRACIÓN COMPLETADA');
          } catch (e) {
            print('[_showEditProfileDialog] ERROR EN MIGRACIÓN: $e');
          }
        }
      }
      
      final storedCI = _ci; // Guardar el CI actual
      if (mounted) {
        setState(() {
          _ciAlreadySet = ciAlreadySet;
          // Si el CI ya fue establecido, asegurarse de que el estado lo refleje
          if (ciAlreadySet && storedCI.isEmpty) {
            print('[_showEditProfileDialog] ADVERTENCIA: CI marcado como establecido pero el valor es vacío');
          }
        });
      }
    } catch (_) {}

    final ciController = TextEditingController(text: _ci);
    final nombresController = TextEditingController(text: _nombres);
    final apellidosController = TextEditingController(text: _apellidos);
    final edadController = TextEditingController(text: _edad);
    final otraEnfermedadController = TextEditingController(text: _otraEnfermedad);
    String tipoSangreSeleccionado = _tipoSangre;
    List<String> enfermedadesSeleccionadas = List.from(_enfermedades);
    
    // Si hay una enfermedad personalizada guardada, agregar "Otro" a la lista
    if (_otraEnfermedad.isNotEmpty && !enfermedadesSeleccionadas.contains('Otro')) {
      enfermedadesSeleccionadas.add('Otro');
    }

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) {
        Uint8List? previewBytes = _profilePhoto;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Editar perfil'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 36,
                          backgroundColor: Colors.pink.shade50,
                          backgroundImage: previewBytes != null ? MemoryImage(previewBytes!) : null,
                          child: previewBytes == null ? const Icon(Icons.person, color: Colors.pink, size: 36) : null,
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: () async {
                            final XFile? file = await openFile(acceptedTypeGroups: [XTypeGroup(label: 'images', extensions: ['jpg', 'jpeg', 'png'])]);
                            if (file != null) {
                              final bytes = await file.readAsBytes();
                              setDialogState(() { previewBytes = bytes; });
                            }
                          },
                          child: const Text('Seleccionar foto'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      decoration: InputDecoration(
                        labelText: 'Cédula de Identidad',
                        helperText: _ciAlreadySet ? 'El CI no se puede modificar después de ser establecido' : null,
                        helperStyle: const TextStyle(color: Colors.orange, fontSize: 12),
                        disabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      controller: ciController,
                      keyboardType: TextInputType.number,
                      maxLength: 10,
                      maxLengthEnforcement: MaxLengthEnforcement.enforced,
                      readOnly: _ciAlreadySet,
                      enabled: !_ciAlreadySet,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      decoration: const InputDecoration(labelText: 'Nombres'),
                      controller: nombresController,
                    ),
                    TextField(
                      decoration: const InputDecoration(labelText: 'Apellidos'),
                      controller: apellidosController,
                    ),
                    TextField(
                      decoration: const InputDecoration(labelText: 'Edad'),
                      keyboardType: TextInputType.number,
                      controller: edadController,
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Tipo de Sangre',
                        border: OutlineInputBorder(),
                      ),
                      value: tipoSangreSeleccionado.isEmpty ? null : tipoSangreSeleccionado,
                      items: tiposSangre.map((tipo) {
                        return DropdownMenuItem<String>(
                          value: tipo,
                          child: Text(tipo),
                        );
                      }).toList(),
                      onChanged: (valor) {
                        if (valor != null) {
                          tipoSangreSeleccionado = valor;
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                    const Text('Enfermedad(es) catastrófica:', style: TextStyle(fontWeight: FontWeight.bold)),
                    ...enfermedadesCatastroficas.map((enfermedad) {
                      return CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(enfermedad),
                        value: enfermedadesSeleccionadas.contains(enfermedad),
                        onChanged: (checked) {
                          setDialogState(() {
                            if (checked == true) {
                              enfermedadesSeleccionadas.add(enfermedad);
                            } else {
                              enfermedadesSeleccionadas.remove(enfermedad);
                            }
                          });
                        },
                      );
                    }),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Otro:'),
                      value: enfermedadesSeleccionadas.contains('Otro'),
                      onChanged: (checked) {
                        setDialogState(() {
                          if (checked == true) {
                            enfermedadesSeleccionadas.add('Otro');
                          } else {
                            enfermedadesSeleccionadas.remove('Otro');
                          }
                        });
                      },
                    ),
                    if (enfermedadesSeleccionadas.contains('Otro'))
                      Padding(
                        padding: const EdgeInsets.only(left: 16.0, top: 4.0),
                        child: TextField(
                          decoration: const InputDecoration(
                            labelText: 'Especifica la enfermedad',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          controller: otraEnfermedadController,
                          maxLines: 2,
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  child: const Text('Cerrar'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                ElevatedButton(
                  child: const Text('Guardar'),
                  onPressed: () async {
                    final ci = ciController.text.trim();
                    final nombres = nombresController.text.trim();
                    final apellidos = apellidosController.text.trim();
                    final edad = edadController.text.trim();
                    final otraEnfermedad = otraEnfermedadController.text.trim();
                    final navigator = Navigator.of(context);

                    // Recarga nuevamente desde SharedPreferences para máxima seguridad
                    try {
                      final sp = await SharedPreferences.getInstance();
                      final ciSetInStorage = sp.getBool(_ciSetKey) ?? false;
                      final storedCI = _ci; // Guardar el CI actual almacenado
                      
                      // Si el CI ya fue establecido antes, BLOQUEAR CUALQUIER INTENTO DE CAMBIO
                      if (ciSetInStorage && ci != storedCI) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('La cédula de identidad no se puede cambiar después de ser establecida. Este cambio ha sido bloqueado por seguridad.'))
                        );
                        return;
                      }
                    } catch (_) {}

                    // Validación adicional: verificar contra el estado local
                    if (_ciAlreadySet && ci != _ci) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('La cédula de identidad no se puede cambiar después de ser establecida. Este cambio ha sido bloqueado por seguridad.'))
                      );
                      return;
                    }

                    if (ci.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('La cédula de identidad es requerida.'))
                      );
                      return;
                    }
                    if (ci.length < 10) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('La cédula debe tener 10 dígitos.'))
                      );
                      return;
                    }
                    if (!_esNombreValido(nombres) || !_esNombreValido(apellidos)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Nombres y apellidos no pueden estar vacíos y solo deben contener letras y espacios.'))
                      );
                      return;
                    }
                    if (!_esEdadValida(edad)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Edad inválida, debe ser un número entre 1 y 120.'))
                      );
                      return;
                    }
                    if (enfermedadesSeleccionadas.contains('Otro') && otraEnfermedad.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Por favor especifica la enfermedad en el campo "Otro".'))
                      );
                      return;
                    }

                    // Guardar si "Otro" estaba seleccionado ANTES de removerlo
                    final otroEstabaMarcado = enfermedadesSeleccionadas.contains('Otro');

                    // Remover "Otro" de la lista de enfermedades
                    enfermedadesSeleccionadas.remove('Otro');
                    
                    // Guardar la enfermedad personalizada solo si "Otro" estaba marcado
                    final finalOtraEnfermedad = otroEstabaMarcado ? otraEnfermedad : '';

                    // Save profile photo if selected
                    if (previewBytes != null) {
                      await _saveProfilePhoto(previewBytes!);
                    }

                    if (!mounted) return;
                    setState(() {
                      _ci = ci;
                      _nombres = nombres;
                      _apellidos = apellidos;
                      _edad = edad;
                      _enfermedades = enfermedadesSeleccionadas;
                      _tipoSangre = tipoSangreSeleccionado;
                      _otraEnfermedad = finalOtraEnfermedad;
                    });

                    // Persist profile data
                    try {
                      await _saveProfileData();
                      navigator.pop();
                    } catch (e) {
                      if (e.toString().contains('CI_IMMUTABLE')) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('La cédula de identidad no se puede cambiar después de ser establecida. Este cambio ha sido rechazado.'))
                        );
                        // Restaurar los valores anteriores en el estado
                        if (!mounted) return;
                        await _loadProfileData();
                      } else {
                        print('[_showEditProfileDialog] ERROR al guardar: $e');
                      }
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Compute responsive font sizes based on device width
    final double deviceWidth = MediaQuery.of(context).size.width;
    final double nameFontSize = (deviceWidth * 0.045).clamp(14.0, 18.0);
    final double phoneFontSize = (deviceWidth * 0.035).clamp(12.0, 14.0);

    return Scaffold(
      backgroundColor: const Color(0xFFFFF5F6),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Ajustes', style: TextStyle(color: Colors.black)),
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const SizedBox(height: 6),
            const Text('Configura tu aplicación de emergencia', style: TextStyle(fontSize: 14, color: Colors.black54)),
            const SizedBox(height: 12),

            // Perfil
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                leading: CircleAvatar(
                  radius: 32,
                  backgroundColor: Colors.pink.shade50,
                  backgroundImage: _profilePhoto != null ? MemoryImage(_profilePhoto!) : null,
                  child: _profilePhoto == null ? const Icon(Icons.person, color: Colors.pink, size: 28) : null,
                ),
                title: const Text('Perfil personal', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                subtitle: Text(
                  _ci.isEmpty && _nombres.isEmpty && _apellidos.isEmpty && _edad.isEmpty && _tipoSangre.isEmpty && _enfermedades.isEmpty && _otraEnfermedad.isEmpty
                    ? 'Editar información personal y médica'
                    : 'CI: $_ci\nNombre: $_nombres\nApellido: $_apellidos\nEdad: $_edad\nTipo de Sangre: ${_tipoSangre.isEmpty ? "No especificado" : _tipoSangre}\nEnfermedades: ${_generarListaEnfermedades()}',
                  style: const TextStyle(fontSize: 13),
                ),
                trailing: TextButton(
                  onPressed: _showEditProfileDialog,
                  child: const Text('Editar', style: TextStyle(color: Colors.red)),
                ),
              ),
            ),

            const SizedBox(height: 18),

            const Padding(
              padding: EdgeInsets.only(bottom: 8.0),
              child: Text('Contactos', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            ),

            // === AQUI ESTA EL CAMBIO RESPONSIVE ===
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  ..._contactos.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final contacto = entry.value;
                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Leading avatar
                              CircleAvatar(
                                backgroundColor: idx % 2 == 0 ? Colors.blue.shade50 : Colors.green.shade50,
                                child: const Icon(Icons.phone, color: Colors.blue),
                              ),
                              const SizedBox(width: 12),
                              // Title and subtitle with Expanded to prevent truncation
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      contacto['nombre'] ?? '',
                                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: nameFontSize),
                                      softWrap: true,
                                      overflow: TextOverflow.visible,
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4.0),
                                      child: Text(
                                        contacto['telefono'] ?? '',
                                        style: TextStyle(fontSize: phoneFontSize),
                                        softWrap: true,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Action buttons
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Favorite star (uses global notifier)
                                  ValueListenableBuilder<Map<String, dynamic>?>(
                                    valueListenable: preferredContact,
                                    builder: (context, fav, _) {
                                      final bool isFav = fav != null && fav['index'] == idx;
                                      return IconButton(
                                        constraints: const BoxConstraints(), // Reduce area extra
                                        padding: const EdgeInsets.all(8),
                                        icon: Icon(isFav ? Icons.star : Icons.star_border, size: 22),
                                        color: isFav ? Colors.amber : Colors.grey,
                                        onPressed: () async {
                                          final messenger = ScaffoldMessenger.of(context);
                                          if (isFav) {
                                            await setPreferredContact(null);
                                            /*messenger.showSnackBar(const SnackBar(content: Text('Contacto favorito removido')));*/
                                          } else {
                                            await setPreferredContact({'nombre': contacto['nombre'] ?? '', 'telefono': contacto['telefono'] ?? '', 'index': idx});
                                            /*messenger.showSnackBar(const SnackBar(content: Text('Contacto marcado como favorito')));*/
                                          }
                                          if (!mounted) return;
                                          setState(() {});
                                        },
                                      );
                                    },
                                  ),
                                  TextButton(
                                    onPressed: () => _showContactoDialog(index: idx),
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 8),
                                      minimumSize: const Size(0, 0),
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: const Text('Editar', style: TextStyle(color: Colors.red, fontSize: 13)),
                                  ),
                                  IconButton(
                                    constraints: const BoxConstraints(),
                                    padding: const EdgeInsets.all(8),
                                    icon: const Icon(Icons.delete_outline, size: 22),
                                    color: Colors.grey,
                                    onPressed: () => _showDeleteConfirmDialog(idx),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 1),
                      ],
                    );
                  }),
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: OutlinedButton(
                      onPressed: () => _showContactoDialog(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.black,
                        side: BorderSide(color: Colors.grey.shade400),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [Icon(Icons.add), SizedBox(width: 8), Text('Agregar contacto')],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // === FIN DEL CAMBIO RESPONSIVE ===

            const SizedBox(height: 18),

            const Padding(
              padding: EdgeInsets.only(bottom: 8.0),
              child: Text('Seguridad y Privacidad', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            ),
            
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: <Widget>[
                  ExpansionTile(
                    tilePadding: const EdgeInsets.symmetric(horizontal: 16),
                    leading: const CircleAvatar(backgroundColor: Colors.white, child: Icon(Icons.shield, color: Colors.black54)),
                    title: const Text('Privacidad', style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: const Text('Toque para más información', style: TextStyle(fontSize: 13)),
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                        child: Text(
                          'Tus datos son tratados únicamente para mejorar el servicio y activar funciones de emergencia. '
                          'No se venden ni se usan para fines comerciales externos, publicidad dirigida ni negocios no autorizados. '
                          'Los datos personales sensibles se encriptan y almacenan de manera segura y solo se envían a la base de datos.',
                          textAlign: TextAlign.justify,
                          style: TextStyle(fontSize: 15, height: 1.5, color: const Color.fromARGB(255, 0, 0, 0)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: const CircleAvatar(backgroundColor: Colors.white, child: Icon(Icons.phone_android, color: Colors.black54)),
                title: const Text('Versión de la app', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('1.4.71', style: TextStyle(fontSize: 13)),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}