import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../utils/preferences.dart';
import '../utils/validators/validators.dart';
import '../services/secure_storage_service.dart';

const String _tutorialCompletedKey = 'tutorial_completed';

class TutorialScreen extends StatefulWidget {
  final VoidCallback onTutorialComplete;

  const TutorialScreen({super.key, required this.onTutorialComplete});

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();

  /// Verificar si el tutorial ya fue completado
  static Future<bool> isTutorialCompleted() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getBool(_tutorialCompletedKey) ?? false;
  }

  /// Marcar tutorial como completado
  static Future<void> markTutorialCompleted() async {
    final sp = await SharedPreferences.getInstance();
    await sp.setBool(_tutorialCompletedKey, true);
  }
}

class _TutorialScreenState extends State<TutorialScreen> {
  late PageController _pageController;
  int _currentPage = 0;

  // Variables para datos del tutorial
  String _nombres = '';
  String _apellidos = '';
  String _ci = '';
  String _edad = '';
  String _tipoSangre = '';
  String _contactoNombre = '';
  String _contactoTelefono = '';
  String _telefonoError = '';

  final List<String> tiposSangre = [
    'O+', 'O-', 'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-'
  ];

  /// Validar formato de teléfono ecuatoriano
  /// Acepta: 09XXXXXXXX (10 dígitos) o +593XXXXXXXXX (14 caracteres)
  bool _isValidPhoneNumber(String phone) {
    if (phone.isEmpty) return true; // Campo vacío es permitido
    
    // Remover espacios
    phone = phone.replaceAll(' ', '');
    
    // Validar si comienza con +593
    if (phone.startsWith('+593')) {
      // +593 + 9 dígitos = 14 caracteres totales
      // Verificar que el resto solo contenga dígitos
      String digitsOnly = phone.replaceAll('+593', '');
      if (digitsOnly.length == 9 && RegExp(r'^\d+$').hasMatch(digitsOnly)) {
        return true;
      }
      return false;
    }
    
    // Validar si comienza con 09
    if (phone.startsWith('09')) {
      // 09 + 8 dígitos = 10 caracteres totales
      String digitsOnly = phone.replaceAll(RegExp(r'^09'), '');
      if (digitsOnly.length == 8 && RegExp(r'^\d+$').hasMatch(digitsOnly)) {
        return true;
      }
      return false;
    }
    
    return false; // No comienza con 09 ni +593
  }

