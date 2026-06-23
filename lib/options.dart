import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import 'symptoms.dart';
import 'documents.dart';
import 'services/alert_service.dart';
import 'services/secure_storage_service.dart';
import 'services/appointment_reminder_service.dart';
import 'validators/validators.dart';

class OptionsPage extends StatefulWidget {
  const OptionsPage({super.key});

  @override
  State<OptionsPage> createState() => _OptionsPageState();
}

class _OptionsPageState extends State<OptionsPage> {
  String? _insuranceCompany;
  String? _policyNumber;
  String? _insurancePhone;
  
  // Listas para condiciones médicas, medicamentos, citas médicas y alergias
  List<Map<String, String>> _conditions = [];
  List<String> _medications = [];
  List<Map<String, dynamic>> _appointments = [];
  List<String> _allergies = [];
  
  // Historial de alertas
  final List<Map<String, dynamic>> _alerts = [];

  String? _userCI; // CI del usuario para generar IDs descriptivos
  int _nextAlertId = 1; // Contador secuencial para IDs de alertas (formato: CI_mod1, CI_mod2, etc)
  bool _storagePermissionRequested = false;

  Future<void> _requestStoragePermissionIfNeeded() async {
    if (_storagePermissionRequested) return;
    _storagePermissionRequested = true;

    try {
      print('[storage-permission] iniciando solicitud de permisos...');
      
      if (Platform.isAndroid) {
        print('[storage-permission] plataforma: Android');
        
        PermissionStatus status = PermissionStatus.denied;
        
        // Primero intentar Permission.photos (Android 13+)
        print('[storage-permission] intentando Permission.photos (Android 13+)...');
        status = await Permission.photos.request();
        print('[storage-permission] Permission.photos: $status');
        
        // Si no fue otorgado, intentar Permission.manageExternalStorage (Android 11+)
        if (!status.isGranted) {
          print('[storage-permission] intentando Permission.manageExternalStorage (Android 11+)...');
          status = await Permission.manageExternalStorage.request();
          print('[storage-permission] Permission.manageExternalStorage: $status');
        }
        
        // Si aún no fue otorgado, intentar Permission.storage (Android 10-)
        if (!status.isGranted) {
          print('[storage-permission] intentando Permission.storage (Android 10-)...');
          status = await Permission.storage.request();
          print('[storage-permission] Permission.storage: $status');
        }
        
        // Verificar estado actual de permisos en el sistema
        print('[storage-permission] verificando permisos actuales en el sistema...');
        final photosStatus = await Permission.photos.status;
        final manageStatus = await Permission.manageExternalStorage.status;
        final storageStatus = await Permission.storage.status;
        
        print('[storage-permission] Estado actual - photos: $photosStatus, manage: $manageStatus, storage: $storageStatus');
        
        // Mostrar resultado al usuario SOLO SI AL MENOS UNO ESTÁ OTORGADO
        if (mounted) {
          if (photosStatus.isGranted || manageStatus.isGranted || storageStatus.isGranted) {
            print('[storage-permission] ✓ al menos un permiso está activo en el sistema');
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✓ Permiso de almacenamiento activado'),
                duration: Duration(seconds: 2),
              ),
            );
          } else if (status.isDenied) {
            print('[storage-permission] ⚠️ permiso denegado');
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('⚠️ Permiso de almacenamiento denegado'),
                duration: Duration(seconds: 2),
              ),
            );
          } else if (status.isPermanentlyDenied) {
            print('[storage-permission] 🔒 permiso denegado permanentemente');
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('🔒 Permiso permanentemente denegado. Ve a Ajustes > Aplicaciones > Life Alert > Permisos > Todos los archivos'),
                duration: Duration(seconds: 3),
              ),
            );
            // Opcional: abrir ajustes automáticamente
            // await openAppSettings();
          }
        }
      } else {
        print('[storage-permission] plataforma no es Android');
      }
    } catch (e) {
      print('[storage-permission] ERROR: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error solicitando permisos: $e')),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _loadAlerts();
    _loadInsurance();
    _loadConditions();
    _loadMedications();
    _loadAppointments();
    _loadAllergies();
    
    // Cargar CI del usuario para generar IDs descriptivos
    _loadUserCI();
    
    // Inicializar AlertService desde storage (lee CI del usuario)
    AlertService.instance.initializeFromStorage();
    
    // Solicitar permisos de almacenamiento inmediatamente después de que el widget esté montado
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestStoragePermissionIfNeeded();
    });
  }

  // Método público para añadir una alerta (útil para que `main.dart` llame cuando se pulse el botón rojo)
  Future<void> addAlert({required DateTime datetime, String? location, required String description, String status = 'Alerta'}) async {
    print('[alerts] addAlert iniciado: datetime=$datetime description="$description" location="$location"');
    
    String finalLocation = location ?? '';
    double? finalLat;
    double? finalLon;
    
    // If no location provided, request permission and capture coordinates (best-effort)
    if (finalLocation.isEmpty) {
      try {
        print('[alerts] obteniendo ubicación...');
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          print('[alerts] servicio de ubicación deshabilitado');
          finalLocation = 'Servicio de ubicación deshabilitado';
        } else {
          LocationPermission permission = await Geolocator.checkPermission();
          if (permission == LocationPermission.denied) {
            permission = await Geolocator.requestPermission();
          }
          
          if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
            print('[alerts] permiso de ubicación denegado');
            finalLocation = 'Permiso de ubicación denegado';
          } else {
            try {
              // Obtener posición con timeout más corto (5 segundos)
              Position pos;
              try {
                pos = await Geolocator.getCurrentPosition(
                  desiredAccuracy: LocationAccuracy.medium,
                  timeLimit: const Duration(seconds: 5),
                );
              } catch (e) {
                print('[alerts] timeout en getCurrentPosition, intentando lastKnownPosition...');
                final lastPos = await Geolocator.getLastKnownPosition();
                if (lastPos != null) {
                  pos = lastPos;
                } else {
                  throw 'No se pudo obtener posición';
                }
              }
              
              finalLat = pos.latitude;
              finalLon = pos.longitude;
              print('[alerts] posición obtenida: lat=$finalLat, lon=$finalLon');
              
              // Obtener nombre de lugar con timeout corto también
              try {
                List<Placemark> placemarks = await placemarkFromCoordinates(
                  pos.latitude,
                  pos.longitude,
                ).timeout(const Duration(seconds: 3), onTimeout: () {
                  print('[alerts] timeout en geocoding, usando coordenadas...');
                  return [];
                });
                
                if (placemarks.isNotEmpty) {
                  Placemark place = placemarks[0];
                  final city = place.locality ?? place.subAdministrativeArea ?? 'Desconocida';
                  final country = place.country ?? '';
                  finalLocation = '$city, $country'.trim();
                  print('[alerts] ubicación traducida: $finalLocation');
                } else {
                  finalLocation = 'Lat:${pos.latitude.toStringAsFixed(5)}, Lon:${pos.longitude.toStringAsFixed(5)}';
                  print('[alerts] sin nombre de lugar, usando coordenadas');
                }
              } catch (e) {
                // Si falla la geocodificación, usar solo coordenadas
                finalLocation = 'Lat:${pos.latitude.toStringAsFixed(5)}, Lon:${pos.longitude.toStringAsFixed(5)}';
                print('[alerts] error en geocodificación: $e');
              }
            } catch (e) {
              print('[alerts] error obteniendo posición: $e');
              finalLocation = 'Ubicación no disponible';
            }
          }
        }
      } catch (e) {
        print('[alerts] error en obtención de ubicación: $e');
        finalLocation = 'Error: $e';
      }
    }

    print('[alerts] addAlert procesando: finalLocation="$finalLocation"');
    
    // Generar ID con formato: CI_modN (ej: 1756278550_mod1, 1756278550_mod2)
    // Si no hay CI, usar timestamp como fallback
    final String alertId;
    if (_userCI != null && _userCI!.isNotEmpty) {
      alertId = '${_userCI}_mod${_nextAlertId}';
      _nextAlertId++;
      print('[alerts] ID generado con CI: $alertId');
    } else {
      alertId = DateTime.now().millisecondsSinceEpoch.toString();
      print('[alerts] ID generado sin CI (fallback a timestamp): $alertId');
    }
    
    final alert = {
      'id': alertId,
      'datetime': datetime,
      'location': finalLocation,
      'latitude': finalLat,
      'longitude': finalLon,
      'description': description,
      'status': status,
      'filename': null,
    };
    
    setState(() {
      _alerts.insert(0, alert);
    });
    
    print('[alerts] alerta insertada en lista. Total alertas: ${_alerts.length}');

    // persist in shared prefs and as file
    try {
      print('[alerts] guardando alerta a archivo...');
      await _saveAlertToFile(_alerts.first);
      print('[alerts] alerta guardada a archivo exitosamente');
    } catch (e) {
      print('[alerts] error guardando alerta a archivo: $e');
    }
    
    try {
      await _saveAlerts();
      print('[alerts] alerta guardada en SharedPreferences');
    } catch (e) {
      print('[alerts] error guardando en SharedPreferences: $e');
    }
  }

  // --- File helpers: save/load alerts to JSON files under app documents/Documentos/alerts ---
  Future<Directory> _getAlertsDirectory() async {
    // En Android: usar almacenamiento externo público (/storage/emulated/0/Documents/alerts)
    // En desktop: usar carpeta del proyecto
    // En iOS: usar documentos de la app
    
    if (Platform.isAndroid) {
      // Ruta pública en almacenamiento externo
      final dir = Directory('/storage/emulated/0/Documents/alerts');
      if (!await dir.exists()) {
        try {
          await dir.create(recursive: true);
          print('[alerts] creada carpeta pública Android: ${dir.path}');
        } catch (e) {
          print('[alerts] error creando carpeta pública: $e');
        }
      } else {
        print('[alerts] usando carpeta pública Android: ${dir.path}');
      }
      return dir;
    }
    
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      final projDir = Directory('${Directory.current.path}${Platform.pathSeparator}Documentos${Platform.pathSeparator}alerts');
      if (!await projDir.exists()) {
        try {
          await projDir.create(recursive: true);
          print('[alerts] creada carpeta de proyecto: ${projDir.path}');
        } catch (e) {
          print('[alerts] no se pudo crear carpeta de proyecto, fallback: $e');
        }
      } else {
        print('[alerts] usando carpeta de proyecto: ${projDir.path}');
      }
      return projDir;
    }

    // Fallback: use application documents directory (iOS y otros)
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory('${base.path}${Platform.pathSeparator}Documentos${Platform.pathSeparator}alerts');
    if (!await dir.exists()) await dir.create(recursive: true);
    print('[alerts] usando carpeta de documentos de la app: ${dir.path}');
    return dir;
  }

  String _monthName(int m) {
    const names = ['Enero','Febrero','Marzo','Abril','Mayo','Junio','Julio','Agosto','Septiembre','Octubre','Noviembre','Diciembre'];
    return names[(m-1).clamp(0,11)];
  }

  String _formatDate(DateTime dt) {
    return '${_monthName(dt.month)} ${dt.day} del ${dt.year}';
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2,'0');
    final ampm = dt.hour >= 12 ? 'pm' : 'am';
    return '${hour.toString().padLeft(2,'0')}:$minute $ampm';
  }

  Future<void> _saveAlertToFile(Map<String, dynamic> alert) async {
    try {
      final dir = await _getAlertsDirectory();
      print('[alerts] guardando alerta id=${alert['id']} en ${dir.path}');
      final id = alert['id'] ?? DateTime.now().millisecondsSinceEpoch;
      final filename = alert['filename'] ?? 'alert_${id}.json';
      final file = File('${dir.path}${Platform.pathSeparator}$filename');
      final Map<String, dynamic> jsonMap = {
        'id': id,
        'place': alert['location'] ?? '',
        'date': _formatDate(alert['datetime'] as DateTime),
        'time': _formatTime(alert['datetime'] as DateTime),
        'timestamp': (alert['datetime'] as DateTime).millisecondsSinceEpoch,
        'status': alert['status'] ?? 'Alerta',
        'latitude': alert['latitude'],
        'longitude': alert['longitude'],
        'description': alert['description'] ?? '',
      };
      await file.writeAsString(jsonEncode(jsonMap), flush: true);
      alert['filename'] = filename;
      print('[alerts] archivo escrito: ${file.path}');
    } catch (e) {
      print('[alerts] error guardando archivo: $e');
    }
  }

  Future<void> _deleteAlertFile(String? filename) async {
    if (filename == null) return;
    try {
      final dir = await _getAlertsDirectory();
      final file = File('${dir.path}${Platform.pathSeparator}$filename');
      if (await file.exists()) {
        await file.delete();
        print('[alerts] archivo borrado: ${file.path}');
      } else {
        print('[alerts] archivo a borrar no existe: ${file.path}');
      }
    } catch (e) {}
  }

  Future<List<Map<String, dynamic>>> _loadAlertsFromFiles() async {
    final List<Map<String, dynamic>> list = [];
    try {
      final dir = await _getAlertsDirectory();
      print('[alerts] cargando archivos desde: ${dir.path}');
      final files = dir.listSync().whereType<File>().where((f) => f.path.endsWith('.json')).toList();
      print('[alerts] archivos encontrados: ${files.length}');
      for (final f in files) {
        try {
          final s = await f.readAsString();
          final data = jsonDecode(s) as Map<String, dynamic>;
          final ts = data['timestamp'] ?? DateTime.now().millisecondsSinceEpoch;
          list.add({
            'id': data['id'] ?? ts,
            'datetime': DateTime.fromMillisecondsSinceEpoch(ts),
            'location': data['place'] ?? '',
            'latitude': data['latitude'],
            'longitude': data['longitude'],
            'description': data['description'] ?? '',
            'status': data['status'] ?? 'Alerta',
            'filename': f.path.split(Platform.pathSeparator).last,
          });
        } catch (e) {
          print('[alerts] error parseando ${f.path}: $e');
        }
      }
      // sort newest first
      list.sort((a,b) => (b['datetime'] as DateTime).compareTo(a['datetime'] as DateTime));
    } catch (e) {}
    return list;
  }

  

  // Persistir alertas en SharedPreferences
  Future<void> _saveAlerts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<Map<String, dynamic>> serializable = _alerts.map((a) => {
            'id': a['id'],
            'datetime': (a['datetime'] as DateTime).toIso8601String(),
            'location': a['location'],
            'latitude': a['latitude'],
            'longitude': a['longitude'],
            'description': a['description'],
            'status': a['status'],
            'filename': a['filename'],
          }).toList();
      await prefs.setString('alerts', jsonEncode(serializable));
      // Persistir contador secuencial para IDs
      await prefs.setInt('nextAlertId', _nextAlertId);
    } catch (e) {
      // ignore errors silently (best-effort persistence)
    }
  }

  Future<void> _loadAlerts() async {
    try {
      // Prefer loading alerts from files in Documentos/alerts if present
      final fileAlerts = await _loadAlertsFromFiles();
      if (fileAlerts.isNotEmpty) {
        setState(() {
          _alerts.clear();
          _alerts.addAll(fileAlerts);
        });
        print('[alerts] alertas cargadas desde archivos: ${_alerts.length}');
        // Cargar contador
        _loadNextAlertId();
        return;
      }
      // Fallback to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final String? data = prefs.getString('alerts');
      if (data != null) {
        final List<dynamic> list = jsonDecode(data);
        setState(() {
          _alerts.clear();
          for (var item in list) {
            _alerts.add({
              'id': item['id'],
              'datetime': DateTime.parse(item['datetime'] as String),
              'location': item['location'] as String,
              'latitude': (item['latitude'] as num?)?.toDouble(),
              'longitude': (item['longitude'] as num?)?.toDouble(),
              'description': item['description'] as String,
              'status': item['status'] as String,
              'filename': item['filename'],
            });
          }
        });
        print('[alerts] alertas cargadas desde SharedPreferences: ${_alerts.length}');
      } else {
        print('[alerts] no hay alertas guardadas');
      }
      // Cargar contador
      _loadNextAlertId();
    } catch (e) {
      print('[alerts] error cargando alertas: $e');
    }
  }

  /// Cargar el contador secuencial de IDs desde SharedPreferences
  Future<void> _loadNextAlertId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedNext = prefs.getInt('nextAlertId');
      if (savedNext != null) {
        _nextAlertId = savedNext;
        print('[alerts] contador cargado: $_nextAlertId');
      }
    } catch (e) {
      print('[alerts] error cargando contador: $e');
    }
  }

  /// Cargar CI del usuario desde SecureStorageService
  Future<void> _loadUserCI() async {
    try {
      final ci = await SecureStorageService.getCI();
      if (mounted && ci != null && ci.isNotEmpty) {
        setState(() {
          _userCI = ci;
        });
        print('[options] CI del usuario cargado: $_userCI');
      } else {
        print('[options] No hay CI configurado');
      }
    } catch (e) {
      print('[options] Error al cargar CI: $e');
    }
  }

  // Cargar información de seguro desde SharedPreferences
  Future<void> _loadInsurance() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _insuranceCompany = prefs.getString('insuranceCompany');
        _policyNumber = prefs.getString('insurancePolicy');
        _insurancePhone = prefs.getString('insurancePhone');
      });
    } catch (e) {
      // ignore
    }
  }

  Future<void> _saveInsurance() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_insuranceCompany != null) await prefs.setString('insuranceCompany', _insuranceCompany!);
      if (_policyNumber != null) await prefs.setString('insurancePolicy', _policyNumber!);
      if (_insurancePhone != null) await prefs.setString('insurancePhone', _insurancePhone!);
    } catch (e) {
      // ignore
    }
  }

  Future<void> _clearInsurance() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('insuranceCompany');
      await prefs.remove('insurancePolicy');
      await prefs.remove('insurancePhone');
    } catch (e) {
      // ignore
    }
    setState(() {
      _insuranceCompany = null;
      _policyNumber = null;
      _insurancePhone = null;
    });
  }

  // Métodos de persistencia para Condiciones Médicas
  Future<void> _loadConditions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? data = prefs.getString('conditions');
      if (data != null) {
        final List<dynamic> list = jsonDecode(data);
        setState(() {
          _conditions = list.map((e) => Map<String, String>.from(e as Map)).toList();
        });
      }
    } catch (e) {
      // ignore
    }
  }

  Future<void> _saveConditions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('conditions', jsonEncode(_conditions));
    } catch (e) {
      // ignore
    }
  }

  // Métodos de persistencia para Medicamentos
  Future<void> _loadMedications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? data = prefs.getString('medications');
      if (data != null) {
        final List<dynamic> list = jsonDecode(data);
        setState(() {
          _medications = list.map((e) => e as String).toList();
        });
      }
    } catch (e) {
      // ignore
    }
  }

  Future<void> _saveMedications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('medications', jsonEncode(_medications));
    } catch (e) {
      // ignore
    }
  }

  // Métodos de persistencia para Citas Médicas
  Future<void> _loadAppointments() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? data = prefs.getString('appointments');
      if (data != null) {
        final List<dynamic> list = jsonDecode(data);
        setState(() {
          _appointments = list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        });
        
        // Sincronizar recordatorios cuando se cargan las citas
        try {
          await AppointmentReminderService.instance().refreshReminders(_appointments);
        } catch (e) {
          print('[options] Error sincronizando recordatorios: $e');
        }
      }
    } catch (e) {
      // ignore
    }
  }

  Future<void> _saveAppointments() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('appointments', jsonEncode(_appointments));
    } catch (e) {
      // ignore
    }
  }

  Widget _buildDetailRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(color: Colors.black87),
        ),
      ],
    );
  }

  String _formatAlertMinutes(int minutes) {
    if (minutes < 60) {
      return '$minutes minutos antes';
    } else if (minutes < 1440) {
      final hours = minutes ~/ 60;
      return '$hours ${hours == 1 ? 'hora' : 'horas'} antes';
    } else if (minutes < 2880) {
      return '1 día antes';
    } else {
      final days = minutes ~/ 1440;
      return '$days días antes';
    }
  }

  // Métodos de persistencia para Alergias
  Future<void> _loadAllergies() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? data = prefs.getString('allergies');
      if (data != null) {
        final List<dynamic> list = jsonDecode(data);
        setState(() {
          _allergies = list.map((e) => e as String).toList();
        });
      }
    } catch (e) {
      // ignore
    }
  }

  Future<void> _saveAllergies() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('allergies', jsonEncode(_allergies));
    } catch (e) {
      // ignore
    }
  }

  void _openDetail(BuildContext context, String title) async {
    // Show custom dialogs for the first three medical info cards
    if (title == 'Condición médica') {
      _showConditionsDialog(context);
      return;
    }
    if (title == 'Medicamentos') {
      _showMedicationsDialog(context);
      return;
    }
    if (title == 'Citas médicas') {
      _showAppointmentsDialog(context);
      return;
    }
    if (title == 'Historial de alertas') {
      _showAlertHistoryDialog(context);
      return;
    }
    if (title == 'Alergias') {
      _showAllergiesDialog(context);
      return;
    }

    if (title == 'Información de seguro') {
      await _showInsuranceDialog(context);
      return;
    }

    if (title == 'Documentos médicos') {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const DocumentsPage()));
      return;
    }

    if (title == 'Registro de síntomas') {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SymptomsPage()));
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => DetailPage(title: title)),
    );
  }

  Future<Map<String, String>?> _showConditionDialog(BuildContext context, {String? initialDiagnosis, String? initialSince}) {
    return showDialog<Map<String, String>>(
      context: context,
      builder: (ctx) {
        final TextEditingController diagnosisController = TextEditingController(text: initialDiagnosis ?? '');
        final TextEditingController sinceController = TextEditingController(text: initialSince ?? '');
        return StatefulBuilder(
          builder: (context, setState) {
            String? diagnosisError;
            String? sinceError;

            void validateFields() {
              diagnosisError = null;
              sinceError = null;

              if (!Validators.isNotEmpty(diagnosisController.text)) {
                diagnosisError = 'Por favor, describe tu condición médica';
              }

              if (!Validators.isNotEmpty(sinceController.text)) {
                sinceError = 'Por favor, selecciona una fecha';
              }
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              title: const Text('Condición Médica'),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                Text('Describe tu condición médica principal', style: TextStyle(color: Theme.of(ctx).textTheme.bodySmall?.color)),
                const SizedBox(height: 16),
                TextField(
                  controller: diagnosisController,
                  maxLines: 3,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Describe tu condición médica...',
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                    errorText: diagnosisError,
                    errorMaxLines: 2,
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Desde', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextField(
                  controller: sinceController,
                  readOnly: true,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'dd/mm/aaaa',
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                    suffixIcon: const Icon(Icons.calendar_today),
                    errorText: sinceError,
                    errorMaxLines: 2,
                  ),
                  onTap: () async {
                    final DateTime? picked = await showDatePicker(
                      context: ctx,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(1900),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      sinceController.text = '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
                      setState(() {});
                    }
                  },
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () {
                validateFields();
                if (diagnosisError == null && sinceError == null) {
                  Navigator.of(ctx).pop({
                    'diagnosis': diagnosisController.text.trim(),
                    'since': sinceController.text.trim(),
                  });
                } else {
                  setState(() {});
                }
              },
              child: const Text('Guardar'),
            ),
          ],
            );
          },
        );
      },
    );
  }

  void _showConditionsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            title: const Text('Condiciones Médicas'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Text('Gestiona tus condiciones médicas', style: TextStyle(color: Colors.black54)),
                  const SizedBox(height: 12),
                  if (_conditions.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      child: Text('No hay condiciones agregadas', style: TextStyle(color: Colors.black54)),
                    )
                  else
                    for (int i = 0; i < _conditions.length; i++)
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                        child: ListTile(
                          title: Text(_conditions[i]['diagnosis'] ?? ''),
                          subtitle: Text('Desde: ${_conditions[i]['since'] ?? ''}', style: const TextStyle(fontSize: 12)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextButton(
                                onPressed: () async {
                                  final result = await _showConditionDialog(context, initialDiagnosis: _conditions[i]['diagnosis'], initialSince: _conditions[i]['since']);
                                  if (result != null) {
                                    if (!mounted) return;
                                    setState(() {
                                      _conditions[i] = result;
                                    });
                                    this.setState(() {});
                                    await _saveConditions();
                                  }
                                },
                                child: const Text('Editar', style: TextStyle(color: Colors.orange)),
                              ),
                              TextButton(
                                onPressed: () => setState(() {
                                  _conditions.removeAt(i);
                                  this.setState(() {});
                                  _saveConditions();
                                }),
                                child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
                              ),
                            ],
                          ),
                        ),
                      ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: () async {
                      final result = await _showConditionDialog(context);
                      if (result != null) {
                        if (!mounted) return;
                        setState(() => _conditions.add(result));
                        this.setState(() {});
                        await _saveConditions();
                      }
                    },
                    child: const Text('+ Agregar condición'),
                  ),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cerrar')),
            ],
          );
        });
      },
    );
  }

  void _showMedicationsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            title: const Text('Medicamentos Actuales'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Text('Gestiona tu lista de medicamentos', style: TextStyle(color: Colors.black54)),
                  const SizedBox(height: 12),
                  if (_medications.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      child: Text('No hay medicamentos agregados', style: TextStyle(color: Colors.black54)),
                    )
                  else
                    for (int i = 0; i < _medications.length; i++)
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        decoration: BoxDecoration(color: Colors.purple.shade50, borderRadius: BorderRadius.circular(8)),
                        child: ListTile(
                          title: Text(_medications[i]),
                          trailing: TextButton(
                            onPressed: () => setState(() {
                              _medications.removeAt(i);
                              this.setState(() {});
                              _saveMedications();
                            }),
                            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
                          ),
                        ),
                      ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: () async {
                      final result = await showDialog<Map<String, String>>(
                        context: context,
                        builder: (dctx) {
                          final TextEditingController nameCtrl = TextEditingController();
                          final TextEditingController qtyCtrl = TextEditingController();
                          final TextEditingController freqCtrl = TextEditingController();
                          return AlertDialog(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            title: const Text('Agregar medicamento'),
                            content: SingleChildScrollView(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  TextField(
                                    controller: nameCtrl,
                                    decoration: InputDecoration(labelText: 'Medicamento', hintText: 'Nombre del medicamento'),
                                  ),
                                  const SizedBox(height: 8),
                                  TextField(
                                    controller: qtyCtrl,
                                    decoration: InputDecoration(labelText: 'Cantidad', hintText: '100mg, 1 pastilla...'),
                                  ),
                                  const SizedBox(height: 8),
                                  TextField(
                                    controller: freqCtrl,
                                    decoration: InputDecoration(labelText: 'Frecuencia', hintText: 'Cada 12 horas / 1 vez al día'),
                                  ),
                                ],
                              ),
                            ),
                            actions: <Widget>[
                              TextButton(onPressed: () => Navigator.of(dctx).pop(), child: const Text('Cancelar')),
                              ElevatedButton(
                                onPressed: () {
                                  final name = nameCtrl.text.trim();
                                  final qty = qtyCtrl.text.trim();
                                  final freq = freqCtrl.text.trim();
                                  if (name.isEmpty) return;
                                  Navigator.of(dctx).pop({'name': name, 'qty': qty, 'freq': freq});
                                },
                                child: const Text('Agregar'),
                              ),
                            ],
                          );
                        },
                      );

                      if (result != null) {
                        if (!mounted) return;
                        final name = result['name'] ?? '';
                        final qty = result['qty'] ?? '';
                        final freq = result['freq'] ?? '';
                        final entry = qty.isNotEmpty ? '$name $qty - $freq' : '$name - $freq';
                        setState(() => _medications.add(entry));
                        this.setState(() {});
                        await _saveMedications();
                      }
                    },
                    child: const Text('+ Agregar medicamento'),
                  ),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cerrar')),
            ],
          );
        });
      },
    );
  }

  void _showAppointmentsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            title: const Text('Próximas Citas Médicas'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Text('Tus consultas programadas', style: TextStyle(color: Colors.black54)),
                  const SizedBox(height: 12),
                  if (_appointments.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      child: Text('No hay citas agregadas', style: TextStyle(color: Colors.black54)),
                    )
                  else
                    for (int i = 0; i < _appointments.length; i++)
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          title: Text(_appointments[i]['name'] ?? ''),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(_appointments[i]['specialty'] ?? ''),
                              const SizedBox(height: 6),
                              Text(_appointments[i]['date'] ?? '', style: const TextStyle(color: Colors.black54)),
                              Text(_appointments[i]['time'] ?? '', style: const TextStyle(color: Colors.black54, fontSize: 12)),
                              Text('🔔 ${_formatAlertMinutes((_appointments[i]['alertMinutes'] as int?) ?? 1440)}', style: const TextStyle(color: Colors.green, fontSize: 11)),
                            ],
                          ),
                          trailing: PopupMenuButton<String>(
                            onSelected: (String value) async {
                              if (value == 'edit') {
                                // Crear controladores una sola vez para el diálogo
                                final nameCtrl = TextEditingController(text: _appointments[i]['name']);
                                final specCtrl = TextEditingController(text: _appointments[i]['specialty']);
                                final dateCtrl = TextEditingController(text: _appointments[i]['date']);
                                final timeCtrl = TextEditingController(text: _appointments[i]['time'] ?? '');
                                final detailCtrl = TextEditingController(text: _appointments[i]['detail'] ?? '');
                                int selectedAlertMinutes = (_appointments[i]['alertMinutes'] as int?) ?? 1440;
                                
                                showDialog<void>(
                                  context: context,
                                  builder: (dctx) {
                                    return StatefulBuilder(
                                      builder: (context, setStateDialog) {
                                        
                                        return ConstrainedBox(
                                          constraints: BoxConstraints(maxHeight: MediaQuery.of(dctx).size.height * 0.7),
                                          child: AlertDialog(
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                            title: const Text('Editar cita'),
                                            content: SingleChildScrollView(
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                            children: <Widget>[
                                              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nombre', isDense: true)),
                                              const SizedBox(height: 12),
                                                  TextField(controller: specCtrl, decoration: const InputDecoration(labelText: 'Especialidad', isDense: true)),
                                                  const SizedBox(height: 12),
                                                  TextField(
                                                    controller: dateCtrl,
                                                    readOnly: true,
                                                    decoration: const InputDecoration(labelText: 'Fecha', isDense: true),
                                                    onTap: () async {
                                                      final DateTime? picked = await showDatePicker(
                                                        context: dctx,
                                                        initialDate: DateTime.now(),
                                                        firstDate: DateTime.now(),
                                                        lastDate: DateTime(2100),
                                                      );
                                                      if (picked != null) {
                                                        dateCtrl.text = '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
                                                      }
                                                    },
                                                  ),
                                                  const SizedBox(height: 12),
                                                  TextField(
                                                    controller: timeCtrl,
                                                    readOnly: true,
                                                    decoration: const InputDecoration(labelText: 'Hora', isDense: true),
                                                    onTap: () async {
                                                      final TimeOfDay? picked = await showTimePicker(
                                                        context: dctx,
                                                        initialTime: TimeOfDay.now(),
                                                      );
                                                      if (picked != null) {
                                                        timeCtrl.text = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                                                      }
                                                    },
                                                  ),
                                                  const SizedBox(height: 12),
                                                  TextField(controller: detailCtrl, decoration: const InputDecoration(labelText: 'Detalle (Opcional)', isDense: true), maxLines: 3),
                                                  const SizedBox(height: 12),
                                                  DropdownButtonFormField<int>(
                                                    value: selectedAlertMinutes,
                                                    decoration: const InputDecoration(labelText: 'Recibir alerta', isDense: true),
                                                    items: [
                                                      const DropdownMenuItem(value: 5, child: Text('5 minutos antes')),
                                                      const DropdownMenuItem(value: 60, child: Text('1 hora antes')),
                                                      const DropdownMenuItem(value: 240, child: Text('4 horas antes')),
                                                      const DropdownMenuItem(value: 1440, child: Text('24 horas antes')),
                                                      const DropdownMenuItem(value: 2880, child: Text('2 días antes')),
                                                    ],
                                                    onChanged: (value) {
                                                      if (value != null) {
                                                        setStateDialog(() => selectedAlertMinutes = value);
                                                      }
                                                    },
                                                  ),
                                                ],
                                              ),
                                            ),
                                            actions: <Widget>[
                                              TextButton(onPressed: () => Navigator.of(dctx).pop(), child: const Text('Cancelar')),
                                              ElevatedButton(
                                                onPressed: () async {
                                                  // Validar que todos los campos estén completos
                                                  if (nameCtrl.text.trim().isEmpty || 
                                                      specCtrl.text.trim().isEmpty ||
                                                      dateCtrl.text.trim().isEmpty ||
                                                      timeCtrl.text.trim().isEmpty) {
                                                    ScaffoldMessenger.of(dctx).showSnackBar(
                                                      const SnackBar(content: Text('Por favor completa todos los campos')),
                                                    );
                                                    return;
                                                  }
                                                  // Actualizar la cita
                                                  setState(() {
                                                    _appointments[i] = {
                                                      'name': nameCtrl.text.trim(),
                                                      'specialty': specCtrl.text.trim(),
                                                      'date': dateCtrl.text.trim(),
                                                      'time': timeCtrl.text.trim(),
                                                      'detail': detailCtrl.text.trim(),
                                                      'alertMinutes': selectedAlertMinutes,
                                                    };
                                                  });
                                                  await _saveAppointments();
                                                  Navigator.of(dctx).pop();
                                                },
                                                child: const Text('Guardar'),
                                              ),
                                            ],
                                            ),
                                          );
                                        },
                                      );
                                    },
                                  );
                              } else if (value == 'delete') {
                                final appointmentToDelete = _appointments[i];
                                setState(() {
                                  _appointments.removeAt(i);
                                });
                                await _saveAppointments();
                                
                                // Cancelar recordatorio de la cita eliminada
                                try {
                                  final appointmentId = 'cita_${appointmentToDelete['name']}_${appointmentToDelete['date']}';
                                  AppointmentReminderService.instance().cancelAppointmentReminder(appointmentId);
                                  print('[options] Recordatorio cancelado para cita: $appointmentId');
                                } catch (e) {
                                  print('[options] Error cancelando recordatorio: $e');
                                }
                              } else if (value == 'view') {
                                showDialog<void>(
                                  context: context,
                                  builder: (dctx) => AlertDialog(
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    title: const Text('Detalles de la Cita'),
                                    content: SingleChildScrollView(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          _buildDetailRow('Especialista:', _appointments[i]['name'] ?? ''),
                                          const SizedBox(height: 12),
                                          _buildDetailRow('Especialidad:', _appointments[i]['specialty'] ?? ''),
                                          const SizedBox(height: 12),
                                          _buildDetailRow('Fecha:', _appointments[i]['date'] ?? ''),
                                          const SizedBox(height: 12),
                                          _buildDetailRow('Hora:', _appointments[i]['time'] ?? ''),
                                          const SizedBox(height: 12),
                                          _buildDetailRow('Alerta:', _formatAlertMinutes((_appointments[i]['alertMinutes'] as int?) ?? 1440)),
                                          if ((_appointments[i]['detail'] ?? '').isNotEmpty) ...[
                                            const SizedBox(height: 12),
                                            _buildDetailRow('Detalle:', _appointments[i]['detail'] ?? ''),
                                          ]
                                        ],
                                      ),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.of(dctx).pop(),
                                        child: const Text('Cerrar'),
                                      ),
                                    ],
                                  ),
                                );
                              }
                            },
                            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                              const PopupMenuItem<String>(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit, size: 18, color: Colors.blue),
                                    SizedBox(width: 8),
                                    Text('Editar'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem<String>(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete, size: 18, color: Colors.red),
                                    SizedBox(width: 8),
                                    Text('Eliminar'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem<String>(
                                value: 'view',
                                child: Row(
                                  children: [
                                    Icon(Icons.visibility, size: 18, color: Colors.green),
                                    SizedBox(width: 8),
                                    Text('Ver Detalles'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: () async {
                      // Crear controladores una sola vez para el diálogo
                      final nameCtrl = TextEditingController();
                      final specCtrl = TextEditingController();
                      final dateCtrl = TextEditingController();
                      final timeCtrl = TextEditingController();
                      final detailCtrl = TextEditingController();
                      int selectedAlertMinutes = 1440; // Por defecto 24 horas
                      
                      showDialog<void>(
                        context: context,
                        builder: (dctx) {
                          return StatefulBuilder(
                            builder: (context, setStateDialog) {
                              return ConstrainedBox(
                                constraints: BoxConstraints(maxHeight: MediaQuery.of(dctx).size.height * 0.7),
                                child: AlertDialog(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  title: const Text('Agregar cita'),
                                  content: SingleChildScrollView(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: <Widget>[
                                        TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nombre', isDense: true)),
                                        const SizedBox(height: 12),
                                    TextField(controller: specCtrl, decoration: const InputDecoration(labelText: 'Especialidad', isDense: true)),
                                    const SizedBox(height: 12),
                                    TextField(
                                      controller: dateCtrl,
                                      readOnly: true,
                                      decoration: const InputDecoration(labelText: 'Fecha (Hoy o Futuro)', isDense: true),
                                      onTap: () async {
                                        final DateTime? picked = await showDatePicker(
                                          context: dctx,
                                          initialDate: DateTime.now(),
                                          firstDate: DateTime.now(),
                                          lastDate: DateTime(2100),
                                        );
                                        if (picked != null) {
                                          dateCtrl.text = '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
                                        }
                                      },
                                    ),
                                    const SizedBox(height: 12),
                                    TextField(
                                      controller: timeCtrl,
                                      readOnly: true,
                                      decoration: const InputDecoration(labelText: 'Hora', isDense: true),
                                      onTap: () async {
                                        final TimeOfDay? picked = await showTimePicker(
                                          context: dctx,
                                          initialTime: TimeOfDay.now(),
                                        );
                                        if (picked != null) {
                                          timeCtrl.text = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                                        }
                                      },
                                    ),
                                    const SizedBox(height: 12),
                                    TextField(controller: detailCtrl, decoration: const InputDecoration(labelText: 'Detalle (Opcional)', isDense: true), maxLines: 3),
                                    const SizedBox(height: 12),
                                    DropdownButtonFormField<int>(
                                      value: selectedAlertMinutes,
                                      decoration: const InputDecoration(labelText: 'Recibir alerta', isDense: true),
                                      items: [
                                        const DropdownMenuItem(value: 5, child: Text('5 minutos antes')),
                                        const DropdownMenuItem(value: 60, child: Text('1 hora antes')),
                                        const DropdownMenuItem(value: 240, child: Text('4 horas antes')),
                                        const DropdownMenuItem(value: 1440, child: Text('24 horas antes')),
                                        const DropdownMenuItem(value: 2880, child: Text('2 días antes')),
                                      ],
                                      onChanged: (value) {
                                        if (value != null) {
                                          setStateDialog(() => selectedAlertMinutes = value);
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            actions: <Widget>[
                              TextButton(onPressed: () => Navigator.of(dctx).pop(), child: const Text('Cancelar')),
                              ElevatedButton(
                                onPressed: () async {
                                  // Validar que todos los campos estén completos
                                  if (nameCtrl.text.trim().isEmpty || 
                                      specCtrl.text.trim().isEmpty ||
                                      dateCtrl.text.trim().isEmpty ||
                                      timeCtrl.text.trim().isEmpty) {
                                    ScaffoldMessenger.of(dctx).showSnackBar(
                                      const SnackBar(content: Text('Por favor completa todos los campos')),
                                    );
                                    return;
                                  }
                                  // Agregar la cita
                                  final newAppointment = {
                                    'name': nameCtrl.text.trim(),
                                    'specialty': specCtrl.text.trim(),
                                    'date': dateCtrl.text.trim(),
                                    'time': timeCtrl.text.trim(),
                                    'detail': detailCtrl.text.trim(),
                                    'alertMinutes': selectedAlertMinutes,
                                  };
                                  print('[options] Guardando nueva cita: $newAppointment');
                                  setState(() => _appointments.add(newAppointment));
                                  await _saveAppointments();
                                  print('[options] Cita guardada en preferencias');
                                  
                                  // Programar recordatorio automático para la cita
                                  try {
                                    final appointmentId = 'cita_${newAppointment['name']}_${newAppointment['date']}';
                                    print('[options] Iniciando programación de recordatorio: $appointmentId');
                                    
                                    // Convertir fecha (DD/MM/YYYY) y hora (HH:MM) a DateTime
                                    final dateParts = ((newAppointment['date'] as String?) ?? '').split('/');
                                    final timeParts = ((newAppointment['time'] as String?) ?? '00:00').split(':');
                                    
                                    if (dateParts.length == 3 && timeParts.length == 2) {
                                      final day = int.tryParse(dateParts[0]) ?? 1;
                                      final month = int.tryParse(dateParts[1]) ?? 1;
                                      final year = int.tryParse(dateParts[2]) ?? 2025;
                                      final hour = int.tryParse(timeParts[0]) ?? 0;
                                      final minute = int.tryParse(timeParts[1]) ?? 0;
                                      
                                      final appointmentDateTime = DateTime(year, month, day, hour, minute);
                                      print('[options] Fecha/Hora de cita: $appointmentDateTime');
                                      
                                      print('[options] Llamando a scheduleAppointmentReminder con minutesBeforeReminder=$selectedAlertMinutes');
                                      await AppointmentReminderService.instance().scheduleAppointmentReminder(
                                        appointmentId: appointmentId,
                                        appointmentDateTime: appointmentDateTime,
                                        doctorName: (newAppointment['name'] as String?) ?? 'Médico',
                                        appointmentDate: (newAppointment['date'] as String?) ?? '',
                                        appointmentTime: (newAppointment['time'] as String?) ?? '',
                                        minutesBeforeReminder: selectedAlertMinutes,
                                      );
                                      print('[options] ✅ Recordatorio programado para cita: $appointmentId');
                                    } else {
                                      print('[options] ❌ Formato de fecha/hora inválido: ${newAppointment['date']} ${newAppointment['time']}');
                                    }
                                  } catch (e) {
                                    print('[options] ❌ Error programando recordatorio: $e');
                                  }
                                  Navigator.of(dctx).pop();
                                },
                                child: const Text('Agregar'),
                              ),
                            ],
                            ),
                          );
                            },
                          );
                        },
                      );
                    },
                    child: const Text('+ Agregar cita'),
                  ),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cerrar')),
            ],
          );
        });
      },
    );
  }

  void _showAlertHistoryDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            title: const Text('Historial de Alertas'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Text('Registro de emergencias activadas', style: TextStyle(color: Colors.black54)),
                  const SizedBox(height: 12),
                  if (_alerts.isEmpty) const Text('No hay alertas registradas.'),
                  for (int i = 0; i < _alerts.length; i++)
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        title: Text(_formatDateTime(_alerts[i]['datetime'] as DateTime)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            if ((_alerts[i]['location'] as String).isNotEmpty) Text(_alerts[i]['location'] as String),
                            const SizedBox(height: 8),
                            Text(_alerts[i]['description'] as String),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 12,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: <Widget>[
                                _statusChip(_alerts[i]['status'] as String),
                                TextButton(
                                  onPressed: () async {
                                      final result = await _showAlertDetailDialog(context, _alerts[i]);
                                      if (result != null) {
                                        if (!mounted) return;
                                        
                                        // Extraer ID de la alerta
                                        final alertId = result['id']?.toString() ?? '';
                                        
                                        // Actualizar localmente
                                        setState(() => _alerts[i] = result);
                                        
                                        // Guardar localmente en archivo y SharedPreferences
                                        try {
                                          await _saveAlertToFile(result);
                                        } catch (_) {}
                                        await _saveAlerts();
                                        
                                        // Actualizar en Firebase
                                        try {
                                          await AlertService.instance.updateAlert(
                                            alertId: alertId,
                                            description: result['description'] as String?,
                                            location: result['location'] as String?,
                                            status: result['status'] as String?,
                                          );
                                          print('[options] Alerta actualizada en Firebase: $alertId');
                                          
                                          if (!mounted) return;
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('✓ Alerta actualizada en Firebase'),
                                              duration: Duration(seconds: 2),
                                            ),
                                          );
                                        } catch (e) {
                                          print('[options] Error al actualizar en Firebase: $e');
                                          if (!mounted) return;
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('Error al actualizar Firebase: $e'),
                                              duration: const Duration(seconds: 3),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                        }
                                      }
                                    },
                                  child: const Text('Ver detalles'),
                                ),
                              ],
                            ),
                          ],
                        ),
                          trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () async {
                            final filename = _alerts[i]['filename'] as String?;
                            if (filename != null) {
                              try {
                                await _deleteAlertFile(filename);
                              } catch (_) {}
                            }
                            setState(() => _alerts.removeAt(i));
                            await _saveAlerts();
                          },
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cerrar')),
            ],
          );
        });
      },
    );
  }

  // Mostrar diálogo con detalles de una alerta (editar solo descripción, lugar y estado)
  Future<Map<String, dynamic>?> _showAlertDetailDialog(BuildContext context, Map<String, dynamic> alert) {
    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dctx) {
        final TextEditingController descCtrl = TextEditingController(text: alert['description'] as String);
        final TextEditingController placeCtrl = TextEditingController(text: alert['location'] as String);
        final DateTime alertDateTime = alert['datetime'] as DateTime;
        final String formattedDateTime = '${_formatDate(alertDateTime)} - ${_formatTime(alertDateTime)}';
        
        return StatefulBuilder(
          builder: (context, setDialogState) {
            String status = alert['status'] as String;
            
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              title: const Text('Detalle de alerta'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    // Fecha y Hora (solo lectura)
                    const Text('Fecha y Hora', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Text(
                        formattedDateTime,
                        style: const TextStyle(fontSize: 14, color: Colors.black87, fontWeight: FontWeight.w500),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Descripción (editable)
                    const Text('Descripción', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: descCtrl,
                      maxLines: 3,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        hintText: 'Descripción de la alerta',
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Lugar (editable)
                    const Text('Lugar', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: placeCtrl,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        hintText: 'Ubicación o lugar',
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Estado (editable con dropdown)
                    const Text('Estado', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButton<String>(
                        value: status,
                        isExpanded: true,
                        underline: const SizedBox(),
                        items: const [
                          DropdownMenuItem(value: 'Alerta', child: Text('🔴 Alerta')),
                          DropdownMenuItem(value: 'Resuelto', child: Text('🟢 Resuelto')),
                          DropdownMenuItem(value: 'Falsa alarma', child: Text('🟠 Falsa alarma')),
                        ],
                        onChanged: (v) {
                          if (v != null) {
                            setDialogState(() {
                              alert['status'] = v;
                              status = v;
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(onPressed: () => Navigator.of(dctx).pop(), child: const Text('Cancelar')),
                ElevatedButton(
                  onPressed: () {
                    final updated = Map<String, dynamic>.from(alert);
                    updated['description'] = descCtrl.text.trim();
                    updated['location'] = placeCtrl.text.trim();
                    updated['status'] = status;
                    Navigator.of(dctx).pop(updated);
                  },
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _statusChip(String status) {
    Color color = Colors.grey;
    if (status == 'Resuelto') color = Colors.green;
    if (status == 'Falsa alarma') color = Colors.orange;
    if (status == 'Alerta') color = Colors.red;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: color.withAlpha((0.15 * 255).round()), borderRadius: BorderRadius.circular(20)),
      child: Text(status, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
    );
  }

  String _formatDateTime(DateTime dt) {
    final d = dt;
    final day = d.day.toString().padLeft(2, '0');
    final month = d.month.toString().padLeft(2, '0');
    final year = d.year;
    final hour = d.hour.toString().padLeft(2, '0');
    final minute = d.minute.toString().padLeft(2, '0');
    return '$day/$month/$year - $hour:$minute';
  }

  void _showAllergiesDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            title: const Text('Alergias Conocidas'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Text('Lista de alergias y reacciones adversas', style: TextStyle(color: Colors.black54)),
                  const SizedBox(height: 12),
                  if (_allergies.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      child: Text('No hay alergias agregadas', style: TextStyle(color: Colors.black54)),
                    )
                  else
                    for (int i = 0; i < _allergies.length; i++)
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(8)),
                        child: ListTile(
                          leading: Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700),
                          title: Text(_allergies[i]),
                          trailing: TextButton(
                            onPressed: () => setState(() {
                              _allergies.removeAt(i);
                              this.setState(() {});
                              _saveAllergies();
                            }),
                            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
                          ),
                        ),
                      ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: () async {
                      final result = await showDialog<String>(
                        context: context,
                        builder: (dctx) {
                          final TextEditingController allergyCtrl = TextEditingController();
                          return AlertDialog(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            title: const Text('Agregar alergia'),
                            content: TextField(
                              controller: allergyCtrl,
                              decoration: InputDecoration(hintText: 'Ej: Penicilina'),
                            ),
                            actions: <Widget>[
                              TextButton(onPressed: () => Navigator.of(dctx).pop(), child: const Text('Cancelar')),
                              ElevatedButton(
                                onPressed: () {
                                  final text = allergyCtrl.text.trim();
                                  if (text.isEmpty) return;
                                  Navigator.of(dctx).pop(text);
                                },
                                child: const Text('Agregar'),
                              ),
                            ],
                          );
                        },
                      );
                      if (result != null && result.isNotEmpty) {
                        if (!mounted) return;
                        setState(() => _allergies.add(result));
                        this.setState(() {});
                        await _saveAllergies();
                      }
                    },
                    child: const Text('+ Agregar alergia'),
                  ),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cerrar')),
            ],
          );
        });
      },
    );
  }

  Future<void> _showInsuranceDialog(BuildContext context) async {
    final TextEditingController companyCtrl = TextEditingController(text: _insuranceCompany ?? '');
    final TextEditingController policyCtrl = TextEditingController(text: _policyNumber ?? '');
    final TextEditingController phoneCtrl = TextEditingController(text: _insurancePhone ?? '');

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Text('Información de Seguro'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Datos de tu seguro médico', style: TextStyle(color: Theme.of(ctx).textTheme.bodySmall?.color)),
                const SizedBox(height: 12),
                const Text('Compañía de seguros', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextField(controller: companyCtrl, decoration: InputDecoration(hintText: 'Nombre de la aseguradora', filled: true, fillColor: Theme.of(ctx).inputDecorationTheme.fillColor ?? Colors.grey.shade100, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none))),
                const SizedBox(height: 12),
                const Text('Número de póliza', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextField(controller: policyCtrl, decoration: InputDecoration(hintText: '123456789', filled: true, fillColor: Theme.of(ctx).inputDecorationTheme.fillColor ?? Colors.grey.shade100, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none))),
                const SizedBox(height: 12),
                const Text('Teléfono de emergencias', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextField(controller: phoneCtrl, decoration: InputDecoration(hintText: '+1 800 123 4567', filled: true, fillColor: Theme.of(ctx).inputDecorationTheme.fillColor ?? Colors.grey.shade100, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none))),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancelar')),
            ElevatedButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Guardar')),
          ],
        );
      },
    );

    if (result == true) {
        if (!mounted) return;
      setState(() {
        _insuranceCompany = companyCtrl.text.trim();
        _policyNumber = policyCtrl.text.trim();
        _insurancePhone = phoneCtrl.text.trim();
      });
      await _saveInsurance();
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double titleFontSize = (screenWidth * 0.05).clamp(18.0, 24.0);
    final double subtitleFontSize = (screenWidth * 0.035).clamp(12.0, 16.0);
    final double sectionTitleFontSize = (screenWidth * 0.04).clamp(14.0, 18.0);
    final double textFontSize = (screenWidth * 0.035).clamp(12.0, 16.0);
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Opciones', style: TextStyle(fontSize: titleFontSize, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('Información médica y recursos', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.black54, fontSize: subtitleFontSize)),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        child: ListView(
          children: <Widget>[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text('Información Médica', style: TextStyle(fontWeight: FontWeight.bold, fontSize: sectionTitleFontSize)),
            ),
            // Tarjeta de Condiciones Médicas
            _buildCard(context, 'Condición médica', 'Gestiona tus condiciones', icon: Icons.favorite, color: Colors.red),
            // Medicamentos
            _buildCard(context, 'Medicamentos', 'Lista de medicinas actuales', icon: Icons.medication, color: Colors.purple),
            // Alergias
            _buildCard(context, 'Alergias', 'Alergias y reacciones', icon: Icons.warning_amber_rounded, color: Colors.orange),
            const SizedBox(height: 12),
            Text('Historial y Seguimiento', style: TextStyle(fontWeight: FontWeight.bold, fontSize: sectionTitleFontSize)),
            const SizedBox(height: 8),
            _buildCard(context, 'Citas médicas', 'Próximas consultas', icon: Icons.calendar_month, color: Colors.blue),
            _buildCard(context, 'Historial de alertas', 'Emergencias registradas', icon: Icons.history, color: Colors.green),
            _buildCard(context, 'Registro de síntomas', 'Diario de salud', icon: Icons.article, color: Colors.teal),
            const SizedBox(height: 12),
            Text('Documentos', style: TextStyle(fontWeight: FontWeight.bold, fontSize: sectionTitleFontSize)),
            const SizedBox(height: 8),
            _buildCard(context, 'Documentos médicos', 'Estudios y recetas', icon: Icons.description, color: Colors.deepPurple),
            _buildCard(context, 'Información de seguro', 'Pólizas y cobertura', icon: Icons.shield, color: Colors.pink),
            // Mostrar resumen de seguro si existe (moved here)
            if (_insuranceCompany != null || _policyNumber != null || _insurancePhone != null)
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Expanded(child: Text('Información de seguro', style: TextStyle(fontWeight: FontWeight.w600, fontSize: textFontSize, color: Theme.of(context).textTheme.bodyMedium?.color))),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              TextButton(onPressed: () async { await _showInsuranceDialog(context); }, child: Text('Editar', style: TextStyle(fontSize: textFontSize * 0.85))),
                              IconButton(onPressed: () async { await _clearInsurance(); }, icon: const Icon(Icons.delete_outline), color: Theme.of(context).iconTheme.color),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (_insuranceCompany != null) Text(_insuranceCompany!, style: TextStyle(fontSize: textFontSize, color: Theme.of(context).textTheme.bodyMedium?.color)),
                      if (_policyNumber != null) Padding(padding: const EdgeInsets.only(top: 6.0), child: Text('Póliza: $_policyNumber', style: TextStyle(fontSize: textFontSize * 0.9, color: Theme.of(context).textTheme.bodySmall?.color))),
                      if (_insurancePhone != null) Padding(padding: const EdgeInsets.only(top: 6.0), child: Text('Tel: $_insurancePhone', style: TextStyle(fontSize: textFontSize * 0.9, color: Theme.of(context).textTheme.bodySmall?.color))),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 20),
            Card(
              color: Colors.red.shade50,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: <Widget>[
                    const Icon(Icons.warning, color: Colors.red),
                    const SizedBox(width: 12),
                    Expanded(child: Text('Información importante\nMantén tu información médica actualizada para que los servicios de emergencia puedan asistirte mejor.', style: TextStyle(fontSize: textFontSize * 0.9))),
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

  Widget _buildCard(BuildContext context, String title, String subtitle, {required IconData icon, required Color color}) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double titleFontSize = (screenWidth * 0.04).clamp(14.0, 16.0);
    final double subtitleFontSize = (screenWidth * 0.032).clamp(12.0, 14.0);
    
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withAlpha((0.12 * 255).round()),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: TextStyle(fontSize: titleFontSize, fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: TextStyle(fontSize: subtitleFontSize)),
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
