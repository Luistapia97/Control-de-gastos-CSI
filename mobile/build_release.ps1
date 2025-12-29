# Script para generar APK de producción
# Ejecutar desde el directorio mobile/

Write-Host "🔨 Construyendo APK de producción..." -ForegroundColor Cyan

# Limpiar builds anteriores
Write-Host "🧹 Limpiando builds anteriores..." -ForegroundColor Yellow
flutter clean

# Obtener dependencias
Write-Host "📦 Obteniendo dependencias..." -ForegroundColor Yellow
flutter pub get

# Build APK release
Write-Host "🚀 Construyendo APK release..." -ForegroundColor Green
flutter build apk --release

# Build App Bundle para Google Play
Write-Host "📱 Construyendo App Bundle..." -ForegroundColor Green
flutter build appbundle --release

Write-Host "`n✅ Build completado!" -ForegroundColor Green
Write-Host "📍 APK ubicado en: build\app\outputs\flutter-apk\app-release.apk" -ForegroundColor Cyan
Write-Host "📍 Bundle ubicado en: build\app\outputs\bundle\release\app-release.aab" -ForegroundColor Cyan

# Información del APK
$apkPath = "build\app\outputs\flutter-apk\app-release.apk"
if (Test-Path $apkPath) {
    $size = (Get-Item $apkPath).Length / 1MB
    Write-Host "`n📊 Tamaño del APK: $([math]::Round($size, 2)) MB" -ForegroundColor Yellow
}