  /// Obtener mensaje de error para el teléfono
  String _getPhoneErrorMessage(String phone) {
    if (phone.isEmpty) return '';
    
    phone = phone.replaceAll(' ', '');
    
    if (phone.startsWith('+593')) {
      String digitsOnly = phone.replaceAll('+593', '');
      if (digitsOnly.length < 9) {
        return 'Faltan ${9 - digitsOnly.length} dígito(s)';
      }
      if (digitsOnly.length > 9) {
        return 'Sobran ${digitsOnly.length - 9} carácter(es)';
      }
      if (!RegExp(r'^\d+$').hasMatch(digitsOnly)) {
        return 'Solo se permiten dígitos después de +593';
      }
      return '';
    }
    
    if (phone.startsWith('09')) {
      String digitsOnly = phone.replaceAll(RegExp(r'^09'), '');
      if (digitsOnly.length < 8) {
        return 'Faltan ${8 - digitsOnly.length} dígito(s)';
      }
      if (digitsOnly.length > 8) {
        return 'Sobran ${digitsOnly.length - 8} carácter(es)';
      }
      if (!RegExp(r'^\d+$').hasMatch(digitsOnly)) {
        return 'Solo se permiten dígitos';
      }
      return '';
    }
    
    return 'Debe empezar con 09 o +593';
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _completeTutorial() async {
    // Guardar datos de perfil
    try {
      final sp = await SharedPreferences.getInstance();

      // Guardar perfil (nombres, apellidos, CI, edad, tipo de sangre)
      if (_nombres.isNotEmpty) {
        await sp.setString('profile_nombres', _nombres);
      }
      if (_apellidos.isNotEmpty) {
        await sp.setString('profile_apellidos', _apellidos);
      }
      if (_ci.isNotEmpty) {
        await sp.setString('profile_ci', _ci);
        await SecureStorageService.saveCI(_ci);
        // IMPORTANTE: Marcar que el CI ya fue establecido (no se puede cambiar después)
        await sp.setBool('ci_already_set', true);
      }
      if (_edad.isNotEmpty) {
        await sp.setString('profile_edad', _edad);
      }
      if (_tipoSangre.isNotEmpty) {
        await sp.setString('profile_blood_type', _tipoSangre);
      }

      // Guardar contacto si fue agregado y validado
      if (_contactoNombre.isNotEmpty && _contactoTelefono.isNotEmpty && _isValidPhoneNumber(_contactoTelefono)) {
        final Map<String, String> contact = {
          'nombre': _contactoNombre,
          'telefono': _contactoTelefono,
        };

        // Normalizar el teléfono para compararlo con contactos existentes
        final telefonoNormalizado = Validators.normalizePhoneNumber(_contactoTelefono);

        // Agregar a lista de contactos (solo si el número no está duplicado)
        final raw = sp.getStringList('user_contacts') ?? [];
        final esDuplicado = raw.any((jsonContact) {
          try {
            final Map<String, dynamic> m = jsonDecode(jsonContact) as Map<String, dynamic>;
            final otroTelefono = Validators.normalizePhoneNumber(m['telefono']?.toString() ?? '');
            return otroTelefono == telefonoNormalizado;
          } catch (_) {
            return false;
          }
        });

        if (esDuplicado) {
          print('[Tutorial] Contacto omitido: el número $telefonoNormalizado ya existe en otro contacto');
        } else {
          raw.add(jsonEncode(contact));
          await sp.setStringList('user_contacts', raw);

          // Establecer como contacto preferido
          await sp.setString('preferred_name', _contactoNombre);
          await sp.setString('preferred_phone', _contactoTelefono);
          await sp.setInt('preferred_index', 0);

          // Actualizar ValueNotifier de preferencias
          allContacts.value = [contact];
          preferredContact.value = {
            'nombre': _contactoNombre,
            'telefono': _contactoTelefono,
            'index': 0,
          };
        }
      }

      // Marcar tutorial como completado
      await TutorialScreen.markTutorialCompleted();

      print('[Tutorial] Datos guardados y tutorial completado');
      widget.onTutorialComplete();
    } catch (e) {
      print('[Tutorial] ERROR al completar tutorial: $e');
    }
  }

  void _nextPage() {
    if (_currentPage < 5) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeTutorial();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _skipTutorial() {
    _completeTutorial();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        onPageChanged: (index) {
          setState(() {
            _currentPage = index;
          });
        },
        children: [
          // Página 0: Bienvenida
          _buildWelcomePage(),
          // Página 1: Navegación
          _buildNavigationPage(),
          // Página 2: Perfil Personal
          _buildProfilePage(),
          // Página 3: Contacto de Emergencia
          _buildEmergencyContactPage(),
          // Página 4: Módulo Opciones
          _buildOptionsModulePage(),
          // Página 5: Pantalla de Inicio
          _buildStartPage(),
        ],
      ),
    );
  }

