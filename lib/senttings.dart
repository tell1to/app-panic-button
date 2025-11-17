import 'package:flutter/material.dart';

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
  List<Map<String, String>> _contactos = [
    {'nombre': 'Contacto 1', 'telefono': '+1 234 567 890'},
    {'nombre': 'Contacto 2', 'telefono': '+1 234 567 891'},
  ];

  // Función para mostrar cuadro de diálogo para agregar/editar contacto
  void _showContactoDialog({int? index}) {
    String initialNombre = index != null ? _contactos[index]['nombre'] ?? '' : '';
    String initialTelefono = index != null ? _contactos[index]['telefono'] ?? '' : '';

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
              onPressed: () {
                setState(() {
                  if (index == null) {
                    _contactos.add({'nombre': nombreController.text, 'telefono': telefonoController.text});
                  } else {
                    _contactos[index] = {'nombre': nombreController.text, 'telefono': telefonoController.text};
                  }
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // Función para mostrar cuadro de diálogo de confirmación de borrado
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
            onPressed: () {
              setState(() {
                _contactos.removeAt(index);
              });
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  // --- Resto: Perfil, Alertas y Notificaciones ---
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
                    }).toList(),
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
                    setState(() {
                      _nombres = nombresController.text;
                      _apellidos = apellidosController.text;
                      _edad = edadController.text;
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


