import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

import 'options.dart';
import 'senttings.dart';
import 'preferences.dart';
import 'validators/validators.dart';
import 'services/rate_limiter.dart';
import 'services/firebase_service.dart';
import 'services/alert_service.dart';
import 'services/notification_service.dart';
import 'services/appointment_reminder_service.dart';

// Global key to access OptionsPage state so other pages (Inicio) can add alerts
final GlobalKey optionsPageKey = GlobalKey();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  print('[main] iniciando app...');
  
  // Inicializar Firebase
  try {
    await FirebaseService.instance.initialize();
    print('[main] Firebase inicializado correctamente');
  } catch (e) {
    print('[main] ERROR al inicializar Firebase: $e');
    // Continuar igualmente si Firebase no se inicializa
  }
  
  // Inicializar servicio de notificaciones (FCM)
  try {
    await NotificationService.instance().initialize();
    print('[main] NotificationService inicializado correctamente');
  } catch (e) {
    print('[main] ERROR al inicializar NotificationService: $e');
    // Continuar igualmente si FCM no se inicializa
  }
  
  // Inicializar servicio de recordatorios de citas médicas
  try {
    await AppointmentReminderService.instance().initialize();
    print('[main] AppointmentReminderService inicializado correctamente');
  } catch (e) {
    print('[main] ERROR al inicializar AppointmentReminderService: $e');
    // Continuar igualmente si el servicio no se inicializa
  }
  
  runApp(const MyApp());
}
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'App de Emergencia',
      theme: ThemeData(
        primarySwatch: Colors.red,
      ),
      navigatorKey: NotificationService.navigatorKey,
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    print('[HomeScreen.build] renderizando con _selectedIndex: $_selectedIndex');

    return Scaffold(
      // Using IndexedStack to keep all pages always built and rendered (invisible ones)
      // This ensures OptionsPage state is always available to InicioPage
      body: SafeArea(
        child: IndexedStack(
          index: _selectedIndex,
          children: <Widget>[
            const InicioPage(),
            OptionsPage(key: optionsPageKey),
            const SenttingsPage(),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu),
            label: 'Opciones',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Ajustes',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.red,
        onTap: (index) {
          print('[HomeScreen._onItemTapped] seleccionando index: $index');
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }
}

class InicioPage extends StatefulWidget {
  const InicioPage({super.key});

  @override
  State<InicioPage> createState() => _InicioPageState();
}

class _InicioPageState extends State<InicioPage> {
  double _holdProgress = 0.0;
  Timer? _holdTimer;
  final int _holdDurationMs = 1200; // 1.2 seconds to activate (reduced)
  // Current preferred contact (from Settings). If null, fallback to '911'.
  Map<String, String>? _preferredContact;
  // Which of the two small buttons on Inicio is set as favorite: 0 = 911, 1 = contacto
  int _mainFavoriteIndex = 0;
  static const String _mainFavoriteKey = 'main_favorite_index';
  // Preferred contact is managed from Settings (preferredContact ValueNotifier).
  late VoidCallback _preferredListener;
  // Contacts listener
  late VoidCallback _contactsListener;
  // Contacts count
  int _contactosCount = 0;
  
  // Variables para ubicación
  String _ciudad = 'Obteniendo...';
  String _pais = '';
  bool _ubicacionCargando = true;
  Position? _lastLocation; // Guardar última ubicación conocida
  
  // Rate Limiting para botón de pánico
  static const String _panicButtonAction = 'panic_button_main';
  static const int _maxPanicAttempts = 4; // 4 intentos máximo
  static const int _panicLimitWindowMinutes = 2; // En 2 minutos
  
  // Estado del rate limit (para mostrar UI)
  RateLimitInfo? _rateLimitInfo;

  Future<void> _callNumber(BuildContext context, String number) async {
    final String normalized = _normalizePhone(number);
    final Uri uri = Uri(scheme: 'tel', path: normalized);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final ok = await launchUrl(uri);
      if (!mounted) return;
      if (!ok) {
        messenger.showSnackBar(const SnackBar(content: Text('No se pudo iniciar la llamada')));
      }
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  // Normalize phone numbers to Ecuador format (e.g. "0963522505" or "+593963522505" -> "0963522505")
  String _normalizePhone(String phone) {
    if (phone.isEmpty) return phone;
    return Validators.normalizePhoneNumber(phone);
  }

  void _startHold() {
    _holdTimer?.cancel();
    setState(() => _holdProgress = 0.0);
    final int tickMs = 50;
    _holdTimer = Timer.periodic(Duration(milliseconds: tickMs), (t) {
      setState(() {
        _holdProgress += tickMs / _holdDurationMs;
        if (_holdProgress >= 1.0) {
          _holdProgress = 1.0;
          t.cancel();
          _activateEmergency();
        }
      });
    });
  }

  void _cancelHold() {
    _holdTimer?.cancel();
    setState(() => _holdProgress = 0.0);
  }

  /// Actualizar información del rate limit
  Future<void> _updateRateLimitInfo() async {
    final info = await RateLimiter.getInfo(
      action: _panicButtonAction,
      maxAttempts: _maxPanicAttempts,
      windowMinutes: _panicLimitWindowMinutes,
    );
    
    if (mounted) {
      setState(() {
        _rateLimitInfo = info;
      });
    }
  }

  void _activateEmergency() async {
    print('[main._activateEmergency] INICIANDO ACTIVACIÓN DE EMERGENCIA');
    
    // Verificar rate limiting primero
    final canActivate = await RateLimiter.canExecute(
      action: _panicButtonAction,
      maxAttempts: _maxPanicAttempts,
      windowMinutes: _panicLimitWindowMinutes,
    );

    if (!canActivate) {
      // Si se alcanzó el límite, mostrar mensaje
      final rateLimitInfo = await RateLimiter.getInfo(
        action: _panicButtonAction,
        maxAttempts: _maxPanicAttempts,
        windowMinutes: _panicLimitWindowMinutes,
      );

      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Límite de intentos alcanzado. ${rateLimitInfo.readableInfo}'),
          duration: const Duration(seconds: 4),
          backgroundColor: Colors.red.shade700,
        ),
      );
      
      print('[main._activateEmergency] Rate limit alcanzado. ${rateLimitInfo.readableInfo}');
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) {
          setState(() => _holdProgress = 0.0);
          _updateRateLimitInfo();
        }
      });
      return;
    }

    // Si pasó el rate limit, proceder con la activación
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Alerta activada: notificando contactos y servicios')),
    );
    
    // Registrar evento en Firebase Analytics
    await FirebaseService.instance.logEvent('emergency_activated', {
      'timestamp': DateTime.now().toIso8601String(),
      'has_location': _lastLocation != null,
    });
    
    // Crear alerta en Firebase
    try {
      // Obtener CI del usuario desde secure storage
      // Si no hay CI configurado, usará 'user_default'
      await AlertService.instance.initializeFromStorage();
      
      final alertId = await AlertService.instance.createAlert(
        latitude: _lastLocation?.latitude,
        longitude: _lastLocation?.longitude,
        contactsNotified: [],
        description: 'Alerta de pánico activada',
        numberCalled: '',
      );
      
      print('[main._activateEmergency] Alerta guardada en Firebase con ID: $alertId');
      
      // Notificar a los contactos de emergencia
      await AlertService.instance.notifyContacts(
        alertId: alertId,
        latitude: _lastLocation?.latitude,
        longitude: _lastLocation?.longitude,
        description: 'Alerta de pánico activada - Se necesita ayuda inmediata',
      );
      
      print('[main._activateEmergency] Contactos notificados sobre la alerta');
    } catch (e) {
      print('[main._activateEmergency] ERROR al guardar alerta: $e');
      FirebaseService.instance.recordError(e, StackTrace.current, reason: 'Error al guardar alerta en Firebase');
    }
    
    // Añadir entrada al historial de alertas en OptionsPage (si existe)
    try {
      print('[main._activateEmergency] Intentando acceder a optionsPageKey.currentState');
      final dyn = optionsPageKey.currentState as dynamic;
      print('[main._activateEmergency] optionsPageKey.currentState obtenido: $dyn');
      
      if (dyn != null) {
        print('[main._activateEmergency] Llamando a addAlert...');
        dyn.addAlert(
          datetime: DateTime.now(),
          location: '',
          description: 'Alerta activada desde botón de pánico',
          status: 'Alerta'
        );
        print('[main._activateEmergency] addAlert llamado exitosamente');
      } else {
        print('[main._activateEmergency] ERROR: optionsPageKey.currentState es NULL');
      }
    } catch (e) {
      print('[main._activateEmergency] ERROR al llamar addAlert: $e');
      print('[main._activateEmergency] Stack trace: ${StackTrace.current}');
    }
    
    // Decide based on which small button is selected
    String numberToCall = '911';
    if (_mainFavoriteIndex == 1) {
      if (_preferredContact != null && (_preferredContact!['telefono']?.isNotEmpty ?? false)) {
        numberToCall = _preferredContact!['telefono']!;
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No hay contacto favorito en Ajustes; llamando a 911')));
        numberToCall = '911';
      }
    } else {
      numberToCall = '911';
    }
    
    print('[main._activateEmergency] Llamando al número: $numberToCall');
    _callNumber(context, numberToCall);
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() => _holdProgress = 0.0);
        _updateRateLimitInfo();
      }
    });
    print('[main._activateEmergency] FIN DE ACTIVACIÓN DE EMERGENCIA');
  }

  // Nueva función para obtener ubicación
  Future<void> _obtenerUbicacion({bool mostrarError = true}) async {
    print('[_obtenerUbicacion] iniciando obtención de ubicación...');
    
    if (mounted) {
      setState(() {
        _ubicacionCargando = true;
        _ciudad = 'Obteniendo...';
      });
    }
    
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('[_obtenerUbicacion] servicio de ubicación deshabilitado');
        if (mounted) {
          setState(() {
            _ciudad = 'Servicio deshabilitado';
            _pais = '';
            _ubicacionCargando = false;
          });
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      print('[_obtenerUbicacion] permiso actual: $permission');
      
      if (permission == LocationPermission.denied) {
        print('[_obtenerUbicacion] solicitando permiso...');
        permission = await Geolocator.requestPermission();
        print('[_obtenerUbicacion] permiso después de solicitud: $permission');
        
        if (permission == LocationPermission.denied) {
          if (mounted) {
            setState(() {
              _ciudad = 'Permiso denegado';
              _pais = '';
              _ubicacionCargando = false;
            });
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print('[_obtenerUbicacion] permisos negados permanentemente');
        if (mounted) {
          setState(() {
            _ciudad = 'Sin permisos';
            _pais = '';
            _ubicacionCargando = false;
          });
        }
        return;
      }

      print('[_obtenerUbicacion] obteniendo posición GPS...');
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
      
      print('[_obtenerUbicacion] posición obtenida: ${position.latitude}, ${position.longitude}');
      
      // Guardar la ubicación
      _lastLocation = position;

      print('[_obtenerUbicacion] obteniendo información de ubicación...');
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        print('[_obtenerUbicacion] placemark: ciudad=${place.locality}, país=${place.country}');
        
        if (mounted) {
          setState(() {
            _ciudad = place.locality ?? place.subAdministrativeArea ?? place.administrativeArea ?? 'Ubicación desconocida';
            _pais = place.country ?? '';
            _ubicacionCargando = false;
          });
        }
        print('[_obtenerUbicacion] ubicación actualizada correctamente: $_ciudad, $_pais');
      } else {
        print('[_obtenerUbicacion] sin placemarks disponibles');
        if (mounted) {
          setState(() {
            _ciudad = 'Ubicación desconocida';
            _pais = '';
            _ubicacionCargando = false;
          });
        }
      }
    } catch (e) {
      print('[_obtenerUbicacion] ERROR: $e');
      print('[_obtenerUbicacion] stack trace: ${StackTrace.current}');
      
      if (mounted) {
        setState(() {
          _ciudad = 'Error obteniendo ubicación';
          _pais = '';
          _ubicacionCargando = false;
        });
        
        // Mostrar notificación de error si es solicitado
        if (mostrarError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al obtener ubicación: $e'),
              duration: const Duration(seconds: 3),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    // remove notifier listeners to avoid calling setState after dispose
    try {
      preferredContact.removeListener(_preferredListener);
      allContacts.removeListener(_contactsListener);
    } catch (_) {}
    _holdTimer?.cancel();
    super.dispose();
  }

  // No _setMainFavorite: favorite is set from Settings only.

  // Preferred is now managed globally from Settings via `preferredContactNumber`.
  @override
  void initState() {
    super.initState();
    
    // Obtener ubicación al iniciar
    _obtenerUbicacion(mostrarError: false);
    
    // Cargar información del rate limit
    _updateRateLimitInfo();
    
    // Listen to global preferred contact from Settings
    _preferredListener = () {
      if (!mounted) return;
      setState(() {
        _preferredContact = preferredContact.value;
        // If no preferred contact exists but the main favorite index points to it, reset to 0 (911)
        if (_preferredContact == null && _mainFavoriteIndex == 1) {
          _mainFavoriteIndex = 0;
          // persist fallback
          SharedPreferences.getInstance().then((sp) => sp.setInt(_mainFavoriteKey, 0));
        }
      });
    };
    preferredContact.addListener(_preferredListener);
    
    // Listen to global contacts list
    _contactsListener = () {
      if (!mounted) return;
      setState(() {
        _contactosCount = allContacts.value.length;
      });
    };
    allContacts.addListener(_contactsListener);
    
    // Load persisted preferred contact (if any)
    loadPreferredContact();
    // Load persisted main favorite index
    SharedPreferences.getInstance().then((sp) {
      final val = sp.getInt(_mainFavoriteKey) ?? 0;
      if (mounted) {
        setState(() {
          _mainFavoriteIndex = val;
        });
      }
    });
    // No persisted main favorite index: the preferred contact from Settings
    // determines which contact will be called when appropriate.
  }

  Future<void> _setMainFavorite(int index) async {
    setState(() {
      _mainFavoriteIndex = index;
    });
    // persist selection
    try {
      final sp = await SharedPreferences.getInstance();
      await sp.setInt(_mainFavoriteKey, index);
    } catch (_) {}
    final label = index == 0 ? '911' : (_preferredContact?['nombre'] ?? 'Contacto');
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Botón seleccionado: $label')));
  }

  // Extracted helpers to reduce build size
  Widget _buildInfoCards(double cardHeight) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Expanded(
          child: SizedBox(
            height: cardHeight,
            child: Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Icon(Icons.contacts, color: Colors.purple, size: (cardHeight * 0.3).clamp(28.0, 36.0)),
                    const SizedBox(height: 8),
                    Text('Contactos', style: TextStyle(fontWeight: FontWeight.bold, fontSize: (cardHeight * 0.12).clamp(14.0, 16.0)), maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text('$_contactosCount Agregados', style: TextStyle(color: Colors.black54, fontSize: (cardHeight * 0.1).clamp(12.0, 13.0))),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SizedBox(
            height: cardHeight,
            child: GestureDetector(
              onTap: () {
                print('[_buildInfoCards] tap en tarjeta de ubicación');
                _obtenerUbicacion(mostrarError: true);
              },
              child: Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Icon(Icons.location_on, color: Colors.blue, size: (cardHeight * 0.3).clamp(28.0, 36.0)),
                          if (_ubicacionCargando)
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: SizedBox(
                                width: (cardHeight * 0.15).clamp(12.0, 16.0),
                                height: (cardHeight * 0.15).clamp(12.0, 16.0),
                                child: const CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Ubicación',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: (cardHeight * 0.12).clamp(14.0, 16.0),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _pais.isNotEmpty ? '$_ciudad, $_pais' : _ciudad,
                        style: TextStyle(
                          color: _ciudad == 'Obteniendo...' ? Colors.orange : Colors.black87,
                          fontSize: (cardHeight * 0.09).clamp(10.0, 12.0),
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomButtons(double buttonHeight) {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 7.0),
              child: SizedBox(
                height: buttonHeight,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    ElevatedButton(
                      onPressed: () => _setMainFavorite(0),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _mainFavoriteIndex == 0 ? Colors.orange : const Color.fromARGB(255, 9, 127, 238),
                        minimumSize: Size(0, buttonHeight),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.max,
                        children: const [
                          Icon(Icons.call, color: Colors.white, size: 22),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text('911', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold), textAlign: TextAlign.center, overflow: TextOverflow.ellipsis),
                          ),
                        ],
                      ),
                    ),
                    if (_mainFavoriteIndex == 0)
                      Positioned(
                        top: (buttonHeight * 0.06).clamp(3.0, 8.0),
                        right: (buttonHeight * 0.06).clamp(3.0, 8.0),
                        child: Container(
                          decoration: BoxDecoration(color: Colors.yellow.shade700, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)]),
                          padding: EdgeInsets.all((buttonHeight * 0.08).clamp(3.0, 6.0)),
                          child: Icon(Icons.star, size: (buttonHeight * 0.25).clamp(10.0, 18.0), color: Colors.white),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 7.0),
              child: SizedBox(
                height: buttonHeight,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    ElevatedButton(
                      onPressed: _preferredContact == null ? null : () => _setMainFavorite(1),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _mainFavoriteIndex == 1 ? Colors.orange : (_preferredContact == null ? Colors.grey : Colors.green),
                        minimumSize: Size(0, buttonHeight),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          const Icon(Icons.person, color: Colors.white, size: 22),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _preferredContact?['nombre'] ?? 'Sin contacto',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _preferredContact?['telefono'] ?? '',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_mainFavoriteIndex == 1 && _preferredContact != null)
                      Positioned(
                        top: (buttonHeight * 0.06).clamp(3.0, 8.0),
                        right: (buttonHeight * 0.06).clamp(3.0, 8.0),
                        child: Container(
                          decoration: BoxDecoration(color: Colors.yellow.shade700, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)]),
                          padding: EdgeInsets.all((buttonHeight * 0.08).clamp(3.0, 6.0)),
                          child: Icon(Icons.star, size: (buttonHeight * 0.25).clamp(10.0, 18.0), color: Colors.white),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Widget que muestra el estado del rate limit
  Widget _buildRateLimitIndicator() {
    if (_rateLimitInfo == null) {
      return const SizedBox.shrink();
    }

    final info = _rateLimitInfo!;
    final screenWidth = MediaQuery.of(context).size.width;
    final fontSize = (screenWidth * 0.035).clamp(12.0, 14.0);

    // Determinar color basado en estado
    Color textColor;
    String statusText;

    if (info.isLimited) {
      textColor = Colors.red;
      statusText = '⚠️ Límite alcanzado - ${info.readableInfo}';
    } else if (info.attemptsRemaining == 1) {
      textColor = Colors.orange;
      statusText = '⚠️ Intentos: ${info.attemptsUsed}/${info.maxAttempts} - Último intento disponible';
    } else {
      textColor = Colors.grey[700] ?? Colors.grey;
      statusText = '✓ Intentos: ${info.attemptsUsed}/${info.maxAttempts}';
    }

    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: Text(
        statusText,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: fontSize,
          color: textColor,
          fontWeight: info.isLimited ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Use responsive sizes to avoid overflow on small screens
    final media = MediaQuery.of(context);
    final double screenWidth = media.size.width;
    final height = media.size.height - media.padding.top - media.padding.bottom -  kToolbarHeight; // available roughly
    final double cardHeight = (height * 0.13).clamp(80.0, 120.0);
    final double emergencyDiameter = (height * 0.45).clamp(220.0, 320.0);
    final double progressDiameter = emergencyDiameter * 0.86;
    final double titleFontSize = (screenWidth * 0.045).clamp(16.0, 20.0);
    final double subtitleFontSize = (screenWidth * 0.035).clamp(12.0, 16.0);

    const double buttonBarHeight = 64.0;
    // responsive sizes for the two small buttons (calculated outside the widget tree)
    // buttons share space using Expanded; no per-button width constants required
    // buttons use Expanded now, no fixed per-button width calculation needed
    final double buttonHeight = (media.size.height * 0.07).clamp(44.0, 64.0);

    return Container(
      color: const Color(0xFFFFF5F6),
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 16, 16, media.padding.bottom + 12),
        child: SizedBox(
          height: media.size.height - media.padding.top - media.padding.bottom,
          child: Stack(
            children: <Widget>[
              SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.only(bottom: buttonBarHeight + 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        const CircleAvatar(backgroundColor: Colors.pink, radius: 22, child: Icon(Icons.person, color: Colors.white)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text('Bienvenido', style: TextStyle(fontSize: titleFontSize, fontWeight: FontWeight.bold)),
                              Text('Sistema de emergencia activo', style: TextStyle(fontSize: subtitleFontSize, color: Colors.black54)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildInfoCards(cardHeight),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: emergencyDiameter + 40,
                      child: Align(
                        alignment: const Alignment(0, 0.46),
                        child: Listener(
                          onPointerDown: (_) => _startHold(),
                          onPointerUp: (_) => _cancelHold(),
                          onPointerCancel: (_) => _cancelHold(),
                          child: Container(
                            width: emergencyDiameter,
                            height: emergencyDiameter,
                            decoration: BoxDecoration(
                              color: const Color.fromARGB(255, 240, 35, 20),
                              shape: BoxShape.circle,
                              boxShadow: [BoxShadow(color: Colors.red.withAlpha((0.45 * 255).round()), blurRadius: 18, spreadRadius: 4)],
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: <Widget>[
                                SizedBox(
                                  width: progressDiameter,
                                  height: progressDiameter,
                                  child: CircularProgressIndicator(
                                    value: _holdProgress,
                                    strokeWidth: (emergencyDiameter * 0.032).clamp(6.0, 12.0),
                                    color: Colors.white.withAlpha((0.95 * 255).round()),
                                    backgroundColor: Colors.white24,
                                  ),
                                ),
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    Icon(Icons.warning, size: (emergencyDiameter * 0.18).clamp(40.0, 80.0), color: Colors.white),
                                    const SizedBox(height: 12),
                                    Text('EMERGENCIA', style: TextStyle(color: Colors.white, fontSize: (emergencyDiameter * 0.06).clamp(16.0, 22.0), fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 6),
                                    Text('Mantén presionado para activar', style: TextStyle(color: Colors.white70, fontSize: (emergencyDiameter * 0.035).clamp(12.0, 16.0))),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: (media.size.height * 0.02).clamp(8.0, 50.0),
                child: _buildRateLimitIndicator(),
              ),
              Positioned(
                left: 16,
                right: 16,
                bottom: (media.size.height * 0.12).clamp(12.0, 140.0),
                child: _buildBottomButtons(buttonHeight),
              ),
            ],
          ),
        ),
      ),
    );
  }
}