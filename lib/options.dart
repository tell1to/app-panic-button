import 'package:flutter/material.dart';

class OptionsPage extends StatelessWidget {
  const OptionsPage({super.key});

  void _openDetail(BuildContext context, String title) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => DetailPage(title: title)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF5F6),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Opciones', style: TextStyle(color: Colors.black)),
        foregroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        child: ListView(
          children: <Widget>[
            const SizedBox(height: 8),
            _buildCard(context, 'Condición médica', 'Detalles de enfermedad'),
            _buildCard(context, 'Medicamentos', 'Lista de medicinas actuales'),
            _buildCard(context, 'Alergias', 'Alergias y reacciones'),
            const SizedBox(height: 12),
            const Text('Historial y Seguimiento', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _buildCard(context, 'Citas médicas', 'Próximas consultas'),
            _buildCard(context, 'Historial de alertas', 'Emergencias registradas'),
            _buildCard(context, 'Registro de síntomas', 'Diario de salud'),
            const SizedBox(height: 12),
            const Text('Documentos', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _buildCard(context, 'Documentos médicos', 'Estudios y recetas'),
            _buildCard(context, 'Información de seguro', 'Pólizas y cobertura'),
            const SizedBox(height: 20),
            Card(
              color: Colors.red.shade50,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: const <Widget>[
                    Icon(Icons.warning, color: Colors.red),
                    SizedBox(width: 12),
                    Expanded(child: Text('Información importante\nMantén tu información médica actualizada para que los servicios de emergencia puedan asistirte mejor.')),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context, String title, String subtitle) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _openDetail(context, title),
      ),
    );
  }
}

class DetailPage extends StatelessWidget {
  final String title;
  const DetailPage({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text('Detalle: $title')),
    );
  }
}
