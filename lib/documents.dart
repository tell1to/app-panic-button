import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_selector/file_selector.dart';
import 'package:path_provider/path_provider.dart';

class DocumentsPage extends StatefulWidget {
  const DocumentsPage({super.key});

  @override
  State<DocumentsPage> createState() => _DocumentsPageState();
}

class _DocumentsPageState extends State<DocumentsPage> {
  List<Map<String, dynamic>> _docs = [];
  int _nextId = 1;

  @override
  void initState() {
    super.initState();
    _loadDocs();
  }

  Future<void> _loadDocs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('documents');
      final next = prefs.getInt('documentsNextId');
      if (raw != null) {
        final List<dynamic> list = jsonDecode(raw);
        setState(() {
          _docs = list.map((e) => Map<String, dynamic>.from(e)).toList();
          if (next != null) _nextId = next;
        });
      } else {
        if (next != null) _nextId = next;
      }
    } catch (e) {
      debugPrint('Error loading documents: $e');
    }
  }

  Future<void> _saveDocs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('documents', jsonEncode(_docs));
      await prefs.setInt('documentsNextId', _nextId);
    } catch (e) {
      debugPrint('Error saving documents: $e');
    }
  }

  Future<void> _pickAndSave() async {
    try {
      final XFile? picked = await openFile();
      if (picked == null) return;
      final String fileName = picked.name;
      final bytes = await picked.readAsBytes();

      final appDir = await getApplicationDocumentsDirectory();
      final targetDir = Directory('${appDir.path}/documents');
      if (!await targetDir.exists()) await targetDir.create(recursive: true);

      final targetPath = '${targetDir.path}/${DateTime.now().millisecondsSinceEpoch}_$fileName';
      final f = File(targetPath);
      await f.writeAsBytes(bytes);
      final stat = await f.length();

      setState(() {
        _docs.insert(0, {
          'id': _nextId++,
          'name': fileName,
          'path': targetPath,
          'size': stat,
          'created': DateTime.now().toIso8601String(),
        });
      });

      await _saveDocs();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Documento subido correctamente')));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al subir el documento')));
      }
    }
  }

  Future<void> _deleteDoc(int index) async {
    try {
      final path = _docs[index]['path'] as String?;
      if (path != null) {
        final file = File(path);
        if (await file.exists()) await file.delete();
      }
    } catch (e) {
      debugPrint('Error deleting document: $e');
    }
    setState(() => _docs.removeAt(index));
    await _saveDocs();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Documentos Médicos'),
        automaticallyImplyLeading: false,
        actions: [IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(context).pop())],
      ),
      body: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          children: <Widget>[
            Text('Gestiona tus estudios y recetas médicas', style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color)),
            const SizedBox(height: 18),
            Expanded(
              child: Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 6,
                child: Padding(
                  padding: const EdgeInsets.all(18.0),
                  child: Column(
                    children: <Widget>[
                      // Upload area
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Theme.of(context).dividerColor),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 14),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Icon(Icons.description_outlined, size: 56, color: Theme.of(context).iconTheme.color),
                            const SizedBox(height: 12),
                            Text('Sube tus estudios y recetas aquí', style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color)),
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              onPressed: _pickAndSave,
                              icon: const Icon(Icons.upload_file),
                              label: const Text('Subir documento'),
                              style: ElevatedButton.styleFrom(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Align(alignment: Alignment.centerLeft, child: Text('Documentos guardados', style: TextStyle(fontWeight: FontWeight.w600))),
                      const SizedBox(height: 8),
                      // Document list
                      Expanded(
                        child: _docs.isEmpty
                            ? Center(child: Text('No hay documentos guardados', style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color)))
                            : ListView.separated(
                                itemCount: _docs.length,
                                separatorBuilder: (context, index) => const Divider(height: 16),
                                itemBuilder: (context, i) {
                                  final d = _docs[i];
                                  final created = d['created'] as String?;
                                  String dateStr = '';
                                  try {
                                    if (created != null) {
                                      final dt = DateTime.parse(created);
                                      dateStr = '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
                                    }
                                  } catch (e) {
                                    debugPrint('Error parsing document date: $e');
                                  }
                                  final sizeKb = ((d['size'] as int?) ?? 0) ~/ 1024;
                                  return ListTile(
                                    contentPadding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                                    leading: CircleAvatar(
                                      radius: 22,
                                      backgroundColor: Theme.of(context).colorScheme.primary.withAlpha((0.12 * 255).round()),
                                      child: Icon(Icons.insert_drive_file_outlined, color: Theme.of(context).colorScheme.primary),
                                    ),
                                    title: Text(d['name'] as String, style: const TextStyle(fontWeight: FontWeight.w600)),
                                    subtitle: Text(dateStr.isNotEmpty ? 'Fecha: $dateStr · Tamaño: $sizeKb KB' : 'Tamaño: $sizeKb KB', style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color)),
                                    trailing: IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => _deleteDoc(i)),
                                    onTap: () async {
                                      final path = d['path'] as String?;
                                      if (path != null) {
                                        try {
                                          await File(path).exists();
                                        } catch (e) {
                                          debugPrint('Error checking document file: $e');
                                        }
                                      }
                                    },
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.secondary,
                    foregroundColor: Theme.of(context).colorScheme.onSecondary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 18),
                  ),
                  child: const Text('Cerrar'),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
