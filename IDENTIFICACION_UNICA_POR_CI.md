# 🔐 Sistema de Identificación Única por CI - Implementación Completa

**Fecha:** 22 de diciembre de 2025  
**Estado:** ✅ IMPLEMENTADO Y COMPILADO  
**Cambios:** 3 archivos modificados

---

## 📋 Resumen del Cambio

### ❌ ANTES (Problema)
```
Todos los usuarios → alerts/user_default/ ← SOBRESCRITURA DE DATOS
Todos los usuarios → misma rama en Firebase
```

### ✅ DESPUÉS (Solución)
```
Usuario 1 (CI: 1234567890) → alerts/1234567890/alert_001
Usuario 2 (CI: 0987654321) → alerts/0987654321/alert_001
Usuario 3 (CI: 1111111111) → alerts/1111111111/alert_001
Cada usuario mantiene SUS PROPIAS alertas
```

---

## 🔧 Cambios Implementados

### 1. `secure_storage_service.dart` ✅

**Se agregaron:**
```dart
// Nuevas claves
static const String _ciKey = 'user_ci';
static const String _firstNameKey = 'user_first_name';
static const String _lastNameKey = 'user_last_name';
static const String _ageKey = 'user_age';
static const String _diseasesKey = 'user_diseases';

// Nuevos métodos
saveCI(String ci)                                    // Guardar CI
getCI()                                              // Obtener CI
saveUserProfile({ci, firstName, lastName, age})     // Guardar perfil completo
getUserProfile()                                     // Obtener perfil completo
hasCompleteProfile()                                 // Verificar si hay perfil
getUserId()                                          // ⭐ CLAVE: Retorna CI o user_default
```

### 2. `alert_service.dart` ✅

**Se agregó nuevo método:**
```dart
initializeFromStorage()  // Inicializa automáticamente desde CI guardado en secure_storage
```

**Cambio en estructura:**
- Ahora el `_userId` se obtiene del CI del usuario
- Si no hay CI, fallback a `user_default`
- Las alertas se guardan en: `alerts/{CI_DEL_USUARIO}/alert_001`

### 3. `main.dart` ✅

**Cambio en `_activateEmergency()`:**
```dart
// ANTES:
final userId = 'user_default';
await AlertService.instance.initialize(userId);

// AHORA:
await AlertService.instance.initializeFromStorage();
// Automáticamente usa el CI del usuario
```

---

## 📱 Cómo Usar (Guía para el Usuario)

### Paso 1: Ir a Settings
1. Abre la app
2. Ve a pestaña **"Ajustes"** (última pestaña)

### Paso 2: Llenar Formulario de Perfil
Aquí es donde necesitas **agregar un formulario** en `senttings.dart`:

```
┌─────────────────────────────┐
│ DATOS DEL USUARIO          │
├─────────────────────────────┤
│ Cédula de Identidad*        │ [1234567890    ]
│ Nombre*                     │ [Juan          ]
│ Apellido*                   │ [Pérez         ]
│ Edad*                       │ [35            ]
│ Enfermedades (checkbox)     │
│   ☑ Hipertensión           │
│   ☐ Diabetes               │
│   ☐ Asma                   │
│   ☐ Otra                   │
├─────────────────────────────┤
│     [GUARDAR]     [CANCELAR]│
└─────────────────────────────┘
```

### Paso 3: Guardar
Cuando el usuario presiona **"GUARDAR"**:
```dart
await SecureStorageService.saveUserProfile(
  ci: '1234567890',
  firstName: 'Juan',
  lastName: 'Pérez',
  age: '35',
  diseases: '["Hipertensión"]', // JSON string
);
```

### Paso 4: Usar el Botón de Pánico
Ahora cuando presiona el botón:
1. Se lee el CI desde secure_storage
2. Se crea la alerta en: `alerts/1234567890/alert_001`
3. Firebase ahora tiene alertas identificadas por usuario

---

## 🏗️ Estructura Firebase (Nueva)

```json
{
  "alerts": {
    "1234567890": {
      "alert_001": {
        "id": "alert_001",
        "userId": "1234567890",
        "timestamp": 1702641600000,
        "latitude": 0.2206,
        "longitude": -78.4872,
        "status": "active",
        "description": "Alerta de pánico activada"
      },
      "alert_002": { ... }
    },
    "0987654321": {
      "alert_001": { ... }
    },
    "user_default": {
      "alert_001": { ... }  // Para usuarios sin CI configurado
    }
  }
}
```

---

## 💻 Implementación en `senttings.dart` (Próximo Paso)

Necesitas agregar un formulario similar a esto:

