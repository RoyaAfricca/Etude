@echo off
title Compilation APK Android Étude
color 0A
chcp 65001 >nul

echo.
echo ========================================================
echo   Étude — Compilation APK Android (Signé)
echo ========================================================
echo.

set "FLUTTER=C:\Users\solta\develop\flutter\bin\flutter.bat"
set "PUB_CACHE=E:\.pub-cache"
set "GRADLE_USER_HOME=E:\.gradle"
set "PROJECT=E:\etude"

if not exist "%PUB_CACHE%" mkdir "%PUB_CACHE%"
if not exist "%GRADLE_USER_HOME%" mkdir "%GRADLE_USER_HOME%"

echo [1/3] Nettoyage et récupération des dépendances...
call "%FLUTTER%" clean
call "%FLUTTER%" pub get
if %errorlevel% neq 0 (
    color 0C
    echo.
    echo ERREUR : flutter pub get a échoué.
    pause
    exit /b 1
)
echo     OK
echo.

echo [2/3] Compilation APK Release Optimisée (arm64 + Obfuscation)...
call "%FLUTTER%" build apk --release --target-platform android-arm64 --obfuscate --split-debug-info=build/app/outputs/symbols
if %errorlevel% neq 0 (
    color 0C
    echo.
    echo ERREUR : La compilation APK a échoué.
    pause
    exit /b 1
)
echo     OK - APK optimisé compilé
echo.

echo [3/3] Copie de l'APK...

rem Copie vers dossier Adel
mkdir "%PROJECT%\Adel" 2>nul
copy /Y "%PROJECT%\build\app\outputs\flutter-apk\app-release.apk" "%PROJECT%\Adel\application_etude.apk"

rem Copie vers dossier final
mkdir "%PROJECT%\final" 2>nul
copy /Y "%PROJECT%\build\app\outputs\flutter-apk\app-release.apk" "%PROJECT%\final\application_etude_1.2.1.apk"

rem Copie pour le site web
copy /Y "%PROJECT%\build\app\outputs\flutter-apk\app-release.apk" "%PROJECT%\website\etude_app_arm64.apk"

echo.
echo ========================================================
echo   TERMINE ! APK disponible :
echo   - Adel\application_etude.apk
echo   - final\application_etude_1.2.1.apk
echo   - website\etude_app_arm64.apk (SITE)
echo ========================================================
echo.
pause