  // ==================== PÁGINA 0: BIENVENIDA ====================
  Widget _buildWelcomePage() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFE63946), Color(0xFFC1121F)],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const SizedBox(height: 60),
          Column(
            children: [
              // Animación del escudo
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: 1),
                duration: const Duration(milliseconds: 800),
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: 0.5 + (value * 0.5),
                    child: Opacity(
                      opacity: value,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.shield,
                          size: 80,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 30),
              Text(
                '¡Bienvenido!',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 15),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Text(
                  'En menos de 2 minutos configuraremos tu app para que estés protegido en cualquier emergencia',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.9),
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 40),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: ElevatedButton(
                      onPressed: _nextPage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Comenzar',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFE63946),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                TextButton(
                  onPressed: _skipTutorial,
                  child: Text(
                    'Saltar tutorial',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== PÁGINA 1: NAVEGACIÓN ====================
  Widget _buildNavigationPage() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFE63946), Color(0xFFC1121F)],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 60, left: 20, right: 20),
            child: Column(
              children: [
                Icon(
                  Icons.navigation,
                  size: 60,
                  color: Colors.white,
                ),
                const SizedBox(height: 20),
                Text(
                  'Tres secciones',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 15),
                Text(
                  'Tu app cuenta con todo lo que necesitas para mantenerte seguro',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
              child: Column(
                children: [
                  _buildNavigationCard(
                    icon: Icons.home,
                    title: 'Inicio',
                    description: 'Botón de pánico y contactos de emergencia rápidos',
                    color: Colors.red,
                  ),
                  const SizedBox(height: 15),
                  _buildNavigationCard(
                    icon: Icons.medical_services,
                    title: 'Opciones',
                    description: 'Tus datos médicos, citas y medicamentos',
                    color: Colors.blue,
                  ),
                  const SizedBox(height: 15),
                  _buildNavigationCard(
                    icon: Icons.person,
                    title: 'Ajustes',
                    description: 'Tu perfil, contactos y preferencias',
                    color: Colors.green,
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _nextPage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Siguiente',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFE63946),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== PÁGINA 2: PERFIL PERSONAL ====================
  Widget _buildProfilePage() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFE63946), Color(0xFFC1121F)],
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 60, left: 20, right: 20),
            child: Column(
              children: [
                Icon(
                  Icons.person_outline,
                  size: 60,
                  color: Colors.white,
                ),
                const SizedBox(height: 20),
                Text(
                  'Tu perfil personal',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Estos datos son vitales en una emergencia',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  TextField(
                    onChanged: (value) => _nombres = value,
                    decoration: InputDecoration(
                      hintText: 'Tu nombre',
                      prefixIcon: Icon(Icons.person),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    onChanged: (value) => _apellidos = value,
                    decoration: InputDecoration(
                      hintText: 'Tu apellido',
                      prefixIcon: Icon(Icons.person),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    onChanged: (value) => _ci = value,
                    decoration: InputDecoration(
                      hintText: 'Cédula de Identidad (CI)',
                      prefixIcon: Icon(Icons.badge),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    onChanged: (value) => _edad = value,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'Tu edad',
                      prefixIcon: Icon(Icons.cake),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButton<String>(
                      value: _tipoSangre.isEmpty ? null : _tipoSangre,
                      hint: Text('Tipo de sangre'),
                      isExpanded: true,
                      underline: SizedBox(),
                      items: tiposSangre.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _tipoSangre = newValue ?? '';
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 30),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.yellow.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.yellow[700]!,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info,
                          color: Colors.yellow[700],
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Los datos de emergencia podría serán los detalles datos más relevantes para salvar vidas',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.blue[300]!,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.edit,
                          color: Colors.blue[300],
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Dentro de la app puedes agregar y modificar más campos, ES IMPORTANTE QUE LO HAGA',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
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
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _previousPage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.3),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text('Anterior',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _nextPage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Siguiente',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFE63946),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== PÁGINA 3: CONTACTO DE EMERGENCIA ====================
  Widget _buildEmergencyContactPage() {
  return Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFFE63946),
          Color.fromARGB(255, 193, 24, 18),
        ],
      ),
    ),
    child: Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 60, left: 20, right: 20),
          child: Column(
            children: [
              const Icon(
                Icons.phone_in_talk,
                size: 60,
                color: Colors.white,
              ),
              const SizedBox(height: 20),
              const Text(
                'Contacto de emergencia',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Agrega alguien de confianza a quien contactar en caso de emergencia',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.amber.shade300,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.amber.shade200,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'El primer contacto se asignará automáticamente como favorito',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.95),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                TextField(
                  onChanged: (value) => _contactoNombre = value,
                  decoration: InputDecoration(
                    hintText: 'Nombre del contacto',
                    hintStyle: TextStyle(
                      color: Colors.grey.shade500,
                    ),
                    prefixIcon: Icon(
                      Icons.person,
                      color: Colors.grey.shade600,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.grey.shade300,
                        width: 1.5,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Colors.blue,
                        width: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                TextField(
                  onChanged: (value) {
                    setState(() {
                      _contactoTelefono = value;
                      _telefonoError = _getPhoneErrorMessage(value);
                    });
                  },
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    hintText: 'Teléfono (+593 o 09...)',
                    hintStyle: TextStyle(
                      color: Colors.grey.shade500,
                    ),
                    prefixIcon: Icon(
                      Icons.phone,
                      color: _telefonoError.isNotEmpty
                          ? Colors.red.shade700
                          : Colors.grey.shade600,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: _telefonoError.isNotEmpty
                            ? Colors.red.shade700
                            : Colors.grey.shade300,
                        width: 1.5,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: _telefonoError.isNotEmpty
                            ? Colors.red.shade700
                            : Colors.blue,
                        width: 2,
                      ),
                    ),
                  ),
                ),
                if (_telefonoError.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.white54,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: Colors.amberAccent,
                            size: 22,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Número no válido',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _telefonoError,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _previousPage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.25),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Anterior',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _contactoTelefono.isEmpty ||
                          _isValidPhoneNumber(_contactoTelefono)
                      ? _nextPage
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade300,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Siguiente',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _contactoTelefono.isEmpty ||
                              _isValidPhoneNumber(_contactoTelefono)
                          ? const Color(0xFFE63946)
                          : Colors.grey,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

  // ==================== PÁGINA 4: MÓDULO OPCIONES ====================
  Widget _buildOptionsModulePage() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFE63946), Color(0xFFC1121F)],
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 60, left: 20, right: 20),
            child: Column(
              children: [
                Icon(
                  Icons.medical_services_outlined,
                  size: 60,
                  color: Colors.white,
                ),
                const SizedBox(height: 20),
                Text(
                  'Módulo de Opciones',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Gestiona tu información médica y de emergencia',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
              child: Column(
                children: [
                  _buildOptionsModuleCard(
                    icon: Icons.health_and_safety,
                    title: 'Condiciones médicas',
                    description: 'Enfermedades diagnosticadas',
                  ),
                  const SizedBox(height: 15),
                  _buildOptionsModuleCard(
                    icon: Icons.medication,
                    title: 'Medicamentos',
                    description: 'Tus medicinas actuales',
                  ),
                  const SizedBox(height: 15),
                  _buildOptionsModuleCard(
                    icon: Icons.calendar_today,
                    title: 'Citas médicas',
                    description: 'Recordatorios de citas',
                  ),
                  const SizedBox(height: 15),
                  _buildOptionsModuleCard(
                    icon: Icons.warning,
                    title: 'Alergias',
                    description: 'Alérgenos que debes evitar',
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _previousPage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.3),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text('Anterior',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _nextPage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Siguiente',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFE63946),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionsModuleCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Color(0xFFE63946).withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Color(0xFFE63946), size: 28),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== PÁGINA 5: PANTALLA DE INICIO ====================
  Widget _buildStartPage() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFE63946), Color(0xFFC1121F)],
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 60, left: 20, right: 20),
            child: Column(
              children: [
                Icon(
                  Icons.home,
                  size: 60,
                  color: Colors.white,
                ),
                const SizedBox(height: 20),
                Text(
                  'Pantalla de Inicio',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Tu centro de control en emergencias',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.emergency,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Botón de Pánico',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Mantén presionado para activar una emergencia. Se notificará a tus contactos favoritos seleccionados.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.85),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 25),
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.call,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Llamada 911',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Acceso rápido al servicio de emergencias. Disponible en la barra inferior.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.85),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 25),
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.favorite,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Contacto Favorito',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tu contacto de confianza principal. Aparece destacado en la pantalla principal.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.85),
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _previousPage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.3),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text('Anterior',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _completeTutorial,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          '¡Comenzar!',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFE63946),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


}
