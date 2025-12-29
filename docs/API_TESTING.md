# Testing de API - Control de Gastos

## ✅ Estado Actual

### Endpoints Implementados y Probados

#### 1. Autenticación (`/api/auth`)
- ✅ `POST /api/auth/register` - Registro de usuarios
- ✅ `POST /api/auth/login` - Login con JWT

#### 2. Usuarios (`/api/users`)
- ✅ `GET /api/users/me` - Obtener usuario actual
- ✅ `PUT /api/users/me` - Actualizar perfil
- ✅ `GET /api/users/` - Listar usuarios (admin)

#### 3. Categorías (`/api/categories`)
- ✅ `GET /api/categories/` - Listar categorías activas

#### 4. Gastos (`/api/expenses`)
- ✅ `GET /api/expenses/` - Listar gastos con filtros
- ✅ `POST /api/expenses/` - Crear gasto
- ✅ `GET /api/expenses/{id}` - Obtener gasto por ID
- ✅ `PUT /api/expenses/{id}` - Actualizar gasto
- ✅ `DELETE /api/expenses/{id}` - Eliminar gasto
- 🔄 `POST /api/expenses/scan` - OCR de recibos (implementado, pendiente de prueba completa)

#### 5. Reportes (`/api/reports`)
- ✅ `GET /api/reports/` - Listar reportes
- ✅ `POST /api/reports/` - Crear reporte
- ✅ `GET /api/reports/{id}` - Obtener reporte con gastos
- ✅ `PUT /api/reports/{id}` - Actualizar reporte (solo draft)
- ✅ `POST /api/reports/{id}/add-expense/{expense_id}` - Agregar gasto
- ✅ `DELETE /api/reports/{id}/remove-expense/{expense_id}` - Quitar gasto
- ✅ `POST /api/reports/{id}/submit` - Enviar para aprobación
- 🔄 `POST /api/reports/{id}/approve` - Aprobar reporte (pendiente)
- 🔄 `POST /api/reports/{id}/reject` - Rechazar reporte (pendiente)
- 🔄 `GET /api/reports/{id}/export` - Exportar PDF/CSV (pendiente)

## Pruebas Realizadas

### Setup
```powershell
# 1. Login
$loginData = @{ 
    email = "test@expense.com"
    password = "password123" 
} | ConvertTo-Json

$auth = Invoke-RestMethod -Method POST `
    -Uri "http://localhost:8000/api/auth/login" `
    -Body $loginData `
    -ContentType "application/json"

$headers = @{ 
    Authorization = "Bearer $($auth.access_token)" 
}
```

### CRUD Completo de Gastos

#### 1. Crear Gasto
```powershell
$payload = '{"category_id":1,"amount":2500,"expense_date":"2025-12-12T11:30:45"}'

$expense = Invoke-RestMethod -Method POST `
    -Uri "http://localhost:8000/api/expenses/" `
    -Headers $headers `
    -Body $payload `
    -ContentType "application/json"
```

**Resultado:**
```json
{
  "id": 1,
  "user_id": 1,
  "category_id": 1,
  "amount": 2500,
  "currency": "USD",
  "status": "draft",
  "expense_date": "2025-12-12T11:30:45",
  "created_at": "2025-12-12T18:23:49.831984"
}
```

#### 2. Listar Gastos
```powershell
$expenses = Invoke-RestMethod -Uri "http://localhost:8000/api/expenses/" -Headers $headers
```

**Resultado:** Lista de gastos del usuario autenticado

#### 3. Obtener Gasto Específico
```powershell
$expense = Invoke-RestMethod -Uri "http://localhost:8000/api/expenses/2" -Headers $headers
```

#### 4. Actualizar Gasto
```powershell
$updatePayload = '{"amount":12000,"status":"pending"}'

$updated = Invoke-RestMethod -Method PUT `
    -Uri "http://localhost:8000/api/expenses/2" `
    -Headers $headers `
    -Body $updatePayload `
    -ContentType "application/json"
```

#### 5. Filtrar Gastos
```powershell
# Por estado
$pending = Invoke-RestMethod -Uri "http://localhost:8000/api/expenses/?status=pending" -Headers $headers

# Por categoría
$food = Invoke-RestMethod -Uri "http://localhost:8000/api/expenses/?category_id=1" -Headers $headers

# Con paginación
$page1 = Invoke-RestMethod -Uri "http://localhost:8000/api/expenses/?skip=0&limit=10" -Headers $headers
```

#### 6. Eliminar Gasto
```powershell
Invoke-RestMethod -Method DELETE `
    -Uri "http://localhost:8000/api/expenses/1" `
    -Headers $headers
