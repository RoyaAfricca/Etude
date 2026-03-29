@echo off
title Generation de l'installateur Windows (MSIX)
color 0A

echo.
echo ========================================================
echo   Preparation de l'installateur Windows...
echo ========================================================
echo.

echo (1/3) Ajout de l'outil de creation d'installateur...
call C:\Users\solta\develop\flutter\bin\flutter.bat pub add --dev msix

echo.
echo (2/3) Compilation de l'application en mode Release...
call C:\Users\solta\develop\flutter\bin\flutter.bat build windows --release

echo.
echo (3/3) Reconditionnement en fichier installable (.msix)...
:: On utilise dart run msix:create pour générer le package
call C:\Users\solta\develop\flutter\bin\dart.bat run msix:create --display-name="Etude" --publisher-display-name="RoyaAfricca" --identity-name="com.royaafricca.etude" --version="1.0.0.0"

if errorlevel 1 (
    color 0C
    echo.
    echo [ERREUR] Impossible de creer l'installateur !
    pause
    exit /b
)

echo.
echo Copie de l'installateur dans le dossier Adel...
mkdir "Adel" 2>nul
copy /Y "build\windows\x64\runner\Release\etude_app.msix" "Adel\etude_app_installateur.msix"

echo.
echo ========================================================
echo   TERMINE ! L'installateur Windows est pret.
echo   Vous le trouverez dans le dossier : Adel\etude_app_installateur.msix
echo   (Double-cliquez dessus pour installer l'application proprement)
echo ========================================================
echo.
pause
exit /b 0
