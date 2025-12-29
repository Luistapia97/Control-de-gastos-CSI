# Quick Start Guide

## 🚀 Inicio Rápido (5 minutos)

### Opción 1: Docker (Más Fácil)

```bash
# 1. Copiar y configurar variables de entorno
cp backend/.env.example backend/.env

# 2. Editar backend/.env (mínimo configurar SECRET_KEY)

# 3. Levantar todo
docker-compose up -d

# 4. Visitar http://localhost:8000/api/docs
```

### Opción 2: Manual

**Backend:**
```bash
cd backend
python -m venv venv
.\venv\Scripts\Activate.ps1
pip install -r requirements.txt
cp .env.example .env
# Editar .env
uvicorn app.main:app --reload
```

**Frontend (cuando instales Flutter):**
```bash
cd mobile
flutter pub get
flutter run
```

---

## 📝 Próximos Pasos

1. **Configurar Google Cloud Vision para OCR**
   - Crear proyecto en Google Cloud
   - Habilitar Vision API
   - Descargar credenciales JSON

2. **Configurar Storage (S3 o R2)**
   - Crear bucket
   - Obtener access keys
   - Actualizar .env

3. **Crear base de datos**
   ```bash
   alembic upgrade head
   ```

4. **Seed de datos iniciales (categorías)**
   ```bash
   python scripts/seed_categories.py
   ```

---

## 🔧 Comandos Útiles

```bash
# Ver logs
docker-compose logs -f backend

# Detener servicios
docker-compose down

# Rebuild después de cambios
docker-compose up -d --build

# Ejecutar tests
docker-compose exec backend pytest

# Acceder a base de datos
docker-compose exec postgres psql -U postgres -d expense_control
```

---

## ⚠️ Troubleshooting

**Error: Connection refused (PostgreSQL)**
- Asegúrate de que PostgreSQL está corriendo
- Verifica DATABASE_URL en .env

**Error: Google Cloud credentials**
- Verifica que el archivo JSON existe
- Revisa GOOGLE_APPLICATION_CREDENTIALS en .env

**Error: Flutter not found**
- Instala Flutter: https://flutter.dev/docs/get-started/install
- Agrega Flutter al PATH
