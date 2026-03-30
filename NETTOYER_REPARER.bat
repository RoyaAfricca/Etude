@echo off
title ETUDE - Reparation et Compilation Complete
cd /d "E:\etude"

set "PUB_CACHE=E:\.pub-cache"
set "GRADLE_USER_HOME=E:\.gradle"
if not exist "%PUB_CACHE%" mkdir "%PUB_CACHE%"
if not exist "%GRADLE_USER_HOME%" mkdir "%GRADLE_USER_HOME%"

echo.
echo ========================================================
echo  1. DESTRUCTION DES PROCESSUS FANTOMES...
echo ========================================================
taskkill /F /IM Etude.exe /T 2>nul
taskkill /F /IM temp_flutter_project.exe /T 2>nul
taskkill /F /IM etude_app.exe /T 2>nul
timeout /t 2 /nobreak >nul

echo.
echo ========================================================
echo  2. SUPPRESSION DU DOSSIER BLOQUE (build)...
echo ========================================================
if exist "build" (
    rmdir /S /Q "build" 2>nul
    if exist "build" (
        echo [AVERTISSEMENT] Certains fichiers n'ont pas pu etre supprimes.
        echo Continuons quand meme...
    ) else (
        echo Dossier build supprime avec succes.
    )
)

echo.
echo ========================================================
echo  3. NETTOYAGE FLUTTER...
echo ========================================================
call C:\Users\solta\develop\flutter\bin\flutter.bat clean

echo.
echo ========================================================
echo  4. TELECHARGEMENT DES DEPENDANCES (pub get)...
echo    [Incluant les nouveaux packages pdf et printing]
echo    Patientez, cela peut prendre 2-3 minutes...
echo ========================================================
call C:\Users\solta\develop\flutter\bin\flutter.bat pub get
if %errorlevel% neq 0 (
    echo [ERREUR] flutter pub get a echoue !
    pause
    exit /b 1
)

echo.
echo ========================================================
echo  5. COMPILATION WINDOWS RELEASE...
echo    Patientez, cela peut prendre 3-5 minutes...
echo ========================================================
call C:\Users\solta\develop\flutter\bin\flutter.bat build windows --release
if %errorlevel% neq 0 (
    echo.
    echo [ERREUR] La compilation a echoue !
    echo Lisez l'erreur ci-dessus.
    pause
    exit /b 1
)

echo.
echo ========================================================
echo  TERMINE ! Application generee avec succes.
echo  Emplacement :
echo  E:\etude\build\windows\x64\runner\Release\
echo ========================================================
echo.
echo  NOUVEAUTES DE CETTE VERSION :
echo  - Ecran de connexion (Login/Mot de passe)
echo  - Changement de mot de passe au premier lancement
echo  - Choix du mode : Enseignant ou Centre d'etudes
echo  - Gestion des enseignants (3 types de contrats)
echo  - Tableau de bord revenus par enseignant
echo  - Impression de recus PDF sur imprimante physique
echo  - Bouton de deconnexion dans le tableau de bord
echo.
pause
