# App Flutter - Control de Gastos

## 🚀 Características Implementadas

### Autenticación
- ✅ Login con validación
- ✅ Registro de usuarios
- ✅ Persistencia de sesión con SharedPreferences
- ✅ Auto-login si hay sesión activa

### Gestión de Gastos
- ✅ Lista de gastos con filtros por estado
- ✅ Crear nuevo gasto con formulario
- ✅ Selector de categorías
- ✅ Selector de fecha
- ✅ Visualización con estados coloreados
- ✅ Pull-to-refresh
- ✅ Formato de moneda y fechas

### UI/UX
- ✅ Diseño Material 3
- ✅ Navegación fluida
- ✅ Mensajes de feedback (SnackBars)
- ✅ Loading states
- ✅ Validación de formularios

## 📱 Plataformas Soportadas

- ✅ Android (Emulador y dispositivos físicos)
- ✅ iOS (Simulador y dispositivos físicos)
- ✅ Windows Desktop
- ✅ Web (Chrome, Edge)

## 🔧 Configuración

### 1. Instalar Dependencias

```bash
cd mobile
flutter pub get
```

### 2. Configurar Backend URL

Edita `lib/services/auth_service.dart` y `lib/services/expense_service.dart`:

```dart
// Para Android Emulator
static const String baseUrl = 'http://10.0.2.2:8000/api';

// Para iOS Simulator
static const String baseUrl = 'http://localhost:8000/api';

// Para dispositivo físico (reemplaza con tu IP local)
static const String baseUrl = 'http://192.168.1.100:8000/api';

// Para Windows/Web
static const String baseUrl = 'http://localhost:8000/api';
```

### 3. Ejecutar la App

#### Android Emulator
```bash
flutter run
```

#### iOS Simulator
```bash
flutter run
```

#### Windows Desktop
```bash
flutter run -d windows
```

#### Web (Chrome)
```bash
flutter run -d chrome
```

## 🧪 Probando la App

### 1. Inicia el Backend

```bash
cd backend
docker-compose up
```

El backend debe estar corriendo en `http://localhost:8000`

### 2. Crear Usuario de Prueba

**Opción A: Desde la app**
- Toca "Regístrate"
- Ingresa: nombre, email, contraseña
- Haz clic en "Registrarse"

**Opción B: Usar usuario existente**
- Email: `test@expense.com`
- Password: `password123`

### 3. Flujo de Prueba

1. **Login**
   - Ingresa credenciales
   - Verifica redirección a lista de gastos

2. **Ver Gastos**
   - Observa la lista de gastos existentes
   - Prueba los filtros por estado

3. **Crear Gasto**
   - Toca el botón "Nuevo Gasto"
   - Selecciona categoría
   - Ingresa monto (ej: 25.50)
   - Opcional: comercio y descripción
   - Selecciona fecha
   - Guarda

4. **Verificar**
   - El nuevo gasto aparece en la lista
   - Estado inicial: "Borrador"
   - Pull-to-refresh actualiza la lista

## 📂 Estructura del Código

```
mobile/lib/
├── main.dart                  # Punto de entrada
├── models/
│   ├── user.dart             # Modelo de usuario
│   ├── expense.dart          # Modelo de gasto
│   └── category.dart         # Modelo de categoría
├── services/
│   ├── auth_service.dart     # Servicio de autenticación
│   └── expense_service.dart  # Servicio de gastos
└── pages/
    ├── login_page.dart       # Pantalla de login
    ├── register_page.dart    # Pantalla de registro
    ├── expenses_page.dart    # Lista de gastos
    └── create_expense_page.dart  # Crear gasto
```

## 🐛 Solución de Problemas

### Error de Conexión

Si ves "Error de conexión":

1. **Verifica que el backend está corriendo**
   ```bash
   curl http://localhost:8000/health
   ```

2. **Verifica la URL en los servicios**
   - Android Emulator: `10.0.2.2:8000`
   - iOS/Desktop: `localhost:8000`
   - Dispositivo físico: Tu IP local

3. **Verifica CORS en backend**
   - El backend debe permitir `http://localhost:*` para web/desktop

### Errores de Compilación

```bash
flutter clean
flutter pub get
flutter run
```

### Hot Reload no Funciona

Presiona `r` en la terminal para hot reload manual, o `R` para hot restart.

## 🎯 Próximas Funcionalidades

- [ ] Captura de foto con cámara
- [ ] Escaneo OCR de recibos
- [ ] Gestión de reportes
- [ ] Dashboard con gráficos
- [ ] Notificaciones push
- [ ] Modo offline con sincronización

## 📝 Notas Técnicas

- **Autenticación**: JWT tokens almacenados en SharedPreferences
- **Montos**: Se envían en centavos al backend (25.50 USD = 2550 centavos)
- **Fechas**: Formato ISO 8601 para compatibilidad
- **HTTP**: Librería `http` para requests REST

## 🔐 Credenciales de Prueba

### Usuario Empleado
- Email: `test@expense.com`
- Password: `password123`
- Rol: employee

### Usuario Manager
- Email: `manager@expense.com`
- Password: `manager123`
- Rol: manager

## 📱 Capturas de Pantalla

_(La app se está ejecutando en tu sistema)_

1. **Login**: Pantalla de inicio de sesión
2. **Lista de Gastos**: Vista principal con filtros
3. **Crear Gasto**: Formulario completo
4. **Estados**: Borrador, Pendiente, Aprobado, Rechazado
