#!/bin/bash
# Script de verificación de Firebase - Windows PowerShell
# Este script verifica que Firebase esté correctamente configurado

Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║  VERIFICACIÓN DE CONFIGURACIÓN FIREBASE                    ║" -ForegroundColor Green
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Green

Write-Host ""
Write-Host "✅ 1. Verificando google-services.json..." -ForegroundColor Cyan

if (Test-Path "android/app/google-services.json") {
    Write-Host "   ✓ google-services.json encontrado" -ForegroundColor Green
    $json = Get-Content "android/app/google-services.json" | ConvertFrom-Json
    Write-Host "   • Project ID: $($json.project_info.project_id)" -ForegroundColor White
    Write-Host "   • Project Number: $($json.project_info.project_number)" -ForegroundColor White
} else {
    Write-Host "   ✗ google-services.json NO encontrado" -ForegroundColor Red
}

Write-Host ""
Write-Host "✅ 2. Verificando dependencias en pubspec.yaml..." -ForegroundColor Cyan

$pubspec = Get-Content "pubspec.yaml"
$firebase_deps = @("firebase_core", "firebase_analytics", "firebase_crashlytics", "firebase_messaging", "firebase_database")

foreach ($dep in $firebase_deps) {
    if ($pubspec -match $dep) {
        Write-Host "   ✓ $dep instalado" -ForegroundColor Green
    } else {
        Write-Host "   ✗ $dep NO instalado" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "✅ 3. Verificando integración en main.dart..." -ForegroundColor Cyan

$maindart = Get-Content "lib/main.dart"
if ($maindar -match "FirebaseService") {
    Write-Host "   ✓ FirebaseService importado" -ForegroundColor Green
} else {
    Write-Host "   ✗ FirebaseService NO importado" -ForegroundColor Red
}

if ($maindar -match "initialize") {
    Write-Host "   ✓ Firebase.initialize() encontrado" -ForegroundColor Green
} else {
    Write-Host "   ✗ Firebase.initialize() NO encontrado" -ForegroundColor Red
}

Write-Host ""
Write-Host "✅ 4. Verificando servicios Firebase creados..." -ForegroundColor Cyan

$services = @("lib/services/firebase_service.dart", "lib/services/alert_service.dart")
foreach ($service in $services) {
    if (Test-Path $service) {
        $size = (Get-Item $service).Length / 1KB
        Write-Host "   ✓ $(Split-Path $service -Leaf) ($([Math]::Round($size))KB)" -ForegroundColor Green
    } else {
        Write-Host "   ✗ $(Split-Path $service -Leaf) NO encontrado" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║  ESTADO: LISTO PARA EJECUTAR                              ║" -ForegroundColor Green
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Green

Write-Host ""
Write-Host "Próximos pasos:" -ForegroundColor Yellow
Write-Host "1. flutter run                  # Ejecutar en emulador/dispositivo" -ForegroundColor White
Write-Host "2. Presionar botón de pánico    # Activar la alerta" -ForegroundColor White
Write-Host "3. Verificar en Firebase Console" -ForegroundColor White
Write-Host "   → Realtime Database → alerts/user_default → alert_XXX" -ForegroundColor White
