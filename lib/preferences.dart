import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Holds the preferred contact as a small map: { 'nombre': ..., 'telefono': ... }
// Null means no preferred contact (fallback to 911).
final ValueNotifier<Map<String, String>?> preferredContact = ValueNotifier<Map<String, String>?>(null);

const _prefNameKey = 'preferred_name';
const _prefPhoneKey = 'preferred_phone';

Future<void> loadPreferredContact() async {
	final sp = await SharedPreferences.getInstance();
	final name = sp.getString(_prefNameKey);
	final phone = sp.getString(_prefPhoneKey);
	if (name != null && phone != null && phone.isNotEmpty) {
		preferredContact.value = {'nombre': name, 'telefono': phone};
	} else {
		preferredContact.value = null;
	}
}

Future<void> setPreferredContact(Map<String, String>? contact) async {
	preferredContact.value = contact;
	final sp = await SharedPreferences.getInstance();
	if (contact == null) {
		await sp.remove(_prefNameKey);
		await sp.remove(_prefPhoneKey);
	} else {
		await sp.setString(_prefNameKey, contact['nombre'] ?? '');
		await sp.setString(_prefPhoneKey, contact['telefono'] ?? '');
	}
}
