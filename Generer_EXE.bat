@echo off
title Compilation de l'EXE Flutter (Windows)
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
echo Copie de l'application dans le dossier Adel...

mkdir "Adel\EtudeWindows" 2>nul
xcopy /E /Y "build\windows\x64\runner\Release\*" "Adel\EtudeWindows\"

echo.
echo ========================================================
echo   TERMINE ! L'application Windows est dans Adel\EtudeWindows
echo   Lancez : Adel\EtudeWindows\etude_app.exe
echo ========================================================
echo.
echo.
rem pause
exit /b 0
