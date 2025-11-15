import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'options.dart';
import 'senttings.dart';

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

  static const List<Widget> _pages = <Widget>[
    const InicioPage(),
    const OptionsPage(),
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

  Future<void> _callNumber(BuildContext context, String number) async {
    final Uri uri = Uri(scheme: 'tel', path: number);
    try {
      if (!await launchUrl(uri)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo iniciar la llamada')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
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
    Future.delayed(const Duration(milliseconds: 800), () {
      setState(() => _holdProgress = 0.0);
    });
  }

  @override
  void dispose() {
    _holdTimer?.cancel();
    super.dispose();
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
                  const CircleAvatar(child: Icon(Icons.person, color: Colors.white), backgroundColor: Colors.pink, radius: 22),
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
              Row(
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
                              Text('2 activos', style: TextStyle(color: Colors.black54, fontSize: (cardHeight * 0.1).clamp(12.0, 13.0))),
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
                              Text('Ubicación', style: TextStyle(fontWeight: FontWeight.bold, fontSize: (cardHeight * 0.12).clamp(14.0, 16.0)), maxLines: 1, overflow: TextOverflow.ellipsis),
                              Text('Activa', style: TextStyle(color: Colors.black54, fontSize: (cardHeight * 0.1).clamp(12.0, 13.0))),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
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
                        color: Colors.red,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: Colors.red.withOpacity(0.45), blurRadius: 18, spreadRadius: 4)],
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
                              color: Colors.white.withOpacity(0.95),
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
                bottom: media.padding.bottom + 12,
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _callNumber(context, '911'),
                        icon: const Icon(Icons.call),
                        label: const Text('911'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          minimumSize: const Size.fromHeight(56),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _callNumber(context, '+1234567890'),
                        icon: const Icon(Icons.phone),
                        label: const Text('Contacto 1'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          minimumSize: const Size.fromHeight(56),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
