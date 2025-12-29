# 🚀 Guía de Despliegue en Render

## Ventajas de Render:
- ✅ **Plan gratuito** (suficiente para uso interno)
- ✅ PostgreSQL incluido (1GB gratis)
- ✅ SSL automático (HTTPS)
- ✅ Despliegue desde GitHub
- ✅ No se apaga como Heroku (con plan pagado)

## Plan Gratuito incluye:
- 750 horas de servicio/mes
- PostgreSQL 1GB
- SSL/HTTPS automático
- ⚠️ Se duerme después de 15 min de inactividad (tarda ~30seg en despertar)

## 💰 Costos:

### **Opción 1: Todo GRATIS (para empezar)**
- Backend: Free ($0/mes) - se duerme
- PostgreSQL: Free ($0/mes) - 1GB
- **Limitaciones:** Se duerme después de 15 min sin uso

### **Opción 2: Producción real (recomendado)**
- Backend: Starter ($7/mes) - nunca se duerme
- PostgreSQL: Starter ($7/mes) - 1GB con backups
- **Total: $14/mes** (mucho más barato que VPS)

---

## 📋 PASOS PARA DESPLEGAR:

### 1️⃣ Crear cuenta en Render
```
https://render.com
→ Sign up with GitHub
```

### 2️⃣ Subir código a GitHub

```bash
# En tu proyecto
cd C:\Users\luiso\OneDrive\Desktop\CSI\App_Control_Gastos

# Inicializar git (si no lo has hecho)
git init
git add .
git commit -m "Initial commit - Expense Control App"

# Crear repositorio en GitHub y subir
git remote add origin https://github.com/TU_USUARIO/expense-control.git
git push -u origin main
```

### 3️⃣ Crear PostgreSQL en Render

1. Dashboard → **New** → **PostgreSQL**
2. Configurar:
   - **Name:** `expense-db`
   - **Database:** `expense_control`
   - **User:** `expense_user`
   - **Region:** Oregon (más cercano)
   - **Plan:** Free (para empezar)
3. Click **Create Database**
4. **Copiar la Internal Database URL** (la usarás después)

### 4️⃣ Crear Web Service (Backend)

1. Dashboard → **New** → **Web Service**
2. Conectar tu repositorio de GitHub
3. Configurar:
   - **Name:** `expense-backend`
   - **Region:** Oregon
   - **Branch:** main
   - **Root Directory:** `backend`
   - **Runtime:** Docker
   - **Dockerfile Path:** `Dockerfile.render`
   - **Plan:** Free (o Starter si quieres que no se duerma)

### 5️⃣ Configurar Variables de Entorno

En el Web Service, ir a **Environment** y agregar:

```
DATABASE_URL = [Pegar la Internal Database URL de PostgreSQL]
SECRET_KEY = [Generar uno nuevo con: openssl rand -hex 32]
ALLOWED_ORIGINS = *
ENVIRONMENT = production
RECEIPTS_DIR = /app/receipts
```

### 6️⃣ Agregar Persistent Disk (para imágenes)

En el Web Service:
1. Ir a **Disks**
2. Click **Add Disk**
3. Configurar:
   - **Name:** `receipts`
   - **Mount Path:** `/app/receipts`
   - **Size:** 1GB (gratis)
4. Save

### 7️⃣ Desplegar

Click **Create Web Service** → Render desplegará automáticamente

Espera 5-10 minutos. Tu URL será: `https://expense-backend.onrender.com`

### 8️⃣ Ejecutar migraciones (primera vez)

En Render Dashboard:
1. Ir a tu Web Service
2. Click en **Shell** (terminal)
3. Ejecutar:

```bash
python -m app.database.init_db
```

### 9️⃣ Actualizar APK con nueva URL

En tu código Flutter, actualizar todas las URLs:

**Cambiar de:**
```dart
final String baseUrl = 'http://192.168.100.53:8000/api';
```

**A:**
```dart
final String baseUrl = 'https://expense-backend.onrender.com/api';
```

Regenerar APK:
```bash
cd mobile
flutter build apk --release
```

### 🔟 Probar

1. Abrir: `https://expense-backend.onrender.com/health`
2. Debería devolver: `{"status":"healthy",...}`
3. Instalar nuevo APK en el celular
4. ¡Listo! Ya no necesitas tu PC encendida

---

## 🔧 Mantenimiento:

### Ver logs:
Dashboard → tu servicio → **Logs**

### Backup manual de BD:
Dashboard → PostgreSQL → **Backups** → Download

### Actualizar código:
```bash
git push origin main
# Render despliega automáticamente
```

---

## 🆙 UPGRADE a plan pagado (cuando lo necesites):

### Cuándo upgradearlo:
- ✅ Tienes usuarios reales usando diariamente
- ✅ Molesta que se duerma (15-30 seg delay)
- ✅ Necesitas más de 1GB de base de datos

### Cómo upgradearlo:
Dashboard → Servicio → **Upgrade** → Starter ($7/mes c/u)

---

## ⚡ OPCIONAL: No dejar que se duerma (plan gratuito)

Crear un cron job que haga ping cada 10 minutos:

**UptimeRobot** (gratis):
1. Crear cuenta en uptimerobot.com
2. Agregar monitor:
   - URL: `https://expense-backend.onrender.com/health`
   - Intervalo: 5 minutos
3. Esto mantiene despierto el servicio gratis

---

## 📱 APK Final para usuarios:

Tu APK conectará a: `https://expense-backend.onrender.com`

**Ventajas:**
- ✅ HTTPS (seguro)
- ✅ Funciona desde cualquier red WiFi/4G
- ✅ No necesitas PC encendida
- ✅ URL permanente
- ✅ Escalable cuando crezcas

---

## 🎯 RESUMEN - Lo mínimo para empezar:

1. Subir código a GitHub (5 min)
2. Crear PostgreSQL en Render (2 min)
3. Crear Web Service en Render (5 min)
4. Ejecutar migraciones (1 min)
5. Actualizar URLs en Flutter y regenerar APK (5 min)
6. **Total: 20 minutos + deploy time**

**Costo: $0/mes** (plan gratuito)
**Limitación:** Se duerme después de 15 min (despierta en 30 seg)

---

¿Quieres que te ayude con algún paso específico? ¿O prefieres otra plataforma?
