# Patrones de Diseño Utilizados

**Version:** 1.4.67  
**Fecha:** 20 de agosto de 2026  
**Estado:** Implementados

---

## Indice

1. [Introduccion](#introduccion)
2. [Singleton Pattern](#singleton-pattern)
3. [Repository Pattern](#repository-pattern)
4. [Service Locator Pattern](#service-locator-pattern)
5. [Observer Pattern](#observer-pattern)
6. [State Management Pattern](#state-management-pattern)
7. [Factory Pattern](#factory-pattern)
8. [Dependency Injection Pattern](#dependency-injection-pattern)
9. [Comparativa de Patrones](#comparativa-de-patrones)

---

## Introduccion

Los **patrones de diseño** son soluciones probadas a problemas comunes en desarrollo de software. El proyecto utiliza **7 patrones principales** para garantizar codigo limpio, mantenible y escalable.

### Por que usar patrones?

- Codigo mas legible
- Facilita mantenimiento
- Reutilizacion de soluciones
- Comunicacion entre desarrolladores
- Menos bugs y errores

---

## Singleton Pattern

### Definicion

Garantiza que una clase tenga **una unica instancia** en toda la aplicacion y proporciona un punto de acceso global a esa instancia.

### Implementacion

```dart
class FirebaseService {
  // Variable estatica privada que guarda la instancia unica
  static final FirebaseService _instance = 
    FirebaseService._internal();
  
  // Constructor privado para evitar instanciacion directa
  FirebaseService._internal();
  
  // Getter publico para acceder a la instancia
  static FirebaseService get instance => _instance;
  
  // Metodos del servicio
  Future<void> initialize() async {
    print('Inicializando Firebase...');
  }
  
  void logEvent(String name, Map<String, dynamic> data) {
    print('Evento registrado: $name');
  }
}

// Uso
await FirebaseService.instance.initialize();
FirebaseService.instance.logEvent('evento', {});
```

### Uso en el Proyecto

| Servicio | Ubicacion | Proposito |
|----------|-----------|----------|
| **FirebaseService** | `lib/services/firebase_service.dart` | Instancia unica de Firebase |
| **AlertService** | `lib/services/alert_service.dart` | Gestion centralizada de alertas |
| **AppointmentReminderService** | `lib/services/appointment_reminder_service.dart` | Recordatorios de citas |
| **NotificationService** | `lib/services/notification_service.dart` | Notificaciones |
| **SecureStorageService** | `lib/services/secure_storage_service.dart` | Almacenamiento seguro |
| **EncryptionService** | `lib/services/encryption_service.dart` | Encriptacion |

### Ventajas

- **Una unica instancia** - Uso eficiente de memoria
- **Acceso global** - Disponible desde cualquier parte
- **Inicializacion lazy** - Se crea solo cuando se necesita
- **Thread-safe** - Seguro en programacion multi-hilo

### Desventajas

- **Dependencia global** - Dificil de testear
- **Oculta dependencias** - No se ve claramente que necesita que
- **Anti-patron si se abusa** - Puede llevar a codigo acoplado

---

## Repository Pattern

### Definicion

Abstrae la logica de acceso a datos y proporciona una interfaz limpia para operaciones CRUD (Create, Read, Update, Delete).

### Implementacion

```dart
// Abstracto (interfaz)
abstract class AlertRepository {
  Future<String> createAlert({
    required double latitude,
    required double longitude,
    required String description,
  });
  
  Future<List<Alert>> getUserAlerts();
  
  Future<void> updateAlertStatus(
    String alertId, 
    AlertStatus status
  );
}

// Implementacion concreta
class FirebaseAlertRepository implements AlertRepository {
  final _database = FirebaseDatabase.instance.ref();
  
  @override
  Future<String> createAlert({
    required double latitude,
    required double longitude,
    required String description,
  }) async {
    final alertId = _generateId();
    await _database
      .child('alerts')
      .child(alertId)
      .set({
        'timestamp': DateTime.now().toIso8601String(),
        'location': {'lat': latitude, 'lon': longitude},
        'description': description,
        'status': 'active',
      });
    return alertId;
  }
  
  @override
  Future<List<Alert>> getUserAlerts() async {
    final snapshot = await _database.child('alerts').get();
    List<Alert> alerts = [];
    for (var child in snapshot.children) {
      alerts.add(Alert.fromJson(child.value as Map));
    }
    return alerts;
  }
  
  @override
  Future<void> updateAlertStatus(
    String alertId,
    AlertStatus status,
  ) async {
    await _database
      .child('alerts')
      .child(alertId)
      .update({'status': status.toString()});
  }
  
  String _generateId() => 
    DateTime.now().millisecondsSinceEpoch.toString();
}
```

### Ventajas

- **Abstraccion de datos** - UI no conoce detalles de BD
- **Facil de cambiar** - Cambiar Firebase por Firestore sin afectar servicios
- **Testeable** - Puede mockearse la interfaz
- **Separacion de responsabilidades** - Cada capa hace su trabajo

---

## Service Locator Pattern

### Definicion

Proporciona un **registro centralizado** de servicios y permite acceder a ellos desde cualquier parte sin pasar dependencias explicitamente.

### Implementacion

```dart
// Registro en main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar y registrar servicios
  await FirebaseService.instance.initialize();
  await AlertService.instance.initializeFromStorage();
  await NotificationService.instance.initialize();
  await AppointmentReminderService.instance.initialize();
  
  // Servicios ahora disponibles globalmente
  runApp(const MyApp());
}

// Uso desde cualquier widget
class InicioPage extends StatefulWidget {
  @override
  State<InicioPage> createState() => _InicioPageState();
}

class _InicioPageState extends State<InicioPage> {
  void _activateEmergency() async {
    // Acceso directo sin necesidad de pasar parametros
    await AlertService.instance.createAlert(...);
    FirebaseService.instance.logEvent('emergency', {});
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onLongPress: _activateEmergency,
        child: Center(child: Text('Boton de Panico')),
      ),
    );
  }
}
```

---

## Observer Pattern

### Definicion

Define una relacion de **uno-a-muchos** entre objetos de manera que cuando uno cambia de estado, todos los que dependen de el se notifican automaticamente.

### Implementacion en el Proyecto

```dart
// En preferences.dart
final ValueNotifier<Map<String, dynamic>?> preferredContact = 
  ValueNotifier(null);

final ValueNotifier<List<Map<String, String>>> allContacts = 
  ValueNotifier([]);

// En settings_page.dart
void _updatePreferredContact(Map<String, dynamic> contact) {
  preferredContact.value = contact;
}

// En main.dart (escuchar cambios)
preferredContact.addListener(() {
  print('Contacto preferido cambio: ${preferredContact.value}');
});

// En Widget (construir reactivamente)
ValueListenableBuilder<Map<String, dynamic>?>(
  valueListenable: preferredContact,
  builder: (context, contact, child) {
    return Text('Contacto: ${contact?['nombre'] ?? 'No definido'}');
  },
)
```

### Ventajas

- **Desacoplamiento** - Observadores no necesitan conocer al sujeto
- **Reactividad** - UI se actualiza automaticamente
- **Multiples observadores** - Muchos widgets pueden escuchar

---

## State Management Pattern

### Definicion

Maneja el estado de la aplicacion de manera centralizada y organizada.

### Implementacion en el Proyecto

```dart
// Pagina con estado local (StatefulWidget)
class SettingsPage extends StatefulWidget {
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // Estado local
  String _nombres = '';
  String _apellidos = '';
  List<Map<String, String>> _contactos = [];
  
  @override
  void initState() {
    super.initState();
    _loadData(); // Cargar datos persistidos
  }
  
  Future<void> _loadData() async {
    // Cargar desde storage
    setState(() {
      _nombres = 'Juan';
      _apellidos = 'Garcia';
    });
  }
  
  Future<void> _saveData() async {
    // Guardar cambios
    await _persistToStorage();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          TextField(
            onChanged: (value) {
              setState(() => _nombres = value);
            },
          ),
          ElevatedButton(
            onPressed: _saveData,
            child: Text('Guardar'),
          ),
        ],
      ),
    );
  }
}
```

---

## Factory Pattern

### Definicion

Proporciona una interfaz para crear objetos sin especificar sus clases concretas.

### Implementacion

```dart
// Interfaz
abstract class Alert {
  String id;
  DateTime timestamp;
  String description;
}

// Implementaciones concretas
class LocalAlert implements Alert {
  @override
  String id;
  @override
  DateTime timestamp;
  @override
  String description;
  
  LocalAlert({required this.id, required this.timestamp, required this.description});
}

class CloudAlert implements Alert {
  @override
  String id;
  @override
  DateTime timestamp;
  @override
  String description;
  
  CloudAlert({required this.id, required this.timestamp, required this.description});
}

// Factory
class AlertFactory {
  static Alert createAlert({
    required String type, // 'local' o 'cloud'
    required String id,
    required DateTime timestamp,
    required String description,
  }) {
    if (type == 'local') {
      return LocalAlert(id: id, timestamp: timestamp, description: description);
    } else if (type == 'cloud') {
      return CloudAlert(id: id, timestamp: timestamp, description: description);
    }
    throw Exception('Tipo de alerta desconocido: $type');
  }
}
```

---

## Dependency Injection Pattern

### Definicion

Proporciona a un objeto las dependencias que necesita en lugar de crear las instancias internamente.

### Implementacion

```dart
// Sin DI (acoplado)
class AlertService {
  final _database = FirebaseDatabase.instance;
  
  void createAlert() {
    // Usa FirebaseDatabase directamente (acoplado)
  }
}

// Con DI (desacoplado)
class AlertService {
  final AlertRepository _repository;
  
  AlertService(this._repository); // Inyeccion en constructor
  
  void createAlert() {
    // Usa repository (desacoplado)
    _repository.save(...);
  }
}

// Uso
final repository = FirebaseAlertRepository();
final alertService = AlertService(repository);
```

---

## Comparativa de Patrones

| Patron | Proposito | Ventaja | Desventaja | Usado En |
|--------|-----------|---------|-----------|----------|
| **Singleton** | Instancia unica | Acceso global simple | Dificil de testear | FirebaseService, AlertService |
| **Repository** | Abstraccion datos | Facil cambiar BD | Mas codigo | AlertService |
| **Service Locator** | Registro central | Flexible, descentralizado | Acoplamiento global | main.dart |
| **Observer** | Notificacion cambios | Reactividad UI | Puede ser confuso | preferences.dart, ValueNotifier |
| **State Management** | Gestion estado | Organizado | Puede crecer mucho | StatefulWidget |
| **Factory** | Crear objetos | Abstrae creacion | Complejidad extra | AlertFactory |
| **Dependency Injection** | Inyectar dependencias | Desacoplamiento | Requiere mas codigo | Servicios |

---

**Nota:** La combinacion de estos patrones permite mantener el codigo limpio, escalable y facil de testear.

**Ultimo cambio:** 20 de agosto de 2026 - Agregado AppointmentReminderService y EncryptionService.
