import 'package:flutter/material.dart';

class SenttingsPage extends StatelessWidget {
  const SenttingsPage({super.key});

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
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        child: ListView(
          children: <Widget>[
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                leading: const Icon(Icons.person),
                title: const Text('Perfil personal'),
                subtitle: const Text('Editar información médica'),
                trailing: TextButton(onPressed: () {}, child: const Text('Editar')),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Column(
                children: <Widget>[
                  SwitchListTile(
                    title: const Text('Notificaciones'),
                    value: true,
                    onChanged: (v) {},
                  ),
                  SwitchListTile(
                    title: const Text('Ubicación'),
                    value: true,
                    onChanged: (v) {},
                  ),
                  SwitchListTile(
                    title: const Text('Llamada automática'),
                    value: false,
                    onChanged: (v) {},
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Column(
                children: <Widget>[
                  ListTile(
                    leading: const Icon(Icons.phone),
                    title: const Text('Contacto 1'),
                    subtitle: const Text('+1 234 567 890'),
                    trailing: Row(mainAxisSize: MainAxisSize.min, children: <Widget>[
                      TextButton(onPressed: () {}, child: const Text('Editar')),
                      IconButton(onPressed: () {}, icon: const Icon(Icons.delete_forever)),
                    ]),
                  ),
                  ListTile(
                    leading: const Icon(Icons.phone),
                    title: const Text('Contacto 2'),
                    subtitle: const Text('+1 234 567 891'),
                    trailing: TextButton(onPressed: () {}, child: const Text('Editar')),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: OutlinedButton(onPressed: () {}, child: const Text('+ Agregar contacto')),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Column(
                children: <Widget>[
                  ListTile(
                    leading: const Icon(Icons.lock),
                    title: const Text('Cambiar PIN'),
                    onTap: () {},
                  ),
                  ListTile(
                    leading: const Icon(Icons.shield),
                    title: const Text('Privacidad'),
                    onTap: () {},
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: const Icon(Icons.phone_android),
                title: const Text('Versión de la app'),
                subtitle: const Text('1.0.0'),
              ),
            ),
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }
}
