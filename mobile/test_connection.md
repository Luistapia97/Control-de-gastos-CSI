# Solución: Network Timeout

## El problema

La app muestra "Network response timed out" porque no puede conectarse al backend en `http://10.0.2.2:8000`

## Verificaciones:

### 1. Backend está corriendo ✅
```bash
docker ps
# El contenedor expense_backend está UP en puerto 8000
```

### 2. URL correcta para emulador Android ✅
```dart
// En auth_service.dart y expense_service.dart
static const String baseUrl = 'http://10.0.2.2:8000/api';
```

## Soluciones a probar:

### Opción 1: Verificar firewall de Windows
El firewall puede estar bloqueando la conexión del emulador.

1. Busca "Firewall de Windows Defender" 
2. Click en "Permitir una aplicación a través de Firewall"
3. Busca "Docker Desktop" y asegúrate que esté marcado para redes privadas

### Opción 2: Probar con tu IP local
En lugar de `10.0.2.2`, usa tu IP local de la máquina:

1. Abre PowerShell y ejecuta:
```powershell
ipconfig
# Busca "IPv4 Address" de tu adaptador WiFi/Ethernet
# Ejemplo: 192.168.1.100
```

2. Actualiza las URLs en:
   - `lib/services/auth_service.dart`
   - `lib/services/expense_service.dart`

```dart
static const String baseUrl = 'http://192.168.1.100:8000/api';
```

### Opción 3: Configurar CORS en backend
Asegúrate que el backend permita conexiones desde el emulador.

En `backend/app/main.py`, verifica que CORS incluya todas las IPs:

```python
ALLOWED_ORIGINS = [
    "http://localhost:*",
    "http://127.0.0.1:*",
    "http://10.0.2.2:*",  # Android emulator
    "http://192.168.*:*",  # LAN
]
```

### Opción 4: Probar conexión directa
Desde el emulador, abre Chrome y visita:
```
http://10.0.2.2:8000/health
```

Si muestra `{"status":"healthy"}`, la conexión funciona y el problema está en la app.

### Opción 5: Logs del backend
Verifica los logs del backend para ver si llegan las peticiones:

```bash
docker logs expense_backend --follow
```

## Pasos recomendados:

1. Encuentra tu IP local con `ipconfig`
2. Actualiza `baseUrl` en auth_service.dart a tu IP local
3. Hot reload la app presionando 'r' en la terminal de Flutter
4. Prueba hacer login nuevamente
