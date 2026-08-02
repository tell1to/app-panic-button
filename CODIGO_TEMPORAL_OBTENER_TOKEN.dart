// 📋 CÓDIGO TEMPORAL PARA OBTENER TOKEN FCM
// 
// Propósito: Obtener y mostrar el token FCM en los logs
// Instrucciones:
//   1. Copia este archivo
//   2. Reemplaza el contenido de lib/main.dart con este código
//   3. Ejecuta: flutter run
//   4. Busca en los logs: "🎯 MI TOKEN FCM:"
//   5. Copia el token
//   6. Restaura main.dart original
//
// ═════════════════════════════════════════════════════════════════════════════

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
  }
  
  // Inicializar NotificationService
  try {
    await NotificationService.instance().initialize();
    print('[main] NotificationService inicializado correctamente');
  } catch (e) {
    print('[main] ERROR al inicializar NotificationService: $e');
  }
  
  // 🔥 OBTENER Y MOSTRAR TOKEN FCM (TEMPORAL)
  try {
    await Future.delayed(const Duration(seconds: 1)); // Esperar a que se inicialice
    String? token = await NotificationService.instance().getFCMToken();
    print('═══════════════════════════════════════════════════════════════');
    print('🎯 MI TOKEN FCM:');
    print('');
    print(token ?? 'NO DISPONIBLE');
    print('');
    print('📋 Para probar notificaciones:');
    print('   1. Ve a: https://console.firebase.google.com/');
    print('   2. Selecciona tu proyecto');
    print('   3. Cloud Messaging → Enviar mensaje');
    print('   4. Pega este token como dispositivo específico');
    print('═══════════════════════════════════════════════════════════════');
  } catch (e) {
    print('❌ Error al obtener token FCM: $e');
  }
  
  runApp(const MyApp());
}

// ... [REST OF main.dart CONTINUES AS NORMAL] ...
// El resto del archivo main.dart permanece igual