```dart
class SenttingsPage extends StatefulWidget {
  @override
  State<SenttingsPage> createState() => _SenttingsPageState();
}

class _SenttingsPageState extends State<SenttingsPage> {
  late TextEditingController _ciController;
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _ageController;
  List<String> _selectedDiseases = [];

  @override
  void initState() {
    super.initState();
    _ciController = TextEditingController();
    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();
    _ageController = TextEditingController();
    _loadUserProfile(); // Cargar datos si existen
  }

  Future<void> _loadUserProfile() async {
    final profile = await SecureStorageService.getUserProfile();
    if (mounted) {
      setState(() {
        _ciController.text = profile['ci'] ?? '';
        _firstNameController.text = profile['firstName'] ?? '';
        _lastNameController.text = profile['lastName'] ?? '';
        _ageController.text = profile['age'] ?? '';
        // Parsear diseases JSON
        try {
          if (profile['diseases'] != null) {
            _selectedDiseases = jsonDecode(profile['diseases']);
          }
        } catch (e) {
          print('Error parsing diseases: $e');
        }
      });
    }
  }

  Future<void> _saveUserProfile() async {
    if (_ciController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La cédula es requerida')),
      );
      return;
    }

    try {
      await SecureStorageService.saveUserProfile(
        ci: _ciController.text,
        firstName: _firstNameController.text,
        lastName: _lastNameController.text,
        age: _ageController.text,
        diseases: jsonEncode(_selectedDiseases),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Perfil guardado correctamente')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error al guardar: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Campos de entrada
              TextField(
                controller: _ciController,
                decoration: const InputDecoration(
                  labelText: 'Cédula de Identidad',
                  hintText: 'Ej: 1234567890',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _firstNameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _lastNameController,
                decoration: const InputDecoration(
                  labelText: 'Apellido',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _ageController,
                decoration: const InputDecoration(
                  labelText: 'Edad',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 24),
              
              // Checkbox de enfermedades
              const Text('Enfermedades:', style: TextStyle(fontWeight: FontWeight.bold)),
              CheckboxListTile(
                title: const Text('Hipertensión'),
                value: _selectedDiseases.contains('Hipertensión'),
                onChanged: (bool? value) {
                  setState(() {
                    if (value == true) {
                      _selectedDiseases.add('Hipertensión');
                    } else {
                      _selectedDiseases.remove('Hipertensión');
                    }
                  });
                },
              ),
              CheckboxListTile(
                title: const Text('Diabetes'),
                value: _selectedDiseases.contains('Diabetes'),
                onChanged: (bool? value) {
                  setState(() {
                    if (value == true) {
                      _selectedDiseases.add('Diabetes');
                    } else {
                      _selectedDiseases.remove('Diabetes');
                    }
                  });
                },
              ),
              CheckboxListTile(
                title: const Text('Asma'),
                value: _selectedDiseases.contains('Asma'),
                onChanged: (bool? value) {
                  setState(() {
                    if (value == true) {
                      _selectedDiseases.add('Asma');
                    } else {
                      _selectedDiseases.remove('Asma');
                    }
                  });
                },
              ),
              
              const SizedBox(height: 24),
              
              // Botón de guardar
              ElevatedButton.icon(
                onPressed: _saveUserProfile,
                icon: const Icon(Icons.save),
                label: const Text('GUARDAR PERFIL'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _ciController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _ageController.dispose();
    super.dispose();
  }
}
```

---

## ✅ Flujo Completo (Nueva Arquitectura)

```
Usuario abre Ajustes
    ↓
Llena formulario (CI, Nombre, etc)
    ↓
Presiona GUARDAR
    ↓
Datos se guardan en secure_storage:
  • _ciKey = '1234567890'
  • _firstNameKey = 'Juan'
  • etc
    ↓
Usuario va a Inicio
    ↓
Presiona botón de pánico (hold 1.2s)
    ↓
_activateEmergency() se ejecuta
    ↓
Llama: AlertService.instance.initializeFromStorage()
    ↓
initializeFromStorage() lee: SecureStorageService.getUserId()
    ↓
Retorna: '1234567890' (el CI del usuario)
    ↓
Crea alerta en: alerts/1234567890/alert_001
    ↓
Firebase ahora tiene:
  alerts: {
    "1234567890": {
      "alert_001": { ... }
    }
  }
```

---

## 🧪 Testing

### Test 1: Guardar CI
```dart
await SecureStorageService.saveCI('1234567890');
final ci = await SecureStorageService.getCI();
assert(ci == '1234567890'); // ✅
```

### Test 2: Obtener UserID
```dart
// Con CI guardado
final userId = await SecureStorageService.getUserId();
assert(userId == '1234567890'); // ✅

// Sin CI guardado
final userId = await SecureStorageService.getUserId();
assert(userId == 'user_default'); // ✅
```

### Test 3: Alert en Firebase
```
1. Guardar CI en Settings
2. Presionar botón de pánico
3. Ver Firebase: alerts/1234567890/alert_001
   ✅ Debe aparecer bajo el CI del usuario
```

---

## 📊 Beneficios de Esta Implementación

| Aspecto | Antes | Después |
|--------|-------|---------|
| **Identificación** | Todos usan `user_default` | Cada usuario tiene su CI único |
| **Escalabilidad** | 500 usuarios = 1 rama | 500 usuarios = 500 ramas |
| **Privacidad** | Las alertas se sobrescriben | Cada usuario mantiene su historial |
| **Analytics** | No se sabe quién alertó | Se identifica al usuario |
| **Fiabilidad** | Pérdida de datos | Datos persistentes por usuario |

---

## 🚀 Próximos Pasos

1. **Actualizar `senttings.dart`** con el formulario de perfil (ver código arriba)
2. **Compilar y probar:**
   ```bash
   flutter build apk --debug
   ```
3. **Probar flujo completo:**
   - Abre Settings
   - Ingresa CI: `1234567890`
   - Presiona GUARDAR
   - Ve a Inicio
   - Presiona botón de pánico
   - Verifica Firebase: `alerts/1234567890/alert_001`

---

## 📝 Notas Importantes

- ✅ El código ya está compilando exitosamente
- ✅ Todos los cambios son backwards compatible (fallback a `user_default`)
- ✅ No hay cambios breaking en la API
- ⏳ Solo falta agregar el formulario en `senttings.dart`
- ⏳ Tests adicionales para validar CI (opcional)

---

**¿Quieres que implemente el formulario en `senttings.dart`?**
