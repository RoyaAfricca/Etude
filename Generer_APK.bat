@echo off
title Compilation de l'APK Flutter
color 0A

echo.
echo ========================================================
echo   Lancement de la compilation de votre APK...
echo ========================================================
echo.
echo Cette operation peut prendre quelques minutes (telechargement des dependances, compilation...)
echo.

set "PUB_CACHE=E:\.pub-cache"
set "GRADLE_USER_HOME=E:\.gradle"
if not exist "%PUB_CACHE%" mkdir "%PUB_CACHE%"
if not exist "%GRADLE_USER_HOME%" mkdir "%GRADLE_USER_HOME%"

call C:\Users\solta\develop\flutter\bin\flutter.bat build apk --release --target-platform android-arm,android-arm64,android-x64

if errorlevel 1 (
    color 0C
    echo.
    echo ❌ ERREUR : La compilation a echoue. Lisez le texte rouge ci-dessus pour comprendre l'erreur.
    pause
    exit /b
)

echo.
echo ✅ Compilation reussie ! 
echo.
echo Copie de l'APK dans le dossier Adel...

mkdir "Adel" 2>nul
copy /Y "build\app\outputs\flutter-apk\app-release.apk" "Adel\application_etude.apk"

echo.
echo ========================================================
echo   TERMINE ! L'application est prete dans le dossier Adel.
echo ========================================================
echo.
echo.
rem pause
exit /b 0
