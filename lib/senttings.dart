import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'preferences.dart';

class SenttingsPage extends StatefulWidget {
  const SenttingsPage({super.key});

  @override
  State<SenttingsPage> createState() => _SenttingsPageState();
}

class _SenttingsPageState extends State<SenttingsPage> {
  bool _notifications = true;
  bool _location = true;
  bool _autoCall = false;

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

  Future<void> _toggleAutoCall(bool value) async {
    setState(() => _autoCall = value);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(
        value ? 'Llamada automática activada' : 'Llamada automática desactivada'
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
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Editar perfil'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                  onPressed: () {
                    final nombres = nombresController.text.trim();
                    final apellidos = apellidosController.text.trim();
                    final edad = edadController.text.trim();

                    if (!_esNombreValido(nombres) || !_esNombreValido(apellidos)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Nombres y apellidos no pueden estar vacíos y solo deben contener letras y espacios.'))
                      );
                      return;
                    }
                    if (!_esEdadValida(edad)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Edad inválida, debe ser un número entre 1 y 120.'))
                      );
                      return;
                    }

                    setState(() {
                      _nombres = nombres;
                      _apellidos = apellidos;
                      _edad = edad;
                      _enfermedades = enfermedadesSeleccionadas;
                    });
                    Navigator.of(context).pop();
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
                  radius: 24,
                  backgroundColor: Colors.pink.shade50,
                  child: const Icon(Icons.person, color: Colors.pink),
                ),
                title: const Text('Perfil personal', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                subtitle: Text(_nombres.isEmpty && _apellidos.isEmpty && _edad.isEmpty && _enfermedades.isEmpty
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
                  const Divider(height: 1),
                  SwitchListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    secondary: CircleAvatar(
                      backgroundColor: Colors.green.shade50,
                      child: const Icon(Icons.call, color: Colors.green),
                    ),
                    title: const Text('Llamada automática', style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: const Text('Llamar al activar pánico', style: TextStyle(fontSize: 13)),
                    value: _autoCall,
                    onChanged: _toggleAutoCall,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            const Padding(
              padding: EdgeInsets.only(bottom: 8.0),
              child: Text('Contactos', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            ),

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
                          title: Text(contacto['nombre'] ?? '',
                              style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text(contacto['telefono'] ?? '', style: const TextStyle(fontSize: 13)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Favorite star (uses global notifier)
                              ValueListenableBuilder<Map<String, String>?>(
                                valueListenable: preferredContact,
                                builder: (context, fav, _) {
                                  final bool isFav = fav != null && fav['telefono'] == (contacto['telefono'] ?? '');
                                  return IconButton(
                                    icon: Icon(isFav ? Icons.star : Icons.star_border),
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
                                child: const Text('Editar', style: TextStyle(color: Colors.red)),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline),
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

            const SizedBox(height: 18),

            const Padding(
              padding: EdgeInsets.only(bottom: 8.0),
              child: Text('Seguridad y Privacidad', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            ),
            
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: <Widget>[
                  ListTile(
                    leading: const CircleAvatar(backgroundColor: Colors.white, child: Icon(Icons.lock, color: Colors.black54)),
                    title: const Text('Cambiar PIN', style: TextStyle(fontWeight: FontWeight.w600)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {},
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const CircleAvatar(backgroundColor: Colors.white, child: Icon(Icons.shield, color: Colors.black54)),
                    title: const Text('Privacidad', style: TextStyle(fontWeight: FontWeight.w600)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {},
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


