# Patrones de Diseño Utilizados
**Versión:** 1.0 | **Fecha:** 21 de diciembre de 2025 | **Estado:** Implementados
---
## Índice
1. [Introducción](#introducción)
2. [Singleton Pattern](#singleton-pattern)
3. [Repository Pattern](#repository-pattern)
4. [Service Locator Pattern](#service-locator-pattern)
5. [Observer Pattern](#observer-pattern)
6. [State Management Pattern](#state-management-pattern)
7. [Factory Pattern](#factory-pattern)
8. [Dependency Injection Pattern](#dependency-injection-pattern)
9. [Comparativa de Patrones](#comparativa-de-patrones)
---
## Introducción
Los **patrones de diseño** son soluciones probadas a problemas comunes en desarrollo de software. El proyecto utiliza **7 patrones principales** para garantizar código limpio, mantenible y escalable.
### Por qué usar patrones?
- Código más legible
- Facilita mantenimiento
- Reutilización de soluciones
- Comunicación entre desarrolladores
- Menos bugs y errores
---
## Singleton Pattern
### Definición
Garantiza que una clase tenga **una única instancia** en toda la aplicación y proporciona un punto de acceso global a esa instancia.
### Implementación
```dart
class FirebaseService {
 // Variable estática privada que guarda la instancia única
 static final FirebaseService _instance =
 FirebaseService._internal();
 // Constructor privado para evitar instanciación directa
 FirebaseService._internal();
 // Getter público para acceder a la instancia
 static FirebaseService get instance => _instance;
 // Métodos del servicio
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
| Servicio | Ubicación | Propósito |
|----------|-----------|----------|
| **FirebaseService** | `lib/services/firebase_service.dart` | Instancia única de Firebase |
| **AlertService** | `lib/services/alert_service.dart` | Gestión centralizada de alertas |
| **NotificationService** | `lib/services/notification_service.dart` | Notificaciones |
### Ventajas
 **Una única instancia** - Uso eficiente de memoria
 **Acceso global** - Disponible desde cualquier parte
 **Inicialización lazy** - Se crea solo cuando se necesita
 **Thread-safe** - Seguro en programación multi-hilo (si se implementa correctamente)
### Desventajas
 **Dependencia global** - Difícil de testear
 **Oculta dependencias** - No se ve claramente qué necesita qué
 **Anti-patrón si se abusa** - Puede llevar a código acoplado
### Alternativas
```dart
// Opción 2: Usar GetIt (Service Locator más robusto)
import 'package:get_it/get_it.dart';
final getIt = GetIt.instance;
void main() {
 getIt.registerSingleton<FirebaseService>(FirebaseService());
}
// Uso
FirebaseService firebaseService = getIt<FirebaseService>();
```
---
## Repository Pattern
### Definición
Abstrae la lógica de acceso a datos y proporciona una interfaz limpia para operaciones CRUD (Create, Read, Update, Delete).
### Implementación
```dart
// Abstracto (interfaz)
abstract class AlertRepository {
 Future<String> createAlert({
 required double latitude,
 required double longitude,
 required String description,
 });
 Future<List<Alert>> getUserAlerts();
 Future<void> updateAlertStatus(String alertId, AlertStatus status);
}
// Implementación concreta
class FirebaseAlertRepository implements AlertRepository {
 final _database = FirebaseDatabase.instance.ref();
 @override
 Future<String> createAlert({
 required double latitude,
 required double longitude,
 required String description,
 }) async {
 // Lógica de creación
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
 String _generateId() => DateTime.now().millisecondsSinceEpoch.toString();
}
```
### Uso en el Proyecto
```dart
// En AlertService
class AlertService {
 final _repository = FirebaseAlertRepository();
 Future<String> createAlert({...}) async {
 return await _repository.createAlert(...);
 }
}
```
### Ventajas
 **Abstracción de datos** - UI no conoce detalles de BD
 **Fácil de cambiar** - Cambiar Firebase por Firestore sin afectar servicios
 **Testeable** - Puede mockearse la interfaz
 **Separación de responsabilidades** - Cada capa hace su trabajo
### Desventajas
 **Más clases** - Más código que mantener
 **Overhead** - Llamadas indirectas pueden ser más lentas
 **Complejidad inicial** - Curva de aprendizaje
---
## Service Locator Pattern
### Definición
Proporciona un **registro centralizado** de servicios y permite acceder a ellos desde cualquier parte sin pasar dependencias explícitamente.
### Implementación
```dart
// Registro en main.dart
void main() async {
 WidgetsFlutterBinding.ensureInitialized();
 // Inicializar y registrar servicios
 await FirebaseService.instance.initialize();
 await AlertService.instance.initializeFromStorage();
 await NotificationService.instance.initialize();
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
 // Acceso directo sin necesidad de pasar parámetros
 await AlertService.instance.createAlert(...);
 FirebaseService.instance.logEvent('emergency', {});
 }
 @override
 Widget build(BuildContext context) {
 return Scaffold(
 body: GestureDetector(
 onLongPress: _activateEmergency,
 child: Center(child: Text('Botón de Pánico')),
 ),
 );
 }
}
```
### Ventajas
 **Acceso simple** - No requiere inyección explícita
 **Menos parámetros** - Constructores más limpios
 **Flexible** - Fácil agregar o cambiar servicios
### Desventajas
 **Dependencia global implícita** - No se ve qué necesita qué
 **Difícil de testear** - Necesita mockear servicios globales
 **Acoplamiento** - Los widgets dependen de servicios globales
---
## Observer Pattern
### Definición
Define una relación **uno a muchos** donde cuando un objeto cambia, todos los observadores se notifican automáticamente.
### Implementación
```dart
// Usando ValueNotifier
class Preferences {
 // Observables
 static final isDarkMode = ValueNotifier<bool>(false);
 static final selectedLanguage = ValueNotifier<String>('es');
 static final isNotificationsEnabled = ValueNotifier<bool>(true);
}
// Widget observador
class SettingsPage extends StatefulWidget {
 @override
 State<SettingsPage> createState() => _SettingsPageState();
}
class _SettingsPageState extends State<SettingsPage> {
 @override
 void initState() {
 super.initState();
 // Escuchar cambios
 Preferences.isDarkMode.addListener(_onThemeChanged);
 Preferences.selectedLanguage.addListener(_onLanguageChanged);
 }
 void _onThemeChanged() {
 print('Tema cambió a: ${Preferences.isDarkMode.value}');
 setState(() {
 // Actualizar UI
 });
 }
 void _onLanguageChanged() {
 print('Idioma cambió a: ${Preferences.selectedLanguage.value}');
 setState(() {
 // Actualizar UI
 });
 }
 @override
 void dispose() {
 // Detener de escuchar
 Preferences.isDarkMode.removeListener(_onThemeChanged);
 Preferences.selectedLanguage.removeListener(_onLanguageChanged);
 super.dispose();
 }
 @override
 Widget build(BuildContext context) {
 return Scaffold(
 body: Column(
 children: [
 // Opción 1: Escuchar manualmente
 Text('Tema: ${Preferences.isDarkMode.value}'),
 // Opción 2: Usar ValueListenableBuilder
 ValueListenableBuilder<bool>(
 valueListenable: Preferences.isDarkMode,
 builder: (context, isDark, child) {
 return Switch(
 value: isDark,
 onChanged: (value) {
 Preferences.isDarkMode.value = value;
 },
 );
 },
 ),
 // Opción 3: Usar AnimatedBuilder
 AnimatedBuilder(
 animation: Preferences.selectedLanguage,
 builder: (context, child) {
 return Text('Idioma: ${Preferences.selectedLanguage.value}');
 },
 ),
 ],
 ),
 );
 }
}
```
### Ventajas
 **Reactividad** - UI se actualiza automáticamente
 **Desacoplamiento** - No hay referencias directas
 **Flexible** - Múltiples observadores sin impacto
### Desventajas
 **Complejo de debuggear** - Difícil rastrear cambios
 **Overhead de memoria** - Manteniendo listeners activos
 **Riesgo de memory leaks** - Si no se limpian listeners
---
## State Management Pattern
### Definición
Gestiona el **estado local** de un widget usando `setState()` para actualizar la UI cuando el estado cambia.
### Implementación
```dart
class InicioPage extends StatefulWidget {
 @override
 State<InicioPage> createState() => _InicioPageState();
}
class _InicioPageState extends State<InicioPage> {
 // Estado local
 double _holdProgress = 0.0;
 int _remainingAttempts = 3;
 String? _errorMessage;
 Position? _lastLocation;
 bool _isLoading = false;
 // Métodos que modifican estado
 void _updateHoldProgress(double progress) {
 setState(() {
 _holdProgress = progress;
 });
 }
 void _activateEmergency() async {
 setState(() {
 _isLoading = true;
 _errorMessage = null;
 });
 try {
 // Lógica de negocio
 await AlertService.instance.createAlert(...);
 setState(() {
 _remainingAttempts--;
 _holdProgress = 0.0;
 });
 } catch (e) {
 setState(() {
 _errorMessage = 'Error: ${e.toString()}';
 });
 } finally {
 setState(() {
 _isLoading = false;
 });
 }
 }
 @override
 Widget build(BuildContext context) {
 return Scaffold(
 appBar: AppBar(title: Text('Emergencia')),
 body: Column(
 children: [
 // Mostrar error si existe
 if (_errorMessage != null)
 Container(
 color: Colors.red,
 padding: EdgeInsets.all(16),
 child: Text(_errorMessage!, style: TextStyle(color: Colors.white)),
 ),
 // Mostrar indicador de intentos
 Text('Intentos: $_remainingAttempts/3'),
 // Mostrar progreso
 LinearProgressIndicator(value: _holdProgress),
 // Mostrar indicador de carga
 if (_isLoading) CircularProgressIndicator(),
 // Botón de pánico
 GestureDetector(
 onLongPress: _activateEmergency,
 onHorizontalDragUpdate: (details) {
 _updateHoldProgress(details.delta.dx / 100);
 },
 child: Container(
 width: 100,
 height: 100,
 decoration: BoxDecoration(
 shape: BoxShape.circle,
 color: Colors.red,
 ),
 child: Center(
 child: Text(
 'PÁNICO',
 style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
 ),
 ),
 ),
 ),
 ],
 ),
 );
 }
}
```
### Ventajas
 **Simple** - Sin librerías adicionales
 **Control total** - Sabes exactamente qué se actualiza
 **Performance aceptable** - Para estado simple/medio
### Desventajas
 **Verboso** - Muchos setState() calls
 **Escalabilidad limitada** - Difícil con estado complejo
 **Performance** - Si hay muchos widgets, puede ser lento
### Alternativas
```dart
// GetX
Get.put(Controller());
GetBuilder<Controller>(
 builder: (controller) => Text(controller.state),
);
// BLoC
BlocBuilder<MyBloc, MyState>(
 builder: (context, state) => Text(state.value),
);
// Riverpod
final myProvider = StateNotifierProvider((ref) => MyController());
```
---
## Factory Pattern
### Definición
Define una interfaz para **crear objetos**, permitiendo que las subclases decidan qué clase instanciar.
### Implementación
```dart
class Alert {
 final String id;
 final DateTime timestamp;
 final double latitude;
 final double longitude;
 final String description;
 final AlertStatus status;
 Alert({
 required this.id,
 required this.timestamp,
 required this.latitude,
 required this.longitude,
 required this.description,
 required this.status,
 });
 // Factory: crear desde JSON
 factory Alert.fromJson(Map<String, dynamic> json) {
 return Alert(
 id: json['id'] as String,
 timestamp: DateTime.parse(json['timestamp'] as String),
 latitude: json['location']['lat'] as double,
 longitude: json['location']['lon'] as double,
 description: json['description'] as String,
 status: AlertStatus.values.firstWhere(
 (e) => e.toString() == 'AlertStatus.${json['status']}',
 ),
 );
 }
 // Factory: crear con valores por defecto
 factory Alert.empty() {
 return Alert(
 id: '',
 timestamp: DateTime.now(),
 latitude: 0.0,
 longitude: 0.0,
 description: '',
 status: AlertStatus.active,
 );
 }
 // Factory: crear para testing
 factory Alert.mock({
 String id = 'mock_1',
 String description = 'Alerta de prueba',
 }) {
 return Alert(
 id: id,
 timestamp: DateTime.now(),
 latitude: -0.3522,
 longitude: -78.5249,
 description: description,
 status: AlertStatus.active,
 );
 }
 // Convertir a JSON
 Map<String, dynamic> toJson() => {
 'id': id,
 'timestamp': timestamp.toIso8601String(),
 'location': {'lat': latitude, 'lon': longitude},
 'description': description,
 'status': status.toString().split('.').last,
 };
}
// Uso
Alert alert1 = Alert.fromJson(jsonData);
Alert alert2 = Alert.empty();
Alert alert3 = Alert.mock(description: 'Alerta de testing');
```
### Ventajas
 **Flexibilidad** - Múltiples formas de crear objetos
 **Encapsulación** - Lógica de creación centralizada
 **Testeable** - Factory.mock() para tests
---
## Dependency Injection Pattern
### Definición
**Inyecta dependencias** a través de constructores o métodos en lugar de que la clase las cree internamente.
### Implementación: Inyección por Constructor
```dart
// Versión básica (sin inyección)
class InicioPage extends StatefulWidget {
 @override
 State<InicioPage> createState() => _InicioPageState();
}
class _InicioPageState extends State<InicioPage> {
 void _activateEmergency() async {
 // Acceso directo a singleton
 await AlertService.instance.createAlert(...);
 }
}
// Versión mejorada (con inyección)
class InicioPage extends StatefulWidget {
 final AlertService alertService;
 final RateLimiter rateLimiter;
 final FirebaseService firebaseService;
 const InicioPage({
 required this.alertService,
 required this.rateLimiter,
 required this.firebaseService,
 });
 @override
 State<InicioPage> createState() => _InicioPageState();
}
class _InicioPageState extends State<InicioPage> {
 void _activateEmergency() async {
 // Usar inyectado
 final canExecute = await widget.rateLimiter.canExecute(...);
 if (canExecute) {
 await widget.alertService.createAlert(...);
 widget.firebaseService.logEvent('emergency', {});
 }
 }
 @override
 Widget build(BuildContext context) {
 return Scaffold(...);
 }
}
// Uso en main.dart
InicioPage(
 alertService: AlertService.instance,
 rateLimiter: RateLimiter(),
 firebaseService: FirebaseService.instance,
)
```
### Ventajas
 **Testeable** - Fácil mockear dependencias
 **Explícito** - Se ve claramente qué necesita qué
 **Flexible** - Cambiar implementación sin afectar widget
### Desventajas
 **Verboso** - Muchos parámetros en constructor
 **Complejo** - Múltiples niveles de inyección
 **Boilerplate** - Mucho código repetitivo
---
## Comparativa de Patrones
| Patrón | Uso | Ventaja Principal | Desventaja Principal |
|--------|-----|-------------------|----------------------|
| **Singleton** | Servicios únicos | Acceso global | Dependencia global |
| **Repository** | Acceso a datos | Abstracción | Más clases |
| **Service Locator** | Registro de servicios | Flexible | Difícil de testear |
| **Observer** | Reactividad | UI automática | Memory leaks posibles |
| **State Management** | Estado local | Simple | No escalable |
| **Factory** | Crear objetos | Flexibilidad | Oculta lógica |
| **Dependency Injection** | Pasar dependencias | Testeable | Verboso |
---
## Combinación de Patrones en el Proyecto
```
 CAPA DE PRESENTACIÓN (UI)
 Usa: State Management + Observer
 CAPA DE SERVICIOS
 Usa: Singleton + Service Locator + Repository
 CAPA DE DATOS
 Usa: Repository + Factory
```
---
## Resumen
| Patrón | Ubicación | Nivel de Uso |
|--------|-----------|--------------|
| **Singleton** | FirebaseService, AlertService | Alto |
| **Repository** | AlertService Firebase | Medio-Alto |
| **Service Locator** | main.dart | Alto |
| **Observer** | Preferences, ValueNotifier | Medio |
| **State Management** | Todos los widgets | Alto |
| **Factory** | Alert, Validators | Medio |
| **Dependency Injection** | Alternativa a Singleton | Bajo (Optional) |
---
## Conclusión
El proyecto utiliza una **combinación estratégica** de patrones:
- **Singletons** para servicios
- **Repository** para datos
- **Service Locator** para acceso global
- **Observer** para reactividad
- **State Management** para UI
- **Factory** para creación de objetos
- **Dependency Injection** (opcional, para testing)
Esta combinación proporciona un **código limpio, mantenible y escalable**.
---
**Última actualización:** 21 de julio de 2026
**Versión:** 1.3.47
**Estado:** Desarrollo
