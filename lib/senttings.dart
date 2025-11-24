import 'dart:convert';
import 'dart:async'; // A veces necesario para Uint8List dependiendo de la versión, pero base64Decode lo usa de dart:convert

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_selector/file_selector.dart';
import 'package:url_launcher/url_launcher.dart'; // Si lo usas, aunque en este archivo no parece necesario, lo dejo por si acaso.

// Asegúrate de que este archivo exista y tenga 'preferredContact' y 'setPreferredContact'
import 'preferences.dart'; 

class SenttingsPage extends StatefulWidget {
  const SenttingsPage({super.key});

  @override
  State<SenttingsPage> createState() => _SenttingsPageState();
}

class _SenttingsPageState extends State<SenttingsPage> {
  bool _notifications = true;
  bool _location = true;

  // Profile photo bytes (persisted as base64)
  Uint8List? _profilePhoto;
  static const String _profilePhotoKey = 'profile_photo_base64';

  // Profile data keys
  static const String _profileNameKey = 'profile_nombres';
  static const String _profileLastKey = 'profile_apellidos';
  static const String _profileAgeKey = 'profile_edad';
  static const String _profileDiseasesKey = 'profile_enfermedades';

  // Variables del perfil
  String _nombres = "";
  String _apellidos = "";
  String _edad = "";
  List<String> _enfermedades = [];

