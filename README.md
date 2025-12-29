# Expense Control - App de Control de Gastos

![Version](https://img.shields.io/badge/version-0.1.0-blue.svg)
![License](https://img.shields.io/badge/license-MIT-green.svg)

Aplicación móvil y backend para control de gastos empresariales con OCR inteligente, flujo de aprobaciones y generación de reportes.

## 🚀 Características

### Core Features (MVP)
- ✅ **Escaneo Inteligente (OCR)**: Extrae automáticamente fecha, monto y comercio de recibos
- ✅ **Categorización**: Organiza gastos por categorías personalizables
- ✅ **Flujo de Aprobación**: Sistema simple de envío y aprobación de reportes
- ✅ **Exportación**: Genera PDFs y CSVs para contabilidad

### Tecnologías
- **Backend**: FastAPI (Python 3.11+)
- **Frontend Mobile**: Flutter 3.x
- **Base de Datos**: PostgreSQL 15
- **Cache/Queue**: Redis
- **OCR**: Google Cloud Vision API
- **Storage**: AWS S3 / Cloudflare R2

---

## 📁 Estructura del Proyecto

```
App_Control_Gastos/
├── backend/                    # FastAPI Backend
│   ├── app/
│   │   ├── api/               # API Routes
│   │   │   ├── auth.py
│   │   │   ├── expenses.py
│   │   │   ├── reports.py
│   │   │   ├── categories.py
│   │   │   └── users.py
│   │   ├── core/              # Core functionality
│   │   │   ├── config.py      # Settings
│   │   │   ├── database.py    # DB connection
│   │   │   └── security.py    # Auth & JWT
│   │   ├── models/            # SQLAlchemy models
│   │   │   ├── user.py
│   │   │   ├── expense.py
│   │   │   ├── report.py
│   │   │   ├── category.py
│   │   │   └── approval.py
│   │   ├── schemas/           # Pydantic schemas
│   │   ├── services/          # Business logic
│   │   │   ├── ocr_service.py
│   │   │   └── storage_service.py
│   │   └── main.py            # App entry point
│   ├── tests/
│   ├── Dockerfile
│   ├── requirements.txt
│   └── .env.example
│
├── mobile/                     # Flutter App
│   ├── lib/
│   │   ├── core/
│   │   │   ├── config/
│   │   │   ├── network/
│   │   │   └── theme/
│   │   ├── features/
│   │   │   ├── auth/
│   │   │   ├── expenses/
│   │   │   └── reports/
│   │   ├── shared/
│   │   └── main.dart
│   ├── android/
│   ├── ios/
│   └── pubspec.yaml
│
├── docs/                       # Documentación
├── scripts/                    # Scripts de utilidad
└── docker-compose.yml
```

---

## 🛠️ Instalación y Setup

### Prerrequisitos
- **Python**: 3.11+
- **PostgreSQL**: 15+
- **Redis**: 7+
- **Docker** (opcional pero recomendado)
- **Flutter**: 3.0+ (para mobile)

### 1. Backend Setup

#### Con Docker (Recomendado)
```bash
# Clonar el repositorio
cd App_Control_Gastos

# Copiar variables de entorno
cp backend/.env.example backend/.env

# Editar backend/.env con tus credenciales
# Especialmente: SECRET_KEY, DATABASE_URL, GOOGLE_APPLICATION_CREDENTIALS

# Levantar servicios
docker-compose up -d

# Crear tablas de base de datos
docker-compose exec backend alembic upgrade head

# Ver logs
docker-compose logs -f backend
```

La API estará disponible en: `http://localhost:8000`
Documentación Swagger: `http://localhost:8000/api/docs`

#### Sin Docker (Manual)
```bash
cd backend

# Crear entorno virtual
python -m venv venv
.\venv\Scripts\Activate.ps1  # Windows PowerShell

# Instalar dependencias
pip install -r requirements.txt

# Configurar .env
cp .env.example .env
# Editar .env con tus configuraciones

# Inicializar base de datos
alembic upgrade head

# Ejecutar servidor
uvicorn app.main:app --reload --port 8000
```

### 2. Mobile Setup

```bash
cd mobile

# Instalar dependencias (requiere Flutter instalado)
flutter pub get

# Ejecutar en emulador/dispositivo
flutter run

# Build para producción
flutter build apk        # Android
flutter build ios        # iOS (requiere Mac)
```

---

## 🔐 Configuración de Servicios Externos

### Google Cloud Vision (OCR)

1. Crear proyecto en [Google Cloud Console](https://console.cloud.google.com/)
2. Habilitar Cloud Vision API
3. Crear credenciales (Service Account)
4. Descargar el archivo JSON de credenciales
5. Configurar en `.env`:
```env
GOOGLE_CLOUD_PROJECT=tu-proyecto-id
GOOGLE_APPLICATION_CREDENTIALS=/path/to/service-account.json
```

### AWS S3 / Cloudflare R2 (Storage)

#### Para AWS S3:
```env
S3_BUCKET=expense-receipts
S3_REGION=us-east-1
S3_ACCESS_KEY=tu-access-key
S3_SECRET_KEY=tu-secret-key
S3_ENDPOINT=
```

#### Para Cloudflare R2:
```env
S3_BUCKET=expense-receipts
S3_REGION=auto
S3_ACCESS_KEY=tu-r2-access-key
S3_SECRET_KEY=tu-r2-secret-key
S3_ENDPOINT=https://your-account-id.r2.cloudflarestorage.com
```

---

## 📊 Modelo de Datos

### Tablas Principales

**users**
- id, email, full_name, hashed_password
- role (employee, manager, admin)
- created_at, updated_at

**expenses**
- id, user_id, category_id, report_id
- amount, currency, merchant, description
- receipt_url, ocr_data, ocr_confidence
- status (draft, pending, approved, rejected)
- expense_date, created_at, updated_at

**reports**
- id, user_id, title, description
- total_amount, currency
- status (draft, submitted, approved, rejected, paid)
- submitted_at, created_at, updated_at

**categories**
- id, name, description, icon, color
- max_amount (límite opcional)

**approvals**
- id, report_id, approver_id
- approved (boolean), comments
- created_at

---

## 🧪 Testing

```bash
# Backend tests
cd backend
pytest tests/ -v

# Mobile tests
cd mobile
flutter test
```

---

## 📱 API Endpoints

### Authentication
- `POST /api/auth/register` - Registrar usuario
- `POST /api/auth/login` - Login
- `POST /api/auth/refresh` - Refresh token

### Expenses
- `GET /api/expenses` - Listar gastos
- `POST /api/expenses` - Crear gasto
- `POST /api/expenses/scan` - Escanear recibo (OCR)
- `GET /api/expenses/{id}` - Obtener gasto
- `PUT /api/expenses/{id}` - Actualizar gasto
- `DELETE /api/expenses/{id}` - Eliminar gasto

### Reports
- `GET /api/reports` - Listar reportes
- `POST /api/reports` - Crear reporte
- `POST /api/reports/{id}/submit` - Enviar a aprobación
- `POST /api/reports/{id}/approve` - Aprobar reporte
- `POST /api/reports/{id}/reject` - Rechazar reporte
- `GET /api/reports/{id}/export` - Exportar PDF/CSV

### Categories
- `GET /api/categories` - Listar categorías
- `POST /api/categories` - Crear categoría

---

## 🚀 Deployment

### Backend (Railway / Render / DigitalOcean)
```bash
# Ejemplo con Railway
railway init
railway add postgres
railway up
```

### Mobile (Google Play / App Store)
```bash
# Android
flutter build appbundle
# Upload to Google Play Console

# iOS
flutter build ipa
# Upload via Xcode to App Store Connect
```

---

## 🗺️ Roadmap

### Fase 1 - MVP (Actual)
- [x] Setup inicial de proyecto
- [ ] Autenticación completa
- [ ] CRUD de gastos
- [ ] OCR básico
- [ ] Flujo de aprobación
- [ ] Exportación PDF

### Fase 2 - Mejoras
- [ ] OCR offline (Google ML Kit)
- [ ] Notificaciones push
- [ ] Dashboard con gráficos
- [ ] Multi-tenancy (empresas)
- [ ] Integración con Stripe/PayPal

### Fase 3 - Escalabilidad
- [ ] App Web (Flutter Web)
- [ ] Integraciones con ERP
- [ ] IA para detección de fraude
- [ ] API pública

---

## 👥 Contribuir

1. Fork el proyecto
2. Crea una rama: `git checkout -b feature/nueva-funcionalidad`
3. Commit: `git commit -am 'Agregar nueva funcionalidad'`
4. Push: `git push origin feature/nueva-funcionalidad`
5. Pull Request

---

## 📄 Licencia

MIT License - ver [LICENSE](LICENSE)

---

## 📞 Soporte

Para preguntas o problemas, crear un [issue](https://github.com/tu-usuario/expense-control/issues).

---

**Desarrollado con ❤️ usando FastAPI + Flutter**
