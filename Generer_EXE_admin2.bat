@echo off
cd /d "%~dp0"
title Compilation de l'EXE Flutter (Windows) pour admin2
color 0A

echo.
echo ========================================================
echo   Lancement de la compilation Windows...
echo ========================================================
echo.
echo Cette operation peut prendre quelques minutes (telechargement des dependances, compilation...)
echo.

call C:\Users\solta\develop\flutter\bin\flutter.bat build windows --release

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
echo Copie de l'application dans le dossier admin2...

mkdir "admin2" 2>nul
xcopy /E /Y "build\windows\x64\runner\Release\*" "admin2\"

echo.
echo ========================================================
echo   TERMINE ! L'application Windows est dans admin2
echo   Lancez : admin2\etude_app.exe
echo ========================================================
echo.
echo.
rem pause
exit /b 0