  final List<String> enfermedadesCatastroficas = [
    'Cáncer', 'Insuficiencia renal', 'Cardiopatía grave', 'Esclerosis múltiple', 'Trasplante de órganos'
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
      if (!mounted) return;
      setState(() {
        _nombres = nombres;
        _apellidos = apellidos;
        _edad = edad;
        _enfermedades = List<String>.from(enfermedades);
      });
    } catch (_) {}
  }

  Future<void> _saveProfileData() async {
    try {
      final sp = await SharedPreferences.getInstance();
      await sp.setString(_profileNameKey, _nombres);
      await sp.setString(_profileLastKey, _apellidos);
      await sp.setString(_profileAgeKey, _edad);
      await sp.setStringList(_profileDiseasesKey, _enfermedades);
    } catch (_) {}
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
      }
    } catch (_) {}
  }

  Future<void> _saveContacts() async {
    try {
      final sp = await SharedPreferences.getInstance();
      final raw = _contactos.map((m) => jsonEncode(m)).toList();
      await sp.setStringList(_contactsKey, raw);
    } catch (_) {}
  }

  // --- VALIDACIONES ---
  bool _esNombreValido(String nombre) {
    return RegExp(r'^[A-Za-záéíóúÁÉÍÓÚüÜñÑ\s]+$').hasMatch(nombre) && nombre.isNotEmpty;
  }

  bool _esTelefonoValido(String telefono) {
    // Accept only 10 digits, no spaces
    return RegExp(r'^\d{10}$').hasMatch(telefono);
  }

  bool _esEdadValida(String edad) {
    int? edadInt = int.tryParse(edad);
    return edadInt != null && edadInt >= 1 && edadInt <= 120;
  }

  // --- Contactos ---
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
                  messenger.showSnackBar(const SnackBar(content: Text('Teléfono inválido. Use 10 dígitos sin espacios (ej: 9123456789).')));
                  return;
                }

                String? previousPhone;
                if (index == null) {
                  _contactos.add({'nombre': nombre, 'telefono': telefono});
                } else {
                  previousPhone = _contactos[index]['telefono'];
                  _contactos[index] = {'nombre': nombre, 'telefono': telefono};
                }

                await _saveContacts();

                // If this is the first contact added, mark it as preferred and select it for main button
                if (index == null && _contactos.length == 1) {
                  await setPreferredContact({'nombre': nombre, 'telefono': telefono});
                  try {
                    final sp = await SharedPreferences.getInstance();
                    await sp.setInt('main_favorite_index', 1);
                  } catch (_) {}
                }

                // If we edited a contact that was previously the preferred, update the preferred info
                if (index != null && previousPhone != null && preferredContact.value != null && preferredContact.value!['telefono'] == previousPhone) {
                  await setPreferredContact({'nombre': nombre, 'telefono': telefono});
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
              final removed = _contactos.removeAt(index);
              final removedPhone = removed['telefono'];
              await _saveContacts();
              if (preferredContact.value != null && preferredContact.value!['telefono'] == removedPhone) {
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

  // --- Alertas y Notificaciones ---
  Future<void> _toggleNotifications(bool value) async {
    setState(() => _notifications = value);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(
        value ? 'Notificaciones activadas' : 'Notificaciones desactivadas'
      )),
    );
  }

  Future<void> _toggleLocation(bool value) async {
    setState(() => _location = value);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(
        value ? 'Compartiendo ubicación GPS' : 'Ubicación GPS desactivada'
      )),
    );
  }


  void _showEditProfileDialog() {
    final nombresController = TextEditingController(text: _nombres);
    final apellidosController = TextEditingController(text: _apellidos);
    final edadController = TextEditingController(text: _edad);
    List<String> enfermedadesSeleccionadas = List.from(_enfermedades);

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
                    final nombres = nombresController.text.trim();
                    final apellidos = apellidosController.text.trim();
                    final edad = edadController.text.trim();
                    final navigator = Navigator.of(context);

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

                    // Save profile photo if selected
                    if (previewBytes != null) {
                      await _saveProfilePhoto(previewBytes!);
                    }

                    if (!mounted) return;
                    setState(() {
                      _nombres = nombres;
                      _apellidos = apellidos;
                      _edad = edad;
                      _enfermedades = enfermedadesSeleccionadas;
                    });

                    // Persist profile data
                    await _saveProfileData();
                    navigator.pop();
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
    final double nameFontSize = (deviceWidth * 0.045).clamp(14.0, 18.0) as double;
    final double phoneFontSize = (deviceWidth * 0.035).clamp(12.0, 14.0) as double;

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
                  _nombres.isEmpty && _apellidos.isEmpty && _edad.isEmpty && _enfermedades.isEmpty
                    ? 'Editar información médica'
                    : 'Nombre: $_nombres\nApellido: $_apellidos\nEdad: $_edad\nEnfermedades: ${_enfermedades.join(", ")}',
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
              child: Text('Alertas y Notificaciones', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            ),

            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: <Widget>[
                  SwitchListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    secondary: CircleAvatar(
                      backgroundColor: Colors.amber.shade50,
                      child: const Icon(Icons.notifications, color: Colors.amber),
                    ),
                    title: const Text('Notificaciones', style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: const Text('Alertas push activadas', style: TextStyle(fontSize: 13)),
                    value: _notifications,
                    onChanged: _toggleNotifications,
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    secondary: CircleAvatar(
                      backgroundColor: Colors.blue.shade50,
                      child: const Icon(Icons.location_on, color: Colors.blue),
                    ),
                    title: const Text('Ubicación', style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: const Text('Compartir ubicación GPS', style: TextStyle(fontSize: 13)),
                    value: _location,
                    onChanged: _toggleLocation,
                  ),
                ],
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
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: CircleAvatar(
                            backgroundColor: idx % 2 == 0 ? Colors.blue.shade50 : Colors.green.shade50,
                            child: const Icon(Icons.phone, color: Colors.blue),
                          ),
                          // Cambiado para responsive: sin maxLines, softWrap true
                          title: Text(
                            contacto['nombre'] ?? '',
                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: nameFontSize),
                            softWrap: true,
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              contacto['telefono'] ?? '',
                              style: TextStyle(fontSize: phoneFontSize),
                              softWrap: true,
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Favorite star (uses global notifier)
                              ValueListenableBuilder<Map<String, String>?>(
                                valueListenable: preferredContact,
                                builder: (context, fav, _) {
                                  final bool isFav = fav != null && fav['telefono'] == (contacto['telefono'] ?? '');
                                  return IconButton(
                                    constraints: const BoxConstraints(), // Reduce area extra
                                    padding: const EdgeInsets.all(8),
                                    icon: Icon(isFav ? Icons.star : Icons.star_border, size: 22),
                                    color: isFav ? Colors.amber : Colors.grey,
                                    onPressed: () async {
                                      final messenger = ScaffoldMessenger.of(context);
                                      if (isFav) {
                                        await setPreferredContact(null);
                                        messenger.showSnackBar(const SnackBar(content: Text('Contacto favorito removido')));
                                      } else {
                                        await setPreferredContact({'nombre': contacto['nombre'] ?? '', 'telefono': contacto['telefono'] ?? ''});
                                        messenger.showSnackBar(const SnackBar(content: Text('Contacto marcado como favorito')));
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
                        children: const [Icon(Icons.add), SizedBox(width: 8), Text('+ Agregar contacto')],
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
                          'Los datos personales sensibles se mantienen en el dispositivo y sólo se comparten con los contactos que tú configures.',
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
                subtitle: const Text('1.0.0', style: TextStyle(fontSize: 13)),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}