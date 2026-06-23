import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

/// Modelo para contacto de emergencia con su FCM token
class EmergencyContact {
  final String name;
  final String phone;
  final String? fcmToken; // Token FCM para recibir notificaciones

  EmergencyContact({
    required this.name,
    required this.phone,
    this.fcmToken,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'phone': phone,
    'fcmToken': fcmToken,
  };

  factory EmergencyContact.fromJson(Map<String, dynamic> json) {
    return EmergencyContact(
      name: json['name'] as String,
      phone: json['phone'] as String,
      fcmToken: json['fcmToken'] as String?,
    );
  }
}

/// Servicio para gestionar contactos de emergencia y sus tokens FCM
class ContactService {
  static final ContactService _instance = ContactService._internal();
  
  late final FlutterSecureStorage _secureStorage;

  ContactService._internal();

  factory ContactService.instance() {
    return _instance;
  }

  void initialize() {
    _secureStorage = const FlutterSecureStorage();
  }

  /// Obtener todos los contactos de emergencia
  Future<List<EmergencyContact>> getContacts() async {
    try {
      final jsonStr = await _secureStorage.read(key: 'emergency_contacts');
      if (jsonStr == null || jsonStr.isEmpty) {
        return [];
      }

      final List<dynamic> jsonList = jsonDecode(jsonStr);
      return jsonList
          .map((json) => EmergencyContact.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('[ContactService.getContacts] ERROR: $e');
      return [];
    }
  }

  /// Agregar o actualizar un contacto
  Future<void> addContact(EmergencyContact contact) async {
    try {
      final contacts = await getContacts();
      
      // Buscar si el contacto ya existe (por teléfono)
      final index = contacts.indexWhere((c) => c.phone == contact.phone);
      
      if (index >= 0) {
        // Actualizar
        contacts[index] = contact;
      } else {
        // Agregar
        contacts.add(contact);
      }

      final jsonList = contacts.map((c) => c.toJson()).toList();
      await _secureStorage.write(
        key: 'emergency_contacts',
        value: jsonEncode(jsonList),
      );
      
      print('[ContactService.addContact] Contacto agregado: ${contact.name}');
    } catch (e) {
      print('[ContactService.addContact] ERROR: $e');
      rethrow;
    }
  }

  /// Remover un contacto por teléfono
  Future<void> removeContact(String phone) async {
    try {
      final contacts = await getContacts();
      contacts.removeWhere((c) => c.phone == phone);

      if (contacts.isEmpty) {
        await _secureStorage.delete(key: 'emergency_contacts');
      } else {
        final jsonList = contacts.map((c) => c.toJson()).toList();
        await _secureStorage.write(
          key: 'emergency_contacts',
          value: jsonEncode(jsonList),
        );
      }
      
      print('[ContactService.removeContact] Contacto removido: $phone');
    } catch (e) {
      print('[ContactService.removeContact] ERROR: $e');
      rethrow;
    }
  }

  /// Obtener todos los tokens FCM de los contactos (para enviar notificaciones)
  Future<List<String>> getAllContactFcmTokens() async {
    try {
      final contacts = await getContacts();
      return contacts
          .where((c) => c.fcmToken != null && c.fcmToken!.isNotEmpty)
          .map((c) => c.fcmToken!)
          .toList();
    } catch (e) {
      print('[ContactService.getAllContactFcmTokens] ERROR: $e');
      return [];
    }
  }

  /// Actualizar el token FCM de un contacto
  Future<void> updateContactFcmToken(String phone, String fcmToken) async {
    try {
      final contacts = await getContacts();
      final contact = contacts.firstWhere(
        (c) => c.phone == phone,
        orElse: () => throw Exception('Contacto no encontrado'),
      );

      // Crear contacto actualizado
      final updatedContact = EmergencyContact(
        name: contact.name,
        phone: contact.phone,
        fcmToken: fcmToken,
      );

      await addContact(updatedContact);
      print('[ContactService.updateContactFcmToken] Token actualizado para: $phone');
    } catch (e) {
      print('[ContactService.updateContactFcmToken] ERROR: $e');
    }
  }

  /// Limpiar todos los contactos
  Future<void> clearAllContacts() async {
    try {
      await _secureStorage.delete(key: 'emergency_contacts');
      print('[ContactService.clearAllContacts] Todos los contactos removidos');
    } catch (e) {
      print('[ContactService.clearAllContacts] ERROR: $e');
    }
  }
}
