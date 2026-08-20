import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class SymptomsPage extends StatefulWidget {
  const SymptomsPage({super.key});

  @override
  State<SymptomsPage> createState() => _SymptomsPageState();
}

class _SymptomsPageState extends State<SymptomsPage> {
  
  final TextEditingController _symptomsCtrl = TextEditingController();
  

  List<Map<String, dynamic>> _entries = [];
  int _nextId = 1;

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  Future<void> _loadEntries() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? raw = prefs.getString('symptoms');
      final int? next = prefs.getInt('symptomsNextId');
      if (raw != null) {
        final List<dynamic> list = jsonDecode(raw);
        setState(() {
          _entries = list.map((e) => Map<String, dynamic>.from(e)).toList();
          if (next != null) _nextId = next;
        });
      } else {
        if (next != null) _nextId = next;
      }
    } catch (e) {
      debugPrint('Error loading symptoms: $e');
    }
  }

  Future<void> _saveEntries() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('symptoms', jsonEncode(_entries));
      await prefs.setInt('symptomsNextId', _nextId);
    } catch (e) {
      debugPrint('Error saving symptoms: $e');
    }
  }

  // removed unused _pickDate

  void _deleteEntry(int index) async {
    setState(() => _entries.removeAt(index));
    await _saveEntries();
  }

  @override
  void dispose() {
    _symptomsCtrl.dispose();
    super.dispose();
  }

  Color _severityColor(int severity) {
    final t = ((severity - 1) / 9).clamp(0.0, 1.0);
    return Color.lerp(Colors.green, Colors.red, t) ?? Colors.orange;
  }

  String _formatDate(DateTime d) {
    final day = d.day.toString().padLeft(2, '0');
    final month = d.month.toString().padLeft(2, '0');
    final year = d.year;
    return '$day/$month/$year';
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double titleFontSize = (screenWidth * 0.06).clamp(22.0, 28.0);
    final double headingFontSize = (screenWidth * 0.05).clamp(18.0, 22.0);
    final double textFontSize = (screenWidth * 0.04).clamp(14.0, 18.0);
    final double labelFontSize = (screenWidth * 0.035).clamp(13.0, 15.0);
    
    // Paleta de colores pastel amigable para adultos mayores
    const Color rosaCoral = Color(0xFFF08080);        // Rosa coral suave
    const Color celesteSuave = Color(0xFFB3E5E0);     // Azul celeste suave
    const Color verdeClaro = Color(0xFF7FD8A8);       // Verde claro amigable
    const Color naranjaCalido = Color(0xFFFFB366);    // Naranja durazno cálido
    const Color fondoPrincipal = Color(0xFFF5FFFE);   // Fondo celeste muy claro
    const Color textoOscuro = Color(0xFF556B7F);      // Gris azulado oscuro (mejor contraste)
    
    return Scaffold(
      backgroundColor: fondoPrincipal,
      appBar: AppBar(
        title: Text('Registro de Síntomas', style: TextStyle(fontSize: titleFontSize, fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: rosaCoral,
        elevation: 2,
        centerTitle: false,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [rosaCoral, naranjaCalido.withAlpha((0.7 * 255).round())],
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
        child: Column(
          children: [
            // Header mejorado con colores amigables
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [celesteSuave.withAlpha((0.4 * 255).round()), Colors.white],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: celesteSuave.withAlpha((0.4 * 255).round()), width: 2),
              ),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [rosaCoral, naranjaCalido],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: rosaCoral.withAlpha((0.4 * 255).round()), blurRadius: 10, offset: const Offset(0, 4))],
                    ),
                    child: Icon(Icons.medical_services, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Diario de Síntomas', style: TextStyle(fontWeight: FontWeight.bold, fontSize: headingFontSize, color: textoOscuro)),
                        Text('Registra cómo te sientes', style: TextStyle(fontSize: labelFontSize, color: textoOscuro.withAlpha((0.7 * 255).round()))),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _showAddDialog(),
                    icon: const Icon(Icons.add, size: 20),
                    label: Text('Agregar', style: TextStyle(fontSize: labelFontSize, fontWeight: FontWeight.w600)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: rosaCoral,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _entries.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: (screenWidth * 0.25).clamp(80.0, 120.0),
                            height: (screenWidth * 0.25).clamp(80.0, 120.0),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [celesteSuave.withAlpha((0.4 * 255).round()), naranjaCalido.withAlpha((0.2 * 255).round())],
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.sentiment_satisfied_outlined, size: (screenWidth * 0.18).clamp(70.0, 90.0), color: naranjaCalido.withAlpha((0.7 * 255).round())),
                          ),
                          const SizedBox(height: 20),
                          Text('No hay entradas todavía', style: TextStyle(fontSize: headingFontSize, color: textoOscuro, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 12),
                          Text('Comienza registrando cómo te sientes hoy', style: TextStyle(fontSize: textFontSize, color: textoOscuro.withAlpha((0.6 * 255).round()))),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _entries.length,
                      itemBuilder: (ctx, i) {
                        final e = _entries[i];
                        final dt = DateTime.parse(e['date'] as String);
                        final severity = e['severity'] as int;
                        return Card(
                          margin: const EdgeInsets.only(bottom: 14),
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          color: Colors.white,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: _severityColor(severity).withAlpha((0.3 * 255).round()),
                                width: 2,
                              ),
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  _severityColor(severity).withAlpha((0.08 * 255).round()),
                                  Colors.white,
                                ],
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text('Fecha', style: TextStyle(fontSize: labelFontSize, color: textoOscuro.withAlpha((0.7 * 255).round()), fontWeight: FontWeight.w700)),
                                            const SizedBox(height: 6),
                                            Text(_formatDate(dt), style: TextStyle(fontSize: textFontSize, fontWeight: FontWeight.w600, color: textoOscuro)),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                        decoration: BoxDecoration(
                                          color: _severityColor(severity).withAlpha((0.2 * 255).round()),
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(color: _severityColor(severity).withAlpha((0.4 * 255).round()), width: 2),
                                        ),
                                        child: Text('Sev ${severity}/10', style: TextStyle(color: _severityColor(severity), fontWeight: FontWeight.w700, fontSize: labelFontSize)),
                                      )
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Text('Síntomas', style: TextStyle(fontSize: labelFontSize, color: textoOscuro.withAlpha((0.7 * 255).round()), fontWeight: FontWeight.w700)),
                                  const SizedBox(height: 8),
                                  Text(e['symptoms'] as String, style: TextStyle(fontSize: textFontSize, color: textoOscuro, height: 1.5, fontWeight: FontWeight.w500)),
                                  const SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Container(
                                        decoration: BoxDecoration(
                                          color: verdeClaro,
                                          borderRadius: BorderRadius.circular(10),
                                          boxShadow: [BoxShadow(color: verdeClaro.withAlpha((0.4 * 255).round()), blurRadius: 6, offset: const Offset(0, 2))],
                                        ),
                                        child: IconButton(
                                          icon: Icon(Icons.edit, size: 22, color: Colors.white),
                                          onPressed: () => _showEditDialog(i),
                                          tooltip: 'Editar',
                                          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                                          padding: const EdgeInsets.all(12),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Container(
                                        decoration: BoxDecoration(
                                          color: rosaCoral,
                                          borderRadius: BorderRadius.circular(10),
                                          boxShadow: [BoxShadow(color: rosaCoral.withAlpha((0.4 * 255).round()), blurRadius: 6, offset: const Offset(0, 2))],
                                        ),
                                        child: IconButton(
                                          icon: Icon(Icons.delete_outline, size: 22, color: Colors.white),
                                          onPressed: () => _deleteEntry(i),
                                          tooltip: 'Eliminar',
                                          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                                          padding: const EdgeInsets.all(12),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _insertEntry(DateTime date, String text, int severity) async {
    final entry = {
      'id': _nextId++,
      'date': date.toIso8601String(),
      'symptoms': text,
      'severity': severity,
    };
    setState(() {
      _entries.insert(0, entry);
    });
    await _saveEntries();
  }
  // Show dialog to add a new entry
  Future<void> _showAddDialog() async {
    const Color rosaCoral = Color(0xFFF08080);
    const Color celesteSuave = Color(0xFFB3E5E0);
    const Color textoOscuro = Color(0xFF556B7F);
    const Color fondoDialog = Color(0xFFF5FFFE);
    
    await showDialog<void>(
      context: context,
      builder: (ctx) {
        final TextEditingController txt = TextEditingController();
        DateTime chosen = DateTime.now();
        double sev = 5.0;
        
        return StatefulBuilder(builder: (ctx2, setState2) {
          final double dialogScreenWidth = MediaQuery.of(context).size.width;
          final double dialogTitleSize = (dialogScreenWidth * 0.055).clamp(19.0, 24.0);
          final double dialogTextSize = (dialogScreenWidth * 0.04).clamp(14.0, 16.0);
          
          return AlertDialog(
            backgroundColor: fondoDialog,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            title: Text('Nueva entrada', style: TextStyle(fontSize: dialogTitleSize, fontWeight: FontWeight.bold, color: textoOscuro)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: celesteSuave.withAlpha((0.15 * 255).round()),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: celesteSuave.withAlpha((0.3 * 255).round()), width: 2),
                    ),
                    child: Row(children: [
                      Expanded(child: Text('Fecha: ${_formatDate(chosen)}', style: TextStyle(fontSize: dialogTextSize, color: textoOscuro, fontWeight: FontWeight.w600))),
                      TextButton(
                        onPressed: () async {
                          final DateTime? picked = await showDatePicker(context: ctx2, initialDate: chosen, firstDate: DateTime(1900), lastDate: DateTime.now().add(const Duration(days: 365)));
                          if (picked != null) setState2(() { chosen = picked; });
                        },
                        child: Text('Cambiar', style: TextStyle(fontSize: dialogTextSize * 0.9, color: rosaCoral, fontWeight: FontWeight.w600))
                      )
                    ]),
                  ),
                  const SizedBox(height: 18),
                  Text('Describe los síntomas', style: TextStyle(fontSize: dialogTextSize * 0.95, color: textoOscuro, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 10),
                  TextField(
                    controller: txt,
                    maxLines: 4,
                    style: TextStyle(fontSize: dialogTextSize, color: textoOscuro, fontWeight: FontWeight.w500),
                    decoration: InputDecoration(
                      hintText: 'Ej: Dolor de cabeza, fiebre...',
                      hintStyle: TextStyle(fontSize: dialogTextSize, color: textoOscuro.withAlpha((0.5 * 255).round())),
                      filled: true,
                      fillColor: celesteSuave.withAlpha((0.08 * 255).round()),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: celesteSuave.withAlpha((0.3 * 255).round()), width: 2),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: celesteSuave.withAlpha((0.3 * 255).round()), width: 2),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: rosaCoral, width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text('Severidad: ${sev.round()}/10', style: TextStyle(fontSize: dialogTextSize * 0.95, color: textoOscuro, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: celesteSuave.withAlpha((0.15 * 255).round()),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Slider(
                      value: sev,
                      min: 1,
                      max: 10,
                      divisions: 9,
                      activeColor: _severityColor(sev.round()),
                      inactiveColor: celesteSuave.withAlpha((0.3 * 255).round()),
                      label: sev.round().toString(),
                      onChanged: (v) => setState2(() { sev = v; }),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () { if (mounted) Navigator.of(ctx).pop(); },
                child: Text('Cancelar', style: TextStyle(fontSize: dialogTextSize, color: textoOscuro.withAlpha((0.7 * 255).round()), fontWeight: FontWeight.w600))
              ),
              ElevatedButton(
                onPressed: () async {
                  final text = txt.text.trim();
                  if (text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Describe los síntomas antes de guardar.', style: TextStyle(fontSize: dialogTextSize))));
                    return;
                  }
                  final navigator = Navigator.of(ctx);
                  await _insertEntry(chosen, text, sev.round());
                  navigator.pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: rosaCoral,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text('Guardar', style: TextStyle(fontSize: dialogTextSize, fontWeight: FontWeight.w700))
              )
            ],
          );
        });
      }
    );
  }

  // Show dialog to edit an existing entry at index i
  Future<void> _showEditDialog(int i) async {
    const Color rosaCoral = Color(0xFFF08080);
    const Color celesteSuave = Color(0xFFB3E5E0);
    const Color textoOscuro = Color(0xFF556B7F);
    const Color fondoDialog = Color(0xFFF5FFFE);
    
    final Map<String, dynamic> entry = Map<String, dynamic>.from(_entries[i]);

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        DateTime chosen = DateTime.parse(entry['date'] as String);
        final TextEditingController txt = TextEditingController(text: entry['symptoms'] as String);
        double sev = (entry['severity'] as int).toDouble();

        return StatefulBuilder(builder: (ctx2, setState2) {
          final double dialogScreenWidth = MediaQuery.of(context).size.width;
          final double dialogTitleSize = (dialogScreenWidth * 0.055).clamp(19.0, 24.0);
          final double dialogTextSize = (dialogScreenWidth * 0.04).clamp(14.0, 16.0);
          
          return AlertDialog(
            backgroundColor: fondoDialog,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            title: Text('Editar entrada', style: TextStyle(fontSize: dialogTitleSize, fontWeight: FontWeight.bold, color: textoOscuro)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: celesteSuave.withAlpha((0.15 * 255).round()),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: celesteSuave.withAlpha((0.3 * 255).round()), width: 2),
                    ),
                    child: Row(children: [
                      Expanded(child: Text('Fecha: ${_formatDate(chosen)}', style: TextStyle(fontSize: dialogTextSize, color: textoOscuro, fontWeight: FontWeight.w600))),
                      TextButton(
                        onPressed: () async {
                          final DateTime? picked = await showDatePicker(context: ctx2, initialDate: chosen, firstDate: DateTime(1900), lastDate: DateTime.now().add(const Duration(days: 365)));
                          if (picked != null) setState2(() { chosen = picked; });
                        },
                        child: Text('Cambiar', style: TextStyle(fontSize: dialogTextSize * 0.9, color: rosaCoral, fontWeight: FontWeight.w600))
                      )
                    ]),
                  ),
                  const SizedBox(height: 18),
                  Text('Describe los síntomas', style: TextStyle(fontSize: dialogTextSize * 0.95, color: textoOscuro, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 10),
                  TextField(
                    controller: txt,
                    maxLines: 4,
                    style: TextStyle(fontSize: dialogTextSize, color: textoOscuro, fontWeight: FontWeight.w500),
                    decoration: InputDecoration(
                      hintText: 'Ej: Dolor de cabeza, fiebre...',
                      hintStyle: TextStyle(fontSize: dialogTextSize, color: textoOscuro.withAlpha((0.5 * 255).round())),
                      filled: true,
                      fillColor: celesteSuave.withAlpha((0.08 * 255).round()),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: celesteSuave.withAlpha((0.3 * 255).round()), width: 2),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: celesteSuave.withAlpha((0.3 * 255).round()), width: 2),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: rosaCoral, width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text('Severidad: ${sev.round()}/10', style: TextStyle(fontSize: dialogTextSize * 0.95, color: textoOscuro, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: celesteSuave.withAlpha((0.15 * 255).round()),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Slider(
                      value: sev,
                      min: 1,
                      max: 10,
                      divisions: 9,
                      activeColor: _severityColor(sev.round()),
                      inactiveColor: celesteSuave.withAlpha((0.3 * 255).round()),
                      label: sev.round().toString(),
                      onChanged: (v) => setState2(() { sev = v; }),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () { if (mounted) Navigator.of(ctx).pop(); },
                child: Text('Cancelar', style: TextStyle(fontSize: dialogTextSize, color: textoOscuro.withAlpha((0.7 * 255).round()), fontWeight: FontWeight.w600))
              ),
              ElevatedButton(
                onPressed: () async {
                  final text = txt.text.trim();
                  if (text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Describe los síntomas antes de guardar.', style: TextStyle(fontSize: dialogTextSize))));
                    return;
                  }
                  setState(() {
                    _entries[i] = {
                      'id': entry['id'],
                      'date': chosen.toIso8601String(),
                      'symptoms': text,
                      'severity': sev.round(),
                    };
                  });
                  final navigator = Navigator.of(ctx);
                  await _saveEntries();
                  navigator.pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: rosaCoral,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text('Guardar', style: TextStyle(fontSize: dialogTextSize, fontWeight: FontWeight.w700))
              )
            ],
          );
        });
      }
    );
  }
}
