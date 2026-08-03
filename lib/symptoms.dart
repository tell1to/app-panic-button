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
    final double titleFontSize = (screenWidth * 0.05).clamp(18.0, 24.0);
    final double headingFontSize = (screenWidth * 0.04).clamp(14.0, 18.0);
    final double textFontSize = (screenWidth * 0.035).clamp(12.0, 16.0);
    final double labelFontSize = (screenWidth * 0.032).clamp(11.0, 13.0);
    
    // Colores pastel: Rosado y Celeste
    const Color pastelRosado = Color(0xFF3B82F6);
    const Color pastelCeleste = Color(0xFF60A5FA);
    const Color textoOscuro = Color(0xFF1F2937);
    
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        title: Text('Registro de Síntomas', style: TextStyle(fontSize: titleFontSize, fontWeight: FontWeight.w700, color: textoOscuro)),
        backgroundColor: pastelRosado,
        elevation: 2,
        centerTitle: false,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [pastelRosado, pastelCeleste.withAlpha((0.5 * 255).round())],
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
        child: Column(
          children: [
            // Header mejorado con colores pastel Rosado y Celeste
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [pastelCeleste.withAlpha((0.3 * 255).round()), Colors.white],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: pastelRosado.withAlpha((0.3 * 255).round()), width: 1.5),
              ),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [pastelRosado, pastelCeleste],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: pastelRosado.withAlpha((0.3 * 255).round()), blurRadius: 8, offset: const Offset(0, 4))],
                    ),
                    child: Icon(Icons.medical_services, color: Colors.white, size: 26),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Diario de Síntomas', style: TextStyle(fontWeight: FontWeight.bold, fontSize: headingFontSize, color: textoOscuro)),
                        Text('Registra cómo te sientes', style: TextStyle(fontSize: labelFontSize * 0.9, color: textoOscuro.withAlpha((0.6 * 255).round()))),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _showAddDialog(),
                    icon: const Icon(Icons.add, size: 18),
                    label: Text('Agregar', style: TextStyle(fontSize: labelFontSize)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: pastelRosado,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      elevation: 0,
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
                            width: (screenWidth * 0.2).clamp(60.0, 100.0),
                            height: (screenWidth * 0.2).clamp(60.0, 100.0),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [pastelRosado.withAlpha((0.3 * 255).round()), pastelCeleste.withAlpha((0.2 * 255).round())],
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.sentiment_satisfied_outlined, size: (screenWidth * 0.15).clamp(60.0, 80.0), color: textoOscuro.withAlpha((0.3 * 255).round())),
                          ),
                          const SizedBox(height: 16),
                          Text('No hay entradas todavía', style: TextStyle(fontSize: textFontSize, color: textoOscuro.withAlpha((0.6 * 255).round()), fontWeight: FontWeight.w500)),
                          const SizedBox(height: 8),
                          Text('Comienza registrando cómo te sientes hoy', style: TextStyle(fontSize: labelFontSize, color: textoOscuro.withAlpha((0.4 * 255).round()))),
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
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          color: Colors.white,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: _severityColor(severity).withAlpha((0.2 * 255).round()),
                                width: 1.5,
                              ),
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  _severityColor(severity).withAlpha((0.05 * 255).round()),
                                  Colors.white,
                                ],
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
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
                                            Text('Fecha', style: TextStyle(fontSize: labelFontSize, color: textoOscuro.withAlpha((0.6 * 255).round()), fontWeight: FontWeight.w600)),
                                            const SizedBox(height: 4),
                                            Text(_formatDate(dt), style: TextStyle(fontSize: textFontSize, fontWeight: FontWeight.w600, color: textoOscuro)),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: _severityColor(severity).withAlpha((0.15 * 255).round()),
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(color: _severityColor(severity).withAlpha((0.3 * 255).round()), width: 1),
                                        ),
                                        child: Text('Sev $severity', style: TextStyle(color: _severityColor(severity), fontWeight: FontWeight.w700, fontSize: labelFontSize)),
                                      )
                                    ],
                                  ),
                                  const SizedBox(height: 14),
                                  Text('Síntomas', style: TextStyle(fontSize: labelFontSize, color: textoOscuro.withAlpha((0.6 * 255).round()), fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 6),
                                  Text(e['symptoms'] as String, style: TextStyle(fontSize: textFontSize, color: textoOscuro.withAlpha((0.8 * 255).round()), height: 1.4)),
                                  const SizedBox(height: 14),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Container(
                                        decoration: BoxDecoration(
                                          color: pastelCeleste.withAlpha((0.2 * 255).round()),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: IconButton(
                                          icon: Icon(Icons.edit, size: 18, color: pastelCeleste.withAlpha((0.8 * 255).round())),
                                          onPressed: () => _showEditDialog(i),
                                          tooltip: 'Editar',
                                          constraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                                          padding: const EdgeInsets.all(8),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        decoration: BoxDecoration(
                                          color: pastelRosado.withAlpha((0.2 * 255).round()),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: IconButton(
                                          icon: Icon(Icons.delete_outline, size: 18, color: pastelRosado.withAlpha((0.8 * 255).round())),
                                          onPressed: () => _deleteEntry(i),
                                          tooltip: 'Eliminar',
                                          constraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                                          padding: const EdgeInsets.all(8),
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
    const Color pastelRosado = Color(0xFFFFB3D9);
    const Color pastelCeleste = Color(0xFFADD8E6);
    const Color textoOscuro = Color(0xFF5A5A7F);
    
    await showDialog<void>(
      context: context,
      builder: (ctx) {
        final TextEditingController txt = TextEditingController();
        DateTime chosen = DateTime.now();
        double sev = 5.0;
        
        return StatefulBuilder(builder: (ctx2, setState2) {
          final double dialogScreenWidth = MediaQuery.of(context).size.width;
          final double dialogTitleSize = (dialogScreenWidth * 0.045).clamp(16.0, 20.0);
          final double dialogTextSize = (dialogScreenWidth * 0.035).clamp(12.0, 14.0);
          
          return AlertDialog(
            backgroundColor: const Color(0xFFFAF8F6),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text('Nueva entrada', style: TextStyle(fontSize: dialogTitleSize, fontWeight: FontWeight.bold, color: textoOscuro)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: pastelCeleste.withAlpha((0.1 * 255).round()),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: pastelRosado.withAlpha((0.2 * 255).round())),
                    ),
                    child: Row(children: [
                      Expanded(child: Text('Fecha: ${_formatDate(chosen)}', style: TextStyle(fontSize: dialogTextSize, color: textoOscuro, fontWeight: FontWeight.w500))),
                      TextButton(
                        onPressed: () async {
                          final DateTime? picked = await showDatePicker(context: ctx2, initialDate: chosen, firstDate: DateTime(1900), lastDate: DateTime.now().add(const Duration(days: 365)));
                          if (picked != null) setState2(() { chosen = picked; });
                        },
                        child: Text('Cambiar', style: TextStyle(fontSize: dialogTextSize, color: pastelRosado))
                      )
                    ]),
                  ),
                  const SizedBox(height: 16),
                  Text('Describe los síntomas', style: TextStyle(fontSize: dialogTextSize * 0.9, color: textoOscuro, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: txt,
                    maxLines: 4,
                    style: TextStyle(fontSize: dialogTextSize, color: textoOscuro),
                    decoration: InputDecoration(
                      hintText: 'Ej: Dolor de cabeza, fiebre...',
                      hintStyle: TextStyle(fontSize: dialogTextSize, color: textoOscuro.withAlpha((0.4 * 255).round())),
                      filled: true,
                      fillColor: pastelCeleste.withAlpha((0.05 * 255).round()),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: pastelRosado.withAlpha((0.2 * 255).round())),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: pastelRosado.withAlpha((0.2 * 255).round())),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: pastelRosado, width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Severidad: ${sev.round()}/10', style: TextStyle(fontSize: dialogTextSize * 0.9, color: textoOscuro, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: pastelCeleste.withAlpha((0.1 * 255).round()),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Slider(
                      value: sev,
                      min: 1,
                      max: 10,
                      divisions: 9,
                      activeColor: _severityColor(sev.round()),
                      inactiveColor: pastelCeleste.withAlpha((0.3 * 255).round()),
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
                child: Text('Cancelar', style: TextStyle(fontSize: dialogTextSize, color: textoOscuro.withAlpha((0.6 * 255).round())))
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
                  backgroundColor: pastelRosado,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text('Guardar', style: TextStyle(fontSize: dialogTextSize, fontWeight: FontWeight.w600))
              )
            ],
          );
        });
      }
    );
  }

  // Show dialog to edit an existing entry at index i
  Future<void> _showEditDialog(int i) async {
    const Color pastelRosado = Color(0xFFFFB3D9);
    const Color pastelCeleste = Color(0xFFADD8E6);
    const Color textoOscuro = Color(0xFF5A5A7F);
    
    final Map<String, dynamic> entry = Map<String, dynamic>.from(_entries[i]);

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        DateTime chosen = DateTime.parse(entry['date'] as String);
        final TextEditingController txt = TextEditingController(text: entry['symptoms'] as String);
        double sev = (entry['severity'] as int).toDouble();

        return StatefulBuilder(builder: (ctx2, setState2) {
          final double dialogScreenWidth = MediaQuery.of(context).size.width;
          final double dialogTitleSize = (dialogScreenWidth * 0.045).clamp(16.0, 20.0);
          final double dialogTextSize = (dialogScreenWidth * 0.035).clamp(12.0, 14.0);
          
          return AlertDialog(
            backgroundColor: const Color(0xFFFAF8F6),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text('Editar entrada', style: TextStyle(fontSize: dialogTitleSize, fontWeight: FontWeight.bold, color: textoOscuro)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: pastelCeleste.withAlpha((0.1 * 255).round()),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: pastelRosado.withAlpha((0.2 * 255).round())),
                    ),
                    child: Row(children: [
                      Expanded(child: Text('Fecha: ${_formatDate(chosen)}', style: TextStyle(fontSize: dialogTextSize, color: textoOscuro, fontWeight: FontWeight.w500))),
                      TextButton(
                        onPressed: () async {
                          final DateTime? picked = await showDatePicker(context: ctx2, initialDate: chosen, firstDate: DateTime(1900), lastDate: DateTime.now().add(const Duration(days: 365)));
                          if (picked != null) setState2(() { chosen = picked; });
                        },
                        child: Text('Cambiar', style: TextStyle(fontSize: dialogTextSize, color: pastelRosado))
                      )
                    ]),
                  ),
                  const SizedBox(height: 16),
                  Text('Describe los síntomas', style: TextStyle(fontSize: dialogTextSize * 0.9, color: textoOscuro, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: txt,
                    maxLines: 4,
                    style: TextStyle(fontSize: dialogTextSize, color: textoOscuro),
                    decoration: InputDecoration(
                      hintText: 'Ej: Dolor de cabeza, fiebre...',
                      hintStyle: TextStyle(fontSize: dialogTextSize, color: textoOscuro.withAlpha((0.4 * 255).round())),
                      filled: true,
                      fillColor: pastelCeleste.withAlpha((0.05 * 255).round()),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: pastelRosado.withAlpha((0.2 * 255).round())),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: pastelRosado.withAlpha((0.2 * 255).round())),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: pastelRosado, width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Severidad: ${sev.round()}/10', style: TextStyle(fontSize: dialogTextSize * 0.9, color: textoOscuro, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: pastelCeleste.withAlpha((0.1 * 255).round()),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Slider(
                      value: sev,
                      min: 1,
                      max: 10,
                      divisions: 9,
                      activeColor: _severityColor(sev.round()),
                      inactiveColor: pastelCeleste.withAlpha((0.3 * 255).round()),
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
                child: Text('Cancelar', style: TextStyle(fontSize: dialogTextSize, color: textoOscuro.withAlpha((0.6 * 255).round())))
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
                  backgroundColor: pastelRosado,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text('Guardar', style: TextStyle(fontSize: dialogTextSize, fontWeight: FontWeight.w600))
              )
            ],
          );
        });
      }
    );
  }
}
