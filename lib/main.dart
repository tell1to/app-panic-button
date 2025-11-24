import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

import 'options.dart';
import 'senttings.dart';
import 'preferences.dart';

// Global key to access OptionsPage state so other pages (Inicio) can add alerts
final GlobalKey optionsPageKey = GlobalKey();

void main() {
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

  // pages built here so we can pass the GlobalKey to OptionsPage
  final List<Widget> _pages = <Widget>[
    const InicioPage(),
    OptionsPage(key: optionsPageKey),
    const SenttingsPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: _pages.elementAt(_selectedIndex)),
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
        onTap: _onItemTapped,
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
  
  // Variables para ubicación
  String _ciudad = 'Obteniendo...';
  String _pais = '';
  bool _ubicacionCargando = true;

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

  // Normalize phone numbers to digits and leading + (e.g. "+51 9 1234 567" -> "+5191234567")
  String _normalizePhone(String phone) {
    if (phone.isEmpty) return phone;
    return phone.replaceAll(RegExp(r'[^+\d]'), '');
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

  void _activateEmergency() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Alerta activada: notificando contactos y servicios')),
    );
    // Aquí podríamos añadir lógica adicional: compartir ubicación, enviar SMS, llamar a contacto, etc.
    // Añadir entrada al historial de alertas en OptionsPage (si existe)
    try {
      final dyn = optionsPageKey.currentState as dynamic;
      dyn?.addAlert(datetime: DateTime.now(), location: '', description: 'Alerta activada desde botón de pánico', status: 'Alerta');
    } catch (_) {}
    // Decide based on which small button is selected
    String numberToCall = '911';
    if (_mainFavoriteIndex == 1) {
      if (_preferredContact != null && (_preferredContact!['telefono']?.isNotEmpty ?? false)) {
        numberToCall = _preferredContact!['telefono']!;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No hay contacto favorito en Ajustes; llamando a 911')));
        numberToCall = '911';
      }
    } else {
      numberToCall = '911';
    }
    _callNumber(context, numberToCall);
    Future.delayed(const Duration(milliseconds: 800), () {
      setState(() => _holdProgress = 0.0);
    });
  }

  // Nueva función para obtener ubicación
  Future<void> _obtenerUbicacion() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
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
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
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
        if (mounted) {
          setState(() {
            _ciudad = 'Sin permisos';
            _pais = '';
            _ubicacionCargando = false;
          });
        }
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty && mounted) {
        Placemark place = placemarks[0];
        setState(() {
          _ciudad = place.locality ?? place.subAdministrativeArea ?? 'Desconocida';
          _pais = place.country ?? '';
          _ubicacionCargando = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _ciudad = 'Error de ubicación';
          _pais = '';
          _ubicacionCargando = false;
        });
      }
    }
  }

  @override
  void dispose() {
    // remove notifier listener to avoid calling setState after dispose
    try {
      preferredContact.removeListener(_preferredListener);
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
    _obtenerUbicacion();
    
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
                    Text('2 Agregados', style: TextStyle(color: Colors.black54, fontSize: (cardHeight * 0.1).clamp(12.0, 13.0))),
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
            child: Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Icon(Icons.location_on, color: Colors.blue, size: (cardHeight * 0.3).clamp(28.0, 36.0)),
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
                    // Mostrar ubicacion en una sola línea para evitar overflow
                    _ubicacionCargando
                        ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2))
                        : Text(
                            _pais.isNotEmpty ? '$_ciudad, $_pais' : _ciudad,
                            style: TextStyle(
                              color: Colors.black87,
                              fontSize: (cardHeight * 0.1).clamp(11.0, 13.0),
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                  ],
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
                        top: 6,
                        right: 6,
                        child: Container(
                          decoration: BoxDecoration(color: Colors.yellow.shade700, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)]),
                          padding: const EdgeInsets.all(6),
                          child: const Icon(Icons.star, size: 20, color: Colors.white),
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
                        top: 6,
                        right: 6,
                        child: Container(
                          decoration: BoxDecoration(color: Colors.yellow.shade700, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)]),
                          padding: const EdgeInsets.all(6),
                          child: const Icon(Icons.star, size: 20, color: Colors.white),
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

  @override
  Widget build(BuildContext context) {
    // Use responsive sizes to avoid overflow on small screens
    final media = MediaQuery.of(context);
    final height = media.size.height - media.padding.top - media.padding.bottom -  kToolbarHeight; // available roughly
    final double cardHeight = (height * 0.13).clamp(80.0, 120.0);
    final double emergencyDiameter = (height * 0.45).clamp(220.0, 320.0);
    final double progressDiameter = emergencyDiameter * 0.86;

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
                            children: const <Widget>[
                              Text('Bienvenido', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              Text('Sistema de emergencia activo', style: TextStyle(color: Colors.black54)),
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