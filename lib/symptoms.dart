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
    final primary = Theme.of(context).colorScheme.primary;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registro de Síntomas'),
        backgroundColor: primary,
        elevation: 2,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black.withAlpha((0.03 * 255).round()), blurRadius: 6)],
              ),
              child: Row(
                children: [
                  CircleAvatar(backgroundColor: primary, child: const Icon(Icons.medical_services, color: Colors.white)),
                  const SizedBox(width: 12),
                  const Expanded(child: Text('Diario de Síntomas', style: TextStyle(fontWeight: FontWeight.bold))),
                  ElevatedButton.icon(
                    onPressed: () => _showAddDialog(),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Agregar'),
                    style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                  )
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _entries.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.sentiment_satisfied_outlined, size: 68, color: Colors.grey.shade300),
                          const SizedBox(height: 12),
                          const Text('No hay entradas todavía', style: TextStyle(color: Colors.black54)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _entries.length,
                      itemBuilder: (ctx, i) {
                        final e = _entries[i];
                        final dt = DateTime.parse(e['date'] as String);
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
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
                                          Text('Fecha', style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
                                          const SizedBox(height: 4),
                                          Text(_formatDate(dt), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(color: _severityColor(e['severity'] as int).withAlpha((0.12 * 255).round()), borderRadius: BorderRadius.circular(6)),
                                      child: Text('Sev ${e['severity']}', style: TextStyle(color: _severityColor(e['severity'] as int), fontWeight: FontWeight.w700, fontSize: 12)),
                                    )
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text('Síntomas', style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
                                const SizedBox(height: 4),
                                Text(e['symptoms'] as String, style: const TextStyle(fontSize: 14)),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit, size: 20),
                                      onPressed: () => _showEditDialog(i),
                                      tooltip: 'Editar',
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                                      onPressed: () => _deleteEntry(i),
                                      tooltip: 'Eliminar',
                                    ),
                                  ],
                                ),
                              ],
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
    await showDialog<void>(
      context: context,
      builder: (ctx) {
        final TextEditingController txt = TextEditingController();
        DateTime chosen = DateTime.now();
        double sev = 5.0;
        
        return StatefulBuilder(builder: (ctx2, setState2) {
          return AlertDialog(
            title: const Text('Nueva entrada'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(child: Text('Fecha: ${_formatDate(chosen)}')),
                    TextButton(
                      onPressed: () async {
                        final DateTime? picked = await showDatePicker(context: ctx2, initialDate: chosen, firstDate: DateTime(1900), lastDate: DateTime.now().add(const Duration(days: 365)));
                        if (picked != null) setState2(() { chosen = picked; });
                      },
                      child: const Text('Cambiar')
                    )
                  ]),
                  const SizedBox(height: 8),
                  TextField(controller: txt, maxLines: 4, decoration: InputDecoration(hintText: 'Describe los síntomas...', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)))),
                  const SizedBox(height: 12),
                  const Text('Severidad'),
                  Slider(value: sev, min: 1, max: 10, divisions: 9, activeColor: _severityColor(sev.round()), label: sev.round().toString(), onChanged: (v) => setState2(() { sev = v; })),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () { if (mounted) Navigator.of(ctx).pop(); },
                child: const Text('Cancelar')
              ),
              ElevatedButton(
                onPressed: () async {
                  final text = txt.text.trim();
                  if (text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Describe los síntomas antes de guardar.')));
                    return;
                  }
                  final navigator = Navigator.of(ctx);
                  await _insertEntry(chosen, text, sev.round());
                  navigator.pop();
                },
                child: const Text('Guardar')
              )
            ],
          );
        });
      }
    );
  }

  // Show dialog to edit an existing entry at index i
  Future<void> _showEditDialog(int i) async {
    final Map<String, dynamic> entry = Map<String, dynamic>.from(_entries[i]);

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        DateTime chosen = DateTime.parse(entry['date'] as String);
        final TextEditingController txt = TextEditingController(text: entry['symptoms'] as String);
        double sev = (entry['severity'] as int).toDouble();

        return StatefulBuilder(builder: (ctx2, setState2) {
          return AlertDialog(
            title: const Text('Editar entrada'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(child: Text('Fecha: ${_formatDate(chosen)}')),
                    TextButton(
                      onPressed: () async {
                        final DateTime? picked = await showDatePicker(context: ctx2, initialDate: chosen, firstDate: DateTime(1900), lastDate: DateTime.now().add(const Duration(days: 365)));
                        if (picked != null) setState2(() { chosen = picked; });
                      },
                      child: const Text('Cambiar')
                    )
                  ]),
                  const SizedBox(height: 8),
                  TextField(controller: txt, maxLines: 4, decoration: InputDecoration(hintText: 'Describe los síntomas...', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)))),
                  const SizedBox(height: 12),
                  const Text('Severidad'),
                  Slider(value: sev, min: 1, max: 10, divisions: 9, activeColor: _severityColor(sev.round()), label: sev.round().toString(), onChanged: (v) => setState2(() { sev = v; })),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () { if (mounted) Navigator.of(ctx).pop(); },
                child: const Text('Cancelar')
              ),
              ElevatedButton(
                onPressed: () async {
                  final text = txt.text.trim();
                  if (text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Describe los síntomas antes de guardar.')));
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
                child: const Text('Guardar')
              )
            ],
          );
        });
      }
    );
  }
}
