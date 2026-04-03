@echo off
title NETTOYAGE COMPLET DES DONNEES ETUDE
color 0E
echo.
echo ========================================================
echo   NETTOYAGE DES CACHES, REGISTRES ET DONNEES (WINDOWS)
echo ========================================================
echo.

echo [1/4] Fermeture de l'application...
taskkill /F /IM Etude.exe /T 2>nul
taskkill /F /IM etude_app.exe /T 2>nul
timeout /t 2 /nobreak >nul

echo [2/4] Suppression des dossiers de donnees locales (standard et MSIX)...

REM Dossier standard base sur l'editeur
if exist "%LOCALAPPDATA%\RoyaAfricca\Etude" (
    echo Suppression de %LOCALAPPDATA%\RoyaAfricca\Etude...
    rmdir /S /Q "%LOCALAPPDATA%\RoyaAfricca\Etude"
)

REM Autres dossiers possibles
if exist "%LOCALAPPDATA%\Etude" (
    echo Suppression de %LOCALAPPDATA%\Etude...
    rmdir /S /Q "%LOCALAPPDATA%\Etude"
)

if exist "%APPDATA%\Etude" (
    echo Suppression de %APPDATA%\Etude...
    rmdir /S /Q "%APPDATA%\Etude"
)

REM Dossiers pour les versions MSIX (paquets Windows)
echo Nettoyage des paquets MSIX si presents...
for /d %%i in ("%LOCALAPPDATA%\Packages\com.royaafricca.etude_*") do (
    echo Suppression du paquet MSIX : %%i
    rmdir /s /q "%%i"
)

echo [3/4] Nettoyage du registre Windows (Optionnel)...
echo Suppression des cles de registre...
reg delete "HKEY_CURRENT_USER\Software\RoyaAfricca\Etude" /f 2>nul
reg delete "HKEY_CURRENT_USER\Software\Etude" /f 2>nul
reg delete "HKEY_LOCAL_MACHINE\Software\RoyaAfricca\Etude" /f 2>nul
reg delete "HKEY_LOCAL_MACHINE\Software\Etude" /f 2>nul

echo [4/4] Nettoyage du cache de compilation (Flutter)...
if exist "pubspec.yaml" (
    call flutter clean
)

echo.
echo ========================================================
echo   TERMINE ! Les donnees et registres ont ete nettoyes.
echo   L'application repartira sur une base vierge.
echo ========================================================
echo.
pause
