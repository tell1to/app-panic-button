import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_application_1/screens/settings_page.dart';
import 'package:flutter_application_1/utils/preferences.dart';

void main() {
  setUp(() {
    // Resetear los notificadores globales entre tests
    allContacts.value = [];
    preferredContact.value = null;
  });

  Future<void> pumpSettingsPage(
    WidgetTester tester, {
    Map<String, Object> prefs = const {},
  }) async {
    SharedPreferences.setMockInitialValues(prefs);
    await tester.pumpWidget(const MaterialApp(home: SenttingsPage()));
    await tester.pumpAndSettle();
  }

  Future<void> openContactDialog(WidgetTester tester) async {
    final addButton = find.text('Agregar contacto');
    await tester.ensureVisible(addButton);
    await tester.pumpAndSettle();
    await tester.tap(addButton);
    await tester.pumpAndSettle();
  }

  Future<void> fillContactForm(
    WidgetTester tester, {
    required String nombre,
    required String telefono,
  }) async {
    await tester.enterText(
      find.widgetWithText(TextField, 'Nombre del responsable'),
      nombre,
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Número de teléfono'),
      telefono,
    );
    await tester.pump();
  }

  Future<void> tapGuardar(WidgetTester tester) async {
    await tester.tap(find.widgetWithText(ElevatedButton, 'Guardar'));
    await tester.pumpAndSettle();
  }

  group('Validación de contactos duplicados', () {
    testWidgets(
        'muestra popup al guardar el mismo número de un contacto existente',
        (tester) async {
      final existing = jsonEncode({'nombre': 'Juan', 'telefono': '0963522505'});
      await pumpSettingsPage(tester, prefs: {'user_contacts': [existing]});

      await openContactDialog(tester);
      await fillContactForm(tester, nombre: 'Pedro', telefono: '0963522505');
      await tapGuardar(tester);

      // Aparece el popup de número duplicado
      expect(find.text('Número duplicado'), findsOneWidget);
      expect(find.textContaining('no se puede colocar'), findsOneWidget);

      // El diálogo de contacto sigue abierto (no se guardó)
      expect(find.text('Nuevo contacto'), findsOneWidget);

      // Cerrar popup y diálogo: la lista sigue con un solo contacto
      await tester.tap(find.text('Aceptar'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cerrar'));
      await tester.pumpAndSettle();

      expect(find.text('Juan'), findsOneWidget);
      expect(find.text('Pedro'), findsNothing);
    });

    testWidgets('detecta duplicado aunque el teléfono use formato +593',
        (tester) async {
      final existing = jsonEncode({'nombre': 'Juan', 'telefono': '0963522505'});
      await pumpSettingsPage(tester, prefs: {'user_contacts': [existing]});

      await openContactDialog(tester);
      await fillContactForm(tester, nombre: 'Pedro', telefono: '+593963522505');
      await tapGuardar(tester);

      expect(find.text('Número duplicado'), findsOneWidget);
      expect(find.textContaining('no se puede colocar'), findsOneWidget);
    });

    testWidgets('permite guardar un número nuevo sin popup', (tester) async {
      final existing = jsonEncode({'nombre': 'Juan', 'telefono': '0963522505'});
      await pumpSettingsPage(tester, prefs: {'user_contacts': [existing]});

      await openContactDialog(tester);
      await fillContactForm(tester, nombre: 'Pedro', telefono: '0999999999');
      await tapGuardar(tester);

      // No aparece popup y el diálogo se cierra (el contacto se guardó)
      expect(find.text('Número duplicado'), findsNothing);
      expect(find.text('Nuevo contacto'), findsNothing);

      // La lista muestra el nuevo contacto junto al existente
      expect(find.text('Juan'), findsOneWidget);
      expect(find.text('Pedro'), findsOneWidget);
      expect(find.text('0999999999'), findsOneWidget);
    });
  });
}