```

## Características Implementadas

### Validaciones
- ✅ Autenticación requerida para todos los endpoints de gastos
- ✅ Validación de categoría existente al crear/actualizar gasto
- ✅ Usuarios solo pueden ver/modificar sus propios gastos
- ✅ Validación de tipos de datos (Pydantic schemas)

### Funcionalidades
- ✅ Almacenamiento de montos en centavos (precisión)
- ✅ Estados de gastos (draft, pending, approved, rejected)
- ✅ Filtros múltiples (categoría, estado, paginación)
- ✅ Timestamps automáticos (created_at, updated_at)
- ✅ Soporte para campos opcionales (merchant, description, receipt)

### OCR Service
- ✅ Integración con Google Cloud Vision (opcional)
- ✅ Modo Mock cuando no hay credenciales de Google Cloud
- ✅ Extracción de datos: merchant, amount, date, confidence
- ⚠️ Pendiente: prueba completa de upload de imagen

## Próximos Pasos

1. **Aprobaciones** (`/api/approvals` o endpoints en `/api/reports`)
   - POST /reports/{id}/approve - Aprobar reporte (requiere rol manager/admin)
   - POST /reports/{id}/reject - Rechazar reporte con comentarios
   - GET /approvals/pending - Listar reportes pendientes de aprobación (para managers)

2. **Exportación**
   - GET /reports/{id}/export/pdf - Generar PDF del reporte
   - GET /reports/{id}/export/csv - Exportar gastos a CSV
   - Integrar con librería de generación de PDFs (reportlab, weasyprint)

3. **OCR Testing Completo**
   - Probar endpoint /scan con imagen real
   - Configurar credenciales de Google Cloud Vision
   - Validar sugerencia automática de categoría

4. **Mobile App (Flutter)**
   - Pantalla de login funcional
   - Lista de gastos
   - Captura de recibo con cámara
   - Creación y envío de reportes

## Pruebas de Reportes

### Setup
```powershell
# Autenticación
$loginData = @{ email = "test@expense.com"; password = "password123" } | ConvertTo-Json
$auth = Invoke-RestMethod -Method POST -Uri "http://localhost:8000/api/auth/login" -Body $loginData -ContentType "application/json"
$headers = @{ Authorization = "Bearer $($auth.access_token)" }
```

### 1. Crear Reporte
```powershell
$reportData = '{"title":"Gastos Diciembre 2025","description":"Reporte mensual","start_date":"2025-12-01T00:00:00","end_date":"2025-12-31T23:59:59"}'
$report = Invoke-RestMethod -Method POST -Uri "http://localhost:8000/api/reports/" -Headers $headers -Body $reportData -ContentType "application/json"
```

**Resultado:**
```json
{
  "id": 1,
  "title": "Gastos Diciembre 2025",
  "status": "draft",
  "expense_count": 0,
  "total_amount": 0
}
```

### 2. Agregar Gastos al Reporte
```powershell
# Agregar gasto existente
Invoke-RestMethod -Method POST -Uri "http://localhost:8000/api/reports/1/add-expense/2" -Headers $headers
```

### 3. Ver Reporte con Gastos
```powershell
$reportDetail = Invoke-RestMethod -Uri "http://localhost:8000/api/reports/1" -Headers $headers
```

**Resultado:** Incluye array de gastos con detalles completos

### 4. Enviar para Aprobación
```powershell
$submitted = Invoke-RestMethod -Method POST -Uri "http://localhost:8000/api/reports/1/submit" -Headers $headers
```

**Efectos:**
- Cambia status del reporte a "submitted"
- Cambia status de todos los gastos a "pending"
- Establece submitted_at timestamp
- Ya no se puede editar el reporte ni agregar/quitar gastos

### Validaciones Implementadas
- ✅ Solo se pueden editar reportes en estado "draft"
- ✅ Solo se pueden agregar gastos a reportes en "draft"
- ✅ Un gasto no puede estar en múltiples reportes
- ✅ No se puede enviar reporte vacío (sin gastos)
- ✅ Los gastos cambian a "pending" al enviar reporte

## Problemas Conocidos y Soluciones

### ❌ Problema: "There was an error parsing the body"
**Causa:** PowerShell ConvertTo-Json con objetos complejos  
**Solución:** Usar string literals para JSON en PowerShell
```powershell
# ❌ No funciona bien
$data = @{ field = (Get-Date) } | ConvertTo-Json

# ✅ Funciona
$data = '{"field":"2025-12-12T11:30:45"}'
```

### ⚠️ Bcrypt 72-char limit
**Solución:** Implementado truncamiento automático en `app/core/security.py`

### ⚠️ Google Cloud Vision no disponible
**Solución:** OCR Service corre en modo mock con datos de demostración

## Documentación Interactiva

- Swagger UI: http://localhost:8000/api/docs
- ReDoc: http://localhost:8000/redoc
- OpenAPI JSON: http://localhost:8000/openapi.json
