import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Holds the preferred contact as a small map: { 'nombre': ..., 'telefono': ..., 'index': ... }
// Null means no preferred contact (fallback to 911).
final ValueNotifier<Map<String, dynamic>?> preferredContact = ValueNotifier<Map<String, dynamic>?>(null);

// Holds the list of all contacts - used to sync across the app
final ValueNotifier<List<Map<String, String>>> allContacts = ValueNotifier<List<Map<String, String>>>([]);

const _prefNameKey = 'preferred_name';
const _prefPhoneKey = 'preferred_phone';
const _prefIndexKey = 'preferred_index';

Future<void> loadPreferredContact() async {
	final sp = await SharedPreferences.getInstance();
	final index = sp.getInt(_prefIndexKey);
	final name = sp.getString(_prefNameKey);
	final phone = sp.getString(_prefPhoneKey);
	if (index != null && index >= 0) {
		preferredContact.value = {'nombre': name ?? '', 'telefono': phone ?? '', 'index': index};
	} else {
		preferredContact.value = null;
	}
}

Future<void> setPreferredContact(Map<String, dynamic>? contact) async {
	preferredContact.value = contact;
	final sp = await SharedPreferences.getInstance();
	if (contact == null) {
		await sp.remove(_prefNameKey);
		await sp.remove(_prefPhoneKey);
		await sp.remove(_prefIndexKey);
	} else {
		await sp.setString(_prefNameKey, contact['nombre'] ?? '');
		await sp.setString(_prefPhoneKey, contact['telefono'] ?? '');
		await sp.setInt(_prefIndexKey, contact['index'] ?? -1);
	}
}
