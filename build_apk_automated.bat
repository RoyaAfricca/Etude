@echo off
set "FLUTTER=C:\Users\solta\develop\flutter\bin\flutter.bat"
set "PROJECT=E:\etude"

echo [1/3] Nettoyage et récupération des dépendances...
call "%FLUTTER%" clean
call "%FLUTTER%" pub get
if errorlevel 1 exit /b 1

echo [2/3] Compilation APK Release...
call "%FLUTTER%" build apk --release --target-platform android-arm64 --obfuscate --split-debug-info=build/app/outputs/symbols
if errorlevel 1 exit /b 1

echo [3/3] Copie de l'APK...
mkdir "%PROJECT%\Adel" 2>nul
copy /Y "%PROJECT%\build\app\outputs\flutter-apk\app-release.apk" "%PROJECT%\Adel\application_etude.apk"
mkdir "%PROJECT%\final" 2>nul
copy /Y "%PROJECT%\build\app\outputs\flutter-apk\app-release.apk" "%PROJECT%\final\application_etude_1.2.1.apk"
mkdir "%PROJECT%\website" 2>nul
copy /Y "%PROJECT%\build\app\outputs\flutter-apk\app-release.apk" "%PROJECT%\website\etude_app_arm64.apk"

exit /b 0
