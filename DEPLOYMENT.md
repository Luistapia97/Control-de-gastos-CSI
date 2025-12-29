# 🚀 GUÍA DE DEPLOYMENT A PRODUCCIÓN

## BACKEND (API FastAPI)

### Opción 1: VPS (DigitalOcean, Linode, AWS EC2)

1. **Crear servidor Ubuntu 22.04**
   - Mínimo 2GB RAM, 1 CPU, 25GB SSD

2. **Conectar por SSH**
   ```bash
   ssh root@tu-ip-servidor
   ```

3. **Instalar dependencias**
   ```bash
   apt update && apt upgrade -y
   apt install docker.io docker-compose git nginx certbot python3-certbot-nginx -y
   systemctl enable docker
   systemctl start docker
   ```

4. **Clonar proyecto**
   ```bash
   cd /opt
   git clone https://github.com/tu-usuario/App_Control_Gastos.git
   cd App_Control_Gastos
   ```

5. **Configurar variables de entorno**
   ```bash
   cp .env.prod.example .env.prod
   nano .env.prod  # Editar con tus valores
   ```

6. **Generar SECRET_KEY seguro**
   ```bash
   openssl rand -hex 32
   ```

7. **Levantar servicios**
   ```bash
   docker-compose -f docker-compose.prod.yml --env-file .env.prod up -d
   ```

8. **Configurar SSL con Let's Encrypt**
   ```bash
   certbot --nginx -d tu-dominio.com -d www.tu-dominio.com
   ```

9. **Ejecutar migraciones**
   ```bash
   docker exec -it expense_backend_prod python -c "from app.core.database import engine; from app.models import *; Base.metadata.create_all(bind=engine)"
   ```

### Opción 2: Render.com (Más fácil)

1. Crear cuenta en render.com
2. Crear PostgreSQL Database
3. Crear Web Service (conectar repo GitHub)
4. Configurar variables de entorno
5. Deploy automático

### Opción 3: Railway.app

1. railway.app → New Project → Deploy from GitHub
2. Add PostgreSQL
3. Variables de entorno automáticas
4. Deploy

---

## FRONTEND (Flutter App)

### A. DISTRIBUCIÓN DIRECTA (APK)

1. **Generar APK firmado**
   ```powershell
   cd mobile
   .\build_release.ps1
   ```

2. **Compartir APK**
   - Subir a Google Drive / Dropbox
   - Enviar por WhatsApp
   - Hosting web propio

### B. GOOGLE PLAY STORE (Recomendado)

1. **Crear cuenta de desarrollador**
   - play.google.com/console
   - Pago único $25 USD

2. **Preparar assets**
   - Icono app (512x512 PNG)
   - Screenshots (2-8 imágenes)
   - Banner (1024x500)
   - Descripción
   - Política de privacidad

3. **Generar clave de firma**
   ```bash
   keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```

4. **Configurar firma en Android**
   Crear `mobile/android/key.properties`:
   ```
   storePassword=tu-password
   keyPassword=tu-password
   keyAlias=upload
   storeFile=../upload-keystore.jks
   ```

5. **Subir a Play Console**
   - Crear nueva aplicación
   - Subir AAB (app-release.aab)
   - Completar formularios
   - Enviar a revisión (2-7 días)

---

## COSTOS ESTIMADOS

### Hosting Backend:
- **DigitalOcean/Linode**: $6-12/mes (droplet básico)
- **AWS EC2**: $5-15/mes (t3.micro)
- **Render.com**: $7/mes (plan básico)
- **Railway.app**: $5/mes (hobby plan)

### Base de Datos:
- Incluida en VPS o
- **Render PostgreSQL**: Gratis (256MB) / $7/mes (1GB)
- **AWS RDS**: ~$15/mes

### Dominio:
- **Namecheap/GoDaddy**: $10-15/año (.com)

### App Distribution:
- **Google Play**: $25 único
- **APK directo**: Gratis

### TOTAL MENSUAL: ~$15-30 USD

---

## CHECKLIST PRE-PRODUCCIÓN

### Backend:
- [ ] Cambiar SECRET_KEY a valor seguro
- [ ] Configurar ALLOWED_ORIGINS con dominio real
- [ ] Deshabilitar DEBUG mode
- [ ] Configurar logs de producción
- [ ] Backup automático de base de datos
- [ ] Certificado SSL (HTTPS)
- [ ] Rate limiting configurado
- [ ] Monitoreo (Sentry, Datadog)

### Frontend:
- [ ] Cambiar baseUrl a dominio producción
- [ ] Remover console.log/debug prints
- [ ] Probar en múltiples dispositivos
- [ ] Optimizar imágenes y assets
- [ ] Configurar manejo de errores
- [ ] Agregar analytics (Firebase, Mixpanel)
- [ ] Política de privacidad publicada
- [ ] Términos de servicio

### Testing:
- [ ] Crear usuario de prueba
- [ ] Probar flujo completo (viajes, gastos, reportes)
- [ ] Probar con/sin conexión
- [ ] Validar roles (admin, usuario)
- [ ] Probar reembolsos
- [ ] Verificar estadísticas

---

## COMANDOS ÚTILES

### Backend (Producción):
```bash
# Ver logs
docker-compose -f docker-compose.prod.yml logs -f backend

# Reiniciar servicios
docker-compose -f docker-compose.prod.yml restart

# Backup base de datos
docker exec expense_postgres_prod pg_dump -U postgres expense_control > backup_$(date +%Y%m%d).sql

# Restaurar backup
cat backup.sql | docker exec -i expense_postgres_prod psql -U postgres expense_control
```

### Frontend:
```powershell
# Build APK release
flutter build apk --release

# Build para Google Play (AAB)
flutter build appbundle --release

# Instalar en dispositivo conectado
flutter install

# Ver logs del dispositivo
flutter logs
```

---

## PRÓXIMOS PASOS RECOMENDADOS

1. **Comprar dominio** (Namecheap, GoDaddy)
2. **Contratar VPS** (DigitalOcean recomendado para empezar)
3. **Configurar DNS** apuntando a IP del servidor
4. **Deploy backend** siguiendo pasos arriba
5. **Actualizar URL en app** a dominio real
6. **Generar APK release**
7. **Distribuir a usuarios** o publicar en Play Store

---

## SOPORTE

Para problemas de deployment:
- Backend: docs.docker.com, docs.gunicorn.org
- Flutter: docs.flutter.dev/deployment
- SSL: letsencrypt.org/docs
- Play Store: support.google.com/googleplay/android-developer
