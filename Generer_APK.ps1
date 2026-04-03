$ErrorActionPreference = "Continue"
$Host.UI.RawUI.WindowTitle = "Compilation APK Android Étude"

Write-Host "`n========================================================" -ForegroundColor Cyan
Write-Host "  Étude — Compilation APK Android (Signé)" -ForegroundColor Cyan
Write-Host "========================================================`n" -ForegroundColor Cyan

$FLUTTER = "C:\Users\solta\develop\flutter\bin\flutter.bat"
$env:PUB_CACHE = "E:\.pub-cache"
$env:GRADLE_USER_HOME = "E:\.gradle"
$PROJECT = "E:\etude"

Write-Host "[1/3] Nettoyage et récupération des dépendances..." -ForegroundColor Yellow
& $FLUTTER clean
& $FLUTTER pub get

Write-Host "`n[2/3] Compilation APK Release Optimisée (arm64 + Obfuscation)..." -ForegroundColor Yellow
& $FLUTTER build apk --release --target-platform android-arm64 --obfuscate --split-debug-info=build/app/outputs/symbols

Write-Host "`n[3/3] Copie de l'APK vers Adel, final, et website..." -ForegroundColor Yellow
$OUT_DIR = "$PROJECT\build\app\outputs\flutter-apk\app-release.apk"

if (Test-Path $OUT_DIR) {
    if (!(Test-Path "$PROJECT\Adel")) { New-Item -ItemType Directory -Path "$PROJECT\Adel" | Out-Null }
    Copy-Item -Path $OUT_DIR -Destination "$PROJECT\Adel\application_etude.apk" -Force
    
    if (!(Test-Path "$PROJECT\final")) { New-Item -ItemType Directory -Path "$PROJECT\final" | Out-Null }
    Copy-Item -Path $OUT_DIR -Destination "$PROJECT\final\application_etude_1.2.1.apk" -Force
    
    Copy-Item -Path $OUT_DIR -Destination "$PROJECT\website\etude_app_arm64.apk" -Force
    
    Write-Host "`n========================================================" -ForegroundColor Green
    Write-Host "  TERMINE AVEC SUCCES !" -ForegroundColor Green
    Write-Host "========================================================`n"
} else {
    Write-Host "`n[!] ERREUR : L'APK n'a pas pu être généré. Vérifiez les erreurs ci-dessus." -ForegroundColor Red
}

Read-Host "Appuyez sur Entrée pour quitter..."
